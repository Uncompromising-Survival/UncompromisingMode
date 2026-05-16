local env = env
GLOBAL.setfenv(1, GLOBAL)

local GEM_DEFS = require("gemology_defs").GEM_DEFS
local scrapbook_prefabs = require("scrapbook_prefabs")
local dataset = require("screens/redux/scrapbookdata")
local UpvalueHacker = require("tools/upvaluehacker")
local SPECIALINFO = STRINGS.SCRAPBOOK.SPECIALINFO
require("um_gemology_geode_defs")
require("simutil")

--strings todo: move this somewhere else?
STRINGS.SCRAPBOOK.CATS.GEMOLOGY = "Gemology"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGYGEM = "Strange Gem"
STRINGS.SCRAPBOOK.SUBCATS.GEODE = "Geode"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGY = "Gemology"

SPECIALINFO.GEMOLOGY_FORGE = "A forge found in the heart of the Magma Caves capable of enchanting tools and weapons with Strange Gems to amplify them with special effects.\n\nGem effects fade with usage."
SPECIALINFO.GEMOLOGY_GEM = "Can be used at a " .. STRINGS.NAMES.UM_GEMOLOGYFORGE .. " to apply a special effect to a Tool or Weapon depending on the quality of the gem.\n\nGem Effects:\n\n"
SPECIALINFO.UM_MOONGLASS_CEILING = "Breaks appart and drops Glass Geodes during earthquakes."
SPECIALINFO.UM_SLIMESTONE_ROCK = "Falls from the Ceiling near Slime Pillars during Earthquakes while Nightmare Phase is active."
SPECIALINFO.UM_SLIMESTONE_ROCK_GEMLESS = "Falls from the Ceiling near Slime Pillars during Earthquakes while Nightmare Phase is active."
SPECIALINFO.PETRIFIED_MUSHTREE = "Petrifies at the end of its blooming season."
--specialinfo for normal mushtrees done in init_scrapbook/changes

--add gemology category
table.insert(SCRAPBOOK_CATS, "gemology")

--data stuff
--gem forge
scrapbook_prefabs["um_gemologyforge"] = true
dataset["um_gemologyforge"] = {
    name = "um_gemologyforge",
    tex = "um_gemologyforge.tex",
    subcat = "gemology",
    type = "POI",
    prefab = "um_gemologyforge",
    build = "um_gemforge",
    bank = "um_gemforge",
    anim = "idle",
    deps = {},
    specialinfo = "GEMOLOGY_FORGE"
}

local dep_blacklist = {
    "fused_shadeling_bomb",
    "compass"
}

for k, v in pairs(dataset) do
    if (v.weapondamage or v.toolactions and not table.contains(v.toolactions, "PLAY") and not table.contains(v.toolactions, "NET")) and v.subcat ~= "riding" and not v.stacksize and not table.contains(dep_blacklist, k) then
        table.insert(dataset["um_gemologyforge"].deps, k)
    end
end

--gems
local function CreateGemologyEntryFromDefs(name, defs)
    STRINGS.SCRAPBOOK.SPECIALINFO[name] = name
    local data = {
        name = name,
        type = "gemology",
        prefab = name,
        tex = "um_gemology" .. defs.img,
        stacksize = 10,
        bank = defs.bank,
        build = defs.build,
        anim = defs.anim,
        specialinfo = string.upper(name),
        subcat = "gemologygem",
        deps = { "um_gemologyforge", "ancientfruit_gem" },
        workable = "HAMMER"
    }


    printwrap("DATA FOR " .. name, data)
    print()

    table.insert(dataset["ancientfruit_gem"].deps, name)
    table.insert(dataset["um_gemologyforge"].deps, name)

    for k, v in pairs(GetGeodeSourcesFromGem(name)) do
        table.insert(data.deps, v)
    end

    return data
end

--DESPAIR DESPAIR DESPAIR


for name, defs in pairs(GEM_DEFS) do
    local data = CreateGemologyEntryFromDefs(name, defs)
    env.AddPrefabPostInit(name, function(inst)
        inst.scrapbook_thingtype = data.type
        inst.scrapbook_specialinfo = data.specialinfo

        if inst.scrapbook_adddeps == nil then
            inst.scrapbook_adddeps = {}
        end

        ConcatArrays(inst.scrapbook_adddeps, data.deps)
    end)

    scrapbook_prefabs[name] = true
    dataset[name] = data
end

--geode sources
-- save that for

--geodes
local function CreateGeodeEntryFromLootTable(name, defs)
    local buildbank = string.gsub(name, "gemology_", "")
    local data = {
        subcat = "geode",
        name = name,
        tex = name .. ".tex",
        anim = "idle",
        build = buildbank,
        bank = buildbank,
        type = "gemology",
        prefab = name,
        stacksize = 10,
        workable = "HAMMER",
        deps = {}
    }

    local _notgemloot = {}
    local _gemloot = {}

    for k, v in pairs(defs.gemloot) do
        if scrapbook_prefabs[k] ~= nil then
            table.insert(_gemloot, k)
        else
            print("[WARNING] Geode Scrapbook: " .. k .. " is not a scrapbook prefab")
        end
    end

    for k, v in pairs(defs.notgemloot) do
        if scrapbook_prefabs[k] ~= nil then
            table.insert(_notgemloot, k)
        else
            print("[WARNING] Geode Scrapbook: " .. k .. " is not a scrapbook prefab")
        end
    end

    data.deps = JoinArrays(_notgemloot, _gemloot)

    return data
end

for name, defs in pairs(GEODE_LOOT_TABLE) do
    local data = CreateGeodeEntryFromLootTable(name, defs)
    printwrap("data for " .. name, data)
    printwrap("data.deps " .. name, data.deps)

    if name == "um_gemology_geode_vent" then
        table.insert(data.deps, "cave_vent_mite")
    elseif name == "um_gemology_geode_ruins" then
        table.insert(data.deps, "chessjunk")
    end

    dataset[name] = data
    scrapbook_prefabs[name] = true
end

--sources
--mushtrees
local colors = {
    "red",
    "green",
    "blue"
}

local color_map = {
    blue = "tall",
    green = "small",
    red = "medium"
}

for k, color in ipairs(colors) do
    --gemless
    local data_gemless = {
        name = "um_" .. color .. "mushtree_gemless",
        tex = "um_" .. color .. "mushtree_gemless.tex",
        type = "thing",
        prefab = "um_" .. color .. "mushtree_gemless",
        bank = "um_" .. color .. "mushtree_gemless",
        build = "um_" .. color .. "mushtree",
        anim = "empty_tall",
        specialinfo = "PETRIFIED_MUSHTREE",
        workable = "MINE",
        deps = { "rocks", "flint", "nitre", "log", color .. "_cap", "mushtree_" .. color_map[color] }
    }

    --gemfull
    local data_gem = {
        name = "um_" .. color .. "mushtree_gem",
        tex = "um_" .. color .. "mushtree_gem.tex",
        type = "thing",
        prefab = "um_" .. color .. "mushtree_gem",
        bank = "um_" .. color .. "mushtree_gem",
        build = "um_" .. color .. "mushtree",
        subcat = "gemology",
        specialinfo = "PETRIFIED_MUSHTREE",
        anim = "gem_tall",
        workable = "MINE",
        deps = { "rocks", "flint", "nitre", "log", "um_gemology_geode_" .. color, "mushtree_" .. color_map[color] }
    }

    dataset[data_gemless.prefab] = data_gemless
    dataset[data_gem.prefab] = data_gem
    scrapbook_prefabs[data_gemless.prefab] = true
    scrapbook_prefabs[data_gem.prefab] = true
end

local function CreateGemSourceEntry(name, build, bank, anim, deps)
    local data = {
        name = name,
        tex = name .. ".tex",
        type = "thing",
        prefab = name,
        build = build,
        bank = bank,
        anim = anim,
        subcat = "gemology",
        workable = "MINE",
        deps = deps
    }

    dataset[name] = data
    scrapbook_prefabs[name] = true
end

--guano rocks
CreateGemSourceEntry("um_guano_rock", "um_guano_rock", "um_guano_rock_gem", "tall_0", { "um_gemology_geode_guano", "bat", "rocks", "guano", "nitre" })
CreateGemSourceEntry("um_guano_rock_gemless", "um_guano_rock", "um_guano_rock_gemless", "tall_0", { "bat", "rocks", "guano", "nitre" })

--slimestone
CreateGemSourceEntry("um_slimestone_rock", "um_slimestone_rock", "um_slimestone_gem", "full", { "um_gemology_geode_slime", "monkey", "rocks", "flint", "poop", "cutlichen", "beardhair", "lightbulb", "slurper_pelt", "pondeel" })
CreateGemSourceEntry("um_slimestone_rock_gemless", "um_slimestone_rock", "um_slimestone_gemless", "full", { "monkey", "rocks", "flint", "poop", "cutlichen", "beardhair", "lightbulb", "slurper_pelt", "pondeel" })

--sinkmound
CreateGemSourceEntry("um_sinkmound_rock", "um_sinkmound", "um_sinkmound_gem", "full", {
    "um_gemology_geode_sink",
    "rocks",
    "flint",
    "twigs",
    "cutgrass",
    "foliage",
    "spider",
    "rabbit",
    "mole",
    "worm",
    "catcoon",
    "slurtle",
    "snurtle",
    "spider_warrior",
    "spider_spitter",
    "spider_hider",
    "spider_dropper",
    "slurper",
})
CreateGemSourceEntry("um_sinkmound_rock_gemless", "um_sinkmound", "um_sinkmound_gemless", "full",
    {
        "rocks",
        "flint",
        "twigs",
        "cutgrass",
        "foliage",
        "spider",
        "rabbit",
        "mole",
        "worm",
        "catcoon",
        "slurtle",
        "snurtle",
        "spider_warrior",
        "spider_spitter",
        "spider_hider",
        "spider_dropper",
        "slurper"
    })

--lobster rock
CreateGemSourceEntry("um_rocklobster_rock", "um_rocklobster_rock", "um_rocklobster_rock", "full", {
    "rocks",
    "flint",
    "goldnugget",
    "um_gemology_geode_lobster",
    "rocky"
})

--glass
--slightly different...
dataset["um_moonglass_ceiling"] = {
    name = "um_moonglass_ceiling",
    tex = "um_moonglass_ceiling.tex",
    type = "thing",
    prefab = "um_moonglass_ceiling",
    build = "um_moonglass_ceiling",
    subcat = "gemology",
    bank = "um_moonglass_ceiling",
    anim = "full",
    deps = { "um_gemology_geode_glass" }
}
scrapbook_prefabs["um_moonglass_ceiling"] = true

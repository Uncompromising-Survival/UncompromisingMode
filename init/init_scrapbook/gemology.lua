local env = env
GLOBAL.setfenv(1, GLOBAL)

local GEM_DEFS = require("gemology_defs").GEM_DEFS
local scrapbook_prefabs = require("scrapbook_prefabs")
local dataset = require("screens/redux/scrapbookdata")
local UpvalueHacker = require("tools/upvaluehacker")

require("um_gemology_geode_defs")
require("simutil")

--strings todo: move this somewhere else?
STRINGS.SCRAPBOOK.CATS.GEMOLOGY = "Gemology"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGYGEM = "Strange Gem"
STRINGS.SCRAPBOOK.SUBCATS.GEODE = "Geode"
STRINGS.SCRAPBOOK.SUBCATS.GEMOLOGY = "Gemology"

STRINGS.SCRAPBOOK.SPECIALINFO.GEMOLOGY_FORGE = "A forge found in the heart of the Magma Caves capable of enchanting tools and weapons with Strange Gems to amplify them with special effects.\n\nGem effects fade with usage."
STRINGS.SCRAPBOOK.SPECIALINFO.GEMOLOGY_GEM = "Can be used at a " .. STRINGS.NAMES.UM_GEMOLOGYFORGE .. " to apply a special effect to a Tool or Weapon depending on the quality of the gem.\n\nGem Effects:\n\n"


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
local function GetKnownNameFromGem(name)
    local color = "DEFAULT"

    if string.find(recipe_type, "um_gemology") ~= nil then --just UM has the color stuff idk if any addons will apply, so we'll use the default.
        color = string.upper(string.gsub(string.gsub(recipe_type, "um_gemology", ""), "gem%d", ""))
    end

    return TheMineralLogbook:IsGemKnown(name) and STRINGS.NAMES[name] or STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN[color] 
end


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
        notes = { gemology_gem = true }, --this will handles wheter to dynamically adjust description/name based on the mineral logbook.
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

--    TheScrapbookPartitions:DebugUnlockEverything()

local env = env
GLOBAL.setfenv(1, GLOBAL)

STRINGS.SCRAPBOOK.SUBCATS.VETERANSCURSE = "Veteran's Curse"
STRINGS.SCRAPBOOK.SUBCATS.UM_DEBUG = "Debug/Additions"

local debug = true

local scrapbook_prefabs = require("scrapbook_prefabs")
local scrapbookdata = require("screens/redux/scrapbookdata")
local um_scrapbookdata = require("um_scrapbookdata")

--code-driven data additions
--------------------- CRAB CLAW GEMS ----------------------------------
local crabclaw_gem_colours = {
    red = 1,
    blue = 1,
    purple = 1.25,
    yellow = 2,
    green = 2,
    orange = 2,
    opalprecious = 2
}

for k, v in pairs(crabclaw_gem_colours) do
    um_scrapbookdata[k .. "gem_cracked"] = {
        name = k .. "gem_cracked",
        tex = k .. "gem_cracked.tex",
        type = "item",
        prefab = k .. "gem_cracked",
        finiteuses = v * 200,
        subcat = "veteranscurse",
        build = "gems",
        bank = "gems",
        anim = (k == "opalprecious" and "opal" or k) .. "gem_idle",
        hungervalue = 2.5,
        healthvalue = 0,
        sanityvalue = 0,
        foodtype = "ELEMENTAL",
        deps = { k .. "gem", "crabclaw" }
    }
end



--------------------- TURFS ----------------------------------
local turfs = {
    um_hotspring_grass = { "twigs", "ice" },
    um_magma = { "rocks", "firenettles_dried" },
    um_hotspring_whiterock = { "rocks", "marble" },
    um_hotspring_yellowrock = { "rocks", "nitre" },
    magma_grass = { "rocks", "firenettles" },
    hoodedfoliage = { "cutgrass", "seeds" },
    hoodedfoliage_dark = { "twigs", "seeds" },
    hoodedmoss = { "twigs", "um_moss" },
    ancienthoodedturf = { "turf_hoodedmoss", "moonrocknugget" },
}

for name, deps in pairs(turfs) do
    local data = {
        name = "turf_" .. name,
        tex = "turf_" .. name .. ".tex",
        subcat = "turf",
        type = "item",
        prefab = "turf_" .. name,
        stacksize = 20,
        build = "hfturf",
        bank = "hfturf",
        anim = name,
        fueltype = "BURNABLE",
        fuelvalue = 7.5,
        burnable = true,
        deps = ConcatArrays({ "turfcraftingstation" }, deps),
        specialinfo = "TURF"
    }

    um_scrapbookdata["turf_" .. name] = data
end



--------------------- UM PREPARED FOODS ----------------------------------
local um_preparedfoods = require("um_preparedfoods")


local offset_required = {
    "beefalowings",
    "blueberrypancakes",
    "californiaking",
    "simpsalad",
    "snowcone"
}

for k, v in pairs(um_preparedfoods) do
    local data = {
        name = k,
        tex = k .. ".tex",
        type = "food",
        prefab = k,
        stacksize = 40,
        hungervalue = v.hunger,
        healthvalue = v.health,
        sanityvalue = v.sanity,
        foodtype = v.foodtype,
        build = k,
        bank = k,
        use_bg = false,
        anim = k == "theatercorn" and "ground" or "idle",
        perishable = v.perishtime,
        burnable = true,
        deps = v.warly_only and { "spoiled_food", "portablecookpot" } or { "spoiled_food", "cookpot", "portablecookpot", "archive_cookpot" }
    }

    if table.contains(offset_required, k) then
        data.animoffsetx = 70
        data.animoffsety = -70
    end

    um_scrapbookdata[k] = data
end



--------------------- ADDING TO VANILLA SCRAPBOOK ----------------------------------
for name, data in pairs(um_scrapbookdata) do
    if debug then
        --so we can easily search all UM entries.
        data.subcat = "um_debug"
    end

    scrapbook_prefabs[name] = true
    scrapbookdata[name] = data
end



--------------------- STRINGS & SPECIAL INFO ----------------------------------
local S = STRINGS.SCRAPBOOK.SPECIALINFO
local N = STRINGS.NAMES

-- KEEP IN SYNC WITH PREFABS/FEATHER_FROCK
local feather_defs = {
    FEATHER_ROBIN = {
        damage = 20,
        damage_reduction = 5,
        effect = "Ignites attackers."
    },
    FEATHER_ROBIN_WINTER = {
        damage = 40,
        damage_reduction = 7,
        effect = "No special effect."
    },
    FEATHER_CROW = {
        damage = 20,
        damage_reduction = 5,
        effect = "Slows downs attackers by 30% for 5 seconds."
    },
    FEATHER_CANARY = {
        damage = 30,
        damage_reduction = 7,
        effect = "Shocks attackers."
    },
    GOOSE_FEATHER = {
        damage = 10,
        damage_reduction = 15,
        effect = "Spawns circling mini-tornadoes."
    },
    MALBATROSS_FEATHER = {
        damage = 50,
        damage_reduction = 10,
        effect = "+100% speed and +1 second speed duration."
    }
}


local specinfo = {
    -- Tooltips for UM stuff. Usually more in-depth tooltips. TODO MOST OF THESE ARE JUST TOOLTIPS. PLEASE ADD DETAIL
    RAT_WHIP = "Stronger when the user is well fed.",
    AIR_CONDITIONER = "Can crush up Mushrooms for helpful stat clouds.",
    ANCIENT_AMULET_RED = "Drops soul orbs when attacked, which will replenish lost health when picked up.\nRevives players when haunted.",
    ARMOR_GLASSMAIL = "Summons spinning Glass Shards when attacking enemies. Loses shards when damage is taken.",
    SALTPACK = "Drops piles of salt, clearing and preventing further buildup of Snow Piles.",
    SPOREPACK = "An 12 slot container that doubles the speed of food spoiling inside, but refreshes spores.",
    UM_BEAR_TRAP_EQUIPPABLE_TOOTH = "Slows down anything it's attached to.\nDeployable and throwable.",
    UM_BEAR_TRAP_EQUIPPABLE_GOLD = "Slows down anything it's attached to.\nDeployable and throwable.",
    HAT_RATMASK = "Finds rat burrows\nShows sources of unwanted attention.",
    SKULLCHEST_CHILD = "Shares its contents with other Skull Chests.",
    SNOWGOGGLES = "Grants protection against Snow Storms / Sand Storms when worn.",
    GASMASK = "Provides protection against spore clouds, smog and hayfever.",
    PLAGUEMASK = "Provides protection against spore clouds, smog and hayfever.",
    FLORAL_BANDAGE = "Heals 45 health. Restores extra health over time.",
    DISEASECUREBOMB = "Fertilizes plants and get those ready for harvest.",
    SLUDGE_OIL = "Multi-use fuel for fires and lanterns alike.",
    ARMOR_SHARKSUIT_UM = "Works as electrical insulation.\nWearer will wash ashore with no penalties.",
    HAT_CRAB = "Repairs & sewing are twice as effective when worn.",
    HAT_CRAB_ICE = "Resistance scales with wetness.\nPrevents the wearer from drying up.",
    ARMOR_CRAB_MAXHP = "Increases maximum health when worn.",
    ARMOR_CRAB_REGEN = "Self-healing.",
    UM_ARMOR_PYRE_NETTLES = "Damages nearby enemies by touching them, and you when equipping.\nIgnores tiny, shadow, or fire-aligned creatures.\nSpoils a little when equipping.",
    WIXIEPUZZLE = "Part of something larger. External help is required to unlock its secrets.",
    CURSED_ANTLER = "Deals 66 damage and area damage when charged.",
    CRYSTAL_CURSED_ANTLER = "Deals 116 planar damage, area damage and creates a slowing freeze aura on hit when charged.",
    BEARGERCLAW = "Launches boulders at the target, creating a temporary sinkhole. Launching boulders again over the sinkhole launches 1 large boulder dealing 60 damage.\nAlso works as a shovel.",
    SLOBBERLOBBER = "Spits a magma blob that splits into 4 magma pools on impact. Magma pools deal fire damage and slow enemies.",
    FEATHER_FROCK = "Can store a feather inside, which grants different effects, flat damage reduction per feather when attacked and +50% speed for 1.5 seconds.\n\n",
    GORE_HORN_HAT = "Walking in a straight line builds up into a charge, gradually increasing speed up to +50% and dealing damage when crashing into creatures.",
    KLAUS_AMULET = "Causes attacks to swing twice in quick succession. The second hit deals 75% of the damage, but does not use durability.",
    CRABCLAW = "Can have up to 4 gems socketed, each  gem has a different effect; alternatively, it can have up to 4 Strange Gems socketed. Each gem socketed increases damage by 5.",
    SILKSACK = "Holds 9 items. Can wrap up to 6 items with Silk into a Silken Bundle.\nPassively spins Silk.",
    SILKEN_BUNDLE = S.BUNDLE .. "\nDoes not preserve food.",
    VETERANSHRINE = "Interact with this to recieve the Veteran's Curse.\n\nThe curse will grant each character an unique afliction, but also allows the cursee to wield powerful Cursed items, dropped by bosses.",
    MOONMAW_DRAGONFLY = "Appears under the light of the full \"Moon\" in Summer.",
    HOODEDWIDOW = "Appears to defend its Cocoons.",
    WIDOWSGRASP = "Can cut open Cocoons.",
    WIDOWSHEAD = "Grants night vision when worn.",
    WEBBEDCREATURE = "Contains a variety of different creatures",
    UM_MOONFLY_LANTERN = "Increase movement speed by 15% when held. Creates a light.\nCreates a trail of particles that create light and speed up survivors by an additional 15%.",
    SNAILDRAKEHAT = "Provides 75% resistance to fire.",
    SNAILDRAKEBUCKET = "Can hold water or lava.\nWater can be used to water crops in an area. Lava can be dumped to create a burning pool.",
    BOULDER_CRAB = "Appears under boulders. Mine its boulder to be able to properly it.\nBoulder will regrow if left alive.",
    UM_ASTRAL_PROJECTOR = "Projects your body to the nearest receptionator.",
    UM_ASTRAL_PROJECTOR_TARGET = "Returns your body back to the projectinator.",
    UM_SPONGEPLANT = "Must be shaved to harvest.",
    UM_SPONGEPLANT_ITEM = "Reduces moisture by 10 when eaten.",
    GIANT_TREE = S.WATERTREEPILLAR .. "\n\nCan be shaved for Moss.",
    GIANT_BLUEBERRY = "Increases moisture by 5 when eaten.",
    UM_BOOMBERRY_BOMB = "Creates a slowing puddle of goo.",
    UM_HAT_LEAFWING = "Increases speed by 15% when worn.\nNegates movement speed reductions.",
    UM_FERN_FOX = "Makes nearby plants grow considerably faster.",
    FRUITBAT = "Feasts on insects.",
    JAWED_SCYTHE = "More uses when reaping.",
    UM_ARMOR_BRAMBLE_RIMEWEED = "This thorny husk deals its damage and freezes its surroundings when attacked.",
    UM_RIMEWEED_ICEPACK = "Heals 30 health. Decreases temperature when used.",
    RIMEWEED_WHIP = "Freezes on hit.",
    SNOWPILE = "Builds up during snow storms.",
    UM_HAT_RIME = "Protection scales with wearer temperature.",
    UM_ICE_SICLE = "More uses when reaping. Freezes on hit, cools down the user when reaping.",
    RIMEWEED_MAIN = "Creates Rimeweed Brambles in the area, ensnaring nearby plants.\n\nWhen fully grown, creates a perpetual snow storm around itself.",
    UM_FIRECREAM = "Heals 15 health.\n\nProvides 100% resistance to fire, and immunity to Pyre Nettles for 8 minutes.",
    UM_FLAMEBURSTER = "Load it with a variety of fiery or chilly items to spew flames when used.",
    UM_HAT_PEPPERDRAGON = "Reverses temperature gain.",
    UM_PYRE_NETTLES = "Touching this plant is not a good idea.",
    UM_PYRITE_CEILING = "Rains down Pyrite during earthquakes.",
    UM_HAT_BEE_MOON = "Ocassionally releases Carrion Bees",
    UM_EYEBALM = "Heals 8 health.\n\nProvides protection against storms for 8 minutes.",
    UM_BACKPACK_AMULETUSE = "Holds 9 items. Putting an amulet in the dedicated amulet slot equips and empowers them."
}



for k, v in pairs(specinfo) do
    S[k] = v
end

for k, v in pairs(feather_defs) do
    S.FEATHER_FROCK = S.FEATHER_FROCK .. N[k] .. ": " .. v.damage .. " damage, " .. v.damage_reduction .. " flat damage reduction.\n" .. v.effect .. "\n\n"
end

local crabclaw_gem_desc = {
    red = "+0.2 health on hit.",
    blue = "+0.1 coldness inflected on hit.",
    purple = "+10% chance to spawn a shadow tentacle on hit.",
    yellow = "+0.2 sanity on hit",
    green = "20% chance to not use gem durability.",
    orange = "-20% movement speed inflected on hit.",
    opalprecious = "+1 gem effect for each socketed gem."
}

for k, v in pairs(crabclaw_gem_desc) do
    S[string.upper(k) .. "GEM_CRACKED"] = "When socketed on a Crab Claw: " .. v
end

if env.GetModConfigData("monstersmallmeat") then
    local monster_meat_replace = {
        "rabbit",
        "spider",
        "molebat",
        "bat",
        "cookiecutter",
        "aphid"
    }

    local replacement_map = {
        monstermeat = "monstersmallmeat",
        cookedmonstermeat = "cookedmonstersmallmeat"
    }

    for _, critter in ipairs(monster_meat_replace) do
        local new_deps = {}

        for k, v in pairs(scrapbookdata[critter].deps) do
            if replacement_map[v] ~= nil then
                table.insert(new_deps, replacement_map[v])
            else
                table.insert(new_deps, v)
            end
        end

        scrapbookdata[critter].deps = new_deps
    end
end

for k, v in pairs(scrapbookdata) do
    if v.name == nil then
        print("WARNING: \"" .. k .. "\" has no name!")
    elseif v.name ~= nil and STRINGS.NAMES[string.upper(v.name)] == nil then
        print("WARNING: \"" .. k .. "\" has no name in STRINGS.NAMES!")
    elseif v.name ~= nil and STRINGS.NAMES[string.upper(v.name)] ~= nil and type(STRINGS.NAMES[string.upper(v.name)]) ~= "string" then
        print("DEBUG: \"" .. k .. "\" has a name in STRINGS.NAMES that is not a string.")
    end
end

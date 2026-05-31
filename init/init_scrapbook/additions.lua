local env = env
GLOBAL.setfenv(1, GLOBAL)

STRINGS.SCRAPBOOK.SUBCATS.VETERANSCURSE = "Veteran's Curse"

local scrapbook_prefabs = require("scrapbook_prefabs")
local scrapbookdata = require("screens/redux/scrapbookdata")
local um_scrapbookdata = require("um_scrapbookdata")

for name, data in pairs(um_scrapbookdata) do
    if data.name == nil or data.name ~= nil and STRINGS.NAMES[string.upper(data.name)] == nil then
        print("WARNING! \"" .. name .. "\" has no name in strings")
    end
    if data.type ~= "item" then
        data.use_bg = true -- automatically adds the inv icon BG.
    end
    scrapbook_prefabs[name] = true
    scrapbookdata[name] = data
end

for name, data in pairs(scrapbookdata) do
    if data.name == nil or data.name ~= nil and STRINGS.NAMES[string.upper(data.name)] == nil then
        print("WARNING! \"" .. name .. "\" has no name in strings")
    end
    if data.name ~= nil and type(STRINGS.NAMES[string.upper(data.name)]) ~= "string" then
        print("DEBUG: \"" .. name .. "\" has non-string name in strings")
    end
end

local S = STRINGS.SCRAPBOOK.SPECIALINFO
STRINGS.SCRAPBOOK.DATA_INFINITE_USES = "Infinite"

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
    SALTPACK = "Drops piles of salt, preventing buildup of Snow Piles.",
    SPOREPACK = "An 12 slot container that doubles the speed of food spoiling inside.",
    UM_BEAR_TRAP_EQUIPPABLE_TOOTH = "Slows down anything it's attached to.\nDeployable and throwable.",
    UM_BEAR_TRAP_EQUIPPABLE_GOLD = "Slows down anything it's attached to.\nDeployable and throwable.",
    HAT_RATMASK = "Finds rat burrows\nShows sources of unwanted attention.",
    SKULLCHEST_CHILD = "Shares its contents with other Skull Chests.",
    SNOWGOGGLES = "Grants protection against Snow Storms / Sand Storms when worn.",
    GASMASK = "Provides protection against spore clouds, smog and hayfever.",
    PLAGUEMASK = "Provides protection against spore clouds, smog and hayfever.",
    FLORAL_BANDAGE = "Restores extra health over time.",
    UM_RIMEWEED_ICEPACK = "Cools the user down.",
    DISEASECUREBOMB = "Fertilizes plants and get those ready for harvest.",
    SLUDGE_OIL = "Multi-use fuel for fires and lanterns alike.",
    ARMOR_SHARKSUIT_UM = "Works as electrical insulation.\nWearer will wash ashore with no penalties.",
    HAT_CRAB = "Repairs & sewing are twice as effective when worn.",
    HAT_CRAB_ICE = "Resistance scales with wetness.\nPrevents the wearer from drying up.",
    ARMOR_CRAB_MAXHP = "Increases maximum health when worn.",
    ARMOR_CRAB_REGEN = "Self-healing.",
    UM_ARMOR_PYRE_NETTLES = "Panics and damages nearby miscreants.\nIgnores tiny, shadow, or fire-aligned creatures.",
    WIXIEPUZZLE = "Part of something larger. External help is required to unlock its secrets.",
    CURSED_ANTLER = "Deals 66 damage and area damage when charged.",
    BEARGERCLAW = "Launches boulders at the target, creating a temporary sinkhole. Launching boulders again over the sinkhole launches 1 large boulder dealing 60 damage.\nAlso works as a shovel.",
    SLOBBERLOBBER = "Spits a magma blob that splits into 4 magma pools on impact. Magma pools deal fire damage and slow enemies.",
    FEATHER_FROCK = "Can store a feather inside, which grants different effects, flat damage reduction per feather when attacked and +50% speed for 1.5 seconds.\n\n",
    GORE_HORN_HAT = "Walking in a straight line builds up into a charge, gradually increasing speed up to +50% and dealing damage when crashing into creatures.",
    KLAUS_AMULET = "Causes attacks to swing twice in quick succession. The second hit deals 75% of the damage, but does not use durability.",
    CRABCLAW = "Can have up to 4 gems socketed, each  gem has a different effect; alternitively, it can have up to 4 Strange Gems socketed. Each gem socketed increases damage by 5.",

}


for k, v in pairs(specinfo) do
    S[k] = v
end

for k, v in pairs(feather_defs) do
    S.FEATHER_FROCK = S.FEATHER_FROCK .. N[k] .. ": " .. v.damage .. " damage, " .. v.damage_reduction .. " flat damage reduction.\n" .. v.effect .. "\n\n"
end

local crabclaw_gem_colours = {
    red = "+0.2 health on hit.",
    blue = "+0.1 coldness inflected on hit.",
    purple = "+10% chance to spawn a shadow tentacle on hit.",
    yellow = "+0.2 sanity on hit",
    green = "20% chance to not use gem durability.",
    orange = "-20% movement speed inflected on hit.",
    opalprecious = "+1 gem effect for each socketed gem."
}

for k, v in pairs(crabclaw_gem_colours) do
    S[string.upper(k).."GEM_CRACKED"] = "When socketed on a Crab Claw: " .. v
end

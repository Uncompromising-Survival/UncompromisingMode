--Just defining some commonly used strings here.
local STRINGS = GLOBAL.STRINGS
local SPECIALINFO = STRINGS.SCRAPBOOK.SPECIALINFO
local TOOLTIP = STRINGS.UNCOMP_TOOLTIP

--Damnit klei.
--Sets the scrabookdata specialinfo of some entries to something else. These entries re-use something else.
local scrapbookdata = require("screens/redux/scrapbookdata")

local specialinfo_ovewrite = {
    blowdart_fire = "BLOWDART_FIRE",
    turf_dragonfly = "TURF_DRAGONFLY",
    premiumwateringcan = "PREMIUMWATERINGCAN",
    wall_dreadstone = "WALL_DREADSTONE"
}
--define the original special info to the new one so it isn't an overwrite
SPECIALINFO.BLOWDART_FIRE = SPECIALINFO.REDSTAFF
SPECIALINFO.TURF_DRAGONFLY = SPECIALINFO.TURF
SPECIALINFO.PREMIUMWATERINGCAN = SPECIALINFO.WATERINGCAN
SPECIALINFO.WALL_DREADSTONE = SPECIALINFO.WALLS

--then change the special info.
for k, v in pairs(specialinfo_ovewrite) do
    scrapbookdata[k]["specialinfo"] = v
end
 
--helper function to format tooltip strings into scrapbook special info.
-- Turns "- Text.\n- like this."
-- into "Text. Like this."
---@param tooltip string
local function ParseTooltip(tooltip)
    if tooltip ~= nil then
        local str = string.gsub(tooltip, "[\n- ]", " ")
        str = string.gsub(str, "- ", "")
        return str
    end
    print("tooltip failed to create scrapbook data!")
end

--Adds extra text with a UM prefix to a scrapbook page's special info
--keep in mind that entry ~= prefab name.
--overwrite removes the previous special info
---@param page string
---@param info string
---@param overwrite? boolean
local function AddAddtionalScrapbookInfo(page, info, overwrite)
    if string.match(page, "ITEM") ~= nil or string.match(page, "KIT") ~= nil then return end -- only show for the actual buildings, not kit/item versions.
    if SPECIALINFO[page] ~= nil then
        if overwrite then
            SPECIALINFO[page] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        else
            SPECIALINFO[page] = SPECIALINFO[page] .. "\n\n󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        end
    else --add the specialinfo
        SPECIALINFO[page] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
    end
end

for k, v in pairs(TOOLTIP) do --automatically add special scrabook info based on tooltips. Not all of these work.
    AddAddtionalScrapbookInfo(k, ParseTooltip(v))
end


--A table containing all types of statues... I wonder if I could do something to include every single one without having to manually list them...
local statues = {
    "HORNUCOPIA",
    "PIPE",
    "ANCHOR",
    "PAWN",
    "ROOK",
    "KNIGHT",
    "BISHOP",
    "MUSE",
    "FORMAL",
    "DEERCLOPS",
    "BEARGER",
    "MOOSEGOOSE",
    "DRAGONFLY",
    "MINOTAUR",
    "TOADSTOOL",
    "BEEQUEEN",
    "KLAUS",
    "ANTLION",
    "STALKER",
    "MALBATROSS",
    "CRABKING",
    "BUTTERFLY",
    "MOON",
    "GUARDIANPHASE3",
    "EYEOFTERROR",
    "TWINSOFTERROR",
    "CLAYHOUND",
    "CLAYWARG",
    "CARRAT",
    "BEEFALO",
    "KITCOON",
    "CATCOON",
    "MANRABBIT",
    "DAYWALKER",
}

local crops =
{
    "asparagus",
    "carrot",
    "corn",
    "dragonfruit",
    "durian",
    "eggplant",
    "garlic",
    "onion",
    "pepper",
    "pomegranate",
    "potato",
    "pumpkin",
    "tomato",
    "watermelon",
}

--Adds special info for every actual statue. The tooltip adds for the chesspiece_thing_builder which is the recipe, but chesspiece_thing is the actual prefab on the scrabook
for k, v in pairs(statues) do
    AddAddtionalScrapbookInfo("CHESSPIECE_" .. v, "No longer has collision.")
end

for k, v in pairs(crops) do
    AddAddtionalScrapbookInfo(string.upper(v) .. "_OVERSIZED", "No longer has collision.")
    AddAddtionalScrapbookInfo("FARM_PLANT_" .. string.upper(v), "No longer grows in Winter.")
end

--additional scrabookdata.
--this table contains extra things, also used for stuff that the tooltip prefab ~= scrapbook. Additionally supports overwrites.
--example:
--REDAMULET = {"string", bool} --wherein bool can be ommited unless you're overwriting.
local clockwork_str = "No longer flameable, additionally, does not panic from fires."
local um_specialinfo = {
    --TOOLTIPS - these are the stuff that have tooltips that either require overwrites or due to different key/prefab names need to be manually defined.
    REDAMULET = { ParseTooltip(TOOLTIP.AMULET), true },
    PURPLESTAFF = "Can select its destination if multiple foci are avaible. Increased uses.",
    WINONABATTERYLOW = ParseTooltip(TOOLTIP.WINONA_BATTERY_LOW),
    WINONABATTERYHIGH = ParseTooltip(TOOLTIP.WINONA_BATTERY_HIGH),
    STAFFTORNADO = ParseTooltip(TOOLTIP.STAFF_TORNADO),
    ARMORSANITY = ParseTooltip(TOOLTIP.ARMOR_SANITY),
    PUMPKINGLANTERN = ParseTooltip(TOOLTIP.PUMPKIN_LANTERN),
    WALLS = ParseTooltip(TOOLTIP.WALL_STONE_ITEM),
    WALL_DREADSTONE = ParseTooltip(TOOLTIP.WALL_DREADSTONE_ITEM),
    BOATCANNON = ParseTooltip(TOOLTIP.BOAT_CANNON_KIT),
    TELEBASE = { "No longer requires gems per teleport. Acts as one of the possible destinations for Telelocator Staves.\nMay be renamed with a Feather Pencil.", true },

    --Other stuff TODO TODO TODO
    DRAGONFLY = "No longer drops scales mid-fight, instead drops all 3 on death.",
    SHIELDOFTERROR = "Negative food stats no longer contribute for repairs.\nIncreased stats.",
    KNIGHT = clockwork_str,
    BISHOP = clockwork_str,
    ROOK = clockwork_str,
    KNIGHT_NIGHTMARE = clockwork_str,
    BISHOP_NIGHTMARE = clockwork_str,
    ROOK_NIGHTMARE = clockwork_str,
    MUSHROOMLIGHT = "Keeps its contents fresh forever.",
    CATCOON = "Faster attacked speed and more fair leap attacks, with a telegraph. Increased health.",
    ICEHOUND = "Freezes targets on bite.",
    FIREHOUND = "Ignites targets on bite.",
    SPIDER = "Now leaps.",
    MUTATEDHOUND = "Faster and stronger.",
    TOADSTOOL = "Drops all Shroom Skin on death.",
    LUREPLANT = "No longer has collision.",
    SPIDERDEN = "No longer has collision.",
    MOSQUITO = "Gets a special look during Spring.",
    WOBYBIG = "Can be commanded to do several tasks, such as picking items, harvesting, getting attention of creatures, and digging when big.",
    CRITTERDEN = "Hides a nasty surprise.",
    KOALEFANT_SUMMER = "Has several new attacks. Increased health.",
    KOALEFANT_WINTER = "Has several new attacks. Increased health.",
    PIGKING = "Can be given any food with 75 or more hunger points to hire nearby guards.",
    MARBLEBEAN = "Can be planted in rocky turf.",
    SPIDER_HEALER = "Reduced healing.",
    TERRARIUM = "When activated, targets the nearest player instead of a random one.",
    GRASSGECKO = "Now drops a Grass Tuft on death.",
    FROG = "Eats foods off the ground.",
    KLAUS = "Drops a Krampus Sack if defeated while enraged.",
    KLAUS_SACK = "Stores all of Krampii's stolen loot.",
    KRAMPUS = "Better at stealing items. Has a new attack.\nAll stolen items are stored inside the Loot Stash.",
    WATERPLANT = "Seedshells no longer create leaks.",
    ALTERGUARDIAN_PHASE1 = "Drops a blueprint.",
    LANTERN = "May be upgraded by a certain survivor.",
    MINERHAT = "May be upgraded by a certain survivor.",
    SHARK = "Deals less damage per bite.\nDrops a new resource.",
    SHADOW_KNIGHT = "Less attack range, but deals knockback.",
    SHADOW_BISHOP = "Attacks differently.",
    STINGER = "Self-stacks. Burnable as fuel.",
    SLURTLE = "Faster attack speed but less health.",
    SNURTLE = "Less health.",
    ARCHIVE_CENTIPEDE = "Releases Moon Gleams on death.",
    ANTLION = "May harrass survivors at sea.\nIncreased resistance against explosives.",
    BEEQUEEN = "Reworked fight. Several new attacks and bees.",
    MONKEY_MEDIUMHAT = "Increases boat steering speed.",
    EYEMASKHAT = "Negative food stats no longer contribute for repairs.",
    SPIDERHAT = "Works as goggles.",
    FOSSILSTALKER = "No longer has collision.",
    HOMESIGN = "No longer has collision.",
    PENGUIN = "Aggressive near its breeding ground.",
    CACTUS = "No longer grows in Winter.",
    BANANABUSH = "No longer grows in Winter.",
    MARSH_BUSH = "No longer grows in Winter.",
    ROCK_AVOCADO_BUSH = "No longer grows in Winter",
    CRAWLINGHORROR = "Drops shadow ink when teleporting.",
    TERRORBEAK = "More evasive, attempts to reposition itself to get an attack.",
    LAVAE = "Explodes after death.",
    DEERCLOPS = "Has 3 variants, each with unique attacks.",
    MOOSE = "Has new attacks.",
    BEARGER = "Has new attacks.",
    LEIF = "Has a new attack.",
    MINOTAUR = "Second phase has been reworked.",
    PIGMAN = "Has a new attack.",
    WALRUS = "Makes use of Snap Traps.",
    BEEFALO = "Has a new attack.",
    SPIDERQUEEN = "Has a new attack.",
    EYEOFTERROR = "Has a new attack.",
    TWINOFTERROR1 = "Has new attacks, matching more closely to its source material.",
    TWINOFTERROR2 = "Has new attacks, matching more closely to its source material.",
    BUTTERFLY = "Immune to aura damage.",
    CRABKING = "Reworked fight.\nTakes damage from being rammed by boats, healing is interruped by cannons or by killing its claws. Main attack no longer creates leaks.",
}

--adds the addtional scrapbook info based on the table above.
for k, v in pairs(um_specialinfo) do
    if type(v) == "table" then
        AddAddtionalScrapbookInfo(k, v[1], v[2])
    else
        AddAddtionalScrapbookInfo(k, v)
    end
end


local um_deps = {
    moonbase = { "staff_moonfall", "opalpreciousgem" },
    telebase = { "featherpencil" },
    moondial = { "moon_tear" },
    klaus = { "krampus_sack", "klaus_amulet" },
    alterguardian_phase1 = { "blueprint" },
    lantern = { "winona_upgradekit_electrical" },
    minerhat = { "winona_upgradekit_electrical" },
    krampus = {"klaus_sack"}
}

for entry, deps in pairs(um_deps) do
    AddPrefabPostInit(entry, function(inst)
        if inst.scrapbook_adddeps == nil then
            inst.scrapbook_adddeps = {}
        end
        for k, v in pairs(deps) do
            table.insert(inst.scrapbook_adddeps, v)
        end
    end)
end

--scuffed, but the actual script is obfuscated, so i'm doing it via postinit.
local wixiethings = {
    "wardrobe",
    "clock",
    "piano"
}

for k, v in pairs(wixiethings) do
    AddPrefabPostInit("wixie_" .. v, function(inst)
        inst.scrapbook_thingtype = "POI"
        inst.scrapbook_specialinfo = "WIXIEPUZZLE"
        if not GLOBAL.TheNet:IsDedicated() then
            inst:AddComponent("pointofinterest")
            inst.components.pointofinterest:SetHeight(0)
        end
    end)
end

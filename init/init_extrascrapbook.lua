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
SPECIALINFO.BLOWDART_FIRE =  SPECIALINFO.REDSTAFF
SPECIALINFO.TURF_DRAGONFLY = SPECIALINFO.TURF
SPECIALINFO.PREMIUMWATERINGCAN = SPECIALINFO.WATERINGCAN
SPECIALINFO.WALL_DREADSTONE = SPECIALINFO.WALLS

--then change the special info.
for k,v in pairs(specialinfo_ovewrite) do
    scrapbookdata[k]["specialinfo"] = v
end

--helper function to format tooltip strings into scrapbook special info.
-- Turns "- Text.\n- like this."
-- into "Text. Like this."
---@param tooltip string
local function ParseTooltip(tooltip)
    local str = string.gsub(tooltip, "[\n- ]", " ")
    str = string.gsub(str, "- ", "")
    return str
end

--Adds extra text with a UM prefix to a scrapbook page's special info
--keep in mind that entry ~= prefab name.
--overwrite removes the previous special info
---@param page string
---@param info string
---@param overwrite? boolean
local function AddAddtionalScrapbookInfo(page, info, overwrite)
	if string.match(page, "ITEM") ~= nil or string.match(page, "KIT") ~= nil then  return end -- only show for the actual buildings, not kit/item versions.
	if SPECIALINFO[page] ~= nil then
        if overwrite then
            SPECIALINFO[page] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        else
            SPECIALINFO[page] = SPECIALINFO[page] .. "\n\n󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        end
	else--add the specialinfo
        SPECIALINFO[page] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
    end
end

for k,v in pairs(TOOLTIP) do --automatically add special scrabook info based on tooltips. Not all of these work.
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

--Adds special info for every actual statue. The tooltip adds for the chesspiece_thing_builder which is the recipe, but chesspiece_thing is the actual prefab on the scrabook
for k,v in pairs(statues) do
    AddAddtionalScrapbookInfo("CHESSPIECE_"..v, "No longer has collision.")
end

--additional scrabookdata.
--this table contains extra things, also used for stuff that the tooltip prefab ~= scrapbook. Additionally supports overwrites.
--example:
--REDAMULET = {"string", bool} --wherein bool can be ommited unless you're overwriting.
local extrascrapbookdata = {
	--TOOLTIPS - these are the stuff that have tooltips that either require overwrites or due to different key/prefab names need to be manually defined.
    REDAMULET = {ParseTooltip(TOOLTIP.AMULET), true},
    PURPLESTAFF = {"Can select its destination if multiple foci are avaible. Increased uses."},
    WINONABATTERYLOW = {ParseTooltip(TOOLTIP.WINONA_BATTERY_LOW)},
	WINONABATTERYHIGH = {ParseTooltip(TOOLTIP.WINONA_BATTERY_HIGH)},
	STAFFTORNADO = {ParseTooltip(TOOLTIP.STAFF_TORNADO)},
	ARMORSANITY = {ParseTooltip(TOOLTIP.ARMOR_SANITY)},
	PUMPKINGLANTERN = {ParseTooltip(TOOLTIP.PUMPKIN_LANTERN)},
	WALLS = {"Provides protection from Snow Storms."},
	WALL_DREADSTONE = {ParseTooltip(TOOLTIP.WALL_DREADSTONE_ITEM)},
	BOATCANNON = {ParseTooltip(TOOLTIP.BOAT_CANNON_KIT)}
}

--adds the addtional scrapbook info based on the table above.
for k,v in pairs(extrascrapbookdata) do
    AddAddtionalScrapbookInfo(k, v[1], v[2])
end
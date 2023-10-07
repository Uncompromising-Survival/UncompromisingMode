local STRINGS = GLOBAL.STRINGS
local SPECIALINFO = GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO

--Damnit klei.
local scrapbookdata = require("screens/redux/scrapbookdata")
local specialinfo_ovewrite = {
    blowdart_fire = "BLOWDART_FIRE",
    turf_dragonfly = "TURF_DRAGONFLY",
    premiumwateringcan = "PREMIUMWATERINGCAN",
}
--so it isn't an overwrite
SPECIALINFO.BLOWDART_FIRE =  SPECIALINFO.REDSTAFF
SPECIALINFO.TURF_DRAGONFLY = SPECIALINFO.TURF
SPECIALINFO.PREMIUMWATERINGCAN = SPECIALINFO.WATERINGCAN

for k,v in pairs(specialinfo_ovewrite) do
    scrapbookdata[k]["specialinfo"] = v
end


local function ParseTooltip(tooltip)
    local str = string.gsub(tooltip, "[\n- ]", " ")
    str = string.gsub(str, "- ", "")
    return str
end

local function AddAddtionalScrapbookInfo(entry, info, overwrite)
	if SPECIALINFO[entry] ~= nil then
        if overwrite then
            SPECIALINFO[entry] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        else
            SPECIALINFO[entry] = SPECIALINFO[entry] .. "\n\n󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
        end
	else--add the specialinfo
        SPECIALINFO[entry] = "󰀕 Uncompromising Mode Changes 󰀕\n\n" .. info
    end
end

for k,v in pairs(STRINGS.UNCOMP_TOOLTIP) do
    AddAddtionalScrapbookInfo(k, ParseTooltip(v))
end

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

for k,v in pairs(statues) do
    AddAddtionalScrapbookInfo("CHESSPIECE_"..v, "No longer has collision.")
end

local extrascrapbookdata = {
    REDAMULET = {ParseTooltip(STRINGS.UNCOMP_TOOLTIP.AMULET), true},
    PURPLESTAFF = {"Can select its destination if multiple foci are avaible. Increased uses."},
    WINONABATTERYLOW = {ParseTooltip(STRINGS.UNCOMP_TOOLTIP.WINONA_BATTERY_LOW)},
	WINONABATTERYHIGH = {ParseTooltip(STRINGS.UNCOMP_TOOLTIP.WINONA_BATTERY_HIGH)},
	STAFFTORNADO = {ParseTooltip(STRINGS.UNCOMP_TOOLTIP.STAFF_TORNADO)},

}

for k,v in pairs(extrascrapbookdata) do
    AddAddtionalScrapbookInfo(k, v[1], v[2])
end
--Damnit klei.
local scrapbookdata = require("screens/redux/scrapbookdata")
local specialinfo_ovewrite = {
    blowdart_fire = "BLOWDART_FIRE",
    turf_dragonfly = "TURF_DRAGONFLY"
}

for k,v in pairs(specialinfo_ovewrite) do
    scrapbookdata[k]["specialinfo"] = v
end

local STRINGS = GLOBAL.STRINGS
local SPECIALINFO = GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO

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
    PURPLESTAFF = {"Can select its destination if multiple foci are avaible. Increased uses."}
}

for k,v in pairs(extrascrapbookdata) do
    AddAddtionalScrapbookInfo(k, v[1], v[2])
end
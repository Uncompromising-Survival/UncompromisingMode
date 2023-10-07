
local STRINGS = GLOBAL.STRINGS
local SPECIALINFO = GLOBAL.STRINGS.SCRAPBOOK.SPECIALINFO

local function ParseTooltip(tooltip)
    local str = string.gsub(tooltip, "[\n- ]", " ")
    str = string.gsub(str, "- ", "")
    return str
end

local function AddAddtionalScrapbookInfo(entry, info, overwrite)
    if entry == "AMULET" then
        entry = "REDAMULET" --what the fuck klei
        overwrite = true
    end

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

}
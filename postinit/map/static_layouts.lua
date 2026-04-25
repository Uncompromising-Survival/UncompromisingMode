local env = env
GLOBAL.setfenv(1, GLOBAL)

local static_layout = require("map/static_layout")

local _Get = static_layout.Get

local function Get(layoutsrc, additionalProps) -- Save our Archives
	local layout = _Get(layoutsrc, additionalProps)
	if additionalProps and additionalProps.areas and additionalProps.areas.archive_sound_area then -- Need a way to find the archive static layouts specifically
		layout.SafeFromDisconnect = true
	end
	return layout
end

static_layout.Get = Get


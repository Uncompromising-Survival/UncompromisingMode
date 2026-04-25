local env = env
GLOBAL.setfenv(1, GLOBAL)

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
local SORTED_FERTILIZERS = require("prefabs/fertilizer_nutrient_defs").SORTED_FERTILIZERS

FERTILIZER_DEFS.um_moss = {nutrients = {16, 0, 0}}

for fertilizer, data in pairs(FERTILIZER_DEFS) do
	if data.inventoryimage == nil then
		if data.atlas == nil then
			data.atlas = "images/inventoryimages/"..fertilizer..".xml"
		end

		data.inventoryimage = fertilizer..".tex"
	end

	if data.name == nil then
		data.name = string.upper(fertilizer)
	end

	if data.uses == nil then
		data.uses = 1
	end
end

local sort_order =
{
	"um_moss",
}

for i, v in ipairs(sort_order) do
	table.insert(SORTED_FERTILIZERS, v)
end

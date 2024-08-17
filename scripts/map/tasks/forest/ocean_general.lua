-- General Changes to Ocean (Mainly UTW prep)
AddRoomPreInit("OceanCoastal", function(room) room.contents.countprefabs = { ums_biometable = 1 } end)
AddRoomPreInit("OceanSwell", function(room) room.contents.countprefabs = { siren_teaser_picker = 1, ums_biometable = 1 } end)
AddRoomPreInit("OceanRough", function(room) room.contents.countprefabs = { siren_teaser_picker = 2 } end)


local ocean_deep =
{
	"OceanSwell",
	"OceanRough",
	"OceanHazardous"
}

for k, v in ipairs(ocean_deep) do
	AddRoomPreInit(v, function(room)
		if room.contents.distributeprefabs == nil then
			room.contents.distributeprefabs = {}
		end
		room.contents.distributeprefabs.oceanfishableflotsam_water = 0.15
	end)
end


local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
Layouts["utw_biomespawner"] = StaticLayout.Get("map/static_layouts/utw_biomespawner")
-- UMSS for Ocean
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.DEFAULT or tasksetdata.name == GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.CLASSIC then
		tasksetdata.ocean_prefill_setpieces["utw_biomespawner"] = { count = math.random(6, 9) }
	end
end)
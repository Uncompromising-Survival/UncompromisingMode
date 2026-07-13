-- All Worldgen Ruins Changes


-- Infest with PAWNS!
local pawnrooms = { "RuinedCity", "Vacant", "Barracks", "LabyrinthEntrance" }

local damagedpawnrooms = { "Labyrinth", "AtriumMazeEntrance" }

for i, room in ipairs(pawnrooms) do
	AddRoomPreInit(room, function(room)
		if room.contents == nil then
			room.contents = {}
		end
		if room.contents.distributeprefabs == nil then
			room.contents.distributeprefabs = {}
		end
		room.contents.distributeprefabs.pawn_hopper = 0.133
	end)
end

for i, room in ipairs(damagedpawnrooms) do
	AddRoomPreInit(room, function(room)
		if room.contents == nil then
			room.contents = {}
		end
		if room.contents.distributeprefabs == nil then
			room.contents.distributeprefabs = {}
		end
		room.contents.distributeprefabs.pawn_hopper_nightmare = 0.2
	end)
end

local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")

Layouts["skeleton_goo"] = StaticLayout.Get("map/static_layouts/skeleton_goo")
-- Add Skeleton Goo Tutorial
AddRoomPreInit("LabyrinthEntrance", function(room)
	if not room.contents.countstaticlayouts then
		room.contents.countstaticlayouts = {}
	end
	room.contents.countstaticlayouts["skeleton_goo"] = 1
end)
	
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
	
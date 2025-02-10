-- Mosaic Changes

local mosaic_rooms = { "BGNoise", "Rocky", "CritterDen", "Graveyard" }
-- Add "mosaic" room tag to all mosaic rooms
for k, v in pairs(mosaic_rooms) do
	AddRoomPreInit(v, function(room)
		if not room.tags then
			room.tags = { "mosaic" }
		elseif room.tags then
			table.insert(room.tags, "mosaic")
		end
	end)
end	

AddRoomPreInit("BGNoise", function(room)
	room.contents.countprefabs.ums_biometable = function() return math.random(0,2) end
end)

AddRoomPreInit("Graveyard", function(room)
	room.contents.countprefabs.ums_biometable = function() return math.random(0,1) end
end)

AddRoomPreInit("CritterDen", function(room)
	room.contents.countprefabs.ums_biometable = function() return math.random(0,1) end
end)
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
	room.contents.countprefabs.ums_biometable = function() return math.random(0,1) end
end)

AddRoomPreInit("Graveyard", function(room)
	room.contents.countprefabs.ums_biometable = function() return math.random(0,1) end
end)

AddRoomPreInit("CritterDen", function(room)
	room.contents.countprefabs.ums_biometable = function() return math.random(0,1) end
end)

if not GLOBAL.KnownModIndex:IsModEnabled("workshop-1467214795") then
	GLOBAL.require("map/rooms/forest/UM_optionalrooms")
	-- Rocky biome... going in this area...

	AddTask("UMMakeABeehat", { --AddTaskPreInit does not work for optional tasks, Redefine!
			locks={LOCKS.SPIDERS_DEFEATED,LOCKS.TIER1},
			keys_given={KEYS.BEEHAT,KEYS.GRASS,KEYS.TIER1},
			room_choices={
				--["Wormhole_Plains"] = 1,
				["Rocky_crabs"] = function() return 1 + math.random(GLOBAL.SIZE_VARIATION) end,
				["FlowerPatch"] = function() return math.random(GLOBAL.SIZE_VARIATION) end,
			},
			room_bg=WORLD_TILES.GRASS,
			background_room="BGGrass",
			colour={r=1,g=1,b=0.5,a=1}
		})
		
		
	AddTaskSetPreInitAny(function(tasksetdata)
		if tasksetdata.location ~= "forest" then
			return
		end
		for i,task in ipairs(tasksetdata.optionaltasks) do
			if task == "Make a Beehat" then
				tasksetdata.optionaltasks[i] = "UMMakeABeehat"
			end
		end
	end)
end
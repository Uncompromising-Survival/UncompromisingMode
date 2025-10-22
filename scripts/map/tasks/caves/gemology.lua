GLOBAL.require("map/rooms/caves/gemology")
AddTaskPreInit("RedForest", function(task)
    task.room_choices={
        ["RedMushForest"] = 1,
        ["RedSpiderForest"] = 1,
        ["RedMushPillars"] = 1,
        ["StalagmiteForest"] = 1,
        ["SpillagmiteMeadow"] = 1,
        ["PitRoom"] = 1,
		
		["RedMushForest_Petrified"] = 1,
		["RedSpiderForest_Petrified"] = 1,
    }
end)

AddTaskPreInit("GreenForest", function(task)
    task.room_choices={
        ["GreenMushForest"] = 1,
        ["GreenMushPonds"] = 1,
        ["GreenMushSinkhole"] = 1,
        ["GreenMushMeadow"] = 1,
        ["GreenMushRabbits"] = 1,
        ["GreenMushNoise"] = 1,
        ["PitRoom"] = 1,
		
		["GreenMushForest_Petrified"] = 1,
		["GreenMushRabbits_Petrified"] = 1,
    }
end)

AddTaskPreInit("BlueForest", function(task)
    task.room_choices={
        ["BlueMushForest"] = 1,
        ["BlueMushMeadow"] = 1,
        ["BlueSpiderForest"] = 1,
        ["DropperDesolation"] = 1,
		
		["BlueMushForest_Petrified"] = 1,
		["BlueSpiderForest_Petrified"] = 1,
    }
end)


-- Fungal Noise Forest [[ They are optional tasks, and need to be adjusted a different way, AddTaskPreInit will not work.
AddTask("FungalNoiseForest_Petrified",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.ROCKY },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["FungusNoiseForest"] = 2,
        ["RedMushForest"] = 1,
        ["BlueMushForest"] = 1,
        ["GreenMushForest"] = 1,
        ["PitRoom"] = 2,
		
		["FungusNoiseForest_Petrified"] = 1,
    },
    background_room="FungusNoiseMeadow",
    room_bg=WORLD_TILES.FUNGUS,
    colour={r=0.0,g=0.5,b=1.0,a=0.9},
})

-- Fungal Noise Meadow
AddTask("FungalNoiseMeadow_Petrified",{
    locks={ LOCKS.CAVE, LOCKS.TIER3, LOCKS.BATS },
    keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ENTRANCE_OUTER },
    room_choices={
        ["FungusNoiseMeadow"] = 1,
        ["SpillagmiteMeadow"] = 1,
        ["BlueMushMeadow"] = 1,
        ["GreenMushMeadow"] = 1,
        ["PitRoom"] = 2,
		
		["FungusNoiseMeadow_Petrified"] = 2,
    },
    background_room="FungusNoiseMeadow",
    room_bg=WORLD_TILES.FUNGUS,
    colour={r=0.0,g=0.5,b=0.8,a=0.9},
})

-- Bats
local batrooms = {"BatCave","BattyCave","FernyBatCave","BGBatCaveRoom"}

for i,v in ipairs(batrooms) do
	AddRoomPreInit(v, function(room) -- red
		room.contents.countprefabs = {um_guano_rock = math.random(1,4)} -- normally doesn't have countprefabs in this room
	end)
end

-- Rocky
local rockyrooms = {"RockyPlains","RockyHatchingGrounds"}

for i,v in ipairs(rockyrooms) do
	AddRoomPreInit(v, function(room) -- red
		room.contents.countprefabs = {um_rocklobster_rock = math.random(1,3)} -- normally doesn't have countprefabs in this room
	end)
end


AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location == "forest" then
		return
	end
	for i,task in ipairs(tasksetdata.optionaltasks) do
		if task == "FungalNoiseForest" then
			tasksetdata.optionaltasks[i] = "FungalNoiseForest_Petrified"
		end
		if task == "FungalNoiseMeadow" then
			tasksetdata.optionaltasks[i] = "FungalNoiseMeadow_Petrified"
		end
	end
end)
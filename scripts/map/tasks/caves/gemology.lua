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

--AXE Makeover the ruins entrance, firstly get rid of sparse optional tasks
AddTaskSetPreInitAny(function(tasksetdata)
	if tasksetdata.location ~= "caves" then
		return
	end

    --AXE Guarantee that the ruins will be as branched as possible...
	for i,task in ipairs(tasksetdata.optionaltasks) do
		if task == "Residential2" then
			table.remove(tasksetdata.optionaltasks,i)
		end
	end	
	for i,task in ipairs(tasksetdata.optionaltasks) do
		if task == "Residential3" then
			table.remove(tasksetdata.optionaltasks,i)
		end
	end
    table.insert(tasks,"Residential2")
end)



AddTaskPreInit("LichenLand", function(task)
    task.room_choices = {
        ["LichenLandMONKEY"] = 8,
        ["LichenLandHub"] = 1,
    }
    --task.hub_room = "LichenLandHub"
    task.entrance_room = "LichenLand"
end)

local residentials = {"","2","3"} --AXE Note that the first Residential biome isn't called Residential1.
for i,v in ipairs(residentials) do
	AddTaskPreInit("Residential"..v, function(task)
		task.room_choices["Vacant"] = 5 -- AXE Constistently a lot of monkeys...
	end)
end

local add_rocks_rooms = {"LichenLand","Vacant"}
for i,v in ipairs(add_rocks_rooms) do
    AddRoomPreInit(v, function(room) -- red\
        room.contents.distributeprefabs["um_slimestone_rock_gemless"] = 0.08
    end)
end

-- Fungal Noise Forest 
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
		room.contents.countprefabs = {
			um_guano_rock_gemless = function() return math.random(3,6) end,
			um_guano_rock = function() return math.random(1,2) end,
			um_guano_rain_node = 1,
		} -- normally doesn't have countprefabs in this room
	end)
end

-- Rocky
local rockyrooms = {"RockyPlains","RockyHatchingGrounds"}

for i,v in ipairs(rockyrooms) do
	AddRoomPreInit(v, function(room) -- red
		room.contents.countprefabs = {um_rocklobster_rock = math.random(1,3)} -- normally doesn't have countprefabs in this room
	end)
end



local function shuffle(arr)
	for i = 1, #arr - 1 do
		local j = math.random(i, #arr)
		arr[i], arr[j] = arr[j], arr[i]
	end
	return arr
end

local entrance_tasks = {}

for i = 1,10 do
	table.insert(entrance_tasks,i)
end

entrance_tasks = shuffle(entrance_tasks)

for i = 1,math.random(3,5) do
	AddTaskPreInit("CaveExitTask"..entrance_tasks[i], function(task)
		task.room_choices={
            ["CaveExitRoom"] = 1,
            ["AnimalHoles"] = 1,
        } --AXE redefining room_choices removes the old room combination in favor of the one that we add here to keep from adding a ton of new rooms.
	end)
end

local startrooms = {
    "RabbitArea",
    "RabbitTown",
    "RabbitSinkhole",
    "SpiderIncursion",
    "SinkholeForest",
    "SinkholeCopses",
    "SinkholeOasis",
    "GrasslandSinkhole",
    "GreenMushSinkhole",
    "GreenMushRabbits",
}

for i,v in ipairs(startrooms) do
	AddRoomPreInit(v, function(room)
		room.contents.distributeprefabs.um_sinkmound_rock = 0.01
		room.contents.distributeprefabs.um_sinkmound_rock_gemless = 0.25
	end)
end

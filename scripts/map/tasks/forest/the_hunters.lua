-- Infest Triple Mac with Ghosts

-- Trapdoor Spiders
if GetModConfigData("trapdoorspiders") then
	AddRoomPreInit("BGSavanna", function(room) -- Primarily affects beefalo plains and triple mac, lumping it into this modimport bc of its prevalence
		room.contents.countprefabs = { trapdoorspawner = function() return math.random(4, 5) end }
	end)
	AddRoomPreInit("Plain", function(room)                                                       -- This effects areas in the Major Beefalo Plains and the Grasslands next to the portal
		room.contents.countprefabs = { trapdoorspawner = function() return math.random(2, 4) end } -- returned number for whole area should be multiplied between 2-4 due to multiple rooms
	end)
end

if GetModConfigData("hoodedforest") then               -- Lock Everything Behind the Mod Config
    GLOBAL.require("map/rooms/forest/gianttreesrooms") 
	
	AddRoomPreInit("WalrusHut_Grassy", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
	AddRoomPreInit("WalrusHut_Rocky", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)


	AddTask("UMTheHunters", { -- Alternative tasks for whatever reason are not responsive to AddTaskPreInit.... So use AddTask as a workaround
			locks={LOCKS.ADVANCED_COMBAT,LOCKS.MONSTERS_DEFEATED,LOCKS.TIER4},
			keys_given={KEYS.WALRUS,KEYS.TIER5},
			room_choices={
			["WalrusGiantTrees"] = 3,
			["GiantTrees"] = 1,
			["BGSavanna"] = 2,
			["Rocky_crabs"] = 2,
			},
			room_bg=WORLD_TILES.HOODEDFOREST,
			background_room="BGGiantTrees",
			colour={r=0,g=1,b=0,a=1}
		})	
		
	AddTaskSetPreInitAny(function(tasksetdata)
		for i,task in ipairs(tasksetdata.optionaltasks) do
			if task == "The hunters" then
				tasksetdata.optionaltasks[i] = "UMTheHunters"
			end
		end
	end)

		

elseif GetModConfigData("ghostwalrus") ~= "disabled" then
	AddRoomPreInit("WalrusHut_Plains", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
	AddRoomPreInit("WalrusHut_Grassy", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
	AddRoomPreInit("WalrusHut_Rocky", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
end
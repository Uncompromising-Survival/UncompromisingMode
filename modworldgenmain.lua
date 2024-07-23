GLOBAL.require("map/terrain")
modimport("tiledefs")
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
local STRINGS = GLOBAL.STRINGS

------

if GetModConfigData("worldgenmastertoggle") then
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "forest" then
            return
        end

        if (tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED) then
            if GetModConfigData("hoodedforest") then
                table.insert(tasksetdata.tasks, "GiantTrees_IA")
            end
            return
        end

        if GetModConfigData("hoodedforest") then
            table.insert(tasksetdata.tasks, "GiantTrees")
        end
		
		
		--------- Magma Caves
		
		
        if GetModConfigData("rice") then
            table.insert(tasksetdata.required_prefabs, "riceplantspawnerlarge")
            table.insert(tasksetdata.required_prefabs, "riceplantspawner")
        end

        if GetModConfigData("wixie_walter") then
            table.insert(tasksetdata.required_prefabs, "wixie_wardrobe") -- Make sure wixie appears.
            table.insert(tasksetdata.required_prefabs, "wixie_clock")
            table.insert(tasksetdata.required_prefabs, "wixie_piano")
            table.insert(tasksetdata.required_prefabs, "charles_t_horse")
        end
		
		
		-- Touch Stones
		table.remove(tasksetdata.set_pieces["ResurrectionStone"].tasks,8)
		table.insert(tasksetdata.set_pieces["ResurrectionStone"].tasks,"Lightning Bluff")
		
		-- Wormholes
		table.remove(tasksetdata.set_pieces["WormholeGrass"].tasks,16)
		table.insert(tasksetdata.set_pieces["WormholeGrass"].tasks,"Lightning Bluff")
	
	
		-- New Badlands
		table.insert(tasksetdata.required_prefabs, "dragonfly_spawner")
		table.insert(tasksetdata.required_prefabs, "cave_entrance_magmabiome")
		
    end)
	
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "cave" then
            return
        end	
	if tasksetdata.required_prefabs then
		table.insert(tasksetdata.required_prefabs, "cave_exit_magmabiome")
	else
		tasksetdata.required_prefabs = {"cave_exit_magmabiome"}
	end
	
	table.insert(tasksetdata.tasks, "MagmaCaves")
	table.insert(tasksetdata.tasks, "MagmaCavesEntrance")
    end)
    Layouts["basefrag_smellykitchen"] = StaticLayout.Get("map/static_layouts/umss_basefrag_smellykitchen")
    Layouts["basefrag_rattystorage"] = StaticLayout.Get("map/static_layouts/umss_basefrag_rattystorage")
    Layouts["moonfrag"] = StaticLayout.Get("map/static_layouts/umss_moonfrag")
    Layouts["utw_biomespawner"] = StaticLayout.Get("map/static_layouts/utw_biomespawner")
    Layouts["impactfuldiscovery"] = StaticLayout.Get("map/static_layouts/umss_impactfuldiscovery")
    Layouts["boon_moonoil"] = StaticLayout.Get("map/static_layouts/umss_moonoil")
    Layouts["umss_biometable"] = StaticLayout.Get("map/static_layouts/umss_biometable")
	Layouts["boilingfields_dragonfly_arena"] = StaticLayout.Get("map/static_layouts/boilingfields_dragonfly_arena")
	Layouts["cave_entrance_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_entrance_magmabiome")
	Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
    AddTaskSetPreInitAny(function(tasksetdata)
        if tasksetdata.location ~= "forest" or (tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.VOLCANO or tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED) then
            return
        end

        tasksetdata.set_pieces["umss_biometable"] = {
            count = math.random(3, 5),
            tasks = {
                "Make a pick",
                -- "Dig that rock",
                "Great Plains",
                "Squeltch",
                "Beeeees!",
                "Speak to the king",
                "Forest hunters",
                "For a nice walk",
                "Badlands",
                "Lightning Bluff",
                "Befriend the pigs",
                "Kill the spiders",
                "Killer bees!",
                "Make a Beehat",
                "The hunters",
                "Magic meadow",
                "Frogs and bugs",
                "Mole Colony Deciduous",
                "Mole Colony Rocks",
                "MooseBreedingTask",
                "Speak to the king classic",
                "GiantTrees"
            }
        }

        if tasksetdata.ocean_prefill_setpieces ~= nil then
            tasksetdata.ocean_prefill_setpieces["utw_biomespawner"] = { count = math.random(6, 9) }
        end -- nice
    end)

    if GetModConfigData("trapdoorspiders") then
        AddRoomPreInit("BGSavanna", function(room) -- This effects the outer areas of the Triple Mac and The Major Beefalo Plains
            room.contents.countprefabs = { trapdoorspawner = function() return math.random(4, 5) end }
        end)
        AddRoomPreInit("Plain", function(room)                                                       -- This effects areas in the Major Beefalo Plains and the Grasslands next to the portal
            room.contents.countprefabs = { trapdoorspawner = function() return math.random(2, 4) end } -- returned number for whole area should be multiplied between 2-4 due to multiple rooms
        end)
    end





	-- New Desert
    AddRoomPreInit("BGLightningBluff", function(room) -- Oasis Desert Has Scorpion Organizers which determine how their burrowing should change.....
        room.contents.countprefabs = { um_scorpionhole = math.random(0, 1) }
    end)

    AddTaskPreInit("Lightning Bluff", function(task)
        GLOBAL.require("map/rooms/forest/UM_LightningBluff")
        task.room_choices["LightningBluff_Scorpion"] = function() return math.random(3, 4) end

		
		-- Oasis Renovation - Give Oasis versions of several Badlands rooms, but they can have sandstorm
		task.room_choices["BarePlain_Oasis"] = 1
		task.room_choices["Houndy_Oasis"] = 1 
		--task.room_choices["Badlands_Oasis"] = 1
		--task.room_choices["BuzzardyBadlands_Oasis"] = 1 
		task.room_choices["BGLightningBluff"] = 0 -- No more BGLightningBluff
		task.background_room = "BGBadlands_Oasis"
    end)
	AddRoomPreInit("LightningBluffLightning", function(room) -- This effects the outer areas of the Triple Mac and The Major Beefalo Plains
		room.tags = {"sandstorm"}
	end)
	AddRoomPreInit("LightningBluffAntlion", function(room) -- This effects the outer areas of the Triple Mac and The Major Beefalo Plains
		room.tags = {"sandstorm"}
	end)
	
	

	-- Transform the Badlands into the BoilingFields (fuck it's "Broiling")
    AddTaskPreInit("Badlands", function(task)
        GLOBAL.require("map/rooms/forest/UM_BoilingFields")
		
		
		-- Room removal! lots of desert things are gone now! Make room for hot springs
		task.room_choices["Badlands"] = 0 
		task.room_choices["BarePlain"] = 0 
		task.room_choices["BuzzardyBadlands"] = 0 
		task.room_choices["HoundyBadlands"] = 0 
		task.room_choices["DragonflyArena"] = 0 

		task.room_choices["BoilingFields_Crabby"] = 1 -- Crabs
		task.room_choices["BoilingFields_Hotsprings"] = 1 -- Hotsprings
		task.room_choices["BoilingFields_Rocky"] = 1 -- Snaildrakes
		task.room_choices["BoilingFields_BasaltHounds"] = 2-- Hounds
		task.room_choices["BoilingFields_DragonflyArena"] = 1 -- Dfly
		task.room_choices["BoilingFields_Sinkhole"] = 1 -- Sinkhole
		task.background_room = "BoilingFields_Hotsprings"
		--task.entrance_room= "BoilingFields_Rocky"
		
		
    end)
	
    -----------Ghost Walrus
    if GetModConfigData("ghostwalrus") ~= "disabled" then
        AddRoomPreInit("WalrusHut_Plains", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)

        AddRoomPreInit("WalrusHut_Grassy", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)

        AddRoomPreInit("WalrusHut_Rocky", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
    end
    -----------Marsh Grass
    AddRoomPreInit("BGMarsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(2, 6) end, marshmist = function() return math.random(4, 6) end } end)

    AddRoomPreInit("Marsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(2, 6) end, marshmist = function() return math.random(4, 6) end } end)

    AddRoomPreInit("SpiderMarsh", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(4, 8) end, marshmist = function() return math.random(4, 6) end } end)

    AddRoomPreInit("SlightlyMermySwamp", function(room) room.contents.countprefabs = { marsh_grass = function() return math.random(4, 8) end, marshmist = function() return math.random(4, 6) end } end)

    -- Waffle's Specific Task Remover Code
    AddTaskSetPreInitAny(function(tasksetdata)
        for _, task in pairs(tasksetdata.tasks) do
            if task == "ToadStoolTask1" then
                table.remove(tasksetdata.tasks, _)
            end
        end
    end)

    AddTaskSetPreInitAny(function(tasksetdata)
        for _, task in pairs(tasksetdata.tasks) do
            if task == "ToadStoolTask2" then
                table.remove(tasksetdata.tasks, _)
            end
        end
    end)

    AddTaskSetPreInitAny(function(tasksetdata)
        for _, task in pairs(tasksetdata.tasks) do
            if task == "ToadStoolTask3" then
                table.remove(tasksetdata.tasks, _)
            end
        end
    end)
    -- Waffle's Specific Task Remover Code

    AddRoomPreInit("RedMushPillars", function(room) -- red
        room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
    end)

    AddRoomPreInit("GreenMushNoise", function(room) -- green
        room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
    end)
    AddRoomPreInit("DropperDesolation", function(room) -- blue
        room.contents.countstaticlayouts = { ["ToadstoolArena"] = 1 }
    end)

    AddRoomPreInit("DeepDeciduous", function(room) room.contents.countprefabs.backupcatcoonden = 1 end)

    -----KoreanWaffle's Spawner Limiter Tag Adding Code
    -- Add new map tags to storygen
    local MapTags = { "scorpions", "hoodedcanopy", "rattygas", "ratkey1", "mosaic" }
    AddGlobalClassPostConstruct("map/storygen", "Story", function(self)
        for k, v in pairs(MapTags) do
            self.map_tags.Tag[v] = function(tagdata) return "TAG", v end
        end
    end)

    -- All the desert rooms. I excluded "DragonflyArena", "LightningBluffAntlion", and "LightningBluffOasis"
    local deserts = { "BGBadlands", "Badlands", "HoundyBadlands", "BuzzardyBadlands", "BGLightningBluff", "LightningBluffLightning" }

    -- Add "scorpions" room tag to all desert rooms
    for k, v in pairs(deserts) do
        AddRoomPreInit(v, function(room)
            if not room.tags then
                room.tags = { "scorpions" }
            elseif room.tags then
                table.insert(room.tags, "scorpions")
            end
        end)
    end

    local meteorIsh = { "BGNoise", "Rocky", "CritterDen", "Graveyard" }

    -- Add "mosaic" room tag to all mosaic rooms
    for k, v in pairs(meteorIsh) do
        AddRoomPreInit(v, function(room)
            if not room.tags then
                room.tags = { "mosaic" }
            elseif room.tags then
                table.insert(room.tags, "mosaic")
            end
        end)
    end

    -----KoreanWaffle's Spawner Limiter Tag Adding Code
    GLOBAL.require("map/rooms/forest/extraswamp")
    if GetModConfigData("vetcurse") == "default" then
        AddTaskPreInit("Make a pick", function(task)
            GLOBAL.require("map/rooms/forest/challengespawner")
            task.room_choices["veteranshrine"] = 1
        end)
    end
    ---- KoreanWaffle's LOCK/KEY initialization code  --Inactive atm
    local LOCKS = GLOBAL.LOCKS
    local KEYS = GLOBAL.KEYS
    local LOCKS_KEYS = GLOBAL.LOCKS_KEYS
    -- keys
    local keycount = 0
    for k, v in pairs(KEYS) do
        keycount = keycount + 1
    end
    KEYS["RICE"] = keycount + 1
    KEYS["HF"] = keycount + 1
	KEYS["MAGMA_CAVES"] = keycount + 1
	KEYS["MAGMA_CAVES_ENTRANCE"] = keycount + 1
	
    -- locks
    local lockcount = 0
    for k, v in pairs(LOCKS) do
        lockcount = lockcount + 1
    end
    LOCKS["RICE"] = lockcount + 1
    LOCKS["HF"] = lockcount + 1
	LOCKS["MAGMA_CAVES"] = lockcount + 1
	LOCKS["MAGMA_CAVES_ENTRANCE"] = lockcount + 1
	
    -- link keys to locks
    LOCKS_KEYS[LOCKS.RICE] = { KEYS.RICE }
    LOCKS_KEYS[LOCKS.HF] = { KEYS.HF }
	LOCKS_KEYS[LOCKS.MAGMA_CAVES] = { KEYS.MAGMA_CAVES}
	LOCKS_KEYS[LOCKS.MAGMA_CAVES_ENTRANCE] = { KEYS.MAGMA_CAVES_ENTRANCE}
	
    if GetModConfigData("rice") then
        AddTaskPreInit("Squeltch", function(task)
            task.room_choices["ricepatch"] = 1      -- Comment to test task based rice worldgen
            task.room_choices["densericepatch"] = 1 -- Comment to test task based rice worldgen
        end)
    end
    if GetModConfigData("hoodedforest") then
        GLOBAL.require("map/tasks/gianttrees")
    end
	
	-- Magma Caves
	GLOBAL.require("map/tasks/magma")
	
    --[[GLOBAL.require("map/tasks/ratacombs")
        GLOBAL.require("map/rooms/caves/ratacombsrooms")
        GLOBAL.require("map/rooms/forest/ratking")

        if GetModConfigData("caved") == false then

            AddTaskSetPreInitAny(function(tasksetdata)
            if tasksetdata.location ~= "forest" or (tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.VOLCANO or tasksetdata.name == STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.SHIPWRECKED) then
                    return
                end
                AddTaskPreInit("Dig that rock",function(task)
                    task.room_choices["RatKingdom"] = 1
                end)
            end)
        else
            AddTaskPreInit("Dig that rock",function(task)
                task.room_choices["RattySinkhole"] = 1
            end)
        end]]
    if GetModConfigData("hoodedforest") then
        AddTaskPreInit("Forest hunters", function(task) -- Leave Forest Hunters in incase someone adds something to its setpieces.
            task.room_choices = { ["Forest"] = 1, ["Clearing"] = 1 }
        end)
    end

    
        --[[AddTaskSetPreInitAny(function(tasksetdata)
            if tasksetdata.location ~= "cave" then
                return
            end
            table.insert(tasksetdata.tasks,"Ratty_Entrance")
            table.insert(tasksetdata.tasks,"Ratty_Link")
            table.insert(tasksetdata.tasks,"Ratty_Maze")
            table.insert(tasksetdata.tasks,"Ratty_Maze")
            table.insert(tasksetdata.tasks,"Ratty_Maze2")
            table.insert(tasksetdata.tasks,"Ratty_Maze3")

            if tasksetdata.required_prefabs ~= nil then
                table.insert(tasksetdata.required_prefabs,"ratking")
                table.insert(tasksetdata.required_prefabs,"ratacombslock")
            else
                tasksetdata.required_prefabs = {"ratking","ratacombslock"}
            end
        end)]]
    Layouts["hooded_town"] = StaticLayout.Get("map/static_layouts/hooded_town")
    Layouts["rose_garden"] = StaticLayout.Get("map/static_layouts/rose_garden")
    Layouts["hf_holidays"] = StaticLayout.Get("map/static_layouts/hf_holidays")

    Layouts["RatLockBlocker1"] = { type = GLOBAL.LAYOUT.CIRCLE_EDGE, start_mask = GLOBAL.PLACE_MASK.NORMAL, fill_mask = GLOBAL.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED, layout_position = GLOBAL.LAYOUT_POSITION.CENTER, ground_types = { GLOBAL.WORLD_TILES.ROCKY }, defs = { rocks = { "ratacombslock_rock_spawner" } }, count = { rocks = 1 }, scale = 0.1 }

    if GetModConfigData("hoodedforest") then
        AddRoomPreInit("HoodedTown", function(room)
            if not room.contents.countstaticlayouts then
                room.contents.countstaticlayouts = {}
            end
            room.contents.countstaticlayouts["hooded_town"] = 1
        end)

        AddRoomPreInit("RoseGarden", function(room)
            if not room.contents.countstaticlayouts then
                room.contents.countstaticlayouts = {}
            end
            room.contents.countstaticlayouts["rose_garden"] = 1
        end)

        AddRoomPreInit("HFHolidays", function(room)
            if not room.contents.countstaticlayouts then
                room.contents.countstaticlayouts = {}
            end
            room.contents.countstaticlayouts["hf_holidays"] = 1
        end)
    end

    if GetModConfigData("rice") then
        AddLevelPreInitAny(function(level)
            if level.location == "forest" then
                level.overrides.keep_disconnected_tiles = true
            end
        end)
        for i = 1, 4 do
            Layouts["ricepatchsmall" .. i] = StaticLayout.Get("map/static_layouts/ricepatchsmall" .. i)
        end
        for i = 1, 1 do
            Layouts["ricepatchlarge" .. i] = StaticLayout.Get("map/static_layouts/ricepatchlarge" .. i)
        end

        AddRoomPreInit("ricepatch", function(room)
            if not room.contents.countstaticlayouts then
                room.contents.countstaticlayouts = {}
            end
            local roomchoice = math.random(1, 4)
            local roomchoice2 = roomchoice
            while roomchoice2 == roomchoice do
                roomchoice2 = math.random(1, 4)
            end
            room.contents.countstaticlayouts["ricepatchsmall" .. roomchoice] = 1
            if math.random() > 0.5 then
                room.contents.countstaticlayouts["ricepatchsmall" .. roomchoice2] = 1
            end
        end)

        AddRoomPreInit("densericepatch", function(room)
            if not room.contents.countstaticlayouts then
                room.contents.countstaticlayouts = {}
            end
            room.contents.countstaticlayouts["ricepatchlarge1"] = 1
        end)
    end
    AddLevel(GLOBAL.LEVELTYPE.SURVIVAL, {
        id = "UNCOMPROMISING",
        name = GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.UNCOMPROMISING,
        desc = GLOBAL.STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.UNCOMPROMISING,
        location = "forest",
        version = 4,
        overrides = {
            antliontribute = "more" -- unnecessary
        }
    })

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

    --[[if GetModConfigData("depthsvipers") then
        AddRoomPreInit("ThuleciteDebris", function(room) room.contents.countprefabs = { viperworm_spawner = function() return math.random(2, 4) end } end)
    end]]

    --[[AddRoomPreInit("CritterDen", function(room)
        if not room.contents.countstaticlayouts then
            room.contents.countstaticlayouts = {}
        end
        room.contents.countstaticlayouts["impactfuldiscovery"] = 1
    end)]]
    AddRoomPreInit("OceanCoastal", function(room) room.contents.countprefabs = { ums_biometable = 1 } end)
	
	
	-- Lava Caves
	
	
	GLOBAL.require("map/rooms/caves/moltenregions")
	GLOBAL.require("map/rooms/caves/moonregions")
	
	AddTaskPreInit("BigBatCave",
		function(task)
		task.room_choices={
			["MoltenBatCave"] = 1,
			["MoltenBattyCave"] = 1,
			["MoltenFernyBatCave"] = 1,
			["PitRoom"] = 1,
		}
		task.background_room="BGMoltenBatCaveRoom"
		task.room_bg=WORLD_TILES.UM_MAGMA
		task.keys_given={KEYS.MAGMA_CAVES}
	end)
	
	if GetModConfigData("depthseels") then
		AddTaskPreInit("MoonCaveForest", function(task)
			task.room_choices["WormyMoonMushForest"] = 1
		end)
	end

	
	
	
	
	
	---------
    AddTaskPreInit("Make a pick", function(task)
        if GetModConfigData("vetcurse") then
            GLOBAL.require("map/rooms/forest/challengespawner")
        end

        if GetModConfigData("wixie_walter") then
            task.room_choices["wixie_puzzlearea"] = 1
        end
    end)

    local IA_SPAWN_TASKS = { "HomeIslandVerySmall", "HomeIslandSmall", "HomeIslandSmallBoon", "HomeIslandSingleTree", "HomeIslandMed", "HomeIslandLarge", "HomeIslandLargeBoon" }
    for k, v in ipairs(IA_SPAWN_TASKS) do
        AddTaskPreInit(v, function(task)
            GLOBAL.require("map/rooms/forest/challengespawner")
            if GetModConfigData("wixie_walter") then
                task.room_choices["wixie_puzzlearea_ia"] = 1
            end
            if GetModConfigData("vetcurse") then
                task.room_choices["veteranshrine_ia"] = 1
            end
        end)
    end

    -- WIXIE PUZZLE SETS

    modimport("init/init_food/init_food_worldgen")

    AddRoomPreInit("OceanSwell", function(room) room.contents.countprefabs = { siren_teaser_picker = 1, ums_biometable = 1 } end)
    AddRoomPreInit("OceanRough", function(room) room.contents.countprefabs = { siren_teaser_picker = 2 } end)

    --IA compat for tornadoes.
    AddRoomPreInit("OceanMedium", function(room) room.contents.countprefabs = { siren_teaser_picker = 3 } end)

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
end

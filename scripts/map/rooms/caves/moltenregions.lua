require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")
Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
Layouts["gemforge1"] = StaticLayout.Get("map/static_layouts/gemforge1")
Layouts["um_pepperdragon_nest"] = StaticLayout.Get("map/static_layouts/um_pepperdragon_nest")

Layouts["um_pepperdragon_nest"] = StaticLayout.Get("map/static_layouts/um_pepperdragon_nest")
Layouts["um_pepperdragon_nest"].ground_types = PYRE_THICKET_GROUND_TYPES

---------------------------------------------
-- Bat Caves
---------------------------------------------

AddRoom("BGMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
	random_node_entrance_weight = 0,
    contents =  {
        distributepercent = .08,
        distributeprefabs=
        {
			lava_pond_cave = 0.05,
			magmarock1 = 0.1,
			
			--um_pyre_nettles_stage_4 = 0.1,
			--um_pyre_nettles_stage_5 = 0.1,
        },
    }
})


-- Borrowed from vents.lua for the portion of the biome that is a mosaic between the two
--[[
random setpiece ideas boons and traps

bunch of vent rocks together with loot inside take loot boom vents trigger with spores or miasma or something

burned setpiece with a bunch of rock trees that had burned?

setpiece with several rock trees, each with 5 ruins gems that is a trap, not actually real
]]

-- withered ferns and light bulbs
-- miasma in general could also do this

local function RandomRockTreeState()
    if math.random() < TUNING.TREE_ROCK.BOULDER_GEN_CHANCE then
        local roll = math.random()
        if roll > 2/3 then
            return { boulder = true, workable = { workleft = TUNING.TREE_ROCK.MINE_MED} }
        elseif roll > 1/3 then
            return { boulder = true, workable = { workleft = TUNING.TREE_ROCK.MINE_LOW} }
        else
            return { boulder = true }
        end
    end
end

local function RandomVentRockState()
    local roll = math.random()
    if roll > 2/3 then
        return { workable = { workleft = TUNING.CAVE_VENTS.MINE_MED }, set_loot_table = "cave_vent_rock_med" }
    elseif roll > 1/3 then
        return { workable = { workleft = TUNING.CAVE_VENTS.MINE_LOW }, set_loot_table = "cave_vent_rock_low"}
    else
        return nil --full state
    end
end


AddRoom("MagmaRole", {
    colour={r=.8,g=1,b=.8,a=.50},
    value = WORLD_TILES.UM_MAGMA_FUMAROLE,
    random_node_exit_weight = 0,
    --type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .1,
        distributeprefabs=
        {
            cave_vent_rock  = 0.5,
            tree_rock1      = 0.12,
            tree_rock2      = 0.12,
			lava_pond_cave = 0.05,
			magmarock1 = 0.1,
        },
        prefabdata = {
            cave_vent_rock = RandomVentRockState,
            tree_rock1 = RandomRockTreeState,
            tree_rock2 = RandomRockTreeState,
        },
    }
})

AddRoom("GrassMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA_JUNGLY,
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
			lava_pond_cave = 0.1,
			magmarock1 = 0.025,
			mushtree_shadow = 0.025,
			pyrethicket_builder = 0.5,
			fyriterock = 0.05,
			--um_pyre_nettles_stage_2 = 0.1,
			--um_pyre_nettles_stage_5 = 0.1,
			um_pyrite_ceiling = 0.025,
        },
		countstaticlayouts = {
			["um_pepperdragon_nest"] = 1,
		},
        countprefabs=
        {
            um_ghost_pepper = function() return math.random(6,9) end,
        },
    }
})

AddRoom("GrassMagmaCliffs", {
	type = NODE_TYPE.Room,
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_GRASSMAGMA,
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
			lava_pond_cave = 0.1,
			magmarock1 = 0.025,
			mushtree_shadow = 0.025,
			pyrethicket_builder = 0.5,
			fyriterock = 0.05,
			um_pyrite_ceiling = 0.025,
        },
    }
})

AddRoom("GrassMagmaCliffsDragon", {
	type = NODE_TYPE.Room,
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_GRASSMAGMA,
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
			lava_pond_cave = 0.1,
			magmarock1 = 0.025,
			mushtree_shadow = 0.025,
			pyrethicket_builder = 0.5,
			fyriterock = 0.05,
			um_pyrite_ceiling = 0.025,
        },
		countstaticlayouts = {
			["um_pepperdragon_nest"] = 1,
		},
    }
})

AddRoom("ShroomyMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
	random_node_entrance_weight = 0,
    contents =  {
        distributepercent = .5,
        distributeprefabs=
        {
			fissure = 0.125,
			lava_pond_cave = 0.05,
			magmarock1 = 0.05,
			mushtree_shadow = 0.9,
			viperfruit_plant = 0.1,
        },
    }
})

AddRoom("FossilMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
	random_node_entrance_weight = 0,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
			lava_pond_cave = 0.025,
			magmarock1 = 0.025,
			magmabone = 0.05,
			um_pyrite_ceiling = 0.0025,
			um_ribopodden = 0.0025,
			--um_pyre_nettles_stage_2 = 0.025,
			--um_pyre_nettles_stage_5 = 0.025,
        },
		countprefabs=
		{
			um_ghost_pepper = function() return math.random(4,7) end,
		},
    }

})

AddRoom("GloomyMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
	random_node_entrance_weight = 0,
    contents =  {
        distributepercent = .15,
        distributeprefabs=
        {
			fissure = 0.15,
			lava_pond_cave = 0.1,
			magmarock1 = 0.15,
			viperfruit_plant = 0.25,
			viperworm = 0.25,
			um_pyrite_ceiling = 0.025,
			--um_pyre_nettles_stage_2 = 0.05,
			--um_pyre_nettles_stage_5 = 0.05,
        },
        countprefabs=
        {
            um_ghost_pepper = function() return math.random(1,2) end,
        },
    }
})

AddRoom("GemForge1", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
    contents =  {
        distributepercent = .08,
        distributeprefabs=
        {
			lava_pond_cave = 0.05,
			magmarock1 = 0.1,
			
        },
		countprefabs = {um_gemologyforge_umss = 1},
    }
})

local bgbatcave = {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.CAVE,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .13,
        distributeprefabs=
        {
            batcave = 0.05,
            stalagmite_tall=0.4,
            stalagmite_tall_med=0.4,
            stalagmite_tall_low=0.4,
            pillar_cave_rock = 0.01,
            fissure = 0.05,
			rock_magma = 0.4,
        },
    }
}

AddRoom("MagmaStairs", {
	colour={r=0,g=.9,b=0,a=.50},
	value = WORLD_TILES.UM_MAGMA,
	random_node_exit_weight = 0,
	contents =  {
					countstaticlayouts = {
						["cave_exit_magmabiome"] = 1,
					},
					distributepercent = .2,
					distributeprefabs=
					{
						--sapling=.5,
						--twiggytree=0.2,
						rocks=.03,
						flint=.03,
						cavelight = 0.25,
						cavelight_small = 0.1,
						cavelight_tiny = 0.1,
						flower_cave = 0.1,
						lava_pond_cave = 0.1,
						magmarock1 = 0.2,
					},								
				}
	

})

AddRoom("BGMoltenBatCave", bgbatcave)
AddRoom("BGMoltenBatCaveRoom", Roomify(bgbatcave))


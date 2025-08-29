require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")
Layouts["cave_exit_magmabiome"] = StaticLayout.Get("map/static_layouts/cave_exit_magmabiome")
Layouts["um_pepperdragon_nest"] = StaticLayout.Get("map/static_layouts/um_pepperdragon_nest")

Layouts["um_pepperdragon_nest"] = StaticLayout.Get("map/static_layouts/um_pepperdragon_nest")
Layouts["um_pepperdragon_nest"].ground_types = PYRE_THICKET_GROUND_TYPES

---------------------------------------------
-- Bat Caves
---------------------------------------------

AddRoom("BGMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
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

AddRoom("ShroomyMagma", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.UM_MAGMA,
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
    contents =  {
        distributepercent = .2,
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


--- RED
AddRoom("RedMushForest_Petrified", {
    colour={r=0.8,g=0.1,b=0.1,a=0.9},
    value = WORLD_TILES.FUNGUSRED,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
            um_redmushtree_gemless = 6.0,
			um_redmushtree_gem = 1,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 0.35,
            stalagmite_med = 0.1,
            stalagmite_low = 0.05,
            pillar_cave = 0.1,
            spiderhole = 0.05,

            slurper = 0.001,
        },
    }
})
AddRoom("RedSpiderForest_Petrified", {
    colour={r=0.8,g=0.1,b=0.4,a=0.9},
    value = WORLD_TILES.FUNGUSRED,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
            um_redmushtree_gemless = 0.5,
			um_redmushtree_gem = 1,
            red_mushroom = 0.25,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            stalagmite = 1.0,
            stalagmite_med = 0.4,
            stalagmite_low = 0.1,
            pillar_cave = 0.2,
            spiderhole = 3,

            slurper = 0.001,
        },
    }
})
--- GREEN
AddRoom("GreenMushForest_Petrified", {
    colour={r=0.1,g=0.8,b=0.1,a=0.9},
    value = WORLD_TILES.FUNGUSGREEN,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .7,
        distributeprefabs=
        {
            um_greenmushtree_gemless = 3.0,
			um_greenmushtree_gem = 0.5,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            rabbithouse = 0.02,

            cave_fern = 2.5,

            slurper = 0.001,
        },
    }
})

AddRoom("GreenMushRabbits_Petrified", {
    colour={r=0.1,g=0.8,b=0.3,a=0.9},
    value = WORLD_TILES.FUNGUSGREEN,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        countstaticlayouts={
            ["RabbitTown"]=1,
        },
        distributepercent = .4,
        distributeprefabs=
        {
            um_greenmushtree_gemless = 2.0,
			um_greenmushtree_gem = 0.5,
            green_mushroom = 0.5,
            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            cavelight = 0.05,
            cavelight_small = 0.05,

            evergreen = 0.1,
            grass = 0.1,
            sapling = 0.1,
            twiggytree = 0.04,
            berrybush = 0.05,
            berrybush_juicy = 0.025,

            cave_fern = 3.5,

            slurper = 0.001,
            rabbithouse = 0.005,
        },
    }
})
--- BLUE
AddRoom("BlueMushForest_Petrified", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.FUNGUS,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .6,
        distributeprefabs=
        {
            um_bluemushtree_gemless = 3.0,
			um_bluemushtree_gem = 0.2,
            blue_mushroom = 0.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            batcave = 0.005,
            dropperweb = 0.015,

            slurper = 0.001,
        },
    }
})

AddRoom("BlueSpiderForest_Petrified", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.FUNGUS,
    tags = {"Hutch_Fishbowl"},
    contents =  {
        distributepercent = .7,
        distributeprefabs=
        {
            um_bluemushtree_gemless = 3.0,
			um_bluemushtree_gem = 1,
            blue_mushroom = 2.5,
            flower_cave = 0.1,
            flower_cave_double = 0.05,
            flower_cave_triple = 0.05,

            dropperweb = 1,
            boneshard = 0.2,
            houndbone = 0.2,

            slurper = 0.001,
        },
    }
})
-- NOISE
AddRoom("FungusNoiseForest_Petrified", {
    colour={r=1.0,g=1.0,b=1.0,a=0.9},
    value = WORLD_TILES.FUNGUS_NOISE,
    tags = {"Hutch_Fishbowl"},
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .4,
        distributeprefabs=
        {
            um_redmushtree_gemless = 8.0,
            um_greenmushtree_gemless = 8.0,
            um_bluemushtree_gemless = 8.0,
            um_redmushtree_gem = 1.0,
            um_greenmushtree_gem = 1.0,
            um_bluemushtree_gem = 1.0,
            red_mushroom = 0.5,
            green_mushroom = 0.5,
            blue_mushroom = 0.5,

            flower_cave = 0.2,
            flower_cave_double = 0.1,
            flower_cave_triple = 0.1,

            slurper = 0.001,
        },
    }
})
AddRoom("FungusNoiseMeadow_Petrified", {
    colour={r=1.0,g=1.0,b=1.0,a=0.9},
    value = WORLD_TILES.FUNGUS_NOISE,
    tags = {"Hutch_Fishbowl"},
    type = NODE_TYPE.Room,
    contents =  {
        distributepercent = .25,
        distributeprefabs=
        {
            um_redmushtree_gemless = 1.0,
            um_greenmushtree_gemless = 1.0,
            um_bluemushtree_gemless = 1.0,
            um_redmushtree_gem = .5,
            um_greenmushtree_gem = .5,
            um_bluemushtree_gem = .5,
            red_mushroom = 2.5,
            green_mushroom = 2.5,
            blue_mushroom = 2.5,

            flower_cave = 1.5,
            flower_cave_double = 1.0,
            flower_cave_triple = 1.0,

            slurper = 0.001,
        },
    }
})





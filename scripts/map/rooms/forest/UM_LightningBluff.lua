AddRoom("Badlands_Oasis", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = WORLD_TILES.DIRT_NOISE,
    tags = { "sandstorm" },
    contents = {
        distributepercent = 0.07,
        distributeprefabs =
        {
            rock_flintless = .8,
            --rock_ice = .5,
            marsh_bush = 0.25,
            marsh_tree = 0.75,
            grass = .5,
            grassgekko = 0.6,
            cactus = .7,
            houndbone = .6,
            tumbleweedspawner = .1,
        },
    }
})

AddRoom("BuzzardyBadlands_Oasis", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = WORLD_TILES.DIRT_NOISE,
    tags = { "sandstorm" },
    contents = {
        distributepercent = 0.1,
        distributeprefabs =
        {
            marsh_bush = .66,
            marsh_tree = 1,
            grass = .33,
            grassgekko = 0.4,
            buzzardspawner = .25,
            houndbone = .15,
            tumbleweedspawner = .1,
        },
    }
})

AddRoom("BGBadlands_Oasis", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    value = WORLD_TILES.DIRT_NOISE,
    tags = { "CharlieStage_Spawner", "sandstorm" },
    contents = {
        distributepercent = 0.07,
        distributeprefabs =
        {
            marsh_bush = 0.05,
            marsh_tree = 0.2,
            rock_flintless = 1,
            --rock_ice = .5,
            grass = 0.1,
            grassgekko = 0.4,
            houndbone = 0.2,
            cactus = 0.2,
            tumbleweedspawner = .1,
        },
    }
})


AddRoom("BarePlain_Oasis", {
    colour = { r = .5, g = .5, b = .45, a = .50 },
    value = WORLD_TILES.SAVANNA,
    tags = { "ExitPiece", "Chester_Eyebone", "Astral_2", "sandstorm" },
    contents = {
        distributepercent = 0.1,
        distributeprefabs =
        {
            perma_grass = 0.8,
            rabbithole = 0.4,
            --					                    beefalo=0.2
        },
    }
})

AddRoom("Houndy_Oasis", {
    colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
    tags = { "ExitPiece", "Chester_Eyebone", "Astral_2", "sandstorm" },
    value = WORLD_TILES.DIRT_NOISE,
    contents = {
        distributepercent = 0.2,
        distributeprefabs =
        {
            rock1 = .5,
            rock2 = 1,
            --rock_ice = .1,
            houndbone = .5,
            houndmound = .33,
        },
    }
})

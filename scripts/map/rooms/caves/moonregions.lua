require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")

---------------------------------------------
-- Lunar Grotto
---------------------------------------------

AddRoom("WormyMoonMushForest", {
    colour={r=0.1,g=0.1,b=0.8,a=0.9},
    value = WORLD_TILES.FUNGUSMOON,
    tags = {},
    random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["GrottoPoolSmall"] = 2,
        },
        countprefabs =
        {
            mushgnome_spawner = 1,
        },
        distributepercent = 0.2,
        distributeprefabs =
        {
            mushtree_moon = 0.025,
			
			zaspberry_plant = 0.025,
			shockworm = 0.01,

            cavelightmoon = 0.003,
            cavelightmoon_small = 0.003,
            cavelightmoon_tiny = 0.003,

            moonglass_stalactite1 = 0.007,
            moonglass_stalactite2 = 0.007,
            moonglass_stalactite3 = 0.007,
        },
    }
})
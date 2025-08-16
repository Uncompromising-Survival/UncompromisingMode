AddRoom("moonforest_bees",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.METEOR,
    --tags = {"ForceDisconnected", "RoadPoison"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
	contents = {
		countstaticlayouts =
		{
			["moontrees_2"] = function(area) return 2 + math.max(1, math.floor(area / 75)) end,
            ["MoonTreeHiddenAxe"] = 1,
		},
		countprefabs =
		{
			um_beehive_moon = function(area) return math.random(1,2) end,
		},
		distributepercent = 0.22,
		distributeprefabs =
		{
			moon_tree = 0.3,
			sapling_moon = 0.3,
			carrat_planted = 0.2,
			moon_tree_blossom_worldgen = 0.2,
			ground_twigs = 0.1,
			rock_avocado_bush = 0.1,
			moonglass_rock = 0.05,
			moon_fissure = 0.2,
		},
	},
})

AddRoom("moonrock_bees",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.METEORMINE_NOISE,
    --tags = {"ForceDisconnected", "RoadPoison"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
	contents = {
		distributepercent = 0.12,
		distributeprefabs =
		{
			moonglass_rock = 1,
			lunar_island_rock1 = 0.4,
			lunar_island_rock2 = 0.2,
			rock_moon = 0.2,
			moonglass = 0.2,
			moonrocknugget = 0.1,
			lunar_island_rocks = 0.1,
			flint = 0.1,
			moon_fissure = 0.5,
		},
		countprefabs =
		{
			um_beehive_moon = 1,
		},
	},
})
require "map/room_functions"

local Layouts = require ("map/layouts").Layouts
local StaticLayout = require ("map/static_layout")
Layouts["cave_entrance_moon"] = StaticLayout.Get("map/static_layouts/cave_entrance_moon")
AddRoom("moonswamp_cave",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.PEBBLEBEACH,
	contents = {
		countstaticlayouts = {
			["cave_entrance_moon"] = 1,
		},
		countprefabs =
		{
			moonspiderden = 1,
		},
		distributepercent = 0.18,
		distributeprefabs =
		{
			dead_sea_bones = 0.75,
			trap_starfish = 0.75,
			bullkelp_beachedroot = 1.25,
			driftwood_small1 = 0.5,
			driftwood_small2 = 0.5,
			driftwood_tall = 0.25,
			lunar_island_rocks = 0.5,
			flint = 0.5,
			lunar_island_rock1 = 0.5,
			reeds = 0.75,
			twigs = 0.25,
		},
	},
})

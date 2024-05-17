require "map/room_functions"

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")


Layouts["boilingfields_dragonfly_arena"] = StaticLayout.Get("map/static_layouts/boilingfields_dragonfly_arena")
AddRoom("BoilingFields_BasaltHounds", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	tags = {"RoadPoison"},
	value = WORLD_TILES.CRACKEDBASALT,
	contents =  {
					distributepercent = 0.3,
					distributeprefabs =
					{
						hotspring_rockbuncher_flintless = .05, --These rocks place fun tiles below them
						hotspring_rockbuncher_gold = 0.015,
						--rock_ice = .1,
						marsh_tree = 1,
						houndbone = .5,
						houndmound = .15,
						cactus = 0.2,
						marsh_bush = 1,
						rock_flintless = 1,
						--basalt = 0.6,
						rock_lichen = 0.1,
						um_hotspring = 0.1,
					},
				}
})

AddRoom("BoilingFields_Rocky", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	tags = {"RoadPoison","Mist"},
	value = WORLD_TILES.BOILINGFIELDS,
	contents =  {
					distributepercent = 0.08,
					distributeprefabs =
					{
						hotspring_rockbuncher_flintless = .02, --These rocks place fun tiles below them
						hotspring_rockbuncher_gold = 0.015,
						--rock_flintless_hotspring = 1,
						rock_lichen = 0.2,
						snaildrake_hole = .05,
						um_hotspring = 0.05,
					},
				}
})
AddRoom("BoilingFields_Crabby", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	tags = {"RoadPoison","Mist"},
	value = WORLD_TILES.BOILINGFIELDS,
	contents =  {
					distributepercent = 0.08,
					distributeprefabs =
					{
						hotspring_rockbuncher_crabs = .03, --These rocks place fun tiles below them
						--rock_flintless_hotspring = 1,
						rock_lichen = 0.2,
						molehill = 0.02,
						um_hotspring = 0.05,
					},
				}
})
AddRoom("BoilingFields_Hotsprings", {
	colour={r=0.3,g=0.2,b=0.1,a=0.3},
	tags = {"RoadPoison","Mist"},
	value = WORLD_TILES.BOILINGFIELDS,
	contents =  {
					distributepercent = 0.05,
					distributeprefabs =
					{
						hotspring_rockbuncher_flintless = .03, --These rocks place fun tiles below them
						hotspring_rockbuncher_gold = 0.02,
						hotspring_rockbuncher_crabs = .01,
						rock_lichen = 0.025,
						um_hotspring = 0.1,
						rabbithole = 0.01,
						molehill = 0.02,
					},
				}
})

AddRoom("BoilingFields_DragonflyArena", {
					colour={r=0.3,g=0.2,b=0.1,a=0.3},
					tags = {"RoadPoison"},
					value = WORLD_TILES.CRACKEDBASALT,
					contents =  {
									countstaticlayouts={["boilingfields_dragonfly_arena"]=1}, -- using a static layout because this can force it to be in the center of the room
									distributepercent = 0.2,
									distributeprefabs =
									{
										marsh_bush = 0.25,
										marsh_tree = 0.75,
										houndbone = .3,
									},
					            }
					})
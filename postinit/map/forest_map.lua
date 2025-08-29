local env = env
GLOBAL.setfenv(1, GLOBAL)

local forest_map = require("map/forest_map")

local _Generate = forest_map.Generate

print("are we running this at least?")
forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)


	if prefab == "cave" then -- Only postinit if this is caves.
		map_width = map_width * 1.25
		map_height = map_height * 1.25
		
		-- local WorldSimMetaTable = getmetatable(WorldSim).__index
		-- local _DetectDisconnect = WorldSimMetaTable.DetectDisconnect
		-- function WorldSimMetaTable.DetectDisconnect(self)
			-- print("Postinit DetectDisconnect")
			-- local val = _DetectDisconnect(self)
			-- return 0
		-- end

		-- WorldSim.DetectDisconnect = DetectDisconnect()
		

		-- local WorldSimMetaTable = getmetatable(WorldSim).__index
		-- local _SeparateIslands = WorldSimMetaTable.SeparateIslands
		-- function WorldSimMetaTable.SeparateIslands(self)
			-- -- ...
			-- print("Postinit SeparateIslands Removed")
			-- --return _SeparateIslands(self)
		-- end
		
		

		
	end
	
	--print("Is this code running?")
	return _Generate(prefab, map_width, map_height, tasks, level, level_type, ...)
end
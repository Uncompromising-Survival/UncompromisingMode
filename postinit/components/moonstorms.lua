local env = env
GLOBAL.setfenv(1, GLOBAL)


-- This code is WIP (will finish it out in a while, isn't called)
-- local UpvalueHacker = require("tools/upvaluehacker")


-- env.AddComponentPostInit("moonstorms", function(self)
	-- local _AddMoonstormNodes = self.AddMoonstormNodes
	
	-- function self:AddMoonstormNodes(node_indices, firstnode)
		-- _AddMoonstormNodes(node_indices, firstnode)
		-- if type(node_indices) ~= "table" then
			-- node_indice = { node_indices }
		-- end

		-- for _, v in ipairs(node_indices) do
			-- _active_moonstorm_nodes[v] = true

			-- local marker = SpawnPrefab("moonstormmarker_big")
		 -- --   local center = TheWorld.topology.nodes[firstnode].cent
			-- local center = TheWorld.topology.nodes[v].cent
			-- SpawnHiveTraps(center)
		-- end
	-- end
-- end)

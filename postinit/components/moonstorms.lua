local env = env
GLOBAL.setfenv(1, GLOBAL)


-- This code is WIP (will finish it out in a while, isn't called)
-- local UpvalueHacker = require("tools/upvaluehacker")


local function SpawnHiveTraps(center)
	local x = center[1]
	local z = center[2]
	local pos = Vector3(x,0,z)	
	--for i = 1,3 do
	local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 24, 32)
	local newx = x + offset.x
	local newz = z + offset.z
	
	local hives = TheSim:FindEntities(newx,0,newz,24,{"beehive"})
	for i,v in ipairs(hives) do -- prevent cramming hives
		if v.prefab == "um_beehive_moon" then
			offset = nil
		end
	end
	if offset then
		local beehive = SpawnPrefab("um_beehive_moon")
		beehive.Transform:SetPosition(newx, 0, newz)
		beehive.BeginDegrade(beehive)
	end
	--end
end

env.AddComponentPostInit("moonstorms", function(self)
	local _AddMoonstormNodes = self.AddMoonstormNodes
	
	function self:AddMoonstormNodes(node_indices, firstnode)
		_AddMoonstormNodes(self, node_indices, firstnode)
		if type(node_indices) ~= "table" then
			node_indice = { node_indices }
		end
		for _, v in ipairs(node_indices) do
		 --   local center = TheWorld.topology.nodes[firstnode].cent
			local center = TheWorld.topology.nodes[v].cent
			SpawnHiveTraps(center)
		end
	end
end)

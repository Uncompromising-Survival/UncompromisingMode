local env = env
GLOBAL.setfenv(1, GLOBAL)
local function RetrofitArchivesBridge()
	local centers = {}
	local start = {}
    for i, node in ipairs(TheWorld.topology.nodes) do
        if (node.tags and (table.contains(node.tags, "UMMazeEntranceGrotto"))) and node.x then --table.contains(node.tags, "lunacyarea")))
			table.insert(start, { x = node.x, z = node.y })
        end
        if (node.tags and (table.contains(node.tags,"UMMazeGrotto"))) and TheWorld.Map:IsVisualGroundAtPoint(node.x,0,node.y) then --table.contains(node.tags, "lunacyarea")))
			table.insert(centers, { x = node.x, z = node.y })
        end
    end
	if #centers == 0 then
		return false
	end
	if #start == 0 then
		return false
	end
	local dist = 120
	local minidx = 1
	for i,v in ipairs(centers) do
		local r = math.sqrt((start[1].x-v.x)^2+(start[1].z-v.z)^2)
		if r < dist then
			dist = r
			minidx = i
		end
	end
	
	local xdist = centers[minidx].x-start[1].x
	local zdist = centers[minidx].z-start[1].z
	
	local tilechecks = 4
	for i = 1,dist,tilechecks do
		local pointx = start[1].x+(xdist)*i/dist
		local pointz = start[1].z+(zdist)*i/dist
		for x1 = -3,3,1 do
			for z1 = -3,3,1 do
				if not TheWorld.Map:IsPassableAtPoint(pointx+x1,0,pointz+z1) then
					local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(pointx+x1, 0, pointz+z1)
					TheWorld.Map:SetTile(tile_x,tile_z,WORLD_TILES.DIRT)
					SpawnPrefab("rock1").Transform:SetPosition(pointx+x1+math.random(-10,10)*0.05,0,pointz+z1+math.random(-10,10)*0.05)
				end
			end
		end
	end
	
	return true
end


env.AddComponentPostInit("retrofitcavemap_anr", function(self)
	local oldonpostinit_cave = self.OnPostInit
	function self:OnPostInit(...)
		print("code is running")
		local building_bridges = RetrofitArchivesBridge()
		if building_bridges then
			print("Re-added the archives bridge after it was swallowed by the void!")
		else
			print("Couldn't re-add the archives bridge! Dunno why! Should check in this world to see if it is directly connected to grotto!")
		end
		return oldonpostinit_cave(self, ...)
	end
end)
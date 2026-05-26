local Um_Electrifies_Tiles = Class(function(self, inst)
    self.inst = inst   
	self.my_tiles = {} 
	self.range = 2

	self.current_range = 0


end)

local function WaterTile(tx,tz)
	local current_tile = TheWorld.Map:GetTile(tx,tz)
	if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
		return true
	end
end

function Um_Electrifies_Tiles:ExtendTiles()

	if self.current_range >= (2*self.range) then -- We've Extended - don't run anything else.
		return
	end

	local x,y,z = self.inst.Transform:GetWorldPosition()
	local tx,tz = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)

	-- Need an initial tile
	if self.current_range == 0 or not table.contains(self.my_tiles,{tx,tz}) then
		TheNet:Announce(tx)
		table.insert(self.my_tiles,{tx,tz})
		self.current_range = 1
		return
	end

	-- Extend instead
	local range_mult = 1
	if math.random() > 0.5 then
		range_mult = -1 -- Extend the other direction first instead
	end
	
	for xi = -self.current_range * range_mult,self.current_range * range_mult do
		for zi = -self.current_range * range_mult,self.current_range * range_mult do
			if not table.contains(self.my_tiles,{tx+xi,tz+zi}) and ((self.current_range <= self.range) or WaterTile(tx+xi,tz+zi)) then
				TheNet:Announce(tx+xi)
				table.insert(self.my_tiles,{tx+xi,tz+zi})
				return
			end
		end
	end

	self.current_range = self.current_range + 1
	self:ExtendTiles() -- Cannot overflow, eventually the if statement at the top will be reached (4 iterations standard)
end

local function ChargePoint(inst,x,z)
	local shock = SpawnPrefab("electricchargedfx")
	shock.Transform:SetPosition(x,0,z)
	local ents = TheSim:FindEntities(x,0,z,2,{"_health"})
	for i,ent in ipairs(ents) do
		if ent.prefab ~= inst.prefab then
			v.components.combat:GetAttacked(inst, 10, nil, "electric")
		end
	end
	for i = 1,math.random(2,3) do
		local shock = SpawnPrefab("sparks")
		shock.Transform:SetPosition(x + math.random(-5,5)/10,0,z + math.random(-5,5)/10)
	end
end

function Um_Electrifies_Tiles:ElectrifyMyTiles()
	local inst = self.inst
    local WIDTH, HEIGHT = TheWorld.Map:GetSize()
    local _mapgrid = DataGrid(WIDTH, HEIGHT)

	for i,v in ipairs(self.my_tiles) do
		local grid_index = _mapgrid:GetIndex(v[1], v[2])
		local x, z = _mapgrid:GetXYFromIndex(grid_index)
		for i = -2,2,2 do
			for j = -2,2,2 do
				
				local point = Vector3(x + i, 0 , z + j)
				local dist = math.sqrt(inst:GetDistanceSqToPoint(point))
				--TheNet:Announce(0.001*dist)
				inst:DoTaskInTime(0.001*dist,function(inst)
					ChargePoint(inst,x+i+math.random(-5,5)/10,z+j+math.random(-5,5)/10)
				end)
			end
		end
	end
end


function Um_Electrifies_Tiles:ClearAllMyTiles()
	self.my_tiles = {} 
	self.current_range = 0
end

return Um_Electrifies_Tiles

-- This file handles the spawning of Pyre Nettles around the player during Summer.


return Class(function(self, inst)
	assert(TheWorld.ismastersim, "um_pyre_nettles_summer_spawner should not exist on client!")
	
	self.inst = inst
	
	
	-- Spawn conditions are here.
	local function SpawnPlants(inst)
		local tempchance = (TheWorld.state.temperature * 2) * math.random()
		
		if tempchance > 70 or TheWorld:HasTag("heatwavestart") then
			for k,v in pairs(AllPlayers) do
				local x, y, z = v.Transform:GetWorldPosition()
				local theta = math.random() * 2 * PI
				local x = x + 30 * math.cos(theta)
				local y = 0
				local z = z - 30 * math.sin(theta)
				
				local blockers = TheSim:FindEntities(x, y, z, 0.5, { "blocker" }, { "invisible", "playerghost" })
				local nettlescrowding = TheSim:FindEntities(x, y, z, 10, { "PyreNettle" })
				local findnettles = TheSim:FindEntities(x, y, z, 30, {"PyreNettle"})
				
				print ("Trying to spawn PN near a player.")
			--	if blockers == nil
			--	and nettlescrowding == nil
			--	and #findnettles < 16
			--	and TheWorld.Map:CanPlantAtPoint(x, y, z) -- Pyre Nettles are lava-dwellers; they can grow in rock. This is just here for reference.
			--	and not (RoadManager ~= nil and RoadManager:IsOnRoad(x, y, z)) -- Not needed in caves.
			--	then
					print ("Spawning PN near a player.")
					local nettle = SpawnPrefab("um_pyre_nettles")
					nettle.Transform:SetPosition(x, y, z)
					nettle:PutBackOnGround(30)
			--	end
			end
		end
	end
	
	
	local function OnSeasonChange()
		if TheWorld.state.season == "summer" then
			self.inst.SpawnChanceTask = self.inst:DoPeriodicTask(3, SpawnPlants, 1)
		elseif self.SpawnChanceTask ~= nil then
			self.inst.SpawnChanceTask:Cancel()
		end
	end
	
	function self:OnPostInit()
		if TheWorld.state.season == "summer" then
			OnSeasonChange()
			
			self:WatchWorldState("season", OnSeasonChange)
		end
	end
end)

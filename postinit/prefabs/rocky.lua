local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function NoOtherRocksAndEnts(pos)
	
	local invitems = TheSim:FindEntities(pos.x, 0, pos.z, 1, nil,{"inventoryitem"}) -- entities other than inventory items, place me away from those.
    if invitems and #invitems > 0 then
		return false
	end
	local rocks = TheSim:FindEntities(pos.x, 0, pos.z, 6, { "boulder" }) -- bigger spacing for rocks
	if rocks and #rocks > 0 then
		return false
	end
	return true

end


local function Repopulate(inst) 
	if inst.listened_to_gen then
		inst.listened_to_gen = nil
		inst:RemoveEventCallback("entitysleep",Repopulate)
	end
	local pos = inst:GetPosition()
	local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 6, 12, true, true, NoOtherRocksAndEnts)
	if offset then
		local rnd = math.random()
		local rock
		local x,y,z = inst.Transform:GetWorldPosition()
		local flintless = TheSim:FindEntities(x,y,z,32,{"boulder"})
		local flintless_count = 0
		for i,v in ipairs(flintless) do
			if v.prefab == "rock_flintless" or v.prefab == "rock_flintless_med" or v.prefab == "rock_flintless_low" then
				flintless_count = flintless_count + 1
			end
		end
		local chance = Lerp(0.05,0.5,math.clamp(flintless_count,0,10)/10)
		if rnd < chance then
			rock = "um_rocklobster_rock"
		else
			rock = "rock_flintless"
		end
		local rockprefab = SpawnPrefab(rock)
		rockprefab.Transform:SetPosition(x + pos.x,0,z + pos.z)
	end
end


local function TryRepopulate(inst)
	if TheWorld.state.isautumn then
		if not inst.entity:IsAwake() then
			Repopulate(inst)
		else
			inst.listened_to_gen = true
			inst:ListenForEvent("entitysleep",Repopulate)
		end
	end
end


env.AddPrefabPostInit("rocky", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:WatchWorldState("isautumn",function(inst)
		inst:DoTaskInTime(0,TryRepopulate)
	end)	-- AXE Misnomer, they're not repopulating themselves, just their baby rocks.
end)

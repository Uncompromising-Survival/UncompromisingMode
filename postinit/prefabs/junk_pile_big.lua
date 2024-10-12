local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function MakeCooker(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	

	local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, 23, 30, true,true)

	local spawner = SpawnPrefab("umss_general")
    spawner.DefineTable(spawner, "wagstaffcooker")
    spawner.Transform:SetPosition(x+offset.x, y, z+offset.z)
    spawner.AnimState:SetMultColour(0, 0, 0, 0) -- makes it invisible too.
    spawner:AddTag("NOCLICK")
    spawner:AddTag("NOBLOCK")
    spawner:DoPeriodicTask(3, function(spawner) spawner:Remove() end) -- just in case it fails.
end


local function LookForCooker(inst)
	if not FindEntity(inst,30,function(ent) return ent.prefab == "um_cookpot_wagstaff" end) then
		MakeCooker(inst)
	end
end

env.AddPrefabPostInit("junk_pile_big", function(inst)
	

	if not TheWorld.ismastersim then
		return
	end
	
	inst:DoTaskInTime(0,LookForCooker)
	
end)
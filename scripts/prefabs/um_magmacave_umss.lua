local function RemoveProblems(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local pyre = TheSim:FindEntities(x,y,z,24,nil,nil,{"lava","PyreNettle"})
	for i,v in ipairs(pyre) do
		v:Remove()
	end
end

local function Spawn(inst)
    local spawner = SpawnPrefab("umss_general")
    spawner.DefineTable(spawner, "um_gemologyforge1")
	local x,y,z = inst.Transform:GetWorldPosition()
    spawner.Transform:SetPosition(x, y, z)
    spawner.AnimState:SetMultColour(0, 0, 0, 0) -- makes it invisible too.
    spawner:AddTag("NOCLICK")
    spawner:AddTag("NOBLOCK")
    spawner:DoPeriodicTask(3, function(spawner) spawner:Remove() end) -- just in case it fails.
	RemoveProblems(inst)
    inst:Remove()
end

local function makefn()
    	local inst = CreateEntity()

    	inst.entity:AddTransform()
    	inst.entity:AddAnimState()
        inst.entity:AddNetwork()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddDynamicShadow()
        inst.entity:SetPristine()
		
        if not TheWorld.ismastersim then
            return inst
        end
		inst:DoTaskInTime(1,Spawn)
        return inst
end

return Prefab("um_gemologyforge_umss", makefn)


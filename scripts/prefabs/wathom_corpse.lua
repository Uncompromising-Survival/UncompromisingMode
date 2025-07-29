local function HasSkill(inst,name)
	return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function OnHaunt(inst, haunter)
	if HasSkill(haunter,"shadow_wathom_2") and haunter.components.health and haunter.components.health:GetPenaltyPercent() <= 0.25 then
		haunter:PushEvent("respawnfromghost", { source = haunter })
		haunter.Physics:Teleport(inst.Transform:GetWorldPosition())
		haunter.components.health:DeltaPenalty(0.25)
		haunter.Transform:SetPosition(inst.Transform:GetWorldPosition())
		haunter:DoTaskInTime(0.05,function(haunter)
			haunter.AnimState:SetBuild("wathom")
			haunter.AnimState:SetBank("wilson")
			haunter.AnimState:PlayAnimation("corpse_revive")
			haunter.AnimState:SetDeltaTimeMultiplier(0.5)
			haunter:ListenForEvent("animover",function(haunter) haunter.AnimState:SetDeltaTimeMultiplier(1) end)
		end)
		inst:Remove()
	end
end

local function corpse()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wathom")
    inst.entity:SetPristine()
	inst.AnimState:PlayAnimation("death",false)
	inst.AnimState:SetFrame(inst.AnimState:GetCurrentAnimationNumFrames())
    if not TheWorld.ismastersim then
        return inst
    end


	inst.persists = false
	
	inst:DoTaskInTime(120,function(inst) 
		SpawnPrefab("skeleton").Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst:Remove() 
	end)
	
	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(OnHaunt)
	
	inst:AddComponent("inspectable")
	
    return inst
end
return Prefab("wathom_corpse",corpse)

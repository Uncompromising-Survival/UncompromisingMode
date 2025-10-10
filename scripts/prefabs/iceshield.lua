local function OnHealthDelta(inst, oldpercent, newpercent)
    if oldpercent > newpercent then
        inst._parent.SoundEmitter:PlaySound("meta4/mortars/cannonball_hit_ice")
        SpawnPrefab("mining_ice_fx").Transform:SetPosition(inst._parent.Transform:GetWorldPosition())
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health.nofadeout = true
    inst.components.health.save_maxhealth = true
    inst.components.health.canheal = false
    inst.components.health:SetMaxHealth(100)
    inst.components.health.ondelta = OnHealthDelta
    inst.components.health.externalfiredamagemultipliers:SetModifier(inst, 10)

    inst:DoPeriodicTask(2.5, function(inst)
        if inst.components.health:GetPercent() < 1 then
            inst.components.health:DoDelta(1)
        end
    end)

    inst:ListenForEvent("death", function(inst)
        SpawnPrefab("fx_ice_pop").Transform:SetPosition(inst._parent.Transform:GetWorldPosition())

        if inst.entity:GetParent() ~= nil then
            inst._parent:PushEvent("ice_shield_death")
        end
        inst:Remove()
    end)

    return inst
end

return Prefab("um_ice_shield", fn)

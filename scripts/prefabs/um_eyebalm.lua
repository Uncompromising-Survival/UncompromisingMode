local assets = {
    Asset("ANIM", "anim/um_eyebalm.zip"),
}

local function OnHealFn(inst, target)
    target:AddDebuff("um_eyebalm_buff", "um_eyebalm_buff")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_eyebalm")
    inst.AnimState:SetBuild("um_eyebalm")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "small", 0.05, 0.95)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(0)
    inst.components.healer:SetOnHealFn(OnHealFn)
	
    MakeHauntableLaunch(inst)

    return inst
end

local function buff_OnAttached(inst, target)
    -- NOTES(JBK): Do not apply health over time for this item because of healerbuffs tag.
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

    if target.components.playervision then
		target.components.playervision:ForceGoggleVision(true)
	end
end

local function buff_OnDetached(inst, target)
    if target ~= nil and target:IsValid() and target.components.playervision.forcegogglevision then
		target.components.playervision.forcegogglevision = false
        target:PushEvent("gogglevision", { enabled = target.components.playervision.forcegogglevision })
    end
    inst:Remove()
end

local function buff_Expire(inst)
    if inst.components.debuff ~= nil then
        inst.components.debuff:Stop()
    end
end

local function buff_OnExtended(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task = inst:DoTaskInTime(60*8, buff_Expire)
end

local function buff_OnSave(inst, data)
    if inst.task ~= nil then
        data.remaining = GetTaskRemaining(inst.task)
    end
end

local function buff_OnLoad(inst, data)
    if data == nil then
        return
    end

    if data.remaining then
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
        inst.task = inst:DoTaskInTime(data.remaining, buff_Expire)
    end
end

local function fn_eyebuff()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(buff_OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(buff_OnExtended)
    inst.components.debuff.keepondespawn = true

    buff_OnExtended(inst)

    inst.OnSave = buff_OnSave
    inst.OnLoad = buff_OnLoad

    return inst
end

return Prefab("um_eyebalm", fn, assets),
Prefab("um_eyebalm_buff", fn_eyebuff)
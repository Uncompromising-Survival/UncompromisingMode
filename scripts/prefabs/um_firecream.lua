local assets = {
    Asset("ANIM", "anim/um_firecream.zip"),
}

local function OnHealFn(inst, target)
    target:AddDebuff("um_firecream_buff", "um_firecream_buff")
    target:AddDebuff("confighealbuff_"..inst.prefab, "confighealbuff", {time = 15})
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_firecream")
    inst.AnimState:SetBuild("um_firecream")
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
    inst.components.healer:SetHealthAmount(15)
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

    if target.components.health then
		inst.prior_immunity = target.components.health.fire_damage_scale
		target.components.health.fire_damage_scale = 0
		target:AddTag("PyreToxinImmune")
	end
end

local function buff_OnDetached(inst, target)
    if target.components.health then -- return to normal fire immunity
		target.components.health.fire_damage_scale = inst.prior_immunity
		target:RemoveTag("PyreToxinImmune")
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
		data.prior_immunity = inst.prior_immunity
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
	if data.prior_immunity then
		inst.prior_immunity = data.prior_immunity
	end
end

local function fn_firebuff()
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

return Prefab("um_firecream", fn, assets),
Prefab("um_firecream_buff", fn_firebuff)
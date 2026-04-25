local assets =
{
    Asset("ANIM", "anim/whip.zip"),
    Asset("ANIM", "anim/swap_whip.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_rat_whip", "swap_whip")
    owner.AnimState:OverrideSymbol("whipline", "swap_rat_whip", "whipline")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function HungerScalingCheck(attacker)
    if attacker and attacker.components.hunger then
        local value = math.max(attacker.components.hunger:GetPercent(), .25)
        return 3 * value, value
    end
    return 0, 0
end

local function WhipDamageCheck(inst, attacker, target)
    local HungerScaling = HungerScalingCheck(attacker)
    local BonusDamage = (34 / 3) * HungerScaling
    return 34 + BonusDamage
end

local function onattack(inst, attacker, target)
    if target and target:IsValid() then
        local snap = SpawnPrefab("impact")
        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = -math.atan2(z1 - z, x1 - x)
        snap.Transform:SetPosition(x1, y1, z1)
        snap.Transform:SetRotation(angle * RADIANS)

        --impact sounds normally play through comabt component on the target
        --whip has additional impact sounds logic, which we'll just add here

        if attacker and attacker.components.hunger then
            local value = attacker.components.hunger:GetPercent()
            local hunger = 3

            if value < .25 then value = .25 end

            local scalingvalue = hunger * value

            snap.Transform:SetScale(scalingvalue / 1.25, scalingvalue / 1.25, scalingvalue / 1.25)

            if target.SoundEmitter then target.SoundEmitter:PlaySound("dontstarve/common/whip_small") end

            if attacker.components.hunger:GetPercent() > 0 then
                local burnrate = attacker.components.hunger.burnratemodifiers:Get()
                attacker.components.hunger:DoDelta(-scalingvalue * burnrate)
            end

            local uses1 = 1
            local uses2 = 1
            if attacker.components.efficientuser then
                uses1 = 1 * (attacker.components.efficientuser:GetMultiplier(ACTIONS.ATTACK) or 1) * value
            end

            uses2 = 1 * value

            local uses = uses1 + uses2

            inst.components.fueled:DoDelta(-uses)
        end
    end
end

local function on_uses_finished(inst)
    if inst.components.inventoryitem.owner then
        inst.components.inventoryitem.owner:PushEvent("toolbroke", { tool = inst })
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("whip")
    inst.AnimState:SetBuild("rat_whip")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("whip")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst, "med", nil, .9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(WhipDamageCheck)
    inst.components.weapon:SetRange(TUNING.WHIP_RANGE)
    inst.components.weapon:SetOnAttack(onattack)

    --[[inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.WHIP_USES)
    inst.components.finiteuses:SetUses(TUNING.WHIP_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)]]

    inst:AddComponent("fueled")
    --inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(200)
    inst.components.fueled:SetDepletedFn(on_uses_finished)
    inst.components.fueled.accepting = false
    --inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("rat_whip", fn, assets)
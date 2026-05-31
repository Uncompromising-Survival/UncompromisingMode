local env = env
GLOBAL.setfenv(1, GLOBAL)

local function CommonClientFunctions(inst)
    inst:AddTag("show_broken_ui")
end

local function CommonFunctions(inst, sound, anim)
    local function OnBroken(inst)
        if inst.components.equippable then
            if inst.components.equippable.restrictedtag then
                inst.old_restrictedtag = inst.components.equippable.restrictedtag
            end
            inst.components.equippable.restrictedtag = "brokendown_" .. inst.prefab
        end
        if inst.components.inspectable then
            if inst.components.inspectable.nameoverride then
                inst.old_nameoverride = inst.components.inspectable.nameoverride
            end
            inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
        end
        inst:AddTag("broken")
    end

    local function OnRepaired(inst)
        if inst.components.equippable then
            inst.components.equippable.restrictedtag = inst._equippable_restrictedtag or nil
        end
        if inst.components.inspectable then
            inst.components.inspectable.nameoverride = inst.old_nameoverride or nil
        end
        inst:RemoveTag("broken")
    end

    inst.OnBroken = OnBroken
    inst.OnRepaired = OnRepaired

    if inst.components.armor then
        local _OnBroken = inst.components.armor.onfinished
        local function OnBroken(inst, ...)
            local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
            if inst.components.equippable and inst.components.equippable:IsEquipped() and owner and owner.components.inventory then
                local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
                if item then
                    owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
                end
            end
            inst:OnBroken(inst)
            if _OnBroken then
                _OnBroken(inst, ...)
            end
        end

        local _OnRepair = inst.components.armor.onrepair
        local function OnRepair(inst, amount, ...)
            if inst:HasTag("broken") and amount > 0 then
                inst:OnRepaired(inst)
            end
            if _OnRepair then
                _OnRepair(inst, amount, ...)
            end
        end
        inst.components.armor.onrepair = OnRepair
        inst.components.armor:SetOnFinished(OnBroken)
        inst.components.armor:SetKeepOnFinished(true)
    end

    if TUNING.DSTU.ARMORREWORK and inst.components.eater then
        --local _oneatfn = inst.components.eater.oneatfn
        inst.components.eater.oneatfn = function(inst, food)
            local health = food.components.edible:GetHealth(inst) * inst.components.eater.healthabsorption
            local hunger = food.components.edible:GetHunger(inst) * inst.components.eater.hungerabsorption

            if health < 0 then
                health = food.components.edible:GetHealth(inst)
            end

            if hunger < 0 then
                hunger = food.components.edible:GetHunger(inst)
            end

            local totaltorepair = health + hunger
            if totaltorepair > 0 then inst.components.armor:Repair(totaltorepair) end

            if not inst:IsInLimbo() then
                inst.AnimState:PlayAnimation("eat")
                inst.AnimState:PushAnimation(anim, true)
            end
            inst.SoundEmitter:PlaySound(totaltorepair <= 0 and "dontstarve/common/teleportworm/sick_cough" or "terraria1/" .. sound .. "/eat")
            --if _oneatfn then
            --_oneatfn(inst, food)
            --end
        end
    end
end

local function OnAttack(inst, attacker, target)
    local efficientuser = attacker.components.efficientuser and attacker.components.efficientuser:GetMultiplier(ACTIONS.ATTACK) or 1
    local useMult = efficientuser * inst.components.weapon.attackwearmultipliers:Get()

    inst.components.armor:TakeDamage(TUNING.SHIELDOFTERROR_USEDAMAGE * useMult)
end

local function castspell(inst, target, pos, doer)
    UMCommonFns.StartRechargeableCooldown(inst, {cooldown = TUNING.DSTU.SHIELDOFTERROR_COOLDOWN, tags = {"shieldofterror"}})
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:HasTag("vetcurse") and inst.components.equippable and inst.components.equippable:IsEquipped() then
        inst.components.aoetargeting:SetEnabled(true)
    end
end

local function ShieldBash(inst, doer, pos)
    UMCommonFns.StartRechargeableCooldown(inst, {cooldown = TUNING.DSTU.SHIELDOFTERROR_COOLDOWN, tags = {"shieldofterror"}})
    return true
end

local function ToggleItemVetcurse(inst, toggle)
    if inst._vetcurseupgraded and inst._vetcurseupgraded:value() ~= not toggle then return end
    if toggle then
        inst._vetcurseupgraded:set(true)

        local aoespell = inst.components.aoespell or inst:AddComponent("aoespell")
        aoespell:SetSpellFn(ShieldBash)

        if inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.aoetargeting then
            inst.components.aoetargeting:SetEnabled(inst.components.rechargeable and inst.components.rechargeable:IsCharged() or false)
        end

        --todo: visual stuff?
    else
        inst._vetcurseupgraded:set(false)

        inst:RemoveComponent("aoespell")

        if inst.components.aoetargeting and inst.components.aoetargeting:IsEnabled() then
            inst.components.aoetargeting:SetEnabled(false)
        end
    end
end

local function ReticuleTargetFn(inst)
    return Vector3(inst.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then return inst.components.reticule.targetpos end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function OnPutInInventory(inst, owner)
    if inst.UMToggleItemVetcurse then inst:UMToggleItemVetcurse(owner:HasTag("vetcurse")) end
end

env.AddPrefabPostInit("shieldofterror", function(inst)
    CommonClientFunctions(inst)
    inst:AddTag("shieldofterror")
    inst:AddTag("rechargeable")

    inst._vetcurseupgraded = net_bool(inst.GUID, "shieldofterror.vetcurse", "vetcursedirty")
    inst._vetcurseupgraded:set(false)

    local aoetargeting = inst.components.aoetargeting or inst:AddComponent("aoetargeting")
    aoetargeting:SetAllowRiding(false)
    aoetargeting.reticule.reticuleprefab = "reticuleline2"
    aoetargeting.reticule.pingprefab = "reticulelongping"
    aoetargeting.reticule.targetfn = ReticuleTargetFn
    aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    aoetargeting.reticule.validcolour = { 1, 1, 1, 1 }
    aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    aoetargeting.reticule.ease = true
    aoetargeting.reticule.mouseenabled = true

    if not TheWorld.ismastersim then return end

    aoetargeting:SetEnabled(false)

    if TUNING.DSTU.ARMORREWORK and inst.components.armor then
        inst.components.armor:InitCondition(TUNING.SHIELDOFTERROR_ARMOR * 2.333, TUNING.SHIELDOFTERROR_ABSORPTION)
    end

    if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED and inst.components.weapon then
        inst._weaponused_callback = function(_, data) end -- Leave empty function. Will crash if set to nil
        inst.components.weapon:SetOnAttack(OnAttack)      -- Use the normal attack function instead
    end

    CommonFunctions(inst, "eye_shield", "idle")

    local rechargeable = inst.components.rechargeable or inst:AddComponent("rechargeable")
    rechargeable:SetOnDischargedFn(OnDischarged)
    rechargeable:SetOnChargedFn(OnCharged)

    local equippable = inst.components.equippable
    local _OnEquip = equippable.onequipfn
    local function OnEquip(inst, owner, ...)
        local ret = _OnEquip(inst, owner, ...)
        if inst.components.aoetargeting and owner:HasTag("vetcurse") then
            inst.components.aoetargeting:SetEnabled(inst.components.rechargeable and inst.components.rechargeable:IsCharged() or false)
        end
        return ret
    end
    equippable:SetOnEquip(OnEquip)

    local _OnUnequip = equippable.onunequipfn
    local function OnUnequip(inst, owner, ...)
        local ret = _OnUnequip(inst, owner, ...)
        if inst.components.aoetargeting and inst.components.aoetargeting:IsEnabled() then
            inst.components.aoetargeting:SetEnabled(false)
        end
        return ret
    end
    equippable:SetOnUnequip(OnUnequip)

    inst.UMToggleItemVetcurse = ToggleItemVetcurse

    inst:ListenForEvent("onputininventory", OnPutInInventory)
end)

env.AddPrefabPostInit("eyemaskhat", function(inst)
    CommonClientFunctions(inst)
    if not TheWorld.ismastersim then return end
    CommonFunctions(inst, "eyemask", "anim")
end)
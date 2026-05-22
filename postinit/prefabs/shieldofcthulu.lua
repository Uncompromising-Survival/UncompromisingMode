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
    inst.components.rechargeable:Discharge(5)
end

local function can_cast_fn(doer, target, pos, inst)
    return inst.components.rechargeable:IsCharged()
end

local function UpgradeItemVetcurse(inst)
    if not inst.components.equippable:IsEquipped() then return end

    inst.spelltype = "UM_SHIELD_BASH"


    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(castspell)
    inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseondead = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster.canusefrominventory = false

    inst._vetcurseupgraded:set(true)

    --todo: visual stuff?
end

local function RemoveItemVetcurse(inst)
    inst.spelltype = nil
    inst:RemoveComponent("spellcaster")
    inst._vetcurseupgraded:set(false)
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
        rot = Lerp((drot > 180 and rot0 + 360) or drot < -180 and rot0 - 360 or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

env.AddPrefabPostInit("shieldofterror", function(inst)
    CommonClientFunctions(inst)
    inst:AddTag("shieldofterror")

    inst._vetcurseupgraded = net_bool(inst.GUID, "shieldofterror.vetcurse", "vetcursedirty")
    inst._vetcurseupgraded:set(false)

    inst:ListenForEvent("vetcursedirty", function(inst)
        local toggle = inst._vetcurseupgraded:value()

        if toggle then
            inst.spelltype = "UM_SHIELD_BASH"

            inst:AddComponent("reticule")
            inst.components.reticule.reticuleprefab = "reticuleline2"
            inst.components.reticule.pingprefab = "reticulelongping"
            -- inst.components.reticule.reticuleprefab = "reticuleline2"
            -- inst.components.reticule.pingprefab = "reticulelineping"
            inst.components.reticule.targetfn = ReticuleTargetFn
            inst.components.reticule.mousetargetfn = ReticuleMouseTargetFn
            inst.components.reticule.updatepositionfn = ReticuleUpdatePositionFn
            inst.components.reticule.validcolour = { 1, 1, 1, 1 }
            inst.components.reticule.invalidcolour = { .5, 0, 0, 1 }
            inst.components.reticule.ease = true
            inst.components.reticule.mouseenabled = true
            inst.components.reticule.ispassableatallpoints = true
        else
            inst.spelltype = nil
            inst:RemoveComponent("reticule")
        end
    end)

    if not TheWorld.ismastersim then return end

    if TUNING.DSTU.ARMORREWORK and inst.components.armor then
        inst.components.armor:InitCondition(TUNING.SHIELDOFTERROR_ARMOR * 2.333, TUNING.SHIELDOFTERROR_ABSORPTION)
    end

    if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED and inst.components.weapon then
        inst._weaponused_callback = function(_, data) end --Leave empty function. Will crash if set to nil
        inst.components.weapon:SetOnAttack(OnAttack)      -- Use the normal attack function instead
    end

    CommonFunctions(inst, "eye_shield", "idle")

    inst:AddComponent("rechargeable")

    local _onequip = inst.components.equippable.onequipfn
    local _onunequip = inst.components.equippable.onunequipfn
    local function OnEquip(inst, owner)
        if owner:HasTag("vetcurse") then
            UpgradeItemVetcurse(inst)
        end
        _onequip(inst, owner)
    end

    local function OnUnequip(inst, owner)
        RemoveItemVetcurse(inst)
        _onunequip(inst, owner)
    end

    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.UpgradeItemVetcurse = UpgradeItemVetcurse
    inst.RemoveItemVetcurse = RemoveItemVetcurse
end)

env.AddPrefabPostInit("eyemaskhat", function(inst)
    CommonClientFunctions(inst)
    if not TheWorld.ismastersim then return end
    CommonFunctions(inst, "eyemask", "anim")
end)

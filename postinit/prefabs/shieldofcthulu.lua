local env = env
GLOBAL.setfenv(1, GLOBAL)

local function CommonClientFunctions(inst)
    inst:AddTag("show_broken_ui")
end

local function CommonFunctions(inst, sound, anim)
    inst.OnBroken = function(_inst)
        if _inst.components.equippable then
            if _inst.components.equippable.restrictedtag then
                _inst.um_equippable_restrictedtag = _inst.components.equippable.restrictedtag
            end
            _inst.components.equippable.restrictedtag = "brokendown_".._inst.prefab -- This does mean that Mannequins can equip this.
        end
        if _inst.components.inspectable then
            if _inst.components.inspectable.nameoverride then
                _inst.um_inspectable_nameoverride = _inst.components.inspectable.nameoverride
            end
            _inst.components.inspectable:SetNameOverride("BROKEN_FORGEDITEM")
        end
        _inst:AddTag("broken")
    end

    inst.OnRepaired = function(_inst)
        if _inst.components.equippable then
            _inst.components.equippable.restrictedtag = _inst.um_equippable_restrictedtag or nil
            _inst.um_equippable_restrictedtag = nil
        end
        if _inst.components.inspectable then
            _inst.components.inspectable:SetNameOverride(_inst.um_inspectable_nameoverride or nil)
            _inst.um_inspectable_nameoverride = nil
        end
        _inst:RemoveTag("broken")
    end

    local armor = inst.components.armor
    if armor then
        local _OnBroken = armor.onfinished
        armor:SetOnFinished(function(_inst, ...)
            local owner = _inst.components.inventoryitem and _inst.components.inventoryitem.owner
            if _inst.components.equippable and _inst.components.equippable:IsEquipped() and owner and owner.components.inventory then
                local item = owner.components.inventory:Unequip(_inst.components.equippable.equipslot)
                if item then
                    owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
                end
            end
            _inst:OnBroken()
            if _OnBroken then _OnBroken(_inst, ...) end
        end)
        local _OnRepair = armor.onrepair
        armor.onrepair = function(_inst, amount, ...)
            if _inst:HasTag("broken") and amount > 0 then
                _inst:OnRepaired()
            end
            if _OnRepair then _OnRepair(_inst, amount, ...) end
        end
        armor:SetKeepOnFinished(true)
    end

    local eater = TUNING.DSTU.ARMORREWORK and inst.components.eater
    if eater then
        --local _oneatfn = eater.oneatfn
        eater:SetOnEatFn(function(_inst, food)
            local health = food.components.edible:GetHealth(_inst) * _inst.components.eater.healthabsorption
            local hunger = food.components.edible:GetHunger(_inst) * _inst.components.eater.hungerabsorption

            if health < 0 then
                health = food.components.edible:GetHealth(_inst)
            end

            if hunger < 0 then
                hunger = food.components.edible:GetHunger(_inst)
            end

            local totaltorepair = health + hunger
            if totaltorepair > 0 then _inst.components.armor:Repair(totaltorepair) end

            if not _inst:IsInLimbo() then
                _inst.AnimState:PlayAnimation("eat")
                _inst.AnimState:PushAnimation(anim, true)
            end
            _inst.SoundEmitter:PlaySound(totaltorepair <= 0 and "dontstarve/common/teleportworm/sick_cough" or "terraria1/" .. sound .. "/eat")
            --if _oneatfn then _oneatfn(_inst, food) end
        end)
    end
end

local function OnVetcurseDirty(inst)
    if inst._vetcurseupgraded:value() then
        inst.spelltype = "UM_SHIELD_BASH"
        inst:AddTag("allow_action_on_impassable")
    else
        inst.spelltype = nil
        inst:RemoveTag("allow_action_on_impassable")
    end
end

local function OnCharged(inst)
    inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge", nil, .4)
end

local function OnAttack(inst, attacker, target)
    local efficientuser = attacker.components.efficientuser and attacker.components.efficientuser:GetMultiplier(ACTIONS.ATTACK) or 1
    local useMult = efficientuser * inst.components.weapon.attackwearmultipliers:Get()

    inst.components.armor:TakeDamage(TUNING.SHIELDOFTERROR_USEDAMAGE * useMult)
end

local function castspell(inst, target, pos, doer)
    UMCommonFns.StartRechargeableCooldown(inst, {cooldown = TUNING.DSTU.SHIELDOFTERROR_COOLDOWN, tags = {"shieldofterror"}})
end

local function CanCastFn(doer, target, pos, inst)
    return inst.components.rechargeable:IsCharged()
end

local function ToggleItemVetcurse(inst, toggle)
    if inst._vetcurseupgraded and inst._vetcurseupgraded:value() ~= not toggle then return end
    if toggle then
        inst._vetcurseupgraded:set(true)

        inst.spelltype = "UM_SHIELD_BASH"

        local spellcaster = inst:AddComponent("spellcaster")
        spellcaster:SetSpellFn(castspell)
        spellcaster:SetCanCastFn(CanCastFn)
        spellcaster.canuseontargets = true
        spellcaster.canuseondead = true
        spellcaster.canuseonpoint = true
        spellcaster.canuseonpoint_water = true

        --todo: visual stuff?
    else
        inst._vetcurseupgraded:set(false)

        inst.spelltype = nil
        inst:RemoveComponent("spellcaster")
    end
end

local function OnPutInInventory(inst, owner)
    if inst.UMToggleItemVetcurse then inst:UMToggleItemVetcurse(owner:HasTag("vetcurse")) end
end

env.AddPrefabPostInit("shieldofterror", function(inst)
    CommonClientFunctions(inst)
    inst:AddTag("shieldofterror")

    inst._vetcurseupgraded = net_bool(inst.GUID, "shieldofterror.vetcurse", "vetcursedirty")
    inst._vetcurseupgraded:set(false)

    inst:ListenForEvent("vetcursedirty", OnVetcurseDirty)

    inst.um_cancastontarget = UMCommonFns.DefaultCanCastOnTarget

    if not TheWorld.ismastersim then return end

    if TUNING.DSTU.ARMORREWORK and inst.components.armor then
        inst.components.armor:InitCondition(TUNING.SHIELDOFTERROR_ARMOR * 2.333, TUNING.SHIELDOFTERROR_ABSORPTION)
    end

    if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED and inst.components.weapon then
        inst._weaponused_callback = function(_, data) end --Leave empty function. Will crash if set to nil
        inst.components.weapon:SetOnAttack(OnAttack)      -- Use the normal attack function instead
    end

    CommonFunctions(inst, "eye_shield", "idle")

    local rechargeable = inst.components.rechargeable or inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    inst.UMToggleItemVetcurse = ToggleItemVetcurse

    inst:ListenForEvent("onputininventory", OnPutInInventory)
end)

env.AddPrefabPostInit("eyemaskhat", function(inst)
    CommonClientFunctions(inst)
    if not TheWorld.ismastersim then return end
    CommonFunctions(inst, "eyemask", "anim")
end)
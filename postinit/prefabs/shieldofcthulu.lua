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
            inst.components.equippable.restrictedtag = "brokendown_"..inst.prefab
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

            inst.components.armor:Repair(math.max(health + hunger, 0.05)) -- Don't go below the set value.

            if not inst:IsInLimbo() then
                inst.AnimState:PlayAnimation("eat")
                inst.AnimState:PushAnimation(anim, true)
            end
            inst.SoundEmitter:PlaySound(health + hunger <= 0 and "dontstarve/common/teleportworm/sick_cough" or "terraria1/"..sound.."/eat")
            --if _oneatfn then
                --_oneatfn(inst, food)
            --end
        end
    end
end

local function OnAttack(inst, attacker, target)
    inst.components.armor:TakeDamage(TUNING.SHIELDOFTERROR_USEDAMAGE * inst.components.weapon.attackwearmultipliers:Get())
end

env.AddPrefabPostInit("shieldofterror", function(inst)
    CommonClientFunctions(inst)

    if not TheWorld.ismastersim then return end

    if TUNING.DSTU.ARMORREWORK and inst.components.armor then
        inst.components.armor:InitCondition(TUNING.SHIELDOFTERROR_ARMOR * 2.333, TUNING.SHIELDOFTERROR_ABSORPTION)
    end

    if TUNING.DSTU.WATHGRITHR_REWORK == 1 and inst.components.weapon then
        inst._weaponused_callback = function(_, data) end --Leave empty function. Will crash if set to nil
        inst.components.weapon:SetOnAttack(OnAttack) -- Use the normal attack function instead
    end

    CommonFunctions(inst, "eye_shield", "idle")
end)

env.AddPrefabPostInit("eyemaskhat", function(inst)
    CommonClientFunctions(inst)
    if not TheWorld.ismastersim then return end
    CommonFunctions(inst, "eyemask", "anim")
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function OnCooldown(inst)
    inst._cdtask = nil
end

local function OnBlocked(owner, data, inst)
    if not inst._cdtask and data and not data.redirected then
        inst._cdtask = inst:DoTaskInTime(.3, OnCooldown)

        SpawnPrefab("cookiespikes"):SetFXOwner(owner)

        if owner.SoundEmitter then
            owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
        end
    end

    if data.original_damage and data.attacker and data.attacker.components.combat and not (data.attacker.components.health and data.attacker.components.health:IsDead())
        and (not data.weapon or ((not data.weapon.components.weapon or not data.weapon.components.weapon.projectile) and not data.weapon.components.projectile)) and
        not data.redirected and not data.attacker:HasAnyTag("thorny", "companion", "abigail") and data.attacker.components.combat:CanBeAttacked() then
        local damage = data.original_damage * .75
        data.attacker.components.combat:GetAttacked(inst, damage)
    end
end

env.AddPrefabPostInit("cookiecutterhat", function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.equippable then
        inst._onblocked = function(owner, data) OnBlocked(owner, data, inst) end

        local _OldOnEquip = inst.components.equippable.onequipfn
        inst.components.equippable.onequipfn = function(inst, owner)
            inst:ListenForEvent("blocked", inst._onblocked, owner)
            inst:ListenForEvent("attacked", inst._onblocked, owner)

            if _OldOnEquip then
                _OldOnEquip(inst, owner)
            end
        end

        local _OldOnUnequip = inst.components.equippable.onunequipfn
        inst.components.equippable.onunequipfn = function(inst, owner)
            inst:RemoveEventCallback("blocked", inst._onblocked, owner)
            inst:RemoveEventCallback("attacked", inst._onblocked, owner)

            if _OldOnUnequip then
                _OldOnUnequip(inst, owner)
            end
        end
    end
end)
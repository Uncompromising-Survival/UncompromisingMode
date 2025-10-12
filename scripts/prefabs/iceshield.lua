local function OnHealthDelta(inst, oldpercent, newpercent)
    if oldpercent > newpercent then
        inst._parent.SoundEmitter:PlaySound("meta4/mortars/cannonball_hit_ice")
        SpawnPrefab("mining_ice_fx").Transform:SetPosition(inst._parent.Transform:GetWorldPosition())
    end
end

local function ShouldWeaponPierce(inst, weapon, attacker)
    if weapon ~= nil and (weapon:HasTag("pierces_ice_shield") or weapon.components.obsidiantool ~= nil) --IA compat
        or attacker ~= nil and attacker:HasTag("pierces_ice_shield") then
        return true
    end

    if weapon ~= nil then
        if weapon.components.weapon ~= nil then
            return weapon.components.weapon.stimuli == "fire" or weapon.components.weapon:GetDamage(attacker, inst) == 0
        end
    end

    return false
end
local function ShouldRecoilIceShield(inst, attacker, weapon, damage)
    print("should recoil", inst, attacker, weapon, damage)
    if inst:HasTag("ice_shielded") and not ShouldWeaponPierce(inst, weapon, attacker) then
        if attacker ~= nil and attacker.components.talker ~= nil then
            attacker.components.talker:Say(GetString(inst, "ANNOUNCE_WEAPON_TOOWEAK_ICESHIELD"))
        end
    end
    return inst:HasTag("ice_shielded") and not ShouldWeaponPierce(inst, weapon, attacker), (ShouldWeaponPierce(inst, weapon, attacker) or not inst:HasTag("ice_shielded")) and damage or damage ~= nil and damage / 2 or nil
end

local function Init(inst, parent, fx_symbol, tier)
    inst.tier = tier
    inst._parent = parent

    inst.components.health:SetMaxHealth(200 * tier)

    parent:AddTag("ice_shielded")

    local fx = SpawnPrefab("fx_ice_crackle")
    fx.Transform:SetPosition(parent.Transform:GetWorldPosition())
    fx.entity:AddFollower()
    fx.Follower:FollowSymbol(parent.GUID, fx_symbol, 0, 0, 0)


    if parent.ice_shield ~= nil then
        parent.ice_shield:Remove()
    end

    parent.ice_shield = inst
    inst.entity:SetParent(parent.entity)
    inst.Transform:SetPosition(parent.Transform:GetWorldPosition())

    if parent.components.health ~= nil then
        parent.components.health.redirect = function(target, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
            print("redirect", target, cause == "fire" and amount * 10 or amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
            if inst.components.health ~= nil and inst:IsValid() then
                if cause == "fire" then
                    amount = amount * 10
                    SpawnPrefab("washashore_puddle_fx").Transform:SetPosition(parent.Transform:GetWorldPosition())
                end

                return inst.components.health:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb, ...)
            end
        end
    end

    if parent.components.combat ~= nil then
        parent.components.combat:SetShouldRecoilFn(ShouldRecoilIceShield)
    end

    if parent.shield_fx ~= nil then
        parent.shield_fx:Remove()
    end

    print("spawning shield FX")
    parent.shield_fx = SpawnPrefab("deer_ice_flakes")
    parent.shield_fx.Transform:SetPosition(parent.Transform:GetWorldPosition())
    parent.shield_fx.entity:AddFollower()
    parent.shield_fx.Follower:FollowSymbol(parent.GUID, fx_symbol, 0, 0, 0)
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

    inst.tier = 1

    inst:AddComponent("health")
    inst.components.health.nofadeout = true
    inst.components.health.save_maxhealth = true
    inst.components.health.canheal = false
    inst.components.health:SetMaxHealth(200)
    inst.components.health.ondelta = OnHealthDelta
    --inst.components.health.externalfiredamagemultipliers:SetModifier(inst, 10)
    --this doesn't work as expected. It never actually gets fire damaged directly. fire damage mults are on the redirect.

    inst:DoPeriodicTask(2.5, function(inst)
        if inst.components.health:GetPercent() < 1 then
            inst.components.health:DoDelta(1 * inst.tier)
        end
    end)

    inst.Init = Init

    inst:ListenForEvent("death", function(inst)
        SpawnPrefab("fx_ice_pop").Transform:SetPosition(inst._parent.Transform:GetWorldPosition())

        if inst._parent ~= nil then
            inst._parent:RemoveTag("ice_shielded") --damn you!! GET RID OF IT!
            inst._parent:PushEvent("ice_shield_death")

            if inst._parent.shield_fx ~= nil then
                inst._parent.shield_fx:Remove()
            end

            if inst._parent.components.burnable ~= nil then
                inst._parent.components.burnable:Extinguish()
            end
        end

        inst:Remove()
    end)

    inst:ListenForEvent("removed", function(inst)
        if inst._parent ~= nil then
            inst._parent:RemoveTag("ice_shielded")
            inst._parent.components.health.redirect = nil
        end
    end)

    return inst
end

return Prefab("um_ice_shield", fn)

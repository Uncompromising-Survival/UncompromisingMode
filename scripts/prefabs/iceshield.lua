local function OnHealthDelta(inst, oldpercent, newpercent, overtime, cause, afflicter, amount)
	local t = GetTime()
    if amount < 0 and (not overtime or cause == "fire") and (t - inst.lasthitfxtime) >= .1 then
        inst.lasthitfxtime = t
        inst._parent.SoundEmitter:PlaySound("meta4/mortars/cannonball_hit_ice")
        SpawnPrefab("mining_ice_fx").Transform:SetPosition(inst._parent.Transform:GetWorldPosition())
    end
end

local function ShouldWeaponPierce(inst, weapon, attacker)
    --minerology
    if weapon ~= nil and weapon.components.gem_enchantable ~= nil and weapon.components.gem_enchantable:HasEnchantment("um_gemologyredgem2") then
        return true
    end

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
        if parent.components.health.redirect then
            inst.redirect_old = parent.components.health.redirect
        end
        parent.components.health.redirect = function(self, amount, overtime, cause, ...)
            if amount >= 0 then
                return inst.redirect_old and inst.redirect_old(self, amount, overtime, cause, ...) or false
            end
            if inst.components.health ~= nil and inst:IsValid() then
                if cause == "fire" then
                    amount = amount * 10
                    SpawnPrefab("washashore_puddle_fx").Transform:SetPosition(parent.Transform:GetWorldPosition())
                end

                inst.components.health:DoDelta(amount, overtime, cause, ...)

                return true
            end
        end
    end

    if parent.components.combat ~= nil then
        parent.components.combat:SetShouldRecoilFn(ShouldRecoilIceShield)
    end

    if parent.shield_fx ~= nil then
        parent.shield_fx:Remove()
    end

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
    inst.lasthitfxtime = 0

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

    inst:ListenForEvent("onremove", function(inst)
        if inst._parent ~= nil then
            inst._parent:RemoveTag("ice_shielded")
            inst._parent.components.health.redirect = inst.redirect_old and inst.redirect_old or nil
        end
    end)

    return inst
end

return Prefab("um_ice_shield", fn)

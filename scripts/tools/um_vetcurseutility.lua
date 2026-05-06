local UMVetCurse = {}

-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------
----------------------------------ATTACH---------------------------------
local TARGET_MUST_TAGS = {"mime", "pinetreepioneer", "plantkin", "wathom", "shadowmagic", "winky"}

local function ForceToTakeMoreDamage(inst)
    local self = inst.components.combat
    local _GetAttacked = self.GetAttacked
    if not inst.OldCombatGetAttacked then
        inst.OldCombatGetAttacked = _GetAttacked
    end
    self.GetAttacked = function(self, attacker, damage, weapon, stimuli, ...)
        if attacker and damage then
            if not inst:HasAnyTag(TARGET_MUST_TAGS) then
                -- Take extra damage
                damage = damage * (1 + (2 / 10))
            end
        end
        return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
    end
end

local function ForceToTakeMoreHunger(inst)
    local self = inst.components.hunger
    local _DoDelta = self.DoDelta
    if not inst.OldHungerDoDelta then
        inst.OldHungerDoDelta = _DoDelta
    end
    self.DoDelta = function(self, delta, overtime, ignore_invincible)
        if delta and overtime and delta < 0 then
            if not inst:HasAnyTag(TARGET_MUST_TAGS) then
                -- Take extra hunger
                delta = delta * (1 + (2 / 10))
            end
        end
        return _DoDelta(self, delta, overtime, ignore_invincible)
    end
end

local function ForceToTakeMoreTime(inst)
    local self = inst.components.oldager
    local _OnTakeDamage = self.OnTakeDamage
    if not inst.OldOldAgerOnTakeDamage then
        inst.OldOldAgerOnTakeDamage = _OnTakeDamage
    end
    self.OnTakeDamage = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if amount and overtime and amount < 0 then
            if not inst:HasAnyTag(TARGET_MUST_TAGS) then
                -- Take extra time
                amount = amount * (1 + (2 / 10))
            end
        end
        return _OnTakeDamage(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
end
----------------------------------DETACH---------------------------------
local function ForceToTakeUsualDamage(inst)
    local self = inst.components.combat
    if inst.OldCombatGetAttacked then
        self.GetAttacked = inst.OldCombatGetAttacked
        inst.OldCombatGetAttacked = nil
    end
end

local function ForceToTakeUsualHunger(inst)
    local self = inst.components.hunger
    if inst.OldHungerDoDelta then
        self.DoDelta = inst.OldHungerDoDelta
        inst.OldHungerDoDelta = nil
    end
end

local function ForceToTakeUsualTime(inst)
    local self = inst.components.oldager
    if inst.OldOldAgerOnTakeDamage then
        self.OnTakeDamage = inst.OldOldAgerOnTakeDamage
        inst.OldOldAgerOnTakeDamage = nil
    end
end
--------------------------------------------------------------------------
local function oneat(inst, data)
    if not inst.modded_healthabsorption then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if not inst.modded_hungerabsorption then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if not inst.modded_sanityabsorption then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.wolfgang_vetcurse and 0 or inst.modded_hungerabsorption or 1, 0)

    local stack_mult = inst.components.eater.eatwholestack and data.food.components.stackable and data.food.components.stackable:StackSize() or 1

    local base_mult = inst.components.foodmemory and inst.components.foodmemory:GetFoodMultiplier(data.food.prefab) or 1
    local maxhp_heal = string.find(data.food.prefab, "spice_salt") ~= nil

    local warlybuff = inst:HasTag("warlybuffed") and 1.2 or 1

    local health_delta = 0
    local hunger_delta = 0
    local sanity_delta = 0

    if inst.components.health and
        (data.food.components.edible.healthvalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        health_delta = data.food.components.edible:GetHealth(inst) * base_mult * inst.modded_healthabsorption * warlybuff
    end

    if inst.components.hunger and
        (data.food.components.edible.hungervalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        hunger_delta = data.food.components.edible:GetHunger(inst) * base_mult * inst.modded_hungerabsorption * warlybuff
    end

    if inst.components.sanity and
        (data.food.components.edible.sanityvalue >= 0 or inst.components.eater:DoFoodEffects(data.food)) then
        sanity_delta = data.food.components.edible:GetSanity(inst) * base_mult * inst.modded_sanityabsorption * warlybuff
    end

    if inst.components.eater.custom_stats_mod_fn then
        health_delta, hunger_delta, sanity_delta = inst.components.eater.custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, data.food, data.feeder)
    end

    --[[local foodaffinitysanitybuff = inst:HasTag("playermerm") and (data.food.prefab == "kelp" or data.food.prefab == "kelp_cooked") and 0 or inst.components.foodaffinity:HasPrefabAffinity(data.food) and 15 or 0
    sanity_delta = sanity_delta + foodaffinitysanitybuff]]

    if health_delta > 3 and not (inst:HasTag("ignores_foodregen") or inst:HasTag("ignores_healthregen")) then
        inst.components.debuffable:AddDebuff("healthregenbuff_vetcurse_" .. data.food.prefab, "healthregenbuff_vetcurse", {duration = (health_delta * 0.1)})
    else
        inst.components.health:DoDelta(health_delta, nil, data.food.prefab)
    end

    if inst.wolfgang_vetcurse then
        if hunger_delta > 1 then
            inst.components.debuffable:AddDebuff("hungerregenbuff_vetcurse_" .. data.food.prefab, "hungerregenbuff_vetcurse", {duration = (hunger_delta * 0.1)})
        else
            inst.components.hunger:DoDelta(hunger_delta)
        end
    end

    if sanity_delta > 3 and not (inst:HasTag("ignores_foodregen") or inst:HasTag("ignores_sanityregen")) then
        inst.components.debuffable:AddDebuff("sanityregenbuff_vetcurse_" .. data.food.prefab, "sanityregenbuff_vetcurse", {duration = (sanity_delta * 0.1)})
    else
        inst.components.sanity:DoDelta(sanity_delta, nil, data.food.prefab)
    end
end

local function ForceOvertimeFoodEffects(inst)
    if not inst.modded_healthabsorption then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if not inst.modded_hungerabsorption then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if not inst.modded_sanityabsorption then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.wolfgang_vetcurse and 0 or inst.modded_hungerabsorption or 1, 0)

    inst:ListenForEvent("oneat", oneat)
end

local function ForceUsualFoodEffects(inst)
    inst.components.eater:SetAbsorptionModifiers(inst.modded_healthabsorption, inst.modded_hungerabsorption, inst.modded_sanityabsorption)

    inst:RemoveEventCallback("oneat", oneat)
end

local function AttachCurse(target)
    if target.components.combat then
        --target.components.combat.externaldamagemultipliers:SetModifier(inst, .75) -- Effect Removed
        target.vetcurse = true

        if target.components and target.components.oldager then
            ForceToTakeMoreTime(target)
        else
            ForceToTakeMoreDamage(target)
        end

        ForceToTakeMoreHunger(target)
        ForceOvertimeFoodEffects(target)
        target:AddTag("vetcurse")
    end
end

local function DetachCurse(target)
    if target.components.combat then
        --target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        target.vetcurse = nil

        if target.components and target.components.oldager then --taking a guess thats what her tag is, I swear, I actually don't know
            ForceToTakeUsualTime(target)
        else
            ForceToTakeUsualDamage(target)
        end

        ForceToTakeUsualHunger(target)
        ForceUsualFoodEffects(target)
        target:RemoveTag("vetcurse")
    end
end

UMVetCurse.ToggleVetCurse = function(inst, toggle)
    if toggle then
        AttachCurse(inst)
    else
        DetachCurse(inst)
    end
    if inst.UMToggleUniqueVetCurse then inst:UMToggleUniqueVetCurse(toggle) end
end

return UMVetCurse
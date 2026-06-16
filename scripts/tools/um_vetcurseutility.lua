local UMVetCurse = {}

-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------
----------------------------------ATTACH---------------------------------
--local TARGET_MUST_TAGS = {"mime", "pinetreepioneer", "plantkin", "wathom", "shadowmagic", "winky"}

UMVetCurse.ToggleDamageTakenModifier = function(inst, toggle)
    local combat = inst.components.combat
    if not combat then return end
    if toggle then
        combat.externaldamagetakenmultipliers:SetModifier(inst, TUNING.DSTU.VETCURSE_DAMAGE_TAKEN_MULT, "um_vetcurse_damage_taken")
    else
        combat.externaldamagetakenmultipliers:RemoveModifier(inst, "um_vetcurse_damage_taken")
    end
end

--[[UMVetCurse.ToggleHungerRateModifier = function(inst, toggle)
    local hunger = inst.components.hunger
    if not hunger then return end
    if toggle then
        hunger.burnratemodifiers:SetModifier(inst, TUNING.DSTU.VETCURSE_HUNGER_RATE, "um_vetcurse_hunger_rate")
    else
        hunger.burnratemodifiers:RemoveModifier(inst, "um_vetcurse_hunger_rate")
    end
end]]

UMVetCurse.ToggleHungerTakenModifier = function(inst, toggle)
    local hunger = inst.components.hunger
    if not hunger then return end
    if toggle then
        local _DoDelta = hunger.DoDelta
        if not inst.OldHungerDoDelta then
            inst.OldHungerDoDelta = _DoDelta
        end
        hunger.DoDelta = function(self, delta, overtime, ignore_invincible, ...)
            if delta and overtime and delta < 0 then
                -- Take extra hunger
                delta = delta * (1 + (2 / 10))
            end
            return _DoDelta(self, delta, overtime, ignore_invincible, ...)
        end
    else
        if inst.OldHungerDoDelta then
            hunger.DoDelta = inst.OldHungerDoDelta
            inst.OldHungerDoDelta = nil
        end
    end
end

local function oneat(inst, data)
    local eater = inst.components.eater
    if not inst.modded_healthabsorption then
        inst.modded_healthabsorption = eater.healthabsorption
    end

    if not inst.modded_hungerabsorption then
        inst.modded_hungerabsorption = eater.hungerabsorption
    end

    if not inst.modded_sanityabsorption then
        inst.modded_sanityabsorption = eater.sanityabsorption
    end

    eater:SetAbsorptionModifiers(0, inst.modded_hungerabsorption or 1, 0)

    local stack_mult = eater.eatwholestack and data.food.components.stackable and data.food.components.stackable:StackSize() or 1
    local base_mult = inst.components.foodmemory and inst.components.foodmemory:GetFoodMultiplier(data.food.prefab) or 1
    local warlybuff = inst:HasTag("warlybuffed") and 1.2 or 1

    local health_delta = inst.components.health and (data.food.components.edible:GetHealth(inst) >= 0 or eater:DoFoodEffects(data.food))
        and data.food.components.edible:GetHealth(inst) * base_mult * inst.modded_healthabsorption * warlybuff or 0
    local sanity_delta = inst.components.sanity and (data.food.components.edible:GetSanity(inst) >= 0 or eater:DoFoodEffects(data.food))
        and data.food.components.edible:GetSanity(inst) * base_mult * inst.modded_sanityabsorption * warlybuff or 0
    local hunger_delta = 0

    if eater.custom_stats_mod_fn then
        health_delta, hunger_delta, sanity_delta = eater.custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, data.food, data.feeder)
    end

    --[[local foodaffinitysanitybuff = inst:HasTag("playermerm") and (data.food.prefab == "kelp" or data.food.prefab == "kelp_cooked") and 0 or inst.components.foodaffinity:HasPrefabAffinity(data.food) and 15 or 0
    sanity_delta = sanity_delta + foodaffinitysanitybuff]]

    if inst:HasTag("wathom") and inst.components.foodaffinity:HasPrefabAffinity(data.food) then
        health_delta = health_delta + 20
    end

    if health_delta > 3 and not inst:HasAnyTag("ignores_foodregen", "ignores_healthregen") then
        inst.components.debuffable:AddDebuff("healthregenbuff_vetcurse_" .. data.food.prefab, "healthregenbuff_vetcurse", { duration = (health_delta * .1) })
    else
        inst.components.health:DoDelta(health_delta, nil, data.food.prefab)
    end

    if TUNING.DSTU.WARLY_CHANGES ~= 0 then
        if string.find(data.food.prefab, "spice_salt") then
            inst.components.health:DeltaPenalty(-.125)
        end
    end

    if sanity_delta > 3 and not inst:HasAnyTag("ignores_foodregen", "ignores_sanityregen") then
        inst.components.debuffable:AddDebuff("sanityregenbuff_vetcurse_" .. data.food.prefab, "sanityregenbuff_vetcurse", { duration = (sanity_delta * .1) })
    else
        inst.components.sanity:DoDelta(sanity_delta, nil, data.food.prefab)
    end

    if inst.wolfgang_vetcurse then --unused but keeping this here if we ever re-use the concept.
        if hunger_delta > 1 then
            inst.components.debuffable:AddDebuff("hungerregenbuff_vetcurse_" .. data.food.prefab, "hungerregenbuff_vetcurse", { duration = (hunger_delta * .1) })
        end
    end
end

UMVetCurse.ToggleFoodEffects = function(inst, toggle)
    local eater = inst.components.eater
    if not eater then return end
    if toggle then
        if not inst.modded_healthabsorption then
            inst.modded_healthabsorption = eater.healthabsorption
        end

        if not inst.modded_hungerabsorption then
            inst.modded_hungerabsorption = eater.hungerabsorption
        end

        if not inst.modded_sanityabsorption then
            inst.modded_sanityabsorption = eater.sanityabsorption
        end

        eater:SetAbsorptionModifiers(0, inst.wolfgang_vetcurse and 0 or inst.modded_hungerabsorption or 1, 0)

        inst:ListenForEvent("oneat", oneat)
    else
        eater:SetAbsorptionModifiers(inst.modded_healthabsorption, inst.modded_hungerabsorption, inst.modded_sanityabsorption)

        inst:RemoveEventCallback("oneat", oneat)
    end
end

UMVetCurse.AttachCurse = function(inst)
    inst.vetcurse = true
    if not inst.UMToggleUniqueVetCurse then
        UMVetCurse.ToggleDamageTakenModifier(inst, true)
        UMVetCurse.ToggleHungerTakenModifier(inst, true)
    end
    UMVetCurse.ToggleFoodEffects(inst, true)
    inst:AddTag("vetcurse")
    inst:PushEvent("vetcurse_added")
end

UMVetCurse.DetachCurse = function(inst)
    inst.vetcurse = nil
    if not inst.UMToggleUniqueVetCurse then
        UMVetCurse.ToggleDamageTakenModifier(inst)
        UMVetCurse.ToggleHungerTakenModifier(inst)
    end
    UMVetCurse.ToggleFoodEffects(inst)
    inst:RemoveTag("vetcurse")
    inst:PushEvent("vetcurse_removed")
end

UMVetCurse.ToggleVetCurse = function(inst, toggle)
    if toggle and inst.vetcurse or not toggle and not inst.vetcurse then return end
    if toggle then
        UMVetCurse.AttachCurse(inst)
    else
        UMVetCurse.DetachCurse(inst)
    end
    if inst.components.inventory then inst.components.inventory:ForEachItem(function(item) if item.UMToggleItemVetcurse then item:UMToggleItemVetcurse(toggle) end end) end
    if inst.UMToggleUniqueVetCurse then inst:UMToggleUniqueVetCurse(toggle) end
end

UMVetCurse.ApplyCurse = function(old, new)
    if TUNING.DSTU.VETCURSE == "default" and old:HasTag("vetcurse") then
        if new.UMToggleVetCurse then new:UMToggleVetCurse(true) end
    end
end

return UMVetCurse
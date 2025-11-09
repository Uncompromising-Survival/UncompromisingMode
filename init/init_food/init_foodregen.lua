local env = env
GLOBAL.setfenv(1, GLOBAL)

local function oneat(inst, data)
    if inst:HasTag("vetcurse") then return end
    if not inst.modded_healthabsorption then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if not inst.modded_hungerabsorption then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if not inst.modded_sanityabsorption then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.modded_hungerabsorption or 1, 0)

    local stack_mult = inst.components.eater.eatwholestack and data.food.components.stackable and data.food.components.stackable:StackSize() or 1
    local base_mult = inst.components.foodmemory and inst.components.foodmemory:GetFoodMultiplier(data.food.prefab) or 1
    local warlybuff = inst:HasTag("warlybuffed") and 1.2 or 1

    local health_delta = inst.components.health and (data.food.components.edible:GetHealth(inst) >= 0 or inst.components.eater:DoFoodEffects(data.food))
        and data.food.components.edible:GetHealth(inst) * base_mult * inst.modded_healthabsorption * warlybuff or 0
    local sanity_delta = inst.components.sanity and (data.food.components.edible:GetSanity(inst) >= 0 or inst.components.eater:DoFoodEffects(data.food))
        and data.food.components.edible:GetSanity(inst) * base_mult * inst.modded_sanityabsorption * warlybuff or 0
    local hunger_delta = 0

    if inst.components.eater.custom_stats_mod_fn then
        health_delta, hunger_delta, sanity_delta = inst.components.eater.custom_stats_mod_fn(inst, health_delta, hunger_delta, sanity_delta, data.food, data.feeder)
    end

    --[[local foodaffinitysanitybuff = inst:HasTag("playermerm") and (data.food.prefab == "kelp" or data.food.prefab == "kelp_cooked") and 0 or inst.components.foodaffinity:HasPrefabAffinity(data.food) and 15 or 0
    sanity_delta = sanity_delta + foodaffinitysanitybuff]]

    if inst:HasTag("wathom") and inst.components.foodaffinity:HasPrefabAffinity(data.food) then
        health_delta = health_delta + 20
    end

	if TUNING.DSTU.WARLY_CHANGES ~= 0 then
		if health_delta > 3 and not inst:HasAnyTag("ignores_foodregen", "ignores_healthregen") then
			inst.components.debuffable:AddDebuff("healthregenbuff_vetcurse_"..data.food.prefab, "healthregenbuff_vetcurse", {duration = (health_delta * 0.1), max_hp = string.find(data.food.prefab, "spice_salt") ~= nil})
		else
			inst.components.health:DoDelta(health_delta, nil, data.food.prefab)
		end
	else
		if health_delta > 3 and not inst:HasAnyTag("ignores_foodregen", "ignores_healthregen") then
			inst.components.debuffable:AddDebuff("healthregenbuff_vetcurse_"..data.food.prefab, "healthregenbuff_vetcurse", {duration = (health_delta * 0.1)})
		else
			inst.components.health:DoDelta(health_delta, nil, data.food.prefab)
		end
	end

    if sanity_delta > 3 and not inst:HasAnyTag("ignores_foodregen", "ignores_sanityregen") then
        inst.components.debuffable:AddDebuff("sanityregenbuff_vetcurse_"..data.food.prefab, "sanityregenbuff_vetcurse", {duration = (sanity_delta * 0.1)})
    else
        inst.components.sanity:DoDelta(sanity_delta, nil, data.food.prefab)
    end
end

env.AddPlayerPostInit(function(inst)
    inst:AddTag("UM_foodregen")

    if not TheWorld.ismastersim then
        return
    end

    if not inst.modded_healthabsorption then
        inst.modded_healthabsorption = inst.components.eater.healthabsorption
    end

    if not inst.modded_hungerabsorption then
        inst.modded_hungerabsorption = inst.components.eater.hungerabsorption
    end

    if not inst.modded_sanityabsorption then
        inst.modded_sanityabsorption = inst.components.eater.sanityabsorption
    end

    inst.components.eater:SetAbsorptionModifiers(0, inst.modded_hungerabsorption or 1, 0)

    inst:ListenForEvent("oneat", oneat)
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------	

local function oneat(inst, data)
    local food = data.food
    if food and food.components.edible then
        local hungerbonus = food.components.edible:GetHunger() * 0.2
        local sanitybonus = food.components.edible:GetSanity() * 0.2
        local healthbonus = food.components.edible:GetHealth() * 0.2

        if inst.components.hunger and hungerbonus > 0 then
            inst.components.hunger:DoDelta(hungerbonus)
        end

        if not inst:HasTag("vetcurse") and not inst:HasTag("UM_foodregen") and inst.components.sanity and sanitybonus > 0 then
            inst.components.sanity:DoDelta(sanitybonus)
        end

        if not inst:HasTag("vetcurse") and not inst:HasTag("UM_foodregen") and inst.components.health and healthbonus > 0 then
            inst.components.health:DoDelta(healthbonus, true, food.prefab)
        end
    end
end

local function OnMurdered(inst, data)
    if data.incinerated then return end
    local victim = data.victim
    if victim and victim:IsValid() and victim.um_wasmurdered and not inst.components.health:IsDead() then
        local x, y, z = inst.Transform:GetWorldPosition()
        if victim.components.lootdropper then
            victim.causeofdeath = inst
            local pos = Vector3(x, y, z)
            for i = 1, data.stackmult do
                local loots = victim.components.lootdropper:GenerateLoot()
                local lootprefab = loots[#loots > 1 and math.random(#loots) or 1]
                if lootprefab then
                    local loot = SpawnPrefab(lootprefab)
                    if loot then
                        inst.components.inventory:GiveItem(loot, nil, pos)
                    end
                end
            end
        end
    end
end

env.AddPrefabPostInit("warly", function(inst)
    if not TheWorld.ismastersim then return end
    --[[
if TUNING.DSTU.WARLY_BUTCHER then
	--local function onbutchered(target, data)
		--local target = data.target
		--if target ~= nil and not target:HasTag("butchermark") then
			--target:AddTag("butchermark")
		--end	
		--if target ~= nil and target.butcher_cancel_task ~= nil then
			--target.butcher_cancel_task:Cancel()
			--target.butcher_cancel_task = nil
		--end
		--target.butcher_cancel_task = target:DoTaskInTime(3, function() target:RemoveTag("butchermark") end)
	--end

	local function inventorystuff(item, data)
		local item = data.item
		if item ~= nil and ((item.components.health and item.components.inventoryitem.canbepickedupalive == true) or item.components.weighable ~= nil) and not item:HasTag("butchermark") then
			item:AddTag("butchermark")
		end
		if item ~= nil and item.butcher_cancel_task ~= nil then
			item.butcher_cancel_task:Cancel()
			item.butcher_cancel_task = nil
		end
	end

	local function ondropitem(item, data)
		local item = data.item
		if item ~= nil and item:HasTag("butchermark") then
			item:RemoveTag("butchermark")
		end
	end
	
	if inst.components.combat ~= nil then
		--inst:ListenForEvent("onattackother", onbutchered)
		inst:ListenForEvent("itemget", inventorystuff)
		inst:ListenForEvent("inventoryfull", inventorystuff)
		inst:ListenForEvent("gotnewitem", inventorystuff)
		inst:ListenForEvent("dropitem", ondropitem)
		inst:ListenForEvent("itemlose", ondropitem)
	end
end]]

    if TUNING.DSTU.WARLY_CHANGES ~= 0 then
        inst:AddTag("warlybuffed")

        if inst.components.eater then
            inst:ListenForEvent("oneat", oneat)
            --inst.components.eater:SetOnEatFn(oneat)
            --inst.components.eater:SetAbsorptionModifiers(1.2, 1.2, 1.2)
        end

        inst:ListenForEvent("murdered", OnMurdered)

        local foodmemory = inst.components.foodmemory
        if foodmemory then
            foodmemory:SetDuration(TUNING.DSTU.WARLY_SAME_OLD_COOLDOWN)
            foodmemory:SetMultipliers(TUNING.DSTU.WARLY_SAME_OLD_MULTIPLIERS)
        end
    end
end)

--[[
env.AddPrefabPostInit("portablecookpot_item", function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.deployable.restrictedtag = nil
end)

env.AddPrefabPostInit("portablecookpot", function(inst)
    --hacky but it wokrs
    inst:RemoveTag("mastercookware")
end)]]


env.AddPrefabPostInit("spicepack", function(inst)
    if TUNING.DSTU.WARLY_CHANGES == 1 then
        inst:RemoveTag("backpack")
        inst:AddTag("portablestorage")

        if not TheWorld.ismastersim then return end

        inst:RemoveComponent("equippable")

        inst.components.inventoryitem.cangoincontainer = true
        inst.components.inventoryitem.canonlygoinpocket = true

        --inst.components.container.restrictedtag = "masterchef"
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true
        inst.components.container.droponopen = true

        if inst.components.burnable then inst:RemoveComponent("burnable") end
        if inst.components.propagator then inst:RemoveComponent("propagator") end
    end
end)
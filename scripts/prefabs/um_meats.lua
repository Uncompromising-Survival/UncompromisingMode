local assets =
{
    Asset("ANIM", "anim/um_leafwing.zip"),
}

local function AddMonsterMeatChange(inst, prefab)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
            local new = SpawnPrefab(prefab)
            if new ~= nil then
                new.Transform:SetPosition(x, y, z)
                if new.components.stackable ~= nil and inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
                    new.components.stackable:SetStackSize(inst.components.stackable:StackSize())
                end
                if new.components.inventoryitem ~= nil and inst.components.inventoryitem ~= nil then
                    new.components.inventoryitem:InheritMoisture(inst.components.inventoryitem:GetMoisture(), inst.components.inventoryitem:IsWet())
                end
                if new.components.perishable ~= nil and inst.components.perishable ~= nil then
                    new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
                end
                new:PushEvent("spawnedfromhaunt", { haunter = haunter, oldPrefab = inst })
                inst:PushEvent("despawnedfromhaunt", { haunter = haunter, newPrefab = new })
                inst.persists = false
                inst.entity:Hide()
                inst:DoTaskInTime(0, inst.Remove)
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            return true
        end
        return false
    end, false, true, false)
end

local function OnSpawnedFromHaunt(inst, data)
    Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
end

local function common(bank, build, anim, tags, dryable, cookable)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation(anim)
    inst.scrapbook_anim = anim

    --inst.pickupsound = "squidgy"

    inst:AddTag("meat")
    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    if dryable ~= nil then
		if dryable.product then
			--dryable (from dryable component) added to pristine state for optimization
			inst:AddTag("dryable")
		end
        inst:AddTag("lureplant_bait")
    end

    if cookable ~= nil then
        --cookable (from cookable component) added to pristine state for optimization
        inst:AddTag("cookable")
    end

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("edible")
    inst.components.edible.ismeat = true
    inst.components.edible.foodtype = FOODTYPE.MEAT

    inst:AddComponent("bait")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("stackable")

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = TUNING.GOLD_VALUES.MEAT

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    if dryable ~= nil and dryable.product ~= nil then
        inst:AddComponent("dryable")
        inst.components.dryable:SetProduct(dryable.product)
        inst.components.dryable:SetDryTime(dryable.time)
		inst.components.dryable:SetBuildFile(dryable.build)
        inst.components.dryable:SetDriedBuildFile(dryable.dried_build)
    end

    if cookable ~= nil then
        inst:AddComponent("cookable")
        inst.components.cookable.product = cookable.product
    end

    if TheNet:GetServerGameMode() == "quagmire" then
        event_server_data("quagmire", "prefabs/meats").master_postinit(inst, cookable)
    end

    MakeHauntableLaunchAndPerish(inst)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

    return inst
end

local function um_leafwing()
    local inst = common("um_leafwing", "um_leafwing", "idle", { "lureplant_bait", "rawmeat"} , nil, nil)

    inst.components.floater:SetSize("med")
    inst.components.floater:SetVerticalOffset(0.02)
    inst.components.floater:SetScale(0.8)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_TINY
    inst.components.edible.sanityvalue = -TUNING.SANITY_TINY

    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
	
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    return inst
end


return Prefab("um_leafwing", um_leafwing, assets)

-- return Prefab("meat", raw, assets, prefabs),
        -- Prefab("cookedmeat", cooked, assets),
        -- Prefab("meat_dried", driedmeat, assets),
        -- Prefab("monstermeat", monster, assets, monsterprefabs),
        -- Prefab("cookedmonstermeat", cookedmonster, assets),
        -- Prefab("monstermeat_dried", driedmonster, assets),
        -- Prefab("smallmeat", smallmeat, assets, smallprefabs),
        -- Prefab("cookedsmallmeat", cookedsmallmeat, assets),
        -- Prefab("smallmeat_dried", driedsmallmeat, assets),
        -- Prefab("drumstick", drumstick, assets, drumstickprefabs),
        -- Prefab("drumstick_cooked", drumstick_cooked, assets),
        -- Prefab("batwing", batwing, assets, batwingprefabs),
        -- Prefab("batwing_cooked", batwing_cooked, assets),
        -- Prefab("plantmeat", plantmeat, assets, plantmeatprefabs),
        -- Prefab("plantmeat_cooked", plantmeat_cooked, assets),
        -- Prefab("fishmeat_small", fishmeat_small, assets, fishmeat_smallprefabs),
        -- Prefab("fishmeat_small_cooked", fishmeat_small_cooked, assets),
        -- Prefab("fishmeat", fishmeat, assets, fishmeat_prefabs),
        -- Prefab("fishmeat_cooked", fishmeat_cooked, assets),
        -- Prefab("humanmeat", humanmeat, assets, humanprefabs),
        -- Prefab("humanmeat_cooked", humanmeat_cooked, assets),
        -- Prefab("humanmeat_dried", humanmeat_dried, assets),
        -- Prefab("quagmire_smallmeat", quagmire_smallmeat, quagmire_assets, quagmire_prefabs),
        -- Prefab("quagmire_cookedsmallmeat", quagmire_cookedsmallmeat, quagmire_assets),
        -- Prefab("barnacle", barnacle, assets),
        -- Prefab("barnacle_cooked", barnacle_cooked, assets),
        -- Prefab("batnose", batnose, batnose_assets, batwingprefabs),
        -- Prefab("batnose_cooked", batnose_cooked, batnose_assets)

local assets =
{
    --Asset("ANIM", "anim/ui_icepack_2x3.zip"),
    --Asset("ANIM", "anim/ui_beard_3x1.zip"),
    --[[Asset("ANIM", "anim/beargerfur_sack.zip"),
    Asset("INV_IMAGE", "beargerfur_sack_open"),]]
    Asset("ANIM", "anim/twigs.zip"),
}

local insulationmod = 0

local function OnTimerDone(inst, data)
    if data.name == "um_totem_canary_speed" then
        if inst.components.locomotor then
		    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, inst.prefab)
            inst.SoundEmitter:PlaySound("dontstarve/birds/takeoff_canary")
	    end
    elseif data.name == "um_totem_azure_insulation" then
        print(insulationmod.." result of timer done azure")
        inst.components.temperature.inherentinsulation = inst.components.temperature.inherentinsulation - insulationmod
        inst.components.temperature.inherentsummerinsulation = inst.components.temperature.inherentinsulation - insulationmod
    elseif data.name == "um_totem_malbatross_nowet" then
        if inst.components.moistureimmunity then
		    inst.components.moistureimmunity:RemoveSource(inst)
            inst.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/attack_call")
	    end
    elseif data.name == "um_totem_goose_speed" then
        if inst.components.locomotor then
		    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, inst.prefab)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
	    end
    end
    inst:RemoveEventCallback("timerdone", OnTimerDone)
end

local function FeatherEffects(inst, totem)
    local feather_robin = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin" end)
    local feather_crow = #totem.components.container:FindItems(function(item) return item.prefab == "feather_crow" end)
    local feather_robin_winter = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin_winter" end)
    local feather_canary = #totem.components.container:FindItems(function(item) return item.prefab == "feather_canary" end)
    local goose_feather = #totem.components.container:FindItems(function(item) return item.prefab == "goose_feather" end)
    local malbatross_feather = #totem.components.container:FindItems(function(item) return item.prefab == "malbatross_feather" end)
    --local cherryforest_feather1 = #totem.components.container:FindItems(function(item) return item.prefab == "???" end)
    --local cherryforest_feather2 = #totem.components.container:FindItems(function(item) return item.prefab == "???" end)
    --local feather_robin = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin" end)
    local feathertotal = #totem.components.container:FindItems(function(item) return item:HasTag("wingsuit_feather") end)
    local didsomething = false

    if feather_robin > 0 then
        inst.components.health:DoDelta(inst.components.health.maxhealth * 0.1 * feather_robin)
        didsomething = true
    end

    if feather_crow > 0 then
        inst.components.sanity:DoDelta(inst.components.sanity.max * 0.15 * feather_crow)
        didsomething = true
    end

    if feather_canary > 0 then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, inst.prefab, 1.15)
        inst.components.timer:StartTimer("um_totem_canary_speed", 90 * feather_canary)
        inst.SoundEmitter:PlaySound("dontstarve/birds/takeoff_canary")
        didsomething = true
    end

    if feather_robin_winter > 0 then
        insulationmod = 80 * feather_robin_winter
        inst.components.temperature.inherentinsulation = inst.components.temperature.inherentinsulation + insulationmod
        inst.components.temperature.inherentsummerinsulation = inst.components.temperature.inherentsummerinsulation + insulationmod
        inst.components.timer:StartTimer("um_totem_azure_insulation", 15)
        didsomething = true
    end

    if goose_feather > 0 then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, inst.prefab, 1.25)
        inst.components.timer:StartTimer("um_totem_goose_speed", 45 * goose_feather)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
        didsomething = true
    end

    if malbatross_feather > 0 then
	    if not inst.components.moistureimmunity then
		    inst:AddComponent("moistureimmunity")
	    end
	    inst.components.moistureimmunity:AddSource(inst)
        inst.components.timer:StartTimer("um_totem_malbatross_nowet", TUNING.TOTAL_DAY_TIME * malbatross_feather)
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
        didsomething = true
    end

    if feathertotal > 0 then
        inst.components.health:DeltaPenalty(-0.125 * feathertotal)
        didsomething = true
    end

    if didsomething then
        inst:ListenForEvent("timerdone", OnTimerDone)
        totem.components.container:RemoveAllItems()
    end

    return didsomething
end

local function IsTotem(item)
    return item.prefab == "um_feather_totem"
end

local function HasTotem(inst)
    return inst.components.inventory and inst.components.inventory:FindItem(IsTotem)
end

local function OnRespawn(inst, totem)
    totem = HasTotem(inst)
    if totem then
        inst:DoTaskInTime(5, function()
            if FeatherEffects(inst, totem) then
                totem.components.finiteuses:Use(1)
            end
        end)
    end
end

local function topocket(inst, owner)
    owner = owner.components.inventoryitem and owner.components.inventoryitem:GetGrandOwner() or owner
    --owner.components.health:DoDelta(10) test if it's working
    if owner ~= inst._owner then
        --toground(inst)
        --owner:AddTag("nightmaretracker")
        --owner:ListenForEvent("onremove", toground, inst)
        owner:ListenForEvent("ms_respawnedfromghost", OnRespawn)
        inst._owner = owner
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("twigs")
    inst.AnimState:SetBuild("screecher_trinket") --Hello Axe or Max or someone else! init/init_recipes/recipes.lua is forcing the recipe icon for this. bye!! -C
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("portablestorage")

    MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", nil, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    --inventoryitem.keepondrown = true
    inventoryitem.keepondeath = true
    inventoryitem.cangoincontainer = true
    inventoryitem.canonlygoinpocket = true
    -- temporary
    inventoryitem.imagename = "screecher_trinket"
    inventoryitem.atlasname = "images/inventoryimages/screecher_trinket.xml"
    --inst.replica.inventoryitem:OverrideImage("screecher_trinket")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("um_feather_totem")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(3)
    inst.components.finiteuses:SetUses(3)
    inst.components.finiteuses:SetOnFinished(inst.Remove)--onfinished

    inst:AddComponent("lootdropper")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
    --inst.components.fuel:SetOnTakenFn(FuelTaken)

    ---------------------
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    inst._owner = nil
    inst:ListenForEvent("onputininventory", topocket)
    --inst:ListenForEvent("ondropped", toground)

    return inst
end

return Prefab("um_feather_totem", fn, assets)
local assets =
{
    --Asset("ANIM", "anim/ui_icepack_2x3.zip"),
    --Asset("ANIM", "anim/ui_beard_3x1.zip"),
    --[[Asset("ANIM", "anim/beargerfur_sack.zip"),
    Asset("INV_IMAGE", "beargerfur_sack_open"),]]
    Asset("ANIM", "anim/twigs.zip"),
}

local insulationmod = 0
local insulate_summer = false
local insulate_winter = false

local function OnTimerDone(owner, data)
    if data.name == "um_totem_feather_speed" then
        if owner.components.locomotor then
		    owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, owner.prefab)
            owner.SoundEmitter:PlaySound("dontstarve/birds/takeoff_canary")
	    end
    elseif data.name == "um_totem_azure_insulation" then
        --print(insulationmod.." result of timer done azure")
        if insulate_winter then
        owner.components.temperature.inherentinsulation = owner.components.temperature.inherentinsulation - insulationmod
        end

        if insulate_summer then
            owner.components.temperature.inherentsummerinsulation = owner.components.temperature.inherentsummerinsulation - insulationmod
        end
    elseif data.name == "um_totem_malbatross_nowet" then
        if owner.components.moistureimmunity then
		    owner.components.moistureimmunity:RemoveSource(owner)
            owner.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/attack_call")
	    end
    end
    owner:RemoveEventCallback("timerdone", OnTimerDone)
end

local function FeatherEffects(owner, totem)
    local feathertotal = #totem.components.container:FindItems(function(item) return item:HasTag("wingsuit_feather") end)
    if feathertotal == 0 then return 0 end

    local feather_robin = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin" end)
    local feather_crow = #totem.components.container:FindItems(function(item) return item.prefab == "feather_crow" end)
    local feather_robin_winter = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin_winter" end)
    local feather_canary = #totem.components.container:FindItems(function(item) return item.prefab == "feather_canary" end)
    local goose_feather = #totem.components.container:FindItems(function(item) return item.prefab == "goose_feather" end)
    local malbatross_feather = #totem.components.container:FindItems(function(item) return item.prefab == "malbatross_feather" end)
    --local cherryforest_feather1 = #totem.components.container:FindItems(function(item) return item.prefab == "???" end)
    --local cherryforest_feather2 = #totem.components.container:FindItems(function(item) return item.prefab == "???" end)
    --local feather_robin = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin" end)

    if feather_robin > 0 then
        owner.components.health:DoDelta(owner.components.health.maxhealth * 0.1 * feather_robin)
    end

    if feather_crow > 0 then
        owner.components.sanity:DoDelta(owner.components.sanity.max * 0.15 * feather_crow)
    end

    if feather_canary > 0 or goose_feather > 0 then
        local speedmult = ((feather_canary * 1.15) + (goose_feather * 1.25)) / (feather_canary + goose_feather)
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, owner.prefab, speedmult)
        if not owner.components.timer:TimerExists("um_totem_feather_speed") then
            owner.components.timer:StartTimer("um_totem_feather_speed", 90 * feather_canary + 45 * goose_feather)
        else
            owner.components.timer:SetTimeLeft("um_totem_feather_speed", 90 * feather_canary + 45 * goose_feather)
        end
        owner.SoundEmitter:PlaySound("dontstarve/birds/takeoff_canary")
    end

    if feather_robin_winter > 0 then
        insulationmod = 80 * feather_robin_winter

        insulate_summer = TheWorld.state.season ~= "winter" -- Regular insulation will not allow the player to cool down in summer
        insulate_winter = TheWorld.state.season ~= "summer" -- Summer insultation will not allow the player to heat up in winter

        if insulate_winter then
            owner.components.temperature.inherentinsulation = owner.components.temperature.inherentinsulation + insulationmod
        end

        if insulate_summer then
        owner.components.temperature.inherentsummerinsulation = owner.components.temperature.inherentsummerinsulation + insulationmod
        end

        if not owner.components.timer:TimerExists("um_totem_azure_insulation") then
            owner.components.timer:StartTimer("um_totem_azure_insulation", 15)
        else
            owner.components.timer:SetTimeLeft("um_totem_azure_insulation", 15)
        end
    end

    --[[if goose_feather > 0 then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, owner.prefab, 1.25)
        owner.components.timer:StartTimer("um_totem_goose_speed", 45 * goose_feather)
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
    end]]

    if malbatross_feather > 0 then
	    if not owner.components.moistureimmunity then
		    owner:AddComponent("moistureimmunity")
	    end
	    owner.components.moistureimmunity:AddSource(owner)
        if not owner.components.timer:TimerExists("um_totem_malbatross_nowet") then
            owner.components.timer:StartTimer("um_totem_malbatross_nowet", TUNING.TOTAL_DAY_TIME * malbatross_feather)
        else
            owner.components.timer:SetTimeLeft("um_totem_malbatross_nowet", TUNING.TOTAL_DAY_TIME * malbatross_feather)
        end
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
    end

    owner.components.health:DeltaPenalty(-0.125 * feathertotal)
    owner:ListenForEvent("timerdone", OnTimerDone)
    totem.components.container:RemoveAllItems() -- Remove this and make Malba and MGoose feathers have a chance to not be consumed.

    return feathertotal
end

local function IsTotem(item)
    return item.prefab == "um_feather_totem"
end

local function HasTotem(owner)
    return owner.components.inventory and owner.components.inventory:FindItem(IsTotem)
end

local function OnRespawn(owner, totem)
    totem = HasTotem(owner)
    if totem then
        owner:DoTaskInTime(5, function()
            local effectCount = FeatherEffects(owner, totem)
            if effectCount > 0 then
                totem.components.finiteuses:Use(effectCount)
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
    inst.AnimState:SetBuild("screecher_trinket") --init/init_recipes/recipes.lua is forcing the recipe icon for this. bye!! -C
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
    inst.components.finiteuses:SetMaxUses(9)
    inst.components.finiteuses:SetUses(9)
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
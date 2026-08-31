local assets =
{
    Asset("ANIM", "anim/ui_um_feather_totem.zip"),
    Asset("ANIM", "anim/um_feather_totem.zip"),
    Asset("INV_IMAGE", "um_feather_totem"),
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
            --owner.components.temperature.inherentinsulation = owner.components.temperature.inherentinsulation - insulationmod
            owner.components.temperature:RemoveInsulationModifier(SEASONS.WINTER, owner, "um_totem_azure_insulation")
        end

        if insulate_summer then
            --owner.components.temperature.inherentsummerinsulation = owner.components.temperature.inherentsummerinsulation - insulationmod
            owner.components.temperature:RemoveInsulationModifier(SEASONS.SUMMER, owner, "um_totem_azure_insulation")
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

    local feather_robin         = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin"        end)
    local feather_crow          = #totem.components.container:FindItems(function(item) return item.prefab == "feather_crow"         end)
    local feather_robin_winter  = #totem.components.container:FindItems(function(item) return item.prefab == "feather_robin_winter" end)
    local feather_canary        = #totem.components.container:FindItems(function(item) return item.prefab == "feather_canary"       end)
    local goose_feather         = #totem.components.container:FindItems(function(item) return item.prefab == "goose_feather"        end)
    local malbatross_feather    = #totem.components.container:FindItems(function(item) return item.prefab == "malbatross_feather"   end)
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
        UMCommonFns.RestartTimer(owner, {name = "um_totem_feather_speed", time = 90 * feather_canary + 45 * goose_feather})
        owner.SoundEmitter:PlaySound("dontstarve/birds/takeoff_canary")
    end

    if feather_robin_winter > 0 then
        insulationmod = 80 * feather_robin_winter

        insulate_summer = TheWorld.state.season ~= "winter" -- Regular insulation will not allow the player to cool down in summer
        insulate_winter = TheWorld.state.season ~= "summer" -- Summer insultation will not allow the player to heat up in winter

        if insulate_winter then
            --owner.components.temperature.inherentinsulation = owner.components.temperature.inherentinsulation + insulationmod
            owner.components.temperature:SetInsulationModifier(SEASONS.WINTER, owner, insulationmod, "um_totem_azure_insulation")
        end

        if insulate_summer then
            --owner.components.temperature.inherentsummerinsulation = owner.components.temperature.inherentsummerinsulation + insulationmod
            owner.components.temperature:SetInsulationModifier(SEASONS.SUMMER, owner, insulationmod, "um_totem_azure_insulation")
        end

        UMCommonFns.RestartTimer(owner, {name = "um_totem_azure_insulation", time = 90 * feather_robin_winter})
    end

    --[[if goose_feather > 0 then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, owner.prefab, 1.25)
        UMCommonFns.RestartTimer(owner, {name = "um_totem_goose_speed", time = 45 * goose_feather})
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/honk")
    end]]

    if malbatross_feather > 0 then
	    if not owner.components.moistureimmunity then
		    owner:AddComponent("moistureimmunity")
	    end
	    owner.components.moistureimmunity:AddSource(owner)
        UMCommonFns.RestartTimer(owner, {name = "um_totem_malbatross_nowet", time = TUNING.TOTAL_DAY_TIME * malbatross_feather})
        owner.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/attack_call")
    end

    local boss_feathers = malbatross_feather + goose_feather
    local basic_feathers = feathertotal - boss_feathers
    owner.components.health:DeltaPenalty((-0.25 / 3) * basic_feathers + (-0.50 / 3) * boss_feathers)
    owner:ListenForEvent("timerdone", OnTimerDone)
    totem.components.container:RemoveAllItems()

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

local function OnAvoidDeath(owner, totem)
    totem = HasTotem(owner)
    if totem then
        local effectCount = FeatherEffects(owner, totem)
        if effectCount > 0 then
            totem.components.finiteuses:Use(effectCount)
        end
    end
end

local function OnOpen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("idle_open", true)
    inst.SoundEmitter:PlaySound("dontstarve/birds/wingflap_cage", nil, 2)
end

local function OnClose(inst)
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/birds/wingflap_cage", nil, 2)
end

local function OnStore(inst)
    inst.AnimState:PlayAnimation("store")
    inst.AnimState:PushAnimation(inst.components.container:IsOpen() and "idle_open" or "idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/birds/chirp_canary", nil, 2)
end

local function topocket(inst, owner)
    owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or owner
    local HasOtherTotem = owner.components.inventory:FindItem(function(item) return item:HasTag("um_feather_totem") and item ~= inst end)
    if owner and owner.components.inventory and HasOtherTotem then
        inst:DoTaskInTime(0, function()
            local stillholding = owner.components.inventory and owner.components.inventory:IsHolding(inst)
            if stillholding then
                owner.components.inventory:DropItem(inst, true, true)
                inst.SoundEmitter:PlaySound("UCSounds/screecher/screecher", nil, 0.1)
            end
        end)
    elseif owner ~= inst._owner then
        --toground(inst)
        --owner:AddTag("nightmaretracker")
        --owner:ListenForEvent("onremove", toground, inst)

        owner:ListenForEvent("ms_respawnedfromghost", OnRespawn)
        owner:ListenForEvent("PocketResurrection", OnAvoidDeath)
        inst._owner = owner
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("um_feather_totem.tex")

    inst.AnimState:SetBank("um_feather_totem")
    inst.AnimState:SetBuild("um_feather_totem")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("um_feather_totem")
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

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("um_feather_totem")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    inst:ListenForEvent("itemget", OnStore)
    inst:ListenForEvent("itemlose", OnStore)

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
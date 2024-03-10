require "prefabutil"

local easing = require("easing")

local assets =
{
    Asset("ANIM", "anim/firefighter.zip"),
    Asset("ANIM", "anim/firefighter_placement.zip"),
    Asset("ANIM", "anim/firefighter_meter.zip"),
}


local prefabs =
{
    "snowball",
    "collapse_small",
}

--Called from stategraph

local function TurnOff(inst, instant)
    inst.Light:Enable(false)
    inst.SoundEmitter:KillSound("engine_running")
    inst.SoundEmitter:KillSound("engine_running2")
    inst.SoundEmitter:KillSound("engine_running3")
    inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/place", nil, 0.125)

    inst.on = false
    if inst.speed_task ~= nil then
        print("cancelling task!")
        inst.speed_task:Cancel()
        inst.speed_task = nil
    end

    if inst.heattask ~= nil then
        inst.heattask:Cancel()
        inst.heattask = nil
    end

    inst.heattask = inst:DoPeriodicTask(1, function(inst)
        inst.heat = math.max(inst.heat - 0.5+ (TheWorld.state.iswinter and -0.125 or TheWorld.state.issummer and 0.125 or 0), 1)
        inst.components.heater.heat = (inst.heat <= 1 and 0 or inst.heat * 100)
    end)


    inst.components.fueled:StopConsuming()
end

local function PlayChuffSound(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_chuff", nil, inst.heat / 10)

    if inst.on then
        inst:DoTaskInTime(2 / inst.heat, PlayChuffSound)
    end
end


local function TurnOn(inst, instant)
    inst.Light:Enable(true)

    inst.on = true

    if inst.heattask ~= nil then
        inst.heattask:Cancel()
        inst.heattask = nil
    end

    inst.heattask = inst:DoPeriodicTask(1, function(inst)
        inst.heat = math.min(inst.heat + 0.5 + (TheWorld.state.iswinter and -0.125 or TheWorld.state.issummer and 0.125 or 0), 10)
        inst.components.heater.heat = inst.heat * 100

        if inst.heat >= 10 then
            print('turning off')
            print("fuel left:", inst.components.fueled:GetPercent())
            if not inst.did_overheat then
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level3", nil, 0.5)
            end
            inst.components.machine.enabled = false
            inst.components.machine:TurnOff()
            inst.cd_task = inst:DoTaskInTime(20, function(inst)
                inst.components.machine.enabled = true
            end)
        end
    end)

    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_idle", "engine_running")
    inst.SoundEmitter:PlaySound("rifts3/wagpunk_armor/wagpunk_armor_body_lp", "engine_running2")
    inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/ratchet_LP", "engine_running3")

    inst.speed_task = inst:DoPeriodicTask(FRAMES * 2, function()
        local boat = TheWorld.Map:GetPlatformAtPoint(inst.Transform:GetWorldPosition())
        if boat ~= nil then
            boat.components.boatphysics:ApplyForce(boat.components.boatphysics.rudder_direction_x, boat.components.boatphysics.rudder_direction_z, 1)
        end


        inst.SoundEmitter:SetVolume("engine_running", inst.heat * 2)
        inst.SoundEmitter:SetVolume("engine_running2", inst.heat * 2)
        inst.SoundEmitter:SetVolume("engine_running3", 1 / (inst.heat * 2))

        inst.SoundEmitter:SetParameter("engine_running2", "param00", inst.heat / 10)
    end)
    inst.components.fueled:StartConsuming()

    inst:DoTaskInTime(2 / inst.heat, PlayChuffSound)
end
local function OnFuelEmpty(inst)
    inst.components.machine:TurnOff()

    inst.on = false
end

local function OnAddFuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
end

local function CanInteract(inst)
    return not inst.components.fueled:IsEmpty() and TheWorld.Map:GetPlatformAtPoint(inst.Transform:GetWorldPosition()) ~= nil
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("engine_running")
    inst.SoundEmitter:KillSound("engine_running2")
    inst.SoundEmitter:KillSound("engine_running3")

    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")

    if inst.heat >= 5 then
        inst:AddComponent("explosive")
        inst.components.explosive.explosiverange = inst.heat
        inst.components.explosive:OnBurnt()
    end
    if inst ~= nil then --inst may get removed in explosion. I think.
        inst:Remove()
    end
end
local function getstatus(inst, viewer)
    --if inst.on then
    return inst.heat >= 8 and "OVERHEATING" or inst.components.fueled ~= nil
        and inst.components.fueled:GetPercent() <= 0.25
        and "LOWFUEL"
        or "ON"
    --else
    --return "OFF"
    --end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil and inst.components.burnable.onburnt ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end
local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")
end

--------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()


    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("firefighter")
    inst.AnimState:SetBuild("firefighter")
    inst.AnimState:PlayAnimation("idle_off")
    inst.AnimState:OverrideSymbol("swap_meter", "firefighter_meter", "10")

    inst:AddTag("structure")

    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(.8)
    inst.Light:SetFalloff(1)
    inst.Light:Enable(false)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.heat = 1

    inst:DoPeriodicTask(FRAMES, function(inst)
        inst.AnimState:SetSymbolAddColour("swap_meter", Lerp(0, 0.5, inst.heat / 10), 0, 0, 0)
        inst.AnimState:SetSymbolLightOverride("swap_meter", Lerp(0, 1, inst.heat / 10))

        inst.AnimState:OverrideSymbol("swap_meter", "firefighter_meter", tostring(math.floor(inst.heat)))

        inst.Light:SetColour(Lerp(0, 2, inst.heat / 10), Lerp(1, 0, inst.heat / 10), Lerp(1, 0, inst.heat / 10))
    end)

    inst._fuellevel = 10

    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("machine")
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.caninteractfn = CanInteract
    inst.components.machine.cooldowntime = 1


    inst:AddComponent("heater")
    inst.components.heater.heat = 0
    inst.components.heater:SetThermics(true, false)

    inst:AddComponent("fueled")
    inst.components.fueled:SetDepletedFn(OnFuelEmpty)
    inst.components.fueled:SetTakeFuelFn(OnAddFuel)
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(10)
    inst.components.fueled:InitializeFuelLevel(60)
    inst.components.fueled.bonusmult = 5
    inst.components.fueled.secondaryfueltype = FUELTYPE.SLUDGE

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)

    inst.OnSave = onsave
    inst.OnLoad = onload
    --inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = OnEntitySleep
    inst.OnRemoveEntity = OnRemoveEntity


    MakeHauntableWork(inst)

    return inst
end


return Prefab("um_boat_engine", fn, assets, prefabs),
    MakePlacer("um_boat_engine_placer", "firefighter", "firefighter", "idle_off", false, nil, nil, 1)

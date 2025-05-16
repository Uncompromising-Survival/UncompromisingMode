local assets =
{
    Asset("ANIM", "anim/um_boatbottle.zip"),
    Asset("ATLAS", "images/inventoryimages/um_boatbottle.xml"),
    Asset("IMAGE", "images/inventoryimages/um_boatbottle.tex"),
}

local function launchitem(item, angle)
    local speed = math.random() * 4 + 2
    angle = (angle + math.random() * 60 - 30) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function CLIENT_CanDeployBoat(inst, pt, mouseover, deployer, rotation)
    return TheWorld.Map:CanDeployBoatAtPointInWater(pt, inst, mouseover,
        {
            boat_radius = TUNING.BOAT.RADIUS, --just default to normal boat radius...
            boat_extra_spacing = 0.2,
            min_distance_from_land = 0.2,
        }) and inst:HasTag("filled_boat_bottle")
end

local function ondeploy(inst, pt, deployer)
    local boat = inst.components.boatbottle:RetrieveBoat(pt)
    SpawnPrefab("fx_boat_pop").Transform:SetPosition(pt.x, 0, pt.z)
    SpawnPrefab("moon_geyser_explode").Transform:SetPosition(pt.x, 0, pt.z)

    local ents = inst.components.boatbottle:RetrieveBoatData(boat)

    boat.AnimState:SetHaunted(true)
    boat:DoTaskInTime(1, function() boat.AnimState:SetHaunted(false) end)

    if boat._container ~= nil then
        boat._container:Remove()
    end

    for k, v in pairs(ents) do
        local x, y, z = v.Transform:GetWorldPosition()
        v.Transform:SetPosition(x, 0, z) --set y explicity to 0, for some reason a couple of prefabs were having values different than that.
        v.AnimState:SetHaunted(true)
        v:DoTaskInTime(1, function() v.AnimState:SetHaunted(false) end)
        if v.prefab == "boat_ancient_container" then --not a good solution, but...
            boat._container = v
        end

        if v:HasTag("walkableperipheral") and v:HasTag("boatbumper") then
            SnapToBoatEdge(v, boat, v:GetPosition())
            boat.components.boatring:AddBumper(v)
        end
    end

    inst.components.boatbottle:ClearBoatData()
    inst:Remove()
    local item = SpawnPrefab("alterguardianhatshard")
    item.Transform:SetPosition(pt.x, pt.y, pt.z)
    launchitem(item, math.random() * 360)

    --scuffed, but inst (the boat bottle) gets removed before the sound actually finishes playing.
    if boat.SoundEmitter ~= nil then
        boat.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    end

    local fx = SpawnPrefab("winona_battery_high_shatterfx")
    fx.AnimState:PlayAnimation("blue_shatter")
    fx.Transform:SetPosition(pt.x, pt.y, pt.z)


    return boat
end

local function OnHit(inst, attacker, target)
    local pt = inst:GetPosition()
    ondeploy(inst, pt)
end

local function OnThrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:PlayAnimation("spin", true)
    if inst.fx ~= nil then
        inst.fx.AnimState:PlayAnimation("spin", true)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("boat_bottle")
    inst.AnimState:SetBuild("boat_bottle")
    inst.AnimState:PlayAnimation("idle2", true)

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("boatbuilder")
    inst:AddTag("usedeployspacingasoffset")

    inst._custom_candeploy_fn = CLIENT_CanDeployBoat

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()


    inst.fx = SpawnPrefab("um_boatbottle_fx")
    inst.fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.fx.entity:SetParent(inst.entity)
    inst.fx.AnimState:SetSortOrder(3)
    inst.fx.Follower:FollowSymbol(inst.GUID, "boat", 0, 50, 0) --TODO, check offsets.
    inst.fx.components.highlightchild:SetOwner(inst)
    inst.fx:Hide()


    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(20)
    inst.components.complexprojectile:SetGravity(-40)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, .25, 0))
    inst.components.complexprojectile:SetOnHit(OnHit)
    inst.components.complexprojectile:SetOnLaunch(OnThrown)

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LARGE)
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.keep_in_inventory_on_deploy = true

    inst:AddComponent("boatbottle")


    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = function(inst, viewer)
        return inst:HasTag("filled_boat_bottle") and "FULL" or "EMPTY"
    end

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunch(inst)
    return inst
end

local function fn_follow_fx(inst)
    local inst = CreateEntity()

    inst.entity:AddNetwork()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBuild("boat_bottle")
    inst.AnimState:SetBank("boat_bottle")
    inst.AnimState:PlayAnimation("idleboat2", true)
    inst.AnimState:HideSymbol("symbol0")
    inst.AnimState:HideSymbol("antennae")
    inst.AnimState:HideSymbol("stand")
    inst.AnimState:SetHaunted(true)

    inst:AddComponent("highlightchild")

    inst.persists = true -- hurhetdhre

    return inst
end


return Prefab("um_boatbottle", fn, assets),
    MakePlacer("um_boatbottle_placer", "boat_01", "boat_test", "idle_full", true, false, false, nil, nil, nil, ControllerPlacer_Boat_SpotFinder, 6),
    Prefab("um_boatbottle_fx", fn_follow_fx, assets)

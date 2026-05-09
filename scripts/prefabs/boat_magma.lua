-- ASSETS

local ice_assets =
{
    Asset("ANIM", "anim/boat_ice.zip"),
}

local ice_prefabs =
{
    "boat_ice_deploy_blocker",
    "boatlip_ice",
    "degrade_fx_ice",
}

--

local sounds_magma =
{
    place = "dontstarve_DLC001/common/iceboulder_hit",
    creak = "dontstarve_DLC001/common/iceboulder_hit",
    damage = "dontstarve_DLC001/common/iceboulder_hit",
    sink = "dontstarve_DLC001/common/iceboulder_hit",
    hit = "dontstarve_DLC001/common/iceboulder_hit",
    thunk = "dontstarve_DLC001/common/iceboulder_hit",
    movement = "dontstarve_DLC001/common/iceboulder_hit",
}

local BOAT_COLLISION_SEGMENT_COUNT = 20

local BOATBUMPER_MUST_TAGS = { "boatbumper" }

local function OnLoadPostPass(inst)
    local boatring = inst.components.boatring
    if not boatring then
        return
    end

    -- If cannons and bumpers are on a boat, we need to rotate them to account for the boat's rotation
    local x, y, z = inst.Transform:GetWorldPosition()

    -- Bumpers
    local bumpers = TheSim:FindEntities(x, y, z, boatring:GetRadius(), BOATBUMPER_MUST_TAGS)
    for _, bumper in ipairs(bumpers) do
        -- Add to boat bumper list for future reference
        table.insert(boatring.boatbumpers, bumper)

        local bumperpos = bumper:GetPosition()
        local angle = GetAngleFromBoat(inst, bumperpos.x, bumperpos.z) / DEGREES

        -- Need to further rotate the bumpers to account for the boat's rotation
        bumper.Transform:SetRotation(-angle + 90)
    end
end

local function OnSpawnNewBoatLeak(inst, data)
    if data ~= nil and data.pt ~= nil then
        data.pt.y = 0

        local leak = SpawnPrefab("boat_leak")
        leak.Transform:SetPosition(data.pt:Get())
        leak.components.boatleak.isdynamic = true
        leak.components.boatleak:SetBoat(inst)
        leak.components.boatleak:SetState(data.leak_size)

        table.insert(inst.components.hullhealth.leak_indicators_dynamic, leak)

        if inst.components.walkableplatform ~= nil then
            inst.components.walkableplatform:AddEntityToPlatform(leak)
            for player_on_platform in pairs(inst.components.walkableplatform:GetPlayersOnPlatform()) do
                if player_on_platform:IsValid() then
                    player_on_platform:PushEvent("on_standing_on_new_leak")
                end
            end
        end

        if data.playsoundfx then
            inst.SoundEmitter:PlaySoundWithParams(inst.sounds.damage, { intensity = 0.8 })
        end
    end
end

local function RemoveConstrainedPhysicsObj(physics_obj)
    if physics_obj:IsValid() then
        physics_obj.Physics:ConstrainTo(nil)
        physics_obj:Remove()
    end
end

local function constrain_object_to_boat(physics_obj, boat)
    if boat:IsValid() then
        physics_obj.Transform:SetPosition(boat.Transform:GetWorldPosition())
        physics_obj.Physics:ConstrainTo(boat.entity)
    end
end
local function AddConstrainedPhysicsObj(boat, physics_obj)
    physics_obj:ListenForEvent("onremove", function() RemoveConstrainedPhysicsObj(physics_obj) end, boat)

    physics_obj:DoTaskInTime(0, constrain_object_to_boat, boat)
end

local function on_start_steering(inst)
    if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller.isclientcontrollerattached then
        inst.components.reticule:CreateReticule()
    end
end

local function on_stop_steering(inst)
    if ThePlayer and ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller.isclientcontrollerattached then
        inst.lastreticuleangle = nil
        inst.components.reticule:DestroyReticule()
    end
end

local function ReticuleTargetFn(inst)
    local dir = Vector3(
        TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT),
        0,
        TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
    )
    local deadzone = TUNING.CONTROLLER_DEADZONE_RADIUS

    if math.abs(dir.x) >= deadzone or math.abs(dir.z) >= deadzone then
        dir = dir:GetNormalized()

        inst.lastreticuleangle = dir
    elseif inst.lastreticuleangle ~= nil then
        dir = inst.lastreticuleangle
    else
        return nil
    end

    local Camangle = TheCamera:GetHeading() / 180
    local theta = -PI * (0.5 - Camangle)
    local sintheta, costheta = math.sin(theta), math.cos(theta)

    local newx = dir.x * costheta - dir.z * sintheta
    local newz = dir.x * sintheta + dir.z * costheta

    local range = 7
    local pos = inst:GetPosition()
    pos.x = pos.x - (newx * range)
    pos.z = pos.z - (newz * range)

    return pos
end

local function EnableBoatItemCollision(inst)
    if not inst.boat_item_collision then
        inst.boat_item_collision = SpawnPrefab(inst.item_collision_prefab)
        AddConstrainedPhysicsObj(inst, inst.boat_item_collision)
    end
end

local function DisableBoatItemCollision(inst)
    if inst.boat_item_collision then
        RemoveConstrainedPhysicsObj(inst.boat_item_collision) --also :Remove()s object
        inst.boat_item_collision = nil
    end
end

local function OnPhysicsWake(inst)
    EnableBoatItemCollision(inst)
    if inst.stopupdatingtask then
        inst.stopupdatingtask:Cancel()
        inst.stopupdatingtask = nil
    else
        inst.components.walkableplatform:StartUpdating()
    end
    inst.components.boatphysics:StartUpdating()
end

local function physicssleep_stopupdating(inst)
    inst.components.walkableplatform:StopUpdating()
    inst.stopupdatingtask = nil
end
local function OnPhysicsSleep(inst)
    DisableBoatItemCollision(inst)
    inst.stopupdatingtask = inst:DoTaskInTime(1, physicssleep_stopupdating)
    inst.components.boatphysics:StopUpdating()
end

local function StopBoatPhysics(inst)
    --Boats currently need to not go to sleep because
    --constraints will cause a crash if either the target object or the source object is removed from the physics world
    inst.Physics:SetDontRemoveOnSleep(false)
end

local function StartBoatPhysics(inst)
    inst.Physics:SetDontRemoveOnSleep(true)
end

local function SpawnFragment(lp, prefix, offset_x, offset_y, offset_z, ignite)
    local fragment = SpawnPrefab(prefix)
    fragment.Transform:SetPosition(lp.x + offset_x, lp.y + offset_y, lp.z + offset_z)

    if offset_y > 0 and fragment.Physics then
        fragment.Physics:SetVel(0, -0.25, 0)
    end

    if ignite and fragment.components.burnable then
        fragment.components.burnable:Ignite()
    end

    return fragment
end

local function OnEntityReplicated(inst)
    --Use this setting because we can rotate, and we are not billboarded with discreet anim facings
    --NOTE: this setting can only be applied after entity replicated
    inst.Transform:SetInterpolateRotation(true)
end

local function create_common_pre(inst, bank, build, data)
    data = data or {}

    local radius = data.radius or TUNING.BOAT.RADIUS

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    if data.minimap_image then
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(data.minimap_image)
        inst.MiniMapEntity:SetPriority(-1)
    end
    inst.entity:AddNetwork()

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("boat")
    inst:AddTag("wood")

    local phys = inst.entity:AddPhysics()
    phys:SetMass(TUNING.BOAT.MASS)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES
    )
    phys:SetCylinder(radius, 3)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
    inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.scrapbook_anim = "idle_full"
    inst.scrapbook_inspectonseen = true

    if data.scale then
        inst.AnimState:SetScale(data.scale, data.scale, data.scale)
    end

    --
    local walkableplatform = inst:AddComponent("walkableplatform")
    walkableplatform.platform_radius = radius

    --
    local healthsyncer = inst:AddComponent("healthsyncer")
    healthsyncer.max_health = data.max_health or TUNING.BOAT.HEALTH

    --
    local waterphysics = inst:AddComponent("waterphysics")
    waterphysics.restitution = 0.75

    --
    local reticule = inst:AddComponent("reticule")
    reticule.targetfn = ReticuleTargetFn
    reticule.ispassableatallpoints = true

    --
    inst.on_start_steering = on_start_steering
    inst.on_stop_steering = on_stop_steering

    --
    inst.doplatformcamerazoom = net_bool(inst.GUID, "doplatformcamerazoom", "doplatformcamerazoomdirty")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("endsteeringreticule", function(inst2, event_data)
            if ThePlayer and ThePlayer == event_data.player then
                inst2:on_stop_steering()
            end
        end)
        inst:ListenForEvent("starsteeringreticule", function(inst2, event_data)
            if ThePlayer and ThePlayer == event_data.player then
                inst2:on_start_steering()
            end
        end)

        inst:AddComponent("boattrail")
    end

    local boatringdata = inst:AddComponent("boatringdata")
    boatringdata:SetRadius(radius)
    boatringdata:SetNumSegments(8)

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
    end

    return inst
end

local function empty_loot_function() end

local function InstantlyBreakBoat(inst)
    -- This is not for SGboat but is for safety on physics.
    if inst.components.boatphysics then
        inst.components.boatphysics:SetHalting(true)
    end
    --Keep this in sync with SGboat.
    for entity_on_platform in pairs(inst.components.walkableplatform:GetEntitiesOnPlatform()) do
        entity_on_platform:PushEvent("abandon_ship")
    end
    for player_on_platform in pairs(inst.components.walkableplatform:GetPlayersOnPlatform()) do
        player_on_platform:PushEvent("onpresink")
    end
    inst:sinkloot()
    if inst.postsinkfn then
        inst:postsinkfn()
    end
    inst:Remove()
end

local function GetSafePhysicsRadius(inst)
    return (inst.components.hull ~= nil and inst.components.hull:GetRadius() or TUNING.BOAT.RADIUS) + 0.18 -- Add a small offset for item overhangs.
end

local function IsBoatEdgeOverLand(inst, override_position_pt)
    local map = TheWorld.Map
    local radius = inst:GetSafePhysicsRadius()
    local segment_count = BOAT_COLLISION_SEGMENT_COUNT * 2
    local segment_span = TWOPI / segment_count
    local x, y, z
    if override_position_pt then
        x, y, z = override_position_pt:Get()
    else
        x, y, z = inst.Transform:GetWorldPosition()
    end
    for segement_idx = 0, segment_count do
        local angle = segement_idx * segment_span

        local angle0 = angle - segment_span / 2
        local x0 = math.cos(angle0) * radius
        local z0 = math.sin(angle0) * radius
        if not map:IsOceanTileAtPoint(x + x0, 0, z + z0) or map:IsVisualGroundAtPoint(x + x0, 0, z + z0) then
            return true
        end

        local angle1 = angle + segment_span / 2
        local x1 = math.cos(angle1) * radius
        local z1 = math.sin(angle1) * radius
        if not map:IsOceanTileAtPoint(x + x1, 0, z + z1) or map:IsVisualGroundAtPoint(x + x1, 0, z + z1) then
            return true
        end
    end

    return false
end

local PLANK_EDGE_OFFSET = -0.05
local function create_master_pst(inst, data)
    data = data or {}

    inst.leak_build = data.leak_build
    inst.leak_build_override = data.leak_build_override

    local radius = data.radius or TUNING.BOAT.RADIUS

    inst.Physics:SetDontRemoveOnSleep(true)
    inst.item_collision_prefab = data.item_collision_prefab
    EnableBoatItemCollision(inst)

    inst.entity:AddPhysicsWaker() --server only component
    inst.PhysicsWaker:SetTimeBetweenWakeTests(TUNING.BOAT.WAKE_TEST_TIME)

    local hull = inst:AddComponent("hull")
    hull:SetRadius(radius)

    if data.boatlip_prefab then
        hull:SetBoatLip(SpawnPrefab(data.boatlip_prefab), data.scale or 1.0)
    end

    if data.plank_prefab then
        local walking_plank = SpawnPrefab(data.plank_prefab)
        hull:AttachEntityToBoat(walking_plank, 0, radius + PLANK_EDGE_OFFSET, true)
        hull:SetPlank(walking_plank)
    end

    if not data.fireproof then
        inst.activefires = 0

        local burnable_locator = SpawnPrefab("burnable_locator_medium")
        burnable_locator.boat = inst
        hull:AttachEntityToBoat(burnable_locator, 0, 0, true)

        burnable_locator = SpawnPrefab("burnable_locator_medium")
        burnable_locator.boat = inst
        hull:AttachEntityToBoat(burnable_locator, 2.5, 0, true)

        burnable_locator = SpawnPrefab("burnable_locator_medium")
        burnable_locator.boat = inst
        hull:AttachEntityToBoat(burnable_locator, -2.5, 0, true)

        burnable_locator = SpawnPrefab("burnable_locator_medium")
        burnable_locator.boat = inst
        hull:AttachEntityToBoat(burnable_locator, 0, 2.5, true)

        burnable_locator = SpawnPrefab("burnable_locator_medium")
        burnable_locator.boat = inst
        hull:AttachEntityToBoat(burnable_locator, 0, -2.5, true)
    end

    --
    local repairable = inst:AddComponent("repairable")
    repairable.repairmaterial = MATERIALS.WOOD

    --
    inst:AddComponent("boatring")
    inst:AddComponent("hullhealth")
    inst:AddComponent("boatphysics")
    inst:AddComponent("boatdrifter")
    inst:AddComponent("savedrotation")

    local health = inst:AddComponent("health")
    health:SetMaxHealth(data.max_health or TUNING.BOAT.HEALTH)
    health.nofadeout = true

    inst:SetStateGraph(data.stategraph or "SGboat")

    inst.StopBoatPhysics = StopBoatPhysics
    inst.StartBoatPhysics = StartBoatPhysics

    inst.OnPhysicsWake = OnPhysicsWake
    inst.OnPhysicsSleep = OnPhysicsSleep

    inst.sinkloot = empty_loot_function
    inst.InstantlyBreakBoat = InstantlyBreakBoat
    inst.GetSafePhysicsRadius = GetSafePhysicsRadius
    inst.IsBoatEdgeOverLand = IsBoatEdgeOverLand

    return inst
end

local function build_boat_collision_mesh(radius, height)
    local segment_count = BOAT_COLLISION_SEGMENT_COUNT
    local segment_span = TWOPI / segment_count

    local triangles = {}
    local y0 = 0
    local y1 = height

    for segement_idx = 0, segment_count do
        local angle = segement_idx * segment_span
        local angle0 = angle - segment_span / 2
        local angle1 = angle + segment_span / 2

        local x0 = math.cos(angle0) * radius
        local z0 = math.sin(angle0) * radius

        local x1 = math.cos(angle1) * radius
        local z1 = math.sin(angle1) * radius

        table.insert(triangles, x0)
        table.insert(triangles, y0)
        table.insert(triangles, z0)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y1)
        table.insert(triangles, z1)
    end

    return triangles
end

local function boat_player_collision_template(radius)
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    inst:AddTag("CLASSIFIED")

    local phys = inst.entity:AddPhysics()
    phys:SetMass(0)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetRestitution(0)
    phys:SetCollisionGroup(COLLISION.BOAT_LIMITS)
    phys:SetCollisionMask(
        COLLISION.CHARACTERS,
        COLLISION.WORLD
    )
    phys:SetTriangleMesh(build_boat_collision_mesh(radius + 0.1, 3))

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function boat_item_collision_template(radius)
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    inst:AddTag("CLASSIFIED")

    local phys = inst.entity:AddPhysics()
    phys:SetMass(1000)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.BOAT_LIMITS)
    phys:SetCollisionMask(
        COLLISION.ITEMS,
        COLLISION.FLYERS,
        COLLISION.WORLD
    )
    phys:SetTriangleMesh(build_boat_collision_mesh(radius + 0.2, 3))
    --Boats currently need to not go to sleep because
    --constraints will cause a crash if either the target object or the source object is removed from the physics world
    --while the above is still true, the constraint is now properly removed before despawning the object, and can be safely ignored for this object, kept for future copy/pasting.
    phys:SetDontRemoveOnSleep(true)

    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

-- ICE FLOE
local function boat_magma_deploy_blocker_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    -- Prevent things from being deployed onto the ice floes.
    inst:SetDeployExtraSpacing(TUNING.OCEAN_ICE_RADIUS + 0.1)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function magma_ondeath(inst)
    if inst:IsAsleep() then
        if not inst.sg:HasStateTag("dead") then
            for ent in pairs(inst.components.walkableplatform:GetEntitiesOnPlatform()) do
                ent:PushEvent("abandon_ship")
            end
        end
        inst.sinkloot_asleep()
        inst:Remove()
    end
end

local function magma_fn()
    local inst = CreateEntity()

    local bank = "boat_ice"
    local build = "boat_ice"
    local MAGMA_BOAT_DATA = {
        radius = TUNING.OCEAN_ICE_RADIUS,
        max_health = TUNING.OCEAN_ICE_HEALTH * 3,
        item_collision_prefab = "boat_magma_item_collision",
        stategraph = "SGboat_ice",
        fireproof = true,
    }

    inst = create_common_pre(inst, bank, build, MAGMA_BOAT_DATA)

    inst:RemoveTag("wood") -- Cookie Cutters should not eat it.

    inst.AnimState:SetMultColour(0.8, .5, .25, 1)

    inst.material = "ice"
    inst.walksound = "ice"

    inst.components.walkableplatform.player_collision_prefab = "boat_magma_player_collision"

    local boattrail = inst.components.boattrail
    if boattrail then
        local scale = TUNING.OCEAN_ICE_RADIUS / TUNING.BOAT.RADIUS
        boattrail.scale_x = scale
        boattrail.scale_y = scale

        boattrail.radius = boattrail.radius * scale
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddTag("magma_boat")

    inst.GetIdleLevel = function()
        local health_percent = inst.components.health:GetPercent()
        return (health_percent > 0.66 and "1")
            or (health_percent > 0.33 and "2")
            or "3"
    end

    inst = create_master_pst(inst, MAGMA_BOAT_DATA)

    inst:ListenForEvent("spawnnewboatleak", OnSpawnNewBoatLeak)
    inst:ListenForEvent("death", magma_ondeath)

    inst.components.hullhealth:SetSelfDegrading(1 + math.random())
    inst.components.hullhealth.leakproof = true

    inst.components.repairable.repairmaterial = nil

    inst.sounds = sounds_magma
    inst.boat_crackle = "deer_fire_burst"

    inst:DoTaskInTime(FRAMES, function(i)
        local ix, iy, iz = i.Transform:GetWorldPosition()
        local deploy_blocker = SpawnPrefab("boat_magma_deploy_blocker")
        deploy_blocker.Transform:SetPosition(ix, iy, iz)
    end)

    inst.sinkloot = function()
        local ignitefragments = false --(inst.activefires > 0)
        local locus_point = inst:GetPosition()
        local num_loot = 3
        local loot_angle = PI2 / num_loot
        local loot_radius = (MAGMA_BOAT_DATA.radius / 2)
        for i = 1, num_loot do
            local r = (1 + math.sqrt(math.random())) * loot_radius
            local t = (i + 2 * math.random()) * loot_angle
            SpawnFragment(locus_point, "rocks", math.cos(t) * r, 0, math.sin(t) * r, ignitefragments)
        end
    end
    inst.sinkloot_asleep = function()
        local num_loot = math.random(3) - 1
        if num_loot > 0 then
            local locus_point = inst:GetPosition()
            local loot_angle = PI2 / num_loot
            local loot_radius = (MAGMA_BOAT_DATA.radius / 2)
            for i = 1, num_loot do
                local r = (1 + math.sqrt(math.random())) * loot_radius
                local t = (i + 2 * math.random()) * loot_angle
                SpawnFragment(locus_point, "rocks", math.cos(t) * r, 0, math.sin(t) * r, false)
            end
        end
    end
    inst.postsinkfn = function(inst)
        local break_fx = SpawnPrefab("deer_fire_burst")
        break_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    inst.SpawnFragment = SpawnFragment

    return inst
end

-- ITEMS

function CLIENT_CanDeployBoat(inst, pt, mouseover, deployer, rotation)
    local inventory = deployer and deployer.replica.inventory
    if inventory and inventory:IsFloaterHeld() then
        local hop_range = TUNING.FLOATING_HOP_DISTANCE_PLATFORM - 0.01 --make sure we're close enough to hop at max range
        local max_range = inst._boat_radius + hop_range
        local min_range = inst._boat_radius + 0.5
        local dsq = deployer:GetDistanceSqToPoint(pt)
        if dsq > max_range * max_range or dsq < min_range * min_range then
            return false
        end
    end
    return TheWorld.Map:CanDeployBoatAtPointInWater(pt, inst, mouseover,
        {
            boat_radius = inst._boat_radius,
            boat_extra_spacing = 0.2,
            min_distance_from_land = 0.2,
        })
end

-- COLLISIONS
local function boat_magma_player_collision_fn()
    return boat_player_collision_template(TUNING.OCEAN_ICE_RADIUS)
end

local function boat_magma_item_collision_fn()
    return boat_item_collision_template(TUNING.OCEAN_ICE_RADIUS)
end

return Prefab("boat_magma", magma_fn, ice_assets, ice_prefabs),
    Prefab("boat_magma_player_collision", boat_magma_player_collision_fn),
    Prefab("boat_magma_item_collision", boat_magma_item_collision_fn),
    Prefab("boat_magma_deploy_blocker", boat_magma_deploy_blocker_fn)

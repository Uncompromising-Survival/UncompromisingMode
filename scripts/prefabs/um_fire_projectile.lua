local function Shrink(inst)
    inst.scale = inst.scale - .015
    inst.components.propagator.heatoutput = 12 - (6 - 6 * inst.scale)
    inst.components.propagator.propagaterange = inst.proprange - (1 - .5 * inst.scale)
    inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
    if inst.scale < 0 then
        inst:Remove()
    end
end

local function ChillSurroundings(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local burnables = TheSim:FindEntities(x, 0, z, inst.scale * 2, nil, inst.dont_hit_tags) -- There isn't a way to search for entities tagged as burnable.... (there is no burnable tag)
    local damage = inst.damage or 1
    for i, v in ipairs(burnables) do
        if v:IsValid() then
            local attackable = UMCommonFns.IsNotFriendly(inst.damager, v)
            if not attackable then return end
            if v.components.burnable and not (v.prefab == "um_fire_projectile" and v.chilly) then
                v.components.burnable:Extinguish(true)
            end
            if v.components.health then
                v.components.health:DoDelta(-damage, false, inst.damager and inst.damager.prefab or nil, nil, inst.damager)
            end
            if v.components.combat and inst.damager then
                v.components.combat:SuggestTarget(inst.damager)
            end
            if v.components.freezable then
                v.components.freezable:AddColdness(0.15, 3)
            end
            if v.components.temperature and v.components.temperature.current > -15 then
                v.components.temperature:DoDelta(-1)
            end
        end
    end
end

local function BurnSurroundings(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local burnables = TheSim:FindEntities(x, 0, z, inst.scale * 2, nil, inst.dont_hit_tags) -- There isn't a way to search for entities tagged as burnable.... (there is no burnable tag)
    local damage = inst.damage or 1
    for i, v in ipairs(burnables) do
        if v:IsValid() then
            if v.prefab == "snowpile" then
                SpawnPrefab("splash_snow_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
                v:Remove()
            end
            local attackable = UMCommonFns.IsNotFriendly(inst.damager, v)
            if not attackable then return end
            if not v.components.fueled and v.components.burnable and not v.components.burnable:IsBurning() and not v:HasTag("burnt") then
                v.components.burnable:Ignite(true, inst, inst.damager)
            end
            if v.components.health then
                v.components.health:DoFireDamage(damage, inst.damager, true)
            end
            if v.components.combat and inst.damager then
                v.components.combat:SuggestTarget(inst.damager)
            end
            if v.components.temperature and v.components.temperature.current < 90 then
                v.components.temperature:DoDelta(1)
            end
        end
    end
end

local function BeginScaleDown(inst)
    inst:DoTaskInTime(inst.time, function(inst)
        inst.Physics:SetMotorVel(0, 0, 0)
        inst:DoPeriodicTask(FRAMES, Shrink)
    end)
end

local function Grow(inst)
    inst.scale = inst.scale + .03
    inst.components.propagator.heatoutput = 12 - (6 - 6 * inst.scale)
    inst.components.propagator.propagaterange = inst.proprange - (1 - .5 * inst.scale)
    inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
    if inst.scale > inst.scalemax then
        inst.growing:Cancel()
        inst.growing = nil
        BeginScaleDown(inst)
    end
end

local function BeginScaleUp(inst, time)
    inst.scale = inst.scale / 6
    inst.Transform:SetScale(inst.scale, inst.scale, inst.scale)
    inst.growing = inst:DoPeriodicTask(FRAMES, Grow)
end

local function SetupColdLight(inst)
    inst.Light:Enable(true)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(12)
    inst.Light:SetColour(64 / 255, 64 / 255, 208 / 255)
end

local function ShootFire(inst)
    local speed = inst.speed or 10
    if not inst.time then
        inst.time = .01
    end
    local time_to_extinguish = inst.totaltime or 6
    inst.Physics:SetMotorVel(speed, 0, 0)
    MakeLargePropagator(inst)
    inst.components.propagator.heatoutput = 12
    inst.proprange = inst.components.propagator.propagaterange
    MakeLargeBurnable(inst, time_to_extinguish)
    local burnable = inst.components.burnable
    burnable:SetOnIgniteFn(nil)
    burnable:SetOnExtinguishFn(inst.Remove)
    burnable.fxdata[1].prefab = "character_fire"

    if inst.chilly then
        burnable.fxdata[1].prefab = "warg_mutated_breath_fx"
        burnable:Ignite()
        for i, fx in ipairs(burnable.fxchildren) do
            -- fx.AnimState:SetMultColour(0.1,0.2,.8,1)
            fx.kill_fx_task:Cancel()
            fx.kill_fx_task = nil
            fx.SoundEmitter:PlaySound("lunarhail_event/creatures/lunar_buzzard/fire_ground_LP", "fire_loop")
            fx.spawn_embers_task:Cancel()
            fx.spawn_embers_task = nil
        end
        inst.components.propagator:StopSpreading(true)
    else
        burnable:Ignite()
    end

    if not inst.scale then
        inst.scale = 1
    end
    inst.scalemax = inst.scale
    BeginScaleUp(inst)
    if inst.chilly then
        SetupColdLight(inst)
        inst:DoPeriodicTask(FRAMES, ChillSurroundings)
    elseif inst.cursed then
        -- ADD CURSED
        -- What?
    else
        inst:DoPeriodicTask(FRAMES, BurnSurroundings)
    end
end

local function fnfire()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fire")
    inst.AnimState:SetBuild("fire")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)

    inst:AddTag("FX")
    MakeInventoryPhysics(inst)

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.doer = nil
    inst.Light:Enable(false)

    inst.Physics:SetMass(1)
    inst.Physics:SetDamping(.1)
    inst.Physics:SetFriction(.3)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES
    )

    inst:DoTaskInTime(0, ShootFire)
    inst.dont_hit_tags = JoinArrays(UMCommonFns.GHOSTLIKE_TAGS, {"INLIMBO", "notarget", "noattack", "invisible"})

    return inst
end
-- Fire Projectile

-- Shock Projectile

local function Redirection(inst, flooded) -- See where the arc should be pointing next
    local x,y,z = inst.Transform:GetWorldPosition()
    local living_things = TheSim:FindEntities(x,y,z,flooded and 32 or 16,{"_health"},inst.dont_hit_tags) -- Do a wide search for things to hit
    local shoot_offcourse
    if math.random() > 0.8 then -- chance for the arc to zig-zag
        shoot_offcourse = true
    end

    local closest_distance = 999
    local closest_target
    for i,v in ipairs(living_things) do
        if v:GetDistanceSqToInst(inst) < closest_distance and not table.contains(inst.shocked,v) then
            closest_distance = v:GetDistanceSqToInst(inst)
            closest_target = v
        end
    end

    if closest_target then
        inst:ForceFacePoint(closest_target:GetPosition())
    end
    if shoot_offcourse then
        inst.Transform:SetRotation(inst:GetRotation()+(math.random() > 0.5 and 90 or -90))
    end

    inst.Physics:SetMotorVel(flooded and (inst.speed * 1.4) or inst.speed, 0, 0) -- Faster on flooded
end

local function GenerateArcs(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sparks").Transform:SetPosition(x + math.random(-10,10)/10,0,z + math.random(-10,10)/10)

    local current_tile = TheWorld.Map:GetTileAtPoint(x,y,z)
    local flooded
    if current_tile == WORLD_TILES.UM_FLOODWATER or current_tile == WORLD_TILES.UM_FLOODWATER_GROTTO or current_tile == WORLD_TILES.UM_FLOODWATER_BROILING then
        inst.lifetime = inst.lifetime - 1
        flooded = true
    else
        inst.lifetime = inst.lifetime - 0.7 -- Longer projectile lifetime on flooded tiles
    end    

    if inst.counter then -- AXE The purpose of this is to make this function only do the damage and search every 0.33 seconds, where the sparking fx generates every 0.167 seconds. Keeping only 1 DoTaskInTime for this function
        SpawnPrefab("electricchargedfx").Transform:SetPosition(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(x,0,z,2,{"_health"},inst.dont_hit_tags)
        for i,ent in ipairs(ents) do
            if ent.prefab ~= inst.prefab then
                ent.components.combat:GetAttacked(inst.attacker and inst.attacker or nil, 20, nil, "electric")

                table.insert(inst.shocked,ent)
            end
        end
        inst.counter = nil
    else
        if math.random() > 0.5 then
            Redirection(inst,flooded) -- See what kind of redirection I should be doing
        end
        inst.counter = true
    end

    if inst.lifetime < 0 then
        inst:Remove()
    end
end

local function ShootShock(inst)
    inst.speed = inst.speed or 10
    
    inst.Physics:SetMotorVel(inst.speed, 0, 0)
    
    inst.lifetime = 12
    inst:DoPeriodicTask(0.08,GenerateArcs)
    --[[inst:DoPeriodicTask(0.08,function(inst)
        SpawnPrefab("electricchargedfx").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end)]]
end

local function fnshock()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    -- No animations, purely invisible the FX prefabs it spawns serve as visualization

    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetMass(1)
    inst.Physics:SetDamping(.1)
    inst.Physics:SetFriction(.3)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
    inst.Physics:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES
    )

    inst:DoTaskInTime(0, ShootShock)
    inst.dont_hit_tags = JoinArrays(UMCommonFns.GHOSTLIKE_TAGS, {"INLIMBO", "notarget", "noattack", "invisible", "worm", "structure"})
    inst.shocked = {}

    inst.speed = 10
    inst.persists = false
    return inst
end

return Prefab("um_fire_projectile", fnfire),
    Prefab("um_shock_projectile", fnshock)
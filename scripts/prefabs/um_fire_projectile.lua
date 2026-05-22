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
        if v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player") then
            return
        end

        if v.components.burnable and not (v.prefab == "um_fire_projectile" and v.chilly) then
            v.components.burnable:Extinguish(true)
        end

        if v.components.health and v:IsValid() then
            v.components.health:DoDelta(-1, false, inst.damager)
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

local function BurnSurroundings(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local burnables = TheSim:FindEntities(x, 0, z, inst.scale * 2, nil, inst.dont_hit_tags) -- There isn't a way to search for entities tagged as burnable.... (there is no burnable tag)
    local damage = inst.damage or 1
    for i, v in ipairs(burnables) do
        if v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader() == inst.damager
            or inst.damager ~= nil and inst.damager:HasTag("player") and v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")
        then
            return
        end

        if v.components.burnable and v.components.burnable.canlight then
            v.components.burnable:Ignite(true, inst, inst.damager)
        end
        if v.components.health and v:IsValid() then
            v.components.health:DoFireDamage(inst.damage, inst.damager, true)
        end
        if v.components.combat and inst.damager then
            v.components.combat:SuggestTarget(inst.damager)
        end
        if v.components.temperature and v.components.temperature.current < 90 then
            v.components.temperature:DoDelta(1)
        end
        if v.prefab == "snowpile" then
            SpawnPrefab("splash_snow_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
            v:Remove()
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

local function Shoot(inst)
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

local function fn()
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

    inst:DoTaskInTime(0, Shoot)
    inst.dont_hit_tags = { "INLIMBO", "noattack", "invisible" } -- When adding more tags elsewhere do this when creating this prefab, please. inst.dont_hit_tags = JoinArrays(inst.dont_hit_tags, yourtablehere)

    return inst
end

return Prefab("um_fire_projectile", fn)

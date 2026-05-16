local assets =
{
    Asset("ANIM", "anim/lava_vomit.zip"),
}

local easing = require("easing")

local AURA_EXCLUDE_TAGS = { "playerghost", "companion", "ghost", "shadow", "shadowminion", "noauradamage",
    "INLIMBO", "notarget", "noattack", "flight", "flying", "dragonfly", "lavae", "invisible", "rabbit", "bird" }

local AURA_EXCLUDE_TAGS_DRAGONFLY = { "playerghost", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO",
    "notarget", "noattack", "flight", "flying", "dragonfly", "lavae", "invisible", "rabbit", "bird" }

local function OnLoad(inst, data)
    inst:Remove()
end

local function GetStatus(inst, viewer)
    return inst.cooled and "COOL" or "HOT"
end

local INTENSITY = .8

local function fade_in(inst)
    inst.components.fader:StopAll()
    inst.Light:Enable(true)
    inst.components.fader:Fade(0, INTENSITY, 5 * FRAMES, function(v) inst.Light:SetIntensity(v) end)
end

local function fade_out(inst)
    inst.components.fader:StopAll()
    inst.components.fader:Fade(INTENSITY, 0, 5 * FRAMES, function(v) inst.Light:SetIntensity(v) end,
        function() inst.Light:Enable(false) end)
end

local function TrySlowdown(inst, target)
    local debuffkey = inst.prefab
    if inst.prefab ~= "um_lavaspit_slobber" then
        if (not target:HasTag("player") or target == inst.lobber) and target.components.locomotor ~= nil then
            if target._lavavomit_speedmulttask ~= nil then
                target._lavavomit_speedmulttask:Cancel()
            end
            target._lavavomit_speedmulttask = target:DoTaskInTime(0.6,
                function(i)
                    i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                    i._lavavomit_speedmulttask = nil
                end)

            target.components.locomotor:SetExternalSpeedMultiplier(target, debuffkey, 0.5)
        end
    end

    if (not target:HasTag("player") or target == inst.lobber) and (inst.prefab ~= "um_lavaspit_slobber" and inst.components.propagator ~= nil or inst.prefab == "um_lavaspit_slobber") and target.components.combat ~= nil and target.components.health ~= nil and
        not target:HasTag("dragonfly") and not target:HasTag("lavae") and target.components.burnable ~= nil then

        target.components.health:DoFireDamage(20, inst.lobber, true)
        if target.components.freezable ~= nil then
            if target.components.freezable:IsFrozen() then
                target.components.freezable:Unfreeze()
            elseif target.components.freezable.coldness > 0 then
                target.components.freezable:AddColdness(-2)
            end
        end

        target:PushEvent("onignite")

        if inst.lobber ~= nil then
            target.components.combat:SuggestTarget(inst.lobber)
            if target.components.combat.onhitfn ~= nil then
                target.components.combat.onhitfn(target, inst.lobber, 0, 0) --fences don't really take damage to break, onhit they get hammered, normal walls update their visuals onhit.
            end
        end

        SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(target.Transform:GetWorldPosition())
        --especial case handling for walls.
        if target:HasTag("wall") and target.components.combat.onhitfn ~= nil then
            target.components.health:DoDelta(inst.prefab == "um_lavaspit_slobber" and -6 or -4)
        end
    end
end

local function DoAreaSlow(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.dragonflyspit then
        local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, AURA_EXCLUDE_TAGS_DRAGONFLY)
        for i, v in ipairs(ents) do
            if v.components ~= nil and v.components.locomotor ~= nil then
                TrySlowdown(inst, v)
            end
        end
    else
        local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, AURA_EXCLUDE_TAGS)
        for i, v in ipairs(ents) do
            if v.components ~= nil and v.components.locomotor ~= nil then
                TrySlowdown(inst, v)
            end
        end
    end

    local walls = TheSim:FindEntities(x, y, z, inst.components.aura.radius, { "wall" }, { "INLIMBO", "_inventoryitem" })

    for i, v in ipairs(walls) do
        if v.components ~= nil then
            TrySlowdown(inst, v)
        end
    end
end

local function fn(Sim) --Sim
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lava_vomit")
    inst.AnimState:SetBuild("lava_vomit")
    inst.Transform:SetFourFaced()

    -- inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
    -- inst.AnimState:SetLayer( LAYER_BACKGROUND )
    -- inst.AnimState:SetSortOrder( 3 )

    inst:AddComponent("fader")
    local light = inst.entity:AddLight()
    light:SetFalloff(.5)
    light:SetIntensity(INTENSITY)
    light:SetRadius(1)
    light:Enable(false)
    light:SetColour(200 / 255, 100 / 255, 170 / 255)
    fade_in(inst)

    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Transform:SetScale(1.1, 1.1, 1.1)

    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()
    --[[]]
    if not TheWorld.ismastersim then
        return inst
    end

    MakeLargePropagator(inst)
    inst.components.propagator.heatoutput = 24
    inst.components.propagator.decayrate = 0
    inst.components.propagator:Flash()
    inst.components.propagator:StartSpreading()

    inst.coolingtime = 5

    inst.cooltask = inst:DoTaskInTime(inst.coolingtime, function(inst)
        inst.AnimState:PushAnimation("cool", false)
        fade_out(inst)
        inst:DoTaskInTime(4 * FRAMES, function(inst)
            inst.AnimState:ClearBloomEffectHandle()
        end)
    end)

    inst.cooltask2 = inst:DoTaskInTime(inst.coolingtime, function(inst)
        inst.AnimState:SetPercent("cool", 1)
        if inst.components.propagator then
            inst.components.propagator:StopSpreading()
            inst:RemoveComponent("propagator")
        end
        inst.cooled = true

        if not inst.components.colortweener then
            inst:AddComponent("colourtweener")
        end

        inst.cooltask3 = inst:DoTaskInTime(1, function(inst)
            inst:RemoveComponent("unevenground")
            if inst._spoiltask ~= nil then
                inst._spoiltask:Cancel()
            end
            inst._spoiltask = nil
        end)


        inst.components.colourtweener:StartTween({ 0, 0, 0, 0 }, 7, function(inst) inst:Remove() end)
    end)

    --[[inst:ListenForEvent("animqueueover", function(inst)
           inst.AnimState:SetPercent("cool", 1)
        if inst.components.propagator then
            inst.components.propagator:StopSpreading()
            inst:RemoveComponent("propagator")
        end
        inst.cooled = true
        inst:AddComponent("colourtweener")
        inst.components.colourtweener:StartTween({0,0,0,0}, 7, function(inst) inst:Remove() end)
    end)]]

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.slowed_objects = {}

    inst:AddComponent("unevenground")
    inst.components.unevenground.radius = 2

    inst:AddComponent("aura")
    inst.components.aura.radius = 3
    inst.components.aura.tickperiod = 0.6
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)

    inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaSlow, inst.components.aura.tickperiod * .5)

    inst.cooled = false

    inst.dragonflyspit = false

    inst.OnLoad = OnLoad

    return inst
end

local function slobberfn()
    local inst = fn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveComponent("unevenground")
    inst:RemoveComponent("propagator")

    inst.lobber = nil

    inst.coolingtime = 15

    inst.cooltask:Cancel()
    inst.cooltask2:Cancel()
    inst._spoiltask:Cancel()

    inst.cooltask = inst:DoTaskInTime(inst.coolingtime, function(inst)
        inst.AnimState:PushAnimation("cool", false)
        fade_out(inst)
        inst:DoTaskInTime(4 * FRAMES, function(inst)
            inst.AnimState:ClearBloomEffectHandle()
        end)
    end)

    inst.cooltask2 = inst:DoTaskInTime(inst.coolingtime, function(inst)
        inst.AnimState:SetPercent("cool", 1)
        if inst.components.propagator then
            inst.components.propagator:StopSpreading()
            inst:RemoveComponent("propagator")
        end
        inst.cooled = true

        if not inst.components.colortweener then
            inst:AddComponent("colourtweener")
        end

        inst.cooltask3 = inst:DoTaskInTime(1, function(inst)
            inst:RemoveComponent("unevenground")
            if inst._spoiltask ~= nil then
                inst._spoiltask:Cancel()
            end
            inst._spoiltask = nil
        end)


        inst.components.colourtweener:StartTween({ 0, 0, 0, 0 }, 7, function(inst) inst:Remove() end)
    end)

    inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaSlow, inst.components.aura.tickperiod * .5)

    return inst
end

local function LaunchMore(inst, xpos, zpos, sound)
    if sound then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/vomit")
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local targetpos = inst:GetPosition()

    local projectile = SpawnPrefab("um_lavaspit_projectile")
    projectile.coolingtime = 15
    projectile.Transform:SetPosition(x, y, z)
    projectile.LaunchMorePhys = true
    projectile.lobber = inst.lobber

    targetpos.x = targetpos.x + xpos
    targetpos.z = targetpos.z + zpos

    local dx = targetpos.x - x
    local dz = targetpos.z - z

    local rangesq = dx * dx + dz * dz
    local maxrange = TUNING.FIRE_DETECTOR_RANGE
    --local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
    local speed = easing.linear(rangesq, maxrange, 5, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(20) --speed
    projectile.components.complexprojectile:SetGravity(-40)
    projectile.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
    projectile.components.complexprojectile.usehigharc = true
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end

local function OnHitInk(inst, attacker, target)
    if inst.nomorespawns == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local lavaspit = SpawnPrefab("um_lavaspit_slobber")

        lavaspit.Transform:SetPosition(x, 0, z)
        lavaspit.lobber = inst.lobber
        lavaspit.coolingtime = 15

        if inst.LaunchMoreSpit then
            LaunchMore(inst, -2.5, 0, true)
            LaunchMore(inst, 2.5, -2.5)
            LaunchMore(inst, 2.5, 2.5)
        else
            inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        end

        inst.nomorespawns = true

        inst:DoTaskInTime(0, inst.Remove)
    end
end

local function oncollide(inst, other)
    local x, y, z = inst.Transform:GetWorldPosition()
    if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("player") and
        not other:HasTag("lavaspit") or y <= inst:GetPhysicsRadius() + 0.001 then
        OnHitInk(inst, other)
    end
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.AnimState:SetBank("lava_spitball")
    inst.AnimState:SetBuild("lava_spitball")
    inst.AnimState:PlayAnimation("spin_loop", true)

    if not inst.LaunchMorePhys then
        inst.Transform:SetScale(1.1, 1.1, 1.1)
    end

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    --inst.Physics:CollidesWith(COLLISION.WORLD)

    if not inst.LaunchMorePhys then
        inst.Physics:CollidesWith(COLLISION.GIANTS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    end

    inst.Physics:SetCapsule(0.02, 0.02)

    inst.Physics:SetCollisionCallback(oncollide)
end

local function projectilefn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    inst.AnimState:SetBank("lava_spitball")
    inst.AnimState:SetBuild("lava_spitball")
    inst.AnimState:PlayAnimation("spin_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("lavaspit")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.lobber = nil
    inst.LaunchMoreSpit = false
    inst.LaunchMorePhys = false
    inst.nomorespawns = nil

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-20)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitInk)
    inst.components.complexprojectile.usehigharc = false

    inst.persists = false

    inst:AddComponent("locomotor")

    --inst:DoTaskInTime(0.1, function(inst) inst:DoPeriodicTask(0, TestProjectileLand) end)

    return inst
end

local function projectiletargetfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local snaildrake_projectile_assets =
{
    Asset("ANIM", "anim/lava_vomit.zip"),
    Asset("ANIM", "anim/spat_splat.zip"),
    Asset("ANIM", "anim/snapalm_bomb.zip"),
    Asset("ANIM", "anim/snapalm_splat.zip"),
    Asset("ANIM", "anim/goo_snapalm.zip"),
}

TUNING.SNAILDRAKE_SLUDGE_DAMAGE = 4
TUNING.SNAILDRAKE_SLIME_SPLAT_RADIUS = 1
TUNING.SNAILDRAKE_MAGMA_SLUDGE_DURATION = 15
TUNING.SNAILDRAKE_SLIME_SLUDGE_DURATION = 15

local SNAILDRAKE_AURA_EXCLUDE_TAGS = { "playerghost", "ghost", "shadow", "shadowminion", "INLIMBO",
    "notarget", "noattack", "flight", "flying", "dragonfly", "lavae", "invisible", "snaildrake" }

-- Apply AoE slow and damage to a target.
local function SnaildrakeTrySlowdownMagma(inst, target)
    local debuffkey = inst.prefab
    if target.components.locomotor then
        if target._lavavomit_speedmulttask ~= nil then
            target._lavavomit_speedmulttask:Cancel()
        end
        target._lavavomit_speedmulttask = target:DoTaskInTime(0.6, function(i)
                i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                i._lavavomit_speedmulttask = nil
            end)

        target.components.locomotor:SetExternalSpeedMultiplier(target, debuffkey, 0.5)
    end

    if target.components.combat and target.components.health and target.components.burnable and not target:HasAnyTag({"dragonfly", "lavae", "snaildrake"}) then
        target.components.health:DoFireDamage(20, inst.lobber, true)
        if target.components.freezable ~= nil then
            if target.components.freezable:IsFrozen() then
                target.components.freezable:Unfreeze()
            elseif target.components.freezable.coldness > 0 then
                target.components.freezable:AddColdness(-2)
            end
        end

        target:PushEvent("onignite")

        if inst.lobber ~= nil then
            target.components.combat:SuggestTarget(inst.lobber)
            if target.components.combat.onhitfn ~= nil then
                --fences don't really take damage to break, onhit they get hammered, 
                -- normal walls update their visuals onhit.
                target.components.combat.onhitfn(target, inst.lobber, 0, 0) 
            end
        end

        SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(target.Transform:GetWorldPosition())
        --especial case handling for walls.
        if target:HasTag("wall") and target.components.combat.onhitfn ~= nil then
            target.components.health:DoDelta(TUNING.SNAILDRAKE_SLUDGE_DAMAGE)
        end
    end
end

-- Find valid entities to apply the AoE slow and damage.
local function DoAreaEffectMagma(inst)
    local lobber = inst.lobber and inst.lobber:IsValid() and inst.lobber or nil
    local lobbercombat = lobber and lobber.components.combat or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, SNAILDRAKE_AURA_EXCLUDE_TAGS)
    for i, v in ipairs(ents) do
        if v ~= lobber and v.entity:IsVisible() and not (lobbercombat and lobbercombat:IsAlly(v)) and v.components.locomotor then
            SnaildrakeTrySlowdownMagma(inst, v)
        end
    end

    local walls = TheSim:FindEntities(x, y, z, inst.components.aura.radius, { "wall" }, { "INLIMBO", "_inventoryitem" })
    for i, v in ipairs(walls) do
        if v ~= lobber and v.entity:IsVisible() and not (lobbercombat and lobbercombat:IsAlly(v)) then
            SnaildrakeTrySlowdownMagma(inst, v)
        end
    end
end

-- Spawn a magma puddle when the projectile hits the ground.
local function OnHitMagma(inst, attacker, target)
    if inst.nomorespawns == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local sludge = SpawnPrefab("um_snaildrake_magma_sludge")

        sludge.Transform:SetPosition(x, 0, z)
        sludge.lobber = inst.lobber
        sludge.coolingtime = TUNING.SNAILDRAKE_MAGMA_SLUDGE_DURATION

        if inst.LaunchMoreSpit then
            LaunchMore(inst, -2.5, 0, true)
            LaunchMore(inst, 2.5, -2.5)
            LaunchMore(inst, 2.5, 2.5)
        else
            inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
        end

        inst.nomorespawns = true

        inst:DoTaskInTime(0, inst.Remove)
    end
end

-- Make sure to not hit other Snaildrakes.
local function OnCollideMagma(inst, other)
    local x, y, z = inst.Transform:GetWorldPosition()
    if (other ~= nil and other:IsValid() and 
        other:HasTag("_combat") and not other:HasTag("snaildrake") and 
        not other:HasTag("lavaspit") or y <= inst:GetPhysicsRadius() + 0.001
    ) then
        OnHitMagma(inst, other)
    end
end

-- Sticks the targets like an Ewecus and spawns an explosive
-- slime on them.
local function OnHitSlime(inst, attacker, other, dont_stick)
    if attacker and not attacker:IsValid() then
        attacker = nil
    end

    -- If not a direct hit, then check to see if the target
    -- was in splash range.
    if attacker and not other then
        other = attacker.components.combat.target
        if other and not(other:IsValid() and other:IsNear(inst, TUNING.SNAILDRAKE_SLIME_SPLAT_RADIUS)) then
            other = nil
        end
    end

    -- We've hit something. Stick an explosive slime onto them.
    if other then
        -- function Pinnable:Stick(goo_build, splashfxlist)
        -- Refer to pinnable component for custom vfx
        if not dont_stick and other.components.pinnable then
            other.components.pinnable:Stick("goo_snapalm")
        end
        other:AddDebuff("snaildrake_slime_debuff", "snaildrake_slime_debuff")
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        local sludge = SpawnPrefab("um_snaildrake_slime_sludge")
        sludge.Transform:SetPosition(x, 0, z)
    end

    inst:DoTaskInTime(0, inst.Remove)
end

-- Refer to the OnHitSlime function.
local function OnCollideSlime(inst, other)
    local attacker = inst.components.complexprojectile.attacker
    OnHitSlime(inst, attacker, other)
end

-- Find the first valid entity to apply the slime debuff.
local function DoAreaEffectSlime(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, AURA_EXCLUDE_TAGS)
    for i, v in ipairs(ents) do
        if v.components ~= nil and v.components.locomotor ~= nil then
            if v.sg and v.sg:HasState("hit") then
                v.sg:GoToState("hit")
            end
            OnHitSlime(inst, nil, v, true)
            inst:Remove()
            break
        end
    end
end

local function DoAreaEffectMeltSnowPiles(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local snow = TheSim:FindEntities(x, y, z, 6, "snowpile","_health")
    
    for i,v in ipairs(snow) do
        if v:HasTag("snowpile") then
            if  v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                SpawnPrefab("splash_snow_fx").Transform:SetPosition(v.Transform:GetWorldPosition())
            end
            v:Remove()
        end
    end
end

local function magma_projectile_fn()
    local inst = projectilefn()

    if not TheWorld.ismastersim then
        return inst
    end

    local _OnLaunchFn = inst.components.complexprojectile.onlaunchfn
    local function OnLaunchFn(inst)
        _OnLaunchFn(inst)
        inst.Physics:SetCollisionCallback(OnCollideMagma)
    end

    inst.components.complexprojectile:SetOnLaunch(OnLaunchFn)
    inst.components.complexprojectile:SetOnHit(OnHitMagma)

    return inst
end

local function magma_sludge_fn()
    local inst = slobberfn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS

    inst:AddComponent("heater")
    inst.components.heater.heat = 500    
    inst._melttask = inst:DoPeriodicTask(1, DoAreaEffectMeltSnowPiles)


    if inst._spoiltask then inst._spoiltask:Cancel() end
    inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaEffectMagma, inst.components.aura.tickperiod * .5)

    return inst
end

local function slime_projectile_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    -- inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(0.02, 0.02)

    -- Ewecus animations
    inst.AnimState:SetBank("spat_bomb")
    inst.AnimState:SetBuild("snapalm_bomb")
    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetCollisionCallback(OnCollideSlime)
    
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-20)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
    -- inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitSlime)
    inst.components.complexprojectile.usehigharc = false

    inst:AddComponent("locomotor")

    inst.persists = false

    return inst
end

local function slime_sludge_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("spat_splat")
    inst.AnimState:SetBuild("snapalm_splat")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("aura")
    inst.components.aura.radius = 2
    inst.components.aura.tickperiod = 0.6
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)
    
    inst:AddComponent("heater")
    inst.components.heater.heat = 250

    inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaEffectSlime, inst.components.aura.tickperiod * .5)

    inst.removetask = inst:DoTaskInTime(TUNING.SNAILDRAKE_SLIME_SLUDGE_DURATION, inst.Remove)

    return inst
end

return Prefab("um_lavaspit", fn, assets),
    Prefab("um_lavaspit_slobber", slobberfn, assets),
    Prefab("um_lavaspit_sludge", slobberfn, assets), --because FOR SOME REASON I can't use SetPrefabNameOverride...
    Prefab("um_lavaspit_projectile", projectilefn),
    Prefab("um_lavaspit_target", projectiletargetfn),
    Prefab("um_snaildrake_magma_projectile", magma_projectile_fn),
    Prefab("um_snaildrake_magma_sludge", magma_sludge_fn, snaildrake_projectile_assets),
    Prefab("um_snaildrake_slime_projectile", slime_projectile_fn),
    Prefab("um_snaildrake_slime_sludge", slime_sludge_fn, snaildrake_projectile_assets)
local assets =
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

local AURA_EXCLUDE_TAGS = { "playerghost", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO",
    "notarget", "noattack", "flight", "flying", "dragonfly", "lavae", "invisible", "snaildrake" }

-- Apply AoE slow and damage to a target.
local function TrySlowdownMagma(inst, target)
    local debuffkey = inst.prefab
    if target.components.locomotor then
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

    if (target.components.combat and target.components.health and
        not target:HasOneOfTags({"dragonfly", "lavae", "snaildrake"}) and target.components.burnable
    ) then
        target.components.health:DoFireDamage(TUNING.SNAILDRAKE_SLUDGE_DAMAGE, inst.lobber, true)
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
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, AURA_EXCLUDE_TAGS)
    for i, v in ipairs(ents) do
        if v.components ~= nil and v.components.locomotor ~= nil then
            TrySlowdownMagma(inst, v)
        end
    end

    local walls = TheSim:FindEntities(x, y, z, inst.components.aura.radius, { "wall" }, { "INLIMBO", "_inventoryitem" })

    for i, v in ipairs(walls) do
        if v.components ~= nil then
            TrySlowdownMagma(inst, v)
        end
    end
end

-- Spawn a magma puddle when the projectile hits the ground.
local function OnHitMagma(inst, attacker, target)
    if inst.nomorespawns == nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local sludge = SpawnPrefab("snaildrake_magma_sludge")

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
        local sludge = SpawnPrefab("snaildrake_slime_sludge")
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
    local inst = Prefabs.lavaspit_projectile.fn()

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
    local inst = Prefabs.lavaspit_sludge.fn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
	
    inst:AddComponent("heater")
    inst.components.heater.heat = 500	
	inst._melttask = inst:DoPeriodicTask(1, DoAreaEffectMeltSnowPiles)
	
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
    inst.components.aura.radius = 3
    inst.components.aura.tickperiod = 0.6
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)
	


    inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaEffectSlime, inst.components.aura.tickperiod * .5)

	
    inst:DoTaskInTime(TUNING.SNAILDRAKE_SLIME_SLUDGE_DURATION, inst.Remove)

    return inst
end

return Prefab("snaildrake_magma_projectile", magma_projectile_fn),
    Prefab("snaildrake_magma_sludge", magma_sludge_fn, assets),
    Prefab("snaildrake_slime_projectile", slime_projectile_fn),
    Prefab("snaildrake_slime_sludge", slime_sludge_fn, assets)

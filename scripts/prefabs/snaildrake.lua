local assets =
{
    Asset("ANIM", "anim/snaildrake_spikeshell.zip"),
    Asset("ANIM", "anim/snaildrake_holeshell.zip"),
    Asset("SOUND", "sound/slurtle.fsb"),
}

local prefabs =
{
    "snapalm",
    "slurtle_shellpieces",
    "armorsnurtleshell",
    "lavaspit_projectile",
}

TUNING.SNAILDRAKE_MAX_CHASEAWAY_DIST = 40
TUNING.SNAILDRAKE_SHARE_TARGET_DIST = 40
TUNING.SNAILDRAKE_SPAWN_SNAPALM_VALUE = 6
TUNING.SNAILDRAKE_DAMAGE = 25
TUNING.SNAILDRAKE_HEALTH = 1200
TUNING.SNAILDRAKE_ATTACK_PERIOD = 4
TUNING.SNAILDRAKE_ATTACK_DIST = 2.5
TUNING.SNAILDRAKE_WALK_SPEED = 3
TUNING.SNAILDRAKE_MAX_SHIELD_DURATION = 6
TUNING.SNAILDRAKE_AGGRO_DIST = 4
TUNING.SNAILDRAKE_BURN_TIME = 4
TUNING.SNAILDRAKE_RANGED_ATTACK_CD = 15

local easing = require("easing")

SetSharedLootTable('snaildrake_slime',
{
    {'snapalm',      1.0},
    {'snapalm',      1.0},
    {'snaildrakebucket', 0.5},
})
SetSharedLootTable('snaildrake_magma',
{
    {'snapalm',      1.0},
    {'snapalm',      1.0},
    {'snaildrakehat', 0.50},
})

local snaildrake_brain = require("brains/snaildrakebrain")

-- Snaildrakes are aggressive and will attack anything that gets too close.
local function RetargetFn(inst)
    if inst.components.combat:HasTarget() then
        return
    end

    local new_target = FindEntity(inst, TUNING.SNAILDRAKE_AGGRO_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, {"snaildrake"})

    if new_target then
        inst.components.combat:SuggestTarget(new_target)
    end
end

-- Snaildrakes will not chase players too far away from their home.
local function KeepTarget(inst, target)
    if not target:IsValid() then
        return false
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and target:GetDistanceSqToPoint(homePos) < TUNING.SNAILDRAKE_MAX_CHASEAWAY_DIST * TUNING.SNAILDRAKE_MAX_CHASEAWAY_DIST
end

-- Herd mentality. Share target with duo partner when attacked.
local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    inst.components.combat:SetTarget(attacker)
    if inst.partner then
        inst.components.combat:ShareTarget(attacker, TUNING.SNAILDRAKE_SHARE_TARGET_DIST, function(ent)
        return ent == inst.partner
        end, 1)
    end
end

-- Kaboom!
local function DoExplosion(inst)
    local explosion = SpawnPrefab("um_snaildrake_explosion")
    explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
    explosion.snaildrake = inst
end

-- Lobs a fiery spit at the enemy.
local function DoRangedAttack(inst, target)
    -- Attempt to find a target.
    if not target then
        target = inst.components.combat:HasTarget() and inst.components.combat.target or nil
    end
    -- Still no target; cancel the attack.
    if not target then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local targetpos = target:GetPosition()
    inst:ForceFacePoint(targetpos)
    
    local angle = math.rad(inst:GetAngleToPoint(targetpos))
    local offset_dist = 1
    local offset_x = offset_dist * math.cos(angle)
    local offset_z = offset_dist * -math.sin(angle)

    local projectile = SpawnPrefab(inst.projectile_prefab)
    projectile.coolingtime = 15
    projectile.Transform:SetPosition(x + offset_x, y + 0.5, z + offset_z)
    projectile.lobber = inst
    -- projectile.LaunchMoreSpit = true
    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.
    local dx = targetpos.x - x
    local dz = targetpos.z - z

    local rangesq = dx * dx + dz * dz
    local maxrange = TUNING.SNAILDRAKE_RANGED_ATTACK_MAX_RANGE
    local speed = easing.linear(rangesq, maxrange, 5, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    -- projectile.components.complexprojectile:SetGravity(-35)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    -- projectile.components.complexprojectile:SetLaunchOffset(Vector3(0, 1.5, 0))

    -- If the target is itself, then the Snaildrake is belching
    -- and the ranged attack should not go on cd.
    if target ~= inst then
        inst.components.timer:StartTimer("rangedattack_cd", TUNING.SNAILDRAKE_RANGED_ATTACK_CD)
    end
end

-- Plays a rattle sound when set on fire.
local function OnIgniteFn(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/rattle", "rattle")
end

-- Force Snaildrakes to exit their shells after they stop burning.
-- They won't normally do this for some reason (Slurtles don't have
-- this problem because they just unalive after exploding).
local function OnExtinguishFn(inst)
    inst.SoundEmitter:KillSound("rattle")
    if inst.sg.currentstate.name == "shield" then
        inst:PushEvent("exitshield")
    end
end

-- Force Snaildrakes out of their shells after some time.
local function OnEnterShield(inst)
    inst:DoTaskInTime(TUNING.SNAILDRAKE_MAX_SHIELD_DURATION, function(inst)
        if inst.sg.currentstate.name == "shield" then
            inst:PushEvent("exitshield")
        end
    end)
end

-- When Snaildrakes are set on fire, they will spawn an explosion.
-- Snaildrakes should not be harmed by their own explosions.
local function CanDodgeFn(inst, attacker)
    return attacker and attacker.snaildrake and attacker.snaildrake == inst
end

-- Snaildrakes will eat minerals off the ground.
local function OnEatElement(inst, food)
    local value = food.components.edible.hungervalue
    inst.stomach = inst.stomach + value
    if inst.stomach >= TUNING.SNAILDRAKE_SPAWN_SNAPALM_VALUE then
        local stacksize = 0
        while inst.stomach >= TUNING.SNAILDRAKE_SPAWN_SNAPALM_VALUE do
            inst.stomach = inst.stomach - TUNING.SNAILDRAKE_SPAWN_SNAPALM_VALUE
            stacksize = stacksize + 1
        end
        return stacksize
    end
    return 0
end

-- Allows Magma Snaildrakes to ignite targets that have been
-- slimed by Slime Snaildrakes.
local function OnHitOtherMagma(inst, other)
    other:PushEvent("firedamage")
end

-- Magma Snaildrakes will belch out magma when they digest minerals.
local function OnEatElementMagma(inst, food)
    local should_belch = OnEatElement(inst, food) > 0 and true or false
    if should_belch then
        DoRangedAttack(inst, inst)
    end
end

-- Slime Snaildrakes will digest minerals and produce Snaplam like Slurtles produce Slurtle Slime.
local function OnEatElementSlime(inst, food)
    local stacksize = OnEatElement(inst, food)
    if stacksize > 0 then
        local snaplam = SpawnPrefab("snapalm")
        snaplam.Transform:SetPosition(inst.Transform:GetWorldPosition())
        snaplam.components.stackable:SetStackSize(stacksize)
    end
end

-- Play a shatter SFX if they do not drop their shells.
local function OnNotChanceLoot(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/shatter")
end

-- Snaildrakes are territorial. They should remember where their home is
-- and return to this location if they chase the player too far.
local function SetHomeLocation(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

-- Try to spawn Snapalm when haunted.
local function CustomOnHaunt(inst)
    inst.components.periodicspawner:TrySpawn()
    return true
end

local function common_fn(bank, build, tag)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2, 1.5)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.2,1.2,1.2)

    MakeCharacterPhysics(inst, 50, .5)

    inst:AddTag("animal")
    inst:AddTag("snaildrake")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.SNAILDRAKE_WALK_SPEED

    inst:SetStateGraph("SGsnaildrake")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.ELEMENTAL }, { FOODTYPE.ELEMENTAL })

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable(tag)
    inst.components.lootdropper:AddIfNotChanceLoot("slurtle_shellpieces")

    inst:AddComponent("inspectable")
    -- Snaildrakes are territorial
    inst:AddComponent("knownlocations")

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "shell"
    inst.components.combat:SetRetargetFunction(3, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(TUNING.SNAILDRAKE_ATTACK_DIST)
    inst.components.combat:SetDefaultDamage(TUNING.SNAILDRAKE_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.SNAILDRAKE_ATTACK_PERIOD)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(450)
    inst.components.health.um_fireimmune = true
    inst.components.health.fire_damage_scale = 0
    
    inst:AddComponent("attackdodger")
    inst.components.attackdodger:SetCanDodgeFn(CanDodgeFn)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("snapalm")
    inst.components.periodicspawner:SetRandomTimes(40, 60)
    inst.components.periodicspawner:SetDensityInRange(20, 2)
    inst.components.periodicspawner:SetMinimumSpacing(8)
    inst.components.periodicspawner:Start()

    inst:AddComponent("timer")

    inst:AddComponent("inventory")

    inst:SetBrain(snaildrake_brain)
    inst:DoTaskInTime(0, SetHomeLocation)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("ifnotchanceloot", OnNotChanceLoot)

    inst:ListenForEvent("entershield", OnEnterShield)
    
    inst:AddComponent("explosiveresist")
    inst.components.explosiveresist:SetResistance(1)
    inst.components.explosiveresist.decaytime = 9999
    
    MakeMediumFreezableCharacter(inst, "shell")
    MakeMediumBurnableCharacter(inst, "shell")
    inst.components.burnable:SetOnIgniteFn(OnIgniteFn)
    inst.components.burnable:SetOnExtinguishFn(OnExtinguishFn)
    inst.components.burnable:SetBurnTime(TUNING.SNAILDRAKE_BURN_TIME) -- 4; default is 8

    inst:AddComponent("heater")
    inst.components.heater.heat = 100

    MakeHauntablePanic(inst)
    AddHauntableCustomReaction(inst, CustomOnHaunt, true, false, true)

    inst.lastmeal = 0
    inst.stomach = 0
    inst.partner = nil
    inst.DoExplosion = DoExplosion
    inst.DoRangedAttack = DoRangedAttack

    return inst
end

-- Magma Snaildrakes
local function magma_fn()
    local inst = common_fn("snurtle", "slurtle_snaily", "snaildrake_magma")

    if not TheWorld.ismastersim then
        return inst
    end
    inst.AnimState:SetBank("snaildrake_spikeshell")
    inst.AnimState:SetBuild("snaildrake_spikeshell")
    inst.components.combat.onhitotherfn = OnHitOtherMagma

    inst.components.eater:SetOnEatFn(OnEatElementMagma)

    inst.projectile_prefab = "um_snaildrake_magma_projectile"

    return inst
end

-- Slime Snaildrakes
local function slime_fn()
    local inst = common_fn("snurtle", "slurtle_snaily", "snaildrake_slime")


    if not TheWorld.ismastersim then
        return inst
    end
    inst.AnimState:SetBank("snaildrake_holeshell")
    inst.AnimState:SetBuild("snaildrake_holeshell")
    inst.components.eater:SetOnEatFn(OnEatElementSlime)

    inst.projectile_prefab = "um_snaildrake_slime_projectile"

    return inst
end

return Prefab("snaildrake_magma", magma_fn, assets, prefabs),
    Prefab("snaildrake_slime", slime_fn, assets, prefabs)

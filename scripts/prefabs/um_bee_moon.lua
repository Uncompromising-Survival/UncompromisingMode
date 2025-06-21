local beecommon = require "brains/beecommon"

local assets =
{
    Asset("ANIM", "anim/um_bee_moon.zip"),
}

local workersounds =
{
    takeoff = "dontstarve/bee/bee_takeoff",
    attack = "dontstarve/bee/bee_attack",
    buzz = "dontstarve/bee/bee_fly_LP",
    hit = "dontstarve/bee/bee_hurt",
    death = "dontstarve/bee/bee_death",
}

local killersounds =
{
    takeoff = "dontstarve/bee/killerbee_takeoff",
    attack = "dontstarve/bee/killerbee_attack",
    buzz = "dontstarve/bee/killerbee_fly_LP",
    hit = "dontstarve/bee/killerbee_hurt",
    death = "dontstarve/bee/killerbee_death",
}

local function bonus_damage_via_allergy(inst, target, damage, weapon)
    return (target:HasTag("allergictobees") and TUNING.BEE_ALLERGY_EXTRADAMAGE) or 0
end

local function OnDropped(inst)
    if inst.buzzing and not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
    inst.sg:GoToState("catchbreath")
    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.brain ~= nil then
        inst.brain:Start()
    end
    if inst.sg ~= nil then
        inst.sg:Start()
    end
    if inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
        local x, y, z = inst.Transform:GetWorldPosition()
        while inst.components.stackable:IsStack() do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(x, y, z)
            end
        end
    end
end

local function OnPickedUp(inst)
    inst.sg:GoToState("idle")
    inst.SoundEmitter:KillSound("buzz")
    inst.SoundEmitter:KillAllSounds()
end

local function EnableBuzz(inst, enable)
    if enable then
        if not inst.buzzing then
            inst.buzzing = true
            if not (inst.components.inventoryitem:IsHeld() or inst:IsAsleep() or inst.SoundEmitter:PlayingSound("buzz")) then
                inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
            end
        end
    elseif inst.buzzing then
        inst.buzzing = false
        inst.SoundEmitter:KillSound("buzz")
    end
end

local function OnWake(inst)
    if inst.buzzing and not (inst.components.inventoryitem:IsHeld() or inst.SoundEmitter:PlayingSound("buzz")) then
        inst.SoundEmitter:PlaySound(inst.sounds.buzz, "buzz")
    end
end

local function OnSleep(inst)
    inst.SoundEmitter:KillSound("buzz")
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "insect", "INLIMBO", "plantkin" }
local RETARGET_ONEOF_TAGS = { "character", "animal", "monster" }
local function KillerRetarget(inst)
    return FindEntity(inst, 16,
        function(guy)
            return inst.components.combat:CanTarget(guy) and
                not (guy.components.skilltreeupdater and guy.components.skilltreeupdater:IsActivated("wormwood_bugs"))
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS,
        RETARGET_ONEOF_TAGS)
end

local function SpringBeeRetarget(inst)
    return TheWorld.state.isspring and
        FindEntity(inst, 4,
            function(guy)
                return inst.components.combat:CanTarget(guy) and
                    not (guy.components.skilltreeupdater and guy.components.skilltreeupdater:IsActivated("wormwood_bugs"))
            end,
			RETARGET_MUST_TAGS,
			RETARGET_CANT_TAGS,
			RETARGET_ONEOF_TAGS)
        or nil
end
local AREAATTACK_EXCLUDETAGS = { "spore", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "shadow", "brightmare", "moon_spore_protection","bee"}
local function Explode(inst)
	local spore = SpawnPrefab("spore_moon")
	spore:AddTag("bee")
	spore.Transform:SetPosition(inst.Transform:GetWorldPosition())
	spore.components.combat:SetDefaultDamage(75)
	spore.AnimState:PlayAnimation("explode")
    spore.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
    spore.components.combat:DoAreaAttack(inst, TUNING.MOONSPORE_ATTACK_RANGE, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
	spore:ListenForEvent("animover",function(inst) inst:Remove() end)
end

local function OnDeath(inst)
	inst:ListenForEvent("animover",Explode)
end

local killerbrain = require("brains/um_bee_moonbrain")

local RUN_AWAY_DIST = 10
local SEE_FLOWER_DIST = 10
local SEE_TARGET_DIST = 6

local MAX_CHASE_DIST = 7
local MAX_CHASE_TIME = 8
local MAX_WANDER_DIST = 32

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 10

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    inst.components.combat:SetTarget(attacker)
    local targetshares = MAX_TARGET_SHARES
    if inst.components.combat:HasTarget() then
        if inst.components.homeseeker and inst.components.homeseeker.home then
            local home = inst.components.homeseeker.home
            if home and home.components.childspawner then
                targetshares = targetshares - home.components.childspawner.childreninside
                home.components.childspawner:ReleaseAllChildren(attacker, "um_bee_moon")
            end
        end
    end
    local iscompanion = inst:HasTag("companion")
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
        if inst.components.homeseeker and dude.components.homeseeker then  --don't bring bees from other hives
            if dude.components.homeseeker.home and dude.components.homeseeker.home ~= inst.components.homeseeker.home then
                return false
            end
        end
        return dude:HasTag("bee") and (iscompanion == dude:HasTag("companion")) and not (dude:IsInLimbo() or (dude.components.health and dude.components.health:IsDead()) or dude:HasTag("epic"))
    end, targetshares)
end

local function OnWorked(inst, worker)
    inst:PushEvent("detachchild")

    if worker.components.inventory ~= nil then
        inst.SoundEmitter:KillAllSounds()

        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(.8, .5)
    inst.Transform:SetFourFaced()

    inst:AddTag("bee")
    inst:AddTag("insect")
    inst:AddTag("smallcreature")
    inst:AddTag("cattoyairborne")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")
	inst:AddTag("killer")
	inst:AddTag("scarytoprey")
    inst.AnimState:SetBank("um_bee_moon")
    inst.AnimState:SetBuild("um_bee_moon")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)

    MakeInventoryFloatable(inst)

    MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.runspeed = 8
	inst.components.locomotor.walkspeed = 8 
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst:SetStateGraph("SGbee")

    inst:AddComponent("stackable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem:SetOnDroppedFn(OnDropped) Done in MakeFeedableSmallLivestock
    -- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPickedUp)
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem.pushlandedevents = false

    ---------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("honey", 2)
    inst.components.lootdropper:AddRandomLoot("houndstooth", 1)
    inst.components.lootdropper.numrandomloot = 1

    ------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnWorked)

    MakeSmallBurnableCharacter(inst, "body", Vector3(0, -1, 1))
    MakeTinyFreezableCharacter(inst, "body", Vector3(0, -1, 1))

    ------------------

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat:SetRange(TUNING.BEE_ATTACK_RANGE)
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)
    inst.components.combat.bonusdamagefn = bonus_damage_via_allergy

    inst.components.health:SetMaxHealth(250)
    inst.components.combat:SetDefaultDamage(34)
    inst.components.combat:SetAttackPeriod(TUNING.BEE_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(2, KillerRetarget)
    
	
    ------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    ------------------

    inst:AddComponent("knownlocations")

    ------------------

    inst:AddComponent("inspectable")

    ------------------

    inst:AddComponent("tradable")

    inst:ListenForEvent("attacked", OnAttacked)

    MakeFeedableSmallLivestock(inst, TUNING.TOTAL_DAY_TIME*2, OnPickedUp, OnDropped)

	inst.sounds = killersounds
    inst.buzzing = true
    inst.EnableBuzz = EnableBuzz
    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep
	inst.incineratesound = inst.sounds.death
	inst:SetBrain(killerbrain)
	MakeHauntablePanic(inst)
	
	inst:ListenForEvent("death",OnDeath)
    return inst
end

return Prefab("um_bee_moon", fn, assets, prefabs)

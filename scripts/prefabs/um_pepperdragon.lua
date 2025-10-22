local brain = require "brains/um_pepperdragonbrain"

local assets =
{
    Asset("ANIM", "anim/um_pepperdragon.zip"),
}

local assetsbladder =
{
    Asset("ANIM", "anim/um_pepperdragon_bladder.zip"),
}

local loot = { "meat", "meat","meat","meat","um_pepperdragon_bladder" }
local MAX_CHASEAWAY_DIST = 32
local MAX_CHASE_DIST = 256

local RETARGET_MUST_TAGS = { "_combat", "_health", }
local RETARGET_PIG_MUST_TAGS = { "pig", "_combat", "_health" }
local RETARGET_CANT_TAGS = { "tallbird" }
local RETARGET_WEREPIG_CANT_TAGS = { "werepig" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }
local RETARGET_ANIMAL_ONEOF_TAGS = { "character", "animal", "monster" }
local function Retarget(inst)
    local function IsValidTarget1(guy) -- med temp
        return not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy) and guy.components.temperature and guy.components.temperature.current < 60
    end
    local function IsValidTarget2(guy) -- low temp
        return not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy) and guy.components.temperature and guy.components.temperature.current < 20
    end
    return FindEntity(inst, 12, IsValidTarget1, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
	or
	FindEntity(inst, 24, IsValidTarget2, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
	
end

local function KeepTarget(inst, target)
    return true
end

local function ShouldSleep(inst)
    return inst.components.timer:TimerExists("bellyfull") and inst.components.combat.target == nil and (inst.components.homeseeker and inst.components.home and inst:GetDistanceSqToInst(inst.components.homeseeker.home) < 1)
end

local function ShouldWake(inst)
    return not inst.components.timer:TimerExists("bellyfull") or inst.components.combat.target ~= nil
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        return
    end

    local current_target = inst.components.combat.target

    if current_target == data.attacker then
        --Already targeting our attacker, just update the time
        inst._last_attacker = current_target
        inst._last_attacked_time = GetTime()
        return
    end

    if current_target ~= nil then
        local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
        if home ~= nil and
            current_target == home.thief and
            home.components.pickable ~= nil and
            home.components.pickable:CanBePicked() then
            --Don't change target from our egg thief!
            return
        end

        local time = GetTime()
        if inst._last_attacker == current_target and
            inst._last_attacked_time + TUNING.TALLBIRD_ATTACK_AGGRO_TIMEOUT >= time then
            --Our target attacked us recently, stay on it!
            return
        end

        --Switch to new target
        inst.components.combat:SetTarget(data.attacker)
        inst._last_attacker = data.attacker
        inst._last_attacked_time = time

    elseif inst.components.combat:SuggestTarget(data.attacker) then
        inst._last_attacker = data.attacker
        inst._last_attacked_time = GetTime()
    end
end


local function OnEntitySleep(inst, data)
end

local function OnEntityWake(inst, data)
end

local function oneat(inst, food)
	-- Don't want to mangle the hunger component to do this. just use a simple counter instead.
	if food.prefab ~= "ice" then
		inst.bellyfullness = inst.bellyfullness + 2
	else -- ice less effective
		inst.bellyfullness =  inst.bellyfullness + 0.5
	end
	if inst.bellyfullness > 5 and not inst.components.timer:TimerExists("bellyfull") then
		inst.components.timer:StartTimer("bellyfull",60*inst.bellyfullness)
		inst.bellyfullness = 0 -- reset belly.
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 20, 1)

    inst.DynamicShadow:SetSize(2.75, 1)
    --inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.Transform:SetSixFaced()

    ----------
    inst:AddTag("tallbird")
    inst:AddTag("animal")
    inst:AddTag("largecreature")
	inst:AddTag("PyreToxinImmune")

    inst.AnimState:SetBank("um_pepperdragon")
    inst.AnimState:SetBuild("um_pepperdragon")
    inst.AnimState:PlayAnimation("idle1")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.override_combat_fx_height = "high"
    inst._last_attacker = nil
    inst._last_attacked_time = nil

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 3

    inst:SetStateGraph("SGum_pepperdragon")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(2000)
	inst.components.health.fire_damage_scale = 0 
    ------------------

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetDefaultDamage(75)
    inst.components.combat:SetAttackPeriod(TUNING.TALLBIRD_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(3)


    MakeLargeFreezableCharacter(inst, "body")
    MakeHauntablePanic(inst)


    -- inst:AddComponent("eater")
    -- inst.components.eater:SetDiet({ FOODTYPE.COLDFOOD }, { FOODTYPE.COLDFOOD })
	-- inst.components.eater:SetOnEatFn(oneat)
	
	-- I don't want to make an entire foodtype just for cold foods, we're doing a hacky workaround. Why? Because the items may already have a primary or secondary foodtype
	inst.OnEatHack = oneat
    ------------------
    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------

    inst:AddComponent("inspectable")
	
	inst:AddComponent("knownlocations")
    ------------------


    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)
	
	inst:AddComponent("timer")
	inst.tolerance = 0 -- for the pounce counterattack
	inst.flamecount = 0 -- how many times he barfs fire in the loop
	inst.bellyfullness = 0 -- how many times he has to eat before he's ready for a nap
	
	
	inst.Transform:SetScale(1.5,1.5,1.5)
    return inst
end

local function fnbladder()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_pepperdragon_bladder")
    inst.AnimState:SetBuild("um_pepperdragon_bladder")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    return inst
end


return Prefab("um_pepperdragon", fn, assets, prefabs),
Prefab("um_pepperdragon_bladder",fnbladder,assetsbladder)
local assets =
{
    Asset("ANIM", "anim/stagehand.zip"),
    Asset("ANIM", "anim/stagehand_sts.zip"),
}

local armassets =
{
    Asset("ANIM", "anim/stagehand_sts_arm.zip"),
}

local prefabs = {
    "um_haunt_attackarm",
    "um_haunt_attackhand",
}

local sounds =
{
    attack = "UCSounds/um_haunt/hawk",
    attack_grunt = "UCSounds/um_haunt/spit",
    death = "UCSounds/um_haunt/death",
    idle = "dontstarve/sanity/creature1/idle",
    taunt = "UCSounds/um_haunt/taunt",
    appear = "UCSounds/um_haunt/appear",
    disappear = "UCSounds/um_haunt/attacked",
}
--------------------------------------------------------------------------------
local function usher_onworked(inst, worker)
    inst.components.combat:SuggestTarget(worker)
end

--------------------------------------------------------------------------------
local function usher_keep_target(inst, target)
    return inst.components.combat:CanTarget(target)
        and inst:IsNear(target, 2*TUNING.STAGEUSHER_ATTACK_RANGE)
end

--------------------------------------------------------------------------------
local function StartAttackingTarget(inst, target)
    if target == nil or not target:IsValid() then
        return false
    end

    local ipos = inst:GetPosition()
    local tpos = target:GetPosition()
    local unit_target_vec = (tpos - ipos):GetNormalized()

    local attack_hand = SpawnPrefab("um_haunt_attackhand")
    attack_hand.Transform:SetPosition((ipos + unit_target_vec*0.5):Get())
    attack_hand:SetOwner(inst)
    attack_hand:SetCreepTarget(target)

    if inst._on_hand_removed == nil then
        inst._on_hand_removed = function(hand) inst:PushEvent("handfinished") end
    end
    inst:ListenForEvent("onremove", inst._on_hand_removed, attack_hand)

    return true
end

local function ChangeVisibility(inst)
	local closest_player, distsq = inst:GetNearestPlayer()
		
	if closest_player ~= nil and distsq ~= nil then
		print("Haunt Visibility "..(1 - (distsq / 100)))
		inst.AnimState:SetMultColour(0, 0, 0, 1 - (distsq / 100))
		
		if (1 - (distsq / 100)) >= 0.8 then
			inst.queue_disappear = true
		end
	else
		inst.AnimState:SetMultColour(0, 0, 0, 0)
	end
end
		
--------------------------------------------------------------------------------=
local USHER_PATHCAPS = { ignorecreep = true }
local FIRE_OFFSET = Vector3(0, 0, 0)
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("um_haunt")
    inst.AnimState:SetBuild("um_haunt")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetMultColour(0, 0, 0, 0)
	inst.AnimState:UsePointFiltering(true)

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("notarget")
    inst:AddTag("notraptrigger")
    inst:AddTag("stageusher")
    inst:AddTag("NOCLICK")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.sounds = sounds
    inst.disappear_count = 0
    inst.haunt_target = nil

    ----------------------------------------------------------------------------
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.STAGEUSHER_ATTACK_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.STAGEUSHER_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.STAGEUSHER_ATTACK_RANGE)
    inst.components.combat:SetKeepTargetFunction(usher_keep_target)
    --inst.components.combat.playerdamagepercent = maybe
    inst.components.combat.ignorehitrange = true
    inst.components.combat.canattack = false
	
    inst:SetStateGraph("SGum_haunt")

    ----------------------------------------------------------------------------
    inst.StartAttackingTarget = StartAttackingTarget
	
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(ChangeVisibility)

    return inst
end

------------------------------------------------------------------------------------------------------------------------
local NUM_ARM_LOOPS = 3
local function create_shadow_arm(inst, ipos, tpos)
    local arm = SpawnPrefab("um_haunt_attackarm")
    arm.Transform:SetPosition(ipos:Get())
    arm:FacePoint(tpos:Get())

    inst._arm_anim = (inst._arm_anim or 0) + 1
    if inst._arm_anim > NUM_ARM_LOOPS then
        inst._arm_anim = 1
    end
    arm.AnimState:PlayAnimation("arm_loop"..tostring(inst._arm_anim), true)

    arm.components.stretcher:SetStretchTarget(inst)
    arm:ListenForEvent("onremove", function() arm:Remove() end, inst)

    if inst._arms == nil then
        inst._arms = {}
    end
    table.insert(inst._arms, arm)

    return arm
end

--------------------------------------------------------------------------------
local on_reached_destination = nil

--------------------------------------------------------------------------------
local function new_creep(inst, ipos, tpos)
    inst:FacePoint(tpos:Get())
    inst:DoTaskInTime(TUNING.STAGEUSHER_ATTACK_STEPTIME, on_reached_destination)
end

local function start_new_creep(inst)
    if inst._target == nil then
        return false
    end

    --------------------------------
    if inst._arms ~= nil then
        inst._arms[#inst._arms].components.stretcher:SetStretchTarget(nil)
    end

    --------------------------------
    local ipos = inst:GetPosition()
    local tpos = inst._target:GetPosition()

    create_shadow_arm(inst, ipos, tpos)
    new_creep(inst, ipos, tpos)

    return true
end

--------------------------------------------------------------------------------
local function on_grab_anim_over(inst)
    inst:RemoveEventCallback("animover", on_grab_anim_over)

    -- Play some animations to indicate we're going away.
    if inst._arms ~= nil then
        for _, arm in ipairs(inst._arms) do
            arm.AnimState:PlayAnimation("arm_scare"..tostring(math.random(1,4)))
        end
    end
    inst.AnimState:PlayAnimation("hand_scare")

    inst.SoundEmitter:KillSound("creeping")
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")

    inst:ListenForEvent("animover", inst.Remove)
end

local function hand_dissipate(inst)
    if inst._is_dissipating then
        return
    else
        inst._is_dissipating = true
		
		if inst._owner ~= nil then
			inst._owner.stop_haunting = true
		end
    end

    -- Stop the hand from moving any more while it plays its fadeout.
    inst.Physics:Stop()

    if inst.components.updatelooper ~= nil then
        inst:RemoveComponent("updatelooper")
    end

    inst.AnimState:PlayAnimation("grab")
    inst:ListenForEvent("animover", on_grab_anim_over)
end

on_reached_destination = function(inst)
    local creep_succeeded = false
    inst._destination_steps = (inst._destination_steps or TUNING.STAGEUSHER_ATTACK_STEPS) - 1
    if inst._destination_steps > 0 then
        creep_succeeded = start_new_creep(inst)
    end

    if not creep_succeeded then
        hand_dissipate(inst)
    end
end

--------------------------------------------------------------------------------
local function SetOwner(inst, owner)
    inst._owner = owner
    inst:ListenForEvent("onremove", inst._on_owner_removed, owner)
end

--------------------------------------------------------------------------------
local ARM_ATTACK_TEST_RATE = 4*FRAMES
local ARM_TARGETS_MUST = {"_combat"}

-- If we're targetting a player, we can hit players. If not, we can't.
local ARM_TARGETS_CANT = {"NOCLICK", "DECOR", "FX", "NOTARGET", "flying", "ghost", "playerghost", "stageusher"}
local ARM_TARGETS_CANT_WITHPLAYER = {"NOCLICK", "DECOR", "FX", "NOTARGET", "flying", "ghost", "playerghost", "stageusher", "player"}
local function test_for_damage_targets(inst, dt)
    inst._attack_time = inst._attack_time + dt
    if inst._attack_time < ARM_ATTACK_TEST_RATE then
        return
    else
        inst._attack_time = inst._attack_time - ARM_ATTACK_TEST_RATE
    end

    if inst._target == nil then
        return
    end

    inst._last_hits = inst._last_hits or {}
    local current_time = GetTime()

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local potential_hits = TheSim:FindEntities(
        ix, iy, iz,
        TUNING.STAGEUSHER_ATTACK_DAMAGERADIUS,
        ARM_TARGETS_MUST,
        (inst._target:HasTag("player") and ARM_TARGETS_CANT) or ARM_TARGETS_CANT_WITHPLAYER
    )
    for _, potential_hit in ipairs(potential_hits) do
        local last_hit_time = inst._last_hits[potential_hit]
        if last_hit_time == nil or (last_hit_time + TUNING.STAGEUSHER_ATTACK_STEPTIME) < current_time then
            inst._last_hits[potential_hit] = current_time

            if inst._owner ~= nil then
                -- NOTE: we are assuming that our owner has combat.ignorehitrange set already
                inst._owner.components.combat:DoAttack(potential_hit)
            else
                potential_hit.components.combat:GetAttacked(inst, TUNING.STAGEUSHER_ATTACK_DAMAGE)
            end
        end
    end
end

local function SetCreepTarget(inst, target)
    inst._target = target
    inst:ListenForEvent("onremove", inst._on_target_removed, target)

    ---------------------------------------
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(test_for_damage_targets)

    ---------------------------------------
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_creep", "creeping")

    ---------------------------------------
    -- We don't want the hand to slow down, so we just set the physics velocity once,
    -- and let it run straight until the end.
    inst.Physics:SetMotorVel(TUNING.STAGEUSHER_ATTACK_SPEED / 2, 0, 0)

    ---------------------------------------
    local ipos = inst:GetPosition()
    local tpos = target:GetPosition()

    create_shadow_arm(inst, ipos, tpos)
    new_creep(inst, ipos, tpos)
end

--------------------------------------------------------------------------------
local HAND_PATHCAPS = { ignorecreep = true }
local function handfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 8, .5)
    RemovePhysicsColliders(inst)

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("NOCLICK")
    inst:AddTag("shadowhand")

    inst.AnimState:SetBank("stagehand_sts_arm")
    inst.AnimState:SetBuild("stagehand_sts_arm")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("hand_in")
    inst.AnimState:PushAnimation("hand_in_loop", true)
	inst.AnimState:SetMultColour(0, 0, 0, .5)
	inst.AnimState:UsePointFiltering(true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    ------------------------------
    inst._on_owner_removed = function(owner)
        inst:Remove()
    end
    inst._on_target_removed = function(target)
        inst._target = nil
        if inst.components.updatelooper ~= nil then
            inst:RemoveComponent("updatelooper")
        end
    end

    ------------------------------
    inst._attack_time = 0
    --inst._target = nil
    inst.SetOwner = SetOwner
    inst.SetCreepTarget = SetCreepTarget

    inst.persists = false

    return inst
end

------------------------------------------------------------------------------------------------------------------------
local function armfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("stagehand_sts_arm")
    inst.AnimState:SetBuild("stagehand_sts_arm")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
	inst.AnimState:SetMultColour(0, 0, 0, .5)
	inst.AnimState:UsePointFiltering(true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    ------------------------------
    inst:AddComponent("stretcher")
    inst.components.stretcher:SetRestingLength(2.5)
    inst.components.stretcher:SetWidthRatio(0.1)

    ------------------------------
    inst.persists = false

    return inst
end

return Prefab("um_haunt", fn, assets, prefabs),
    Prefab("um_haunt_attackhand", handfn, armassets),
    Prefab("um_haunt_attackarm", armfn, armassets)

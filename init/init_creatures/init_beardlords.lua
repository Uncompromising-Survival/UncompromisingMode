local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

_G.UM_BEARDLORDS = {}
UM_BEARDLORDS.AnimStates = {}

local _PlayAnimation = AnimState.PlayAnimation
function AnimState:PlayAnimation(anim, loop, ...)
    local inst = UM_BEARDLORDS.AnimStates and UM_BEARDLORDS.AnimStates[self]
    if inst then
        local beardlord_overrides = inst.um_beardlord_overrides
        if beardlord_overrides then anim, loop = beardlord_overrides.anim, beardlord_overrides.loop end
    end
    return _PlayAnimation(self, anim, loop, ...)
end

local _PushAnimation = AnimState.PushAnimation
function AnimState:PushAnimation(anim, loop, ...)
    local inst = UM_BEARDLORDS.AnimStates and UM_BEARDLORDS.AnimStates[self]
    if inst then
        local beardlord_overrides = inst.um_beardlord_overrides
        if beardlord_overrides then
            if beardlord_overrides.blockpush then
                inst.um_beardlord_overrides = nil
                inst.AnimState:PlayAnimation(beardlord_overrides.anim, beardlord_overrides.loop)
                return
            end
            anim, loop = beardlord_overrides.anim, beardlord_overrides.loop
        end
    end
    return _PushAnimation(self, anim, loop, ...)
end

--[[local _SetClientsideBuildOverride = AnimState.SetClientsideBuildOverride
function AnimState:SetClientsideBuildOverride(flag, default_build, build_to_swap, ...)
    if flag == "insane" and default_build == "manrabbit_build" and build_to_swap == "manrabbit_beard_build" then return end
    return _SetClientsideBuildOverride(self, flag, default_build, build_to_swap, ...)
end]]

local _PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(sound, ...)
    local inst = self:GetEntity()
    if inst then
        local beardlord_overrides = inst.um_beardlord_overrides
        if beardlord_overrides then
            if beardlord_overrides.blocksound and sound == beardlord_overrides.blocksound then return end
            sound = beardlord_overrides.sound
        end
    end
    return _PlaySound(self, sound, ...)
end

local BunnymanBrain = require("brains/bunnymanbrain")
local hunterparams_scarer = UpvalueHacker.GetUpvalue(BunnymanBrain.OnStart, "hunterparams_scarer")
if hunterparams_scarer then
    local _ShouldRunAway = hunterparams_scarer.fn
    local function ShouldRunAway(hunter, inst, ...)
        if inst.beardlord then return end
        return not _ShouldRunAway or _ShouldRunAway(hunter, inst, ...)
    end
    hunterparams_scarer.fn = ShouldRunAway
end

local function FindAndReplaceNode(self)
    for id, node in pairs(self.bt.root.children) do
        if node.name == "Parallel" and node.children then
            for _, node2 in pairs(node.children) do
                if node2.name == "PanicScared" then
                    self.bt.root.children[id] = WhileNode(function() return not self.inst.beardlord end, "ShouldPanicWhenScared", node)
                    return
                end
            end
        end
    end
    if hunterparams_scarer then
        for id, node in pairs(self.bt.root.children) do
            if node.name == "ChattyNode" and node.children then
                for _, node2 in pairs(node.children) do
                    if node2.hunterseeequipped == hunterparams_scarer.hunterseeequipped then
                        self.bt.root.children[id] = WhileNode(function() return not self.inst.beardlord end, "ShouldRunAwayFromScarer", node)
                        return
                    end
                end
            end
        end
    end
end

env.AddBrainPostInit("bunnymanbrain", function(self)
    FindAndReplaceNode(self)
end)

env.AddStategraphPostInit("bunnyman", function(inst)
    local events = {
        EventHandler("um_transform", function(inst, data)
            if not (inst.components.health and inst.components.health:IsDead()) and data then
                if not inst.sg:HasStateTag("busy") and not data.nostate then
                    inst.sg:GoToState("um_transform", data)
                    return
                end
                if inst.UMToggleBeardlord then inst:UMToggleBeardlord({toggle = data.toggle}) end
            end
        end),
    }

    local idlestate = inst.states["idle"]
    local funnyidlestate = inst.states["funnyidle"]
    local attackstate = inst.states["attack"]
    local walk_startstate = inst.states["walk_start"]
    local walk_stopstate = inst.states["walk_stop"]
    local run_startstate = inst.states["run_start"]
    local run_stopstate = inst.states["run_stop"]

    if idlestate then
        local idlestate_onenter = idlestate.onenter
        idlestate.onenter = function(inst, pushanim, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_idle_loop"} end
            local ret = idlestate_onenter(inst, pushanim, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
        table.insert(idlestate.timeline, TimeEvent(0 * FRAMES, function(inst) if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/wererabbit_breathin") end end))
        table.insert(idlestate.timeline, TimeEvent(15 * FRAMES, function(inst) if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/wererabbit_idle") end end))
        table.sort(idlestate.timeline, function(a, b) return a.time < b.time end)
    end

    if funnyidlestate then
        local funnyidlestate_onenter = funnyidlestate.onenter
        funnyidlestate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_taunt", sound = "dontstarve/creatures/bunnyman/wererabbit_taunt"} end
            local ret = funnyidlestate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end
    
    if attackstate then
        local attackstate_onenter = attackstate.onenter
        attackstate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_atk", sound = "dontstarve/creatures/bunnyman/wererabbit_attack"} end
            local ret = attackstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local attackstate_timeline1 = attackstate.timeline[1]
        if attackstate_timeline1 then
            local attackstate_timeline1_fn = attackstate_timeline1.fn
            attackstate_timeline1.fn = function(inst, ...)
                if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {blocksound = "dontstarve/creatures/bunnyman/bite"} end
                local ret = attackstate_timeline1_fn(inst, ...)
                if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
                return ret
            end
        end

        local attackstate_events_animover = attackstate.events["animover"]
        if attackstate_events_animover then
            local attackstate_events_animover_fn = attackstate_events_animover.fn
            attackstate_events_animover.fn = function(inst, ...)
                if not inst.AnimState:AnimDone() then return end -- Fixes an issue where Bunnyman can have their attack cancelled suddenly.
                return attackstate_events_animover_fn(inst, ...)
            end
        end
    end

    if walk_startstate then
        local walk_startstate_onenter = walk_startstate.onenter
        walk_startstate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_walk_pre"} end
            local ret = walk_startstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local walk_startstate_events_animover = walk_startstate.events["animover"]
        if walk_startstate_events_animover then
            local walk_startstate_events_animover_fn = walk_startstate_events_animover.fn
            walk_startstate_events_animover.fn = function(inst, ...)
                if inst.UMIsBeardlord and inst:UMIsBeardlord(true) and inst.AnimState:AnimDone() then
                    inst.sg:GoToState("um_beard_walk")
                    return
                end
                return walk_startstate_events_animover_fn(inst, ...)
            end
        end
    end

    if walk_stopstate then
        local walk_stopstate_onenter = walk_stopstate.onenter
        walk_stopstate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_walk_pst", blockpush = true} end
            local ret = walk_stopstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end

    if run_startstate then
        local run_startstate_onenter = run_startstate.onenter
        run_startstate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_run_pre"} end
            local ret = run_startstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local run_startstate_events_animover = run_startstate.events["animover"]
        if run_startstate_events_animover then
            local run_startstate_events_animover_fn = run_startstate_events_animover.fn
            run_startstate_events_animover.fn = function(inst, ...)
                if inst.UMIsBeardlord and inst:UMIsBeardlord(true) and inst.AnimState:AnimDone() then
                    inst.sg:GoToState("um_beard_run")
                    return
                end
                return run_startstate_events_animover_fn(inst, ...)
            end
        end
    end

    if run_stopstate then
        local run_stopstate_onenter = run_stopstate.onenter
        run_stopstate.onenter = function(inst, ...)
            if inst.UMIsBeardlord and inst:UMIsBeardlord(true) then inst.um_beardlord_overrides = {anim = "beard_run_pst", blockpush = true} end
            local ret = run_stopstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end

    local states = {
        State{
            name = "um_transform",
            tags = {"transform", "busy"},

            onenter = function(inst, data)
                inst.Physics:Stop()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/transform")
				local isbeardlord = inst.UMIsBeardlord and inst:UMIsBeardlord(true)
                inst.AnimState:PlayAnimation(isbeardlord and "trans_beard_pre" or "trans_rabbit_pre")
                inst.AnimState:PushAnimation(isbeardlord and "trans_beard_pst" or "trans_rabbit_pst", false)
                inst.sg.statemem.um_beardlord_data = data
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)
                    local data = inst.sg.statemem.um_beardlord_data
                    if data and inst.UMToggleBeardlord then
                        inst:UMToggleBeardlord({toggle = data.toggle})
                    end
                end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                local data = inst.sg.statemem.um_beardlord_data
                if data and inst.UMToggleBeardlord then
                    inst:UMToggleBeardlord({toggle = data.toggle})
                end
            end,
        },
        State{
            name = "um_beard_walk",
            tags = {"moving", "canrotate"},

            onenter = function(inst)
                inst.components.locomotor:WalkForward()
                inst.AnimState:PlayAnimation("beard_walk_loop", true)
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end,

            timeline =
            {
                TimeEvent(0, PlayFootstep),
                TimeEvent(12 * FRAMES, PlayFootstep),
            },

            ontimeout = function(inst) inst.sg:GoToState("um_beard_walk") end,
        },
        State{
            name = "um_beard_run",
            tags = {"moving", "running", "canrotate"},

            onenter = function(inst)
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation("beard_run_loop", true)
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end,

            timeline =
            {
                TimeEvent(0, PlayFootstep),
                TimeEvent(10 * FRAMES, PlayFootstep),
            },

            ontimeout = function(inst) inst.sg:GoToState("um_beard_run") end,
        },
    }

    for _, event in pairs(events) do
        inst.events[event.name] = event
    end

    for _, state in pairs(states) do
        inst.states[state.name] = state
    end
end)

--[[local IsForcedNightmare
local IsCrazyGuy]]
local DoShadowFx

local function RemoveFromGlobalTable(inst)
    local AnimState = inst.AnimState
    if AnimState and UM_BEARDLORDS.AnimStates[AnimState] then UM_BEARDLORDS.AnimStates[AnimState] = nil end
    inst:RemoveEventCallback("onremove", RemoveFromGlobalTable)
end

local function BeardlordAnimations(inst)
    local AnimState = inst.AnimState
    if AnimState then UM_BEARDLORDS.AnimStates[AnimState] = inst end
    inst:ListenForEvent("onremove", RemoveFromGlobalTable)
end

local function IsBeardlord(inst, forced)
    return inst.beardlord and (not forced or inst.components.timer and inst.components.timer:TimerExists("forcenightmare"))
end

local function ToggleBeardlord(inst, data)
    local toggle = data.toggle
    --if inst.beardlord ~= toggle then return end
    if toggle then
        inst.AnimState:SetBuild("manrabbit_beard_build")
        inst.components.combat:SetDefaultDamage(TUNING.BEARDLORD_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.BEARDLORD_ATTACK_PERIOD)
        inst.components.combat.panic_thresh = TUNING.BEARDLORD_PANIC_THRESH
        inst.components.sleeper:SetSleepTest(function() return false end)
        inst.components.sleeper:SetWakeTest(function() return true end)
    else
        inst.AnimState:SetBuild("manrabbit_build")
        inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE)
        inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD)
        inst.components.combat.panic_thresh = TUNING.BUNNYMAN_PANIC_THRESH
        inst.components.sleeper.sleeptestfn = NocturnalSleepTest
        inst.components.sleeper.waketestfn = NocturnalWakeTest
    end
end

--[[local function FindPlayer(inst, target)
    return not IsEntityDeadOrGhost(target) and target.entity:IsVisible() and IsCrazyGuy and IsCrazyGuy(target)
end

local BEARDLORD_TRANSFORM_RANGE = 20 --ENTITY_POPOUT_RADIUS + 1
local function ShouldBeBeardlord_Internal(inst, data)
    --local target = inst.um_beardlord_target
    --if target and target:IsValid() and inst.UMFindPlayer then return target.isplayer and inst:UMFindPlayer(target) end
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if inst.UMFindPlayer and inst:UMFindPlayer(v) and v:GetDistanceSqToPoint(x, y, z) < (BEARDLORD_TRANSFORM_RANGE * BEARDLORD_TRANSFORM_RANGE) then
            return true
        end
    end
    return nil
end

local function ShouldBeBeardlord(inst, data)
    if inst.components.health and inst.components.health:IsDead() or inst.components.timer and inst.components.timer:TimerExists("forcenightmare") then return end
    local becomebeardlord = not (data and data.forcefail) and inst.UMShouldBeBeardlord_Internal and inst:UMShouldBeBeardlord_Internal() or nil
    if inst.beardlord ~= becomebeardlord then
        inst.beardlord = becomebeardlord
        inst:PushEvent("um_transform", {toggle = becomebeardlord, nostate = data and data.nostate})
    end
end]]

--[[local function OnNewTarget(inst, data)
    inst.um_beardlord_target = data and data.target or nil
    if not inst.um_shouldbebeardlord then
        inst.um_shouldbebeardlord = inst:DoPeriodicTask(FRAMES, inst.UMShouldBeBeardlord, 0)
    end
end

local function OnDroppedTarget(inst, data)
    if inst.um_shouldbebeardlord then
        inst.um_shouldbebeardlord:Cancel()
        inst.um_shouldbebeardlord = nil
    end
    inst.um_beardlord_target = nil
    inst:UMShouldBeBeardlord({forcefail = true, nostate = inst.um_onload or inst:IsAsleep()})
end]]

--[[local _OnEntityWake
local function OnEntityWake(inst, ...)
    local ret = _OnEntityWake and _OnEntityWake(inst, ...)
    if inst.UMShouldBeBeardlord then inst:UMShouldBeBeardlord({nostate = true}) end
    if not inst.um_shouldbebeardlord then
        inst.um_shouldbebeardlord = inst:DoPeriodicTask(FRAMES, inst.UMShouldBeBeardlord)
    end
    return ret
end

local _OnEntitySleep
local function OnEntitySleep(inst, ...)
    local ret = _OnEntitySleep and _OnEntitySleep(inst, ...)
    if inst.UMShouldBeBeardlord then inst:UMShouldBeBeardlord({forcefail = true, nostate = true}) end
    if inst.um_shouldbebeardlord then
        inst.um_shouldbebeardlord:Cancel()
        inst.um_shouldbebeardlord = nil
    end
    return ret
end]]

local _OnLoad
local function OnLoad(inst, ...)
    inst.um_onload = true
    local ret = _OnLoad and _OnLoad(inst, ...)
    inst.um_onload = nil
    return ret
end

local function BunnymanFunctions(inst)
    BeardlordAnimations(inst)
    inst.UMIsBeardlord = IsBeardlord
    inst.UMToggleBeardlord = ToggleBeardlord
    --[[inst.UMFindPlayer = FindPlayer
    inst.UMShouldBeBeardlord_Internal = ShouldBeBeardlord_Internal
    inst.UMShouldBeBeardlord = ShouldBeBeardlord
    inst.um_shouldbebeardlord = inst:DoPeriodicTask(FRAMES, inst.UMShouldBeBeardlord, 0)]] -- Commented parts for sane players to see beardlords if there's an insane player nearby.
    --[[inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("droppedtarget", OnDroppedTarget)]]

    --[[if not _OnEntityWake then
        _OnEntityWake = inst.OnEntityWake
    end
    inst.OnEntityWake = OnEntityWake
    if not _OnEntitySleep then
        _OnEntitySleep = inst.OnEntitySleep
    end
    inst.OnEntitySleep = OnEntitySleep]]
    if not _OnLoad then
        _OnLoad = inst.OnLoad
    end
    inst.OnLoad = OnLoad
end

local function OnTimerDone(inst, data)
    if data and data.name == "forcenightmare" then
        local rendered = not (inst:IsInLimbo() or inst:IsAsleep())
        if rendered then
            if inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("sleeping") then
                inst.components.timer:StartTimer("forcenightmare", 1)
                return
            end
            if DoShadowFx then DoShadowFx(inst, false) end
        end
        inst:RemoveEventCallback("timerdone", OnTimerDone)
        --[[if inst.beardlord and not (inst.UMShouldBeBeardlord_Internal and inst:UMShouldBeBeardlord_Internal()) then
            inst.beardlord = nil
            inst:PushEvent("um_transform", {toggle = nil, nostate = not rendered})
        end]]
        if not inst.clearbeardlordtask then inst.beardlord = nil end
        inst:PushEvent("um_transform", {toggle = nil, nostate = not rendered})
    end
end

env.AddPrefabPostInit("world", function(inst) -- Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not TheWorld.ismastersim then return end
    --[[IsForcedNightmare = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "LootSetupFunction", "IsForcedNightmare")
    local beardlordloot = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "LootSetupFunction", "beardlordloot")
    local _LootSetupFunction = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "LootSetupFunction")
    if _LootSetupFunction then
        local function LootSetupFunction(lootdropper, ...)
            local inst = lootdropper.inst
            if inst.beardlord and IsForcedNightmare and not IsForcedNightmare(inst) then
                lootdropper:SetLoot(beardlordloot)
                return
            end
            return _LootSetupFunction(lootdropper, ...)
        end
        UpvalueHacker.SetUpvalue(Prefabs.bunnyman.fn, LootSetupFunction, "LootSetupFunction")
    end
    IsCrazyGuy = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "CalcSanityAura", "IsCrazyGuy")
    local _ClearObservedBeardlord = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "CalcSanityAura", "SetObserverdBeardLord", "ClearObservedBeardlord")
    if _ClearObservedBeardlord then
        local function ClearObservedBeardlord(inst, ...) end
        UpvalueHacker.SetUpvalue(Prefabs.bunnyman.fn, ClearObservedBeardlord, "CalcSanityAura", "SetObserverdBeardLord", "ClearObservedBeardlord")
    end
    local _SetObserverdBeardLord = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "CalcSanityAura", "SetObserverdBeardLord")
    if _SetObserverdBeardLord then
        local function SetObserverdBeardLord(inst, ...) end
        UpvalueHacker.SetUpvalue(Prefabs.bunnyman.fn, SetObserverdBeardLord, "CalcSanityAura", "SetObserverdBeardLord")
    end
    local _CalcSanityAura = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "CalcSanityAura")
    if _CalcSanityAura then
        local function CalcSanityAura(inst, observer, ...)
            if inst.beardlord and IsForcedNightmare and not IsForcedNightmare(inst) then return -TUNING.SANITYAURA_MED end
            return _CalcSanityAura(inst, observer, ...)
        end
        UpvalueHacker.SetUpvalue(Prefabs.bunnyman.fn, CalcSanityAura, "CalcSanityAura")
    end]]
    DoShadowFx = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "OnForceNightmareState", "DoShadowFx")
    local _SetForcedBeardLord = UpvalueHacker.GetUpvalue(Prefabs.bunnyman.fn, "OnForceNightmareState", "SetForcedBeardLord")
    if _SetForcedBeardLord then
        local function SetForcedBeardLord(inst, duration)
            --duration nil is loading, so don't perform checks
            if duration then
                if inst.components.health:IsDead() then return end
                local t = inst.components.timer:GetTimeLeft("forcenightmare")
                if t then
                    if t < duration then
                        inst.components.timer:SetTimeLeft("forcenightmare", duration)
                    end
                    return
                end
                inst.components.timer:StartTimer("forcenightmare", duration)
            end
            --[[local wasbeardlord = inst.beardlord
            if not wasbeardlord then
                inst.beardlord = true
                inst:PushEvent("um_transform", {toggle = true, nostate = inst.um_onload or inst:IsAsleep()})
            end]]
            inst.beardlord = true
            inst:PushEvent("um_transform", {toggle = true, nostate = inst.um_onload or inst:IsAsleep()})
            inst:ListenForEvent("timerdone", OnTimerDone)
        end
        UpvalueHacker.SetUpvalue(Prefabs.bunnyman.fn, SetForcedBeardLord, "OnForceNightmareState", "SetForcedBeardLord")
    end
end)

env.AddPrefabPostInit("bunnyman", function(inst)
    if not TheWorld.ismastersim then return end
    BunnymanFunctions(inst)
end)
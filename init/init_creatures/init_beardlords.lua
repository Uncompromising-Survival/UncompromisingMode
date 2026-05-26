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

env.AddStategraphPostInit("bunnyman", function(inst)
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
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_idle_loop"} end
            local ret = idlestate_onenter(inst, pushanim, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
        table.insert(idlestate.timeline, TimeEvent(0 * FRAMES, function(inst) if inst.beardlord then inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/wererabbit_breathin") end end))
        table.insert(idlestate.timeline, TimeEvent(15 * FRAMES, function(inst) if inst.beardlord then inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/wererabbit_idle") end end))
        table.sort(idlestate.timeline, function(a, b) return a.time < b.time end)
    end

    if funnyidlestate then
        local funnyidlestate_onenter = funnyidlestate.onenter
        funnyidlestate.onenter = function(inst, ...)
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_taunt", sound = "dontstarve/creatures/bunnyman/wererabbit_taunt"} end
            local ret = funnyidlestate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end
    
    if attackstate then
        local attackstate_onenter = attackstate.onenter
        attackstate.onenter = function(inst, ...)
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_atk", sound = "dontstarve/creatures/bunnyman/wererabbit_attack"} end
            local ret = attackstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local attackstate_timeline1 = attackstate.timeline[1]
        if attackstate_timeline1 then
            local attackstate_timeline1_fn = attackstate_timeline1.fn
            attackstate_timeline1.fn = function(inst, ...)
                if inst.beardlord then inst.um_beardlord_overrides = {blocksound = "dontstarve/creatures/bunnyman/bite"} end
                local ret = attackstate_timeline1_fn(inst, ...)
                if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
                return ret
            end
        end
    end

    if walk_startstate then
        local walk_startstate_onenter = walk_startstate.onenter
        walk_startstate.onenter = function(inst, ...)
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_walk_pre"} end
            local ret = walk_startstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local walk_startstate_events_animover = walk_startstate.events["animover"]
        if walk_startstate_events_animover then
            local walk_startstate_events_animover_fn = walk_startstate_events_animover.fn
            walk_startstate_events_animover.fn = function(inst, ...)
                if inst.AnimState:AnimDone() and inst.beardlord then
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
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_walk_pst", blockpush = true} end
            local ret = walk_stopstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end

    if run_startstate then
        local run_startstate_onenter = run_startstate.onenter
        run_startstate.onenter = function(inst, ...)
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_run_pre"} end
            local ret = run_startstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end

        local run_startstate_events_animover = run_startstate.events["animover"]
        if run_startstate_events_animover then
            local run_startstate_events_animover_fn = run_startstate_events_animover.fn
            run_startstate_events_animover.fn = function(inst, ...)
                if inst.AnimState:AnimDone() and inst.beardlord then
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
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_run_pst", blockpush = true} end
            local ret = run_stopstate_onenter(inst, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end

    local states = {
        State{
            name = "um_transform",
            tags = {"transform", "busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/transform")
                inst.AnimState:PlayAnimation(inst.beardlord and "trans_rabbit_pre" or "trans_beard_pre")
                inst.AnimState:PushAnimation(inst.beardlord and "trans_beard_pst" or "trans_rabbit_pst", false)
            end,

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },

            --[[onexit = function(inst)
                inst.AnimState:SetBuild("werepig_build")
            end,]]
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
        State{
            name = "um_beard_attack",
            tags = {"attack", "busy"},

            onenter = function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/wererabbit_attack")
                inst.components.combat:StartAttack()
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("beard_atk")
            end,

            timeline =
            {
                TimeEvent(13 * FRAMES, function(inst)
                    inst.components.combat:DoAttack()
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("busy")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
    }

    --[[for _, event in pairs(events) do
        inst.events[event.name] = event
    end]]

    for _, state in pairs(states) do
        inst.states[state.name] = state
    end
end)

env.AddPrefabPostInit("bunnyman", function(inst)
    if not TheWorld.ismastersim then return end
    BeardlordAnimations(inst)
end)
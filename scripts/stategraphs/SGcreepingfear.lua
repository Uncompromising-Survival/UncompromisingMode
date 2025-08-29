require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
}

local events =
{
    EventHandler("attacked", function(inst)
        if not (inst.sg:HasAnyStateTag("attack", "hit", "noattack") or inst.components.health and inst.components.health:IsDead())
            and inst.hitcount and inst.hitcount <= 0 then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health and inst.components.health:IsDead()) then
            inst.sg:GoToState("attack", data.target)
        end
    end),
    CommonHandlers.OnLocomote(false, true),
}

local function FinishExtendedSound(inst, soundid)
    inst.SoundEmitter:KillSound("sound_"..tostring(soundid))
    inst.sg.mem.soundcache[soundid] = nil
    if inst.sg.statemem.readytoremove and not next(inst.sg.mem.soundcache) then
        inst:Remove()
    end
end

local function PlayExtendedSound(inst, soundname)
    if not inst.sg.mem.soundcache then
        inst.sg.mem.soundcache = {}
        inst.sg.mem.soundid = 0
    else
        inst.sg.mem.soundid = inst.sg.mem.soundid + 1
    end
    inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
    inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_"..tostring(inst.sg.mem.soundid))
    inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
end

local function OnAnimOverRemoveAfterSounds(inst)
    if not inst.sg.mem.soundcache or not next(inst.sg.mem.soundcache) then
        inst:Remove()
    else
        inst:Hide()
        inst.sg.statemem.readytoremove = true
    end
end

local function TryDropTarget(inst)
    if inst.ShouldKeepTarget then
        local target = inst.components.combat.target
        if target and not inst:ShouldKeepTarget(target) then
            inst.components.combat:DropTarget()
            return true
        end
    end
end

local function TryDespawn(inst)
    if inst.sg.mem.forcedespawn or (inst.wantstodespawn and not inst.components.combat:HasTarget()) then
        inst.sg:GoToState("disappear")
        return true
    end
end

local function CancelSpikewaves(inst)
    if inst.spiketask then
        inst.spiketask:Cancel()
        inst.spiketask = nil
    end
end

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            --[[if inst.wantstodespawn then
                local t = GetTime()
                if t > inst.components.combat:GetLastAttackedTime() + 5 then
                    local target = inst.components.combat.target
                    if not target or not target.components.combat --Apparently this can be nil? got a crash once.
                        or not target.components.combat:IsRecentTarget(inst)
                        or (target.components.combat.laststartattacktime and t > target.components.combat.laststartattacktime + 5) then
                        inst.sg:GoToState("disappear")
                        return
                    end
                end
            end]]
            local dropped = TryDropTarget(inst)
            if TryDespawn(inst) then
                return
            elseif dropped then
                inst.sg:GoToState("taunt")
                return
            end
            inst.components.locomotor:StopMoving()
            if not inst.AnimState:IsCurrentAnimation("idle_loop") then
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            PlayExtendedSound(inst, "attack_grunt")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst) PlayExtendedSound(inst, "attack") end),
            TimeEvent(16 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if math.random() < .333 then
                    TryDropTarget(inst)
                    inst.forceretarget = true --V2C: try to keep legacy behaviour; it used SetTarget(nil) here, which would always result in a retarget
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.Physics:Stop()
            CancelSpikewaves(inst)
            inst.AnimState:PlayAnimation("disappear")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local x0, y0, z0 = inst.Transform:GetWorldPosition()
                for k = 1, 4 --[[# of attempts]] do
                    local x = x0 + math.random() * 20 - 10
                    local z = z0 + math.random() * 20 - 10
                    if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
                        inst.Physics:Teleport(x, 0, z)
                        break
                    end
                end
                inst.sg:GoToState("appear")
            end),
        },
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            PlayExtendedSound(inst, "taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "appear",
        tags = {"busy"},

        onenter = function(inst)
            TryDropTarget(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.Physics:Stop()
            inst.hitcount = 3
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst:AddTag("NOCLICK")
            CancelSpikewaves(inst)
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end
    },

    State{
        name = "disappear",
        tags = {"busy", "noattack"},

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.Physics:Stop()
            inst:AddTag("NOCLICK")
            CancelSpikewaves(inst)
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },

    State{ 
        name = "teleport_disapper",
        tags = {"busy", "noattack"},
    
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("disappear")
        end,
    
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("appear") end),
        },
    },

    State{
        name = "action",

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0 * FRAMES, function(inst)
            local dropped = TryDropTarget(inst)
            if TryDespawn(inst) then
                return
            elseif dropped then
                inst.sg:GoToState("taunt")
            end
        end),
    },
})

return StateGraph("creepingfear", states, events, "appear", actionhandlers)
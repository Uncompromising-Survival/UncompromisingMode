require("stategraphs/commonstates")

local function PlayBatSound(inst, sound)
    inst.SoundEmitter:PlaySound(sound)
end

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, function(inst)
        local ba = inst:GetBufferedAction()
        return ba and (ba.target and ba.target:HasTag("sinkhole") or ba.options.do_not_locomote) and "flyaway" or "action"
    end),
    ActionHandler(ACTIONS.EAT, function(inst)
        local ba = inst:GetBufferedAction()
        return ba and ba.target and ba.target.prefab == "nitre" and "chew_ground" or "eat_loop"
    end),
    ActionHandler(ACTIONS.PICKUP, "eat_enter"),
    ActionHandler(ACTIONS.STEAL, "eat_enter"),
}

local function ChooseAttack(inst, target)
    target = target or inst.components.combat.target
    if target and target:IsValid() then
        inst.sg:GoToState("attack", target)
        return true
    end
    return false
end

local events =
{
    EventHandler("fly_back", function(inst, data)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("flyback")
        end
    end),
    EventHandler("fly_away", function(inst, data)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("flyaway")
        end
    end),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnElectrocute(),
    CommonHandlers.OnKnockback(),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnCorpseChomped(),
    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            ChooseAttack(inst, data and data.target)
        end
    end),
    CommonHandlers.OnAttacked(),
}

local function DoChewSound(inst)
    PlayBatSound(inst, "UCSounds/vampirebat/flap") -- Always flap.

    if inst.sg.statemem.chewsounds then
        if inst.sg.statemem.chewsounds > 1 then
            inst.sg.statemem.chewsounds = inst.sg.statemem.chewsounds - 1
            PlayBatSound(inst, "dontstarve/creatures/bat/chew")
        else
            inst.sg.statemem.chewsounds = nil
        end
    end
end

--Keep 6-faced in Transform component; anim with no facings will behave like 2-faced.
local function SwitchToNoFaced(inst)
    inst.sg.mem.nofaced = true
end

local function TryRestoreSixFaced(inst)
    if not inst.sg.statemem.keepnofaced then
        inst.sg.mem.nofaced = nil
    end
end

local states =
{
    State{
        
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, pushanim)
            inst.components.locomotor:StopMoving()

            if type(pushanim) == "string" then
                inst.sg.statemem.pushanim = true
                inst.AnimState:PlayAnimation(pushanim)
            elseif pushanim and not inst.AnimState:AnimDone() then
                inst.sg.statemem.pushanim = true
            else
                local anim = inst.sg.mem.nofaced and "fly_loop_nofaced" or "fly_loop"
                if not inst.AnimState:IsCurrentAnimation(anim) or inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation(anim, true)
                end
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
            --TimeEvent(5 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/vampirebat/breath") end ),
            TimeEvent(17 * FRAMES, function(inst) inst:PushEvent("wingdown") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

        timeline =
        {
            FrameEvent(7, function(inst)
                if not inst.sg.statemem.pushanim then
                    PlayBatSound(inst, "UCSounds/vampirebat/flap")
                end
            end),
            FrameEvent(17, function(inst)
                if not inst.sg.statemem.pushanim then
                    PlayBatSound(inst, "UCSounds/vampirebat/flap")
                end
            end),
        },

        events =
        {
            --NOTE: we may be have several anims still queued
            EventHandler("animqueueover", function(inst)
                if inst.sg.statemem.pushanim and inst.AnimState:AnimDone() then
                    inst.sg.statemem.keepnofaced = true
                    inst.sg:GoToState("idle")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "action",

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("fly_loop", true)
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },

    State{
        name = "flyaway",
        tags = {"flight", "busy", "noelectrocute", "noknockback", "noattack", "temp_invincible", "jumping"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            inst.DynamicShadow:Enable(false)

            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("fly_away_pre")
            inst.AnimState:PushAnimation("fly_away_loop", true)

            inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
        end,

        timeline =
        {
            FrameEvent(6, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(13, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(23, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(33, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(41, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(51, function(inst) inst:PerformBufferedAction() end),
        },

        onexit = function(inst)
            TryRestoreSixFaced(inst)
            inst.DynamicShadow:Enable(true)
        end,
    },

    State{
        name = "flyback",
        tags = {"flight", "busy", "noelectrocute", "noknockback", "noattack", "temp_invincible", "jumping"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.DynamicShadow:Enable(false)

            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("fly_back_loop", true)

            local x, _, z = inst.Transform:GetWorldPosition()
            inst.Physics:Teleport(x, 15, z)
            inst.Physics:SetMotorVel(0, -10 + math.random() * 2, 0)
        end,

        onupdate = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y <= 0.1 or inst:IsAsleep() then
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.sg.statemem.keepnofaced = true
                inst.sg:GoToState("flyback_pst")
                return
            end

            inst.Physics:SetMotorVel(0, -10 + math.random() * 2, 0)
        end,

        timeline =
        {
            FrameEvent(3, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(14, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(24, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(34, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(41, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
        },

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            TryRestoreSixFaced(inst)
            inst.DynamicShadow:Enable(true)
        end,
    },

    State{
        name = "flyback_pst",
        tags = {"busy", "caninterrupt", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()

            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("fly_back_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.keepnofaced = true
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "taunt",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            FrameEvent(1, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/taunt") end),
            FrameEvent(6, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/breath") end),
            FrameEvent(7, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(18 * FRAMES, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(28 * FRAMES, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(43 * FRAMES, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(40, function(inst)
                inst.sg:AddStateTag("caninterrupt")
            end),
            FrameEvent(45, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.keepnofaced = true
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "eat_enter",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat", false)
        end,

        timeline =
        {
            FrameEvent(7, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(8, function(inst) inst:PerformBufferedAction() PlayBatSound(inst, "UCSounds/vampirebat/bite") end),
            FrameEvent(16, function(inst)
                inst.sg:AddStateTag("caninterrupt")
            end),
            FrameEvent(17, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.keepnofaced = true
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "eat_loop",
        tags = {"busy", "caninterrupt", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("eat_loop", true)
            inst.sg:SetTimeout(1 + math.random() * 2)
        end,

        timeline =
        {
            FrameEvent(7, function(inst)
                PlayBatSound(inst, "UCSounds/vampirebat/flap")
                PlayBatSound(inst, "dontstarve/creatures/bat/chew")
            end),
            FrameEvent(17, function(inst)
                PlayBatSound(inst, "UCSounds/vampirebat/flap")
                PlayBatSound(inst, "dontstarve/creatures/bat/chew")
            end),
        },

        ontimeout = function(inst)
            inst.lastmeal = GetTime()
            inst:PerformBufferedAction()
            inst.sg.statemem.keepnofaced = true
            inst.sg:GoToState("idle")
        end,

        events =
        {
            EventHandler("attacked", function(inst)
                --drop food
                if inst.components.inventory then
                    inst.components.inventory:DropEverything()
                end
                inst.sg:GoToState("hit")
            end),
        },

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "chew_ground",
        tags = {"busy", "caninterrupt", "canrotate"},

        onenter = function(inst, data)
            inst.components.locomotor:StopMoving()

            SwitchToNoFaced(inst)
            inst.AnimState:PlayAnimation("chew_pre")

            local chews = math.min(data and data.chews or math.random(14, 18), 18)
            for i = 1, chews do
                inst.AnimState:PushAnimation("chew_loop", false)
            end

            inst.AnimState:PushAnimation("chew_pst", false)

            inst.sg.statemem.chewsounds = chews
        end,

        timeline =
        {
            FrameEvent(6, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(12 + 9 * 0, DoChewSound),
            FrameEvent(12 + 9 * 1, DoChewSound),
            FrameEvent(12 + 9 * 2, DoChewSound),
            FrameEvent(12 + 9 * 3, DoChewSound),
            FrameEvent(12 + 9 * 4, DoChewSound),
            FrameEvent(12 + 9 * 5, DoChewSound),
            FrameEvent(12 + 9 * 6, DoChewSound),
            FrameEvent(12 + 9 * 7, DoChewSound),
            FrameEvent(12 + 9 * 8, DoChewSound),
            FrameEvent(12 + 9 * 9, DoChewSound),
            FrameEvent(12 + 9 * 10, DoChewSound),
            FrameEvent(12 + 9 * 11, DoChewSound),
            FrameEvent(12 + 9 * 12, DoChewSound),
            FrameEvent(12 + 9 * 13, DoChewSound),
            FrameEvent(12 + 9 * 14, DoChewSound),
            FrameEvent(12 + 9 * 15, DoChewSound),
            FrameEvent(12 + 9 * 16, DoChewSound),
            FrameEvent(12 + 9 * 17, DoChewSound),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.lastmeal = GetTime()
                    inst:PerformBufferedAction()
                    inst.sg.statemem.keepnofaced  = true
                    inst.sg:GoToState("idle")
                end
            end),
            EventHandler("attacked", function(inst)
                --drop food
                if inst.components.inventory then
                    inst.components.inventory:DropEverything()
                end
                inst.sg:GoToState("hit")
            end),
        },

        onexit = TryRestoreSixFaced,
    },

    State{
        name = "hit",
        tags = {"hit", "busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        timeline =
        {
            FrameEvent(1, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/hit") end),
            FrameEvent(7, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
            FrameEvent(9, function(inst)
                if not (inst.sg.statemem.doattack and inst.sg.statemem.doattack:IsValid()) then
                    inst.sg:AddStateTag("caninterrupt")
                end
            end),
            FrameEvent(10, function(inst)
                if inst.sg.statemem.doattack and ChooseAttack(inst, inst.sg.statemem.doattack) then
                    return
                end
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("doattack", function(inst, data)
                if inst.sg:HasStateTag("busy") and data and data.target and data.target:IsValid() then
                    inst.sg.statemem.doattack = data.target
                    inst.sg:RemoveStateTag("caninterrupt")
                    return true
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "jumping"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("atk")

            inst.components.combat:StartAttack()

            inst.sg.statemem.speedmult = 1

            if target and target:IsValid() then
                inst.sg.statemem.target = target

                local x, _, z = inst.Transform:GetWorldPosition()
                local x1, _, z1 = target.Transform:GetWorldPosition()
                local dx = x1 - x
                local dz = z1 - z
                if dx ~= 0 or dz ~= 0 then
                    inst.Transform:SetRotation(math.atan2(-dz, dx) * RADIANS)
                end

                if target.components.locomotor == nil then
                    if dx ~= 0 or dz ~= 0 then
                        local dist = 1.025
                        local dist1 = math.sqrt(dx * dx + dz * dz) - inst:GetPhysicsRadius(0) - target:GetPhysicsRadius(0)
                        inst.sg.statemem.speedmult = math.clamp(dist1, 0, dist) / dist
                    else
                        inst.sg.statemem.speedmult = 0
                    end
                end
            end

            inst.Physics:SetMotorVelOverride(1.5 * inst.sg.statemem.speedmult, 0, 0)
        end,

        timeline =
        {
            FrameEvent(5, function(inst)
                inst.Physics:SetMotorVelOverride(6 * inst.sg.statemem.speedmult, 0, 0)
            end),
            FrameEvent(8, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/bite") end),
            FrameEvent(10, function(inst)
                inst.Physics:SetMotorVelOverride(2 * inst.sg.statemem.speedmult, 0, 0)
                PlayBatSound(inst, "UCSounds/vampirebat/flap")
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            FrameEvent(11, function(inst)
                inst.Physics:SetMotorVelOverride(1 * inst.sg.statemem.speedmult, 0, 0)
            end),
            FrameEvent(12, function(inst)
                inst.Physics:SetMotorVelOverride(0.5 * inst.sg.statemem.speedmult, 0, 0)
            end),
            FrameEvent(13, function(inst)
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.sg:RemoveStateTag("jumping")
            end),
            FrameEvent(15, function(inst)
                inst.sg:AddStateTag("caninterrupt")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
        end,
    },

    State{
        name = "glide",
        tags = {"idle", "flying", "busy"},

        onenter = function(inst)
            inst.DynamicShadow:Enable(false)
            inst.AnimState:PlayAnimation("glide", true)
            inst.Physics:SetMotorVelOverride(0, -25, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVelOverride(0, -25, 0)
            local pt = Point(inst.Transform:GetWorldPosition())
            if pt.y <= .1 then
                inst.Physics:ClearMotorVelOverride()
                pt.y = 0
                inst.Physics:Stop()
                inst.Physics:Teleport(pt.x,pt.y,pt.z)
                --inst.AnimState:PlayAnimation("land")
                inst.DynamicShadow:Enable(true)

                --inst.sg:GoToState("idle")
                inst.sg:GoToState("land")
            end
        end,

        onexit = function(inst)
            if inst:GetPosition().y > 0 then
                local pos = inst:GetPosition()
                pos.y = 0
                inst.Transform:SetPosition(pos:Get())
            end
            --inst.components.knownlocations:RememberLocation("landpoint", inst:GetPosition())
        end,
    },

    State{
        name = "land",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("land", false)
            --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/land")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

}

local walkanims =
{
    startwalk = "fly_loop",
    walk = "fly_loop",
    stopwalk = "fly_loop",
}

local walktimeline =
{
    FrameEvent(7, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
    FrameEvent(5, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/breath") end),
    FrameEvent(17, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
}

CommonStates.AddWalkStates(states,
{
    starttimeline = walktimeline,
    walktimeline = walktimeline,
    endtimeline = walktimeline,
}, walkanims, true)

--keep in sync with bat/bat_boss constructor shadoow size
local function ConfigSleepLanded(inst, landed)
    if landed then
        if inst:HasTag("flying") then
            LandFlyingCreature(inst)
        end
        inst.DynamicShadow:SetSize(2, 1)
    else
        if not inst:HasTag("flying") then
            if inst.components.floater:IsFloating() then
                SpawnPrefab("splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            RaiseFlyingCreature(inst)
        end
        inst.DynamicShadow:SetSize(1.5, .75)
    end
end

CommonStates.AddSleepExStates(states,
{
    starttimeline =
    {
        FrameEvent(7, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
        FrameEvent(5, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/breath") end),
        FrameEvent(17, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
        FrameEvent(27, function(inst)
            inst.sg:RemoveStateTag("caninterrupt")
        end),
    },
    sleeptimeline =
    {
        FrameEvent(23, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/breath") end),
    },
    waketimeline =
    {
        CommonHandlers.OnNoSleepFrameEvent(12, function(inst)
            inst.sg:RemoveStateTag("nosleep")
            inst.sg:AddStateTag("caninterrupt")
            inst.sg:AddStateTag("canrotate")
            ConfigSleepLanded(inst, false)
        end),
        FrameEvent(13, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end),
    },
},
{
    onsleep = function(inst)
        inst.sg:AddStateTag("caninterrupt")
        SwitchToNoFaced(inst)
    end,
    onexitsleep = function(inst)
        if not inst.sg.statemem.continuesleeping then
            TryRestoreSixFaced(inst)
        end
    end,
    onsleeping = function(inst)
        SwitchToNoFaced(inst)
        ConfigSleepLanded(inst, true)
    end,
    onexitsleeping = function(inst)
        if not inst.sg.statemem.continuesleeping then
            TryRestoreSixFaced(inst)
            ConfigSleepLanded(inst, false)
        end
    end,
    onwake = function(inst)
        SwitchToNoFaced(inst)
        ConfigSleepLanded(inst, true)
    end,
    onexitwake = function(inst)
        TryRestoreSixFaced(inst)
        ConfigSleepLanded(inst, false)
    end,
})

CommonStates.AddDeathState(states,
{
    FrameEvent(1, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/death") end),
    FrameEvent(4, function(inst) PlayBatSound(inst, "UCSounds/vampirebat/flap") end ),
    FrameEvent(15, LandFlyingCreature),
},
nil, nil, { has_corpse_handler = true })

CommonStates.AddFrozenStates(states,
    function(inst)
        SwitchToNoFaced(inst)
        LandFlyingCreature(inst)
    end,
    function(inst)
        TryRestoreSixFaced(inst)
        RaiseFlyingCreature(inst)
    end)

local function _nofacedidleonanimover(inst)
	if inst.AnimState:AnimDone() then
		inst.sg.statemem.keepnofaced = true
		inst.sg:GoToState("idle")
	end
end

CommonStates.AddElectrocuteStates(states, nil, nil,
{
	loop_onenter = SwitchToNoFaced,
	loop_onexit = TryRestoreSixFaced,
	pst_onenter = function(inst)
		inst.sg:AddStateTag("canrotate")
		SwitchToNoFaced(inst)
	end,
	onanimover = _nofacedidleonanimover,
	pst_onexit = TryRestoreSixFaced,
})

CommonStates.AddKnockbackStates(states,
{ --timelines
	knockback =
	{
		FrameEvent(14, LandFlyingCreature),
		FrameEvent(33, RaiseFlyingCreature),
	},
},
nil, --anims
{ --fns
	knockback_onenter = SwitchToNoFaced,
	knockback_onexit = function(inst)
		TryRestoreSixFaced(inst)
		RaiseFlyingCreature(inst)
	end,
	knockback_onanimover = _nofacedidleonanimover,
})

_nofacedidleonanimover = nil

CommonStates.AddInitState(states, "idle")
CommonStates.AddCorpseStates(states)

return StateGraph("um_vampirebat", states, events, "init", actionhandlers)
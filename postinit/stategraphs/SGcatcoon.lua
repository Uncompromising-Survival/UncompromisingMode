local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddStategraphPostInit("catcoon", function(inst)
    --[[local events =
    {
        EventHandler("doattack", function(inst, data)
            if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
                if data.target:HasTag("cattoyairborne") then
                    if data.target.sg and (data.target.sg:HasStateTag("landing") or data.target.sg:HasStateTag("landed")) then
                        inst.components.combat:SetTarget(nil)
                    else
                        inst.sg:GoToState("pounceplay", data.target)
                    end
                elseif data.target and data.target:IsValid() and inst:GetDistanceSqToInst(data.target) > TUNING.CATCOON_MELEE_RANGE*TUNING.CATCOON_MELEE_RANGE/(1.5*1.5) or math.random() > 0.5) then
                    inst.sg:GoToState("pounce_pre", data.target)
                else
                    inst.sg:GoToState("attack", data.target)
                end
            end
        end),
    }]]

    local attackedeventhandler = inst.events["attacked"]
    if attackedeventhandler then
        local attackedeventhandler_fn = attackedeventhandler.fn
        attackedeventhandler.fn = function(inst, data, ...)
            if inst.components.health and not inst.components.health:IsDead() and not CommonHandlers.TryElectrocuteOnAttacked(inst, data)
                and not CommonHandlers.HitRecoveryDelay(inst) and inst.sg.currentstate.name == "hiss" then
                inst.sg:GoToState("hit")
                return
            end
            return attackedeventhandler_fn(inst, data, ...)
        end
    end

    local pounceattackstate = inst.states["pounceattack"]
    if pounceattackstate then
        local pounceattackstate_onenter = pounceattackstate.onenter
        pounceattackstate.onenter = function(inst, target, ...)
            inst.components.combat:SetRange(TUNING.CATCOON_ATTACK_RANGE / 2)
            return pounceattackstate_onenter(inst, target, ...)
        end
        local pounceattackstate_onexit = pounceattackstate.onexit
        pounceattackstate.onexit = function(inst, ...)
            inst.components.combat:SetRange(TUNING.CATCOON_ATTACK_RANGE / 1.5)
            return pounceattackstate_onexit(inst, ...)
        end
    end

    --[[local states =
    {
        State{
            name = "pounce_pre",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.countercounter = 1
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("taunt_pre")
                inst.AnimState:PushAnimation("taunt", false)
                inst.AnimState:PushAnimation("taunt_pst", false)
                inst.sg:SetTimeout(.777)
            end,

            ontimeout = function(inst)
                local target = inst.sg.statemem.target and inst.sg.statemem.target:IsValid() and inst.sg.statemem.target or inst.components.combat and inst.components.combat.target
                if target then
                    inst.sg:GoToState("pounceattack", target)
                else
                    inst.sg:GoToState("idle")
                end
            end,  

            timeline =
            {
                TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/hiss_pre") end),
                TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/catcoon/hiss") end)
            },
            
        },
    }

    for k, v in pairs(events) do
        assert(v:is_a(EventHandler), "Non-event added in mod events table!")
        inst.events[v.name] = v
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end]]
end)
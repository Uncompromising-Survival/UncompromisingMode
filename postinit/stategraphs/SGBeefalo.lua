local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("beefalo", function(inst)
    local attackedeventhandler = inst.events["attacked"]
    if attackedeventhandler then
        local attackedeventhandler_fn = attackedeventhandler.fn
        attackedeventhandler.fn = function(inst, data, ...)
            if inst.components.health and not inst.components.health:IsDead() and inst.sg:HasStateTag("um_charging") then
                CommonHandlers.TryElectrocuteOnAttacked(inst, data)
                return
            end
            return attackedeventhandler_fn(inst, data, ...)
        end
    end

    local attackstate = inst.states["attack"]
    if attackstate then
        local attackstate_animqueueover_fn = attackstate.events["animqueueover"].fn
        attackstate.events["animqueueover"].fn = function(inst, ...)
            if inst.components.combat.target --[[and math.random() < .33]] and not inst.justcharged then
                inst.justcharged = true
                inst.sg:GoToState("charge_start", inst.components.combat.target)
                return
            end
            if inst.justcharged then inst.justcharged = nil end
            return attackstate_animqueueover_fn(inst, ...)
        end
    end

    local states =
    {
        State{
            name = "charge_start",
            tags = {"um_charging", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target
                inst.AnimState:SetDeltaTimeMultiplier(1.2)
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("mating_taunt1")
                inst.SoundEmitter:PlaySound(inst.sounds.yell)
                inst.sg:SetTimeout(1)
            end,
            
            onupdate = function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("charge", inst.sg.statemem.target and inst.sg.statemem.target:IsValid() and inst.sg.statemem.target or inst.components.combat.target)
            end,

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "charge",
            tags = {"um_charging", "busy"},

            onenter = function(inst, target)
                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()
                inst.sg.statemem.target = target
                inst.components.locomotor:RunForward()
                inst.components.locomotor:SetExternalSpeedMultiplier(inst, "um_charge", math.max(16 / inst.components.locomotor.runspeed, 1))
                inst.AnimState:SetDeltaTimeMultiplier(1.2)
                inst.AnimState:PlayAnimation("run_loop", true)
            end,

            onupdate = function(inst, dt)
                if inst:IsAsleep() then
                    inst.sg:GoToState("idle")
                    return
                elseif dt > 0 then
                    local target = inst.sg.statemem.target
                    if target and target:IsValid() then
                        local combat = inst.components.combat
                        if inst:IsNear(target, combat:GetHitRange() + target:GetPhysicsRadius(0)) then
                            combat:DoAttack(target)
                            inst.sg:GoToState("chargeattack", target)
                        end
                    end
                end
            end,

            timeline =
            {
                TimeEvent(5 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(9 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(10 * FRAMES, PlayFootstep),
                TimeEvent(14 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(15 * FRAMES, PlayFootstep),
                TimeEvent(24 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(25 * FRAMES, PlayFootstep),
                TimeEvent(29 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(30 * FRAMES, function(inst) inst.sg:GoToState("idle") end),
            },

            onexit = function(inst)
                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "um_charge")
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "chargeattack",
            tags = {"um_charging", "busy", "attack"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target
                inst.SoundEmitter:PlaySound(inst.sounds.angry)
                inst.components.combat:StartAttack()
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("atk")
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
    }

    --[[for k, v in pairs(events) do
        assert(v:is_a(EventHandler), "Non-event added in mod events table!")
        inst.events[v.name] = v
    end]]

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)
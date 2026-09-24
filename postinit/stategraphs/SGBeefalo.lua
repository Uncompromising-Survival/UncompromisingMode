local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("beefalo", function(inst)
    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health:IsDead() or inst.sg:HasStateTag("electrocute")) and inst.sg.mem.um_chargeattack then
                inst.sg.mem.um_chargeattack = nil
                inst.sg:GoToState("chargeattack", data.target)
            else
                doattackeventhandler_fn(inst, data, ...)
            end
        end
    end

    local attackedeventhandler = inst.events["attacked"]
    if attackedeventhandler then
        local attackedeventhandler_fn = attackedeventhandler.fn
        attackedeventhandler.fn = function(inst, data, ...)
            if inst.components.health and not inst.components.health:IsDead() and inst.sg:HasStateTag("charging") then
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
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                if math.random() < 1 and not inst.justcharged then
                    inst.justcharged = true
                    inst.sg:GoToState("charge_start", inst.components.combat.target)
                    return
                end
            end
            if inst.justcharged then inst.justcharged = nil end
            return attackstate_animqueueover_fn(inst, ...)
        end
    end

    local states =
    {
        State{
            name = "charge_start",
            tags = {"charging", "busy", "canrotate"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.AnimState:SetDeltaTimeMultiplier(1.2)
                inst.Physics:Stop()
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
                if inst.components.rideable and inst.components.rideable:GetRider() then
                    inst:ApplyBuildOverrides(inst.components.rideable:GetRider().AnimState)
                end
                inst.sg:GoToState("charge", inst.sg.statemem.target)
            end,

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "charge",
            tags = {"charging", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.AnimState:SetDeltaTimeMultiplier(1.2)
                if not inst.AnimState:IsCurrentAnimation("run_loop") then
                    inst.AnimState:PlayAnimation("run_loop", true)
                end
            end,

            onupdate = function(inst, dt)
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT * 2.29 -- Should be equal to Rook.
                inst.components.locomotor:RunForward()
                if inst:IsAsleep() then
                    inst.sg:GoToState("idle")
                    return
                elseif dt > 0 then
                    local target = inst.sg.statemem.target
                    if target and target:IsValid() and inst:GetDistanceSqToInst(target) <= inst.components.combat:CalcAttackRangeSq(target) then
                        inst.components.combat:ResetCooldown()
                        inst.sg:RemoveStateTag("busy")
                        if inst.components.combat:TryAttack(target) then inst.sg.mem.um_chargeattack = true end
                        inst.sg:GoToState("idle")
                    end
                end
            end,

            timeline =
            {
                TimeEvent(5 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(9 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(10 * FRAMES, PlayFootstep),
                TimeEvent(14 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(15 * FRAMES, function(inst) inst.sg:GoToState("idle") end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
            end,
        },
        State{
            name = "chargeattack",
            tags = {"busy", "charging", "attack"},

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
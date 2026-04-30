local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("beefalo", function(inst)
    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead()) and (inst.sg:HasStateTag("charging") or inst:HasTag("chargespeed")) then
                inst.sg:GoToState("chargeattack", data.target)
            else
                doattackeventhandler_fn(inst, data, ...)
            end
        end
    end

    local attackstate = inst.states["attack"]
    if attackstate then
        local attackstate_onenter = attackstate.onenter
        attackstate.onenter = function(inst, target, ...)
            if inst:HasTag("chargespeed") then
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
                inst:RemoveTag("chargespeed")
            end
            return attackstate_onenter(inst, target, ...)
        end
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
            tags = {"charging", "busy", "attack", "canrotate"},

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
                inst.sg:GoToState("charge")
                if inst.components.combat then -- Somehow combat was removed in a prior bug report.
                    inst.components.combat:ResetCooldown()
                end
            end,

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        State{
            name = "charge",
            tags = {"moving", "running", "charging", "busy", "attack"},

            onenter = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1.2)
                inst.components.combat:ResetCooldown()
                if not inst.AnimState:IsCurrentAnimation("run_loop") then
                    inst.AnimState:PlayAnimation("run_loop", true)
                end
                if not inst:HasTag("chargespeed") then inst:AddTag("chargespeed") end
                --inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end,

            onupdate = function(inst)
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT * 2.29 -- Should be equal to Rook.
                inst.components.locomotor:RunForward()
            end,

            timeline =
            {
                --TimeEvent(5 * FRAMES,  function(inst) inst.SoundEmitter:PlaySound(inst.effortsound) end),
                TimeEvent(5 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(9 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(10 * FRAMES, PlayFootstep),
                TimeEvent(14 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(15 * FRAMES, function(inst)
                    if inst:HasTag("chargespeed") then inst:RemoveTag("chargespeed") end
                    inst.sg:GoToState("idle")
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
            end,

            --[[events =
            {   
                EventHandler("animover", function(inst) inst.sg:GoToState("charge") end),
            },]]
        },
        State{
            name = "chargeattack",
            tags = {"busy", "charging", "attack"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target
                --inst.SoundEmitter:KillSound("charge")
                inst.SoundEmitter:PlaySound(inst.sounds.angry)
                inst.components.combat:StartAttack()
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("atk")
                if inst:HasTag("chargespeed") then
                    inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
                    inst:RemoveTag("chargespeed")
                end
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
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("leif", function(inst)
    local events =
    {
        EventHandler("snare", function(inst, target)
            if not inst.components.health:IsDead() then
                if inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute") or not inst.sg:HasStateTag("busy") then
                    inst.sg:GoToState("snare", target)
                else
                    inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_ABILITY_RETRY_CD)
                end
            end
        end),
        --EventHandler("bosshide", function(inst) inst.sg:GoToState("hide") end),
    }

    local states = {
        State{
            name = "snare",
            tags = {"attack", "busy", "snare"},

            onenter = function(inst, target)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("special")
                inst.sg.statemem.target = target and target:IsValid() and target or inst.components.combat.target
                inst.sg.statemem.summonattack = TUNING.DSTU.PINELINGS and inst.sg.statemem.target and inst.UMFindStump and inst:UMFindStump(inst.sg.statemem.target) or nil
                inst.components.timer:StartTimer("snare_cd", inst.sg.statemem.summonattack and 15 or 30)
            end,

            timeline =
            {
                TimeEvent(25 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/foley") end),
                TimeEvent(34 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/footstep") end),
                TimeEvent(35 * FRAMES, function(inst)
                    inst.components.combat:DoAttack(inst.sg.statemem.target)
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        if inst.sg.statemem.summonattack then
                            inst:SummonStumplings(inst.sg.statemem.target)
                        else
                            inst:SpawnSnare(inst.sg.statemem.target)
                        end
                    end
                end),
                TimeEvent(36 * FRAMES, function(inst) inst.sg:RemoveStateTag("busy") end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },

        --[[State{
            name = "hide",
            tags = {"hiding", "sleeping", "busy"},

            onenter = function(inst)
                inst:AddTag("notarget")
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("transform_tree", false)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/transform_VO")
                inst.sg:SetTimeout(10)
            end,

            events =
            {
                EventHandler("attacked", function(inst) if not inst.components.health:IsDead() then inst.sg:GoToState("wake") end end),
            },

            onexit = function(inst)
                inst:RemoveTag("notarget")
            end,

            ontimeout = function(inst)
                inst:RemoveTag("notarget")
                inst.sg:GoToState("wake")
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/foley") end),
                TimeEvent(25 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/foley") end),
            },
        },]]
    }

    for k, v in pairs(events) do
        assert(v:is_a(EventHandler), "Non-event added in mod events table!")
        inst.events[v.name] = v
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("leif", function(inst)
    local events =
    {
        EventHandler("um_snare", function(inst, target)
            if not inst.components.health:IsDead() then
                if inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute") or not inst.sg:HasStateTag("busy") then
                    inst.sg:GoToState("um_snare", target)
                else
                    inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_ABILITY_RETRY_CD)
                end
            end
        end),
        EventHandler("um_hide", function(inst)
            if not inst.components.health:IsDead()
                and (inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute") or not inst.sg:HasStateTag("busy")) then
                inst.sg:GoToState("um_hide")
            end
        end),
    }

    local states = {
        State{
            name = "um_snare",
            tags = {"attack", "busy", "um_snare"},

            onenter = function(inst, target)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("special")
                inst.sg.statemem.target = target
                inst.sg.statemem.summonattack = UM_CONFIG.PINELINGS and inst.sg.statemem.target and inst.UMFindStump and inst:UMFindStump(inst.sg.statemem.target) or nil
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
                            inst:UMSummonStumplings(inst.sg.statemem.target)
                        else
                            inst:UMSpawnSnare(inst.sg.statemem.target)
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

        State{
            name = "um_hide",
            tags = {"um_hiding", "busy", "nosleep", "nofreeze", "noelectrocute"},

            onenter = function(inst)
                inst.sg.statemem.um_scale = 1
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("transform_tree", false)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/transform_VO")
            end,

            onupdate = function(inst)
                if inst.sg.statemem.um_scale > .8 then
                    inst.sg.statemem.um_scale = inst.sg.statemem.um_scale - .01
                    inst.AnimState:SetScale(inst.sg.statemem.um_scale, inst.sg.statemem.um_scale)
                end
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/foley") end),
                TimeEvent(25 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/foley") end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        local scale = inst._scale or 1
                        ReplacePrefab(inst, "evergreen"..string.gsub(inst.prefab, "leif", "")..(scale >= 1.25 and "_tall" or scale >= 1 and "_normal" or scale <= .7 and "_short"))
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetScale(1, 1)
            end,
        },
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
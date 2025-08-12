local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("bearger", function(inst)
    local function ShakeIfClose_Footstep(inst)
        ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1, inst, 40)
    end

    local function DoFootstep(inst)
        if inst:IsStandState("quad") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_soft")
        else
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
            ShakeIfClose_Footstep(inst)
        end
    end

    local _OldAttackEvent = inst.events["doattack"].fn
    inst.events["doattack"].fn = function(inst, data, ...)
        if inst.rockthrow and not (inst.sg:HasStateTag("busy") or inst.components.health and inst.components.health:IsDead()) then
            inst.sg:GoToState("pre_shoot", data.target)
        else
            _OldAttackEvent(inst, data, ...)
        end
    end

    local states = {

        State{
            name = "pre_shoot",
            tags = {"busy", "canrotate"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.Physics:Stop()
                --inst.AnimState:SetBuild("bearger_build_old")
                inst.AnimState:PlayAnimation("taunt")
            end,

            onupdate = function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt") end),
                TimeEvent(9 * FRAMES, function(inst) DoFootstep(inst) end),
                TimeEvent(33 * FRAMES, function(inst) DoFootstep(inst) end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst:ClearBufferedAction() inst.sg:GoToState("shoot", inst.sg.statemem.target) end),
            },

            --[[onexit = function(inst)
                inst.AnimState:SetBuild("bearger_build")
            end,]]
        },
        
        State{
            name = "shoot",
            tags = {"attack", "canrotate", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.AnimState:SetBuild("bearger_build_old")
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("t")
            end,

            onupdate = function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,

            timeline =
            {
                TimeEvent(7 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/taunt", "taunt") 
                end),
                TimeEvent(25 * FRAMES, function(inst)
                    if inst.components.combat and inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.LaunchProjectile(inst, inst.sg.statemem.target)
                        local x, y, z = inst.Transform:GetWorldPosition()
                        SpawnPrefab("groundpound_fx").Transform:SetPosition(x, 0, z)
                        local sandpuff = SpawnPrefab("sand_puff")
                        sandpuff.Transform:SetPosition(x, 0, z)
                        sandpuff.Transform:SetScale(2, 2, 2)
                        inst.components.timer:StopTimer("RockThrow")
                        inst.components.timer:StartTimer("RockThrow", TUNING.BEARGER_NORMAL_GROUNDPOUND_COOLDOWN * 1.4)
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },

            onexit = function(inst)
                inst.AnimState:SetBuild("bearger_build")
            end,
        },
    }

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end
end)
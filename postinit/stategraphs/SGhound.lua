local env = env
GLOBAL.setfenv(1, GLOBAL)

local function ShowEyeFX(inst)
    if inst._eyeflames ~= nil then
        inst._eyeflames:set(true)
    end
end

local function HideEyeFX(inst)
    if inst._eyeflames ~= nil then
        inst._eyeflames:set(false)
    end
end

env.AddStategraphPostInit("hound", function(inst)
    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead())
                and ((inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) or not inst.sg:HasStateTag("busy")) then
                if inst:HasAnyTag("lightninghound", "glacialhound") and inst.lightningshot then
                    inst.sg:GoToState("charging_pre", data.target)
                elseif inst:HasTag("magmahound") and inst.lightningshot then
                    inst.sg:GoToState("burning_pre", data.target)
                elseif not inst:HasAnyTag("lightninghound", "magmahound") or data.target and data.target:IsValid() and inst:IsNear(data.target, 3) then
                    doattackeventhandler_fn(inst, data, ...)
                end
            end
        end
    end

    local events =
    {
        EventHandler("doleapattack", function(inst, data) -- Spore Hound
            if not (inst.sg:HasStateTag("busy") or inst.components.health and inst.components.health:IsDead()) and not (inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water) then
                --inst.sg:GoToState("leap_attack_pre", data.target)
                inst.sg:GoToState("leap_attack", data.target)
            end
        end),
    }

    local states =
    {
        State{
            name = "leap_attack_pre",
            tags = {"attack", "canrotate", "busy","leapattack"},

            onenter = function(inst, target)
                inst.components.locomotor:Stop()                    
                inst.AnimState:PlayAnimation("jump")
                inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack", {startpos = inst.sg.statemem.startpos, targetpos = inst.sg.statemem.targetpos}) end),
            },
        },
        State{
            name = "leap_attack",
            tags = {"attack", "canrotate", "busy", "leapattack"},

            onenter = function(inst, target)
                inst.sg.statemem.startpos = Vector3(inst.Transform:GetWorldPosition())
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
                --[[inst.sg.statemem.startpos = data.startpos
                inst.sg.statemem.targetpos = data.targetpos]]
                inst.components.locomotor:Stop()
                inst.Physics:SetActive(false)
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                inst.components.timer:StopTimer("lightningshot_cooldown")
                inst.components.timer:StartTimer("lightningshot_cooldown", 8 + math.random(3))
                inst.components.combat:StartAttack()
                inst.AnimState:PlayAnimation("jump_atk_loop")            
            end,

            onupdate = function(inst)
                if (inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water) then inst.sg:GoToState("idle") return end
                local percent = inst.AnimState:GetCurrentAnimationTime () / inst.AnimState:GetCurrentAnimationLength()
                local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
                local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
                inst.Transform:SetPosition(inst.sg.statemem.startpos.x + (xdiff * percent), 0, inst.sg.statemem.startpos.z + (zdiff * percent))
            end,

            onexit = function(inst)
                inst.Physics:SetActive(true)
                --inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.sg.statemem.startpos = nil
                inst.sg.statemem.targetpos = nil
            end,
            
            timeline =
            {
                TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
                --TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/hippo/huff_out") end),
            },
            
            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack_pst") end),
            },
        },
        State{
            name = "leap_attack_pst",
            tags = {"busy"},

            onenter = function(inst, target)
                inst.lightningshot = false
                --[[inst.components.timer:StopTimer("jumpability_cooldown")
                inst.components.timer:StartTimer("jumpability_cooldown", 8)]]
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("hit")
                local x, y, z = inst:GetPosition():Get()
                local ents = TheSim:FindEntities(x, y, z, 2.5, {"_combat"}, {"wall", "houndmound", "hound", "houndfriend"})
                for i, v in ipairs(ents) do
                    if v.components.combat then
                        v.components.combat:GetAttacked(inst, 25, nil)
                    end
                end
                SpawnPrefab("sporecloud_toad").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
            },
        },
        State{
            name = "charging_pre",
            tags = {"attack", "busy", "canrotate"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charging_loop") end),
            },
        },
        State{
            name = "charging_loop",
            tags = {"busy", "canrotate", "charging"},

            onenter = function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.pant)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_loop", true)
                inst:Charge()
                local timeouttime = inst:HasTag("lightninghound") and 4 + math.random() or 1
                inst.sg:SetTimeout(timeouttime)
            end,

            onexit = function(inst)
                inst.lightningshot = false
                inst.components.timer:StopTimer("lightningshot_cooldown")
                inst.components.timer:StartTimer("lightningshot_cooldown", 6 + math.random())
                inst:CancelCharge()
            end,

            ontimeout = function(inst)
                inst:CancelCharge()
                inst.sg:GoToState("charging_pst")
            end,
        },
        State{
            name = "charging_pst",
            tags = {"attack", "busy", "canrotate"},

            onenter = function(inst)
                inst.foogley = 0
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState(inst:HasTag("lightninghound") and "howl_attack" or "ice_howl_attack") end),
            },
        },
        State{
            name = "howl_attack",
            tags = {"attack", "busy", "howling"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("howl")
            end,

            timeline =
            {
                TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.howl) end),
                TimeEvent(15 * FRAMES, function(inst) 
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.inkpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
        State{
            name = "ice_howl_attack",
            tags = {"attack", "busy", "howling"},

            onenter = function(inst, target)
                if not inst.tripleshot then inst.tripleshot = 1 end
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                --inst.AnimState:PlayAnimation("taunt")
                inst.AnimState:PlayAnimation("atk_pre")
            end,

            timeline =
            {
                TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
                TimeEvent(5 * FRAMES, function(inst) 
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
            },

            events =
            {
            
                EventHandler("animover", function(inst) 
                    if inst.tripleshot < 3 then
                        inst.tripleshot = inst.tripleshot + 1
                        inst.sg:GoToState("ice_howl_attack") 
                    else
                        inst.tripleshot = nil
                        inst.sg:GoToState("idle") 
                    end
                end),
            },
        },
        State{
            name = "burning_pre",
            tags = {"attack", "busy", "canrotate"},

            onenter = function(inst)
                inst.Physics:Stop()
                ShowEyeFX(inst)
                inst.AnimState:PlayAnimation("scared_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("burning_loop") end),
            },
        },
        State{
            name = "burning_loop",
            tags = {"busy", "canrotate", "charging"},
            onenter = function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.pant)
                inst.Physics:Stop()
                ShowEyeFX(inst)
                inst.AnimState:PlayAnimation("burningup", true)
                inst:Charge()
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                end
                inst.sg:SetTimeout(1+math.random())
            end,
            
            onexit = function(inst)
                inst.lightningshot = false
                inst.components.timer:StopTimer("lightningshot_cooldown")
                inst.components.timer:StartTimer("lightningshot_cooldown", 6 + math.random())
                inst:CancelCharge()
            end,
            
            ontimeout = function(inst)
                inst:CancelCharge()
                inst.sg:GoToState("burning_pst")
            end,
        },
        State{
            name = "burning_pst",
            tags = {"attack", "busy", "canrotate"},

            onenter = function(inst)
                inst.foogley = 0
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("burning_howl_attack") end),
            },
        },
        State{
            name = "burning_howl_attack",
            tags = {"attack", "busy", "howling", "canrotate"},

            onenter = function(inst, target)
                ShowEyeFX(inst)
                --inst.Transform:SetFourFaced()
                inst.foogley = inst.foogley + 1 or 0
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("belch")
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,

            timeline =
            {
                TimeEvent(0, function(inst)  inst.SoundEmitter:PlaySound(inst.sounds.howl) end),
                TimeEvent(3 * FRAMES, function(inst)
                    --[[if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                        inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    end]]
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.inkpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
                TimeEvent(6 * FRAMES, function(inst) 
                    --[[if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                        inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    end]]
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.inkpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
                TimeEvent(9 * FRAMES, function(inst) 
                    --[[if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                        inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    end]]
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.inkpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
                TimeEvent(12 * FRAMES, function(inst) 
                    --[[if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                        inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    end]]
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                        inst.sg.statemem.inkpos = Vector3(inst.sg.statemem.target.Transform:GetWorldPosition())
                        inst:LaunchProjectile(inst.sg.statemem.target)
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) 
                    if inst.foogley < 6 then
                        inst.sg:GoToState("howl_attack")
                    else
                        inst.foogley = 0
                        inst.sg:GoToState("idle")
                    end
                 end),
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
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)

local function ArtificialLocomote(inst, destination, speed) --Locomotor is basically running a similar code anyhow, this bypasses any physics interactions preventing
    if destination and speed then --our locomote from working... Inconsistencies in when the entity is supposed to walk forward led to this.
        speed = speed * FRAMES
        local hypoten = math.sqrt(inst:GetDistanceSqToPoint(destination))
        local x, y, z = inst.Transform:GetWorldPosition()
        local x_final, y_final, z_final
        local speedmult = inst.components.locomotor ~= nil and inst.components.locomotor:GetSpeedMultiplier() or 1
        x_final = ((destination.x - x) / hypoten) * (speed * speedmult) + x
        z_final = ((destination.z - z) / hypoten) * (speed * speedmult) + z
        inst.Transform:SetPosition(x_final, y, z_final)
    end
end

local function FindFarLandingPoint(inst, destination) --This makes the geese aim for a point behind the player instead of where the player is at.
    if destination then --If it aimed directly at the player, it'll do something similar to the bugged version.
        inst.hopPoint = destination
        local hypoten = math.sqrt(inst:GetDistanceSqToPoint(destination))
        local x, y, z = inst.Transform:GetWorldPosition()
        local x_far, z_far
        x_far = ((destination.x - x) / hypoten) * 20 + x --20 is arbitrary, another number could be used if desired, if it is low enough it may make m/goose undershoot the player too.
        z_far = ((destination.z - z) / hypoten) * 20 + z
        inst.hopPoint.x = x_far
        inst.hopPoint.z = z_far
    end
end

local function ShakeIfClose(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, .35, .02, 1, inst, 40)
end

env.AddStategraphPostInit("moose", function(inst)
    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead())
                and ((inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) or not inst.sg:HasStateTag("busy")) then
                if inst:HasTag("mothergoose") then
                    if inst.CanDisarm and not inst.tornado_tracking then
                        inst.sg:GoToState("disarm")
                    elseif inst.TornadoAttack then
                        inst.sg:GoToState("tornadostorm")
                    else
                        inst.sg:GoToState("attack")
                    end
                else
                    doattackeventhandler_fn(inst, data, ...)
                end
            end
        end
    end
    
    local attackstate = inst.states["attack"]
    if attackstate then
        local attackstate_timeline4 = inst.states["attack"].timeline[4]
        if attackstate_timeline4 then
            local attackstate_timeline4_fn = inst.states["attack"].timeline[4].fn
            inst.states["attack"].timeline[4].fn = function(inst, ...)
                local ret = attackstate_timeline4_fn(inst, ...)
                if inst:HasTag("mothergoose") and inst.components.health:GetPercent() <= .66 and not inst.components.timer:TimerExists("TornadoAttack") then
                    inst.components.timer:StartTimer("TornadoAttack", 20)
                end
                return ret
            end
        end
    end

    local actionhandlers =
    {
        ActionHandler(ACTIONS.LAYEGG, function(inst) return not inst.components.combat:HasTarget() and "layegg2" end)
    }

    local events =
    {
        EventHandler("locomote", function(inst)
            if (not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("superhop")) then return end
            if not inst.components.locomotor:WantsToMoveForward() then
                if not inst.sg:HasStateTag("idle") then
                    inst.sg:GoToState("idle", {softstop = true})
                end
            else
                local target = inst.components.combat and inst.components.combat.target
                if TUNING.DSTU.HARDER_MOOSE and not inst.sg:HasStateTag("hopping") and inst.superhop and target and math.random() < .5 then
                    inst.sg:GoToState("hopatk")
                elseif not inst.sg:HasStateTag("hopping") then
                    inst.sg:GoToState("hop")
                end
            end
        end),
    }

    local states = {
        State{
            name = "hopatk",
            tags = {"attack", "moving", "hopping", --[["canrotate",]] "busy", "superhop"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("hopatk")
                PlayFootstep(inst)
                if inst.doublesuperhop then
                    inst.doublesuperhop = inst.doublesuperhop + 1
                else
                    inst.doublesuperhop = 1
                end
                local target = inst.components.combat.target
                if target and target.Transform then
                    inst:ForceFacePoint(target.Transform:GetWorldPosition())
                    FindFarLandingPoint(inst, inst.components.combat.target:GetPosition())
                else
                    FindFarLandingPoint(inst, inst:GetPosition())
                end
                if math.random() <= .3 or inst.doublesuperhop > 1 then
                    inst.doublesuperhop = 0
                    inst.superhop = false
                    inst.components.timer:StopTimer("SuperHop")
                    inst.components.timer:StartTimer("SuperHop", 10)
                end
            end,

            timeline =
            {
                TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/preen") end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/swhoosh")
                    inst.sg:GoToState("hopatk_loop")
                end),
            },
        },
        State{
            name = "hopatk_loop",
            tags = {"attack", "moving", "hopping", "busy", "superhop"},

            onenter = function(inst)
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.WORLD)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/attack")
                inst.AnimState:PlayAnimation("hopatk_loop", true)
                inst.flapySound = inst:DoPeriodicTask(6 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap")
                end)
                local target = inst.components.combat.target
                local distsq = target and target:IsValid() and inst:GetDistanceSqToInst(target) / 10 or 15
                if distsq and distsq > 7.5 then
                    distsq = 7.5
                end
                inst.hop_speed = distsq + 7.5
                --inst.sg:SetTimeout(.5)
            end,

            onexit = function(inst)
                inst.Physics:CollidesWith(COLLISION.OBSTACLES)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                inst.Physics:CollidesWith(COLLISION.GIANTS)
                if inst.flapySound then
                    inst.flapySound:Cancel()
                    inst.flapySound = nil
                end
            end,

            onupdate = function(inst)
                ArtificialLocomote(inst, inst.hopPoint, inst.hop_speed or 15)
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("landatk") end),
            },
        },
        State{
            name = "landatk",
            tags = {"attack", "moving", "hopping", "busy", "superhop"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("land")
                PlayFootstep(inst)
                ShakeIfClose(inst)
            end,

            timeline =
            {
                TimeEvent(2 * FRAMES, function(inst)
                    inst.components.groundpounder:GroundPound()
                    inst.components.combat:DoAreaAttack(inst, TUNING.MOOSE_ATTACK_RANGE * 1.3, nil, nil, nil, { "moose", "mossling" }) --GroundPound Is purely visual
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/land")
                end)
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle", {softstop = true}) end),
            },
        },
        State{
            name = "tornadostorm",
            tags = {"busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("takeoff_pre_diagonal")
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.AnimState:PushAnimation("tornadoattack", false)
                inst.TornadoAttack = false
                if math.random() > .5 then
                    inst.tornadotype = true
                else
                    inst.tornadotype = false
                end
                local tornado1 = SpawnPrefab("mothergoose_tornado")
                --tornado1.Transform:SetPosition(inst.Transform:GetWorldPosition())
                --tornado1.rotation = 90
                --tornado1.spawnmore = false
                tornado1.WINDSTAFF_CASTER = inst
                tornado1.components.linearcircler:SetCircleTarget(inst)
                tornado1.components.linearcircler:Start()
                tornado1.components.linearcircler.randAng = 0
                tornado1.components.linearcircler.clockwise = inst.tornadotype
                if inst.tornadotype then
                    tornado1.AnimState:SetMultColour(1, 1, .3, 1)
                end
                --tornado1.Physics:Teleport(0, 0, 0)
                --inst:AddChild(tornado1)
                --tornado1.Physics:Stop()
                local tornado2 = SpawnPrefab("mothergoose_tornado")
                --tornado2.Transform:SetPosition(inst.Transform:GetWorldPosition())
                --tornado2.rotation = 180
                --tornado2.spawnmore = false
                tornado2.WINDSTAFF_CASTER = inst
                tornado2.components.linearcircler:SetCircleTarget(inst)
                tornado2.components.linearcircler:Start()
                tornado2.components.linearcircler.randAng = .25
                tornado2.components.linearcircler.clockwise = inst.tornadotype
                if inst.tornadotype then
                    tornado2.AnimState:SetMultColour(1, 1, .3, 1)
                end
                --tornado2.Physics:Teleport(0, 0, 0)
                --inst:AddChild(tornado2)
                --tornado2.Physics:Stop()
                local tornado3 = SpawnPrefab("mothergoose_tornado")
                --tornado3.Transform:SetPosition(inst.Transform:GetWorldPosition())
                --tornado3.rotation = 270
                --tornado3.spawnmore = false
                tornado3.WINDSTAFF_CASTER = inst
                tornado3.components.linearcircler:SetCircleTarget(inst)
                tornado3.components.linearcircler:Start()
                tornado3.components.linearcircler.randAng = .5
                tornado3.components.linearcircler.clockwise = inst.tornadotype
                if inst.tornadotype then
                    tornado3.AnimState:SetMultColour(1, 1, .3, 1)
                end
                --tornado3.Physics:Teleport(0, 0, 0)
                --inst:AddChild(tornado3)
                --tornado3.Physics:Stop()
                local tornado4 = SpawnPrefab("mothergoose_tornado")
                --tornado4.Transform:SetPosition(inst.Transform:GetWorldPosition())
                --tornado4.rotation = 0
                --tornado4.spawnmore = false
                tornado4.WINDSTAFF_CASTER = inst
                tornado4.components.linearcircler:SetCircleTarget(inst)
                tornado4.components.linearcircler:Start()
                tornado4.components.linearcircler.randAng = .75
                tornado4.components.linearcircler.clockwise = inst.tornadotype
                if inst.tornadotype then
                    tornado4.AnimState:SetMultColour(1, 1, .3, 1)
                end
                --tornado4.Physics:Teleport(0, 0, 0)
                --inst:AddChild(tornado4)
                --tornado4.Physics:Stop()
                inst.tornado_tracking = true
            end,

            timeline =
            {
                TimeEvent(9 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
                TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/taunt") end),
                TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
                TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
                TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
                TimeEvent(27 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
                TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/flap") end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
            },
        }
    }

    for k, v in pairs(events) do
        assert(v:is_a(EventHandler), "Non-event added in mod events table!")
        inst.events[v.name] = v
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

    for k, v in pairs(actionhandlers) do
        assert(v:is_a(ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end
end)
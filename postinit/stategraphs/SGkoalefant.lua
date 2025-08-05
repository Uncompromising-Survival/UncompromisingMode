local env = env
GLOBAL.setfenv(1, GLOBAL)

local function isplayer(ent)
    return ent and ent:HasTag("player") -- fix to friendly AOE: refer for later AOE mobs -Axe
end
    
env.AddStategraphPostInit("koalefant", function(inst)
    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead() or inst.sg:HasStateTag("electrocute")) and (inst.sg:HasStateTag("charging") or inst:HasTag("chargespeed")) then
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
            if target and target:IsValid() then inst.sg.statemem.target = target end
            inst.counterattack = false
            inst:DoTaskInTime(1.5, function(inst) inst.counterattack = true end)
            if inst:HasTag("chargespeed") then
                inst.components.locomotor.runspeed = TUNING.BEEFALO_RUN_SPEED.DEFAULT
                inst:RemoveTag("chargespeed")
            end
            return attackstate_onenter(inst, target, ...)
        end
        local attackstate_timeline1 = attackstate.timeline[1]
        if attackstate_timeline1 then
            attackstate_timeline1.fn = function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end
        end
        local attackstate_animqueueover_fn = attackstate.events["animqueueover"].fn
        attackstate.events["animqueueover"].fn = function(inst, ...)
            if inst.components.combat.target and inst.components.combat.target:IsValid() then
                local chance = math.random()
                if chance < .33 and not inst.justcharged then
                    inst.justcharged = true
                    inst.sg:GoToState("charge_start", inst.components.combat.target)
                    return
                else
                    if inst.justcharged then inst.justcharged = nil end
                    if chance > .77 and inst.disarmattack and inst.components.combat:CanHitTarget(inst.components.combat.target) then
                        inst.sg:GoToState("disarm")
                        return
                    end
                end
            end
            if inst.justcharged then inst.justcharged = nil end
            return attackstate_animqueueover_fn(inst, ...)
        end
    end

    local attackedeventhandler = inst.events["attacked"]
    if attackedeventhandler then
        local attackedeventhandler_fn = attackedeventhandler.fn
        attackedeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead()) then
                if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
                    return
                elseif not inst.sg:HasAnyStateTag("attack", "busy", "electrocute", "charging") and math.random() > .66
                    and inst.components.combat.target and 4 > inst:GetDistanceSqToInst(inst.components.combat.target) and inst.counterattack then
                    inst.sg:GoToState("stomp") 
                    return
                end
            end
            return attackedeventhandler_fn(inst, data, ...)
        end
    end

    local function DisarmTarget(inst, target)
        local item = nil
        if target and target.components.inventory and not target:HasTag("stronggrip") then
            item = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        end
        if item and not item:HasTag("nosteal") and item.Physics then
            target.components.inventory:DropItem(item)
            local x, y, z = item:GetPosition():Get()
            y = .1
            item.Physics:Teleport(x, y, z)
            local hp = target:GetPosition()
            local pt = inst:GetPosition()
            local vel = (hp - pt):GetNormalized()
            local speed = 5 + (math.random() * 2)
            local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
            item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
        end
        inst.CanDisarm = false
    end

    local states = {
        State{
            name = "charge_start",
            tags = {"charging", "busy", "attack", "canrotate"},
            
            onenter = function(inst, target)
                inst.sg.statemem.target = target ~= nil and target:IsValid() and target or inst.components.combat and inst.components.combat.target
                inst.Physics:Stop()
                inst.components.locomotor:StopMoving()
                inst.components.combat:ResetCooldown()
                inst.AnimState:PlayAnimation("paw")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            end,

            onupdate = function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,

            timeline =
            {
                TimeEvent(5 * FRAMES, PlayFootstep),
                TimeEvent(10 * FRAMES, PlayFootstep),
            },        

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charge") end),
            },
        },
        State{  
            name = "charge",
            tags = {"moving", "running", "charging", "busy", "attack"},

            onenter = function(inst)
                inst.components.combat:ResetCooldown()
                if not inst.AnimState:IsCurrentAnimation("run_loop") then
                    inst.AnimState:PlayAnimation("run_loop", true)
                end
                if not inst:HasTag("chargespeed") then inst:AddTag("chargespeed") end
                --inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            end,

            onupdate = function(inst)
                inst.components.locomotor.runspeed = 7 * 2.29 -- Should be equal to Rook.
                inst.components.locomotor:RunForward()
            end,

            timeline =
            {
                --TimeEvent(5 * FRAMES,  function(inst) inst.SoundEmitter:PlaySound(inst.effortsound) end),
                TimeEvent(5 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(9 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(10 * FRAMES, PlayFootstep),
                TimeEvent(14 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(15 * FRAMES, PlayFootstep),
                TimeEvent(24 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(25 * FRAMES, PlayFootstep),
                TimeEvent(29 * FRAMES, function(inst) SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition()) end),
                TimeEvent(30 * FRAMES, function(inst)
                    if inst:HasTag("chargespeed") then inst:RemoveTag("chargespeed") end
                    inst.sg:GoToState("idle")
                end),
            },

            onexit = function(inst)
                inst.components.locomotor.runspeed = 7
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
                inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
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
        State{
            name = "disarm",
            tags = {"attack", "busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scare")
                inst.disarmattack = false
                inst:DoTaskInTime(20, function(inst) inst.disarmattack = true end)
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
                    if inst.components.combat.target and inst.components.combat.target.ShakeCamera then
                        inst.components.combat.target:ShakeCamera(CAMERASHAKE.FULL, .75, .01, 1.5, 40)
                    end
                end),
                TimeEvent(10 * FRAMES, function(inst) DisarmTarget(inst, inst.components.combat.target) end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
            },

        },
        --[[State{  
            name = "stomp_pre",
            tags = {"busy", "attack"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.components.locomotor:StopMoving()
                inst.components.combat:ResetCooldown()
                inst.AnimState:PlayAnimation("stomp_pre")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("stomp") end),
            },
        },]]
        State{
            name = "stomp",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = target
                inst.SoundEmitter:PlaySound("dontstarve/creatures/koalefant/angry")
                inst.components.combat:StartAttack()
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("stompatk", false)
                if inst:HasTag("chargespeed") then
                    inst.components.locomotor.runspeed = 7
                    inst:RemoveTag("chargespeed")
                end
                inst.components.combat:SetAreaDamage(4, 1, isplayer)
            end,

            timeline=
            {
                TimeEvent(36 * FRAMES, function(inst) 
                    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.components.combat:DoAttack(inst.sg.statemem.target) 
                    local ring = SpawnPrefab("groundpoundring_fx")
                    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    ring.Transform:SetScale(.7, .7, .7)
                end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.components.combat:ResetCooldown()
                    inst.components.combat:SetAreaDamage()
                    inst.sg:GoToState("idle")
                end),
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
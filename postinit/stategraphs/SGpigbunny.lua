local env = env
GLOBAL.setfenv(1, GLOBAL)

local KNOCKBACK_CANT_TAGS = {"fat_gang", "foodknockbackimmune", "heavybody"}
local KNOCKBACK_ARMOR_CANT_TAGS = {"heavyarmor", "knockback_protection"}
local function DoCounterAttack(inst)
    local target = inst.components.combat.target
    if target and distsq(target:GetPosition(), inst:GetPosition()) <= inst.components.combat:CalcAttackRangeSq(target) then
        target.components.combat:GetAttacked(inst, 33)

        local inventory = target.components.inventory
        local bodyslot = inventory and inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if not target:HasAnyTag(KNOCKBACK_CANT_TAGS) and not target.sg:HasStateTag("shell") and not (target.components.rider and target.components.rider:IsRiding())
            and (not bodyslot or not bodyslot:HasAnyTag(KNOCKBACK_ARMOR_CANT_TAGS)) then
            target:PushEvent("knockback", { knocker = inst, radius = 150, strengthmult = 1 })
        end
    end
end

env.AddStategraphPostInit("pig", function(inst)
    local events =
    {
        EventHandler("doattack", function(inst, data)
            if inst:HasTag("pigattacker") and data.target:HasTag("pigattacker") and not data.target:HasTag("werepig") or inst:HasTag("manrabbit") and data.target:HasTag("manrabbit") then
                inst.sg:GoToState("refuse", data.target)
                inst.components.combat:SetTarget(nil)
            else
                local nstate = "attack"
                if inst.sg:HasStateTag("charging") then
                    nstate = "charge_attack"
                elseif inst.sg.mem.wantstocounter then
                    inst.sg.mem.wantstocounter = nil
                    nstate = "counterattack_pre"
                end
                if not (inst.components.health and inst.components.health:IsDead())
                    and not inst.sg:HasStateTag("busy") then
                    inst.sg:GoToState(nstate)
                end
                --inst.sg:GoToState("attack", data.target)
            end
        end),
    }

    local _OldAttackedEvent = inst.events["attacked"].fn
    inst.events["attacked"].fn = function(inst, data, ...)
        if not (inst.components.health and inst.components.health:IsDead()) then
            if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
                return
            elseif inst:HasTag("pigattacker") and not inst:HasTag("werepig") and not inst.sg:HasAnyStateTag("counter", "caninterrupt", "electrocute") then
                if inst.sg.mem.wantstocounter then
                    inst.components.combat:ResetCooldown()
                    return
                end
                if inst.counter then
                    inst.counter = inst.counter + 1
                    if inst.countertask then
                        inst.countertask:Cancel()
                        inst.countertask = nil
                    end
                else
                    inst.counter = 1
                end

                inst.countertask = inst:DoTaskInTime(10, function(inst) inst.counter = 0 end)

                if inst.counter and inst.counter >= math.random(3, 4) and (data.attacker and data.attacker:IsValid() and inst:GetDistanceSqToInst(data.attacker) < 5^2) then -- Added a range check
                    if inst.countertask then
                        inst.countertask:Cancel()
                        inst.countertask = nil
                    end
                    inst.counter = 0
                    inst.sg.mem.wantstocounter = true
                    inst.components.combat:ResetCooldown()
                    return
                end
            end
        end
        _OldAttackedEvent(inst, data, ...)
    end

    local states =
    {
        State {
            name = "counterattack_pre",
            tags = {"attack", "busy", "counter"},

            onenter = function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
                inst.components.combat:StartAttack()
                inst.Physics:Stop()
                inst.sg:SetTimeout(0.5)
                inst.AnimState:PlayAnimation("idle_angry")
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("counterattack")
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("counterattack")
                end),
            },
        },
        State{
            name = "counterattack",
            tags = {"attack", "busy", "counter"},

            onenter = function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/pig/attack")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                inst.components.combat:StartAttack()
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("counter_atk")
            end,

            timeline =
            {
                TimeEvent(9 * FRAMES, function(inst)
                    DoCounterAttack(inst)

                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("counter")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("charge_pre")
                end),
            },
        },
        State{
            name = "charge_antic_pre",
            tags = {"attack", "busy", "moving", "charging", "busy", "atk_pre", "canrotate"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("paw_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charge_antic_loop") end),
            },
        },
        State{
            name = "charge_antic_loop",
            tags = {"attack", "busy", "moving", "charging", "busy", "atk_pre", "canrotate"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("paw_loop", true)
                inst.sg:SetTimeout(1.5)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("charge_pre")
                inst:PushEvent("attackstart")
            end,
        },
        State{
            name = "charge_pre",
            tags = {"busy", "charging", "moving", "running"},

            onenter = function(inst)
                inst.components.locomotor:RunForward()
                inst.AnimState:PlayAnimation("charge_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charge_loop") end),
            },
        },
        State{
            name = "charge_loop",
            tags = {"charging", "moving", "running"},

            onenter = function(inst)
                inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED + 8
                inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED + 8

                inst.components.locomotor:WalkForward()
                inst.AnimState:PlayAnimation("charge_loop")
            end,

            onexit = function(inst)
                inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED
                inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charge_attack") end),
            },
        },
        State{
            name = "charge_pst",
            tags = {"canrotate", "idle"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("charge_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
        State{
            name = "charge_attack",
            tags = {"chargingattack"},

            onenter = function(inst)
                inst.components.combat:StartAttack()
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("charge_atk")
                inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/wild_boar/charge_attack")
            end,

            timeline =
            {
                TimeEvent(12 * FRAMES, function(inst)
                    inst.components.combat:DoAttack()
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
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
end)


local ARC = 90 * DEGREES --degrees to each side
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "notarget", "noattack","werepig"}

local function DoArcAttack(inst, dist, radius, heavymult, mult, forcelanded, targets)
    inst.components.combat.ignorehitrange = true
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation() * DEGREES
    local x0, z0
    if dist ~= 0 then
        if dist > 0 and ((mult ~= nil and mult > 1) or (heavymult ~= nil and heavymult > 1)) then
            x0, z0 = x, z
        end
        x = x + dist * math.cos(rot)
        z = z - dist * math.sin(rot)
    end
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and
            not (targets ~= nil and targets[v]) and -- For some reason this is failing when the werepig is targetting wilson, it doesn't fail for widow or bearger...
            v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead()) --and not v.prefab == "moonhound" -- No tags to grab onto for moonhounds
        then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and
                DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC and
                inst.components.combat:CanTarget(v)
            then
                inst.components.combat:DoAttack(v)
                inst.hit_other = true
            end
        end
    end
    inst.components.combat.ignorehitrange = false
end

local werepigs = {"moonpig","werepig"}
for i,werepig in ipairs(werepigs) do

                
    env.AddStategraphPostInit(werepig, function(inst)
        local states = {
            State{
                name = "attack",
                tags = { "attack", "busy" },

                onenter = function(inst,target)
                    inst.components.combat:StartAttack()
                    inst.AnimState:PlayAnimation("were_atk_pre")
                    inst.AnimState:PushAnimation("were_atk", false)
                    inst.hit_other = nil
                    inst.sg.statemem.original_target = target and target or inst.components.combat.target
                end,

                timeline =
                {
                    TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/werepig/attack") end),
                    TimeEvent(16*FRAMES, function(inst) DoArcAttack(inst, 0, 3, nil, nil, nil, inst.sg.statemem.targets) 
                    if not inst.hit_other then
                        inst:PushEvent("onmissother", { target = inst.sg.statemem.original_target })
                    end
                    --inst.Physics:Stop() -- May consider stopping movement here...
                end),
                },

                events =
                {
                    EventHandler("animqueueover", function(inst)
                        inst.sg:GoToState(
                            not inst.components.combat:HasTarget() and
                            math.random() < 0.3 and
                            "howl" or
                            "idle")
                    end),
                },
                onexit = function(inst)
                    inst.Physics:Stop()
                    inst.attacked_run_cd = inst:DoTaskInTime(0.5,function(inst)
                        inst.attacked_run_cd:Cancel()
                        inst.attacked_run_cd = nil
                    end)
                end,
            },
        }
        
        --If the werepig is waiting to run away, then manages to reach you, causing him to stand still, stop the dotaskintime that tells the werepig to not run away
        --local idlestate = inst.states["idle"]
        --if idlestate then
            --local idlestate_onenter = idlestate.onenter
            --idlestate.onenter = function(inst, target, ...)
                --if inst.attacked_run_cd and inst.components.combat.target and inst.components.combat:CanHitTarget(inst.components.combat.target) then
                    --inst.attacked_run_cd:Cancel()
                    --inst.attacked_run_cd = nil
                --end
                --return idlestate_onenter(inst, ...)
            --end
        --end
        
        local events = -- Klei's implementation (CommonHandlers.OnAttacked(nil, TUNING.PIG_MAX_STUN_LOCKS),) is not working after the werepig finishes his transformation, this implements it in a different way to fix that.
        {
            EventHandler("attacked", function(inst, data)
                if not (inst.components.health and inst.components.health:IsDead()) then
                    if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
                        return
                    elseif inst.components.combat.target and not inst.components.combat:InCooldown() and inst.components.combat:CanHitTarget(inst.components.combat.target) and not inst.sg:HasAnyStateTag("attack", "busy", "electrocute") then
                    -- Werepigs will immediately try to attack if they can
                        inst.sg:GoToState("attack")
                    elseif not inst.sg:HasAnyStateTag("attack", "busy", "electrocute") and inst.attacked_run_cd then -- only play the animation if he can't run away
                        inst.sg:GoToState("hit")
                    end
                end
            end),
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
end
local easing = require("easing")
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("spider", function(inst)
    local function ShadowFade(inst)
        inst.scaleFactor = inst.scaleFactor - 0.01
        inst.Transform:SetScale(inst.scaleFactor, inst.scaleFactor, inst.scaleFactor)
        if inst.scaleFactor < 0.05 then
            inst:Remove()
        end
    end
    
    local function WebMortar(inst,angle) -- Same function as Hooded Widow, want to each new players about the attack w/out having to previously fight Hooded Widow
        if inst.components.combat.target ~= nil then
            local target = inst.components.combat.target
            local x, y, z = inst.Transform:GetWorldPosition()
            local projectile = SpawnPrefab("web_mortar")
            projectile.Transform:SetPosition(x,y,z)
            local scaleFactor = Lerp(.5, 1.5, 1)
            projectile.shadow = SpawnPrefab("warningshadow")
            projectile.shadow.scaleFactor = scaleFactor
            projectile.shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
            projectile.shadow = projectile.shadow:DoPeriodicTask(FRAMES, ShadowFade, nil, 5)    
            local a, b, c = target.Transform:GetWorldPosition()
            local targetpos = target:GetPosition()
            if not angle then
                angle = 0
            end
            local theta = inst.Transform:GetRotation() + angle
            theta = theta*DEGREES
            targetpos.x = targetpos.x + 15 * math.cos(theta)
            targetpos.z = targetpos.z - 15 * math.sin(theta)
            
            projectile.components.complexprojectile:SetHorizontalSpeed(20)
            projectile.components.complexprojectile:Launch(targetpos, inst, inst)
        end
    end
    
    local function SoundPath(inst, event)
        local creature = "spider"

        if inst:HasTag("spider_moon") then
            return "turnoftides/creatures/together/spider_moon/" .. event
        elseif inst:HasTag("spider_warrior") then
            creature = "spiderwarrior"
        elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
            creature = "cavespider"
        else
            creature = "spider"
        end
        return "dontstarve/creatures/" .. creature .. "/" .. event
    end

    local _OldAttackEvent = inst.events["doattack"] and inst.events["doattack"].fn
    if _OldAttackEvent then
        inst.events["doattack"].fn = function(inst, data)
            if inst.prefab == "spider_trapdoor_hooded" and not inst.web_cd and inst.hooded then -- *Hooded* Trapdoor spider web attack
                inst.sg:GoToState("spit_web")
                return
            end
            if inst.prefab == "spider_trapdoor" or inst.prefab == "spider_trapdoor_hooded" then
                inst.sg:GoToState("trapdoor_attack")
            end
            _OldAttackEvent(inst, data)
        end
    end

    local _OldAttackedEvent = inst.events["attacked"] and inst.events["attacked"].fn
    if _OldAttackedEvent then
        inst.events["attacked"].fn = function(inst)
            if not inst.components.health:IsDead() and TUNING.DSTU.SPIDERWARRIORCOUNTER and inst:HasTag("spider_warrior") and not inst:HasTag("trapdoorspider")
                and not (inst.sg:HasStateTag("caninterrupt") or inst:HasTag("forcestunned")) then
                if not inst.sg:HasAnyStateTag("attack", "evade") and inst.components.combat.target then -- don't interrupt attack or exit shield
                    inst.sg:GoToState("evade_loop")
                end
                return
            end
            _OldAttackedEvent(inst)
        end
    end

    -- Remove when Klei fixes this!
    local healstate = inst.states["heal"]
    if healstate then
        local healstate_onenter = inst.states["heal"].onenter
        healstate.onenter = function(inst, target, ...)
            healstate_onenter(inst, target, ...)
            inst.SoundEmitter:PlaySound("webber1/creatures/spider_cannonfodder/heal") -- Missing Content Fix!
        end
    end
    --

    --[[local events =
{    
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if inst:HasTag("spider_warrior") or inst:HasTag("spider_spitter") or inst:HasTag("spider_moon") then
                if not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("evade") then -- don't interrupt attack or exit shield
                    if inst:HasTag("spider_warrior") and not inst:HasTag("trapdoorspider") and inst.components.combat.target ~= nil and TUNING.DSTU.SPIDERWARRIORCOUNTER then
                    inst.sg:GoToState("evade_loop")
                    else
                    inst.sg:GoToState("hit") -- can still attack
                    end
                end
            elseif not inst.sg:HasStateTag("shield") then
                inst.sg:GoToState("hit_stunlock")  -- can't attack during hit reaction
            end
        end
    end),
    EventHandler("doattack", function(inst, data) 
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            --target CAN go invalid because SG events are buffered
            if inst:HasTag("spider_warrior") or inst:HasTag("spider_regular") then
                inst.sg:GoToState(
                    data.target:IsValid()
                    and not (inst:IsNear(data.target, TUNING.SPIDER_WARRIOR_MELEE_RANGE) or (TUNING.DSTU.REGSPIDERJUMP == false and inst:HasTag("spider_regular")))
                    and "warrior_attack" --Do leap attack
                    or "attack",
                    data.target
                )
            elseif inst:HasTag("spider_spitter") then
                inst.sg:GoToState(
                    data.target:IsValid()
                    and not inst:IsNear(data.target, TUNING.SPIDER_SPITTER_MELEE_RANGE)
                    and "spitter_attack" --Do spit attack
                    or "attack",
                    data.target
                )
            elseif inst:HasTag("spider_moon") then
                inst.sg:GoToState(
                    data.target:IsValid()
                    and not inst:IsNear(data.target, TUNING.SPIDER_WARRIOR_MELEE_RANGE)
                    and "spike_attack"
                    or "attack",
                    data.target
                )
            else
                inst.sg:GoToState("attack", data.target)
            end
        end
    end),
    
}]]

    local states = {

        State{
        name = "trapdoor_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("trapdoor_atk")
            inst.sg.statemem.target = target
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "attack_grunt")) end),
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Jump")) end),
            TimeEvent(8*FRAMES, function(inst) inst.Physics:SetMotorVelOverride(20,0,0) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "Attack")) end),
            --TimeEvent(19*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(20*FRAMES,
                function(inst)
                    inst.components.combat:DoAttack(inst.sg.statemem.target)
                    inst.Physics:ClearMotorVelOverride()
                    inst.components.locomotor:Stop()
                end),
        },

        events=
        {
            EventHandler("animover", 
            function(inst) 
            inst.sg:GoToState("taunt")
            end),
        },
    },--[[
    State{
        name = "taunt",
        tags = {"busy","taunting"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(SoundPath(inst, "scream"))
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },]]
        State {
            name = "shield",
            tags = { "busy", "shield" },

            onenter = function(inst)
                --If taking fire damage, spawn fire effect.
                inst.components.health:SetAbsorptionAmount(TUNING.SPIDER_HIDER_SHELL_ABSORB)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("hide")
                inst.AnimState:PushAnimation("hide_loop")
                if inst.components.workable ~= nil then
                    inst.components.workable:SetWorkLeft(1)
                end
                inst:AddTag("hiding")
            end,

            onexit = function(inst)
                inst.components.health:SetAbsorptionAmount(0)
                if inst.components.workable ~= nil then
                    inst.components.workable:SetWorkLeft(0)
                end
                inst:RemoveTag("hiding")
            end,
        },
        State {
            name = "evade",
            tags = { "busy", "evade", "no_stun" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                --inst.AnimState:PlayAnimation("evade")
                --inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                --inst.Physics:SetMotorVelOverride(-20,0,0)
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.components.combat.target ~= nil then
                        inst.sg:GoToState("evade_loop")
                    else
                        inst.sg:GoToState("hit")
                    end
                end),
            },
        },

        State {
            name = "evade_loop",
            tags = { "busy", "evade", "no_stun" },


            onenter = function(inst)
                if inst ~= nil then
                    inst.sg:SetTimeout(0.1)
                    if inst.components.combat.target and inst.components.combat.target:IsValid() then
                        inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                    else
                        inst.sg:GoToState("hit")
                    end
                    inst.components.locomotor:Stop()
                    inst.AnimState:PlayAnimation("evade", true)
                    inst.Physics:SetMotorVelOverride(-30, 0, 0)
                    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                end
            end,
            --[[
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("evade_pst") 
            end ),
        },  
]]
            timeline =
            {
                TimeEvent(3 * FRAMES, function(inst) inst.Physics:SetMotorVel(-20, 0, 0) end),

            },
            ontimeout = function(inst)
                inst.sg:GoToState("evade_pst")
            end,

            onexit = function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
            end,
        },

        State {
            name = "evade_pst",
            tags = { "busy", "evade", "no_stun" },

            onenter = function(inst)
                if inst.components.combat.target and inst.components.combat.target:IsValid() then
                    inst:ForceFacePoint(inst.components.combat.target:GetPosition())
                end
                inst.components.locomotor:Stop()
                --inst.AnimState:PlayAnimation("evade_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.components.combat.target and inst.components.combat.target:IsValid() then

                        local JUMP_DISTANCE = 3

                        local distance = inst:GetDistanceSqToInst(inst.components.combat.target)
                        
                        if distance > JUMP_DISTANCE * JUMP_DISTANCE then
                            inst.sg:GoToState("warrior_attack", inst.components.combat.target)
                        else
                            inst.sg:GoToState("attack", inst.components.combat.target)
                        end
                    else
                        inst.sg:GoToState("idle")
                    end

                end),
            },

            onexit = function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
            end,
        },
        State{
            name = "spit_web",
            tags = {"attack", "busy", "spitting"},

            onenter = function(inst, target)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("atk")

                if target ~= nil and target:IsValid() then
                    inst.sg.statemem.target = target
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                
                inst.web_cd = true
                inst:DoTaskInTime(10,function(inst) inst.web_cd = nil end) -- Cooldown for the web attack, don't need to bother with a timer component
            end,

            onupdate = function(inst)
                if inst.sg.statemem.target ~= nil then
                    if inst.sg.statemem.target:IsValid() then
                        local pos = inst.sg.statemem.targetpos

                        pos.x, pos.y, pos.z = inst.sg.statemem.target.Transform:GetWorldPosition()
                    else
                        inst.sg.statemem.target = nil
                    end
                end

                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
            end,


            timeline =
            {
                FrameEvent(14, function(inst)
                    WebMortar(inst,0)
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/cavespider/spit_web")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) 
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
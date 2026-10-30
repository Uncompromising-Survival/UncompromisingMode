local env = env
GLOBAL.setfenv(1, GLOBAL)

local function GetTargetForState(target, inst)
    return target and target:IsValid() and target or inst.components.combat and inst.components.combat.target
end

local function MagmaHoundShootFire(inst)
    local target = inst.sg.statemem.target
    if target and target:IsValid() then
        inst:ShootFire(3)
    end
end

local function QuickAttackFX(inst)
    inst[inst.sg.statemem.isfire and "FirePoof" or "SnowFX"](inst)
    local target = inst.sg.statemem.target
    if target and target:IsValid() then
        inst:ForceFacePoint(target:GetPosition())
    end
end

env.AddStategraphPostInit("hound", function(inst)
    local tauntstate = inst.states["taunt"]
    if tauntstate then
        local tauntstate_onenter = tauntstate.onenter
        tauntstate.onenter = function(inst, norepeat, ...)
            local magmahound = inst:HasAllTags("magmahound", "clay")
            if magmahound then inst:RemoveTag("clay") end
            local ret = tauntstate_onenter(inst, norepeat, ...)
            if magmahound then inst:AddTag("clay") end
            return ret
        end
    end

    local doattackeventhandler = inst.events["doattack"]
    if doattackeventhandler then
        local doattackeventhandler_fn = doattackeventhandler.fn
        doattackeventhandler.fn = function(inst, data, ...)
            if not (inst.components.health and inst.components.health:IsDead())
                and ((inst.sg:HasStateTag("hit") and not inst.sg:HasStateTag("electrocute")) or not inst.sg:HasStateTag("busy")
                or inst.sg:HasStateTag("caninterrupt")) and inst.um_specialattackready then
                inst.sg:GoToState(data.target:IsValid() and not inst:IsNear(data.target, 3)
                    and (inst:HasAnyTag("lightninghound", "glacialhound") and "charging_pre" or inst:HasTag("magmahound") and "burning_pre"
                    or (inst.prefab == "firehound" or inst.prefab == "icehound") and "quickattack") or "attack", data.target)
                return
            end
            return doattackeventhandler_fn(inst, data, ...)
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

        EventHandler("regen_iceshield", function(inst, data)
            if not (inst.components.health and inst.components.health:IsDead()) and not (inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water) then
                inst.sg:GoToState("regen_iceshield")
            end
        end)
    }

    local states =
    {
        State {
            name = "leap_attack_pre",
            tags = {"attack", "busy", "leapattack"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("jump")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("leap_attack", target) end),
            },
        },
        State {
            name = "leap_attack",
            tags = {"attack", "busy", "leapattack"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                inst.sg.statemem.startpos = inst:GetPosition()
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
                    inst:ForceFacePoint(inst.sg.statemem.targetpos)
                end
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
                if not inst.sg.statemem.targetpos or inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water then
                    inst.sg:GoToState("idle")
                    return
                end
                local percent = inst.AnimState:GetCurrentAnimationTime() / inst.AnimState:GetCurrentAnimationLength()
                local xdiff = inst.sg.statemem.targetpos.x - inst.sg.statemem.startpos.x
                local zdiff = inst.sg.statemem.targetpos.z - inst.sg.statemem.startpos.z
                inst.Transform:SetPosition(inst.sg.statemem.startpos.x + (xdiff * percent), 0, inst.sg.statemem.startpos.z + (zdiff * percent))
            end,

            onexit = function(inst)
                inst.Physics:SetActive(true)
                --inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
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
        State {
            name = "leap_attack_pst",
            tags = {"busy"},

            onenter = function(inst)
                inst.um_specialattackready = false
                --[[inst.components.timer:StopTimer("jumpability_cooldown")
                inst.components.timer:StartTimer("jumpability_cooldown", 8)]]
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("hit")
                inst:SporeCloudAttack()
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
            },
        },
        State {
            name = "charging_pre",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("charging_loop", inst.sg.statemem.target) end),
            },
        },
        State {
            name = "charging_loop",
            tags = {"busy", "charging"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.SoundEmitter:PlaySound(inst.sounds.pant)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_loop", true)
                inst:Charge()
                inst.sg:SetTimeout(inst:HasTag("lightninghound") and 4 + math.random() or 1)
            end,

            onexit = function(inst)
                inst.um_specialattackready = false
                if inst.UMToggleCombatRange then inst:UMToggleCombatRange() end
                inst.components.timer:StopTimer("lightningshot_cooldown")
                inst.components.timer:StartTimer("lightningshot_cooldown", 8 + math.random())
                inst:CancelCharge()
            end,

            ontimeout = function(inst)
                inst:CancelCharge()
                inst.sg:GoToState("charging_pst", inst.sg.statemem.target)
            end,
        },
        State {
            name = "charging_pst",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState(inst:HasTag("lightninghound") and "howl_attack" or "ice_howl_attack", inst.sg.statemem.target) end),
            },
        },
        State {
            name = "regen_iceshield",
            tags = {"busy", "howling"},
            onenter = function(inst)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("howl")
                inst.SoundEmitter:PlaySound(inst.sounds.howl)
                inst:RegenIceShield(2) --TODO:SCALING TIERS
            end,
            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },
        State {
            name = "howl_attack",
            tags = {"attack", "busy", "howling"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
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
                    local target = inst.sg.statemem.target
                    if target and target:IsValid() then
                        inst:LaunchProjectile(target)
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
        State {
            name = "ice_howl_attack",
            tags = {"attack", "busy", "howling"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                if not inst.tripleshot then inst.tripleshot = 1 end
                inst.Physics:Stop()
                --inst.AnimState:PlayAnimation("taunt")
                inst.AnimState:PlayAnimation("atk_pre")
            end,

            timeline =
            {
                TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.bark) end),
                TimeEvent(5 * FRAMES, function(inst)
                    local target = inst.sg.statemem.target
                    if target and target:IsValid() then
                        inst:LaunchProjectile(target)
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.tripleshot < 3 then
                        inst.tripleshot = inst.tripleshot + 1
                        inst.sg:GoToState("ice_howl_attack", inst.sg.statemem.target)
                    else
                        inst.tripleshot = nil
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },
        --AXE This SG series is implemented by the Magma Hound, it charges up its attack by looping through a single state, then loops through a breathing state.
        State {
            name = "burning_pre",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pre")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("burning_loop", inst.sg.statemem.target) end),
            },
        },
        State {
            name = "burning_loop",
            tags = {"busy", "charging"},
            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.SoundEmitter:PlaySound(inst.sounds.pant)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("burningup", true)
                inst:Charge()
                inst.sg:SetTimeout(1 + math.random())
            end,

            onexit = function(inst)
                inst.um_specialattackready = false
                if inst.UMToggleCombatRange then inst:UMToggleCombatRange() end
                inst.components.timer:StopTimer("lightningshot_cooldown")
                inst.components.timer:StartTimer("lightningshot_cooldown", 9 + math.random())
                inst:CancelCharge()
            end,

            ontimeout = function(inst)
                inst:CancelCharge()
                inst.sg:GoToState("burning_pst", inst.sg.statemem.target)
            end,
        },
        State {
            name = "burning_pst",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("scared_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("burning_howl_attack", inst.sg.statemem.target) end),
            },
        },
        State {
            name = "burning_howl_attack",
            tags = {"attack", "busy", "howling"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if not inst.burning_anim_count and inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                --inst.Transform:SetFourFaced()
                inst.burning_anim_count = (inst.burning_anim_count or 0) + 1
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("belch")
            end,

            onupdate = function(inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    local t_rot = inst:GetAngleToPoint(inst.sg.statemem.target:GetPosition())
                    local rot = inst:GetRotation()
                    local drot = math.clamp(ReduceAngle(t_rot - rot), -3, 3)
                    inst.Transform:SetRotation(rot + drot)
                end
            end,

            timeline =
            {
                TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound(inst.sounds.howl) end),
                TimeEvent(3 * FRAMES, MagmaHoundShootFire),
                TimeEvent(6 * FRAMES, MagmaHoundShootFire),
                TimeEvent(9 * FRAMES, MagmaHoundShootFire),
                TimeEvent(12 * FRAMES, MagmaHoundShootFire),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.burning_anim_count < 6 then
                        inst.sg:GoToState("burning_howl_attack", inst.sg.statemem.target)
                    else
                        inst.burning_anim_count = nil
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },
        State {
            name = "quickattack",
            tags = {"attack", "busy"},

            onenter = function(inst, target)
                inst.sg.statemem.target = GetTargetForState(target, inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                end
                inst.sg.statemem.isfire = inst.prefab == "firehound"
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("atk_pre")
                inst.components.timer:StartTimer(inst.sg.statemem.isfire and "quickbreath" or "quickspike", math.random(6, 10)) --AXE Queue up the next time the hound will spit again.
                inst.AnimState:SetDeltaTimeMultiplier(.3)
                inst.um_specialattackready = false
                inst.components.combat:SetRange(3, 3) --AXE Reset the range back to normal
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, QuickAttackFX),
                TimeEvent(16 * FRAMES, QuickAttackFX),
                TimeEvent(24 * FRAMES, function(inst)
                    inst.sg.statemem.not_interrupted = true
                    inst.AnimState:SetDeltaTimeMultiplier(1)
                    local target = inst.sg.statemem.target
                    if target and target:IsValid() then
                        inst:ForceFacePoint(target:GetPosition())
                        local isfire = inst.sg.statemem.isfire
                        inst[isfire and "ShootFire" or "IceSpike"](inst, not isfire and target or nil)
                    end
                end),
            },

            onexit = function(inst) --AXE Incase it's taken from this state via freezing, or such
                if not inst.sg.statemem.not_interrupted then
                    inst.AnimState:SetDeltaTimeMultiplier(1)
                end
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
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
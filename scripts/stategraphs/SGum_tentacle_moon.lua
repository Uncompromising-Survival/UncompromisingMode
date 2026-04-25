local easing = require("easing")
require("stategraphs/commonstates")

local events=
{
	EventHandler("attacked", function(inst, data)
		if inst.components.health and not inst.components.health:IsDead() then
			if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
				return
			elseif not inst.sg:HasAnyStateTag("hit", "attack") then
                if inst.sg:HasStateTag("raised") then
                    inst.sg:GoToState("hit_raised")
                else
				    inst.sg:GoToState("hit_ground")
                end
			end
		end
	end),
    CommonHandlers.OnFreeze(),
	--CommonHandlers.OnElectrocute(),
    EventHandler("newcombattarget", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("raised") then
            inst.sg:GoToState("raise")
        end
    end),
    EventHandler("losttarget", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.combat:TryRetarget() --AXE give it one more go before leaving.
            if inst.components.combat.target == nil and inst.sg:HasStateTag("raised") then
                inst.sg:GoToState("lower")
            end
        end
    end),
    EventHandler("death", function(inst,data)
        if inst.sg:HasStateTag("raised") then
            inst.sg:GoToState("death_raised")
        else
            inst.sg:GoToState("death_ground")
        end
    end),
    EventHandler("freeze", function(inst,data)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.sg:GoToState("frozen")
        end
    end),
}

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("tentacle")
end

local function OnEntityWake(inst)
    if inst.sg.mem.rumblesoundstate then --don't nil check, can be false
        if not inst.SoundEmitter:PlayingSound("tentacle") then
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_rumble_LP", "tentacle")
        end
        inst.SoundEmitter:SetParameter("tentacle", "state", inst.sg.mem.rumblesoundstate)
    end
end

local function StartRumbleSound(inst, state)
    if inst.sg.mem.rumblesoundstate ~= state then
        if inst.sg.mem.rumblesoundstate == nil then
            inst:ListenForEvent("entitysleep", OnEntitySleep)
            inst:ListenForEvent("entitywake", OnEntityWake)
        end
        inst.sg.mem.rumblesoundstate = state
        if not inst:IsAsleep() then
            OnEntityWake(inst)
        end
    end
end

local function StopRumbleSound(inst)
    if not inst.sg.statemem.keeprumblesound then
        inst.sg.mem.rumblesoundstate = false
        inst.SoundEmitter:KillSound("tentacle")
    end
end

local function ThrowSpines(inst, target)
    for randrng = 0,5,1 do
        local x, y, z = inst.Transform:GetWorldPosition()
        local projectile = SpawnPrefab("um_tentacle_moon_projectile")
        projectile.attacker = inst
        projectile.attacker_faction = "tentacle"
        projectile.Transform:SetPosition(x, y, z)
        local a, b, c = target.Transform:GetWorldPosition()
        local targetpos = target:GetPosition()
        targetpos.x = targetpos.x + math.random(-randrng, randrng)
        targetpos.z = targetpos.z + math.random(-randrng, randrng)
        local dx = a - x
        local dz = c - z
        local rangesq = dx * dx + dz * dz
        local maxrange = 28
        local bigNum = 15
        local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange)
        projectile:AddTag("canthit")
        projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
        projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    end
end

local states=
{


    State{
        name = "idle_ground",
		tags = { "idle"},
        onenter = function(inst)
            inst.AnimState:PushAnimation("idle_retreated", true)
            inst.SoundEmitter:KillAllSounds()
        end,
    },

    State{
        name = "idle_raised",
		tags = { "idle","raised"},
        onenter = function(inst)
            --StartRumbleSound(inst, 0)
            inst.AnimState:PlayAnimation("idle_land", false)
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,
        events=
        {
            EventHandler("animover", function(inst)
                local target = inst.components.combat and inst.components.combat.target and inst.components.combat.target or nil
                if target and target:IsValid() and inst.components.combat:CanAttack(target) then
                    inst.sg:GoToState("attack_pre")
                else
                    inst.sg:GoToState("idle_raised")
                end
            end),
        },

    },

    State{
        name = "raise",
		tags = { "idle","raised","busy"},
        onenter = function(inst)
            StartRumbleSound(inst, 0)
            inst.AnimState:PlayAnimation("appear_pre", false)
            inst.AnimState:PushAnimation("appear_land", false)
        end,
        events=
        {
            EventHandler("animqueueover", function(inst)
                --inst.sg.statemem.keeprumblesound = true
                inst.sg:GoToState("idle_raised")
            end),
        },
        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge_VO") end),
        },
    },
    State{
        name = "lower",
		tags = { "idle"},
        onenter = function(inst)
            StartRumbleSound(inst, 0)
            inst.AnimState:PlayAnimation("retreat_land", false)
        end,
        EventHandler("animover", function(inst)
            --inst.sg.statemem.keeprumblesound = true
            inst.sg:GoToState("idle_ground")
        end),
    },

    State{
        name ="attack_pre",
        tags = {"attack","raised","attack"},
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("attack_pre_land")
            StartRumbleSound(inst, 1)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("attack")
            end),
        },
    },
    State{
        name = "attack",
        tags = {"attack","raised","attack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_land")
            inst.AnimState:PushAnimation("attack_pst_land",false)
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) 
                if inst.components.combat and inst.components.combat.target and inst.components.combat.target:IsValid() then
                    ThrowSpines(inst,inst.components.combat.target)
                end
                inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") 
            end),
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(9*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle_raised")
            end),
        },
    },
    State{
        name = "hit_raised",
        tags = {"busy", "hit"},

        onenter = function(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("hit_land")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_hurt_VO")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack_pre") end),
        },
    },
    State{
        name = "hit_ground",
        tags = {"busy", "hit","raised"},

        onenter = function(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("hit_retreated")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_hurt_VO")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle_ground") end),
        },
    },
	State{
        name = "death_raised",
        tags = {"busy","raised"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_death_VO")
            inst.AnimState:PlayAnimation("death_land")
            RemovePhysicsColliders(inst)
            inst:DropDeathLoot()
        end,

        
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat") end),
        },
    },
	State{
        name = "death_ground",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_death_VO")
            inst.AnimState:PlayAnimation("death_land")
            RemovePhysicsColliders(inst)
            inst:DropDeathLoot()
        end,

        
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat") end),
        },
    },
    State{
        name = "rumble_old",
		tags = { "idle", "invisible", "noelectrocute" },
        onenter = function(inst)
            StartRumbleSound(inst, 0)
            inst.AnimState:PlayAnimation("idle_retreated")
            inst.AnimState:PushAnimation("idle_retreated", true)
            inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
        end,
        ontimeout = function(inst)
            inst.AnimState:PushAnimation("idle_retreated", false)
            inst.sg:GoToState("idle")
        end,

        onexit = StopRumbleSound,
    },

    State{
        name = "idle_old",
		tags = { "idle", "invisible", "noelectrocute" },
        onenter = function(inst)
            inst.AnimState:PushAnimation("idle_retreated", true)
            inst.sg:SetTimeout(GetRandomWithVariance(10, 5) )
            inst.SoundEmitter:KillAllSounds()
        end,

        ontimeout = function(inst)
			inst.sg:GoToState("rumble")
        end,
    },

    State{
        name = "taunt_old",
		tags = { "taunting", "noelectrocute" },
        onenter = function(inst)
            StartRumbleSound(inst, 0)
            TheNet:Announce("taunting/appearing")
            inst.AnimState:PlayAnimation("idle")

            inst.AnimState:PlayAnimation("appear_pre_land")
            inst.AnimState:PushAnimation("appear_land", true)
        end,

        onupdate = function(inst)
            if inst.sg.timeinstate > .75 and inst.components.combat:TryAttack() then
                inst.sg:GoToState("attack_pre")
            elseif inst.components.combat.target == nil then
                inst.sg:GoToState("idle")
            end

        end,
        onexit = StopRumbleSound,
    },

    State{
        name ="attack_pre_old",
        tags = {"attack"},
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge")
            inst.components.combat:StartAttack()
            TheNet:Announce("told to attack")
            inst.AnimState:PlayAnimation("attack_pre_land")
            StartRumbleSound(inst, 1)
        end,
        events=
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keeprumblesound = true
                inst.sg:GoToState("attack")
            end),
        },
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_emerge_VO") end),
        },
        onexit = StopRumbleSound,
    },

    State{
        name = "attack_old",
        tags = {"attack"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_land")
            inst.AnimState:PushAnimation("attack_pst_land")
        end,

        timeline=
        {
            TimeEvent(2*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") end),
			TimeEvent(7*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_attack") end),
            TimeEvent(17*FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(18*FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst)
                inst.sg.statemem.keeprumblesound = true
                if inst.components.combat.target then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("attack_post")
                end
            end),
        },
        onexit = StopRumbleSound,
    },

    State{
        name ="attack_post_old",
		tags = { "noelectrocute" },
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_disappear")
            inst.AnimState:PlayAnimation("attack_pst_land")
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.SoundEmitter:KillAllSounds() inst.sg:GoToState("idle") end),
        },
        onexit = StopRumbleSound,
    },

    State{
        name = "idle_raised_old",
		tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_land", true)
        end,
    },

	State{
        name = "death_old",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_death_VO")
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst:DropDeathLoot()
        end,

        events =
        {
            CommonHandlers.OnCorpseDeathAnimOver(),
        },
        
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_splat") end),
        },
    },


    State{
        name = "hit_old",
        tags = {"busy", "hit"},

        onenter = function(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/pig/grunt")
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentacle_hurt_VO")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack") end),
        },
    },

    State{
        name = "frozen",
        tags = {"busy", "frozen"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen_loop_land")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
        end,

        events =
        {
            EventHandler("onthaw", function(inst) inst.sg:GoToState("thaw") end ),
        },
    },

    State{
        name = "thaw",
        tags = {"busy", "thawing"},

        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("frozen_pst_land", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
        end,
    },
}
--CommonStates.AddFrozenStates(states) --AXE Not using common states because of the way the animations were named.
--[[CommonStates.AddElectrocuteStates(states, nil, nil, {
	onanimover = function(inst)
		if inst.AnimState:AnimDone() then
			inst.sg:GoToState("attack_pre")
		end
	end,
})]] -- AXE Missing electrocute animations

CommonStates.AddInitState(states, "idle_ground")
--CommonStates.AddCorpseStates(states)

return StateGraph("um_tentacle_moon", states, events, "init")

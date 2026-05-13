require("stategraphs/commonstates")

local DESTROYSTUFF_IGNORE_TAGS = { "INLIMBO", "mushroomsprout", "NET_workable" }
local BOUNCESTUFF_MUST_TAGS = { "_inventoryitem" }
local BOUNCESTUFF_CANT_TAGS = { "locomotor", "INLIMBO" }
SPORECLOUD_TAGS = { "sporecloud" }

local function DestroyStuff(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, nil, DESTROYSTUFF_IGNORE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and
            v.components.workable ~= nil and
            v.components.workable:CanBeWorked() and
            v.components.workable.action ~= ACTIONS.NET then
            SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
            v.components.workable:Destroy(inst)
        end
    end
end

local function ClearRecentlyBounced(inst, other)
    inst.sg.mem.recentlybounced[other] = nil
end

local function SmallLaunch(inst, launcher, basespeed)
    local hp = inst:GetPosition()
    local pt = launcher:GetPosition()
    local vel = (hp - pt):GetNormalized()
    local speed = basespeed * 2 + math.random() * 2
    local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
    inst.Physics:Teleport(hp.x, .1, hp.z)
    inst.Physics:SetVel(math.cos(angle) * speed, 1.5 * speed + math.random(), math.sin(angle) * speed)

    launcher.sg.mem.recentlybounced[inst] = true
    launcher:DoTaskInTime(.6, ClearRecentlyBounced, inst)
end

local function BounceStuff(inst)
    if inst.sg.mem.recentlybounced == nil then
        inst.sg.mem.recentlybounced = {}
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, BOUNCESTUFF_MUST_TAGS, BOUNCESTUFF_CANT_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and not (v.components.inventoryitem.nobounce or inst.sg.mem.recentlybounced[v]) and v.Physics ~= nil and v.Physics:IsActive() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            local intensity = math.clamp((36 - distsq) / 27 --[[(36 - 9)]], 0, 1)
            SmallLaunch(v, inst, intensity)
        end
    end
end
-- BounceStuff used when he counters and dies

local function PoofMouthFire(inst)
	local fx = SpawnPrefab(inst.coldfire and "deer_ice_burst" or "deer_fire_burst")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx.entity:AddFollower()
	fx.Follower:FollowSymbol(inst.GUID, "mouth_fire")
end

local ARC = 90 * DEGREES --degrees to each side
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "notarget", "noattack"}
local function PoofNearby(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation() * DEGREES
    local x0, z0
	local radius = 4
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, nil, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC then
				if v.components.burnable then
					v.components.burnable:Ignite()
				end
				if v.components.health then
					v.components.health:DoFireDamage(10,nil,true)
				end
			end
        end
    end
end

local function ShootFire(inst,total_flame)
	for i = 1,total_flame do
		inst:DoTaskInTime(0+math.random(1,15)*FRAMES,function(inst)
			
			local x,y,z = inst.Transform:GetWorldPosition()
			local projectile = SpawnPrefab("um_fire_projectile")
			if inst.coldfire then
				projectile.chilly = true
			end
			local rot = inst.Transform:GetRotation() 
			local degrand = 5
			local dx = 4*math.sin((rot+ 90+degrand) * DEGREES)
			local dz = 4*math.cos((rot+ 90+degrand) * DEGREES)
			rot = rot + math.random(-20,20)
			projectile.Transform:SetPosition(x + dx,2,z+dz)
			projectile.Transform:SetRotation(rot)
			projectile.speed = 15
			projectile.scale = 1 + math.random(0,10)/100 -- scale up sometimes.
			projectile.damage = 3
			projectile.damager = inst
			if not inst.coldfire then
				PoofNearby(inst)
			end
			
		end)
	end
end

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "gohome"),
    ActionHandler(ACTIONS.PICK, "pick"),
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events=
{
    CommonHandlers.OnAttacked(),
    EventHandler("doattack", function(inst)
		if not (inst.components.health:IsDead() or inst.sg:HasStateTag("electrocute") or inst.sg:HasStateTag("busy")) then
            if inst.sg.mem.wantstostomp then
                inst.sg.mem.wantstostomp = nil
                inst.sg:GoToState("stomp")
			elseif (inst.components.timer:TimerExists("pissedoff") and not inst.components.timer:TimerExists("flame_cd")) or inst.flamecount > 0 then
				inst.sg:GoToState("flame_pre")
			else
				inst.sg:GoToState("attack")
			end
			
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
    CommonHandlers.OnLocomote(false,true),
}

local states=
{

	State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/death")
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
		
        timeline=
        {
            TimeEvent(20*FRAMES, function(inst) 
				TheWorld:PushEvent("ms_miniquake", { rad = 20, num = 20, duration = 2.5, target = inst })
                BounceStuff(inst)
			end),
        },


    },
                
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()

            if start_anim then
                inst.AnimState:PlayAnimation(start_anim)
                inst.AnimState:PushAnimation("idle1", true)
            else
                inst.AnimState:PlayAnimation("idle1", true)
            end
        end,

    },

    State{
        name = "taunt",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar")
            if inst.components.combat and inst.components.combat.target then
                inst:FacePoint(Vector3(inst.components.combat.target.Transform:GetWorldPosition()))
            end
        end,

        timeline=
        {
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_soft") end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_soft") end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("bite", false)
        end,

        timeline=
        {
            TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") end),
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "flame_pre",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("flame_pre", false)
			inst.flamecount = 0
			inst.flamecount_total = math.random(7,9) -- Can retune this...
			if inst.bellyfullness > 0 then
				inst.bellyfullness = 0
				inst.coldfire = true
			end
        end,

        timeline=
        {
			TimeEvent(8*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") 
				PoofMouthFire(inst)
			end),
            TimeEvent(14*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") 
				PoofMouthFire(inst)
			end),
        },
		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("flame") end),
        },
    },
	
    State{
        name = "flame",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("flame_loop", false)
        end,

		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,
        timeline=
        {
			TimeEvent(4*FRAMES, function(inst) ShootFire(inst,math.random(5,8))  end),
        },
        events=
        {
            EventHandler("animqueueover", 
				function(inst) 
					inst.flamecount = inst.flamecount + 1
					if inst.flamecount > inst.flamecount_total or (inst.components.combat and not inst.components.combat.target) then -- no target condition or after you're tired of breathing fire.
						inst.sg:GoToState("flame_pst")
					else
						inst.sg:GoToState("flame") 
					end
				end),
        },
    },
    State{
        name = "flame_pst",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
			inst.flamecount = 0
            inst.AnimState:PlayAnimation("flame_pst", false)
			inst.components.timer:StartTimer("flame_cd",20)
			inst.components.combat:SetRange(3)
        end,

        timeline=
        {
			TimeEvent(8*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") 
				PoofMouthFire(inst)
			end),
            TimeEvent(14*FRAMES, function(inst) 
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp")
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") 
				PoofMouthFire(inst)
			end),
        },
		onexit = function(inst)
			if inst.coldfire then
				inst.coldfire = false
			end
		end,
		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst)
            if not inst.sg.mem.wantstostomp then
			    inst.tolerance = inst.tolerance + 0.3 + (math.random() * 0.2)
            end
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
			CommonHandlers.UpdateHitRecoveryDelay(inst)
            if inst.components.timer:TimerExists("pissedoff") then
                inst.components.timer:StopTimer("pissedoff")
            end
            inst.components.timer:StartTimer("pissedoff",60) -- 1 minute of piss off time.
			if not inst.components.timer:TimerExists("flame_cd") then
				inst.components.combat:SetRange(8,3) --AXE He should be ready to breath fire, set his range to be longer than usual so he doesn't walk up to the player to start the attack
			end
        end,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.tolerance > 1 then
                    inst.tolerance = 0
                    inst.sg.mem.wantstostomp = true
                    inst.components.combat:ResetCooldown()
                end
				inst.sg:GoToState("idle")
			end),
        },
    },


    State{
        name = "gohome",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            if inst.components.sleeper then
                inst.components.sleeper:GoToSleep()
            end
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar")
        end,

        timeline=
        {
            TimeEvent(18*FRAMES, function(inst) 
				if inst._hacky_eat_target then
					inst.OnEatHack(inst,inst._hacky_eat_target)
					inst._hacky_eat_target:Remove()
					inst._hacky_eat_target = nil
				end
			end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
	State{
		name = "stomp",
		tags = {"attack", "busy"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar")
			inst.components.combat:StartAttack()
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("pound", false)
			inst.components.combat:SetAreaDamage(4, 1)
            inst.components.combat:SetDefaultDamage(225) -- AXE He's being killed by worms AAAA
		end,

		timeline=
		{
			TimeEvent(36 * FRAMES, function(inst) 
				SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
				SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
				SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
				SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
				inst.components.combat:DoAttack(inst.sg.statemem.target) 
				local ring = SpawnPrefab("groundpoundring_fx")
				ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
				ring.Transform:SetScale(.7, .7, .7)
                TheWorld:PushEvent("ms_miniquake", { rad = 20, num = 20, duration = 2.5, target = inst })
                BounceStuff(inst)
				
			end),
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.components.combat:SetAreaDamage()
                inst.components.combat:SetDefaultDamage(75)
				inst.sg:GoToState("idle")
			end),
		},
	},	

}

CommonStates.AddWalkStates(states,
{
	walktimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp") end ),
		TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/step_stomp") end ),
	},
})

CommonStates.AddSleepStates(states,
{
	starttimeline =
	{
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") end ),
	},
	waketimeline =
	{
		TimeEvent(0*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/roar") 
			if inst.components.timer:TimerExists("bellyfull") then
				inst.components.timer:StopTimer("bellyfull")
			end
		end ),
	},
})

CommonStates.AddSimpleActionState(states, "pick", "bite", 13 * FRAMES, { "busy" })
CommonStates.AddFrozenStates(states)
--CommonStates.AddElectrocuteStates(states) -- Need to figure out what animations these are first.

return StateGraph("um_pepperdragon", states, events, "wake", actionhandlers)

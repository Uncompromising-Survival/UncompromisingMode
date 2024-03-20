require("stategraphs/commonstates")

local events =
{
    EventHandler("doattack", function(inst, data) 
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			if data.target:IsValid() then
				inst.sg:GoToState("jump_pre", data.target)
			end
        end
    end),
	EventHandler("attacked", function(inst)
		if not (inst.sg:HasStateTag("noattack") or inst.sg:HasStateTag("temp_invincible") or inst.components.health:IsDead()) then
			inst.sg:GoToState("hit")
		end
	end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),

	CommonHandlers.OnLocomote(true, false),
}

local function TryAttach(inst, target)
	print(inst.sg.statemem.target)
	if target ~= nil and target:IsValid() and inst:IsNear(target, 3) then
		print("invade")
		if target ~= nil and target:HasTag("player") and target.components.inventory ~= nil then
			if target.components.inventory:IsFull() then
				inst.components.thief:StealItem(target)
			end
			
			inst.StartLeeching(inst, target)
			
			inst.sg:GoToState("attached")
			--target.components.inventory:GiveItem(inst)
		end
	end
end

local function FinishExtendedSound(inst, soundid)
    inst.SoundEmitter:KillSound("sound_"..tostring(soundid))
    inst.sg.mem.soundcache[soundid] = nil
    if inst.sg.statemem.readytoremove and next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    end
end

local function PlayExtendedSound(inst, soundname)
    if inst.sg.mem.soundcache == nil then
        inst.sg.mem.soundcache = {}
        inst.sg.mem.soundid = 0
    else
        inst.sg.mem.soundid = inst.sg.mem.soundid + 1
    end
    inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
    inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_"..tostring(inst.sg.mem.soundid))
    inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
end

local function OnAnimOverRemoveAfterSounds(inst)
    if inst.sg.mem.soundcache == nil or next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    else
        inst:Hide()
        inst.sg.statemem.readytoremove = true
    end
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},

	State{
		name = "spawn_delay",
		tags = { "busy", "noattack", "temp_invincible", "invisible" },

		onenter = function(inst, delay)
			inst.components.locomotor:Stop()
			inst:Hide()
			inst.sg:SetTimeout(delay or math.random())
		end,

		ontimeout = function(inst)
			local target = inst.components.entitytracker:GetEntity("daywalker")
			if target ~= nil then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.sg:GoToState("spawn")
		end,

		onexit = function(inst)
			inst:Show()
		end,
	},

	State{
		name = "spawn",
		tags = { "busy", "noattack", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("spawn")
		end,

		timeline =
		{
			FrameEvent(35, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.sg:RemoveStateTag("temp_invincible")
			end),
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
		name = "hit",
		tags = { "busy", "hit", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("disappear")
			inst.SoundEmitter:PlaySound("daywalker/leech/die")
			--inst.SoundEmitter:PlaySound("dontstarve/sanity/death_pop")
		end,

		timeline =
		{
			FrameEvent(12, function(inst)
				inst.sg:AddStateTag("noattack")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					local x0, y0, z0 = inst.Transform:GetWorldPosition()
					local daywalker = inst.components.entitytracker:GetEntity("daywalker")
					local dir0 = daywalker ~= nil and daywalker:GetAngleToPoint(x0, y0, z0) or nil
					for k = 1, 4 do
						local radius = GetRandomMinMax(4 - k, 8)
						local angle = dir0 ~= nil and (dir0 + math.random() * 90 - 45) * DEGREES or math.random() * TWOPI
						local x = x0 + math.cos(angle) * radius
						local z = z0 - math.sin(angle) * radius
						if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
							inst.Physics:Teleport(x, 0, z)
							break
						end
					end
					inst.sg:GoToState("appear")
				end
			end),
		},
	},

	State{
		name = "appear",
		tags = { "busy", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("appear")
		end,

		timeline =
		{
			FrameEvent(17, function(inst)
				inst.sg:RemoveStateTag("temp_invincible")
			end),
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
		name = "death",
		tags = { "busy", "noattack" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("disappear")
			inst.SoundEmitter:PlaySound("daywalker/leech/die")
			inst.SoundEmitter:PlaySound("dontstarve/sanity/death_pop")
			local pt = inst:GetPosition()
			pt.y = 1
			inst.components.lootdropper:DropLoot(pt)
			inst:AddTag("NOCLICK")
			inst.persists = false
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:Remove()
				end
			end),
		},

		onexit = function(inst)
			--Shouldn't reach here!
			inst:RemoveTag("NOCLICK")
		end,
	},

	State{
		name = "jump_pre",
		tags = { "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("jump_pre")
			inst.SoundEmitter:PlaySound("daywalker/leech/leap")
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.targetpos = target:GetPosition()
			end
		end,

		onupdate = function(inst)
			if inst.sg.statemem.target ~= nil then
				if inst.sg.statemem.target:IsValid() then
					local pos = inst.sg.statemem.targetpos
					pos.x, pos.y, pos.z = inst.sg.statemem.target.Transform:GetWorldPosition()
					inst:ForceFacePoint(pos)
				else
					inst.sg.statemem.target = nil
				end
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("jump", inst.sg.statemem.target or inst.sg.statemem.targetpos)
				end
			end),
		},
	},

	State{
		name = "jump",
		tags = { "busy", "jumping", "noattack" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("jump")
			inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			local dist
			if target == nil then
				dist = 6
				local theta = inst.Transform:GetRotation() * DEGREES
				target = inst:GetPosition()
				target.x = target.x + math.cos(theta) * dist
				target.z = target.z - math.sin(theta) * dist
			elseif EntityScript.is_instance(target) and target:IsValid() then
				inst.sg.statemem.target = target
				target = target:GetPosition()
				dist = math.sqrt(inst:GetDistanceSqToPoint(target))
			end
			inst:ForceFacePoint(target)
			inst.sg.statemem.speed = math.min(16.5, dist / (5 * FRAMES))
			print("leap speed"..inst.sg.statemem.speed)
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
			inst.Physics:ClearCollidesWith(COLLISION.SANITY)
		end,

		timeline =
		{
			FrameEvent(10, function(inst)
				TryAttach(inst, inst.sg.statemem.target)
			end),
			FrameEvent(12, function(inst)
				TryAttach(inst, inst.sg.statemem.target)
			end),
			FrameEvent(14, function(inst)
				TryAttach(inst, inst.sg.statemem.target)
			end),
			FrameEvent(15, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed * .35, 0, 0)
				inst.Physics:CollidesWith(COLLISION.SANITY)
				inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("flail")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			inst.Physics:CollidesWith(COLLISION.SANITY)
		end,
	},

	State{
		name = "flail",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("flail_loop", true)
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() * 3)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("flail_pst")
		end,
	},

	State{
		name = "flail_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("flail_pst")
		end,

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
		name = "attached",
		tags = { "busy", "noattack", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("attach_loop", true)
			inst.Physics:SetActive(false)
			inst:AddTag("notarget")
			inst:ToggleBrain(false)
			--inst.SoundEmitter:PlaySound("daywalker/leech/suck", "suckloop")
		end,

		onexit = function(inst)
			inst.Follower:StopFollowing()
			inst.Physics:SetActive(true)
			inst:RemoveTag("notarget")
			inst:ToggleBrain(true)
			--inst.SoundEmitter:KillSound("suckloop")
		end,
	},

	State{
		name = "flung",
		tags = { "busy", "jumping", "noattack", "temp_invincible" },

		onenter = function(inst, speedmult)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("toss")
			inst.SoundEmitter:PlaySound("daywalker/leech/fall_off")
			inst.sg.statemem.speed = -10 * (speedmult or 1)
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
			inst.Physics:ClearCollidesWith(COLLISION.SANITY)
		end,

		timeline =
		{
			FrameEvent(18, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.sg:RemoveStateTag("temp_invincible")
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed * .35, 0, 0)
				inst.Physics:CollidesWith(COLLISION.SANITY)
				inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("flail")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			inst.Physics:CollidesWith(COLLISION.SANITY)
		end,
	},

}

CommonStates.AddRunStates(states,
{
	starttimeline =
	{
		FrameEvent(6, function(inst)
			inst.components.locomotor:RunForward()
		end),
	},
},
nil, nil, true--[[delaystart]],
{
	runonenter = function(inst)
		inst.SoundEmitter:PlaySound("daywalker/leech/walk", "walkloop")
	end,
	runonexit = function(inst)
		inst.SoundEmitter:KillSound("walkloop")
	end,
})

return StateGraph("um_shadow_leech", states, events, "appear")

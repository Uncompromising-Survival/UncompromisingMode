require("stategraphs/commonstates")

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

local events=
{
    --CommonHandlers.OnLocomote(true, false),
	EventHandler("locomote", function(inst) 
        if not inst.sg:HasStateTag("busy") --[[and not inst.sg:HasStateTag("grabbing") and not inst.sg:HasStateTag("evade")]] then
            
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    --inst.sg:GoToState("premoving")
                    inst.sg:GoToState("moving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("newcombattarget", function(inst) 
		if not inst.components.health:IsDead() and not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("busy")) then 
			inst.sg:GoToState("taunt") 
		end 
	end),
    EventHandler("attacked", function(inst) if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") and not inst.sg:HasStateTag("hit") and not CommonHandlers.HitRecoveryDelay(inst, nil, TUNING.WALRUS_MAX_STUN_LOCKS) then inst.sg:GoToState("hit") end end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),

    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() then
			inst.sg:GoToState("attack", data.target)
        end
    end),
}

local states=
{
    State{
        name = "idle",
        tags = { "idle" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if not inst.AnimState:IsCurrentAnimation("idle") then
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,
    },
	
    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            --PlayExtendedSound(inst, "idle")
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk", true)
        end,

        timeline=
        {
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },
	
	State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.components.locomotor:StopMoving()
            --inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

    },

    State{
        name = "taunt",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("giggle")
            PlayExtendedSound(inst, "taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy" },

        onenter = function(inst)
            PlayExtendedSound(inst, "attack")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
			
			local target = inst.components.combat.target ~= nil and inst.components.combat.target or nil
			
			if target ~= nil and target.Transform ~= nil then
				inst.sg.statemem.target = target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			else
				inst.sg:GoToState("idle")
			end
			
			inst.AnimState:PlayAnimation("smork")
        end,

		timeline =
		{   
            TimeEvent(20*FRAMES, function(inst) 
				PlayExtendedSound(inst, "attack_grunt")
			
				if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    inst:FacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                end
			
				if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
					inst:LaunchProjectile()
				end
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
    },

    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "disappear",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            PlayExtendedSound(inst, "disappear")
            inst.AnimState:PlayAnimation("disappear")
            inst.Physics:Stop()
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },

    State{
        name = "hit",
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.Physics:Stop()
            PlayExtendedSound(inst, "disappear")
            inst.AnimState:PlayAnimation("disappear")
        end,

        events =
        {
            EventHandler("animover", function(inst)
				local x0, y0, z0 = inst.Transform:GetWorldPosition()
				for k = 1, 4 --[[# of attempts]] do
					local x = x0 + math.random() * 20 - 10
					local z = z0 + math.random() * 20 - 10
					if TheWorld.Map:IsPassableAtPoint(x, 0, z) and #TheSim:FindEntities(x, 0, z, 3, { "player" }) == 0 then
						inst.Physics:Teleport(x, 0, z)
                        break
                    end
                end

                inst.sg:GoToState("appear")
            end),
        },
    },
}

--CommonStates.AddWalkStates(states)

return StateGraph("um_heckler", states, events, "appear")
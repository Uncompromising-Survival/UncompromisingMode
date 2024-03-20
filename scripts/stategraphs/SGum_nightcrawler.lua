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

local actionhandlers =
{
	ActionHandler(ACTIONS.PICKUP, "steal"),
}

local events =
{
	EventHandler("death", function(inst) inst.sg:GoToState("death") end),
	EventHandler("locomote", function(inst) 
        if not inst.sg:HasStateTag("busy") then
            
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("moving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("attack_pre", data.target)
        end
    end),
}

local states =
{
	State {
		name = "idle",
		tags = { "idle" },
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PushAnimation("idle")
		end,

        events=
        {
            EventHandler("animover", function(inst) 
				inst.sg:GoToState("idle") 
			end)
        },
	},
	
    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            PlayExtendedSound(inst, "idle")
            inst.components.locomotor:WalkForward()
			
			if inst.fat then
				inst.AnimState:PlayAnimation("walk_fat", true)
			else
				inst.AnimState:PlayAnimation("walk", true)
			end
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
        name = "attack_pre",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_pre")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("attack_loop") end)
        },
    },

    State{
        name = "attack_loop",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_loop")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
			if inst.components.combat.target ~= nil and inst:IsNear(inst.components.combat.target, 3) then
				inst.components.combat.target.components.health:DoDelta(-1)
			end
        end,

        events =
        {
            EventHandler("animover", function(inst) 
				if inst.components.combat.target ~= nil and inst:IsNear(inst.components.combat.target, 3) then
					inst.sg:GoToState("attack_loop")
				else
					inst.sg:GoToState("attack_pst")
				end
			end)
        },
    },

    State{
        name = "attack_pst",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("attack_pst")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },
	
	State{
        name = "death",
        tags = {"busy", "death", "nointerrupt"},

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.components.locomotor:StopMoving()
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

    },

	State{
		name = "steal",
		tags = {"busy"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat")
		end,
		
		timeline=
		{
			
			TimeEvent(5*FRAMES, function(inst)
				inst:PerformBufferedAction() 
				PlayExtendedSound(inst, "taunt")
			end),
		},
		
		
		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		}, 		
	},
}

return StateGraph("um_nightcrawler", states, events, "appear", actionhandlers)
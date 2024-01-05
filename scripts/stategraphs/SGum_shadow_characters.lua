require("stategraphs/commonstates")

local actionhandlers = 
{
    ActionHandler(ACTIONS.INVESTIGATE, "investigate"),
}

local events=
{
    EventHandler("attacked", function(inst) 
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("no_stun") and not inst.sg:HasStateTag("attack") and not inst:HasTag("INLIMBO") then 
            inst.sg:GoToState("hit")  -- can't attack during hit reaction
        end 
    end),
    EventHandler("doattack", function(inst, data) 
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("evade") and data and data.target and not inst:HasTag("INLIMBO") then 
			inst.sg:GoToState("attack_swilson", data.target) 
        end 
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst:HasTag("INLIMBO") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),    
}

local function SpawnSwilsonCopies(inst)
	RemovePhysicsColliders(inst)
	local rot = inst.Transform:GetRotation()
	inst.rotation = 1
	local health = 0.33
	if inst.components.health:GetPercent() > 0.33 then
		health = 0.66
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	for i = 1,3 do
		local swilson = SpawnPrefab("swilson")
		RemovePhysicsColliders(swilson)
		swilson.components.health:SetPercent(health)
		swilson.Transform:SetPosition(x,y,z)
		swilson.rotation = i+1
		swilson:AddTag("splitting")
		swilson:AddTag("INLIMBO")
		swilson.Transform:SetRotation(rot)
		swilson.sg:GoToState("split")
	end
end

local function AmLast(inst)
	if FindEntity(inst,100,function(inst) return inst.prefab == "swilson" end) == nil then
		return true
	end
end

local states=
{
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
			if inst.prefab == "swilson" and AmLast(inst) then
				inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			end
        end,
		timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
        },
    },
    State{
        name = "death_split",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
			inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death",false)
        end,
		timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
        },
        events=
        {
            EventHandler("animover", function(inst)
				SpawnSwilsonCopies(inst)
				inst.sg:GoToState("split") 
			end),
        },
    },  
    State{
        name = "split",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.Physics:Stop()
            inst.AnimState:SetPercent("death",1)
			inst.sg:SetTimeout(5)
			inst.radius = 0
			if inst.rotation == 1 then
				inst.angle = 0
			elseif inst.rotation == 2 then
				inst.angle = 3.14/2
			elseif inst.rotation == 3 then
				inst.angle = 3.14
			elseif inst.rotation == 4 then
				inst.angle = 3.14*3/2
			end
			local x,y,z = inst.Transform:GetWorldPosition()
			inst.x = x
			inst.y = y
			inst.z = z
        end,
		timeline=
        {
            ---TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			---TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			---TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
        },
		onupdate = function(inst)
			inst.radius = inst.radius + 0.01
			inst.angle = inst.angle + 0.1
			inst.Transform:SetPosition(inst.x+inst.radius*math.cos(inst.angle),inst.y,inst.z+inst.radius*math.sin(inst.angle))
		end,
        ontimeout = function(inst)
			inst.sg:GoToState("death_reverse")
        end,
    }, 
    State{
        name = "death_reverse",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.Physics:Stop()
			local x,y,z = inst.Transform:GetWorldPosition()
			MakeCharacterPhysics(inst, 10, .5)
			inst.Transform:SetPosition(x,y,z)
            inst.AnimState:PlayAnimation("death",true)
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
			--inst.AnimState:SetFrame(inst.AnimState:GetCurrentAnimationLength())
			inst.AnimState:SetDeltaTimeMultiplier(-0.5)
        end,
		timeline=
        {
            ---TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			---TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			---TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
        },
		ontimeout = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
			inst:RemoveTag("INLIMBO")
			inst:RemoveTag("splitting")
			if math.random() > 0.3 then
				inst.sg:GoToState("idle")
			else
				inst.sg:GoToState("taunt")
			end
		end,
    },  
    State{
        name = "enter",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
            inst.AnimState:PlayAnimation("jump")
        end,
		timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			TimeEvent(18*FRAMES, function(inst) inst.sg:GoToState("idle") end),
        },
	},

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,
        
        timeline=
        {
            TimeEvent(3*FRAMES, PlayFootstep),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },
    
    State{
        name = "moving",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("run_loop")
        end,
        
        timeline=
        {
            TimeEvent(4*FRAMES, PlayFootstep),
            TimeEvent(8*FRAMES, PlayFootstep),
        },
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
        
    },    
    
    
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        ontimeout = function(inst)
			inst.sg:GoToState("taunt")
        end,
        
        onenter = function(inst)
            inst.Physics:Stop()
            local animname = "idle"
            if math.random() < .3 then
				inst.sg:SetTimeout(math.random()*2 + 2)
			end

			inst.AnimState:PlayAnimation("idle", true)

        end,
    },



    State{
        name = "taunt",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emote_fistshake")
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },    
    
    State{
        name = "investigate",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,
        
        events=
        {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("idle")
            end),
        },
    },    
    
    State{
        name = "attack_swilson", -- Psuedo Leap
        tags = {"attack", "busy", "no_stun"},
        
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk",false)
            inst.sg.statemem.target = target
			inst.AnimState:SetDeltaTimeMultiplier(0.6)
        end,
        
        timeline=
        {
			TimeEvent(2*FRAMES, function(inst) inst.AnimState:SetDeltaTimeMultiplier(0.2) end),
			TimeEvent(28*FRAMES, function(inst) 
				inst.AnimState:SetDeltaTimeMultiplier(1)
				if inst.components.combat and inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
				inst.Physics:SetMotorVelOverride(50,0,0)
			end),
            TimeEvent(31*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
            TimeEvent(32*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			TimeEvent(36*FRAMES, function(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
				inst.Physics:SetMotorVelOverride(0,0,0)
				inst.Physics:Stop()			
			end),
        },
		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,
        onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end,
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("moving") end),
        },
    },

    State{
        name = "hit",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },    
    
    State{
        name = "hit_stunlock",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) 
            inst.sg:GoToState("idle") 
            end ),
        },
    },  
}

CommonStates.AddFrozenStates(states)

return StateGraph("um_shadow_characters", states, events, "idle", actionhandlers)


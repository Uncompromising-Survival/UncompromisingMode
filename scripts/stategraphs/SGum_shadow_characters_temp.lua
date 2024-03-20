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
			if inst.prefab == "swilson" then
				inst.sg:GoToState("attack_swilson", data.target) 
			elseif inst.prefab == "swathgrithr" then -- For now, only use wilson attack
				inst.sg:GoToState("twirl_swathgrithr", data.target) --Initiate with swilson's longer windup
			end
        end 
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("locomote", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) and not inst:HasTag("INLIMBO") then
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
	local x,y,z = inst.Transform:GetWorldPosition()
	local swilsons = TheSim:FindEntities(x,y,z,100,{"shadowchar_swilson"})
	for i,v in ipairs(swilsons) do
		if v ~= inst and v.components.health and not v.components.health:IsDead() then
			return false -- There's another that's not me, and is not dead
		end
	end
	return true -- Made it through, I'm truly the last
end

local function SendBabaIsYou(inst)
	if inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) < 12^2 then
		local anomen = SpawnPrefab("swathgrithr_labotomized")
		anomen.Transform:SetPosition(inst.Transform:GetWorldPosition())
		anomen.LabAttack(anomen,inst,inst.components.combat.target)
		inst.AnimState:PlayAnimation("lunge_pre",false)
	else
		inst.sg:GoToState("swathgrithr_sing")
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
			if (inst.prefab == "swilson" and AmLast(inst)) and TUNING.DSTU.SHADOW_ITEMS then --If Shadow Items from Characters are Enabled.
				inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
			end
        end,
		timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.PlaySound(inst,"death") end),
			--TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
			--TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") end),
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
            TimeEvent(3*FRAMES, function(inst) inst.PlaySound(inst,"death") end),
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
			inst.AnimState:SetDeltaTimeMultiplier(-0.5)
        end,
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
        timeline=
        {
            TimeEvent(3*FRAMES, function(inst) inst.PlaySound(inst,"taunt") end),
        },       
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },    
     State{
        name = "swathgrithr_sing",
        tags = {"busy"},
        
        onenter = function(inst)
			inst.components.health:SetAbsorptionAmount(0)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("sing_pre", false)
			inst.AnimState:PushAnimation("sing", false)
			inst.AnimState:SetDeltaTimeMultiplier(0.6)
        end,
        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst.PlaySound(inst,"sing") end),
        },     
        onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end,		
        events=
        {
            EventHandler("animqueueover", function(inst) 
				--inst.BuffShadows(inst)
				inst.components.health:SetAbsorptionAmount(0.9)
				inst.sg:GoToState("idle") 
			end),
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
        name = "attack_swilson", -- Psuedo Leap, several characters use it
        tags = {"attack", "busy", "no_stun"},
        
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
			inst.AnimState:PushAnimation("atk",false)
            inst.sg.statemem.target = target
			--inst.AnimState:SetDeltaTimeMultiplier(0.6)
        end,
        
        timeline=
        {
			TimeEvent(5*FRAMES, function(inst) inst.AnimState:SetDeltaTimeMultiplier(0) end),
			TimeEvent(28*FRAMES, function(inst) 
				inst.AnimState:SetDeltaTimeMultiplier(1)
				if inst.components.combat and inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
				inst.Physics:SetMotorVelOverride(50,0,0)
			end),
            TimeEvent(31*FRAMES, function(inst) inst.PlaySound(inst,"attack") end),
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
            EventHandler("animqueueover", function(inst)
				if inst.prefab == "swathgrithr" then -- Wigfrid combos (that's all for now)
					inst.combo = inst.combo + 1
					if inst.combo == 3 then
						inst.combo = 0
						inst.sg:GoToState("taunt")
					else
						inst.sg:GoToState("attack_swathgrithr") -- This is a combo attack
					end
				else
					inst.sg:GoToState("moving")
				end
			end),
        },
    },
	State{
        name = "attack_swathgrithr", -- First Attack for wigfrid
        tags = {"attack", "busy", "no_stun"},
        
        onenter = function(inst, target)
            inst.Physics:Stop()
			inst.Physics:SetMotorVelOverride(30,0,0)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
            inst.components.combat:StartAttack()
            --inst.AnimState:PlayAnimation("lunge_pre")
			inst.AnimState:PushAnimation("lunge_pst",false)
            inst.sg.statemem.target = target
			--inst.AnimState:SetDeltaTimeMultiplier(0.6)
			inst.sg:SetTimeout(30*FRAMES)
        end,
        
        timeline=
        {
            TimeEvent(21*FRAMES, function(inst) inst.PlaySound(inst,"attack") end),
            TimeEvent(22*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			TimeEvent(26*FRAMES, function(inst)
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
        ontimeout = function(inst)
			inst.combo = inst.combo + 1
			if inst.combo == 3 then
				inst.combo = 0
				inst.sg:GoToState("swathgrithr_sing")
			else
				inst.sg:GoToState("twirl_swathgrithr")
			end
        end,
    },
	State{
        name = "twirl_swathgrithr", -- First Attack for wigfrid
        tags = {"attack", "busy", "no_stun"},
        
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("lunge_pre",false)
            inst.sg.statemem.target = target
			inst.AnimState:SetDeltaTimeMultiplier(0.3)
			
        end,
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
            EventHandler("animover", function(inst) 
				SendBabaIsYou(inst)
            end ),
        },		
    },
    State{
        name = "attack_swathgrithr_combo", -- Combo for wigfrid
        tags = {"attack", "busy", "no_stun"},
        
        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("lunge_pre")
			inst.AnimState:PushAnimation("lunge_lag",false)
            inst.sg.statemem.target = target
			--inst.AnimState:SetDeltaTimeMultiplier(0.6)
			inst.sg:SetTimeout(20*FRAMES)
        end,
		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,        
        timeline=
        {
			TimeEvent(6*FRAMES, function(inst) 
				inst.AnimState:SetDeltaTimeMultiplier(1)
				if inst.components.combat and inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
				inst.Physics:SetMotorVelOverride(50,0,0)
			end),
            TimeEvent(11*FRAMES, function(inst) inst.PlaySound(inst,"attack") end),
            TimeEvent(12*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
			TimeEvent(16*FRAMES, function(inst)
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
        ontimeout = function(inst)
			inst.combo = inst.combo + 1
			if inst.combo == 3 then
				inst.combo = 0
				inst.sg:GoToState("swathgrithr_sing")
			else
				inst.sg:GoToState("attack_swathgrithr_combo")
			end
        end,
    },
    State{
        name = "hit",
        tags = {"hit"},
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

return StateGraph("um_shadow_characters_temp", states, events, "idle", actionhandlers)


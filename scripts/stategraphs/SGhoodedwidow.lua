require("stategraphs/commonstates")
local easing = require("easing")

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "jumphome"),
}

local function ShootWebBomb(inst)
	if inst.components.combat and inst.components.combat.target then
		local target = inst.components.combat.target
		local web_attack = SpawnPrefab("web_bomb")
		web_attack.Transform:SetPosition(inst.Transform:GetWorldPosition())
		web_attack.components.projectile:Throw(inst, target, inst)
	end
end

local function RunningForAbility(inst) --Widow is making some space to use her ability
	if inst.components.timer and (not inst.components.timer:TimerExists("pounce") or not inst.components.timer:TimerExists("mortar")) then
		return true
	end
end

local function PlayPreyAnimations(inst) --Our Prey plays these animations
	if inst:HasTag("smallcocoon") then
		inst.AnimState:PlayAnimation("hit_small",false)
		inst.AnimState:PushAnimation("idle_small",true)
	elseif inst:HasTag("mediumcocoon") then
		inst.AnimState:PlayAnimation("hit_medium",false)
		inst.AnimState:PushAnimation("idle_medium",true)	
	else
		inst.AnimState:PlayAnimation("hit_large",false)
		inst.AnimState:PushAnimation("idle_large",true)	
	end
end

local function ReadyToLeapOrStick(inst)
	if inst.components.timer and (not inst.components.timer:TimerExists("mortar") or not inst.components.timer:TimerExists("pounce")) then
		return true
	end
end

local function Eat(inst)
	local webbedcreature = FindEntity(inst,2,nil,{"webbedcreature"})
	if webbedcreature then -- Food's here! Time to dine
		inst.prey = webbedcreature
		inst.sg:GoToState("eat_pre")
	else	-- The prey was fake or was removed before we could eat it. Bummer.
		inst.prey = nil
	end
end


local events=
{
    EventHandler("attacked", function(inst) 
		if not inst.components.health:IsDead() and not inst.sg:HasStateTag("ability") and not inst.sg:HasStateTag("attack") and not RunningForAbility(inst) then 
			inst.sg:GoToState("hit") 
		end
		if inst.sg:HasStateTag("eating") then -- If we're eating we definately need to go to hit
			inst.components.timer:StartTimer("pounce",math.random(5,10)) --Restart Pounce (Make her do it soon)
			inst.components.timer:StartTimer("mortar",math.random(20,30)) --Restart Mortar
			inst.sg:GoToState("hit") 
		end
	end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data)
		if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
			inst.sg:GoToState("attack", data.target)
		end
    end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnFreeze(),
}

local function ShadowFade(inst)
	inst.scaleFactor = inst.scaleFactor - 0.01
	inst.Transform:SetScale(inst.scaleFactor, inst.scaleFactor, inst.scaleFactor)
	if inst.scaleFactor < 0.05 then
		inst:Remove()
	end
end

local splashprefabs =
{
    "web_splash_fx_melted",
    "web_splash_fx_low",
    "web_splash_fx_med",
    "web_splash_fx_full",
}

local function WebMortar(inst,angle)
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
		local theta = inst.Transform:GetRotation()+angle
		theta = theta*DEGREES
		targetpos.x = targetpos.x + 15*math.cos(theta)
		targetpos.z = targetpos.z - 15*math.sin(theta)
		
		projectile.components.complexprojectile:SetHorizontalSpeed(20)
		projectile.components.complexprojectile:Launch(targetpos, inst, inst)
	end
end

local function Watercheck(inst)
	local angle = inst.Transform:GetRotation()
	local x,y,z = inst.Transform:GetWorldPosition()
	x = x + 4*math.cos(angle)
	z = z + 4*math.sin(angle)
	return not TheWorld.Map:IsVisualGroundAtPoint(x,y,z)
end


local function Charge_ReAssess(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local targets = TheSim:FindEntities(x,y,z,6,{"_combat"},{"webbedcreature"})
	local should_attack = false
	local should_exit = false
	local should_turnaround = false
	local should_climb = false
	for i,target in ipairs(targets) do
		local angle = inst:GetAngleToPoint(target:GetPosition())
		local my_angle = inst.Transform:GetRotation()
		if target and ((math.abs(angle-my_angle) < 60 and inst:GetDistanceSqToInst(target) < 12^2)) then
			--TheNet:Announce("Told To Attack")
			should_attack = true
		end
	end
	if inst.components.combat and not inst.components.combat.target then
		--TheNet:Announce("Told To Exit (No Target)")
		should_exit = true
	else
		local angle = inst:GetAngleToPoint(inst.components.combat.target:GetPosition())
		local my_angle = inst.Transform:GetRotation()
		if math.abs(angle-my_angle) > 90 and math.abs(angle-my_angle) < 270 and inst:GetDistanceSqToInst(inst.components.combat.target) > 14^2  then
			TheNet:Announce("Told To Turn Around (Not Facing Target)")
			should_turnaround = true
		end
	end
	
	if Watercheck(inst) then
		--TheNet:Announce("Told To Turn Around (Water)")
		should_turnaround = true
	end
	
	if should_turnaround and inst.turns > 0 then
		--TheNet:Announce("Reducing Turns")
		inst.turns = inst.turns - 1
		TheNet:Announce(inst.turns)
	elseif should_turnaround then
		--TheNet:Announce("Told To Exit (No more Turns)")
		should_turnaround = false
		should_exit = true
	end
	
	if inst.treetarget and inst:GetDistanceSqToInst(inst.treetarget) < 2^2 then
		TheNet:Announce("climb!")
		should_climb = true
	end
	
	-- Decide what to do
	if should_climb then
		inst.sg:GoToState("climb_pre") -- Begin our Ascent
	elseif should_exit then
		inst.sg:GoToState("chargeover")
	elseif should_turnaround and not inst.treetarget then
		inst.sg:GoToState("chargeturnaround")
	elseif should_attack and not inst.treetarget then
		inst.sg:GoToState("chargeattack")
	else
		inst.sg:GoToState("charge")
	end
end

local function DecideWhatTreeToBe(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local trees = TheSim:FindEntities(x,y,z,20,{"giant_tree"})
	local mindist = 99999
	for i,tree in ipairs(trees) do
		local treedist = inst:GetDistanceSqToInst(tree)
		if treedist < mindist then
			inst.treetarget = tree
			mindist = treedist
		end
	end
end

local function ChargeTurn(inst)
	inst.Physics:SetMotorVelOverride(inst.chargespeed*inst.components.locomotor.walkspeed*inst.components.locomotor:GetSpeedMultiplier(),0,0) -- Bear traps work...
	if inst.treetarget then
		inst:ForceFacePoint(inst.treetarget:GetPosition())
	else
		if inst.components.combat and inst.components.combat.target and inst.components.combat.target:IsValid() then
			local angle = inst:GetAngleToPoint(inst.components.combat.target:GetPosition())
			local my_angle = inst.Transform:GetRotation()

			local max_turning = 2 -- Only allow a certain maximum turning speed
			if angle > my_angle and math.abs(angle-my_angle) > 3 and inst.turn_speed < max_turning then
				inst.turn_speed = inst.turn_speed + 0.1
			elseif angle < my_angle and math.abs(angle-my_angle) > 3 and inst.turn_speed > -max_turning then
				inst.turn_speed = inst.turn_speed - 0.1
			end
			
			
			if math.abs(angle-my_angle) > 90 and math.abs(angle-my_angle) < 270 and inst:GetDistanceSqToInst(inst.components.combat.target) > 12^2 then
				if inst.turns > 0 then
					inst.turns = inst.turns - 1
					inst.sg:GoToState("chargeturnaround")
				elseif not inst.go_up_fucking_tree then
					inst.sg:GoToState("chargeover")
				elseif not inst.treetarget then
					DecideWhatTreeToBe(inst)
					if inst.treetarget then
						inst.sg:GoToState("chargeturnaround")
					else
						inst.sg:GoToState("chargeover")
					end
				end
			end
			--TheNet:Announce("turning")
			inst.Transform:SetRotation(my_angle+inst.turn_speed)
		else
			inst.sg:GoToState("chargeover")
		end
	end
	
	--[[--Knockback Task (Scrapped, was unfun)
	local x,y,z = inst.Transform:GetWorldPosition()
	local entities = TheSim:FindEntities(x,y,z,4,{"_health"},{"webbedcreature"})
	for i,other in ipairs(entities) do
		if other and other.components.inventory and not other:HasTag("fat_gang") and not other:HasTag("foodknockbackimmune") and not other.sg:HasStateTag("knockback") and
			--Don't knockback if you wear marble
			(other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == nil or not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("marble") and not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("knockback_protection")) then
			--other.tempknockbackimmune = other:DoTaskInTime(1,function(other) other.tempknockbackimmune = nil end)
			other:PushEvent("knockback", { knocker = inst, radius = 30, strengthmult = 1 })
		end
	end]]
end

local function ChargeAttacked(inst) --Cone attack (beef it up if it's too lenient)
	local x,y,z = inst.Transform:GetWorldPosition()
	local targets = TheSim:FindEntities(x,y,z,inst.components.combat:GetHitRange(),{"_combat"},{"webbedcreature","ghost"})
	for i,target in ipairs(targets) do
		local angle = inst:GetAngleToPoint(target:GetPosition())
		local my_angle = inst.Transform:GetRotation()
		if target and (math.abs(angle-my_angle) < 90 or inst:GetDistanceSqToInst(target) < 3^2) and target ~= inst then -- Relatively wide, but not completely to her side. (FUCKING SHE WAS KILLING HERSELF GODDAMN IT)
			target.components.combat:GetAttacked(inst,inst.components.combat.defaultdamage)
		end
	end
end

local states=
{

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
			--if inst.should_go_tired then
				--inst.should_go_tired = false
				--inst.sg:GoToState("tired")
			--else
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("idle", true)
				if math.random() < .2 then
					inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
				end
			--end
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
			if inst.prey then --If we manage to pull off a melee attack, we should forget about trying to heal
				inst.prey = nil
			end
			--if math.random() < 0.5/inst.combo and inst.components.health and inst.components.health.currenthealth < 8000*TUNING.DSTU.WIDOW_HEALTH*0.5 then
				--inst.docombo = true
				--if inst.combo == 1 then
					--inst.combosucceed = false
				--end
			--end
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
        end,

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack") end),
            TimeEvent(25*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(30*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/swipe") end),
            TimeEvent(30*FRAMES, function(inst) 
			--inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
			inst.components.combat:DoAttack()
			end),
        },

        events=
        {
            EventHandler("animover", function(inst)
				
				--if inst.components.health and inst.components.health.currenthealth < 8000*TUNING.DSTU.WIDOW_HEALTH*0.5 and inst.docombo then
					--inst.docombo = false
					--inst.combo = inst.combo+2
					--inst.sg:RemoveStateTag("busy")
					--inst.sg:GoToState("attack")
				--else
					--if inst.combosucceed == false and inst.combo > 1 then
						--inst.combosucceed = true
						--inst.sg:GoToState("tired")
					--else
						--inst.combo = 1
						inst.sg:GoToState("idle") 
					--end
				--end 
			end),
        },
    },

  	State{
		name = "hit",
        tags = {"hit"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/hurt")
        end,

        events=
        {
			EventHandler("animover", function(inst)
				if inst.prey then --If we were hit out of snacking, then reposition
					inst.prey = nil
				end
				inst.sg:GoToState("idle") 
			end),
        },
    },

  	State{
		name = "tired",
        tags = {"busy", "ability"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("tired",false)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
	
	State{
		name = "taunt",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
		name = "eat_pre",
        tags = {"busy","eating"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
			if inst.prey then --If we have prey, face it.
				inst:ForceFacePoint(inst.prey:GetPosition())
			end
        end,

        events=
        {
			EventHandler("animover", function(inst) inst.sg:GoToState("eat_loop") end),
        },
    },

	State{
		name = "eat_loop",
        tags = {"eating"}, --not busy! we want the player to hit widow out of this

        onenter = function(inst, cb)
			inst.AnimState:SetDeltaTimeMultiplier(1.5)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
        timeline=
        {	
            TimeEvent(25*FRAMES/1.5, function(inst) 
				inst.components.health:DoDelta(200)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
				if inst.prey then
					PlayPreyAnimations(inst.prey)
				end
			end),
        },
		onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end,
		
        events=
        {
			EventHandler("animover", 
				function(inst)
					if inst.components.health and inst.components.health:GetPercent() < 1 then
						inst.sg:GoToState("eat_loop")
					else
						if inst.prey then
							inst.prey = nil
						end
						inst.sg:GoToState("idle")
					end
				end),
        },
    },
	
	State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/die")
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            RemovePhysicsColliders(inst)            
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
        
    },
    State{
        name = "launchprojectile",
        tags = {"attack", "busy", "ability"},
        
        onenter = function(inst, target)
			inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shoot_pre")
            inst.AnimState:PushAnimation("shoot_loop", false)
            inst.AnimState:PushAnimation("shoot_pst", false)
        end,
        
        
        timeline=
        {
            TimeEvent(47*FRAMES, function(inst)
				ShootWebBomb(inst)
            end),
        },
        
        events=
        {
            EventHandler("animqueueover", function(inst) 
		
			inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "lobprojectile",
        tags = {"attack", "busy", "ability"},
        
        onenter = function(inst)
			inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shoot_pre")
            inst.AnimState:PushAnimation("shoot_loop", false)
            inst.AnimState:PushAnimation("shoot_pst", false)
			inst.AnimState:SetDeltaTimeMultiplier(1.5)
        end,
        
        
        timeline=
        {
            TimeEvent(47*FRAMES/1.5, function(inst)
			if inst.components.combat and inst.components.combat.target ~= nil and inst.components.combat:CanHitTarget(inst.components.combat.target) then
				local target = inst.components.combat.target
				if target.components.pinnable ~= nil then
					target.components.pinnable:Stick("web_net_trap",splashprefabs)
					target:DoTaskInTime(1, function(target) target.components.pinnable:Unstick() end)
				end
				inst.armorcrunch = true --! Someone was WAAY too close.
				inst.sg:GoToState("attack")
			end
			WebMortar(inst,-15)
			WebMortar(inst,15)
			if inst.components.health and inst.components.health.currenthealth < 8000*TUNING.DSTU.WIDOW_HEALTH*0.66 and inst.components.health.currenthealth > 8000*TUNING.DSTU.WIDOW_HEALTH*0.33 then
				WebMortar(inst,0)
			end
			if inst.components.health and inst.components.health.currenthealth < 8000*TUNING.DSTU.WIDOW_HEALTH*0.33 then
				WebMortar(inst,-30)
				WebMortar(inst,30)
			end
			local time
			if inst.components.health:GetPercent() < 0.5 then --Under half health she speeeeds up
				time = 25+math.random(-3,5)
			else
				time = 30+math.random(-3,5)
			end
			inst.components.timer:StartTimer("mortar",time)
            end),
        },  
		onexit = function(inst)
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end,
		
        events=
        {
            EventHandler("animqueueover", function(inst)

			if not inst.components.timer:TimerExists("pounce") then --If Widow is planning on leaping get a new dodge destination
				inst.ShouldDodge(inst)
			end			
			inst.sg:GoToState("idle") end),
        },
    },
	
    State{
        name = "tossplayer", --Not Finished
        tags = {"attack", "busy", "ability"},
        
        onenter = function(inst, target)
			inst.sg.statemem.target = target
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("poop_pre")
            inst.AnimState:PushAnimation("poop_loop", false)
            inst.AnimState:PushAnimation("poop_pst", false)
        end,
        events=
        {
            EventHandler("animqueueover", function(inst) 
		
			inst.sg:GoToState("attack") end),
        },
    },
	
    State{
        name = "fall",
        tags = {"busy","noweb","ability"},
        onenter = function(inst, data)
			if inst:HasTag("notarget") then
				inst:RemoveTag("notarget")
			end
			inst.AnimState:PlayAnimation("fall")	
        end,
		timeline =
        {
            TimeEvent(10*FRAMES, function(inst) 
			inst.components.combat:DoAreaAttack(inst, TUNING.SPIDERQUEEN_ATTACKRANGE*0.8) --GroundPound Is purely visual
			inst.components.groundpounder:GroundPound() end),

        },
        events=
        {
            EventHandler("animqueueover", function(inst)
            inst.sg:GoToState("taunt") end),
        },          
    },
    State{
        name = "preleapattack",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			
			inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("prejump")
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("leapattack") end),
        },       
    },
    State{
        name = "leapattack",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.Physics:ClearCollisionMask()
			inst.Physics:CollidesWith(COLLISION.WORLD)
			local speed = 10
			if inst.components.combat.target ~= nil then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
            inst.components.locomotor:Stop()
			if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
				inst.oldtarget = inst.components.combat.target
			end
			if inst.brain then
				inst.brain:Stop()
			end
			--inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
			inst.AnimState:PlayAnimation("leap", true)
			inst.Physics:SetMotorVelOverride(speed,0,0)
        end,
		timeline =
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
			TimeEvent(20*FRAMES, function(inst) inst.components.locomotor:Stop()
			
			inst.components.combat:DoAreaAttack(inst, 1.2*TUNING.SPIDERQUEEN_ATTACKRANGE) --GroundPound Is purely visual --Had to reduce the AOE range a little bit, since Widow now tries to line up her jumps
			inst.components.groundpounder:GroundPound()
			local x,y,z = inst.Transform:GetWorldPosition()
			MakeCharacterPhysics(inst, 1000, 1)
			inst.components.locomotor.pathcaps = { ignorecreep = true }
			inst.Transform:SetPosition(x,y,z) --I know this seems strange, but if I don't the widow actually teleports 
											  --back to where it started its jump from right as MakeCharacterPhysics is called
											  --this code makes it to where it moves the queen right back to where the end of the jump left it off.
			end),
        },
        events=
        {
            EventHandler("animover", function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
			local time
			if inst.components.health:GetPercent() < 0.5 then --Under half health she speeeeds up
				time = 15+math.random(-3,5)
			else
				time = 20+math.random(-3,5)
			end
			inst.components.timer:StartTimer("pounce",time)
			
			if inst.oldtarget ~= nil and inst.components.combat ~= nil and inst.oldtarget:IsValid() then
				inst.components.combat:SuggestTarget(inst.oldtarget)
			end
			inst.sg:GoToState("idle") end),
        },       
		
		onexit = function(inst)
			if not inst.components.timer:TimerExists("mortar") then --If Widow is still planning on Mortaring, we need to get a new dodge position
				inst.ShouldDodge(inst)
			end
			if inst.brain then
				inst.brain:Start()
			end
		end,
    },
	State{
        name = "leaptoprey_pre",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
			if inst.prey then
				inst:ForceFacePoint(inst.prey:GetPosition())
			end
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("prejump")
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("leaptoprey") end),
        },       

    },
    State{
        name = "leaptoprey",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.Physics:ClearCollisionMask()
			inst.Physics:CollidesWith(COLLISION.WORLD)
			local speed = inst:GetDistanceSqToInst(inst.prey)^0.5/(FRAMES*20)
			if inst.components.combat.target ~= nil then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
            inst.components.locomotor:Stop()
			if inst.prey then
				inst:ForceFacePoint(inst.prey:GetPosition())
			end
			if inst.brain then
				inst.brain:Stop()
			end
			--inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
			inst.AnimState:PlayAnimation("leap", true)
			inst.Physics:SetMotorVelOverride(speed,0,0)
        end,
		timeline =
        {
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
			TimeEvent(20*FRAMES, function(inst) inst.components.locomotor:Stop()
			
			--inst.components.combat:DoAreaAttack(inst, 1.2*TUNING.SPIDERQUEEN_ATTACKRANGE) --GroundPound Is purely visual --Had to reduce the AOE range a little bit, since Widow now tries to line up her jumps
			--inst.components.groundpounder:GroundPound()
			local x,y,z = inst.Transform:GetWorldPosition()
			MakeCharacterPhysics(inst, 1000, 1)
			inst.components.locomotor.pathcaps = { ignorecreep = true }
			inst.Transform:SetPosition(x,y,z) --I know this seems strange, but if I don't the widow actually teleports 
											  --back to where it started its jump from right as MakeCharacterPhysics is called
											  --this code makes it to where it moves the queen right back to where the end of the jump left it off.
			end),
        },
        events=
        {
            EventHandler("animover", function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
				Eat(inst) 
			end),
        },       
		onupdate = function(inst)
			if inst:IsValid() and inst.prey and inst.prey:IsValid() and inst:GetDistanceSqToInst(inst.prey) < 2^2 then
				inst.Physics:SetMotorVelOverride(0,0,0)
			elseif inst.prey and not inst.prey:IsValid() then
				local x,y,z = inst.prey.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x,y,z)
				inst.Physics:SetMotorVelOverride(0,0,0)
			end
		end,
		onexit = function(inst)
			if inst.brain then
				inst.brain:Start()
			end
			if inst.components.combat then
				inst.components.combat:ResetCooldown()
			end
		end,
    },	
    State{
        name = "jumphome",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst:AddTag("notarget")
            inst.AnimState:PlayAnimation("precanopy")
			inst.AnimState:PushAnimation("canopy", false)
			if inst.components.locomotor ~= nil then -- Check to make sure 
            inst.components.locomotor:Stop()
            end
        end,

	
	  events=
        {
            EventHandler("animqueueover", function(inst) 
                inst:DoDespawn()
            end),
        },   
    },
	
    State{
        name = "precanopy",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("prejump")
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("canopyjump") end),
        },       

    },
	State{
        name = "canopyjump", --depricated
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("leap", true)
        end,
        onupdate = function(inst)
			inst.Physics:SetMotorVel(0,20,0)		
		end,
        events=
        {
            EventHandler("animover", function(inst) 
			inst:DoTaskInTime(1.5+math.random(-1,1),function(inst)inst.sg:GoToState("canopyland") end) end),
        },       

    },
    State{
        name = "canopyland",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			if inst:HasTag("notarget") then
			inst:RemoveTag("notarget")
			end
            inst.AnimState:PlayAnimation("fall")	
        end,
        
        events=
        {
            EventHandler("animqueueover", function(inst)
			inst.components.groundpounder:GroundPound()
			inst.components.combat:DoAreaAttack(inst, TUNING.SPIDERQUEEN_ATTACKRANGE * 1.2) --GroundPound Is purely visual
            inst.sg:GoToState("taunt") end),
        }, 

    },
------------------------------------------
-- Wow new states for the Widow re-re-rework
    State{
        name = "prechargeattack",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.turn_speed = 0
			inst.turns = 3
			inst.AnimState:PlayAnimation("charge_pre")
        end,
		onupdate = function(inst)
			if inst.components.combat and inst.components.combat.target then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end		
		end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst) 
				inst.Physics:ClearCollisionMask()
				inst.Physics:CollidesWith(COLLISION.WORLD)
				inst.components.locomotor:EnableGroundSpeedMultiplier(false)
				if inst.brain then
					inst.brain:Stop()
				end
				Charge_ReAssess(inst) --May need to immediately attack or turn
			end),
        },       
    },
    State{
        name = "charge",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.AnimState:PlayAnimation("charge_loop", true)
        end,
		onupdate = ChargeTurn,
		timeline =
        {
			TimeEvent(0*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(7*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(10*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(13*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(17*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(25*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(32*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(38*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },
        events=
        {
            EventHandler("animover", Charge_ReAssess),
        },
	},
    State{
        name = "chargeattack",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.AnimState:PlayAnimation("charge_strike", true)
        end,
		onupdate = ChargeTurn,
		timeline =
        {
			--Attack
            TimeEvent(0*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack") end),
            TimeEvent(0.4*25*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(0.4*30*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/swipe") end),
            TimeEvent(0.4*30*FRAMES, ChargeAttacked),
			
			--Walk
			TimeEvent(0*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(7*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(10*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(13*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(17*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(25*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(32*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(38*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },
        events=
        {
            EventHandler("animover", Charge_ReAssess),
        },
	},
    State{
        name = "chargeturnaround",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			inst.turn_speed = 0
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("charge_turn")
        end,
		onupdate = function(inst)
			if inst.treetarget then
				inst:ForceFacePoint(inst.treetarget:GetPosition())
			else
				if inst.components.combat and inst.components.combat.target then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end	
			end
		end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("charge") end),
        },       
    },
    State{
        name = "chargeover",
		tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			TheNet:Announce("ToldToStop")
			inst.Physics:ClearMotorVelOverride()
			local x,y,z = inst.Transform:GetWorldPosition()
			MakeCharacterPhysics(inst, 1000, 1)
			inst.components.locomotor.pathcaps = { ignorecreep = true }
			inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			inst.components.locomotor:Stop()
			inst.Transform:SetPosition(x,y,z)
			inst.AnimState:SetBank("widow")
			inst.AnimState:PlayAnimation("charge_pst",false)
			
			local time
			if inst.components.health:GetPercent() < 0.5 then --Under half health she speeeeds up
				time = 5
			else
				time = 5
			end
			inst.components.timer:StartTimer("pounce",time)
			inst.sg:SetTimeout(0.8) --Won't leave?
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
		onexit = function(inst)
			inst.AnimState:SetBank("widow")
			if not inst.components.timer:TimerExists("mortar") then --If Widow is still planning on Mortaring, we need to get a new dodge position
				inst.ShouldDodge(inst)
			end
			if inst.brain then
				inst.brain:Start()
			end
		end,
        ontimeout = function(inst)
            inst.sg:GoToState("tired")
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("tired") end),
        },       		
    },
	
----- Climbing related
    State{
        name = "climb_pre",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			TheNet:Announce("Told to climb")
			inst.components.locomotor:Stop()
			inst.Transform:SetSixFaced() --Climbing animations are six faced rather than four faced
			inst.AnimState:PlayAnimation("climb_pre")
			inst.currentoffset = 0
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events=
        {
            EventHandler("animqueueover", function(inst)
				inst.DynamicShadow:Enable(false)
				inst.sg:GoToState("climb") 
			end),
        },       
    },	
	
    State{
        name = "climb",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst, data)
			inst.Physics:ClearCollisionMask()
			inst.Physics:CollidesWith(COLLISION.WORLD)
			if inst.brain then
				inst.brain:Stop()
			end
			inst.AnimState:PlayAnimation("climb", true)	
        end,
		onupdate = function(inst)
			if inst.treetarget then
				inst:ForceFacePoint(inst.treetarget:GetPosition())
			end	
			--inst.Physics:SetMotorVelOverride(0,inst.chargespeed*inst.components.locomotor.walkspeed*inst.components.locomotor:GetSpeedMultiplier()/2,0)
			inst.currentoffset = inst.chargespeed*inst.components.locomotor.walkspeed*inst.components.locomotor:GetSpeedMultiplier()+inst.currentoffset --Fake the climbing.
			inst.AnimState:SetFinalOffset(inst.currentoffset)
		end,		
		timeline =
        { -- Just Walking Sounds
			TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
			TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),			
        },
        events=
        {
            EventHandler("animover", function(inst)
				if inst.currentoffset > 10*60 then
					inst.sg:GoToState("climb_wait")
				else
					inst.sg:GoToState("climb")
				end
			end),
        },       
    },	
    State{
        name = "climb_wait",
        tags = {"busy", "noweb","ability"},
        onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("hang")
        end,
		timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),

            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        }, -- Wait here, let's test to make sure it works.     
    },	
}

CommonStates.AddSleepStates(states,
	{
		sleeptimeline = {
	        TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/sleeping") end),
		},
	},
	{
		onsleep = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/fallasleep")
		end,
		onwake = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/wakeup")
		end
	}
)
local backupanim =
{
    startrun = "backup_pre",
    run = "backup_loop",
    stoprun = "backup_pst",
}


CommonStates.AddWalkStates(states,
{
	walktimeline = {
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
		TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
	},
},nil,nil,nil,
{
	startonenter = function(inst)
		if inst._dodgedest and ReadyToLeapOrStick(inst) and inst._enemypos and inst:GetDistanceSqToPoint(inst._enemypos) < inst:GetDistanceSqToPoint(inst._dodgedest) then
			inst.AnimState:SetBank("widow_backup")
			inst.AnimState:SetDeltaTimeMultiplier(-1)
		else
			inst.AnimState:SetBank("widow")
		end
	end,
	walkonexit = function(inst)
		inst.AnimState:SetDeltaTimeMultiplier(1)
	end,
})

CommonStates.AddFrozenStates(states)

-- WAS "spiderqueen" NOW "hoodedwidow" as to not replace regular spiderqueen stategraph
-- replaced "idle" with "fall" so queen always spawns from falling
return StateGraph("hoodedwidow", states, events, "fall",actionhandlers)

--You're welcome :) ~Kind Stranger
 
--Thanks ~Lureplague Guy 



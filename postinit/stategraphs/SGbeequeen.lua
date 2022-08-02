local env = env
GLOBAL.setfenv(1, GLOBAL)

local function DoScreech(inst)
    ShakeAllCameras(CAMERASHAKE.FULL, 1, .015, .3, inst, 30)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/taunt")
end

local function DoScreechAlert(inst)
    inst.components.epicscare:Scare(5)
    inst.components.commander:AlertAllSoldiers()
end

local function FaceTarget(inst)
    local target = inst.components.combat.target
    if inst.sg.mem.focustargets ~= nil then
        local mindistsq = math.huge
        for i = #inst.sg.mem.focustargets, 1, -1 do
            local v = inst.sg.mem.focustargets[i]
            if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("playerghost") then
                local distsq = inst:GetDistanceSqToInst(v)
                if distsq < mindistsq then
                    mindistsq = distsq
                    target = v
                end
            else
                table.remove(inst.sg.mem.focustargets, i)
                if #inst.sg.mem.focustargets <= 0 then
                    inst.sg.mem.focustargets = nil
                    break
                end
            end
        end
    end
    if target ~= nil and target:IsValid() then
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
    end
end

local function AdjustGuardSpeeds(inst,speed)
	local soldiers = inst.components.commander:GetAllSoldiers()
	if #soldiers > 0 then
		for i, soldier in ipairs(soldiers) do	
			if soldier.components.health and not soldier.components.health:IsDead() then
				soldier.chargeSpeed = speed
			end
		end
	end		
end

local function PutArmyToSleep(inst)
	local soldiers = inst.components.commander:GetAllSoldiers()
	if #soldiers > 0 then
		for i, soldier in ipairs(soldiers) do	
			if soldier.components.health and not soldier.components.health:IsDead() and soldier.components.sleeper then
				soldier.components.sleeper:GoToSleep(20)
			end
		end
	end	
end

local function SetSpinSpeed(inst,speed,changeDir)
	if inst.beeHolder then
		for i, beeHolder in ipairs(inst.beeHolder) do	
			beeHolder.components.linearcircler.setspeed = speed
		end
	end
end

local function StartFlapping(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/wings_LP", "flying")
end

local function RestoreFlapping(inst)
    if not inst.SoundEmitter:PlayingSound("flying") then
        StartFlapping(inst)
    end
end

local function StopFlapping(inst)
    inst.SoundEmitter:KillSound("flying")
end

local function VVallcheck(inst)
	if inst.defensebees then
		for i,bee in ipairs(inst.defensebees) do
			if bee.components.health and not bee.components.health:IsDead() then
				return true
			end
		end
	end
end

local function ShouldVVall(inst)
	if inst.components.health:GetPercent() < 0.75 and not inst.defensebee and inst.defenseready then
		inst.defenseready = nil
		return true
	elseif inst.components.health:GetPercent() < 0.75 and not inst.defensebee then
		inst.defenseready = true
		return false
	else
		return false
	end
end

local function SpinVVall(inst,speed)
	if inst.defensebees then
		for i,bee in ipairs(inst.defensebees) do
			if bee.components.health and not bee.components.health:IsDead() and bee.components.linearcircler then
				bee.components.linearcircler.setspeed = speed
			end
		end
	end
end

local function MortarCommand(inst)
	if inst.components.health and not inst.components.health:IsDead() then
		if inst.components.health:GetPercent() < 0.75 then
			inst.should_seeker_rage = true
			inst.sg:GoToState("spawnguards_seeker")
		else
			inst.sg:GoToState("command_mortar")
		end
	end
end

local function HasShootersOrSeekers(inst)
	if inst.shooterbees then
		for i,bee in ipairs(inst.shooterbees) do
			if bee.components.health and not bee.components.health:IsDead() then
				return false
			end
		end
	end
	if inst.extrabees then
		for i,bee in ipairs(inst.extrabees) do
			if bee.components.health and not bee.components.health:IsDead() then
				return false
			end
		end
	end
	if inst.shooterbeeline then
		for i,bee in ipairs(inst.shooterbeeline) do
			if bee.components.health and not bee.components.health:IsDead() then
				return false
			end
		end		
	end
	return true
end

local function MakeSeekerHitlist(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x,y,z,40,{"player"},{"playerghost"})
	inst.seeker_hitlist = players
end
env.AddStategraphPostInit("SGbeequeen", function(inst) --For some reason it's called "SGbeequeen" instead of just... beequeen, funky
	
	local _OldOnExit 
	if inst.states["spawnguards"].onexit then
		_OldOnExit = inst.states["spawnguards"].onexit
	end
	inst.states["spawnguards"].onexit = function(inst)
		inst.should_focus = true
		if _OldOnExit then
			_OldOnExit(inst)
		end
		if inst.components.health and inst.components.health:GetPercent() < 1 then
			if ShouldVVall(inst) then --Should I spavvn vvall bees
				if math.random() < 0.9 then --Should I fake out the player and vvait a moment to do my thing
					inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("spawnguards_vvall") end)
				else
					inst:DoTaskInTime(math.random(3,6),function(inst) 
						if inst.components.health and not inst.components.health:IsDead() then
							inst.sg:GoToState("spawnguards_vvall")
						end
					end)
				end
			else
				if inst.components.health:GetPercent() < 1 then
					if math.random() < 0.9 then --Should I fake out the player and vvait a moment to 
						inst:DoTaskInTime(0,MortarCommand)
					else
						inst:DoTaskInTime(math.random(3,6),MortarCommand)
					end
				end
			end
		end
	end
	
	local _OldOnAtk
	if inst.states["attack"].onexit then
		_OldOnAtk = inst.states["attack"].onexit
	end
	inst.states["attack"].onexit = function(inst)
		if _OldOnAtk then
			_OldOnAtk(inst)
		end
        local soldiers = inst.components.commander:GetAllSoldiers()
		if inst.should_final then
			if inst.should_seeker_rage then
				inst.should_seeker_rage = nil
			end
			inst.should_final = nil
			inst.ffcount = 5
			inst.FinalFormation(inst)
		else
			if VVallcheck(inst) and inst.components.health and inst.components.health:GetPercent() > 0.4 then
				inst.defensivespincount = inst.defensivespincount - 1
				if inst.defensivespincount < 1 then
					inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("defensive_spin") end)
				end
			else
				if inst.ShouldChase(inst) and inst.should_seeker_rage then
					if not inst.seekerrage and inst.components.health and inst.components.health:GetPercent() < 0.75 then
						inst.should_seeker_rage = nil
						MakeSeekerHitlist(inst)
						inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("spawnguards_seeker_quick") end)
					end
				end
			end
			if inst.ShouldChase(inst) and inst.should_shooter_rage and inst.should_shooter_rage < 1 and not inst.should_seeker_rage then
				inst.should_shooter_rage = 30
				
				if math.random() > 0.25 then
					inst:DoTaskInTime(0,function(inst) 
					
						local x,y,z = inst.Transform:GetWorldPosition()
						local targets = TheSim:FindEntities(x,y,z,40,{"player"},{"playerghost","bee"})
						inst.shoottargets = targets
						inst.sg:GoToState("spawnguards_shooter_circle") 
					end)
				else
					inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("spawnguards_seeker") end)
				end
			end
		end
	end
	

local events=
	{        
	}

local states = {
    State{
        name = "stomp",
        tags = { "busy", "nosleep", "nofreeze", "ability" },

        onenter = function(inst)
			--inst.brain:Stop()
            --StopFlapping(inst)
            inst.Transform:SetNoFaced()
            inst.components.locomotor:StopMoving()
            inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("stomp_pre")
			inst.AnimState:PushAnimation("stomp",false)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/enter")
            inst.sg.mem.wantstoscreech = true
        end,

        timeline =
        {
            CommonHandlers.OnNoSleepTimeEvent(38 * FRAMES, function(inst)
				local function isvalid(ent)
					local tags = { "INLIMBO", "epic", "notarget", "invisible", "noattack", "flight", "playerghost", "shadow", "shadowchesspiece", "shadowcreature","bee","beehive"}
					for i,v in ipairs(tags) do
						if ent:HasTag(v) then
							return false
						end
					end
					return true
				end
				local x,y,z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x,y,z,8,"_combat")
				for i,ent in ipairs(ents) do
					if (isvalid(ent)) and ent.components.health and not ent.components.health:IsDead() and ent.components.combat then --Support for the other sort of bees
						ent.components.combat:GetAttacked(inst,200)
					end
				end
				inst.components.groundpounder:GroundPound()
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("screech"),
        },

        onexit = function(inst)
            --RestoreFlapping(inst)
            inst.Transform:SetSixFaced()
            inst.components.health:SetInvincible(false)
        end,
    },
	
    State{
        name = "command_mortar",
        tags = { "busy", "nosleep", "nofreeze", "ability"  },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("command2")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, DoScreech),
            TimeEvent(9 * FRAMES, DoScreechAlert),
            TimeEvent(11 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/attack_pre")
            end),
            TimeEvent(18 * FRAMES, function(inst)
                inst.sg.mem.wantstofocustarget = nil

                local soldiers = inst.components.commander:GetAllSoldiers()
                if #soldiers > 0 and inst.components.combat and inst.components.combat.target then
					for i, soldier in ipairs(soldiers) do
						soldier:MortarAttack(soldier)
					end  
                end
				if inst.seekerbees then
					for i,seeker in ipairs(inst.seekerbees) do
						if not seeker.sg:HasStateTag("mortar") then
							local x,y,z = seeker.Transform:GetWorldPosition()
							seeker:RemoveComponent("linearcircler")
                            if x ~= nil and y ~= nil and z ~= nil then 
                                seeker.Transform:SetPosition(x,y,z)
                            end
							seeker:MortarAttack(seeker)
						end
					end
				end
            end),
            CommonHandlers.OnNoSleepTimeEvent(25 * FRAMES, function(inst)
                inst.sg:AddStateTag("caninterrupt")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },
		
        onexit = function(inst)
			inst.components.sanityaura.aura = 0
        end,
		
        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },

    },
	
    State{
        name = "command_charge_pre",
        tags = {"busy", "nosleep", "nofreeze", "ability"},

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("command2")
			inst.AnimState:PushAnimation("idle_loop",true)
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, DoScreech),
            TimeEvent(9 * FRAMES, DoScreechAlert),
            TimeEvent(11 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/attack_pre")
            end),
            CommonHandlers.OnNoSleepTimeEvent(25 * FRAMES, function(inst)
                inst.sg:AddStateTag("caninterrupt")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },
		
        onexit = function(inst)
			inst.components.sanityaura.aura = 0
			inst.chargeTask = inst:DoPeriodicTask(0.1, function(inst) inst:CheckForReadyCharge(inst) end)
			--inst.components.timer:StartTimer("mortar_atk", 20)
        end,
		
        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },

    },

    State{
        name = "defensive_spin",
        tags = {"busy", "ability" },

        onenter = function(inst)
			inst.defensivespincount = math.random(3,5)
			if inst.components.timer:TimerExists("spin_bees") then
				inst.components.timer:StopTimer("spin_bees")
			end
			inst.AnimState:PlayAnimation("command1")
			inst.AnimState:PushAnimation("command3",false)
            FaceTarget(inst)
            inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE
            inst.components.locomotor:StopMoving()

			SpinVVall(inst,0.1)
        end,
		
        timeline =
        {
            TimeEvent(8 * FRAMES, DoScreech),
            TimeEvent(9 * FRAMES, DoScreechAlert),
            TimeEvent(11 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/attack_pre")
            end),
        },	

		onexit = function(inst)
			SpinVVall(inst,0)
			inst.components.sanityaura.aura = 0		
		end,
		
        events=
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
	
    State{
        name = "tired", --Bee Queen is Tired after rapidly commanding the army
        tags = {"busy", "ability","tired"},

        onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("tired_pre")
			inst.AnimState:PushAnimation("tired_loop",true)
			if not inst.tiredcount then
				inst.tiredcount = 9
			end
			inst.sg:SetTimeout(inst.tiredcount)
        end,
		
        timeline =
        {
            TimeEvent(9 * FRAMES, StopFlapping),
        },		
		
        ontimeout = function(inst)
			inst.tiredcount = nil
			inst.sg:GoToState("tired_pst")
        end, 		

    },
    State{
        name = "tired_pst", --Bee Queen is Tired after rapidly commanding the army
        tags = {"busy", "ability" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("tired_pst")
        end,
		
        events=
        {
            EventHandler("animover", function(inst)
				StartFlapping(inst)
                inst.sg:GoToState("idle")
            end),
        },	

    },
    State{
        name = "spawnguards_vvall",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)

				if inst.components.health:GetPercent() > 0.4 or math.random() > 0.9 then
					inst.SpawnDefensiveBees(inst)
				else
					if inst.components.health:GetPercent() > 0.25 then
						inst.SpawnDefensiveBeesII(inst)
					else
						inst.defensivecircle = true
						inst.SpawnShooterBeesCircle(inst)
					end
				end
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
    },
    State{
        name = "spawnguards_shooter_circle",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
			if inst.components.health and inst.components.health:GetPercent() < 0.25 then
				inst:DoTaskInTime(math.random(12,20),function(inst) inst.should_final = true end)
			end
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
				local priotarget = inst.shoottargets[1]
				table.remove(inst.shoottargets,1)
				inst.SpawnShooterBeesCircle(inst,priotarget)
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
		onexit = function(inst) --Unfinished business, need to shoot more ppl.
			if inst.shoottargets[1] then
				inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("spawnguards_shooter_circle") end)
			end
		end,
    },
    State{
        name = "spawnguards_shooter_line",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
					inst.SpavvnShooterBeesLine(inst,3,inst.ffdir)
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
    },
    State{
        name = "spavvn_support",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
					inst.SpawnSupport(inst)
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
    },
    State{
        name = "spawnguards_seeker",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
				inst.SpawnSeekerBees(inst)
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
				inst:DoTaskInTime(0,function(inst) inst.sg:GoToState("command_mortar") end)
            end),
        },

        events =
        {
            --CommonHandlers.OnNoSleepAnimOver("command_mortar"), --for some reason this isn't vvorking, taunting happens instead, so dotaskintime(0 is just going to have to be hovv vve do it in these heavy edit postinit casess
        },
    },
    State{
        name = "spawnguards_seeker_quick",
        tags = { "spawnguards", "busy", "nosleep", "nofreeze" },

        onenter = function(inst)
            FaceTarget(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("spawn")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/spawn")
			inst.seekercount = inst.seekercount - 1
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, function(inst)
				inst.SpawnSeekerBees(inst)
            end),
            CommonHandlers.OnNoSleepTimeEvent(32 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nosleep")
                inst.sg:RemoveStateTag("nofreeze")
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },
		onexit = function(inst)
				local target 
				if inst.seeker_hitlist then
					local possibletarget = inst.seeker_hitlist[inst.seekercount + 1]
					if possibletarget and possibletarget.components.health and not possibletarget.components.health:IsDead() and not possibletarget:HasTag("playerghost") then
						target = possibletarget
					else
						local choice = math.random(1,#inst.seeker_hitlist)
						possibletarget = inst.seeker_hitlist[choice]
						if possibletarget and possibletarget.components.health and not possibletarget.components.health:IsDead() and not possibletarget:HasTag("playerghost") then
							target = possibletarget
						else
							target = inst.components.combat.target
						end
					end
				else
					target = inst.components.combat.target
				end
				if target then
					if inst.seekerbees then
						for i,seeker in ipairs(inst.seekerbees) do
							if not seeker.sg:HasStateTag("mortar") then
								local x,y,z = seeker.Transform:GetWorldPosition()
								seeker:RemoveComponent("linearcircler")
                                if x ~= nil and y ~= nil and z ~= nil then 
                                    seeker.Transform:SetPosition(x,y,z)
                                end
                                seeker:MortarAttack(seeker,inst.components.combat.target,0.5)
							end
						end
					end
				end
				inst:DoTaskInTime(0,function(inst)
					if inst.seekercount > 0 then
						inst.sg:GoToState("spawnguards_seeker_quick")
					else
						if inst.components.health:GetPercent() < 0.25 then
							inst:DoTaskInTime(math.random(12,20),function(inst) inst.should_final = true end)
						end
						inst.seekercount = math.random(4,5)
						inst.tiredcount = 10
						inst.sg:GoToState("tired")
					end
				end)
		end,
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


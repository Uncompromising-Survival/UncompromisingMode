local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

local function DisableThatStuff(inst)
	TheWorld:PushEvent("beequeenkilled")
		
	if TheWorld.net ~= nil then
		TheWorld.net:AddTag("queenbeekilled")
	end
	
	SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "Hayfever_Stop"), nil)
end
env.AddPrefabPostInit("beeguard", function(inst)
	inst:AddTag("ignorewalkableplatforms")
end)

local function VVallcheck(inst)
	if inst.defensebees then
		for i,bee in ipairs(inst.defensebees) do
			if bee.components.health and not bee.components.health:IsDead() then
				return true
			end
		end
	end
end

local function AbilityRage(inst) --Reserved for those trying to kill BQ vvithout her having all bees dead, not a punishment, an alternative. (So that her special bees actually do stuff)
	local percent = inst.components.health:GetPercent()
	if percent > 0.75 then
		inst.sg:GoToState("spawnguards") --No ability yet, I'll just spavvn guards.
	end
	if percent < 0.75 and percent > 0.5 then
		if math.random() > 0.5 then --AHA I have some abilities. 
			if VVallcheck(inst) then
				inst.sg:GoToState("defensive_spin")
			else
				inst.sg:GoToState("spawnguards_vvall")
			end
		else
			inst.sg:GoToState("spawnguards_seeker_quick")
		end
	end
	if percent < 0.5 and percent > 0.25 then
		if math.random() > 0.5 then --VVall or shooters...
			if VVallcheck(inst) then
				inst.sg:GoToState("defensive_spin")
			else
				inst.sg:GoToState("spawnguards_vvall")
			end
		else
			inst.sg:GoToState("spawnguards_shooter_circle")
		end
	end
	if percent < 0.25 then
		if math.random() > 0.66 then
			inst.sg:GoToState("spawnguards_shooter_circle")
		else
			if math.random() > 0.5 then
				inst.sg:GoToState("spawnguards_seeker_quick")
			else
				inst.FinalFormation(inst)
			end
		end
	end
end

local function StompHandler(inst,data)
	--TheNet:Announce(inst.stomprage)
	--[[if inst.components.health and inst.components.health:GetPercent() > 0.5 then --fast fovvard to the 3rd phase
		inst.components.health:SetPercent(0.49)
	end]]
	local soldiers = inst.components.commander:GetAllSoldiers()
	if #soldiers > 0 then --This is added if the player is exploiting BQ having only like... one bee, and preventing the natural proc for any sort of ability to happen.
		inst.abilityrage = inst.abilityrage + 1
		if inst.abilityrage > 15 then --This number is the threshold of hits, vve don't necessarily need to make them NOT like attacking her like this, just not allovv her to bee cheesed.
			inst.abilityrage = 0
			AbilityRage(inst)
		end
	end
	
	if inst.components.health and inst.components.health:GetPercent() < 0.5 and not inst.sg:HasStateTag("busy") then
		local soldiers = inst.components.commander:GetAllSoldiers()
		if #soldiers > 0 then
			inst.sg:GoToState("focustarget")
		end
		inst.should_shooter_rage = inst.should_shooter_rage -1
	end
	if inst.components.health and inst.components.health:GetPercent() < 0.75 then
		if inst.sg:HasStateTag("tired") then
			inst.AnimState:PlayAnimation("tired_hit")
			inst.AnimState:PushAnimation("tired_loop",true)
		end

		inst.stomprage = inst.stomprage + 1

		if data.attacker and data.attacker.components.combat and inst.stompready then
			inst.prioritytarget = data.attacker
			if inst.components.combat.target ~= nil then
				if data.attacker ~= inst.components.combat.target then
					inst.stomprage = inst.stomprage + 4
				end
			end
			local x,y,z = data.attacker.Transform:GetWorldPosition()
			if TheWorld.Map:GetPlatformAtPoint(x, z) ~= nil then
				inst.stomprage = inst.stomprage + 10
			end
			if inst.stomprage > 20 and not inst.sg:HasStateTag("ability") and inst.components.health and not inst.components.health:IsDead() then
				inst:ForceFacePoint(x,y,z)
				inst.stomprage = 0
				inst.stompready = false
				inst:DoTaskInTime(math.random(3,5),function(inst) inst.stompready = true end)
				inst.sg:GoToState("stomp")
			end
		end
	end
end

local function StompRageCalmDown(inst)
	if inst.stomprage < 3 then
		inst.stomprage = 0
	else
		inst.stomprage = inst.stomprage - 3
	end
end

local function SpavvnShooterBeesLine(inst,time,back)
	local x,y,z = inst.Transform:GetWorldPosition()
	local LIMIT = 10
	local target = FindEntity(inst,40^2,nil,{"player"},{"playerghost"})
	if not target then
		target = FindEntity(inst,40^2,nil,{"_combat"},{"playerghost"})
	end
	local total = 8
	local dist = 13
	if back then
		dist = -dist
	end
	local spacing = 4
	local randomness = math.random()
	local aligned = math.random()
	if target and target:IsValid() then
		inst.shooterbeeline = {}
		for i = 1,total do
			inst.shooterbeeline[i] = SpawnPrefab("um_beeguard_shooter")
			inst.shooterbeeline[i].queen = inst
			inst.shooterbeeline[i].target = target

			inst.shooterbeeline[i].components.linearcircler:SetCircleTarget(inst)
			inst.shooterbeeline[i].components.linearcircler.grounded = true
			inst.shooterbeeline[i].components.linearcircler:Start()
			inst.shooterbeeline[i].components.linearcircler.randAng = i*0.125
			inst.shooterbeeline[i].components.linearcircler.clockwise = false
			inst.shooterbeeline[i].components.linearcircler.distance_limit = LIMIT
			inst.shooterbeeline[i].components.linearcircler.setspeed = 0.05
			
			inst.shooterbeeline[i].components.timer:StartTimer("natural_death", time)
			inst.shooterbeeline[i].components.entitytracker:TrackEntity("queen", inst)
			inst.shooterbeeline[i].line = true
			inst.shooterbeeline[i]:DoTaskInTime(0.1,function(bee) 
				if bee.components.health and not bee.components.health:IsDead() then
					local x,y,z = bee.Transform:GetWorldPosition()
					bee:RemoveComponent("linearcircler")
					bee.Transform:SetPosition(x,y,z)
					bee.sg:GoToState("flyup_shooter") 
				end 
			end)
			inst.shooterbeeline[i]:DoPeriodicTask(FRAMES,function(bee) 
				if bee.target and bee:IsValid() then 
					bee:ForceFacePoint(bee.target:GetPosition()) 
				end 
			end)
			
			inst.shooterbeeline[i].pos1 = target:GetPosition()
			inst.shooterbeeline[i].pos1.x = inst.shooterbeeline[i].pos1.x + dist
			inst.shooterbeeline[i].pos2 = target:GetPosition()
			inst.shooterbeeline[i].pos2.x = inst.shooterbeeline[i].pos2.x - dist
			
			if aligned > 0.5 then
				inst.shooterbeeline[i].pos1.z = inst.shooterbeeline[i].pos1.z + spacing*((i)-(total+1)/2)+randomness
				inst.shooterbeeline[i].pos2.z = inst.shooterbeeline[i].pos2.z + spacing*((i)-(total+1)/2)+randomness
			else
				inst.shooterbeeline[i].pos1.z = inst.shooterbeeline[i].pos1.z + spacing*((i)-(total)/2)
				inst.shooterbeeline[i].pos2.z = inst.shooterbeeline[i].pos2.z + spacing*((i)-(total)/2)			
			end
		end
		randomness = -math.random()
		for i = 1,total do
			local j = i + total
			inst.shooterbeeline[j] = SpawnPrefab("um_beeguard_shooter")
			inst.shooterbeeline[j].queen = inst
			inst.shooterbeeline[j].target = target

			inst.shooterbeeline[j].components.linearcircler:SetCircleTarget(inst)
			inst.shooterbeeline[j].components.linearcircler.grounded = true
			inst.shooterbeeline[j].components.linearcircler:Start()
			inst.shooterbeeline[j].components.linearcircler.randAng = i*0.125
			inst.shooterbeeline[j].components.linearcircler.clockwise = false
			inst.shooterbeeline[j].components.linearcircler.distance_limit = LIMIT
			inst.shooterbeeline[j].components.linearcircler.setspeed = 0.05
			
			inst.shooterbeeline[j].components.timer:StartTimer("natural_death", time)
			inst.shooterbeeline[j].components.entitytracker:TrackEntity("queen", inst)
			inst.shooterbeeline[j].line = true
			inst.shooterbeeline[j]:DoTaskInTime(0.1,function(bee) 
				if bee.components.health and not bee.components.health:IsDead() then
					local x,y,z = bee.Transform:GetWorldPosition()
					bee:RemoveComponent("linearcircler")
					bee.Transform:SetPosition(x,y,z)
					bee.sg:GoToState("flyup_shooter") 
				end 
			end)
			inst.shooterbeeline[j]:DoPeriodicTask(FRAMES,function(bee) 
				if bee.target and bee:IsValid() then 
					bee:ForceFacePoint(bee.target:GetPosition()) 
				end 
			end)
			
			inst.shooterbeeline[j].pos1 = target:GetPosition()
			inst.shooterbeeline[j].pos1.z = inst.shooterbeeline[j].pos1.z + dist
			inst.shooterbeeline[j].pos2 = target:GetPosition()
			inst.shooterbeeline[j].pos2.z = inst.shooterbeeline[j].pos2.z - dist
			
			if aligned < 0.5 then
				inst.shooterbeeline[j].pos1.x = inst.shooterbeeline[j].pos1.x + spacing*((i)-(total+1)/2)+randomness
				inst.shooterbeeline[j].pos2.x = inst.shooterbeeline[j].pos2.x + spacing*((i)-(total+1)/2)+randomness
			else
				inst.shooterbeeline[j].pos1.x = inst.shooterbeeline[j].pos1.x + spacing*((i)-(total)/2)
				inst.shooterbeeline[j].pos2.x = inst.shooterbeeline[j].pos2.x + spacing*((i)-(total)/2)			
			end
		end
	end
end

local function SpawnShooterBeesCircle(inst, prioritytarget)
	local x,y,z = inst.Transform:GetWorldPosition()
	local LIMIT = 4
	local target = FindEntity(inst,40^2,nil,{"player"},{"playerghost"})
	if not target then
		target = FindEntity(inst,40^2,nil,{"_combat"},{"playerghost"})
	end
	if prioritytarget then
		--TheNet:Announce("setting priority target")
		target = prioritytarget
	end
	if target then
		inst.shooterbees = {}
		for i = 1,8 do
			inst.shooterbees[i] = SpawnPrefab("um_beeguard_shooter")
			inst.shooterbees[i].queen = inst
			inst.shooterbees[i].target = target
			inst.shooterbees[i].components.linearcircler:SetCircleTarget(inst)
			inst.shooterbees[i].components.linearcircler.grounded = true
			inst.shooterbees[i].components.linearcircler:Start()
			inst.shooterbees[i].components.linearcircler.randAng = i*0.125
			inst.shooterbees[i].components.linearcircler.clockwise = false
			inst.shooterbees[i].components.linearcircler.distance_limit = LIMIT
			inst.shooterbees[i].components.linearcircler.setspeed = 0.05
			inst.shooterbees[i].time = 1+0.5*i
			if inst.defensivecircle then
				inst.shooterbees[i].components.timer:StartTimer("epic",2+0.5*i)
			end
			inst.shooterbees[i].count = i
			inst.shooterbees[i].components.entitytracker:TrackEntity("queen", inst)
			if not inst.defensivecircle then
				inst.shooterbees[i].circle = true
				inst.shooterbees[i]:DoTaskInTime(2,function(bee) if bee.components.health and not bee.components.health:IsDead() then bee.sg:GoToState("flyup_shooter") end end)
			end
			inst.shooterbees[i]:DoPeriodicTask(FRAMES,function(bee) 
				if bee.target and bee:IsValid() then 
					bee:ForceFacePoint(bee.target:GetPosition()) 
				end 
			end)
			--inst.lavae[i].AnimState:PushAnimation("hover",true)
		end
	end
	if inst.defensivecircle then
		inst.defensivecircle = nil
	end
end

local function SpawnDefensiveBeesII(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local LIMIT = 5
	inst.defensebees = {}
	for i = 1,8 do
		inst.defensebees[i] = SpawnPrefab("um_beeguard_blocker")
		inst.defensebees[i].queen = inst
		inst.defensebees[i].components.linearcircler:SetCircleTarget(inst)
		inst.defensebees[i].components.linearcircler:Start()
		inst.defensebees[i].components.linearcircler.randAng = i*0.125*3/5
		inst.defensebees[i].components.linearcircler.clockwise = false
		inst.defensebees[i].components.linearcircler.distance_limit = LIMIT
		inst.defensebees[i].components.linearcircler.setspeed = 0.05
		inst.defensebees[i].components.timer:StartTimer("natural_death", math.random(60,75))
		inst.defensebees[i].components.entitytracker:TrackEntity("queen", inst)
		--inst.lavae[i].AnimState:PushAnimation("hover",true)
	end
end

local function SpawnDefensiveBees(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local LIMIT = 4
	inst.defensebees = {}
	for i = 1,8 do
		inst.defensebees[i] = SpawnPrefab("um_beeguard_blocker")
		inst.defensebees[i].queen = inst
		inst.defensebees[i].components.linearcircler:SetCircleTarget(inst)
		inst.defensebees[i].components.linearcircler:Start()
		inst.defensebees[i].components.linearcircler.randAng = i*0.125*4/5
		inst.defensebees[i].components.linearcircler.clockwise = false
		inst.defensebees[i].components.linearcircler.distance_limit = LIMIT
		inst.defensebees[i].components.linearcircler.setspeed = 0
		inst.defensebees[i].components.timer:StartTimer("natural_death", math.random(60,75))
		inst.defensebees[i].components.entitytracker:TrackEntity("queen", inst)
		--inst.lavae[i].AnimState:PushAnimation("hover",true)
	end
end

local function SpawnSeekerBees(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local rangeLIMIT = 5
	if not inst.seekerbees then
		inst.seekerbees = {}
	end
	local totalseekers
	if inst.components.health:GetPercent() < 0.5 then
		totalseekers = 12
	else
		totalseekers = 8
	end
	for i = 1,totalseekers do
		inst.seekerbees[i] = SpawnPrefab("um_beeguard_seeker")
		inst.seekerbees[i].queen = inst
		inst.seekerbees[i].components.linearcircler:SetCircleTarget(inst)
		inst.seekerbees[i].components.linearcircler:Start()
		inst.seekerbees[i].components.linearcircler.randAng = i*1/totalseekers
		inst.seekerbees[i].components.linearcircler.clockwise = false
		inst.seekerbees[i].components.linearcircler.distance_limit = rangeLIMIT
		inst.seekerbees[i].components.linearcircler.setspeed = 0.1
		inst.seekerbees[i].components.entitytracker:TrackEntity("queen", inst)
	end
end

local function SpawnSupport(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local LIMIT = 4
	inst.extrabees = {}
	local MAXBEES = 1
	local players = TheSim:FindEntities(x,y,z,30,{"player"},{"playerghost"})
	if inst.components.health and inst.components.health:GetPercent() < 0.5 then
		MAXBEES = 2*#players
	elseif inst.components.health then
		MAXBEES = #players
	end
	for i = 1,MAXBEES do
		local beetype
		if inst.components.health and inst.components.health:GetPercent() < 0.5 then
			if math.random() < 0.25 then
				beetype = "um_beeguard_seeker"
			else
				beetype = "um_beeguard_shooter"
			end
		elseif inst.components.health then
			beetype = "um_beeguard_seeker"
		end
		inst.extrabees[i] = SpawnPrefab(beetype)
		inst.extrabees[i].queen = inst
		inst.extrabees[i].components.linearcircler:SetCircleTarget(inst)
		inst.extrabees[i].components.linearcircler:Start()
		inst.extrabees[i].components.linearcircler.randAng = i*1/MAXBEES
		inst.extrabees[i].components.linearcircler.clockwise = false
		inst.extrabees[i].components.linearcircler.distance_limit = LIMIT
		inst.extrabees[i].components.linearcircler.setspeed = 0.1
		if beetype == "um_beeguard_shooter" then
			inst.extrabees[i].components.timer:StartTimer("natural_death", i+math.random(2,3))
		end
		inst.extrabees[i].components.entitytracker:TrackEntity("queen", inst)
		--inst.lavae[i].AnimState:PushAnimation("hover",true)
	end
end

local function RedoSpavvnguard_cd(inst)
	inst.spawnguards_threshold = 20 --threshhold is primarily related ot the spavvn times rather than number of bees novv...
	if inst.components.health and inst.components.health:GetPercent() > 0.75 then
		return math.random(40,60)
	elseif inst.components.health then
		if inst.components.health:GetPercent() < 0.75 and inst.components.health:GetPercent() > 0.5 then
			return math.random(30,40)
		else
			return math.random(70,80)
		end
	end
	inst.sg:GoToState("spawnguards")
end

local function ShouldChase(inst) --All the cases that BQ shouldn't chase the player: Grumble bees are alive, shooter bees are alive, extra bees are alive (extra bees are shooter/seeker)
	local soldiers = inst.components.commander:GetAllSoldiers()
	if #soldiers > 0 then
		return false
	else
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
end

local PHASE2_HEALTH = .75
local PHASE3_HEALTH = .5
local PHASE4_HEALTH = .25

local function FinalFormation(inst)
	inst.sg:GoToState("spawnguards_shooter_line")
	inst.ffcount = inst.ffcount - 1
	if inst.ffdir then
		inst.ffdir = nil
	else
		inst.ffdir = true
	end
	local time = 2
	if inst.ffcount > 0 then
		inst:DoTaskInTime(time,FinalFormation)
	else
		inst:DoTaskInTime(time,function(inst)
			inst.tiredcount = 12
			inst.sg:GoToState("tired")
		end)
	end
end

env.AddPrefabPostInit("beequeen", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	if TUNING.DSTU.VETCURSE ~= "off" then
		inst:AddComponent("vetcurselootdropper")
		inst.components.vetcurselootdropper.loot = "um_beegun"
	end
	
    inst.Physics:CollidesWith(COLLISION.FLYERS)
	
	if inst.components.health ~= nil then
		inst.components.health:SetMaxHealth(TUNING.BEEQUEEN_HEALTH)
	end
	
	inst:AddComponent("groundpounder") --Groundpounder is visual only
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 0
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.platformPushingRings = 2
    inst.components.groundpounder.numRings = 1
	inst:ListenForEvent("death", DisableThatStuff)
	--inst:ListenForEvent("death", ReleasebeeHolders)
	
	inst.stomprage = 0
	inst.stompready = true
	inst:DoPeriodicTask(3, StompRageCalmDown)
	inst:ListenForEvent("attacked", StompHandler)
	
	
	inst.chargeTask = nil
	inst.chargeCount = 0
	
	
	
	-- No more honey when attacking
	local OnMissOther = UpvalueHacker.GetUpvalue(Prefabs.beequeen.fn, "OnMissOther")
	local OnAttackOther = UpvalueHacker.GetUpvalue(Prefabs.beequeen.fn, "OnAttackOther")
    inst:RemoveEventCallback("onattackother", OnAttackOther)
    inst:RemoveEventCallback("onmissother", OnMissOther)
	

	inst.ShouldChase = ShouldChase
	inst.SpawnDefensiveBees = SpawnDefensiveBees
	inst.SpawnDefensiveBeesII = SpawnDefensiveBeesII
    inst.components.healthtrigger:AddTrigger(PHASE2_HEALTH, function(inst) 
		inst:DoTaskInTime(0, function(inst)
			RedoSpavvnguard_cd(inst)
		end)
	end)
    inst.components.healthtrigger:AddTrigger(PHASE3_HEALTH, function(inst) inst:DoTaskInTime(0, RedoSpavvnguard_cd) end)
    inst.components.healthtrigger:AddTrigger(PHASE4_HEALTH, function(inst) inst:DoTaskInTime(0, RedoSpavvnguard_cd) end)
	--inst:DoTaskInTime(5,SpawnDefensiveBees)
	
	inst.spawnguards_cd = RedoSpavvnguard_cd(inst)
	inst.SpawnSeekerBees = SpawnSeekerBees
	inst.seekercount = math.random(4,5)
	inst.defensivespincount = math.random(3,5)
	inst.spawnguards_threshold = 20
	inst.should_shooter_rage = 20
	inst.abilityrage = 0
	inst.SpawnShooterBeesCircle = SpawnShooterBeesCircle
	inst.SpawnSupport = SpawnSupport
	inst.SpavvnShooterBeesLine = SpavvnShooterBeesLine
	inst.FinalFormation = FinalFormation
end)

local function OnTagTimer(inst, data)
	if data.name == "hivegrowth" then
		TheWorld:PushEvent("beequeenrespawned")
		if TheWorld.net ~= nil then
			TheWorld.net:RemoveTag("queenbeekilled")
		end
		
		SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "Hayfever_Start"), nil)
	end
end

env.AddPrefabPostInit("beequeenhive", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst:ListenForEvent("timerdone", OnTagTimer)
end)
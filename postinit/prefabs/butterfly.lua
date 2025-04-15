local env = env
GLOBAL.setfenv(1, GLOBAL)

if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" then
	local function Slippy(inst, target, speed, distancemod) -- Reduced from wixie_shove to something only applicable to the butterfly
		local x,y,z = inst.Transform:GetWorldPosition()
		for i = 1, 50 do
			inst:DoTaskInTime((i - 1) / 50, function(inst)
				local tx, ty, tz = target.Transform:GetWorldPosition()
					
				if tx ~= nil then
					local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
					local velx = math.cos(rad)
					local velz = -math.sin(rad)
													
					local distancemultiplier = distancemod ~= nil and 1 + (distancemod / 10) or 1
					local dx, dy, dz = tx + ((((3 / (i + 2)) * velx))) / distancemultiplier, ty, tz + ((((3 / (i + 2)) * velz))) / distancemultiplier
					target.Transform:SetPosition(dx, dy, dz)
				end											
			end)
		end
	end

	local function SittingStill(statename)
		return statename and statename == "pollinate" or statename == "land_idle" or statename == "frozen" or statename == "thaw"
	end
	
	local function ByPassWeapon(weapon)
		return weapon and (weapon.prefab == "bugzapper")
	end
	
	local function ByStimuli(stimuli)
		return stimuli and (stimuli == "soul" or stimuli == "projectile")
	end
	
	local function SlipAway(inst,data)
		local statename = inst.sg.currentstate.name

		
		local weapon = data.attacker.components.combat and data.attacker.components.combat:GetWeapon() or nil
		if weapon then
			TheNet:Announce(weapon.prefab)
		end
		if data and data.attacker and (not SittingStill(statename) and not ByPassWeapon(weapon) and not ByStimuli(data.stimuli)) then -- Can only attack when idle
			inst.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop")
			if inst.components.health then
				inst.components.health:SetPercent(1)
			end
			
			Slippy(data.attacker,inst)
			if data.attacker.components.talker then
				data.attacker.components.talker:Say(GetString(data.attacker, "ANNOUNCE_BUTTERFLY_SLIP"))
			end
		else --  any other condition needs to instantly kill the butterfly, feigning having 1 health
			inst.components.health:Kill()
		end
	end



	local function BozoUpdate(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x,y,z,8,{"_health"},{"structure","smallcreature"})
		local mindist = 12
		if ents then
			for i,v in ipairs(ents) do
				if (inst:GetDistanceSqToInst(v))^0.5 < mindist then
					mindist = inst:GetDistanceSqToInst(v)^0.5
				end
			end
		end
		if mindist < 8 then
			local statename = inst.sg.currentstate.name
			if statename == "pollinate" or statename == "land_idle" and not inst.takeoff then
				inst.takeoff = 	inst:DoTaskInTime(1,function(inst)
					local statename = inst.sg.currentstate.name
					if statename == "pollinate" or statename == "land_idle" and TheWorld.state.isday then
						inst.sg:GoToState("takeoff")
					end
					inst.takeoff = nil				
				end)
			elseif inst.bufferedaction and TheWorld.state.isday then
				inst.bufferedaction = nil
			elseif statename == "idle" and mindist < 4 and TheWorld.state.isday then --uhoh getting close! 
				inst.sg:GoToState("moving")
			else
				local speed = 6
				speed = 12 - mindist 
				
				if speed > 8 then -- clamp the speed at some maximum value
					speed = 8
				end
				inst.components.locomotor.runspeed = speed
				inst.components.locomotor.walkspeed = speed
			end	
			
		else
			inst.components.locomotor.runspeed = 6
			inst.components.locomotor.walkspeed = 4
		end
	end
	
	local function CheckForNearbyBozos(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x,y,z,12,{"_health"},{"structure","smallcreature"})
		if #ents > 0 and not inst.active_monitoring then
			inst.active_monitoring = inst:DoPeriodicTask(FRAMES,BozoUpdate)
		elseif inst.active_monitoring then
			inst.active_monitoring:Cancel()
			inst.active_monitoring = nil
		end
	end

	env.AddPrefabPostInit("butterfly", function(inst)

		if not TheWorld.ismastersim then
			return
		end
		inst.components.health:SetAbsorptionAmount(1)
		inst.components.health:SetMaxHealth(5) -- needs to have health > 1 for it to not immediately get KO-ed
		inst:ListenForEvent("attacked",SlipAway)
		
		inst.components.locomotor.runspeed = 4 -- faster flying
		inst.components.locomotor.walkspeed = 4 -- faster flying
		
		inst:AddComponent("playerprox")
		
		inst:DoPeriodicTask(2,CheckForNearbyBozos)
	end)

	local ranged = {"blowdart_sleep","blowdart_fire","blowdart_pipe","blowdart_yellow","um_blowdart_rime","um_blowdart_pyre","boomerang"}
	for i,v in ipairs(ranged) do
		env.AddPrefabPostInit(v, function(inst)

			if not TheWorld.ismastersim then
				return
			end
			inst.components.projectile.stimuli = "projectile"
		end)
	end


	local function ReEnableButterfly(inst)
		if inst.spawned_butterfly then
			inst.spawned_butterfly = nil
		end
	end
	
	local flower_types = {"flower","flower_evil"}
	for i,v in ipairs(flower_types) do
		env.AddPrefabPostInit(v, function(inst)
			if not TheWorld.ismastersim then
				return
			end
			inst:WatchWorldState("isday",ReEnableButterfly)
		end)
	end

	local FLOWER_TAGS = { "flower" }
	local BUTTERFLY_TAGS = { "butterfly" }
	
	local function GetSpawnPoint(player)
		local rad = 25
		local mindistance = 36
		local x, y, z = player.Transform:GetWorldPosition()
		local flowers = TheSim:FindEntities(x, y, z, rad, FLOWER_TAGS)

		for i, v in ipairs(flowers) do
			while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance or (v ~= nil and v.spawned_butterfly) do
				table.remove(flowers, i)
				v = flowers[i]
			end
		end
		
		local chosen_flower
		if next(flowers) then
			chosen_flower = flowers[math.random(1, #flowers)]
			chosen_flower.spawned_butterfly = true
			
		end
		return chosen_flower ~= nil and chosen_flower or nil
	end

	local UpvalueHacker = require("tools/upvaluehacker")
	env.AddComponentPostInit("butterflyspawner", function(cmp)
		local _GetSpawnPoint, _fn_i, scope_fn = UpvalueHacker.GetUpvalue(cmp.OnPostInit, "ToggleUpdate", "ScheduleSpawn", "SpawnButterflyForPlayer", "GetSpawnPoint")

		debug.setupvalue(scope_fn, _fn_i,GetSpawnPoint)
	end)	
end
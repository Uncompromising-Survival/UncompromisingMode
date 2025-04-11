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
		return weapon and (weapon.prefab == "bugzapper" or weapon:HasTag("rangedweapon") or weapon:HasTag("projectile")) and not weapon.prefab == "icestaff"
	end
	
	local function ByStimuli(stimuli)
		return stimuli and (stimuli == "soul")
	end
	
	local function SlipAway(inst,data)
		local statename = inst.sg.currentstate.name
		--TheNet:Announce(statename)

		if data.stimuli then
			--TheNet:Announce(data.stimuli)
		end
		local weapon = data.attacker.components.combat:GetWeapon() or nil
		if weapon then
			--TheNet:Announce(weapon.prefab)
		end
		--TheNet:Announce(data.attacker.prefab)
		if data and data.attacker and (not SittingStill(statename) and not ByPassWeapon(weapon) and not ByStimuli(data.stimuli)) then -- Can only attack when idle
			if not (weapon and weapon.prefab == "icestaff") then -- ice staff doesn't kill but doesn't slip either
				inst.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop")
				if inst.components.health then
					inst.components.health:SetPercent(1)
				end
				
				Slippy(data.attacker,inst)
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
					if statename == "pollinate" or statename == "land_idle" then
						inst.sg:GoToState("takeoff")
					end
					inst.takeoff = nil				
				end)
			elseif inst.bufferedaction then
				inst.bufferedaction = nil
			elseif statename == "idle" and mindist < 4 then --uhoh getting close! 
				inst.sg:GoToState("moving")
			else
				local speed = 6
				speed = 12 - mindist 
				
				if speed > 10 then -- clamp the speed at some maximum value
					speed = 10
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
end
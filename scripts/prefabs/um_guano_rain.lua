local function CheckGuanoStatus(x,y,z)
	local high = 0
	local med = 0
	local low = 0
	local impacted_rock
	local impacted_guano
	local gems = 0
	local fertilizers = TheSim:FindEntities(x,y,z,24,{"fertilizerresearchable"}) --#AXE technically any rock counts
	local guano_rocks = TheSim:FindEntities(x,y,z,36,{"guano_rock"})
	local too_close
	
	local guanos = {}
	for i,v in ipairs(fertilizers) do
		if v.prefab == "guano" then
			table.insert(guanos,v)
			if v:GetDistanceSqToPoint(Vector3(x,y,z)) < (4*math.random(2,3))^2 then --AXE Need a little spacing between each rock.
				too_close = true
			end
			if v:GetDistanceSqToPoint(Vector3(x,y,z)) < 4 then --AXE the guano managed to land on top of a poop.
				impacted_guano = v
			end
		end
	end
	
	for i,v in ipairs(guano_rocks) do
		if v:GetDistanceSqToPoint(Vector3(x,y,z)) < 4 then --AXE the guano managed to land on top of a rock.
			impacted_rock = v
		end
		if v:GetDistanceSqToPoint(Vector3(x,y,z)) < (4*math.random(2,3))^2 then --AXE Need a little spacing between each rock.
			too_close = true
		end
		if v.tier == 3 then
			high = high + 1
		elseif v.tier == 2 then
			med = med + 1
		elseif v.tier == 1 then
			low = low + 1
		end
		if v.prefab == "um_guano_rock" then
			gems = gems + 1
		end
	end
	return high, med, low, gems, impacted_rock, impacted_guano, too_close, guanos, guano_rocks
end

local DAMAGE_ONEOF_TAGS = {"NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }


local function ContributeToPoopSociety(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
		if math.random() > 0.75 then
		local high, med, low, gems, impacted_rock, impacted_guano, too_close, guanos, guano_rocks = CheckGuanoStatus(x,y,z)
		
		if impacted_rock then
			if impacted_rock.tier == 2 and high < (med + 1) then
				impacted_rock.UpgradeTier(impacted_rock,3)
			end
			if impacted_rock.tier == 1 and med < (low + 2) then
				impacted_rock.UpgradeTier(impacted_rock,2)
			end
		else
			if impacted_guano then
				local prefab = "um_guano_rock_gemless"
				if math.random() > 0.75 then 
					prefab = "um_guano_rock"
				end
				local rock = SpawnPrefab(prefab)
				rock.tier = 1
				rock:DoTaskInTime(0.1,function(rock)
					rock.AnimState:PlayAnimation("low_grow_0")
					rock.AnimState:PushAnimation("low_0")
				end)
				
				local structure_ents = TheSim:FindEntities(x, 0, z, 2,nil,nil,DAMAGE_ONEOF_TAGS)
				for i,v in ipairs(structure_ents) do
					if not (v.prefab == "um_guano_rock" or v.prefab == "um_guano_rock_gemless") then 
						SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
						v.components.workable:Destroy(inst)					
					end
				end
				impacted_guano:Remove()
				rock.Transform:SetPosition(x,y,z)
			elseif (not guanos or (guanos and #guanos) < 5) and not too_close then
				local poop = SpawnPrefab("guano")
				poop.Transform:SetPosition(x,y,z)
				poop.AnimState:PlayAnimation("idle")
			end
		end
	end	
	--AXE hit players in the head
	local ents = TheSim:FindEntities(x, 0, z, 2, {"_sanity"})
	for i, v in ipairs(ents) do
		if v:IsValid() then 
			if v.prefab == "wormwood" then
				v.components.sanity:DoDelta(5)
			else
				v.components.combat:GetAttacked(inst, 3)
				v.components.sanity:DoDelta(-10)
			end
		end
	end


end

local function FreeFallin(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local scaleFactor = Lerp(.5, 1.5, y / 35)
	inst.shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
    if y <= .2 then
		ContributeToPoopSociety(inst)
		SpawnPrefab("snowball_shatter_fx").Transform:SetPosition(x,y,z)
		inst.SoundEmitter:PlaySound("dontstarve/frog/splat")
		
		inst.shadow:Remove()
		inst.updatetask:Cancel()
		inst.updatetask = nil
		
		inst:Hide()
		inst:DoTaskInTime(2,function(inst) --AXE need to give it some time to emit the sound
			inst:Remove()
		end)
	end	
end

local function BeginFreeFallin(inst)
	if math.random() > 0.5 then
		inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/"..(math.random() > 0.75 and "taunt" or "flap"))
	end
	if inst.entity:IsAwake() then --AXE if this prefab spawns whenever there's no player nearby, it must be removed immediately so it doesn't set up the Periodic Task below.
		inst.AnimState:SetDeltaTimeMultiplier(.1)
		local x,y,z = inst.Transform:GetWorldPosition()
		inst.Transform:SetPosition(x,y+30,z)
		inst.AnimState:PlayAnimation("dump")
		inst.shadow = SpawnPrefab("warningshadow")
		inst.shadow:ListenForEvent("onremove", function(inst) inst.shadow:Remove() end, inst)
		inst.shadow.Transform:SetPosition(x, 0, z)
		inst.updatetask = inst:DoPeriodicTask(FRAMES, FreeFallin)
	else
		inst:Remove()
	end
end

local function fnparticle()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("guano")
    inst.AnimState:SetBuild("guano")
    

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
	inst:DoTaskInTime(0,BeginFreeFallin)
	
	inst.persists = false
    return inst
end

	

local function GenerateSomeGuanoStuffsOffScreen(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local high, med, low, gems, impacted_rock, impacted_guano, too_close, guanos, guano_rocks = CheckGuanoStatus(x,y,z)
	for i = 1,6 do
		if #guano_rocks > 16 then
			if #guanos < 10 then
				local offset = FindWalkableOffset(inst:GetPosition(), TWOPI*math.random(), math.random(4,32),64)
				local guano = SpawnPrefab("guano")
				guano.Transform:SetPosition(x+offset.x,0,z+offset.z)
			end
		else
			if high < 3 and med > 0 then
				for i,v in ipairs(guano_rocks) do
					if v.tier == 2 then
						v.UpgradeTier(v,3)
						break
					end
				end
			elseif med < 7 and low > 0 then
				for i,v in ipairs(guano_rocks) do
					if v.tier == 1 then
						v.UpgradeTier(v,2)
						break
					end
				end		
			else
				local offset = FindWalkableOffset(inst:GetPosition(), TWOPI*math.random(), math.random(4,32),64)
				local prefab = "um_guano_rock_gemless"
				if math.random() > 0.8 then
					prefab = "um_guano_rock"
				end
				local rock = SpawnPrefab(prefab)
				rock.Transform:SetPosition(x+offset.x,y,z+offset.z)
				rock.tier = math.random(1,2)
			end
		end
	end
	
end

local function SpawnGuanoRain(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local offset = FindWalkableOffset(inst:GetPosition(), TWOPI*math.random(), math.random(4,32),64)
	local guano_rain = SpawnPrefab("um_guano_rain_particle")
	guano_rain.Transform:SetPosition(x+offset.x,y,z+offset.z)
end

local function MoreBATS(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local bats = TheSim:FindEntities(x,y,z,128,{"bat"})
	if #bats < 15 then
		local offset = FindWalkableOffset(inst:GetPosition(), TWOPI*math.random(), math.random(4,32),64)
		for i = 1,math.random(5,15) do
			local bat = SpawnPrefab("bat")
			bat.Transform:SetPosition(x+offset.x,y,z+offset.z)
			bat.sg:GoToState("flyback")
		end
	end
end

local function OnWake(inst)
	if inst.active then
		inst.raining = inst:DoPeriodicTask(0.5,SpawnGuanoRain)
		inst.batting = inst:DoPeriodicTask(math.random(60,120),MoreBATS)
		inst.woke = true --This woke at some point, don't add prefabs at the end
	end	
end

local function OnSleep(inst)
	if inst.active and inst.raining then
		inst.raining:Cancel()
		inst.raining = nil
	end	
end

local function Activate(inst)
	inst.active = true
	if inst.entity:IsAwake() then
		OnWake(inst)	
	end
end

local function Deactivate(inst)
	inst.active = false
	if not inst.woke then
		GenerateSomeGuanoStuffsOffScreen(inst)
	end
	if inst.raining then
		inst.raining:Cancel()
		inst.raining = nil
	end
	if inst.batting then
		inst.batting:Cancel()
		inst.batting = nil
	end
	inst.woke = nil
end

local function OnSave(inst)
	local data = {}
	data.active = inst.active
	data.woke = inst.woke
end

local function OnLoad(inst,data)
	if data then
		if data.active then
			inst.active = data.active
		end
		if data.woke then
			inst.woke = data.woke
		end
		if inst.woke and inst.active then
			Activate(inst)
		end
	end
end

local function fnnode()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:ListenForEvent("entitywake",OnWake)
	inst:ListenForEvent("entitysleep",OnSleep)
	
	inst.Activate = Activate
	inst.Deactivate = Deactivate
	
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst:DoTaskInTime(0,function(inst)
		local guano_rain_component = TheWorld.components.um_guano_rain
		if guano_rain_component then
			table.insert(guano_rain_component.guano_nodes,inst)
		else
			inst:Remove()
		end
	end)
    return inst
end

return Prefab("um_guano_rain_particle", fnparticle),
Prefab("um_guano_rain_node", fnnode) --AXE This is an invisible node that controls where guano is raining - worldgen distributes it so that there's 1 per guano room.

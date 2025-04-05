local assets =
{
    Asset("ANIM", "anim/um_thicket.zip"),
}

local function onregenfn(inst)
	inst:Show()
	inst.hidden = nil
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
	inst:AddTag("briar_plants")
end

local function makeemptyfn(inst)

        inst.AnimState:PlayAnimation("picked")
		inst.AnimState:PushAnimation("empty")
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING and
        (   inst.components.witherable ~= nil and
            inst.components.witherable:IsWithered()
        ) then
        inst.AnimState:PlayAnimation(wasempty and "empty" or "empty")
        inst.AnimState:PushAnimation("empty", false)
    else
        inst.AnimState:PlayAnimation("empty")
    end
end

local function ToggleBusyAnimation(inst)
	inst.busyanimation = false
	inst:RemoveEventCallback("animover",ToggleBusyAnimation)
end


local function GetCropSeeds()
	local weighted_briar_loot = {} 
	
	local all_seeds = {"carrot","corn","dragonfruit","durian","eggplant","pomegranate","pumpkin","asparagus","tomato","potato","onion","pepper","garlic","watermelon"}
	
	for i,v in ipairs(all_seeds) do
		weighted_briar_loot[v] = 0.1
	end
	
	
	if TheWorld.state.isspring then
		local spring_seeds = {"carrot","corn","dragonfruit","durian","eggplant","pomegranate","pumpkin","asparagus","tomato","potato","onion","garlic","watermelon"}
		for i,v in ipairs(spring_seeds) do
			weighted_briar_loot[v] = 0.4
		end
	elseif TheWorld.state.iswinter then
		--nothing
	elseif TheWorld.state.issummer then
		local summer_seeds = {"corn","dragonfruit","pomegranate","tomato","onion","pepper","garlic","watermelon","carrot"}
		for i,v in ipairs(summer_seeds) do
			weighted_briar_loot[v] = 0.4
		end	
	else
		local fall_seeds = {"carrot","corn","eggplant","pumpkin","asparagus","tomato","potato","onion","pepper","garlic"}
		for i,v in ipairs(fall_seeds) do
			weighted_briar_loot[v] = 0.4
		end	
	end
	return weighted_random_choice(weighted_briar_loot).."_seeds"
end

local function GenerateLoot(inst, picker)
	local weighted_briar_loot = {}
	weighted_briar_loot["seeds"] = 0.2
	weighted_briar_loot["crop_seed"] = 0.4
	weighted_briar_loot["cutgrass"] = 0.2
	weighted_briar_loot["twigs"] = 0.4
	weighted_briar_loot["aphid"] = 0.01
	weighted_briar_loot["spider"] = 0.01
	weighted_briar_loot["mound"] = 0.01
	
	local loot = weighted_random_choice(weighted_briar_loot)
	if loot == "crop_seed" then
		loot = GetCropSeeds()
	end
	if inst:IsValid() then
		if loot == "mound" then
			local mound = SpawnPrefab("mound")
			mound.Transform:SetPosition(inst.Transform:GetWorldPosition())
			mound.persists = false
			mound:DoTaskInTime(60*8,function(mound) mound:Remove() end) -- disappear after a day
		else
			if picker.components.inventory ~= nil and loot ~= "spider" and loot ~= "aphid" then
				picker.components.inventory:GiveItem(SpawnPrefab(loot), nil, inst:GetPosition())
			else
				Launch(inst.components.lootdropper:SpawnLootPrefab(loot), inst, 1.5)
			end
		end
	end
end
local function onpickedfn(inst, picker)
	if inst.busyanimation == true then
		ToggleBusyAnimation(inst)
	end
	if inst.BrushingTest then
		inst.BrushingTest:Cancel()
		inst.BrushingTest = nil
	end
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("pick")
	
	if math.random() < 0.2 then
		if inst.hidden then
			Launch(inst.components.lootdropper:SpawnLootPrefab("ash"), inst, 1.5)
		else
			GenerateLoot(inst,picker)
		end
	end
    inst.AnimState:PushAnimation("empty", false)
	inst:RemoveTag("briar_plants")
	
end

local function OutOfTheWoodsYet(target)
	if not FindEntity(target,1.75,nil,{"briar_plants"}) then
		target.components.locomotor:RemoveExternalSpeedMultiplier(target, "thicket")
		target.thicketcheck:Cancel()
		target.thicketcheck = nil
	end
end



local function CheckToSeeIfTargetsMoving(inst)
	for i,v in ipairs(inst.playertracking) do
		if inst:GetDistanceSqToInst(v) <= 1.5^2 then	
			if v.sg:HasStateTag("moving") and inst.busyanimation == false then
				inst.AnimState:PlayAnimation("bounce",false)
				inst.busyanimation = true
				inst:ListenForEvent("animover",ToggleBusyAnimation)
			end
		else
			table.remove(inst.playertracking,i)
		end
	end
	if #inst.playertracking == 0 then
		inst.BrushingTest:Cancel()
		inst.BrushingTest = nil
		inst.AnimState:PlayAnimation("unpress")
		inst.AnimState:PushAnimation("idle")
	end
end


local function onnear(inst, target)
	if inst.components.pickable and inst.components.pickable:CanBePicked() then
		if math.random() > 0.95 then
			SpawnPrefab("aphid").Transform:SetPosition(inst.Transform:GetWorldPosition())
		end


		target.components.locomotor:SetExternalSpeedMultiplier(target, "thicket", 0.3)
		if not target.thicketcheck then
			target.thicketcheck = target:DoPeriodicTask(0.1,OutOfTheWoodsYet)
		end
		table.insert(inst.playertracking,target)
		
		if #inst.playertracking > 0 and not inst.BrushingTest then
			inst.BrushingTest = inst:DoPeriodicTask(0.3,CheckToSeeIfTargetsMoving)
			if #inst.playertracking == 1 then
				inst.AnimState:PlayAnimation("depress",false)
				inst.busyanimation = true
				inst:ListenForEvent("animover",ToggleBusyAnimation)
			end
		end
	end
end



local function grass(name, stage)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		
        inst.AnimState:SetBank("um_thicket")
        inst.AnimState:SetBuild("um_thicket")
        inst.AnimState:PlayAnimation("idle", true)

        inst:AddTag("plant")
		inst:AddTag("briar_plants")
        inst:AddTag("lunarplant_target")
		inst:AddTag("walrus_trap_spot")

		-- local multcolour = 0.5
		-- if 0 <= multcolour and multcolour < 1 then
			-- local colour = multcolour + math.random() * (1.0 - multcolour)
			-- inst.AnimState:SetMultColour(colour, colour, colour, 1)
		-- end
		

        inst.entity:SetPristine()
		inst.AnimState:SetTime(math.random() * 2)
        if not TheWorld.ismastersim then
            return inst
        end
        


        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

        inst.components.pickable:SetUp(nil, TUNING.GRASS_REGROW_TIME,2)
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        inst.components.pickable.makebarrenfn = makebarrenfn
        inst.components.pickable.max_cycles = 2 -- Not transplantable, shouldn't matter.
        inst.components.pickable.cycles_left = 2 -- Not transplantable, shouldn't matter.
		
		inst:AddComponent("lootdropper")

        inst:AddComponent("inspectable")
		
        ---------------------
		inst:AddComponent("playerprox")
		inst.components.playerprox:SetDist(1.75, 3) --set specific values
		inst.components.playerprox:SetOnPlayerNear(onnear)
		inst.components.playerprox:SetPlayerAliveMode(inst.components.playerprox.AliveModes.AliveOnly)
        MakeMediumBurnable(inst)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)
		
		
		inst.components.burnable:SetBurnTime(0.75)
		inst.components.burnable:SetOnBurntFn(function(inst)
			inst.hidden = true
			inst.components.pickable:Pick(TheWorld)
			inst.hidden = true
			inst:Hide()
		end)
		inst.playertracking = {}
		
		inst.OnSave = function(inst,data)
			if inst.hidden then
				data = {}
				data.hidden = true
			end
		end
		inst.OnLoad = function(inst,data)
			if data and data.hidden then
				inst.hidden = true
				inst:Hide()
			end
		end
		
        return inst
    end

	
    return Prefab(name, fn, assets)
end

local function fnthicket()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	if not TheWorld.ismastersim then
		return inst
	end
	
	local function LargeFernCheck(x,y,z)
		local plants = #TheSim:FindEntities(x,y,z,2.25,{"plant"})
		local sculpture = #TheSim:FindEntities(x,y,z,7,{"heavy"})-- The spacing for the sculpture is larger so it doesn't cover them up 
		local sinkhole_bockers = #TheSim:FindEntities(x,y,z,7,{"antlion_sinkhole_blocker"})
		if plants > 0 or sculpture > 0 or sinkhole_bockers > 0 then
			return true
		end
	
	end
	inst:DoTaskInTime(0,function(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		for i = -15, 15, 0.5 do
			for j = -15, 15, 0.5 do
				local x1 = x + i + math.random(-1,1)/math.random(2,4)
				local z1 = z + j + math.random(-1,1)/math.random(2,4)
				if TheWorld.Map:GetTileAtPoint(x1, y, z1) == WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK and not LargeFernCheck(x1,y,z1) then
					SpawnPrefab("hooded_fern").Transform:SetPosition(x1,y,z1)
				end
			end
		end
		inst:Remove()
	end)
	
	return inst
end


return grass("hooded_fern", 0),
    grass("depleted_hooded_fern", 1),
	Prefab("thicket_builder", fnthicket)
	

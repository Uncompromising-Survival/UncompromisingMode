local assets = {
	Asset("ANIM", "anim/um_poofshroom.zip"),
}


local function DoDamageEffect(inst,target)
	local mult = 1
	local plague

	-- air filtration
	if target.components.inventory then
		if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "plaguemask" then
				plague = true
			end
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "um_hat_nettlemask" then
				mult = mult * 0.5
			end
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "gasmask" then
				mult = mult * 0.5
			end
		end
		if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "minifan" then
				mult = mult * 0.5
			end
		end
	end
					
	if not plague then
        if target.components.combat and not target.components.health:IsDead() then
            --target.components.combat:GetAttacked(inst,inst.color == "g" and 20 or inst.color == "r" and 20 or inst.color == "b" and 20 or 20)	
			target.components.combat:GetAttacked(inst,30)
		end
		target:PushEvent("knockback", { knocker = inst, radius = 1.5, strengthmult = 1.5, forcelanded = true })
        if target.components.sanity and inst.color == "g" then
            target.components.sanity:DoDelta(-5*mult)
        end
        if target.components.moisture and inst.color == "b" then
            target.components.moisture:DoDelta(10*mult)
        end
        if target.components.hunger and inst.color == "r" then
            target.components.hunger:DoDelta(-5*mult)
        end
	end
end

local should_hit = { "_health","_combat"}
local shouldnt_hit = {"ghost","brightmare_gestalt","nightmarecreature"}

local function OnExplode(inst, target)
	inst.OnExplode = nil
	inst.persists = false
	local x,y,z = inst.Transform:GetWorldPosition()
    inst.SoundEmitter:PlaySound("dontstarve/common/together/infection_burst")
	
    local poof = SpawnPrefab("air_conditioner_smoke")
	if inst.color == "r" then
		poof.AnimState:SetMultColour(1,0.2,0.2,1)
	elseif inst.color == "b" then
		poof.AnimState:SetMultColour(0.2,0.2,1,1)
	else
		poof.AnimState:SetMultColour(0.2,1,0.2,1)
	end  
    poof.Transform:SetPosition(x,y,z)
    poof.Transform:SetScale(0.75,0.75,0.75)

	inst.AnimState:PlayAnimation(inst.color..inst.variant.."_hide",false)

	inst:ListenForEvent("animover",function(inst) inst:Remove() end)

    local ents = TheSim:FindEntities(x, y, z, TUNING.TRAP_TEETH_RADIUS,{"_health"})
    for i, v in ipairs(ents) do
        if v:HasAllTags(should_hit) and not v:HasAnyTag(shouldnt_hit) then
			DoDamageEffect(inst,v)
        end
	end
	inst:DoTaskInTime(0.1,function(inst) --AXE trigger the spoil after a delay, incase something was dropped from an enemy
		local ents = TheSim:FindEntities(x, y, z, 2*TUNING.TRAP_TEETH_RADIUS)
		for i, v in ipairs(ents) do
			if v.components.perishable then
				if v.components.inventoryitem and v.components.inventoryitem:IsHeld() then
					v.components.perishable:SetPercent(v.components.perishable:GetPercent()-0.33)
				else
					v.components.perishable:SetPercent(0)
				end
			end
		end
	end)

end

local function OnSave(inst)
	local data = {}
	data.color = inst.color
	data.variant = inst.variant
	data.flipped = inst.flipped
	return data
end

local function OnLoad(inst,data)
	if data then
		inst.color = data.color
		inst.variant = data.variant
		inst.flipped = data.flipped
	end
end

local function Leave(inst)
	if inst.entity:IsAwake() then
		inst.AnimState:PlayAnimation(inst.color..inst.variant.."_hide",false)
		inst:ListenForEvent("animover",function(inst)
			inst:Remove()
		end)
	else
		inst:Remove()
	end
end

local function TryLeave(inst,isseason)
	inst:DoTaskInTime(0.1,function(inst)
		if inst.color == "r" and TheWorld.state.issummer then
			Leave(inst)
		elseif inst.color == "g" and TheWorld.state.isspring then
			Leave(inst)
		elseif inst.color == "b" and TheWorld.state.iswinter then
			Leave(inst)
		end
	end)
end


local function HideAnim(inst)
	inst.showing = false
	inst:Hide()
	inst:RemoveEventCallback("animover",HideAnim)
end


local function LookForEnts(inst)
	if not inst.showing and FindEntity(inst,8,nil,{"_health"}) and not FindEntity(inst,2,nil,{"_health"}) then
		inst.showing = true
		inst:Show()
		inst.AnimState:PlayAnimation(inst.color..inst.variant.."_show",false)
		inst.AnimState:PushAnimation(inst.color..inst.variant.."_loop",false)
	elseif not inst.showing then
		inst:Hide()
		inst.showing = false
	elseif not FindEntity(inst,12,nil,{"_health"}) then
		inst.AnimState:PlayAnimation(inst.color..inst.variant.."_hide",false)
		inst:ListenForEvent("animover",HideAnim)
	end
end

local function InPoofshroomArea(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, y, z)
	local self = {}
	if node_index ~= self.current_area then
		self.current_area = node_index or 0
		self.current_area_data = node and {
			id = TheWorld.topology.ids[node_index],
			type = node.type,
			center = node.cent,
			poly = node.poly,
			tags = node.tags,
		}
		or nil
	end

	return self.current_area_data and self.current_area_data.tags and table.contains(self.current_area_data.tags, "um_poofshrooms")
end

local colors = {"r","g","b"}
local colorsfull = {"red","green","blue"}

local function Init(inst)
	--inst.MiniMapEntity:SetEnabled(false)
	if not inst.color then
		local color = math.random(1,#colors)
		inst.color = colors[color]
		inst.colorfull = colorsfull[color]
	end
	if not inst.variant then
		if inst.color == "r" then
			inst.variant = math.random(1,11)
		elseif inst.color == "g" then
			inst.variant = math.random(1,10)
		elseif inst.color == "b" then
			inst.variant = math.random(1,9)
		end
	end
	if not inst.flipped then
		inst.flipped = math.random() > 0.5 and true or false
	end
	if inst.flipped then
		inst.AnimState:SetScale(-1,1)
	end
	inst.AnimState:SetBank("um_poofshroom_"..inst.colorfull)
	--inst.AnimState:PlayAnimation(inst.color..inst.variant.."_show",false)
	--inst.AnimState:PushAnimation(inst.color..inst.variant.."_idle",true)

	if inst.color == "r" then
		inst:WatchWorldState("issummer",TryLeave)
	elseif inst.color == "g" then
		inst:WatchWorldState("isspring",TryLeave)
	else
		inst:WatchWorldState("iswinter",TryLeave)
	end

	if inst.entity:IsAwake() then
		inst.showing = false
		inst.looking = inst:DoPeriodicTask(math.random(20,30)/10,function(inst)
			LookForEnts(inst)
		end)
	end
	
	inst:ListenForEvent("entitywake",function(inst)
		inst.showing = false
		inst.looking = inst:DoPeriodicTask(math.random(20,30)/10,function(inst)
			LookForEnts(inst)
		end)
	end)
	inst:ListenForEvent("entitysleep",function(inst)
		inst.showing = false
		if inst.looking then
			inst.looking:Cancel()
			inst.looking = nil
		end
	end)

	if not InPoofshroomArea(inst) and not inst.ignore_biome then
		inst:Remove() -- AXE Normal Poofshrooms should only be in mushroom biomes
	end
end

local function calculate_mine_test_time()
    return TUNING.STARFISH_TRAP_TIMING.BASE + (math.random() * TUNING.STARFISH_TRAP_TIMING.VARIANCE) --This will be the "regrow" period of the blueberry, will extend it to be much longer.
end

local function OnDug(inst)
	inst.OnExplode = nil
	inst.persists = false
	local rnd = math.random()
	local loot
	if rnd < 0.01 then
		loot = "um_gemology_geode"..inst.colorfull
	elseif rnd < 0.1 then
		loot = inst.colorfull.."_cap"
	elseif rnd < 0.5 then
		loot = "spoiled_food"
	elseif rnd < 0.7 then
		if inst.color == "r" then
			loot = "spore_medium"
		elseif inst.color == "g" then
			loot = "spore_small"
		else
			loot = "spore_tall"
		end
	end
	if loot then
		inst.components.lootdropper:SpawnLootPrefab(loot)
	end
	Leave(inst)
end



local function poofshroom()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	--inst.entity:AddMiniMapEntity()

    inst:AddTag("NOBLOCK")
    inst:AddTag("trap")
	inst:AddTag("groundspike")
	--inst.MiniMapEntity:SetPriority(21)
	--inst.MiniMapEntity:SetIcon("springrock1.png")
	--inst.MiniMapEntity:SetEnabled(true)
	inst.AnimState:SetBuild("um_poofshroom")
	
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end


	inst:DoTaskInTime(0.1,Init)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad



	MakeSmallBurnable(inst)
	inst.components.burnable:SetBurnTime(0.75)
    MakeSmallPropagator(inst)

    --[[inst:AddComponent("mine")
    inst.components.mine:SetRadius(0.5)
    inst.components.mine:SetAlignment("plantkin")
    inst.components.mine:SetOnExplodeFn(OnExplode)
	inst.components.mine:SetTestTimeFn(calculate_mine_test_time)
	inst.components.mine:Reset()]]
	inst.OnExplode = OnExplode

	inst:AddComponent("inspectable")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDug)
    inst.components.workable:SetWorkable(true)

	inst:AddComponent("lootdropper")

	inst:AddComponent("areaaware")

	return inst
end

local function noentcheckfn(pos)
	--local invitems = FindEntity(Vector3(pos),1.5,nil,{"inventoryitem"})
	local invitems = TheSim:FindEntities(pos.x, 0, pos.z, 2, nil,{"inventoryitem"})
    if invitems and #invitems > 0 then
		return false
	end
	local cave_exit = TheSim:FindEntities(pos.x, 0, pos.z, 32, { "migrator" })
	--local cave_exit = FindEntity(Vector3(pos),32,function(ent) return ent.prefab == "cave_exit" end)
	if cave_exit and #cave_exit > 0 then
		return false
	end
	return true
end

local function nopoofsLarge(pos)
	--local invitems = FindEntity(Vector3(pos),1.5,nil,{"inventoryitem"})
	local poofs = TheSim:FindEntities(pos.x, 0, pos.z, math.random(8,16), {"trap"})
    if poofs and #poofs > 0 then
		return false
	end
	return noentcheckfn(pos)
end

local function nopoofsSmall(pos)
	--local invitems = FindEntity(Vector3(pos),1.5,nil,{"inventoryitem"})
	local poofs = TheSim:FindEntities(pos.x, 0, pos.z, 0.5, {"trap"})
    if poofs and #poofs > 0 then
		return false
	end
	return true
end

local function Ring(inst)
	local type = inst.type
	local x,y,z = inst.Transform:GetWorldPosition()
	local pt = inst:GetPosition()
	local radius = math.random(8,16)
	for theta = 0,2*PI,PI/(radius*4) do
		local offset = FindWalkableOffset(pt, theta, radius-0.5, radius+0.5, false, true, noentcheckfn, true, true)
		if offset and TheWorld.Map:IsAboveGroundAtPoint(x+offset.x,0,z+offset.z) then
			local poofshroom = SpawnPrefab("um_poofshroom")
			poofshroom.color = colors[inst.type]
			poofshroom.colorfull = colorsfull[inst.type]
			poofshroom.Transform:SetPosition(x+offset.x,0,z+offset.z)
		end
	end
end

local function Clustered(inst)
	local type = inst.type
	local x,y,z = inst.Transform:GetWorldPosition()
	local pt = inst:GetPosition()
	for radius = 1,math.random(32,64),math.random(3,4) do
		for theta = 0,2*PI,4 * (PI * math.random(6,10)/32)/radius do
			local offset = FindWalkableOffset(pt, theta, radius-2, radius+2, false, true, nopoofsLarge, true, true)
			if offset and TheWorld.Map:IsAboveGroundAtPoint(x+offset.x,0,z+offset.z) then
				local poofshroom = SpawnPrefab("um_poofshroom")
				poofshroom.color = colors[inst.type]
				poofshroom.colorfull = colorsfull[inst.type]
				poofshroom.Transform:SetPosition(x+offset.x,0,z+offset.z)

				local newpt = {}
				newpt.x = offset.x + x
				newpt.y = 0
				newpt.z = offset.z + z
				for i = 1,math.random(4,5) do
					local newoffset = FindWalkableOffset(newpt, 2*PI*math.random(), 0.5, 2, false, true, nopoofsSmall,true,true)
					if newoffset and TheWorld.Map:IsAboveGroundAtPoint(x+newoffset.x,0,z+newoffset.z) then
						local poofshroom = SpawnPrefab("um_poofshroom")
						poofshroom.color = colors[inst.type]
						poofshroom.colorfull = colorsfull[inst.type]
						poofshroom.Transform:SetPosition(newpt.x+newoffset.x,0,newpt.z+newoffset.z)
					end
				end
			end
		end
	end
end

local function PlacePoofShrooms(inst)
	inst:DoTaskInTime(0,function(inst)
		local rnd = math.random()
		if rnd < 0.1 then
			Ring(inst)
		else
			Clustered(inst)
		end
	end)
end

local function nodecommon(type)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end

	inst.type = type

	inst.PlacePoofShrooms = PlacePoofShrooms

	-- AXE Tests functionality
	--inst:DoTaskInTime(0,PlacePoofShrooms)
	return inst
end

local function nodered()
	local inst = nodecommon(1)
	inst:DoTaskInTime(0,function(inst)
		if TheWorld.components.um_poofshroom_repopulator then
			table.insert(TheWorld.components.um_poofshroom_repopulator.list_red,inst)
		end
	end)
	return inst
end

local function nodegreen()
	local inst = nodecommon(2)
	inst:DoTaskInTime(0,function(inst)
		if TheWorld.components.um_poofshroom_repopulator then
			table.insert(TheWorld.components.um_poofshroom_repopulator.list_green,inst)
		end
	end)
	return inst
end


local function nodeblue()
	local inst = nodecommon(3)
	inst:DoTaskInTime(0,function(inst)
		if TheWorld.components.um_poofshroom_repopulator then
			table.insert(TheWorld.components.um_poofshroom_repopulator.list_blue,inst)
		end
	end)
	return inst
end

return Prefab("um_poofshroom", poofshroom,assets),
Prefab("um_poofshroom_node_red",nodered),
Prefab("um_poofshroom_node_green",nodegreen),
Prefab("um_poofshroom_node_blue",nodeblue)
require "prefabutil"

local io = require("io")

local scale = 1/5

local function onopen(inst)
	if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end

	local x,y,z = inst.Transform:GetWorldPosition()
	local itemsinside = inst.components.container:GetAllItems()
	local range = 0
	
	local range_indicator = SpawnPrefab("um_dynlayout_range")

	for i,v in ipairs(itemsinside) do
		if v.prefab == "log" then
			range = range + v.components.stackable:StackSize()
		end --since each log is 1, 4 logs = 1 tile!
		if v.prefab == "boards" then
			range = range + (v.components.stackable:StackSize()*TILE_SCALE)
		end
	end
--[[
	local indicator = TheSim:FindEntities(x,y,z,5,{"DYNLAYOUT_INDICATOR"})

	if indicator ~= nil then
		print("indicator not nil")
		print(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))

		for i, v in ipairs(indicator) do--THIS IS NOT RUNNING, WHY?!
			print("FOR LOOP")
			v.Transform:SetPosition(x,y,z)
			v.Transform:SetScale(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))--help I failed math.
		end
	else
		print("indicator nil")
		range_indicator.Transform:SetPosition(x,y,z)
		range_indicator.Transform:SetScale(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))--help I failed math.
	end]]
end

local function onclose(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end

	local x,y,z = inst.Transform:GetWorldPosition()
	local itemsinside = inst.components.container:GetAllItems()
	local range = 0
	local range_indicator = SpawnPrefab("um_dynlayout_range")

	for i,v in ipairs(itemsinside) do
		if v.prefab == "log" then
			range = range + v.components.stackable:StackSize()
		end --since each log is 1, 4 logs = 1 tile!
		if v.prefab == "boards" then
			range = range + (v.components.stackable:StackSize()*TILE_SCALE)
		end--1 BOARD = 1 TILE
	end
	--[[
	local indicator = TheSim:FindEntities(x,y,z,5,{"DYNLAYOUT_INDICATOR"})

	if indicator ~= nil then
		print("indicator not nil")
		print(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))

		for i, v in ipairs(indicator) do--THIS IS NOT RUNNING, WHY?!
			print("FOR LOOP")
			v.Transform:SetPosition(x,y,z)
			v.Transform:SetScale(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))--help I failed math.
		end
	else
		print("indicator nil")
		range_indicator.Transform:SetPosition(x,y,z)
		range_indicator.Transform:SetScale(RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5), RoundBiasedUp(math.pow(range, scale)*math.pow(range, scale), 5))--help I failed math.
	end]]
end

local function onhammered(inst, worker)
    inst:Remove()
end

local function onhit(inst, worker)
	inst:Remove()
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/chest_craft")
end

local function OnStopChanneling(inst)
	if inst.channeler ~= nil then
		--inst.channeler.sg:GoToState("idle")P
	end
	inst.channeler = nil
end

local function Capture(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local itemsinside = inst.components.container:GetAllItems()
	local range = 0
	local no_tiles = nil
	local rotation = nil

	for i,v in ipairs(itemsinside) do
		if v.prefab == "log" then
			range = range + v.components.stackable:StackSize()
		end --since each log is 0.5 - 8 logs = 1 tile!
		v:AddTag("DEVBEHOLDER")
		if v.prefab == "pitchfork" then
			no_tiles = true
		end
		if v.prefab == "boat_rotator_kit" then
			rotation = true
		end
	end
	--TheNet:Announce(range)
	local ents = TheSim:FindEntities(x,y,z,range,nil,{"DEVBEHOLDER","player","bird", "NOCLICK", "CLASSIFIED", "FX", "INLIMBO", "smalloceancreature", "DECOR"})
	local totaltable_number = tostring(math.random(1000))
	local totaltable = "returnedTable"..totaltable_number.." = { "
	--print("	{x = 2, z = 2, prefab = \"evergreen\"},")
	for i,v in ipairs(ents) do
		local px,py,pz = v.Transform:GetWorldPosition()
		local vx = px-x
		local vy = py-y
		local vz = pz-z
		totaltable = totaltable.."	{x = "..vx..", z = "..vz..", prefab = \""..v.prefab.."\""
		if v.components.pickable and v.components.pickable:IsBarren() then
			totaltable = totaltable..", barren = true"
		end
		if v.components.witherable and v.components.witherable:IsWithered() then
			totaltable = totaltable..", withered = true"
		end
		if TheWorld.Map:IsOceanAtPoint(px,py,pz) then
			totaltable = totaltable..", ocean = true"
		else
			totaltable = totaltable..", ocean = false"
		end
		if (TheWorld.Map:GetTileAtPoint(px,py,pz) and not no_tiles) or (v.prefab == "um_dynlayout_tileflag" and TheWorld.Map:GetTileAtPoint(px,py,pz)) then
			totaltable = totaltable..", tile = "..tostring(TheWorld.Map:GetTileAtPoint(px,py,pz))	--flags always get tiles, regardless of tile setting.
		end
		if v.components.health ~= nil then
			totaltable = totaltable..", health = "..tostring(v.components.health:GetPercent())
		end
		if v:HasTag("burnt") then
			totaltable = totaltable..", burnt = true"
		end
		if v.components.container ~= nil and not v.components.container:IsEmpty() then
			--totaltable = totaltable..", contents = "..tostring(v.components.container:GetAllItems())
			--this results in a table.
			--not sure how I'd do this. I know scenarios can insert loot into chests, so that might work instead. But does limit what loot we have inside.
		end
		if v.components.finiteuses ~= nil then
			totaltable = totaltable..", uses = "..tostring(v.components.finiteuses:GetUses())
		end
		if v.components.fueled ~= nil then
			totaltable = totaltable..", fuel = "..tostring(v.components.fueled:GetPercent())
		end
		if v.components.scenariorunner ~= nil and v.components.scenariorunner.scriptname ~= nil then
			totaltable = totaltable..", scenario = "..tostring(v.components.scenariorunner.scriptname)
		end
		if rotation then
			totaltable = totaltable..", rotation = "..tostring(v.Transform:GetRotation())
		end
		totaltable = totaltable.."},"
	end
	totaltable = totaltable.."},\n"
	--print("captured prefabs:", totaltable)

	local file_name = TUNING.DSTU.MODROOT.."scripts/umss_tables.lua"

	print(file_name)
	print(totaltable_number)

	local file = io.open(file_name, "r+")
	if file then
		local file_string = file:read("*a")
		file_string = string.gsub(file_string, "} return UMSS_TABLES", "")
		totaltable = file_string.."\n    "..totaltable.."} return UMSS_TABLES"
		file:close()
		file = io.open(file_name, "w")
		local data = file:write(totaltable)
		file:close()
		TheNet:Announce("Successfully captured! Saved as returnedTable"..totaltable_number.." in "..file_name.."\nWe suggest renaming it!")--TODO: AUTO ADD UMSS PREFAB STUFF TOO!
		inst:Remove()
		return data
	else
		TheNet:Announce("Failed to write: file invalid!")
	end
	--now supports ludicrously sized setpieces!
	--had to write the result on a new file, print can only fit so much.
	--now self writing!!!
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("structure")
	inst:AddTag("chest")
	inst:AddTag("DEVBEHOLDER")
		
    inst.AnimState:SetBank("chest")
    inst.AnimState:SetBuild("treasure_chest")
    inst.AnimState:PlayAnimation("closed")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("uncompromising_devcapture")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(Capture, OnStopChanneling)
    inst.components.channelable.use_channel_longaction_noloop = true
    --inst.components.channelable.skip_state_stopchanneling = true
    inst.components.channelable.skip_state_channeling = true
	
	inst:DoTaskInTime(0,function(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local tile_x, tile_y, tile_z = TheWorld.Map:GetTileCenterPoint(x, 0, z)
		inst.Transform:SetPosition(tile_x,tile_y,tile_z)
	end)
	
    return inst
end

local function OnDropped(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local tile_x, tile_y, tile_z = TheWorld.Map:GetTileCenterPoint(x, 0, z)
	if tile_x ~= nil and  tile_y ~= nil and  tile_z ~= nil  then
		inst.Transform:SetPosition(tile_x,tile_y,tile_z)
	end
end

local function TileFlag(inst)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()


    inst.AnimState:SetBank("gridplacer")
    inst.AnimState:SetBuild("gridplacer")
    inst.AnimState:PlayAnimation("anim")
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

	inst.AnimState:SetMultColour(math.random(5, 10)/10,math.random(5, 10)/10,0,1)

	inst:AddTag("DYNLAYOUT_FLAG")
	
	--MakeInventoryPhysics(inst)

    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = 60

	inst:DoTaskInTime(0, OnDropped)
    inst.OnEntityWake = OnDropped

	return inst
end


local function Helper(inst)
    inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    --inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    --inst:AddTag("placer")
	inst:AddTag("DYNLAYOUT_INDICATOR")

    inst.Transform:SetScale(1, 1, 1)--at 1, it has a diameter of 1.5 tiles.

    inst.AnimState:SetBank("firefighter_placement")
    inst.AnimState:SetBuild("firefighter_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetAddColour(0, .2, .5, 0)

    --inst.entity:SetParent(inst.entity)

    return inst
end

--[[
local function placer_postinit_fn(inst)
	inst.entity
end]]

return Prefab("um_dynlayout_devcapture", fn), --Version 1.0
	Prefab("um_dynlayout_tileflag",TileFlag),
	Prefab("um_dynlayout_range", Helper)



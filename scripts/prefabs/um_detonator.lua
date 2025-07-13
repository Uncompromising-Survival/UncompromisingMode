require("components/deployhelper") -- TriggerDeployHelpers lives here

local assets =
{
	Asset("ANIM", "anim/um_detonator.zip"),
}

local prefabs =
{

}

local function ShouldRepeatCast(inst, doer)
	return not inst:HasTag("usesdepleted")
end



local function PingCatapult(inst, doer, pos, catapult)
	local ping = SpawnPrefab("reticuleaoewinonaengineeringping")
	ping.Transform:SetPosition(catapult.Transform:GetWorldPosition())
	ping.Transform:SetRotation(catapult.Transform:GetRotation())

	--placer colours:
	--  -base colour 0x6e6045 via multcolour
	--  -validcolour (0.25, 0.75, 0.25) via addcolour
	--
	--normally, reticule:PingReticuleAt controls the colours
	--to manually match it:
	--  use multcolour to match the base+validclour
	--  addcolour is fixed (0.2, 0.2, 0.2) when triggering ping
	ping.AnimState:SetMultColour(math.min(1, 0x6e/255+0.25), math.min(1, 0x60/255+0.75), math.min(1, 0x45/255+0.25), 1)
	ping.AnimState:SetAddColour(0.2, 0.2, 0.2, 0)

	return true
end



--------------------------------------------------------------------------


--------------------------------------------------------------------------

local standard_explosives = {"gunpowder","slurtleslime","snapalm"}

local function IsStandardExplosive(prefab)
	for i,v in ipairs(standard_explosives) do
		if prefab == v then
			return true
		end
	end
end

local explosive_enemies = {"um_bee_moon","um_pawn_nightmare","slurtle","snurtle","snaildrake_magma","snaildrake_slime"}

local function IsExplosiveEnemy(prefab)
	for i,v in ipairs(explosive_enemies) do
		if prefab == v then
			return true
		end
	end
end

local melee_mines = {"trap","trap_teeth","trap_starfish","trap_bramble","um_bear_trap","um_bear_trap_equippable_gold","um_bear_trap_equippable_tooth","um_bear_trap_old"}

local function IsMeleeMine(prefab)
	for i,v in ipairs(melee_mines) do
		if prefab == v then
			return true
		end
	end
end


local function FindNearbyTarget(pos)
	local ents = TheSim:FindEntities(pos.x,pos.y,pos.z,16,{"_health"})
	local dist = 999
	local target  
	for i,v in ipairs(ents) do -- Look for the closest
		local x,y,z = v.Transform:GetWorldPosition()
		local newdist = math.sqrt((pos.x-x)^2+(pos.z-z)^2)
		if newdist < dist then
			dist = newdist
			target = v
		end
	end
	return target
end

local function ExplodeSpellFn(inst, doer, pos)
	local ents = TheSim:FindEntities(pos.x,pos.y,pos.z,4)
	for i,v in ipairs(ents) do
		if v.prefab == "spore_moon" then -- Spores
			inst.components.finiteuses:Use(1)
			v.sg:GoToState("pre_pop")
		end
		if IsStandardExplosive(v.prefab) and v.components.explosive then -- Gunpowder, the likes
			inst.components.finiteuses:Use(1)
			v.components.explosive:OnBurnt()
		end
		if IsExplosiveEnemy(v.prefab) then -- Exploding enemies, mostly UM
			if v.prefab == "snaildrake_magma" or v.prefab == "snaildrake_slime" then -- These guys have different handling
				inst.components.finiteuses:Use(1)
				v:DoExplosion()
			elseif v.components.explosive then
				inst.components.finiteuses:Use(50)
				v.components.explosive:OnBurnt()
			elseif v.components.health and not v.components.health:IsDead() then
				inst.components.finiteuses:Use(50)
				v.components.health:Kill()
			end
		end
		if v.components.mine then
			local target = FindNearbyTarget(pos)
			inst.components.finiteuses:Use(1)
			if IsMeleeMine(v.prefab) then
				v.components.mine:Explode()
			else
				v.components.mine:Explode(target)
			end
		end
		inst.ModdedExplodeFn(inst,v) -- If there is a modded prefab, let them postinit this function and add their own handling! 
	end
end

local function ExplodeSpellUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	reticule.Transform:SetPosition(pos:Get())
end

--------------------------------------------------------------------------


--------------------------------------------------------------------------

local function ReticuleTargetAllowWaterFn()
	local player = ThePlayer
	local ground = TheWorld.Map
	local pos = Vector3()
	--Cast range is 30, leave room for error
	--15 is the aoe range
	for r = 10, 0, -.25 do
		pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
		if ground:IsPassableAtPoint(pos.x, 0, pos.z, true) and not ground:IsGroundTargetBlocked(pos) then
			return pos
		end
	end
	return pos
end

local function StartAOETargeting(inst)
	local playercontroller = ThePlayer.components.playercontroller
	if playercontroller ~= nil then
		playercontroller:StartAOETargetingUsing(inst)
	end
end

local ICON_SCALE = .6
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2


local SPELLS =
{
	{
		label = "Detonate Explosives",
		onselect = function(inst)
			inst.components.spellbook:SetSpellName("Detonate Explosives")
			inst.components.spellbook:SetSpellAction(nil)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)			
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
			inst.components.aoetargeting.reticule.updatepositionfn =ExplodeSpellUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
				inst.components.aoespell:SetSpellFn(ExplodeSpellFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		bank = "spell_icons_winona",
		build = "spell_icons_winona",
		anims =
		{
			idle = { anim = "icon_wake" },
			focus = { anim = "icon_wake_focus", loop = true },
			down = { anim = "icon_wake_pressed" },
			disabled = { anim = "icon_wake_disabled" },
		},
		clicksound = "um_detonator/winona_UI/select",
		widget_scale = ICON_SCALE,
	},
}

local SPELLBOOK_BG =
{
	bank = "spell_icons_winona",
	build = "spell_icons_winona",
	anim = "dpad",
	widget_scale = ICON_SCALE,
}

--[[local function OnOpenSpellBook(inst)
	local inventoryitem = inst.replica.inventoryitem
	if inventoryitem ~= nil then
		inventoryitem:OverrideImage("waxwelljournal_open")
	end
end

local function OnCloseSpellBook(inst)
	local inventoryitem = inst.replica.inventoryitem
	if inventoryitem ~= nil then
		inventoryitem:OverrideImage(nil)
	end
end]]

--------------------------------------------------------------------------

local function SetLedEnabled(inst, enabled)
	if enabled then
		inst.AnimState:OverrideSymbol("led_off", "winona_remote", "led_on")
		inst.AnimState:SetSymbolBloom("led_off")
		inst.AnimState:SetSymbolLightOverride("led_off", 0.5)
		inst.AnimState:SetSymbolLightOverride("winona_remote_parts", 0.14)
	else
		inst.AnimState:ClearOverrideSymbol("led_off")
		inst.AnimState:ClearSymbolBloom("led_off")
		inst.AnimState:SetSymbolLightOverride("led_off", 0)
		inst.AnimState:SetSymbolLightOverride("winona_remote_parts", 0)
	end
end

local function OnUpdateChargingFuel(inst)
	if inst.components.fueled:IsFull() then
		inst.components.fueled:StopConsuming()
	end
end

local function NotifyCircuitChanged(inst, node)
	node:PushEvent("engineeringcircuitchanged")
end

local function OnCircuitChanged(inst)
	--Notify other connected batteries
	inst.components.circuitnode:ForEachNode(NotifyCircuitChanged)
end

local function SetCharging(inst, powered, duration)
	if not powered then
		if inst._powertask then
			inst._powertask:Cancel()
			inst._powertask = nil
			inst.components.fueled:StopConsuming()
			inst.components.fueled.rate = 0
			inst.components.fueled:SetUpdateFn(nil)
			inst.components.powerload:SetLoad(0)
			SetLedEnabled(inst, false)
			OnCircuitChanged(inst)
		end
	else
		local waspowered = inst._powertask ~= nil
		local remaining = waspowered and GetTaskRemaining(inst._powertask) or 0
		if duration > remaining then
			if inst._powertask then
				inst._powertask:Cancel()
			end
			inst._powertask = inst:DoTaskInTime(duration, SetCharging, false)
			if not waspowered then
				inst.components.fueled.rate = TUNING.WINONA_REMOTE_RECHARGE_RATE * (inst._quickcharge and TUNING.SKILLS.WINONA.QUICKCHARGE_MULT or 1)
				inst.components.fueled:SetUpdateFn(OnUpdateChargingFuel)
				inst.components.fueled:StartConsuming()
				inst.components.powerload:SetLoad(TUNING.WINONA_REMOTE_POWER_LOAD_CHARGING)
				SetLedEnabled(inst, true)
				OnCircuitChanged(inst)
			end
		end
	end
end

local function OnPutInInventory(inst, owner)
	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end
	inst._landed_owner = nil
	inst._owner = owner
	inst._quickcharge = false
	inst.components.circuitnode:Disconnect()
end

local function OnDropped(inst)
	if inst._owner then
		if inst._owner.components.skilltreeupdater and
			inst._owner.components.skilltreeupdater:IsActivated("winona_gadget_recharge") and
			not (inst._owner.components.health and inst._owner.components.health:IsDead() or inst._owner:HasTag("playerghost"))
		then
			inst._quickcharge = true
		end
		inst._landed_owner = inst._owner
		inst._owner = nil
	end

	if inst.components.inventoryitem.is_landed then
		inst.components.circuitnode:ConnectTo("engineeringbattery")
		if inst._landed_owner then
			inst.components.circuitnode:ForEachNode(function(inst, node)
				node:OnUsedIndirectly(inst._landed_owner)
			end)
			inst._landed_owner = nil
		end
	else
		inst.components.circuitnode:Disconnect()
	end
end

local function OnNoLongerLanded(inst)
	inst.components.circuitnode:Disconnect()
end

local function OnLanded(inst)
	if not (inst.components.circuitnode:IsEnabled() or inst.components.inventoryitem:IsHeld()) then
		inst.components.circuitnode:ConnectTo("engineeringbattery")
		if inst._landed_owner and inst._landed_owner:IsValid() then
			inst.components.circuitnode:ForEachNode(function(inst, node)
				node:OnUsedIndirectly(inst._landed_owner)
			end)
		end
	end
	inst._landed_owner = nil
end

local function OnSave(inst, data)
	data.power = inst._powertask and math.ceil(GetTaskRemaining(inst._powertask) * 1000) or nil

	--skilltree
	data.quickcharge = inst._quickcharge or nil
end

local function OnLoad(inst, data)--, newents)
	if inst._inittask then
		inst._inittask:Cancel()
		inst._inittask = nil
	end

	--skilltree
	inst._quickcharge = data and data.quickcharge or false

	if data and data.power then
		inst:AddBatteryPower(math.max(2 * FRAMES, data.power / 1000))
	else
		SetCharging(inst, false)
	end
	--Enable connections, but leave the initial connection to batteries' OnPostLoad
	inst.components.circuitnode:ConnectTo(nil)
end

local function OnInit(inst)
	inst._inittask = nil
	inst.components.circuitnode:ConnectTo("engineeringbattery")
end

--------------------------------------------------------------------------

local function GetStatus(inst)
	return (inst._powertask and "CHARGING")
		or (inst.components.circuitnode:IsConnected() and inst.components.fueled:IsFull() and "CHARGED")
		or (inst.components.fueled:IsEmpty() and "OFF")
		or nil
end

local function AddBatteryPower(inst, power)
	if inst.components.fueled:IsFull() then
		SetCharging(inst, false)
	else
		SetCharging(inst, true, power)
	end
end

local function OnUpdateSparks(inst)
	if inst._flash > 0 then
		local k = inst._flash * inst._flash
		inst.components.colouradder:PushColour("wiresparks", .3 * k, .3 * k, 0, 0)
		inst._flash = inst._flash - .15
	else
		inst.components.colouradder:PopColour("wiresparks")
		inst._flash = nil
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateSparks)
	end
end

local function DoWireSparks(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/together/spot_light/electricity", nil, .5)
	SpawnPrefab("winona_battery_sparks").entity:AddFollower():FollowSymbol(inst.GUID, "wire", 0, 0, 0)
	if inst.components.updatelooper then
		if inst._flash == nil then
			inst.components.updatelooper:AddOnUpdateFn(OnUpdateSparks)
		end
		inst._flash = 1
		OnUpdateSparks(inst)
	end
end

local function OnConnectCircuit(inst)--, node)
	if not inst._wired then
		inst._wired = true
		inst.AnimState:ClearOverrideSymbol("wire")
		if not POPULATING then
			DoWireSparks(inst)
		end
	end
	OnCircuitChanged(inst)
end

local function OnDisconnectCircuit(inst)--, node)
	if inst.components.circuitnode:IsConnected() then
		OnCircuitChanged(inst)
	elseif inst._wired then
		inst._wired = nil
		--This will remove mouseover as well (rather than just :Hide("wire"))
		inst.AnimState:OverrideSymbol("wire", "winona_remote", "dummy")
		DoWireSparks(inst)
		SetCharging(inst, false)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("winona_remote")
	inst.AnimState:SetBuild("um_detonator")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:OverrideSymbol("wire", "winona_remote", "dummy")

	inst:AddTag("remotecontrol")
	inst:AddTag("engineering")
	inst:AddTag("engineeringbatterypowered")

	MakeInventoryFloatable(inst, "small", 0.14, { 1.1, 1.15, 1 })

	inst:AddComponent("spellbook")
	--inst.components.spellbook:SetRequiredTag("portableengineer")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetItems(SPELLS)
	inst.components.spellbook:SetBgData(SPELLBOOK_BG)
	--inst.components.spellbook:SetOnOpenFn(OnOpenSpellBook)
	--inst.components.spellbook:SetOnCloseFn(OnCloseSpellBook)
	inst.components.spellbook.opensound = "meta4/winona_UI/open"
	inst.components.spellbook.closesound = "meta4/winona_UI/close"
	--inst.components.spellbook.executesound = "meta4/winona_UI/select"	--use .clicksound for item buttons instead
	inst.components.spellbook.focussound = "meta4/winona_UI/hover"		--item UIAnimButton don't have hover sound

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAllowWater(true)
	inst.components.aoetargeting:SetRange(TUNING.WINONA_REMOTE_RANGE)
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
	inst.components.aoetargeting.reticule.validcolour = { 0x33/255, 0x66/255, 0xFF/255, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { 0.5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = TUNING.WINONA_REMOTE_RANGE

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.swap_build = "um_detonator"

	inst:AddComponent("updatelooper")
	inst:AddComponent("colouradder")

	inst:AddComponent("inspectable")
	--inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("inventoryitem")
	-- inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
	-- inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

	-- inst:AddComponent("fueled")
	-- inst.components.fueled.fueltype = FUELTYPE.MAGIC
	-- inst.components.fueled.rate = 0
	-- inst.components.fueled:InitializeFuelLevel(TUNING.WINONA_REMOTE_FUEL)

	-- inst:AddComponent("circuitnode")
	-- inst.components.circuitnode:SetRange(TUNING.WINONA_BATTERY_RANGE)
	-- inst.components.circuitnode:SetFootprint(0)
	-- inst.components.circuitnode:SetOnConnectFn(OnConnectCircuit)
	-- inst.components.circuitnode:SetOnDisconnectFn(OnDisconnectCircuit)
	-- inst.components.circuitnode.connectsacrossplatforms = false
	-- inst.components.circuitnode.rangeincludesfootprint = false

	-- inst:AddComponent("powerload")
	-- inst.components.powerload:SetLoad(0)

	-- inst:ListenForEvent("engineeringcircuitchanged", OnCircuitChanged)
	-- inst:ListenForEvent("on_no_longer_landed", OnNoLongerLanded)
	-- inst:ListenForEvent("on_landed", OnLanded)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(1000)
	inst.components.finiteuses:SetUses(1000)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	--inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
		
	inst:AddComponent("aoespell")

	--MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
	--MakeSmallPropagator(inst)

	MakeHauntableLaunch(inst)

	-- inst.AddBatteryPower = AddBatteryPower
	-- inst.OnSave = OnSave
	-- inst.OnLoad = OnLoad

	--skilltree
	-- inst._quickcharge = false

	-- inst._wired = nil
	-- inst._inittask = inst:DoTaskInTime(0, OnInit)


	inst.ModdedExplodeFn = function(inst,prefab) end -- Fellow Modders, if you want the detonator to work on something from your mod, simply postinit this prefab, call the ExplodeSpellFn, add your own handlers, and then you should be good.
	
	return inst
end

return Prefab("um_detonator", fn, assets, prefabs)

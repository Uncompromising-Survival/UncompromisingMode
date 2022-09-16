local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("SOUNDPACKAGE", "sound/wathomcustomvoice.fev"),
	Asset("SOUND", "sound/wathomcustomvoice.fsb")
}

-- Your character's stats
TUNING.WATHOM_HEALTH = 225
TUNING.WATHOM_HUNGER = 120
TUNING.WATHOM_SANITY = 120

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WATHOM
end
local prefabs = FlattenTree(start_inv, true)

local function UnAmp(inst)
	inst:RemoveTag("amped") -- Party's over.
	TheWorld:PushEvent("enabledynamicmusic", true)
	TheFocalPoint.SoundEmitter:KillSound("wathommusic")
	inst.components.combat.attackrange = 2
	inst.AmpDamageTakenModifier = 5
	if inst.adrenalinehpregen ~= nil then
		inst.adrenalinehpregen:Cancel()
		inst.adrenalinehpregen = nil
	end
end

local function Amp(inst)
	inst.components.combat.attackrange = 7 -- These values are for when Wathom's at 100 Adrenaline, so he should be Amping Up right now.
	inst.AmpDamageTakenModifier = 5
	inst:AddTag("amped")
	inst.components.talker:Say("AMPED UP!", nil, true)
	TheWorld:PushEvent("enabledynamicmusic", false)
	if not TheFocalPoint.SoundEmitter:PlayingSound("wathommusic") then
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/music/music_hoedown_moose", "wathommusic")
	end
	inst.adrenalinehpregen = inst:DoPeriodicTask(1, function(inst)
		if inst.components.health ~= nil and not inst.components.health:IsDead() then
			inst.components.health:DoDelta(1.5)
		end
	end)
end

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wathom_speed_mod", 1)
	UnAmp(inst)
	inst.components.adrenalinecounter:SetPercent(0.25)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wathom_speed_mod")
	UnAmp(inst)
	inst.components.adrenalinecounter:SetPercent(0.25)
end

-------------------------------------------


local function AmpTimer(inst)
	if inst.components.grogginess ~= nil and
		(inst.components.adrenalinecounter:GetPercent() < 0.24 and not inst:HasTag("amped")) then
		inst.components.grogginess.grog_amount = 0.5
	end
end

local function AmpTimer2(inst)
	-- Draining adrenaline when not in combat.
	if inst:HasTag("amped") then
		if inst.adrenalpause then
			inst.components.adrenalinecounter:DoDelta(-1)
		else
			inst.components.adrenalinecounter:DoDelta(-4)
		end
	elseif (inst.components.adrenalinecounter:GetPercent() > 0.25 and not inst.adrenalpause) then
		inst.components.adrenalinecounter:DoDelta(-1)
	end

	if inst.components.adrenalinecounter:GetPercent() < 0.25 and not inst:HasTag("amped") then
		inst.components.adrenalinecounter:DoDelta(0.5) -- Slowly regaining to normal levels.
	end

	local AmpLevel = inst.components.adrenalinecounter:GetPercent()
	local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	--range updates
	if AmpLevel < 0.25 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 2
		else
			inst.components.combat.attackrange = 2
		end
	elseif AmpLevel < 0.32 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 4
		else
			inst.components.combat.attackrange = 2
		end
	elseif AmpLevel < 0.45 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 5
		else
			inst.components.combat.attackrange = 2
		end
	elseif AmpLevel < 0.66 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 6
		else
			inst.components.combat.attackrange = 2
		end
	elseif AmpLevel < 1 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 7
		else
			inst.components.combat.attackrange = 2
		end
	end
end

local function AttackOther(inst, data)
	if data and data.target and inst.components.adrenalinecounter:GetPercent() > 0.24 and
		((data.target.components.combat and data.target.components.combat.defaultdamage > 0) or
			(
			data.target.prefab == "dummytarget" or data.target.prefab == "antlion" or data.target.prefab == "stalker_atrium" or
				data.target.prefab == "stalker")) then
		inst.adrenalpause = true
		if inst.adrenalresume then
			inst.adrenalresume:Cancel()
			inst.adrenalresume = nil
		end
		inst.adrenalresume = inst:DoTaskInTime(10, function(inst) inst.adrenalpause = false end)
		if not inst:HasTag("amped") then
			inst.components.adrenalinecounter:DoDelta(2)
		end
	end
end

local function OnHealthDelta(inst, data)
	inst:DoTaskInTime(FRAMES*2, function(inst)
		if data.amount < 0 and not inst:HasTag("amped") then
			inst.components.adrenalinecounter:DoDelta(data.amount * -0.5) -- This gives Wathom adrenaline when attacked!
		end
	end)
end

---------------------------------------------

local function GetPointSpecialActions(inst, pos, useitem, right)
	--we really need a adrenaline replica or something
	--for barking to not work on clients. -A
	if right and useitem == nil then
		local rider = inst.replica.rider
		if rider ~= nil and not rider:IsRiding() or rider == nil then
			return { ACTIONS.WATHOMBARK }
		end
	end
	return {}
end

local function OnSetOwner(inst)
	if inst.components.playeractionpicker ~= nil then
		inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
	end
end

local WATHOM_COLOURCUBES =
{
	day = "images/colour_cubes/ruins_dim_cc.tex",
	dusk = "images/colour_cubes/ruins_dim_cc.tex",
	night = "images/colour_cubes/ruins_dim_cc.tex",
	full_moon = "images/colour_cubes/ruins_dim_cc.tex",
}

-- When loading or spawning the character
local function onload(inst, data)
	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)
	--	inst.components.playervision:SetCustomCCTable(nil)
	--    inst.components.playervision:ForceNightVision(false) -- So Wathom doesn't get flashbanged by his nightvision.

	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end
	if TheWorld:HasTag("cave") then
		inst.components.playervision:ForceNightVision(true)
		inst.components.playervision:SetCustomCCTable(WATHOM_COLOURCUBES)
	end
	if data and data.amped then
		inst:AddTag("amped")
	end
end

local function UpdateAdrenaline(inst)
	local AmpLevel = inst.components.adrenalinecounter:GetPercent()
	local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

	if (AmpLevel > 0.5 or inst:HasTag("amped")) and not inst:HasTag("wathomrun") then --Handle VVathom Running
		inst:AddTag("wathomrun")
	elseif inst:HasTag("wathomrun") and not (AmpLevel > 0.5 or inst:HasTag("amped")) then
		inst:RemoveTag("wathomrun")
	end
	if AmpLevel == 0 and inst:HasTag("amped") then
		UnAmp(inst)
	elseif AmpLevel < 0.25 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 2
		else
			inst.components.combat.attackrange = 2
		end
		inst.AmpDamageTakenModifier = 3
	elseif AmpLevel < 0.32 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 4
		else
			inst.components.combat.attackrange = 2
		end
		inst.AmpDamageTakenModifier = 1
	elseif AmpLevel < 0.45 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 5
		else
			inst.components.combat.attackrange = 2
		end
		inst.components.health:SetAbsorptionAmount(-0.50)
		inst.AmpDamageTakenModifier = 1.5
	elseif AmpLevel < 0.66 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 6
		else
			inst.components.combat.attackrange = 2
		end
		inst.components.health:SetAbsorptionAmount(-1)
		inst.AmpDamageTakenModifier = 2
	elseif AmpLevel < 1 and not inst:HasTag("amped") then
		if item ~= nil then
			inst.components.combat.attackrange = 7
		else
			inst.components.combat.attackrange = 2
		end
		inst.AmpDamageTakenModifier = 5
	elseif AmpLevel == 1 and not inst:HasTag("amped") then
		Amp(inst)
	end
end

local function CustomCombatDamage(inst, target)
	--sometimes I hate short-circuit evals...
	return (target.components.hauntable and target.components.hauntable.panic and inst:HasTag("amped")) and (1.5 * 4) or
		(target.components.hauntable and target.components.hauntable.panic) and (1.5 * 2) or inst:HasTag("amped") and 4 or 2
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("wathom.tex")

	inst:AddTag("wathom")
	inst:AddTag("monster")
	inst:AddTag("playermonster")

	inst:AddTag("nightvision")
	inst.OnLoad = onload
	inst.OnNewSpawn = onload
	-- Wathom's Nightvision aboveground

	if TheWorld:HasTag("cave") or TheWorld.state.isnight then
		inst.components.playervision:ForceNightVision(true)
		inst.components.playervision:SetCustomCCTable(WATHOM_COLOURCUBES)
	else
		inst.components.playervision:ForceNightVision(false)
		inst.components.playervision:SetCustomCCTable(nil)
	end

	inst:WatchWorldState("isnight", function()
		inst:DoTaskInTime(TheWorld.state.isnight and 0 or 1, function(inst)
			if not TheWorld:HasTag("cave") then
				if TheWorld.state.isnight then
					inst.components.playervision:ForceNightVision(true)
					inst.components.playervision:SetCustomCCTable(WATHOM_COLOURCUBES)
				else
					inst.components.playervision:ForceNightVision(false)
					inst.components.playervision:SetCustomCCTable(nil)
				end
			end
		end)
	end)

	inst:ListenForEvent("setowner", OnSetOwner)
	inst:ListenForEvent("ondeath", function(inst) if inst:HasTag("amped") then inst:RemoveTag("amped") end end)

end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)

	inst.adrenalinecheck = 0 -- I have no idea what this does. It's left over from SCP-049.

	-- Set starting inventory
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	-- choose which sounds this character will play
	inst.soundsname = "wathomvoiceevent"
	inst.talker_path_override = "wathomcustomvoice/"

	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
	--inst.talker_path_override = "dontstarve_DLC001/characters/"

	-- Carnivore
	if inst.components.eater ~= nil then
		inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
	end

	inst.components.eater:SetCanEatRawMeat(true)

	inst.components.foodaffinity:AddPrefabAffinity("hardshelltacos", 20) -- replace with hardshell tacos when implementing in uncomp

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.WATHOM_HEALTH)
	inst.components.hunger:SetMax(TUNING.WATHOM_HUNGER)
	inst.components.sanity:SetMax(TUNING.WATHOM_SANITY)

	-- Damage multiplier (In reality, Wathom won't deal double damage. The time it takes for him to attack is about twice as long as other characters.
	--inst.components.combat.damagemultiplier = 2
	inst.components.combat.customdamagemultfn = CustomCombatDamage

	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE

	-- Idle animation
	inst.customidleanim = "spooked"

	-- grogginess stuff

	local function DefaultKnockoutTest(inst)
		local self = inst.components.grogginess
		return self.grog_amount >= self:GetResistance()
			and not (inst.components.health ~= nil and inst.components.health.takingfiredamage)
			and not (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
	end

	inst.components.grogginess.knockouttestfn = function(inst)
		if inst:HasTag("amped") then
			return false
		else
			return DefaultKnockoutTest(inst)
		end
	end

	-- Wathom's Nightvision aboveground
	if TheWorld:HasTag("cave") or TheWorld.state.isnight then
		inst.components.playervision:ForceNightVision(true)
		inst.components.playervision:SetCustomCCTable(WATHOM_COLOURCUBES)
	else
		inst.components.playervision:ForceNightVision(false)
		inst.components.playervision:SetCustomCCTable(nil)
	end

	inst:WatchWorldState("isnight", function()
		inst:DoTaskInTime(TheWorld.state.isnight and 0 or 1, function(inst)
			if not TheWorld:HasTag("cave") then
				if TheWorld.state.isnight then
					inst.components.playervision:ForceNightVision(true)
					inst.components.playervision:SetCustomCCTable(WATHOM_COLOURCUBES)
				else
					inst.components.playervision:ForceNightVision(false)
					inst.components.playervision:SetCustomCCTable(nil)
				end
			end
		end)
	end)

	-- stuff relating to Wathom's adrenaline timer. This can most likely be optimized.
	inst:DoPeriodicTask(0.5, function() AmpTimer(inst) end)
	inst:DoPeriodicTask(1, function() AmpTimer2(inst) end)

	inst:ListenForEvent("healthdelta", OnHealthDelta)
	inst:ListenForEvent("onattackother", AttackOther)
	if TheWorld.ismastersim then
		inst:ListenForEvent("adrenalinedelta", UpdateAdrenaline)
	end
	inst:ListenForEvent("ondeath", function(inst) if inst:HasTag("amped") then inst:RemoveTag("amped") end end)
	-- Wathom's immunity to night drain during the night.
	inst.components.sanity.night_drain_mult = 0

	-- Night Vision enabler
	--	inst.components.playervision:ForceNightVision(true) -- Should only force this if it's night or in caves.

	-- Doubles Wathom's attack range so he can jump at things from further away.
	-- inst.components.combat.attackrange = 4

	local _onsave = inst.OnSave

	local function onsave(inst, data)
		if inst:HasTag("amped") then
			data.amped = true
		end
		if _onsave ~= nil then
			return _onsave(inst, data)
		end
	end

	inst.OnLoad = onload
	inst.OnSave = onsave

	inst.OnNewSpawn = onload

end

return MakePlayerCharacter("wathom", prefabs, assets, common_postinit, master_postinit, prefabs)

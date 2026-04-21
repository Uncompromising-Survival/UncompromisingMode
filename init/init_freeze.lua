-- How much time will the mob have immunity.
local NORMAL_IMMUNITY = 5
local EPIC_IMMUNITY = 10

-- How much more time will the mob have immunity, per stack.
local NORMAL_BUILDUP = 1
local EPIC_BUILDUP = 2

-- How much time until the mob loses a buildup stack.
local BUILDUP_FADE = 120

local function AreYouEpic(inst)
	return inst ~= nil and inst:HasTag("epic")
end

local function AreYouPlayer(inst)
	return inst ~= nil and inst:HasTag("player")
end

-- Defines which imunnity the mob will have.
local function WhichImmunity(inst)
	return AreYouEpic(inst) and EPIC_IMMUNITY or NORMAL_IMMUNITY
end

-- Defines which buildup stack the mob will have.
local function Stacks(inst)
	return AreYouEpic(inst) and EPIC_BUILDUP or NORMAL_BUILDUP
end

-- Checks if immunity should be ignored.
local function IgnoreFreezeImmunity(inst)
	return inst ~= nil and inst.IgnoreImmunity == true
end

-- Blocks freezing if immunity is active.
local function DontFreeze(inst)
	return inst.FreezeImmune ~= nil and GetTime() < inst.FreezeImmune and not IgnoreFreezeImmunity(inst)
end

-- Defines the fading of buildup stacks overtime.
local function FinalFade(inst)
	if inst == nil or AreYouPlayer(inst) then
		return
	end

	if inst.FreezeStacks == nil or inst.FreezeStacks <= 0 then
		inst.FreezeStacks = 0
		return
	end

	if inst.ThawedOut == nil then
		return
	end

	local accounted = GetTime() - inst.ThawedOut
	if accounted < BUILDUP_FADE then
		return
	end

	local rectified = math.floor(accounted / BUILDUP_FADE)
	if rectified <= 0 then
		return
	end

	inst.FreezeStacks = math.max(0, inst.FreezeStacks - rectified)
	inst.ThawedOut = inst.ThawedOut + (rectified * BUILDUP_FADE)
end

-- Calculates current amount of immunity.
local function CurrentImmunity(inst)
	if inst == nil then
		return NORMAL_IMMUNITY
	end

	if AreYouPlayer(inst) then
		return WhichImmunity(inst)
	end

	FinalFade(inst)

	local stacks = inst.FreezeStacks or 0
	return WhichImmunity(inst) + (stacks * Stacks(inst))
end

-- Increases buildup stacks after a freeze cycle.
local function IncreaseBuildup(inst)
	if inst == nil or AreYouPlayer(inst) then
		return
	end

	FinalFade(inst)
	inst.FreezeStacks = (inst.FreezeStacks or 0) + 1
end

-- Applies immunity when unfreezing.
local function ApplyFreezeImmunity(inst)
	if inst == nil then
		return
	end

	local duration = CurrentImmunity(inst)
	inst.FreezeImmune = GetTime() + duration
	inst.ThawedOut = GetTime()
	IncreaseBuildup(inst)
end

AddComponentPostInit("freezable", function(self)
	if self.YouCool then
		return
	end
	self.YouCool = true

	local OldAddColdness = self.AddColdness
	local OldUnfreeze = self.Unfreeze
	local OldOnSave = self.OnSave
	local OldOnLoad = self.OnLoad

	self.AddColdness = function(self, ...)
		local inst = self.inst

		if inst ~= nil and DontFreeze(inst) then
			return
		end

		return OldAddColdness(self, ...)
	end

	self.Unfreeze = function(self, ...)
		local inst = self.inst
		local WasFrozen = self:IsFrozen()

		local result = OldUnfreeze(self, ...)

		if inst ~= nil and WasFrozen and not self:IsFrozen() then
			ApplyFreezeImmunity(inst)
		end

		return result
	end

	self.OnSave = function(self)
		local data = OldOnSave ~= nil and OldOnSave(self) or {}
		local inst = self.inst

		if inst ~= nil then
			if inst.FreezeStacks ~= nil and inst.FreezeStacks > 0 then
				data.FreezeStacks = inst.FreezeStacks
			end

			if inst.ThawedOut ~= nil then
				data.ThawedOut = GetTime() - inst.ThawedOut
			end

			if inst.FreezeImmune ~= nil then
				local remaining = inst.FreezeImmune - GetTime()
				if remaining > 0 then
					data.FreezeImmune = remaining
				end
			end
		end

		return data
	end

	self.OnLoad = function(self, data)
		if OldOnLoad ~= nil then
			OldOnLoad(self, data)
		end

		if data == nil then
			return
		end

		local inst = self.inst
		if inst == nil then
			return
		end

		inst.FreezeStacks = data.FreezeStacks or 0

		if data.ThawedOut ~= nil then
			inst.ThawedOut = GetTime() - data.ThawedOut
		else
			inst.ThawedOut = nil
		end

		if data.FreezeImmune ~= nil and data.FreezeImmune > 0 then
			inst.FreezeImmune = GetTime() + data.FreezeImmune
		else
			inst.FreezeImmune = nil
		end
	end
end)

-- Makes some cool weapons bypass the new immunity.
local function FreezeImmunityBypass(prefab)
	AddPrefabPostInit(prefab, function(inst)
		inst:DoTaskInTime(0, function()
			if inst.components.weapon == nil then
				return
			end

			local old_onattack = inst.components.weapon.onattack

			inst.components.weapon:SetOnAttack(function(weapon, attacker, target, ...)
				if target ~= nil then
					target.IgnoreImmunity = true
				end

				local result = nil
				if old_onattack ~= nil then
					result = old_onattack(weapon, attacker, target, ...)
				end

				if target ~= nil and target:IsValid() then
					target.IgnoreImmunity = nil
				end

				return result
			end)
		end)
	end)
end

-- List of cool weapons that bypass immunity.
local CoolStuff = {
	"icestaff",
	"icestaff2",
	"icestaff3",
}

for _, prefab in ipairs(CoolStuff) do
	FreezeImmunityBypass(prefab)
end

local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local BASE_IMMUNITY = 7
local IMMUNITY_BUILDUP = 1
local MAX_IMMUNITY = 20
local BUILDUP_FADE = 30

local function PlayerCheck(inst)
	return inst ~= nil and inst:HasTag("player")
end

local function MaxStacks()
	return math.max(0, math.floor((MAX_IMMUNITY - BASE_IMMUNITY) / IMMUNITY_BUILDUP))
end

local function DontElectrocute(inst)
	return inst ~= nil and not PlayerCheck(inst) and inst.ElectricImmune ~= nil and GetTime() < inst.ElectricImmune
end

local function FinalFade(inst)
	if not inst.ElectricStacks or inst.ElectricStacks <= 0 then
		inst.ElectricStacks = 0
		return
	end

	if not inst.ElectrocutedOut then
		return
	end

	local accounted = GetTime() - inst.ElectrocutedOut
	if accounted < BUILDUP_FADE then
		return
	end

	local rectified = math.floor(accounted / BUILDUP_FADE)
	if rectified <= 0 then
		return
	end

	inst.ElectricStacks = math.max(0, inst.ElectricStacks - rectified)
	inst.ElectrocutedOut = inst.ElectrocutedOut + (rectified * BUILDUP_FADE)
end

local function CurrentImmunity(inst)
	FinalFade(inst)
	local stacks = inst.ElectricStacks or 0
	return math.min(MAX_IMMUNITY, BASE_IMMUNITY + (stacks * IMMUNITY_BUILDUP))
end

local function IncreaseBuildup(inst)
	FinalFade(inst)
	local stacks = inst.ElectricStacks or 0
	inst.ElectricStacks = math.min(MaxStacks(), stacks + 1)
end

local function ApplyElectricImmunity(inst)
	if inst == nil or not inst:IsValid() or PlayerCheck(inst) then
		return
	end

	local duration = CurrentImmunity(inst)

	inst.ElectricImmune = GetTime() + duration
	inst.ElectrocutedOut = GetTime()

	IncreaseBuildup(inst)
end

local function ApplyDelayedElectricImmunity(inst)
	if inst == nil or not inst:IsValid() then
		return
	end

	inst:DoTaskInTime(0, function(inst)
		if inst ~= nil and inst:IsValid() then
			ApplyElectricImmunity(inst)
		end
	end)
end

local function ForcedElectrocutionCheck(event, data)
	return event == "electrocute" and (data == nil or data.stimuli == nil or data.stimuli == "electric")
end

local function BlockForcedElectrocution(inst, event, data)
	return ForcedElectrocutionCheck(event, data) and DontElectrocute(inst)
end

local _PushEvent = EntityScript.PushEvent
function EntityScript:PushEvent(event, data, ...)
	if BlockForcedElectrocution(self, event, data) then
		return
	end

	local back = _PushEvent(self, event, data, ...)

	if ForcedElectrocutionCheck(event, data) and self ~= nil and self:IsValid() then
		ApplyDelayedElectricImmunity(self)
	end

	return back
end

local _PushEventImmediate = EntityScript.PushEventImmediate
function EntityScript:PushEventImmediate(event, data, ...)
	if BlockForcedElectrocution(self, event, data) then
		return
	end

	local back = _PushEventImmediate(self, event, data, ...)

	if ForcedElectrocutionCheck(event, data) and self ~= nil and self:IsValid() then
		ApplyDelayedElectricImmunity(self)
	end

	return back
end

env.AddComponentPostInit("combat", function(self)
	local _GetAttacked = self.GetAttacked

	function self:GetAttacked(attacker, damage, weapon, stimuli, ...)
		if stimuli == "electric" and not PlayerCheck(self.inst) then
			if DontElectrocute(self.inst) then
				return _GetAttacked(self, attacker, damage, weapon, nil, ...)
			end

			local back = _GetAttacked(self, attacker, damage, weapon, stimuli, ...)

			if self.inst ~= nil and self.inst:IsValid() then
				ApplyDelayedElectricImmunity(self.inst)
			end

			return back
		end

		return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
	end

	local _OnSave = self.OnSave
	function self:OnSave(...)
		local data = _OnSave ~= nil and _OnSave(self, ...) or {}

		if self.inst.ElectricStacks and self.inst.ElectricStacks > 0 then
			data.ElectricStacks = self.inst.ElectricStacks
		end

		if self.inst.ElectrocutedOut then
			data.ElectrocutedOut = GetTime() - self.inst.ElectrocutedOut
		end

		if self.inst.ElectricImmune then
			local remaining = self.inst.ElectricImmune - GetTime()
			if remaining > 0 then
				data.ElectricImmune = remaining
			end
		end

		return data
	end

	local _OnLoad = self.OnLoad
	function self:OnLoad(data, ...)
		local back = _OnLoad ~= nil and _OnLoad(self, data, ...) or nil

		if not data then
			return back
		end

		self.inst.ElectricStacks = math.min(data.ElectricStacks or 0, MaxStacks())

		if data.ElectrocutedOut then
			self.inst.ElectrocutedOut = GetTime() - data.ElectrocutedOut
		else
			self.inst.ElectrocutedOut = nil
		end

		if data.ElectricImmune and data.ElectricImmune > 0 and not PlayerCheck(self.inst) then
			self.inst.ElectricImmune = GetTime() + math.min(data.ElectricImmune, MAX_IMMUNITY)
		else
			self.inst.ElectricImmune = nil
		end

		return back
	end
end)

-- How much time will the mob have immunity.
local NORMAL_IMMUNITY = 5
local EPIC_IMMUNITY = 10

-- How much more time will the mob have immunity, per stack.
local NORMAL_BUILDUP = 1
local EPIC_BUILDUP = 2

-- How much time until the mob loses a buildup stack.
local BUILDUP_FADE = 120

local function AreYouEpic(inst)
    return inst:HasTag("epic")
end

local function AreYouPlayer(inst)
    return inst:HasTag("player")
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
    return inst.IgnoreImmunity
end

-- Blocks freezing if immunity is active.
local function DontFreeze(inst)
    return inst.FreezeImmune and GetTime() < inst.FreezeImmune and not IgnoreFreezeImmunity(inst)
end

-- Defines the fading of buildup stacks overtime.
local function FinalFade(inst)
    if not inst.FreezeStacks or inst.FreezeStacks <= 0 then
        inst.FreezeStacks = 0
        return
    end

    if not inst.ThawedOut then return end

    local accounted = GetTime() - inst.ThawedOut
    if accounted < BUILDUP_FADE then return end

    local rectified = math.floor(accounted / BUILDUP_FADE)
    if rectified <= 0 then return end

    inst.FreezeStacks = math.max(0, inst.FreezeStacks - rectified)
    inst.ThawedOut = inst.ThawedOut + (rectified * BUILDUP_FADE)
end

-- Calculates current amount of immunity.
local function CurrentImmunity(inst)
    if AreYouPlayer(inst) then return WhichImmunity(inst) end

    FinalFade(inst)

    local stacks = inst.FreezeStacks or 0
    return WhichImmunity(inst) + (stacks * Stacks(inst))
end

-- Increases buildup stacks after a freeze cycle.
local function IncreaseBuildup(inst)
    if AreYouPlayer(inst) then return end

    FinalFade(inst)
    inst.FreezeStacks = (inst.FreezeStacks or 0) + 1
end

-- Applies immunity when unfreezing.
local function ApplyFreezeImmunity(inst)
    local duration = CurrentImmunity(inst)
    inst.FreezeImmune = GetTime() + duration
    inst.ThawedOut = GetTime()
    IncreaseBuildup(inst)
end

AddComponentPostInit("freezable", function(self)
    local _AddColdness = self.AddColdness
    function self:AddColdness(...)
        if DontFreeze(self.inst) then return end
        return _AddColdness(self, ...)
    end

    local _Unfreeze = self.Unfreeze
    function self:Unfreeze(...)
        local WasFrozen = self:IsFrozen()
        local ret = _Unfreeze(self, ...)
        if WasFrozen and not self:IsFrozen() then ApplyFreezeImmunity(self.inst) end
        return ret
    end

    local _OnSave = self.OnSave
    function self:OnSave(...)
        local data = _OnSave(self, ...) or {}

        if self.inst.FreezeStacks and self.inst.FreezeStacks > 0 then
            data.FreezeStacks = self.inst.FreezeStacks
        end

        if self.inst.ThawedOut then
            data.ThawedOut = GetTime() - self.inst.ThawedOut
        end

        if self.inst.FreezeImmune then
            local remaining = self.inst.FreezeImmune - GetTime()
            if remaining > 0 then
                data.FreezeImmune = remaining
            end
        end

        return data
    end

    local _OnLoad = self.OnLoad
    function self:OnLoad(data, ...)
        local ret = _OnLoad(self, data, ...)

        if not data then return end

        self.inst.FreezeStacks = data.FreezeStacks or 0

        if data.ThawedOut then
            self.inst.ThawedOut = GetTime() - data.ThawedOut
        else
            self.inst.ThawedOut = nil
        end

        if data.FreezeImmune and data.FreezeImmune > 0 then
            self.inst.FreezeImmune = GetTime() + data.FreezeImmune
        else
            self.inst.FreezeImmune = nil
        end

        return ret
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
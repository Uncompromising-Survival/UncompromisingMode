local env = env
GLOBAL.setfenv(1, GLOBAL)

--local GeneratorGroundCharging = require("generatorcharging")


local function CalcBatteryChargeMult(inst, battery)
    local pct = inst.components.fueled:GetPercent()
    return math.clamp(1 - pct, 0, 1)
end

local function OnBatteryUsed(inst, battery, mult)
    if mult <= 0 or inst.components.fueled:IsFull() then
        return false, "CHARGE_FULL"
    end

    local newpercent = math.clamp(inst.components.fueled:GetPercent() + mult, 0, 1)
    inst.components.fueled:SetPercent(newpercent)
    SpawnElectricHitSparks(inst, battery, true)

    return true
end


env.AddPrefabPostInit("lantern", function(inst)
    if not TheWorld.ismastersim then
        return
    end


    local function OnUpgrade(inst)
        if inst then
            inst.upgraded = true
            inst:SetPrefabNameOverride("LANTERN_ELECTRICAL")
            inst.components.upgradeable.upgradetype = nil
            inst.components.fueled.fueltype = FUELTYPE.BATTERYPOWER
            inst.components.fueled.maxfuel = TUNING.LANTERN_LIGHTTIME * 2
            inst.components.fueled:DoDelta(0) --do a 0delta to update the %, maybe?
            inst.components.named:SetName(STRINGS.NAMES.LANTERN_ELECTRICAL)

            inst:AddComponent("batteryuser")
            inst.components.batteryuser:SetChargeMultFn(CalcBatteryChargeMult)
            inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
            inst.components.batteryuser:SetAllowPartialCharge(true)
        end
    end

    local _OnSave = inst.OnSave
    local function OnSave(inst, data, ...)
        if inst.upgraded then
            data.upgraded = inst.upgraded
        end
        if _OnSave then return _OnSave(inst, data, ...) end
    end

    local _OnLoad = inst.OnLoad
    local function OnLoad(inst, data, ...)
        if data and data.upgraded then
            inst.upgraded = true
            OnUpgrade(inst)
        end
        if _OnLoad then return _OnLoad(inst, data, ...) end
    end

    if inst.components.hauntable then
        local _OnHaunt = inst.components.hauntable.onhaunt
        local function OnHaunt(inst, haunter, ...)
            local turnoff = inst.components.machine.turnofffn
            if inst._light and inst._light:IsValid() then
                turnoff(inst)
                return true
            else
                return _OnHaunt(inst, haunter, ...)
            end
        end
        inst.components.hauntable:SetOnHauntFn(OnHaunt)
    end

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.ELECTRICAL
    inst.components.upgradeable.onupgradefn = OnUpgrade

    inst:AddComponent("named")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)

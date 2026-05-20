local env = env
GLOBAL.setfenv(1, GLOBAL)

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

env.AddPrefabPostInit("minerhat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local function OnUpgrade(inst)
        if inst ~= nil then
            inst.upgraded = true
            inst:SetPrefabNameOverride("MINERHAT_ELECTRICAL") --this is mainly for quotes, though I could use getstatus instead now...
            inst.components.upgradeable.upgradetype = nil
            inst.components.fueled.fueltype = FUELTYPE.BATTERYPOWER
            inst.components.fueled.rate_modifiers:SetModifier(inst, 0.75, "electricalefficiency")

            inst.components.named:SetName(STRINGS.NAMES.MINERHAT_ELECTRICAL) --this seems to actually set the name, since it has a replica for clients

            inst:AddComponent("batteryuser")
            inst.components.batteryuser:SetChargeMultFn(CalcBatteryChargeMult)
            inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
            inst.components.batteryuser:SetAllowPartialCharge(true)
        end
    end

    local _OnSave = inst.OnSave

    local function OnSave(inst, data)
        if inst.upgraded then
            data.upgraded = inst.upgraded
        end


        if _OnSave ~= nil then
            return _OnSave(inst, data)
        end
    end

    local _OnLoad = inst.OnLoad

    local function OnLoad(inst, data)
        if data ~= nil and data.upgraded then
            inst.upgraded = true
            OnUpgrade(inst)
        end

        if _OnLoad ~= nil then
            return _OnLoad(inst, data)
        end
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.ELECTRICAL
    inst.components.upgradeable.onupgradefn = OnUpgrade

    inst:AddComponent("named")
end)

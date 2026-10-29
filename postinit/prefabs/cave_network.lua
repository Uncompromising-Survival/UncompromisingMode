local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function OnSeasonTick(inst, data)
    local season = data.season
    if season == "summer" and TUNING.DSTU.HOTCAVES then
        inst.components.worldtemperature:SetTemperatureMod(TUNING.DSTU.SUMMER_CAVES_TEMP_MULT, TUNING.CAVES_TEMP_LOCUS)
    elseif season == "winter" then
        inst.components.worldtemperature:SetTemperatureMod(TUNING.DSTU.WINTER_CAVES_TEMP_MULT, TUNING.CAVES_TEMP_LOCUS)
    else
        inst.components.worldtemperature:SetTemperatureMod(TUNING.CAVES_TEMP_MULT, TUNING.CAVES_TEMP_LOCUS)
    end
end

env.AddPrefabPostInit("cave_network", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("seasontick", OnSeasonTick)
    OnSeasonTick(inst, {season = TheWorld.state.season})
end)
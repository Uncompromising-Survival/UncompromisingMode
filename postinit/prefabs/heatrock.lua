local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

--[[
    Normally, Thermal Stones have 120 insulation. Now they have 60, but inherit half the player's insulation.
    This means they're just as powerful as before if you wear a Winter Hat or a Tam O'Shanter, but benefit
    further if you equip high insulation clothing such as a Beefalo Hat, or use both head and body slots
    for insulation. --KoreanWaffles
]]

if TUNING.DSTU.INSUL_THERMALSTONE then
    local base_insulation = TUNING.INSULATION_TINY --60 insulation

    local function CalculateInsulation(inst)
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.components.temperature then
            local winter_insulation, summer_insulation = owner.components.temperature:GetInsulation()
            inst.components.temperature.inherentinsulation = base_insulation + winter_insulation / 2
            inst.components.temperature.inherentsummerinsulation = base_insulation + summer_insulation / 2
        else
            inst.components.temperature.inherentinsulation = base_insulation
            inst.components.temperature.inherentsummerinsulation = base_insulation
        end
    end

    env.AddPrefabPostInit("heatrock", function(inst)
        if not TheWorld.ismastersim then return end

        if inst.components.temperature ~= nil then
            inst.components.temperature.inherentinsulation = base_insulation
            inst.components.temperature.inherentsummerinsulation = base_insulation
        end

        inst:ListenForEvent("temperaturedelta", CalculateInsulation)
    end)
end

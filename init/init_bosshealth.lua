local bosses = {
    "MINOTAUR",
    "STALKER_ATRIUM",
    "BEARGER",
    "BEEQUEEN",
    "ALTERGUARDIAN_PHASE1",
    "ALTERGUARDIAN_PHASE2",
    "ALTERGUARDIAN_PHASE3",
    "DEERCLOPS",
    "DRAGONFLY",
    "EYEOFTERROR",
    "TWINOFTERROR1",
    "TWINOFTERROR2",
    "SHARKBOI",
    "LORDFRUITFLY",
    "MALBATROSS",
    "MOOSE",
    "DAYWALKER",    
    "SPIDERQUEEN",
    "TOADSTOOL",
    "TOADSTOOL_DARK",
    "KLAUS",
    "ANTLION",
    "CRABKING",
    "LEIF",
    "MUTATEDBEARGER",
    "MUTATEDDEERCLOPS",
    "MUTATEDWARG",
    "WORM_BOSS",
    "WAGBOSS_ROBOT",
    "ALTERGUARDIAN_PHASE1_LUNARRIFT",
    "ALTERGUARDIAN_PHASE4_LUNARRIFT",
    "STALKER",    
}

for _, v in pairs(bosses) do

    if v == "ALTERGUARDIAN_PHASE1" then
        TUNING.ALTERGUARDIAN_PHASE1_HEALTH = TUNING.ALTERGUARDIAN_PHASE1_HEALTH * GetModConfigData("alterguardian_health_")
    elseif v == "ALTERGUARDIAN_PHASE2" then    
        TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH = TUNING.ALTERGUARDIAN_PHASE2_MAXHEALTH * GetModConfigData("alterguardian_health_")
        TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH = TUNING.ALTERGUARDIAN_PHASE2_STARTHEALTH * GetModConfigData("alterguardian_health_")
    elseif v == "ALTERGUARDIAN_PHASE3" then        
        TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH = TUNING.ALTERGUARDIAN_PHASE3_STARTHEALTH * GetModConfigData("alterguardian_health_")
        TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH = TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH * GetModConfigData("alterguardian_health_")
    elseif v == "TWINOFTERROR1" then
        TUNING.TWIN1_HEALTH = TUNING.TWIN1_HEALTH * GetModConfigData("twinofterror_health_")
    elseif v == "TWINOFTERROR2" then
        TUNING.TWIN2_HEALTH = TUNING.TWIN2_HEALTH * GetModConfigData("twinofterror_health_")
    elseif v == "MUTATEDBEARGER" then
        TUNING.MUTATED_BEARGER_HEALTH = TUNING.MUTATED_BEARGER_HEALTH * GetModConfigData("mutated_bearger_health_")        
    elseif v == "MUTATEDDEERCLOPS" then
        TUNING.MUTATED_DEERCLOPS_HEALTH = TUNING.MUTATED_DEERCLOPS_HEALTH * GetModConfigData("mutated_deerclops_health_")        
    elseif v == "MUTATEDWARG" then
        TUNING.MUTATED_WARG_HEALTH = TUNING.MUTATED_WARG_HEALTH * GetModConfigData("mutated_warg_health_")
    elseif v == "ALTERGUARDIAN_PHASE1_LUNARRIFT" then
        TUNING.ALTERGUARDIAN_PHASE1_LUNARRIFT_HEALTH = TUNING.ALTERGUARDIAN_PHASE1_LUNARRIFT_HEALTH * GetModConfigData("wagboss_robot_health_")
    elseif v == "ALTERGUARDIAN_PHASE4_LUNARRIFT" then        
        TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_HEALTH = TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_HEALTH * GetModConfigData("wagboss_robot_health_")
    elseif v == "STALKER" then        
        TUNING.STALKER_HEALTH = TUNING.STALKER_HEALTH * GetModConfigData("stalker_atrium_health_")
    else
        TUNING[v.."_HEALTH"] = TUNING[v.."_HEALTH"] * GetModConfigData(string.lower(v).."_health_")
    end
end

TUNING.STALKER_ATRIUM_PHASE2_HEALTH = TUNING.STALKER_ATRIUM_PHASE2_HEALTH * GetModConfigData("stalker_atrium_health_")
TUNING.SHADOW_ROOK.HEALTH = {1000 * GetModConfigData("shadowpieces_health_"), 4000 * GetModConfigData("shadowpieces_health_"), 10000 * GetModConfigData("shadowpieces_health_")}
TUNING.SHADOW_KNIGHT.HEALTH = {900 * GetModConfigData("shadowpieces_health_"), 2700 * GetModConfigData("shadowpieces_health_"), 8100 * GetModConfigData("shadowpieces_health_")}
TUNING.SHADOW_BISHOP.HEALTH = {800 * GetModConfigData("shadowpieces_health_"), 2500 * GetModConfigData("shadowpieces_health_"), 7500 * GetModConfigData("shadowpieces_health_")}

local function BossMultiplier(inst)
    local name = inst.prefab:upper()
    local config = string.lower(name).."_health_"
    local m = GetModConfigData(config)

    if not m then
        if name == "ALTERGUARDIAN_PHASE1" or name == "ALTERGUARDIAN_PHASE2" or name == "ALTERGUARDIAN_PHASE3" then
            m = GetModConfigData("alterguardian_health_")
        elseif name == "ALTERGUARDIAN_PHASE1_LUNARRIFT" or name == "ALTERGUARDIAN_PHASE4_LUNARRIFT" then
            m = GetModConfigData("wagboss_robot_health_")
        elseif name == "STALKER" then
            m = GetModConfigData("stalker_atrium_health_")        
        elseif name == "TWINOFTERROR1" or name == "TWINOFTERROR2" then
            m = GetModConfigData("twinofterror_health_")
        elseif name == "MUTATEDBEARGER" then
            m = GetModConfigData("mutated_bearger_health_")
        elseif name == "MUTATEDDEERCLOPS" then
            m = GetModConfigData("mutated_deerclops_health_")
        elseif name == "MUTATEDWARG" then
            m = GetModConfigData("mutated_warg_health_")            
        end
    end

    return m or 1
end

local spookyskeletons_bosses = {
    stalker = true,
    stalker_atrium = true,
    stalker_forest = true,
}

local spookyskeletons_items = {
    fossil_piece = true,
    shadowheart = true,
}

local unique_loot = {}

local function MultiplyLoot(inst, mult)
    local lootdropper = inst.components.lootdropper
    if not lootdropper or mult == 1 then return end

    local _GenerateLoot = lootdropper.GenerateLoot
    lootdropper.GenerateLoot = function(self, ...)
        local base = _GenerateLoot(self, ...)
        local final = {}

        for _, prefab in ipairs(base) do
            table.insert(final, prefab)

            local multiply = true

            if spookyskeletons_bosses[inst.prefab] and spookyskeletons_items[prefab] then
                multiply = false
            end

            if unique_loot[prefab] then
                multiply = false
            end
                
            if multiply then
                local whole = math.floor(mult - 1)
                local frac = (mult - 1) % 1

                for i = 1, whole do
                    table.insert(final, prefab)
                end

                if frac > 0 and math.random() < frac then
                    table.insert(final, prefab)
                end
            end
        end

        return final
    end
end

local function Duplicator(inst, n)
    local m = 1 + (n - 1) / 2
    if m <= 1 then return end
    MultiplyLoot(inst, m)
end

for _, bossname in ipairs(bosses) do
    AddPrefabPostInit(string.lower(bossname), function(inst)
        if not TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, Duplicator, BossMultiplier(inst))
    end)
end

local shadowpieces = {
    "shadow_knight",
    "shadow_rook",
    "shadow_bishop",
}

local function MultiplyShadowLoot(inst, mult)
    local lootdropper = inst.components.lootdropper
    if not lootdropper or mult == 1 then return end

    local _lootsetupfn = lootdropper.lootsetupfn or function() end
    lootdropper:SetLootSetupFn(function(lootdropper)
        _lootsetupfn(lootdropper)

        local base_loot = lootdropper.loot or {}
        local final_loot = {}

        for _, prefab in ipairs(base_loot) do
            table.insert(final_loot, prefab)

            local whole = math.floor(mult - 1)
            local frac = (mult - 1) % 1

            for i = 1, whole do
                table.insert(final_loot, prefab)
            end

            if frac > 0 and math.random() < frac then
                table.insert(final_loot, prefab)
            end
        end

        lootdropper.loot = final_loot
    end)
end

for _, prefab in ipairs(shadowpieces) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, function()
            local n = GetModConfigData("shadowpieces_health_")
            local m = 1 + (n - 1) / 2
            if m <= 1 then return end
            MultiplyShadowLoot(inst, m)
        end)
    end)
end

AddPrefabPostInit("leif_sparse", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("leif_health_"))
end)

AddPrefabPostInit("daywalker2", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("daywalker_health_"))
end)

AddPrefabPostInit("stalker_forest", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("stalker_atrium_health_"))
end)

AddPrefabPostInit("moonmaw_dragonfly", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("moonmaw_dragonfly_health_"))
end)

AddPrefabPostInit("mock_dragonfly", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("mock_dragonfly_health_"))
end)

AddPrefabPostInit("hoodedwidow", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, Duplicator, GetModConfigData("hoodedwidow_health_"))
end)
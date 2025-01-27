local env = env
GLOBAL.setfenv(1, GLOBAL)



local UpvalueHacker = require("tools/upvaluehacker")


env.AddComponentPostInit("hounded", function(self)
    local _spawndata = UpvalueHacker.GetUpvalue(self.SetSpawnData, "_spawndata")
    function self:GetSpawnData() return _spawndata end

    local _spawnwintervariant = UpvalueHacker.GetUpvalue(self.SetWinterVariant, "_spawnwintervariant")
    local _spawnsummervariant = UpvalueHacker.GetUpvalue(self.SetSummerVariant, "_spawnsummervariant")

    local SummonSpawn = UpvalueHacker.GetUpvalue(self.SummonSpawn, "SummonSpawn")
    local _GetSpawnPrefab = UpvalueHacker.GetUpvalue(SummonSpawn, "GetSpawnPrefab")
    local GetSpecialSpawnChance = UpvalueHacker.GetUpvalue(_GetSpawnPrefab, "GetSpecialSpawnChance")
    local GetSpawnPoint = UpvalueHacker.GetUpvalue(self.SummonSpawn, "SummonSpawn", "GetSpawnPoint")
    local _OldGetSpawnPrefab = UpvalueHacker.GetUpvalue(_GetSpawnPrefab, "OldGetSpawnPrefab")

    --Winterlands compat. 
    if _OldGetSpawnPrefab or not GetSpawnPoint then
        GetSpecialSpawnChance = UpvalueHacker.GetUpvalue(_OldGetSpawnPrefab, "GetSpecialSpawnChance")
        GetSpawnPoint = UpvalueHacker.GetUpvalue(SummonSpawn, "OldSummonSpawn", "GetSpawnPoint")
    end

    local function GetSpawnPrefab(upgrade)
        --not good, but I need to be able to refresh this spawn data for caves.
        if upgrade and _spawndata.upgrade_spawn then
            return (TheWorld.state.iswinter and _spawndata.upgrade_spawn_summer ~= nil and _spawndata.upgrade_spawn_winter or TheWorld.state.issummer and _spawndata.upgrade_spawn_summer ~= nil and _spawndata.upgrade_spawn_summer or _spawndata.upgrade_spawn)
        end

        local do_seasonal_spawn = math.random() < GetSpecialSpawnChance()
        if do_seasonal_spawn then
            if _spawnwintervariant and (TheWorld.state.iswinter or TheWorld.state.isspring) then
                return _spawndata.spring_prefab ~= nil and TheWorld.state.isspring and math.random() > 0.66 and _spawndata.spring_prefab or _spawndata.winter_prefab
            end
            if _spawnsummervariant and (TheWorld.state.issummer or TheWorld.state.isautumn) then
                return _spawndata.autumn_prefab ~= nil and TheWorld.state.isautumn and math.random() > 0.66 and _spawndata.autumn_prefab or _spawndata.summer_prefab
            end
        end

        return _spawndata.base_prefab
    end
    local function NoHoles(pt)
        return not TheWorld.Map:IsPointNearHole(pt)
    end

    local SPAWN_DIST = 30

    local function GetMagmaSpawnPoint(pt)
        if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
            pt = FindNearbyLand(pt, 1) or pt
        end
        local offset = FindWalkableOffset(pt, math.random() * 2 * PI, SPAWN_DIST, 12, true, true,
            NoHoles)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    end


    local function SummonSpawn(pt, upgrade, radius_override)
        local prefab = GetSpawnPrefab(upgrade)
        local spawn_pt = prefab == "magmahound" and GetMagmaSpawnPoint(pt) or GetSpawnPoint(pt, radius_override)
        if spawn_pt ~= nil then
            local spawn = SpawnPrefab(prefab)
            if spawn ~= nil then
                if spawn.hounded_overridelocation then
                    local new_spawn_pt = spawn:hounded_overridelocation(pt)
                    if new_spawn_pt then
                        spawn_pt = new_spawn_pt
                    end
                end

                if spawn.Physics then
                    spawn.Physics:Teleport(spawn_pt:Get())
                else
                    spawn.Transform:SetPosition(spawn_pt:Get())
                end
                spawn:FacePoint(pt)
                if spawn.components.spawnfader ~= nil then
                    spawn.components.spawnfader:FadeIn()
                end
                return spawn
            end
        end
    end

    UpvalueHacker.SetUpvalue(self.SummonSpawn, SummonSpawn, "SummonSpawn")
end)

local wormspawn =
{
    base_prefab = "worm",
    upgrade_spawn = "worm_boss",
    winter_prefab = TUNING.DSTU.DEPTHSEELS and "shockworm" or "worm",
    summer_prefab = TUNING.DSTU.DEPTHSVIPERS and "viperworm" or "worm",

    attack_levels =
    {
        intro = { warnduration = function() return 120 end, numspawns = function() return 1 end },                    -- 1
        light = { warnduration = function() return 60 end, numspawns = function() return 1 + math.random(0, 1) end }, -- 1-2
        med   = { warnduration = function() return 45 end, numspawns = function() return 1 + math.random(0, 1) end }, -- 1-2
        heavy = { warnduration = function() return 30 end, numspawns = function() return 2 + math.random(0, 1) end }, -- 2-3
        crazy = { warnduration = function() return 30 end, numspawns = function() return 3 + math.random(0, 2) end }, -- 3-5
    },

    attack_delays =
    {
        intro      = function() return TUNING.TOTAL_DAY_TIME * 6, math.random() * TUNING.TOTAL_DAY_TIME * 2.5 end,
        rare       = function() return TUNING.TOTAL_DAY_TIME * 7, math.random() * TUNING.TOTAL_DAY_TIME * 2.5 end,
        occasional = function() return TUNING.TOTAL_DAY_TIME * 8, math.random() * TUNING.TOTAL_DAY_TIME * 2.5 end,
        frequent   = function() return TUNING.TOTAL_DAY_TIME * 9, math.random() * TUNING.TOTAL_DAY_TIME * 2.5 end,
        crazy      = function() return TUNING.TOTAL_DAY_TIME * 10, math.random() * TUNING.TOTAL_DAY_TIME * 2.5 end,
    },

    specialupgradecheck = function(wave_pre_upgraded, wave_override_chance, _wave_override_settings)
        wave_pre_upgraded = nil

        local chance = wave_override_chance * (_wave_override_settings["worm_boss"] or 1)
        if _wave_override_settings["worm_boss"] ~= 0 and (math.random() < chance or _wave_override_settings["worm_boss"] == 9999) then
            wave_pre_upgraded = "available"
        end

        if wave_pre_upgraded == "available" then
            wave_override_chance = 0
        elseif TheWorld.state.cycles > TUNING.WORM_BOSS_DAYS then
            wave_override_chance = math.min(0.5, wave_override_chance + 0.05)
        end

        return wave_pre_upgraded, wave_override_chance
    end,

    warning_speech = function(wave_pre_upgraded)
        if wave_pre_upgraded then
            return "ANNOUNCE_WORMS_BOSS", wave_pre_upgraded
        end
        return "ANNOUNCE_WORMS", wave_pre_upgraded
    end,

    warning_sound_thresholds = function(wave_pre_upgraded, wave_override_chance)
        if wave_pre_upgraded then
            return {
                { time = 30,  sound = "WORM_BOSS" },
                { time = 60,  sound = "WORM_BOSS" },
                { time = 90,  sound = "WORM_BOSS" },
                { time = 500, sound = "WORM_BOSS" },
            }, wave_pre_upgraded
        else
            return {
                { time = 30,  sound = "LVL4_WORM" },
                { time = 60,  sound = "LVL3_WORM" },
                { time = 90,  sound = "LVL2_WORM" },
                { time = 500, sound = "LVL1_WORM" },
            }, wave_pre_upgraded
        end
    end,

    ShouldUpgrade = function(amount, wave_pre_upgraded)
        if wave_pre_upgraded == "available" then
            wave_pre_upgraded = "used" -- We've got one for the wave now, clear this so there aren't more.
            return true, amount, wave_pre_upgraded
        else
            return false, nil, wave_pre_upgraded
        end
    end,
}

env.AddPrefabPostInit("cave", function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.hounded ~= nil then
        local spawndata = inst.components.hounded:GetSpawnData()
        for k, v in pairs(wormspawn) do
            spawndata[k] = v
        end
        inst.components.hounded:SetSpawnData(wormspawn)
    end
end)

env.AddPrefabPostInit("forest", function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.hounded ~= nil then
        local spawndata = inst.components.hounded:GetSpawnData()
        if TUNING.DSTU.SPOREHOUNDS then
            spawndata.autumn_prefab = "sporehound"
        end
        if TUNING.DSTU.LIGHTNINGHOUNDS then
            spawndata.spring_prefab = "lightninghound"
        end
        if TUNING.DSTU.GLACIALHOUNDS then
            spawndata.upgrade_spawn_winter = "glacialhound"
        end
        if TUNING.DSTU.MAGMAHOUNDS then
            spawndata.upgrade_spawn_summer = "magmahound"
        end
    end
end)

--decided to keep all skilltree experience changes centered here for easier access of all parts. - Atoba
--GOD this is a mess.
--TODO: UNMESS THIS

local function ResetSkills(prefab)
    if ThePlayer ~= nil then
        GLOBAL.TheSkillTree:RespecSkills(GLOBAL.ThePlayer.prefab)
        GLOBAL.TheSkillTree.skillxp[GLOBAL.ThePlayer.prefab] = GLOBAL.TheWorld.state.cycles --reset skillpoints.
    else
        GLOBAL.TheSkillTree:RespecSkills(prefab)
        GLOBAL.TheSkillTree.skillxp[prefab] = GLOBAL.TheWorld.state.cycles --reset skillpoints.
    end
    --[[
    GLOBAL.TheGenericKV:SetKV("wathgrithr_instantsong_uses", "0")
    GLOBAL.TheGenericKV:SetKV("wathgrithr_container_unlocked", "0")
    GLOBAL.TheGenericKV:SetKV("wathgrithr_horn_played", "0")
    GLOBAL.TheGenericKV:SetKV("celestialchampion_killed", "0")
    GLOBAL.TheGenericKV:SetKV("fuelweaver_killed", "0")]]
end

local function SyncXp(prefab, xp)
    print(xp)
    if xp > 140 then
        xp = 140
    end
    print(xp)
    GLOBAL.TheSkillTree.skillxp[prefab] = math.min(xp, GLOBAL.TheSkillTree:GetMaximumExperiencePoints())
    if GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.components.skilltreeupdater ~= nil and GLOBAL.ThePlayer.components.skilltreeupdater.skilltree ~= nil then
        GLOBAL.ThePlayer.components.skilltreeupdater.skilltree.skillxp[prefab] = math.min(xp, GLOBAL.TheSkillTree:GetMaximumExperiencePoints()) --sync points for everyone with day count.
    end
    if GLOBAL.TheSkillTree:GetAvailableSkillPoints() > 0 then
        if GLOBAL.ThePlayer ~= nil then
            GLOBAL.ThePlayer.new_skill_available_popup = true
            GLOBAL.ThePlayer:PushEvent("newskillpointupdated")
        end
    end
end


local function SyncBossKills(sending_shard_id, boss, isminiboss)
    print("Hi! Sync boss kills!")
    print(sending_shard_id, boss_kills, miniboss_kills)
    if isminiboss then
        GLOBAL.TheWorld.minibosses_defeated[boss] = true
    else
        GLOBAL.TheWorld.bosses_defeated[boss] = true
    end
end

AddClientModRPCHandler("WorldlySkilltrees", "ResetSkills", ResetSkills)
AddClientModRPCHandler("WorldlySkilltrees", "SyncXp", SyncXp)
AddShardModRPCHandler("WorldlySkilltrees", "SyncBossKills", SyncBossKills)

local env = env
GLOBAL.setfenv(1, GLOBAL)


TUNING.SKILL_THRESHOLDS = {
    0,  --1
    10, --2
    10, --3
    10, --4
    10, --5
    10, --6
    10, --7
    10, --8
    10, --9
    10, --10
    10, --11
    10, --12
    10, --13
    10, --14
    10, --15
}


env.AddComponentPostInit("skilltreeupdater", function(self)
    self.skip_validation = true
end)


local function GetBossXPBonus()
    local boss_bonus = 0

    for k, v in pairs(TheWorld.bosses_defeated) do
        boss_bonus = boss_bonus + 7.5
    end

    for k, v in pairs(TheWorld.minibosses_defeated) do
        boss_bonus = boss_bonus + 5
    end

    return boss_bonus
end


local TheSkillTree = require("skilltreedata")()
local function TrySkilltreeReset(character)
    if TheSkillTree ~= nil then
        TheSkillTree.save_enabled = false
    end
    if character.hasresetskills ~= true then
        SendModRPCToClient(GetClientModRPC("WorldlySkilltrees", "ResetSkills"), ThePlayer ~= nil and ThePlayer.userid or character.userid, character.prefab)

        local skilltreeupdater = character.components.skilltreeupdater

        if skilltreeupdater ~= nil and skilltreeupdater:GetActivatedSkills() ~= nil then
            for k, v in pairs(skilltreeupdater:GetActivatedSkills()) do
                skilltreeupdater:DeactivateSkill(k)
            end
        end



        if skilltreeupdater ~= nil then  
            skilltreeupdater.skilltree.skillxp[character.prefab] = math.min(TheWorld.state.cycles + GetBossXPBonus(), TheSkillTree:GetMaximumExperiencePoints()) --reset skillpoints.
        end
        character.hasresetskills = true
    end
end

local function __newindex(t, k, v)
    print("__newindex")

    for k, player in pairs(AllPlayers) do
        player.components.skilltreeupdater.skilltree.skillxp[player.prefab] = math.min(TheWorld.state.cycles + GetBossXPBonus(), TheSkillTree:GetMaximumExperiencePoints())
        SendModRPCToClient(GetClientModRPC("WorldlySkilltrees", "SyncXp"), ThePlayer ~= nil and ThePlayer.userid or player.userid, player.prefab, math.min(TheWorld.state.cycles + GetBossXPBonus(), TheSkillTree:GetMaximumExperiencePoints()))
    end

    rawset(t, k, v)
end

env.AddPrefabPostInit("world", function(inst)
    if TheWorld.bosses_defeated == nil then
        TheWorld.bosses_defeated = {}
    end
    if TheWorld.minibosses_defeated == nil then
        TheWorld.minibosses_defeated = {}
    end

    setmetatable(TheWorld.bosses_defeated, {
        __newindex = __newindex
    })
    setmetatable(TheWorld.minibosses_defeated, {
        __newindex = __newindex
    })

    TheWorld:ListenForEvent("ms_newplayercharacterspawned", function(inst, data)
        if data ~= nil and data.mode ~= nil and data.player ~= nil then
            if data.mode ~= "Load" then
                TrySkilltreeReset(data.player)
            end
        end
    end)

    if not TheWorld.ismastersim then return end

    local _OnSave = inst.OnSave

    TheWorld.OnSave = function(inst, data, ...)
        data.bosses_defeated = TheWorld.bosses_defeated
        data.minibosses_defeated = TheWorld.minibosses_defeated

        if _OnSave ~= nil then
            return _OnSave(inst, data, ...)
        end
    end

    local _OnLoad = inst.OnLoad

    TheWorld.OnLoad = function(inst, data, ...)
        if data then
            TheWorld.bosses_defeated = data.bosses_defeated
            TheWorld.minibosses_defeated = data.minibosses_defeated

            setmetatable(TheWorld.bosses_defeated, {
                __newindex = __newindex
            })
            setmetatable(TheWorld.minibosses_defeated, {
                __newindex = __newindex
            })
        end

        if _OnLoad ~= nil then
            return _OnLoad(inst, data, ...)
        end
    end
end)

env.AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    local _OnSave = inst.OnSave

    inst.OnSave = function(inst, data, ...)
        data.hasresetskills = inst.hasresetskills
        if _OnSave ~= nil then
            return _OnSave(inst, data, ...)
        end
    end

    local _OnLoad = inst.OnLoad

    inst.OnLoad = function(inst, data, ...)
        if data then
            if data.hasresetskills then
                inst.hasresetskills = data.hasresetskills
                if not inst.hasresetskills then
                    TrySkilltreeReset(inst)
                end
            end
        end

        if _OnLoad ~= nil then
            return _OnLoad(inst, data, ...)
        end
    end
end)

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst ~= nil and inst:HasTag("epic") and inst.components.health ~= nil then
        inst:ListenForEvent("death", function(inst)
            if TheWorld.bosses_defeated[inst.prefab] ~= true and inst.components.health.maxhealth >= 3500 then
                TheWorld.bosses_defeated[inst.prefab] = true
            elseif TheWorld.minibosses_defeated[inst.prefab] ~= true then
                TheWorld.minibosses_defeated[inst.prefab] = true
            end
            SendModRPCToShard(GetShardModRPC("WorldlySkilltrees", "SyncBossKills"), nil, inst.prefab, inst.components.health.maxhealth < 3500)
        end)
    end
end)

env.AddComponentPostInit("experiencecollector", function(self)
    local skilltreedefs = require "prefabs/skilltree_defs"

    function self:UpdateXp()
        if not skilltreedefs.SKILLTREE_DEFS[self.inst.prefab] then
            return nil
        end


        self.inst.components.skilltreeupdater.skilltree.skillxp[self.inst.prefab] = math.min(TheWorld.state.cycles + GetBossXPBonus(), TheSkillTree:GetMaximumExperiencePoints()) --sync points for everyone with day count.
        --self.inst.components.skilltreeupdater:AddSkillXP(0)                                                            --scuffed, but I need to get an update.
        SendModRPCToClient(GetClientModRPC("WorldlySkilltrees", "SyncXp"), ThePlayer ~= nil and ThePlayer.userid or self.inst.userid, self.inst.prefab, math.min(TheWorld.state.cycles + GetBossXPBonus(), TheSkillTree:GetMaximumExperiencePoints()))
    end

    self.inst:DoTaskInTime(0, function() self:UpdateXp() end)
end)

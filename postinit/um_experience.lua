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
    GLOBAL.TheSkillTree.skillxp[prefab] = xp

    if GLOBAL.TheSkillTree:GetAvailableSkillPoints() > 0 then
        GLOBAL.ThePlayer.new_skill_available_popup = true
        GLOBAL.ThePlayer:PushEvent("newskillpointupdated")
    end
end

AddClientModRPCHandler("WorldlySkilltrees", "ResetSkills", ResetSkills)
AddClientModRPCHandler("WorldlySkilltrees", "SyncXp", SyncXp)

local env = env
GLOBAL.setfenv(1, GLOBAL)


TUNING.SKILL_THRESHOLDS = {
        0,  --1
        5,  --2
        5,  --3
        5,  --4
        5,  --5
        10, --6
        10, --7
        10, --8
        10, --9
        10, --10
        15, --11
        15, --12
        15, --13
        15, --14
        15, --15
    },

    env.AddComponentPostInit("skilltreeupdater", function(self)
        self.skip_validation = true
    end)



local TheSkillTree = require("skilltreedata")()
local function ResetSkilltree(character)
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
            skilltreeupdater.skilltree.skillxp[character.prefab] = TheWorld.state.cycles --reset skillpoints.
        end
        character.hasresetskills = true
    end
end

env.AddPrefabPostInit("world", function(inst)
    TheWorld:ListenForEvent("ms_newplayercharacterspawned", function(inst, data)
        if data ~= nil and data.mode ~= nil and data.player ~= nil then
            if data.mode ~= "Load" then
                ResetSkilltree(data.player)
            end
        end
    end)
end)

env.AddPlayerPostInit(function(inst)
    inst:ListenForEvent("boss_defeated", function(inst, data)
        local boss, trueboss = data.boss, data.trueboss

        if inst.bosses_defeated == nil then inst.bosses_defeated = {} end

        if not inst.bosses_defeated[boss] then
            inst.bosses_defeated[boss] = true
            if inst.components.skilltreeupdater ~= nil then
                inst.components.skilltreeupdater:AddSkillXP(trueboss and 10 or 5)
            end
        end
    end)

    if not TheWorld.ismastersim then return end

    local _OnSave = inst.OnSave

    inst.OnSave = function(inst, data, ...)
        data.bosses_defeated = inst.bosses_defeated
        data.hasresetskills = inst.hasresetskills
        if _OnSave ~= nil then
            return _OnSave(inst, data, ...)
        end
    end

    local _OnLoad = inst.OnLoad

    inst.OnLoad = function(inst, data, ...)
        if data then
            if data.bosses_defeated then
                inst.bosses_defeated = data.bosses_defeated
            end
            if data.hasresetskills then
                inst.hasresetskills = data.hasresetskills
                if not inst.hasresetskills then
                    ResetSkilltree(inst)
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
            for k, v in pairs(AllPlayers) do
                v:PushEvent("boss_defeated", { boss = inst.prefab, trueboss = inst.components.health.maxhealth >= 3500 })
            end
        end)
    end
end)

env.AddComponentPostInit("experiencecollector", function(self)
    local skilltreedefs = require "prefabs/skilltree_defs"

    function self:UpdateXp()
        if not skilltreedefs.SKILLTREE_DEFS[self.inst.prefab] then
            return nil
        end


        local boss_bonus = 0
        if self.inst.bosses_defeated ~= nil then
            for k, v in pairs(self.inst.bosses_defeated) do
                boss_bonus = boss_bonus + 10
            end
        end

        self.inst.components.skilltreeupdater.skilltree.skillxp[self.inst.prefab] = TheWorld.state.cycles + boss_bonus --sync points for everyone with day count.
        self.inst.components.skilltreeupdater:AddSkillXP(0)                                                            --scuffed, but I need to get an update.
        SendModRPCToClient(GetClientModRPC("WorldlySkilltrees", "SyncXp"), ThePlayer ~= nil and ThePlayer.userid or self.inst.userid, self.inst.prefab, TheWorld.state.cycles + boss_bonus)
    end

    self.inst:DoTaskInTime(0, function() self:UpdateXp() end)
end)

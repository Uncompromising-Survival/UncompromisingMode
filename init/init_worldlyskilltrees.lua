-- List of all enabled prefabs where the changes of the skilltrees will be applied
local enabled_prefabs = GLOBAL.DST_CHARACTERLIST 

-- Here come all the changes to the skilltrees and their point system
-- also the ability to have different skillpoints for different worlds.
local SkillTreeData = require("skilltreedata")
local skilltreedefs = require "prefabs/skilltree_defs"


-- Apply our THRESHOLDS to the character if it's enabled
TUNING.SKILL_THRESHOLDS = {
    10, --1
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


-- We need to set the loaded values to zero/nil so that we can take those from the server
local old_Load = SkillTreeData.Load
function SkillTreeData:Load(...)
    old_Load(self, ...)
    for k, prefab in pairs(enabled_prefabs) do
        if self.activatedskills then
            self.activatedskills[prefab] = nil
        end
        if self.skillxp then
            self.skillxp[prefab] = nil
        end
    end
end

local _old_OPAH_DoBackup = SkillTreeData.OPAH_DoBackup
function SkillTreeData:OPAH_DoBackup(...)
    local characterprefab = (GLOBAL.ThePlayer and GLOBAL.ThePlayer.prefab) or (self.owner and self.owner.prefab)
    local flag = characterprefab and enabled_prefabs[characterprefab]
    -- If it's an enabled character, reset their activated skills and xp as they get the data from the server
    if flag then
        self.activatedskills[characterprefab], self.skillxp[characterprefab] = nil, 0
    end
    _old_OPAH_DoBackup(self, ...)
end

local _old_OPAH_Ready = SkillTreeData.OPAH_Ready
function SkillTreeData:OPAH_Ready(...)
    local characterprefab = (GLOBAL.ThePlayer and GLOBAL.ThePlayer.prefab) or (self.owner and self.owner.prefab)
    local flag = characterprefab and enabled_prefabs[characterprefab]
    local activatedskills_backup
    local old_AddSkillXP
    local skilltreeupdater = GLOBAL.ThePlayer.components.skilltreeupdater
    -- If it's an enabled prefab, make the AddSkillXP function to nothing as otherwise the toast may be triggered even if it shouldn't
    -- Then backup the activated skills received from the server
    if flag then
        old_AddSkillXP = skilltreeupdater.AddSkillXP
        skilltreeupdater.AddSkillXP = function() end
        activatedskills_backup = self.activatedskills[characterprefab]
    end
    -- Run the original Ready function
    _old_OPAH_Ready(self, ...)
    -- Set the activated skills to the backup, restore the AddSkillXP function and check if toast should be triggered
    if flag then
        self.activatedskills[characterprefab] = activatedskills_backup
        skilltreeupdater.AddSkillXP = old_AddSkillXP
        skilltreeupdater:AddSkillXP(0)
    end
end

-- We add a client mod rpc to send the xp from the server to the client, as it is not sent by default
local function SetXPSkillTree(inst, amount)
    if inst and inst.components.skilltreeupdater then
        inst.components.skilltreeupdater.skilltree.skillxp[inst.prefab] = amount
        --dumptable(inst.components.skilltreeupdater.skilltree)
    end
end

AddClientModRPCHandler("UncompromisingSurvival", "SetXPSkillTree", SetXPSkillTree)

-- Nearly copy of the original function except for sending the server xp to the client
AddComponentPostInit("skilltreeupdater", function(self)
    local old_SendFromSkillTreeBlob = self.SendFromSkillTreeBlob
    function self:SendFromSkillTreeBlob(inst, ...)
        if enabled_prefabs[self.inst.prefab] then
            if self.skilltreeblob ~= nil and (self.skilltreeblobprefab == nil or self.skilltreeblobprefab == self.inst.prefab) then
                local activatedskills, xp = self.skilltree:DecodeSkillTreeData(self.skilltreeblob)
                -- Set xp
                GLOBAL.TheSkillTree.ignorexp = true
                self:AddSkillXP(xp, nil, true)
                SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "SetXPSkillTree"), self.inst.userid, self.inst, xp)
                GLOBAL.TheSkillTree.ignorexp = nil

                -- At this point the client will have sent their current XP to measure from so use that value and not the local stored invalid XP.
                self.skilltreeblob = nil
                self.skilltreeblobprefab = nil
                if self.skilltree:ValidateCharacterData(self.inst.prefab, activatedskills, self:GetSkillXP()) then
                    if activatedskills ~= nil then
                        self:SetSkipValidation(true) -- Validated already skip checking again.
                        self:SetSilent(true)
                        for skill, _ in pairs(activatedskills) do
                            self:DeactivateSkill(skill)
                        end
                        self:SetSilent(false)
                        -- The skills are validated so apply them and network them if need be.
                        for skill, _ in pairs(activatedskills) do -- Two loops just in case of activation states.
                            self:ActivateSkill(skill)
                        end
                        self:SetSkipValidation(false)

                        self.inst:PushEvent("onsetskillselection_server")
                    end
                end
            end
        else
            old_SendFromSkillTreeBlob(self, inst, ...)
        end
    end
end)



local function masterpostinit_skilltree_fn(inst)
    if GLOBAL.TheWorld.ismastersim then
        local skilltreedefs = require "prefabs/skilltree_defs"
        if skilltreedefs.SKILLTREE_DEFS[inst.prefab] then
            inst:AddComponent("modexperiencecollector")
        end
    end
    return inst
end

AddPlayerPostInit(masterpostinit_skilltree_fn)


-- These events need to be monitored to know when the player completes them
-- as they are needed to unlock locks in some skilltrees
local generickv_to_overwrite = {
    fuelweaver_killed = true,
    celestialchampion_killed = true,
    wathgrithr_container_unlocked = true,
    wathgrithr_horn_played = true,
    wathgrithr_instantsong_uses = true,
}

-- If we want to reset these events for each world, we overwrite some functionality of TheGenericKV
-- which saves these events to only give the events completed of this world.
local GenericKV = require("generickv")
GenericKV.modded_kvs = {}
local old_GetKV = GenericKV.GetKV
function GenericKV:GetKV(key)
    local prefab = (GLOBAL.ThePlayer and GLOBAL.ThePlayer.prefab) or nil
    if generickv_to_overwrite[key] ~= nil and prefab and enabled_prefabs[prefab] then
        return self.modded_kvs[key]
    end
    return old_GetKV(self, key)
end

local old_SetKV = GenericKV.SetKV
function GenericKV:SetKV(key, value)
    local res = old_SetKV(self, key, value)
    local prefab = (GLOBAL.ThePlayer and GLOBAL.ThePlayer.prefab) or nil
    if res and generickv_to_overwrite[key] ~= nil and prefab and enabled_prefabs[prefab] then
        self.modded_kvs[key] = value
    end
    return res
end

-- This is used to send our completed events from the server to the client
local function SetModdedGenericKV(key, value)
    if GLOBAL.TheGenericKV then
        GLOBAL.TheGenericKV.modded_kvs[key] = value and tostring(value) or "1"
    end
end

AddClientModRPCHandler("UncompromisingSurvival", "SetModdedGenericKV", SetModdedGenericKV)

local function AddModdedGenericKVToMaster(_, userid, key, value, increase)
    if GLOBAL.TheWorld.components.modgenerickv then
        if increase then
            GLOBAL.TheWorld.components.modgenerickv:IncreaseValue(userid, key, value, increase)
        else
            GLOBAL.TheWorld.components.modgenerickv:SetValue(userid, key, value)
        end
    end
end

AddShardModRPCHandler("UncompromisingSurvival", "AddModdedGenericKVToMaster", AddModdedGenericKVToMaster)

local function SendModdedGenericKVFromMaster(shard_id, userid)
    if GLOBAL.TheWorld.components.modgenerickv then
        GLOBAL.TheWorld.components.modgenerickv:SendToShard(userid, shard_id)
    end
end

AddShardModRPCHandler("UncompromisingSurvival", "SendModdedGenericKVFromMaster", SendModdedGenericKVFromMaster)

local function SendModdedGenericKVToShard(_, userid, key, value)
    SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "SetModdedGenericKV"), userid, key, value)
end

AddShardModRPCHandler("UncompromisingSurvival", "SendModdedGenericKVToShard", SendModdedGenericKVToShard)

local function SendModdedGenericKV(inst)
    if GLOBAL.TheWorld.ismastershard then
        if GLOBAL.TheWorld.components.modgenerickv then
            GLOBAL.TheWorld.components.modgenerickv:SendToClient(inst.userid)
        end
    else
        SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "SendModdedGenericKVFromMaster"), 1, inst.userid)
    end
end

local function playerspawn(world, player)
    -- Wait a second so everything has been correctly loaded
    if player then
        world:DoTaskInTime(1, function()
            SendModdedGenericKV(player)
        end)
    end
end

local function world_postinit(world)
        if world.ismastershard then
            world:AddComponent("modgenerickv")
            -- Send modded generic kv on player spawn
        end
        world:ListenForEvent("ms_playerspawn", playerspawn)
end

AddPrefabPostInit("world", world_postinit)

local function SetInMaster(userid, key, value, increase)
    if GLOBAL.TheWorld.ismastershard then
        if GLOBAL.TheWorld.components.modgenerickv then
            if increase then
                GLOBAL.TheWorld.components.modgenerickv:IncreaseValue(userid, key, value, increase)
            else
                GLOBAL.TheWorld.components.modgenerickv:SetValue(userid, key, value)
            end
        end
    else
        SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "AddModdedGenericKVToMaster"), 1, userid, key, value, increase)
    end
end

AddPrefabPostInit("alterguardian_phase3", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("death", function()
        for ID in pairs(inst.attackerUSERIDs) do
            SetInMaster(ID, "celestialchampion_killed")
        end
    end)
end)

AddPrefabPostInit("stalker_atrium", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("death", function()
        for ID in pairs(inst.attackerUSERIDs) do
            SetInMaster(ID, "fuelweaver_killed")
        end
    end)
end)

for name in pairs(require("prefabs/battlesongdefs").song_defs) do
    local function IsBattleSong(item)
        return item:HasTag("battlesong")
    end
    AddPrefabPostInit(name, function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("onputininventory", function(_, owner)
            if owner ~= nil and owner:HasTag("battlesinger") and owner.components.skilltreeupdater ~= nil and not owner.components.skilltreeupdater:IsActivated("wathgrithr_songs_container") then
                local battlesongs = owner.components.inventory:FindItems(IsBattleSong)

                local battlesongs_prefabs = {}

                for _, item in ipairs(battlesongs) do
                    battlesongs_prefabs[item.prefab] = true
                end

                if GLOBAL.GetTableSize(battlesongs_prefabs) >= TUNING.SKILLS.WATHGRITHR.BATTLESONGS_CONTAINER_NUM_BATTLESONGS_TO_UNLOCK then
                    SetInMaster(owner.userid, "wathgrithr_container_unlocked")
                end
            end
        end)
    end)
end

AddPrefabPostInit("horn", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
    local old_OnPlayHorn = inst.components.instrument.onplayed
    inst.components.instrument.onplayed = function(_inst, musician)
        if musician ~= nil and
            musician:HasTag("battlesinger") and
            musician.components.skilltreeupdater ~= nil and
            not musician.components.skilltreeupdater:IsActivated("wathgrithr_songs_revivewarrior")
        then
            SetInMaster(musician.userid, "wathgrithr_horn_played")
        end
        return old_OnPlayHorn(_inst, musician)
    end
end)

AddComponentPostInit("singinginspiration", function(self)
    local old_OnAddInstantSong = self.OnAddInstantSong
    function self:OnAddInstantSong(song)
        if not self.inst.components.skilltreeupdater:IsActivated("wathgrithr_songs_instantsong_cd") then
            SetInMaster(self.inst.userid, "wathgrithr_instantsong_uses", 1, TUNING.SKILLS.WATHGRITHR.INSTANTSONG_CD_UNLOCK_COUNT)
        end
        old_OnAddInstantSong(self, song)
    end
end)

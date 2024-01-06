--[[
    This file belongs to monti1811's "Configurable Skilltrees" mod; adapted for Uncompromising Mode. All credits go to Monti.
]]

local skilltreedefs = require "prefabs/skilltree_defs"

local bosses = { --copy for onsave
    "alterguardian_phase1",
    "alterguardian_phase2",
    "alterguardian_phase3",
    "antlion",
    "bearger",
    "beequeen",
    "crabking",
    "deerclops",
    "dragonfly",
    "eyeofterror",
    "klaus",
    "lordfruitfly",
    "malbatross",
    "moose",
    "minotaur",
    "shadow_rook",
    "shadow_knight",
    "shadow_bishop",
    "sharkboi",
    "stalker_forest",
    "stalker",
    "stalker_atrium",
    "toadstool",
    "twinofterror1",
    "twinofterror2",
    "hoodedwidow",
    "moonmaw_dragonfly",
    "mutateddeerclops",
    "mutatadwarg",
    "mutatedbearger"
}

local ModExperienceCollector = Class(function(self, inst)
    self.inst = inst
    self.enemy_threshold = {
        epic = (2.5),
        boss = (7.5),
    }
    self.bosses = {
        "alterguardian_phase1",
        "alterguardian_phase2",
        "alterguardian_phase3",
        "antlion",
        "bearger",
        "beequeen",
        "crabking",
        "deerclops",
        "dragonfly",
        "eyeofterror",
        "klaus",
        "lordfruitfly",
        "malbatross",
        "moose",
        "minotaur",
        "shadow_rook",
        "shadow_knight",
        "shadow_bishop",
        "sharkboi",
        "stalker_forest",
        "stalker",
        "stalker_atrium",
        "toadstool",
        "twinofterror1",
        "twinofterror2",
        "hoodedwidow",
        "moonmaw_dragonfly"
    }
    self.bosses = table.invert(self.bosses)
    self.fighting_xp = 0

    self.inst:ListenForEvent("killed", function(_, data)
        self:OnKilled(data)
    end)
end)

function ModExperienceCollector:OnKilled(data)
    if not skilltreedefs.SKILLTREE_DEFS[self.inst.prefab] then
        return nil
    end

    for k,v in pairs(AllPlayers) do
        if v ~= self.inst then
            v.components.modexperiencecollector:OnKilled(data)
        end
    end

    if data.victim and data.victim.components.health and data.victim.components.health.maxhealth > 0 then
        local enemy_type = (self.bosses[data.victim.prefab] ~= nil or data.victim.components.health.maxhealth >= 3500 and data.victim:HasTag("epic")) and "boss" or data.victim:HasTag("epic") and "epic"
        local xp = self.enemy_threshold[enemy_type] or 0
        self.fighting_xp = self.fighting_xp + xp
        if self.fighting_xp >= 1 then
            self.inst.components.skilltreeupdater:AddSkillXP(math.floor(self.fighting_xp))
            self.fighting_xp = self.fighting_xp - math.floor(self.fighting_xp)
        end
    end
end

function ModExperienceCollector:OnEvent(event)
    if not skilltreedefs.SKILLTREE_DEFS[self.inst.prefab] then
        return nil
    end
end

function ModExperienceCollector:DoDelta(xp)
    if not skilltreedefs.SKILLTREE_DEFS[self.inst.prefab] then
        return nil
    end
    self.inst.components.skilltreeupdater:AddSkillXP(xp)
end

function ModExperienceCollector:OnLoad(data)
    if data then
        self.fighting_xp = data.fighting_xp or 0
        self.bosses = data.bosses or bosses
    end
end

function ModExperienceCollector:OnSave()
    return {
        fighting_xp = self.fighting_xp,
        bosses = self.bosses,
    }
end

return ModExperienceCollector

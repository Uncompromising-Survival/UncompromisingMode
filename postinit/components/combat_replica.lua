local env = env
GLOBAL.setfenv(1, GLOBAL)

local function FindBeeQueen(inst)
    return inst.prefab == "beequeen"
end

local Combat = require("components/combat_replica")--postinits do not seem to work.

local _IsAlly = Combat.IsAlly
function Combat:IsAlly(guy, ...)
    if guy.prefab == "um_beeguard_blocker" and FindEntity(guy, 30, FindBeeQueen) then
        return true
    elseif guy.prefab == "ancient_trepidation" and ((self.inst.replica ~= nil and
        self.inst.replica.sanity:GetPercent() > 0.5 or
        self.inst.components.sanity ~= nil and self.inst.components.sanity:GetPercent() > 0.5) or not guy:HasTag("hostile")) then
        return true
    end

    return _IsAlly(self, guy, ...)
end

local env = env
GLOBAL.setfenv(1, GLOBAL)

local function FindBeeQueen(inst)
    return inst.prefab == "beequeen"
end

env.AddClassPostConstruct("components/combat_replica", function(self)
    local _IsAlly = self.IsAlly
    function self:IsAlly(guy, ...)
        if guy.prefab == "um_beeguard_blocker" and FindEntity(guy, 30, FindBeeQueen) then
            return true
        --elseif guy.prefab == "ancient_trepidation" and not guy:HasTag("hostile") then
        --    return true
        end
        if self.inst.UMIsAlly and self.inst:UMIsAlly(guy) then return true end
        return _IsAlly(self, guy, ...)
    end
end)
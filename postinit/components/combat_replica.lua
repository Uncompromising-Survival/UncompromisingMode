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
        local ret = _IsAlly(self, guy, ...)
        if not ret and self.inst.UMIsAlly and self.inst:UMIsAlly(guy) then return true end
        return ret
    end

    local _CanTarget = self.CanTarget
    function self:CanTarget(target, ...)
        if target and target:HasTag("um_slippery") and not self.inst.isplayer then return false end
        return _CanTarget(self, target, ...)
    end

    local _IsValidTarget = self.IsValidTarget
    function self:IsValidTarget(target, ...)
        if not target or target == self.inst or not (target.entity:IsValid() and target.entity:IsVisible()) then
            return _IsValidTarget(self, target, ...)
        end
        local follower = self.inst.replica.follower
        local leader = follower and follower:GetLeader()
        if leader and leader.replica.combat and target:HasAllTags("shadow", "fused_shadeling") and leader.replica.combat:IsValidTarget(target) then
            return true
        end
        return _IsValidTarget(self, target, ...)
    end

    --[[local _CanBeAttacked = self.CanBeAttacked
    function self:CanBeAttacked(attacker, ...)
        local follower = attacker and attacker.replica.follower
        local leader = follower and follower:GetLeader()
        return _CanBeAttacked(self, leader and self.inst:HasAnyTag("fused_shadeling") and leader or attacker, ...)
    end]]
end)
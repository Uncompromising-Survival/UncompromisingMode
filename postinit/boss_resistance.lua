local env = env
GLOBAL.setfenv(1, GLOBAL)

local function BossPlayerScan(bossmonster)
    local x, y, z = bossmonster.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 24, { "player" }, { "playerghost" })
    return #ents
end

env.AddComponentPostInit("combat", function(self)
    local _GetAttacked_Internal = self.GetAttacked_Internal
    function self:GetAttacked_Internal(attacker, damage, weapon, stimuli, spdamage, from_doattack, ...)
        local NearbyPlayers = BossPlayerScan(self.inst)
        if NearbyPlayers > 1 and table.contains(TUNING.DSTU.DYNRES_BOSSES, self.inst.prefab) then
            if NearbyPlayers >= 10 then NearbyPlayers = 10 end
            if damage then
                if UM_CONFIG.BOSS_RESISTANCE == "static" then
                    damage = damage * math.pow(.95, NearbyPlayers)
                elseif UM_CONFIG.BOSS_RESISTANCE == "dynamic" then
                    -- TODO: config options for numbers...
                    self.inst.damage_res = (self.inst.damage_res or 1) - .005
                    local old_damage = damage
                    damage = damage * self.inst.damage_res

                    local min_dmg = 1 - ((NearbyPlayers / 10) - .05)
                    if min_dmg <= .45 then min_dmg = .45 end

                    if damage < old_damage * min_dmg then
                        damage = old_damage * min_dmg
                    end
                end
            end
        end
        return _GetAttacked_Internal(self, attacker, damage, weapon, stimuli, spdamage, from_doattack, ...)
    end
end)

env.AddPrefabPostInitAny(function(inst)
    if inst:HasTag("epic") then
        inst:DoPeriodicTask(10, BossPlayerScan, 0, inst)

        inst.damage_res = 1
        inst:DoPeriodicTask(2.5, function(inst)
            inst.damage_res = inst.damage_res + 0.005 -- periodic damage res reduction
            if inst.damage_res > 1 then inst.damage_res = 1 end
        end)
    end
end)
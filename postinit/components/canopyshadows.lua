local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------
env.AddComponentPostInit("canopyshadows", function(self)
    local Canopyshadows = Global_Canopyshadows
    local _SpawnShadows = self.SpawnShadows
    function self:SpawnShadows(...)
        if self.um_canopyshadows then
            if self.spawned or not self.inst.entity:IsAwake() then return end

            for i, v in ipairs(self.canopy_positions) do
                local x, z = v[1], v[2]
                local shadetile = Canopyshadows[x.."-"..z]
                shadetile.spawnrefs = shadetile.spawnrefs + 1
                if shadetile.spawnrefs == 1 then
                    shadetile.id = SpawnHoodedforestCanopy(x, z)
                end
            end

            self.spawned = true
            return
        end
        return _SpawnShadows(self, ...)
    end

    local _DespawnShadows = self.DespawnShadows
    function self:DespawnShadows(ignore_entity_sleep, ...)
        if self.um_canopyshadows then
            if not self.spawned or (not ignore_entity_sleep and self.inst.entity:IsAwake()) then return end

            for i, v in ipairs(self.canopy_positions) do
                local x, z = v[1], v[2]
                local shadetile = Canopyshadows[x.."-"..z]
                shadetile.spawnrefs = shadetile.spawnrefs - 1
                if shadetile.spawnrefs == 0 then
                    DespawnHoodedforestCanopy(shadetile.id)
                    shadetile.id = nil
                end
            end

            self.spawned = false
            return
        end
        return _DespawnShadows(self, ignore_entity_sleep, ...)
    end
end)
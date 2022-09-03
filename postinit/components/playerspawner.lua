
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("playerspawner", function(self)
    function self:_ShouldEnableSpawnProtection(inst, player, x, y, z, isloading)
        if TheWorld.topology.overrides ~= nil and TheWorld.topology.overrides.spawnprotection == "never" then
            return false
        end
        return true
    end
end)
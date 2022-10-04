
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("playerspawner", function(self)
	local _SpawnAtLocation = self.SpawnAtLocation
	
	function self:SpawnAtLocation(inst, player, x, y, z, isloading, platform_uid, rx, ry, rz)
        if player:HasTag("troublemaker") and not isloading and TheSim:FindFirstEntityWithTag("wixie_wardrobe") ~= nil then
			player:DoStaticTaskInTime(6*FRAMES+FRAMES, function(inst)
				player:Hide()
			end)
            return _SpawnAtLocation(self, inst, player, x, y, z, true)
        else
            return _SpawnAtLocation(self, inst, player, x, y, z, true, platform_uid, rx, ry, rz)
		end
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
local easing = require("easing")
------------------------Fire spread is less efficient in winter-----------------------------------------
env.AddComponentPostInit("wateryprotection", function(self)

	local _SpreadProtectionAtPoint = self.SpreadProtectionAtPoint

	function self:SpreadProtectionAtPoint(x, y, z, dist, noextinguish)
		local ents = TheSim:FindEntities(x, y, z, dist or self.protection_dist or 4, {"um_washable_goo"})
		for i, v in ipairs(ents) do
			if v.prefab == "ratpoison" then
				v:Remove()
			elseif not (v.isfading and v._isfading:value()) then
				v.OnStartFade(v)
			end
		end
		_SpreadProtectionAtPoint(self, x, y, z, dist, noextinguish)
	end
end)
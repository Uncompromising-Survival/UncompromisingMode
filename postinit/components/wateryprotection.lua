local env = env
GLOBAL.setfenv(1, GLOBAL)
local easing = require("easing")
------------------------This allows items with wateryprotection to wash away UM Goo-----------------------------------------

local function OnStartFade(inst) -- Borrowed from Klei Honey Trail
    inst.AnimState:PlayAnimation(inst.trailname.."_pst")
    inst._isfading:set(true)
    inst.task:Cancel()
end

env.AddComponentPostInit("wateryprotection", function(self)
    local _SpreadProtectionAtPoint = self.SpreadProtectionAtPoint

    function self:SpreadProtectionAtPoint(x, y, z, dist, noextinguish)
        local ents = TheSim:FindEntities(x, y, z, dist or self.protection_dist or 4, {"um_washable_goo"})
        for i, v in ipairs(ents) do
            if v.prefab == "honey_trail" or v.prefab == "cherry_honey_trail" then
                OnStartFade(v)
            elseif v.prefab == "ratpoison" then
                v:Remove()
            elseif not (v._isfading and v._isfading:value()) and v.FadeAway then
                v:FadeAway(v)
            end
        end
        _SpreadProtectionAtPoint(self, x, y, z, dist, noextinguish)
    end
end)
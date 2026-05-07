local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMVetCurse = require("tools/um_vetcurseutility")
-----------------------------------------------------------------
env.AddComponentPostInit("seamlessplayerswapper", function(self)
    local _OnSeamlessCharacterSwap = self.OnSeamlessCharacterSwap
    function self:OnSeamlessCharacterSwap(old_player, ...)
        UMVetCurse.ApplyCurse(old_player, self.inst)
        local ret = _OnSeamlessCharacterSwap(self, old_player, ...)
        return ret
    end
end)
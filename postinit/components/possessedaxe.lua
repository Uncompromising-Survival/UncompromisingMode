local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("possessedaxe", function(self)

	local _IsValidOwner = UpvalueHacker.GetUpvalue(self.onplayerjoined,"IsValidOwner")
	
	local function IsValidOwner(inst, owner)
		return inst.prefab == "um_gemologyforge" or _IsValidOwner(inst,owner)
	end

	UpvalueHacker.SetUpvalue(self.onplayerjoined,IsValidOwner,"IsValidOwner")

end)
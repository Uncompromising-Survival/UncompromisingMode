local env = env
GLOBAL.setfenv(1, GLOBAL)

local UMUpvalueHacker = require("tools/um_upvaluehacker")

env.AddComponentPostInit("firedetector", function(self)
    local _NOTAGS  = UMUpvalueHacker.GetUpvalue(self.Activate, "LookForFiresAndFirestarters", "NOTAGS")
	
	if _NOTAGS ~= nil then
		table.insert(_NOTAGS, "campfire")
		table.insert(_NOTAGS, "NIGHTMARE_fueled")
	end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("possessedaxe", function(self)
	--AXE Leaving this postinit for the handle later


end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local Coach = require("components/coach")

UpvalueHacker.SetUpvalue(Coach.StartInspiring, 0, "inspire", "SANITY_BUFF")
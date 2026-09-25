local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local Coach = require("components/coach")

UMUpvalueHacker.SetUpvalue(Coach.StartInspiring, 0, "inspire", "SANITY_BUFF")
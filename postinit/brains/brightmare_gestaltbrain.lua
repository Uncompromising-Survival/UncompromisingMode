local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local GestaltBrain = require("brains/brightmare_gestaltbrain")

local SHADOW_TAGS = UpvalueHacker.GetUpvalue(GestaltBrain.OnStart, "SHADOW_TAGS")

if SHADOW_TAGS then
    table.insert(SHADOW_TAGS.oneoftags, "shadow_item")
    SHADOW_TAGS.seeequipped = true
end
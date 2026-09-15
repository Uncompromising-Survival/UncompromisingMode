local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local WalrusBrain = require("brains/walrusbrain")

local _GetNoLeaderLeashPos = UMUpvalueHacker.TryGetUpvalue(WalrusBrain.OnStart, "GetNoLeaderLeashPos")
if _GetNoLeaderLeashPos then
    local function GetNoLeaderLeashPos(inst, ...)
        local combat = inst.components.combat
        if combat and combat:HasTarget() then return false end
        return _GetNoLeaderLeashPos(inst, ...)
    end
    UMUpvalueHacker.SetUpvalue(WalrusBrain.OnStart, GetNoLeaderLeashPos, "GetNoLeaderLeashPos")
end
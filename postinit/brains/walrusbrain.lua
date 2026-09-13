local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local WalrusBrain = require("brains/walrusbrain")

local _GetNoLeaderLeashPos = UMUpvalueHacker.GetUpvalue(WalrusBrain.OnStart, "GetNoLeaderLeashPos")
local function GetNoLeaderLeashPos(inst, ...)
    local combat = inst.components.combat
    if combat and combat:HasTarget() then return false end
    return _GetNoLeaderLeashPos(inst, ...)
end

UMUpvalueHacker.SetUpvalue(WalrusBrain.OnStart, GetNoLeaderLeashPos, "GetNoLeaderLeashPos")
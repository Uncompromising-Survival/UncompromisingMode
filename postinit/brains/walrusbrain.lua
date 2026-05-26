local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local WalrusBrain = require("brains/walrusbrain")

local _GetNoLeaderLeashPos = UpvalueHacker.GetUpvalue(WalrusBrain.OnStart, "GetNoLeaderLeashPos")
local function GetNoLeaderLeashPos(inst, ...)
    local combat = inst.components.combat
    if combat and combat:HasTarget() then return false end
    return _GetNoLeaderLeashPos(inst, ...)
end

UpvalueHacker.SetUpvalue(WalrusBrain.OnStart, GetNoLeaderLeashPos, "GetNoLeaderLeashPos")
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")
local FireDetector = require("components/firedetector")

local _NOTAGS = UpvalueHacker.GetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "NOTAGS")
local NOTAGS = {"campfire", "NIGHTMARE_fueled", "noflingowash"}
for _, tag in pairs(NOTAGS) do
    table.insert(_NOTAGS, tag)
end

local _EMERGENCYTAGS = UpvalueHacker.GetUpvalue(FireDetector.ActivateEmergencyMode, "OnDetectEmergencyTargets", "EMERGENCYTAGS")
local _NONEMERGENCYTAGS = UpvalueHacker.GetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "NONEMERGENCYTAGS")
local TAGS = {"um_washable_goo"}

for _, tag in pairs(TAGS) do
    table.insert(_EMERGENCYTAGS, tag)
end

for _, tag in pairs(TAGS) do
    table.insert(_NONEMERGENCYTAGS, tag)
end

local _CheckTargetScore = UpvalueHacker.GetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "CheckTargetScore")
local function CheckTargetScore(target, ...)
    return target and target:HasTag("um_washable_goo") and 8 or _CheckTargetScore(target, ...)
end

UpvalueHacker.SetUpvalue(FireDetector.Activate, CheckTargetScore, "LookForFiresAndFirestarters", "CheckTargetScore")
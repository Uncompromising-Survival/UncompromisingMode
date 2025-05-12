local env = env
GLOBAL.setfenv(1, GLOBAL)

local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("firedetector", function(self)
    local _NOTAGS = UpvalueHacker.GetUpvalue(self.Activate, "LookForFiresAndFirestarters", "NOTAGS")
    local NOTAGS = {"campfire", "NIGHTMARE_fueled", "noflingowash"}

    if _NOTAGS then
        for _, tag in pairs(NOTAGS) do
            table.insert(_NOTAGS, tag)
        end
    end

    local _EMERGENCYTAGS = UpvalueHacker.GetUpvalue(self.ActivateEmergencyMode, "OnDetectEmergencyTargets", "EMERGENCYTAGS")
    local _NONEMERGENCYTAGS = UpvalueHacker.GetUpvalue(self.Activate, "LookForFiresAndFirestarters", "NONEMERGENCYTAGS")
    local TAGS = {"um_washable_goo"}

    if _EMERGENCYTAGS then
        for _, tag in pairs(TAGS) do
            table.insert(_EMERGENCYTAGS, tag)
        end
    end

    if _NONEMERGENCYTAGS then
        for _, tag in pairs(TAGS) do
            table.insert(_NONEMERGENCYTAGS, tag)
        end
    end

    local _CheckTargetScore = UpvalueHacker.GetUpvalue(self.Activate, "LookForFiresAndFirestarters", "CheckTargetScore")
    if _CheckTargetScore then
        local function CheckTargetScore(target, ...)
            return target and target:HasTag("um_washable_goo") and 8 or _CheckTargetScore(target, ...)
        end
        UpvalueHacker.SetUpvalue(self.Activate, CheckTargetScore, "LookForFiresAndFirestarters", "CheckTargetScore")
    end
end)
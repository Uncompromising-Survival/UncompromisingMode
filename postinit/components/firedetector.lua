local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local FireDetector = require("components/firedetector")

local _NOTAGS = UMUpvalueHacker.GetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "NOTAGS")
local NOTAGS = { "campfire", "NIGHTMARE_fueled", "noflingowash" }
for _, tag in pairs(NOTAGS) do
    table.insert(_NOTAGS, tag)
end

local _EMERGENCYTAGS = UMUpvalueHacker.GetUpvalue(FireDetector.ActivateEmergencyMode, "OnDetectEmergencyTargets", "EMERGENCYTAGS")
local _NONEMERGENCYTAGS = UMUpvalueHacker.GetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "NONEMERGENCYTAGS")
local TAGS = { "um_washable_goo", "magma_tile" }

for _, tag in pairs(TAGS) do
    table.insert(_EMERGENCYTAGS, tag)
end

for _, tag in pairs(TAGS) do
    table.insert(_NONEMERGENCYTAGS, tag)
end

local function CanCoolDownTile(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    if TheWorld.components.um_magmamanager ~= nil then
        local tile_data = TheWorld.components.um_magmamanager:GetTempTileDataAtPoint(x, y, z)
        if tile_data ~= nil then
            return tile_data.duration < TUNING.DSTU.MAGMATILE_REFRESH_THRESHOLD
        end

        if TheWorld.Map:GetTileAtPoint(x, y, z) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
            return true
        end
    end
    return false
end

local _CheckTargetScore = UMUpvalueHacker.TryGetUpvalue(FireDetector.Activate, "LookForFiresAndFirestarters", "CheckTargetScore")
if _CheckTargetScore then
    local function CheckTargetScore(target, ...)
        return target and target:HasTag("um_washable_goo") and 8
            or target and target:HasTag("magma_tile") and CanCoolDownTile(target) and 8
            or _CheckTargetScore(target, ...)
    end
    UMUpvalueHacker.SetUpvalue(FireDetector.Activate, CheckTargetScore, "LookForFiresAndFirestarters", "CheckTargetScore")
end

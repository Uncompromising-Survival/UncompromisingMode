local PortalGhostTeleport = {}

local RADIUS_MIN = 2
local RADIUS_MAX = 4
local MAX_POSITION_ATTEMPTS = 10
local _portals = {}

local function GetRandomNearbyPosition(portal)
    local x, y, z = portal.Transform:GetWorldPosition()
    for i = 1, MAX_POSITION_ATTEMPTS do
        local angle = math.random() * 2 * math.pi
        local dist  = RADIUS_MIN + math.random() * (RADIUS_MAX - RADIUS_MIN)
        local nx    = x + math.cos(angle) * dist
        local nz    = z + math.sin(angle) * dist
        if TheWorld.Map:IsPassableAtPoint(nx, 0, nz) then
            return nx, 0, nz
        end
    end
    return x, y, z
end

PortalGhostTeleport.GetRandomNearbyPosition = GetRandomNearbyPosition

function PortalGhostTeleport.SetupPortalListeners(portal)
    if _portals[portal] then return end
    _portals[portal] = portal.prefab
    portal:ListenForEvent("onremove", function()
        _portals[portal] = nil
    end)
end

function PortalGhostTeleport.GetPortal()
    for portal in pairs(_portals) do
        if portal:IsValid() then
            return portal
        end
        _portals[portal] = nil
    end
    return nil
end

function PortalGhostTeleport.GetPortalPrefab()
    for portal, prefab in pairs(_portals) do
        if portal:IsValid() then
            return prefab
        end
        _portals[portal] = nil
    end
    return nil
end

function PortalGhostTeleport.ScanExistingPortals()
    local found = TheSim:FindEntities(0, 0, 0, 50000, {"multiplayer_portal"})
    for _, portal in ipairs(found) do
        if portal:IsValid() and not _portals[portal] then
            PortalGhostTeleport.SetupPortalListeners(portal)
        end
    end
end

return PortalGhostTeleport

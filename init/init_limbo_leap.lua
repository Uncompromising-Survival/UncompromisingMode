local PortalGhostTeleport = require("um_portalteleport")
local _cached_portal = nil
local _portal_prefab = nil
local _recreate_button_fn = nil
local RPC_UsePortal
local RPC_RequestPortalInfo
local RPC_LimboLeapPortalInfo

local TELEPORT_DELAY = 2

local function GetPortalTextures()
    if _portal_prefab == "multiplayer_portal_moonrock" then
        return
            "images/limboleap/moonrock_portal_button_hover.xml",
            "moonrock_portal_button_hover.tex",
            "images/limboleap/moonrock_portal_button.xml",
            "moonrock_portal_button.tex"
    end
    return
        "images/limboleap/portal_button_hover.xml",
        "portal_button_hover.tex",
        "images/limboleap/portal_button.xml",
        "portal_button.tex"
end

local function SetPortalCache(inst)
    _cached_portal = inst
    _portal_prefab = inst.prefab
end

local function TryFindPortal()
    if _cached_portal and _cached_portal:IsValid() then return end
    local found = TheSim:FindEntities(0, 0, 0, 50000, {"multiplayer_portal"})
    if found[1] and found[1]:IsValid() then
        SetPortalCache(found[1])
    end
end

local function OnPortalPostInit(inst)
    SetPortalCache(inst)
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        if GLOBAL.TheNet:GetIsServer() then
            PortalGhostTeleport.SetupPortalListeners(inst)
        end
        if GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("playerghost") then
            if _recreate_button_fn then
                _recreate_button_fn()
            end
        end
    end)
end

local portals = {"multiplayer_portal", "multiplayer_portal_moonrock_constr", "multiplayer_portal_moonrock"}
for _, portal in ipairs(portals) do
    AddPrefabPostInit(portal, OnPortalPostInit)
end

AddPrefabPostInit("world", function(inst)
    if inst.ismastersim then
        inst:DoTaskInTime(0, function()
            PortalGhostTeleport.ScanExistingPortals()
        end)
    end
end)

AddModRPCHandler("UncompromisingSurvival", "RequestPortalInfo", function(player)
    if not (player and player:IsValid()) then return end
    local prefab = PortalGhostTeleport.GetPortalPrefab()
    if prefab then
        SendModRPCToClient(RPC_LimboLeapPortalInfo, player, prefab)
    end
end)

AddClientModRPCHandler("UncompromisingSurvival", "LimboLeapPortalInfo", function(prefab)
    _portal_prefab = prefab
    if GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("playerghost") and _recreate_button_fn then
        _recreate_button_fn()
    end
end)

AddModRPCHandler("UncompromisingSurvival", "UsePortal", function(player)
    if not (player and player:IsValid() and player:HasTag("playerghost") and player.sg and player.sg:HasAnyStateTag("moving", "idle")) then return end
    local target = PortalGhostTeleport.GetPortal()
    if target == nil then return end
    local nx, ny, nz = PortalGhostTeleport.GetRandomNearbyPosition(target)

    player.sg:GoToState("remoteresurrect")

    player:DoTaskInTime(TELEPORT_DELAY, function()
        if player:IsValid() and player:HasTag("playerghost") then
            player.Physics:Teleport(nx, ny, nz)
        end
    end)
end)

RPC_UsePortal = GetModRPC("UncompromisingSurvival", "UsePortal")
RPC_RequestPortalInfo = GetModRPC("UncompromisingSurvival", "RequestPortalInfo")
RPC_LimboLeapPortalInfo = GetClientModRPC("UncompromisingSurvival", "LimboLeapPortalInfo")

AddClassPostConstruct("widgets/statusdisplays", function(self)
    if not (GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD) then return end
    if GLOBAL.ThePlayer ~= self.owner then return end

    local ImageButton = require("widgets/imagebutton")
    local btn = nil

    local function DestroyButton()
        if btn then
            btn:Kill()
            btn = nil
        end
    end

    local function CreateButton()
        if not _portal_prefab then
            SendModRPCToServer(RPC_RequestPortalInfo)
            return
        end
        DestroyButton()

        local hover_atlas, hover_tex, normal_atlas, normal_tex = GetPortalTextures()

        btn = self:AddChild(ImageButton(hover_atlas, hover_tex))

        local _OnGainFocus = btn.OnGainFocus
        btn.OnGainFocus = function(s)
            _OnGainFocus(s)
            s.image:SetTexture(hover_atlas, hover_tex)
        end

        local _OnLoseFocus = btn.OnLoseFocus
        btn.OnLoseFocus = function(s)
            _OnLoseFocus(s)
            s.image:SetTexture(normal_atlas, normal_tex)
        end

        btn.image:SetTexture(normal_atlas, normal_tex)
        btn:SetScale(.75, .75, .75)
        btn:SetPosition(-90, 25)
        btn:SetTooltip("Limbo Leap")

        btn:SetOnClick(function()
            if GLOBAL.TheNet:IsServerPaused() then return end
            SendModRPCToServer(RPC_UsePortal)
        end)
    end

    _recreate_button_fn = CreateButton

    TryFindPortal()
    -- Always register the world-loaded listener so it fires after cave/surface migration
    self.inst:ListenForEvent("ms_worldhasloaded", function()
        TryFindPortal()
        if self.owner:HasTag("playerghost") then
            CreateButton()
        end
    end, GLOBAL.TheWorld)

    local _SetGhostMode = self.SetGhostMode
    self.SetGhostMode = function(s, ghostmode, ...)
        _SetGhostMode(s, ghostmode, ...)
        if ghostmode then
            CreateButton()
        else
            DestroyButton()
        end
    end

    if self.owner:HasTag("playerghost") then
        CreateButton()
    end
end)

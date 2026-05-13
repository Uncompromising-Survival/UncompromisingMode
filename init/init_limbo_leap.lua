local PortalGhostTeleport = require("um_portalteleport")
local _cached_portal = nil
local _portal_prefab = nil
local _recreate_button_fn = nil

local TELEPORT_DELAY = 2

print("[LimboLeap] init_limbo_leap.lua loaded")

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
    print("[LimboLeap] SetPortalCache - prefab:", inst.prefab)
    _cached_portal = inst
    _portal_prefab = inst.prefab
    inst:ListenForEvent("onremove", function()
        if _cached_portal == inst then
            _cached_portal = nil
            print("[LimboLeap] portal removed, _cached_portal cleared")
        end
    end)
end

local function TryFindPortal()
    if _portal_prefab then return end
    print("[LimboLeap] TryFindPortal - searching")
    local found = TheSim:FindEntities(0, 0, 0, 50000, {"multiplayer_portal"})
    print("[LimboLeap] TryFindPortal - count:", #found)
    if found[1] and found[1]:IsValid() then
        print("[LimboLeap] TryFindPortal - found:", found[1].prefab)
        SetPortalCache(found[1])
    else
        print("[LimboLeap] TryFindPortal - not found")
    end
end

local function OnPortalPostInit(inst)
    print("[LimboLeap] OnPortalPostInit - prefab:", inst.prefab)
    SetPortalCache(inst)
    inst:DoTaskInTime(0, function()
        if not inst:IsValid() then return end
        print("[LimboLeap] OnPortalPostInit deferred - IsServer:", GLOBAL.TheNet:GetIsServer())
        if GLOBAL.TheNet:GetIsServer() then
            PortalGhostTeleport.SetupPortalListeners(inst)
        end
        if GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("playerghost") then
            print("[LimboLeap] OnPortalPostInit deferred - player is ghost, calling recreate")
            if _recreate_button_fn then
                _recreate_button_fn()
            else
                print("[LimboLeap] OnPortalPostInit deferred - _recreate_button_fn is nil!")
            end
        end
    end)
end

local portals = {"multiplayer_portal", "multiplayer_portal_moonrock_constr", "multiplayer_portal_moonrock"}
for _, portal in ipairs(portals) do
    AddPrefabPostInit(portal, OnPortalPostInit)
end

AddPrefabPostInit("world", function(inst)
    print("[LimboLeap] world PostInit - ismastersim:", inst.ismastersim)
    if inst.ismastersim then
        inst:DoTaskInTime(0, function()
            PortalGhostTeleport.ScanExistingPortals()
        end)
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

local RPC_UsePortal = GetModRPC("UncompromisingSurvival", "UsePortal")

AddClassPostConstruct("widgets/statusdisplays", function(self)
    print("[LimboLeap] AddClassPostConstruct statusdisplays fired")
    print("[LimboLeap] ThePlayer:", GLOBAL.ThePlayer, "HUD:", GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD)
    if not (GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD) then
        print("[LimboLeap] ABORT: no ThePlayer or HUD")
        return
    end
    print("[LimboLeap] self.owner:", self.owner, "ThePlayer:", GLOBAL.ThePlayer)
    if GLOBAL.ThePlayer ~= self.owner then
        print("[LimboLeap] ABORT: owner mismatch")
        return
    end

    local ImageButton = require("widgets/imagebutton")
    local btn = nil

    local function DestroyButton()
        if btn then
            print("[LimboLeap] DestroyButton")
            btn:Kill()
            btn = nil
        end
    end

    local function CreateButton()
        print("[LimboLeap] CreateButton - _portal_prefab:", _portal_prefab)
        if not _portal_prefab then
            print("[LimboLeap] CreateButton ABORT: _portal_prefab nil")
            return
        end
        DestroyButton()

        local hover_atlas, hover_tex, normal_atlas, normal_tex = GetPortalTextures()
        print("[LimboLeap] CreateButton - atlases:", hover_atlas, normal_atlas)

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

        print("[LimboLeap] CreateButton OK")
    end

    _recreate_button_fn = CreateButton

    TryFindPortal()
    if not _portal_prefab then
        print("[LimboLeap] portal not found yet, listening for ms_worldhasloaded")
        self.inst:ListenForEvent("ms_worldhasloaded", function()
            print("[LimboLeap] ms_worldhasloaded fired")
            TryFindPortal()
            if _portal_prefab and self.owner:HasTag("playerghost") then
                print("[LimboLeap] ms_worldhasloaded - player is ghost, creating button")
                CreateButton()
            end
        end, GLOBAL.TheWorld)
    end

    local _SetGhostMode = self.SetGhostMode
    self.SetGhostMode = function(s, ghostmode, ...)
        print("[LimboLeap] SetGhostMode - ghostmode:", ghostmode, "_portal_prefab:", _portal_prefab)
        _SetGhostMode(s, ghostmode, ...)
        if ghostmode then
            CreateButton()
        else
            DestroyButton()
        end
    end

    if self.owner:HasTag("playerghost") then
        print("[LimboLeap] owner already ghost at init, creating button")
        CreateButton()
    end
end)

local require = GLOBAL.require

local function MiniBlizzNear(inst)
    if TheSim then
        local x, y, z = inst.Transform:GetWorldPosition()
        local miniblizzards = TheSim:FindEntities(x, y, z, 32, {"miniblizzard"})
        if #miniblizzards > 0 then
            return true
        end
    end
end

local function GetSnowstormLevel(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if GLOBAL.TheWorld.state.iswinter and (GLOBAL.TheWorld.net and GLOBAL.TheWorld.net:HasTag("snowstormstartnet") or GLOBAL.TheWorld:HasTag("snowstormstart") or MiniBlizzNear(inst)) and not GLOBAL.IsUnderRainDomeAtXZ(x, z) then
        return 1
    else
        return 0
    end
end

local function SetInstanceFunctions2(inst)
    inst.GetSnowstormLevel = GetSnowstormLevel
end

AddPlayerPostInit(function(inst)
    SetInstanceFunctions2(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:AddComponent("snowstormwatcher")
end)

local overlaystosort = {"um_heatwaveover", "snowover", "snowdustover", "um_stormover", "raindomeover", "leafcanopy", "drops_vig", "vig"} 
local function SortOverlays(self)
    for _, overlay in pairs(overlaystosort) do
        if self[overlay] then
            self[overlay]:MoveToBack()
        end
    end
end

AddClassPostConstruct("screens/playerhud", function(inst)
    local SnowOver = require("widgets/snowover")
    local SnowDustOver = require("widgets/sanddustover")
    local Um_StormOver = require("widgets/um_stormover")
    local HeatwaveOver = require("widgets/heatwaveover")

    local fn = inst.CreateOverlays
    function inst:CreateOverlays(owner)
        fn(self, owner)
        self.um_stormover = self.overlayroot:AddChild(Um_StormOver(owner))
        self.snowdustover = self.storm_overlays:AddChild(SnowDustOver(owner))
        self.snowover = self.overlayroot:AddChild(SnowOver(owner, self.snowdustover))
        self.um_heatwaveover = self.overlayroot:AddChild(HeatwaveOver(owner))
        SortOverlays(self)
    end
end)

local function OnSpy(inst)
    --inst._parent.HUD.snowover:SnowOn()
    if inst._parent then
        inst._parent:PushEvent("snowover", {enabled = inst.snowover:value()})
    end
end

--[[local function OffSpy(inst)
    if inst._parent then
        --ThePlayer.HUD.snowover:Show()
        inst._parent.HUD.snowover:SnowOn()
    end
end]]

AddPrefabPostInit("player_classified", function(inst)
    inst.snowover = GLOBAL.net_bool(inst.GUID, "snow.snowover", "snowdirty")
    inst:ListenForEvent("snowdirty", OnSpy)
end)
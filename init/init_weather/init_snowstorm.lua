local require = GLOBAL.require

local function MiniBlizzNear(inst)
    if TheSim then
        local x, y, z = inst.Transform:GetWorldPosition()
        local miniblizzards = TheSim:FindEntities(x, y, z, 24, {"miniblizzard"})
        if #miniblizzards > 0 then
            return true
        end
    end
end

local function GetSandstormLevel(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if TheSim then
        local ents = TheSim:FindEntities(x, y, z, 4, {"wall"})
        local suppressorNearby1 = (#ents > 2)

        local ents2 = TheSim:FindEntities(x, y, z, 6, {"fire"})
        local suppressorNearby2 = (#ents2 > 0)

        local ents3 = TheSim:FindEntities(x, y, z, 5.5, {"shelter"})
        local suppressorNearby3 = (#ents3 > 2)

        local ents4 = TheSim:FindEntities(x, y, z, 6, {"snowstorm_protection_high"})
        local suppressorNearby4 = (#ents4 > 0)
        --[[else
    
        local ents = TheSim:FindEntities(x, y, z, 4, {"wall"})
        local suppressorNearby1 = 0
        
        local ents2 = TheSim:FindEntities(x, y, z, 6, {"fire"})
        local suppressorNearby2 = 0
        
        local ents3 = TheSim:FindEntities(x, y, z, 5.5, {"shelter"})
        local suppressorNearby3 = 0
    --]]
    end

    if GLOBAL.TheWorld.state.iswinter and not suppressorNearby1 and not suppressorNearby2 and not suppressorNearby3 and not suppressorNearby4 and (GLOBAL.TheWorld:HasTag("snowstormstart") or (GLOBAL.TheWorld.net and GLOBAL.TheWorld.net:HasTag("snowstormstartnet")) or MiniBlizzNear(inst)) then
        return 1
    else
        return inst.player_classified and inst.player_classified.stormlevel:value() / 7 or 0
    end
end

local function SetInstanceFunctions2(inst)
    inst.GetSandstormLevel = GetSandstormLevel
end

AddPlayerPostInit(function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:AddComponent("snowstormwatcher")

    SetInstanceFunctions2(inst)
end)

local overlaystosort = {"um_heatwaveover", "snowover", "snowdustover", "um_stormover", "sanddustover", "storm_overlays", "storm_root", "raindomeover", "leafcanopy", "drops_vig", "vig"} 
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
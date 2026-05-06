local env = env
GLOBAL.setfenv(1, GLOBAL)

local myself


env.AddClassPostConstruct("widgets/inspirationbadge", function(self, owner, colour)
    local _UpdateState = self.UpdateState
    self.owner = owner
    myself = self

    function self:OnUpdate(dt)
        if TheNet:IsServerPaused() then return end
        
        --[[
        local shadowDrainMult = 1
        local lunarDrainMult = 1

        if self.owner:HasTag("player_shadow_aligned") then
            shadowDrainMult = TUNING.DSTU.WATHGRITHR_SHADOW_INSPIRATION_DRAIN_MULT
            if self.active == true then self:Hide() end
        else
        if self.owner:HasTag("player_lunar_aligned") then
            lunarDrainMult = TUNING.DSTU.WATHGRITHR_LUNAR_INSPIRATION_DRAIN_MULT
        end

        local percent = math.max(0, self.percent + dt * TUNING.INSPIRATION_DRAIN_RATE * shadowDrainMult * lunarDrainMult * 0.98 / 100) -- just go a little bit slower than the server so there will be less jumping backwards in the meter
        self:SetPercent(percent)]]
    end
end)

env.AddClassPostConstruct("widgets/statusdisplays", function(self)
    -- Hide hunger meter

    local function ToggleInspirationBadge(visible) 
        if self.inspirationbadge then
            if visible then
                self.inspirationbadge:Show()
            else 
                self.inspirationbadge:Hide()
            end
        end
        print("badge event received, visible: ", visible)
    end

    self.inst:DoTaskInTime(0, function()
        if ThePlayer then
            --ThePlayer:ListenForEvent("UM_ToggleInspirationBadge", ToggleInspirationBadge)
            ThePlayer:ListenForEvent("UM_ShowInspirationBadge", function() ToggleInspirationBadge(true) end)
            ThePlayer:ListenForEvent("UM_HideInspirationBadge", function() ToggleInspirationBadge(false) end)
        end
    end)

end)

--AddClientModRPCHandler("InspirationBadgeRPC", "HideBadge", function() myself:Hide() end)
--AddClientModRPCHandler("InspirationBadgeRPC", "ShowBadge", function() myself:Show() end)
--[[
local function PushBadgeToggleEvent(inst, displayBadge)
    print("badgeRPC received. displayBadge", displayBadge, inst)
    -- This runs on the client
    local player = ThePlayer
    if player ~= nil then
        print("badge event pushed")
        player:PushEvent("UM_ToggleInspirationBadge", { visible = displayBadge })
    end
end]]


-- I have to do this shit because I can't manage to pass variables on RPCs
-- Someone please fix this

--AddClientModRPCHandler("UncompromisingSurvival", "ToggleInspirationBadge", PushBadgeToggleEvent)
AddClientModRPCHandler("UncompromisingSurvival", "ShowInspirationBadge", function()
    local player = ThePlayer
    if player ~= nil then
        player:PushEvent("UM_ShowInspirationBadge")
    end
end)

AddClientModRPCHandler("UncompromisingSurvival", "HideInspirationBadge", function()
    local player = ThePlayer
    if player ~= nil then
        player:PushEvent("UM_HideInspirationBadge")
    end
end)
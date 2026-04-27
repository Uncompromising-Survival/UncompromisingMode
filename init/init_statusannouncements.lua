local PlayerHud = GLOBAL.require("screens/playerhud")
local TUNING = GLOBAL.TUNING
--[[local _PlayerHudSetMainCharacter = PlayerHud.SetMainCharacter

function PlayerHud:SetMainCharacter(maincharacter, ...)
    local ret = _PlayerHudSetMainCharacter(self, maincharacter, ...)

    self.inst:DoTaskInTime(1, function()
        if self._StatusAnnouncer == nil then return end
        print("works yknow")
        self._StatusAnnouncer:RegisterInterceptor(modname, "STAT", function(announce_str, data)
            print("heyy")
            return string.gsub(announce_str, "sanity", "eyeball") --Lunacy
        end)
    end)

    return ret
end]]

local function AddStatAnnouncements(statusAnnouncer, statName, badge, currentMaxFn)
    -- This shouldn't really ever be nil with status announcements installed.
    -- Some people crash without this line however: might be something to do with mod priority.
    if statusAnnouncer.RegisterStat == nil then return end
    statusAnnouncer:RegisterStat(
        statName,
        badge,
        CONTROL_ROTATE_LEFT,
        { .15, .35, .55, .75 },
        { "EMPTY", "LOW", "MID", "HIGH", "FULL" },
        currentMaxFn,
        nil
    )
end

local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
function PlayerHud:SetMainCharacter(maincharacter, ...)
    local ret = PlayerHud_SetMainCharacter(self, maincharacter, ...)
    self.inst:DoTaskInTime(0, function()
        if not self._StatusAnnouncer then return end
        if ThePlayer.prefab == "wathom" then
            AddStatAnnouncements(self._StatusAnnouncer, "Adrenaline", self.controls.status.adrenaline,
                function(ThePlayer)
                    return ThePlayer.counter_current and ThePlayer.counter_current:value(), -- Adrenaline replica's GetCurrent() just returns 100. What.
                        ThePlayer.counter_max:value()
                end)
        elseif ThePlayer.prefab == "walter" then
            -- WOBY_HUNGER changed to just WOBY in the quotes, otherwise we'll announce the underscore (Woby_Hunger: 25/100 ...)
            AddStatAnnouncements(self._StatusAnnouncer, "Woby", self.controls.status.WobyHungerDisplay,
                function(ThePlayer)
                    return ThePlayer.player_classified.WobyHunger and ThePlayer.player_classified.WobyHunger:value(),
                        TUNING.WOBY_BIG_HUNGER -- I couldn't find a get max fn anywhere. Is this the right one? Both big and small have the same value.
                end)
        end
    end)
    return ret
end
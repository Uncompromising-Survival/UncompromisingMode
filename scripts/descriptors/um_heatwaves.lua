local function Describe(self, context)
    local description = nil
    local _worldsettingstimer = TheWorld.components.worldsettingstimer

    local timeleft = _worldsettingstimer:TimerExists("um_stopheatwave_timer") and TheWorld:HasTag("heatwavestart") and _worldsettingstimer:GetTimeLeft("um_stopheatwave_timer")
        or _worldsettingstimer:TimerExists("um_stopheatwave_timer") and _worldsettingstimer:GetTimeLeft("um_heatwave_timer") or nil

    if timeleft then
        timeleft = context.time:SimpleProcess(timeleft)

        if _worldsettingstimer:TimerExists("um_stopheatwave_timer") and TheWorld:HasTag("heatwavestart") then
            description = "Heat Wave will stop in " .. timeleft
        elseif _worldsettingstimer:TimerExists("um_heatwave_timer") then
            description = "Heat Wave will start in " .. timeleft
        end
    end

    return {
        priority = 0,
        description = description,
        append = true,
        icon = {
            atlas = "images/crafting_menu_icons.xml",
            tex = "filter_summer.tex",
        },

    }
end

return {
    Describe = Describe
}

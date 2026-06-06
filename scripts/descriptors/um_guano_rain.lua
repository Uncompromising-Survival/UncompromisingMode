local function Describe(self, context)
    local description = nil

    local timeleft = TheWorld.components.timer:GetTimeLeft("begin_guano_rain") and TheWorld.components.timer:GetTimeLeft("begin_guano_rain")
    or TheWorld.components.timer:TimerExists("end_guano_rain") and TheWorld.components.timer:GetTimeLeft("end_guano_rain")

    timeleft = context.time:SimpleProcess(timeleft)

    if TheWorld.components.timer:TimerExists("begin_guano_rain") then
        description = "Guano rain will start in " .. timeleft
    elseif TheWorld.components.timer:TimerExists("end_guano_rain") then
        description = "Guano rain will end in " .. timeleft
    end

    return {
        priority = 0,
        description = description,
        append = true,
        icon = {
            atlas = "images/um_guano_rain_icon.xml",
            tex = "um_guano_rain_icon.tex",
        },

    }
end

return {
    Describe = Describe
}

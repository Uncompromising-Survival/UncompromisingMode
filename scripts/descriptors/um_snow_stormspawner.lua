local function Describe(self, context)
    local description = nil
    local _worldsettingstimer = TheWorld.components.worldsettingstimer

    local timeleft = _worldsettingstimer:TimerExists("um_stopsnowstorm_timer") and TheWorld:HasTag("snowstormstart") and _worldsettingstimer:GetTimeLeft("um_stopsnowstorm_timer")
        or _worldsettingstimer:TimerExists("um_snowstorm_timer") and _worldsettingstimer:GetTimeLeft("um_snowstorm_timer") or nil

    if timeleft then
        timeleft = context.time:SimpleProcess(timeleft)

        if _worldsettingstimer:TimerExists("um_stopsnowstorm_timer") and TheWorld:HasTag("snowstormstart") then
            description = "Snow Storm will stop in " .. timeleft
        elseif _worldsettingstimer:TimerExists("um_snowstorm_timer") then
            description = "Snow Storm will start in " .. timeleft
        end

        local rimeweed_timerleft = _worldsettingstimer:TimerExists("um_rimeweed_timer") and _worldsettingstimer:GetTimeLeft("um_rimeweed_timer") or nil

        if rimeweed_timerleft then
            local rimeweed_text = "\n<prefab=rimeweed_main> will attempt a spawn in %s"
            rimeweed_text = string.format(
                Insight.env.ProcessRichTextPlainly(rimeweed_text),
                context.time:SimpleProcess(rimeweed_timerleft)
            )

            description = description .. rimeweed_text
        end
    end


    return {
        priority = 0,
        description = description,
        append = true,
        icon = {
            atlas = "images/crafting_menu_icons.xml",
            tex = "filter_winter.tex",
        },
    }
end

return {
    Describe = Describe
}

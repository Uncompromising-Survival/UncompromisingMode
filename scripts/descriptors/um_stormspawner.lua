local function Describe(self, context)
    local description = nil
    local _worldsettingstimer = TheWorld.components.worldsettingstimer

    local timeleft = _worldsettingstimer:TimerExists("um_storm_timer") and _worldsettingstimer:GetTimeLeft("um_storm_timer") or nil
    local tornado = TheSim:FindFirstEntityWithTag("um_tornado")

    if timeleft and tornado == nil then
        timeleft = context.time:SimpleProcess(timeleft)
        description = "Tornado will spawn in " .. timeleft
    end

    if tornado ~= nil then
        local x, y, z = tornado.Transform:GetWorldPosition()
        description = "Tornado is " .. math.floor(math.sqrt(TheWorld:GetDistanceSqToPoint(x, y, z))) .. " units away."
    end

    return {
        priority = 0,
        description = description,
        append = true,
        icon = {
            atlas = "images/um_tornado_icon.xml",
            tex = "um_tornado_icon.tex",
        },

    }
end

return {
    Describe = Describe
}

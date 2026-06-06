--[[
-Code courtesy of penguin0616. Most belongs to Insight.
Adapted for uncompromising mode.
]]

local function GetRespawnData(inst)
    local widow_timer = nil
    local is_reroll = false

    if inst.components.timer:TimerExists("regen_widow") then
        widow_timer = inst.components.timer:GetTimeLeft("regen_widow")
    elseif inst.components.timer:TimerExists("reroll_cocoons") then
        widow_timer = inst.components.timer:GetTimeLeft("reroll_cocoons")
        is_reroll = true
    end

    return {
        time_to_respawn = widow_timer,
        is_reroll = is_reroll
    }
end

local function RemoteDescribe(data, context)
    if not data or not data.time_to_respawn then
        return
    end

    if data.time_to_respawn >= 0 then
        local description = context.time:SimpleProcess(data.time_to_respawn)
        return {
            description = description,
            icon = {
                atlas = "images/widowweb_icon.xml",
                tex = data.is_reroll and "cocoon.tex" or "widow.tex",
            },
            worldly = true,
            prefably = true,
            from = "prefab",
            time_to_respawn = data.time_to_respawn,
        }
    end
    return nil
end

local function StatusAnnouncementsDescribe(special_data, context)
    if not special_data.time_to_respawn then
        return
    end

    local text = "<prefab=webbedcreature>s will reroll/<prefab=hoodedwidow> will spawn in %s"

    local description = string.format(
        Insight.env.ProcessRichTextPlainly(text),
        context.time:TryStatusAnnouncementsTime(special_data.time_to_respawn)
    )

    return {
        description = description,
        append = true
    }
end

return {
    GetRespawnData = GetRespawnData,
    RemoteDescribe = RemoteDescribe,
    StatusAnnouncementsDescribe = StatusAnnouncementsDescribe
}

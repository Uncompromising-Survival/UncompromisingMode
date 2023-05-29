local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")


--thanks korean!
env.AddComponentPostInit("wildfires", function(self)
    local _ShouldActivateWildfires
    local _ms_startwildfireforplayerfn
    local inst = self.inst
    -- simplify the for loop by adding [inst] to the end
    for k, func in pairs(inst.event_listening["ms_lightwildfireforplayer"][inst]) do
        -- check that the upvalue we want to grab is the correct one (i.e the function ShouldActivateWildfires)
        if UpvalueHacker.GetUpvalue(func, "ShouldActivateWildfires") then
            _ms_startwildfireforplayerfn = func
            _ShouldActivateWildfires = UpvalueHacker.GetUpvalue(func, "ShouldActivateWildfires")
            -- we can break out of the loop now since we found the upvalue we wanted
            break
        end
    end
    local ShouldActivateWildfires = function()
        return _ShouldActivateWildfires() and TheWorld:HasTag("heatwavestart")
    end
    UpvalueHacker.SetUpvalue(_ms_startwildfireforplayerfn, ShouldActivateWildfires, "ShouldActivateWildfires")
end)

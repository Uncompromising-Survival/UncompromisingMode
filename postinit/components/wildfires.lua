local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")

--why was this a postconstruct?? -A
env.AddComponentPostInit("wildfires", function(self)
    local _ms_startwildfireforplayerfn
    for k, v in pairs(self.inst.event_listening["ms_lightwildfireforplayer"]) do
        for _k, _v in pairs(self.inst.event_listening["ms_lightwildfireforplayer"][k]) do
            print(_v)
            _ms_startwildfireforplayerfn = _v
        end
    end

    local ShouldActivateWildfires = function()
        return --[[_ShouldActivateWildfires() or]] TheWorld:HasTag("heatwavestart")
    end

    UpvalueHacker.SetUpvalue(_ms_startwildfireforplayerfn, ShouldActivateWildfires,
        "ShouldActivateWildfires")
    local _excludetags = UpvalueHacker.GetUpvalue(_ms_startwildfireforplayerfn, "LightFireForPlayer", "_excludetags")
    --local _radius      = UpvalueHacker.GetUpvalue(_ms_startwildfireforplayerfn, "LightFireForPlayer", "_radius")
    table.insert(_excludetags, "structure")
    --UpvalueHacker.SetUpvalue(_ms_startwildfireforplayerfn, _radius + 75, "LightFireForPlayer", "_radius")
    --TODO: Rework this into a heat wave that goes across the map!!
    _radius = UpvalueHacker.GetUpvalue(_ms_startwildfireforplayerfn, "LightFireForPlayer", "_radius")
end)

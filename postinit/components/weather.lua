local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
env.AddComponentPostInit("weather", function(self)
    local _OnUpdate = self.OnUpdate
    local _rainfx
    local _snowfx
    local _pollenfx
    local _hasfx = not TheNet:IsDedicated()

    for i, v in pairs(Ents) do
        if v.prefab then
            if v.prefab == "rain" then
                _rainfx = v
            elseif v.prefab == "snow" then
                _snowfx = v
            elseif v.prefab == "pollen" then
                _pollenfx = v
            end
        end
    end

    function self:OnUpdate(dt)
        _OnUpdate(self, dt)
        if TheWorld.state.issummer and TheWorld.net:HasTag("heatwavestartnet") then
            if _hasfx then
                _pollenfx.particles_per_tick = _pollenfx.particles_per_tick * 1000 + 1 --MOREEEEEEEEEEEEEEEE
            end
        end
    end
end)

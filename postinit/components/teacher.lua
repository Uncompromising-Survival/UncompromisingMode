local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("teacher", function (self)
    local _Teach = self.Teach
    function self:Teach(target, ...)
        local _Remove
        if self.recipe then
            _Remove = self.inst.Remove
            self.inst.Remove = function() end
        end
        local ret = {_Teach(self, target, ...)}
        if _Remove then self.inst.Remove = _Remove end
        return unpack(ret)
    end
end)
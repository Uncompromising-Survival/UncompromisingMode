local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local Sheltered = require("components/sheltered")
local _OnUpdate = Sheltered.OnUpdate
function Sheltered:OnUpdate(dt, ...)
    local canopytrees = self.inst.canopytrees
    if self.inst.um_gianttrees and self.inst.um_gianttrees > 0 and not (canopytrees and canopytrees > 0) then
        self.inst.canopytrees = 1
    end
    local ret = _OnUpdate(self, dt, ...)
    if canopytrees or not canopytrees and self.inst.canopytrees then self.inst.canopytrees = canopytrees end
    return ret
end
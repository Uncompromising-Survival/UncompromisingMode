local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")
local DragonflyBrain = require("brains/dragonflybrain")

local _ShouldSpawnFn = UMUpvalueHacker.GetUpvalue(DragonflyBrain.OnStart, "ShouldSpawnFn")
if _ShouldSpawnFn then
    local function ShouldSpawnFn(self, ...)
        local ret = _ShouldSpawnFn(self, ...)
        if ret then
            if self.inst.sg:HasAnyStateTag("grounded", "busy") and not self.inst.sg:HasStateTag("hit") then
                self.inst.components.stuckdetection:Reset()
            elseif self.inst.components.stuckdetection:IsStuck() then
                self._spawnpos = self.inst:GetPosition()
            end
        end
        return ret
    end
    UMUpvalueHacker.SetUpvalue(DragonflyBrain.OnStart, ShouldSpawnFn, "ShouldSpawnFn")
end
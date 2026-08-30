local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------Fire spread is less efficient in winter-----------------------------------------
local function PreventAllyFireDamage(ret, inst)
    for i = #ret, 1, -1 do
        local v = ret[i]
        if v:IsValid() and v.components.propagator and v.components.health
            and v.components.health.vulnerabletoheatdamage ~= false and not UMCommonFns.IsNotFriendly(inst, v) then
            table.remove(ret, i)
        end
    end
    return ret
end

env.AddComponentPostInit("propagator", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local damager = self.inst.damager and self.inst.damager:IsValid() and self.inst.damager
        if damager and self.spreading and self.damages then
            UMSimTempOverride.data = {fn = PreventAllyFireDamage, inst = damager}
        end
        local propagaterange_damagerange
        if TheWorld.state.iswinter and not self.inst.sg then
            propagaterange_damagerange = {propagaterange = self.propagaterange, damagerange = self.damagerange}
            self.propagaterange = self.propagaterange * TUNING.DSTU.WINTER_FIRE_MOD
            self.damagerange = self.damagerange * TUNING.DSTU.WINTER_FIRE_MOD
        end
        local ret = _OnUpdate(self, dt, ...)
        if propagaterange_damagerange then
            self.propagaterange = propagaterange_damagerange.propagaterange
            self.damagerange = propagaterange_damagerange.damagerange
        end
        if UMSimTempOverride.data then UMSimTempOverride.data = nil end
        return ret
    end
end)
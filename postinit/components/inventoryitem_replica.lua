local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddClassPostConstruct("components/inventoryitem_replica", function(self, inst)
    local _SetPickupPos = self.SetPickupPos
    function self:SetPickupPos(pos, ...)
        if self.classified then
            _SetPickupPos(self, pos, ...) --fuckin' hell Klei, please add more checks.
        end
    end

    local _CanBePickedUp = self.CanBePickedUp
    function self:CanBePickedUp(doer, ...)
        if self.inst.um_no_pickup and doer and doer:HasTag("player") then return false end
        return _CanBePickedUp(self, doer, ...)
    end
end)
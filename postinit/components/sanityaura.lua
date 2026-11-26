local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("sanityaura", function(self)
    local _GetAura = self.GetAura
    function self:GetAura(observer)
        local aura_val = _GetAura(self,observer)

        if observer and observer.components.inventory then
            local item = observer.components.inventory:FindItem(function(item) return item.um_pocket_sanity_res end)
            if item then
                aura_val = aura_val * item.um_pocket_sanity_res
            end
        end

        return aura_val
    end
end)

local env = env
GLOBAL.setfenv(1, GLOBAL)

-- This is an attempt at manually fixing an issue when people are checked for insulation
-- scrimbles

env.AddComponentPostInit("inventory", function(self)
	local _OldIsInsulated = self.IsInsulated

	function self:IsInsulated()
		if self.isexternallyinsulated == nil or self.isexternallyinsulated:Get() == nil then
			for k,v in pairs(self.equipslots) do
				if v and v.components.equippable:IsInsulated() then
					return true
				end
			end
		else
			return _OldIsInsulated(self)
		end
	end

	local _EquipHasTag = self.EquipHasTag
    function self:EquipHasTag(tag, ...)
        if self.inst.components.skilltreeupdater and self.inst.components.skilltreeupdater:IsActivated("wathom_allegiance_neutral") and tag == "ancient_reader" then return true end
        return _EquipHasTag(self, tag, ...)
    end
end)

env.AddClassPostConstruct("components/inventory_replica", function(self)
    local _EquipHasTag = self.EquipHasTag
    function self:EquipHasTag(tag, ...)
        if self.inst.components.skilltreeupdater and self.inst.components.skilltreeupdater:IsActivated("wathom_allegiance_neutral") and tag == "ancient_reader" then return true end
        return _EquipHasTag(self, tag, ...)
    end
end)
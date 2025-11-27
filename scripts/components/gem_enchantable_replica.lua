local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = require("gemology_defs")

local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    self._enchants = net_smallbytearray(inst.GUID, "gemology.enchants", "gemology.onenchantsdirty")
end)

function GemEnchantable:SetEnchantments(enchants)
    self._enchants:set(enchants)
end

function GemEnchantable:SetEnchantmentsFromNames(enchant_names)
    local enchants = {}
    for k, v in pairs(enchant_names) do
        table.insert(enchants, GEM_LOOKUP[v])
    end

    self.SetEnchants(enchants)
end

function GemEnchantable:GetEnchantments()
    return self._enchants:value()
end

function GemEnchantable:GetEnchantmentNames()
    local enchants = self:GetEnchantments()
    local names = {}
    for k, v in pairs(enchants) do
        names[k] = INVERTED_GEM_LOOKUP[v]
    end
    return names
end

return GemEnchantable

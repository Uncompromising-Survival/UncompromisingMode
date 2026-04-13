local DEFS = require("gemology_defs")
local GEM_LOOKUP, INVERTED_GEM_LOOKUP = DEFS.GEM_LOOKUP, DEFS.INVERTED_GEM_LOOKUP


local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    self._enchants = net_smallbytearray(inst.GUID, "gemology.enchants", "gemology.onenchantsdirty")
    self._slots = net_int(inst.GUID, "gemology.slots", "gemology.onslotsdirty")
end)

function GemEnchantable:SetEnchantments(enchants)
    self._enchants:set(enchants)
end

function GemEnchantable:SetEnchantmentsFromNames(enchant_names)
    local _enchants = {}
    for _, enchant in ipairs(enchant_names) do
        table.insert(_enchants, INVERTED_GEM_LOOKUP[enchant])
    end
    self:SetEnchantments(_enchants)
end

function GemEnchantable:GetEnchantments()
    return self._enchants:value()
end

function GemEnchantable:GetEnchantmentNames()
    local enchants = self:GetEnchantments()
    local names = {}

    for k, v in pairs(enchants) do
        table.insert(names, GEM_LOOKUP[v])
    end

    return names
end

return GemEnchantable

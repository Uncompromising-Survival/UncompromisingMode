local DEFS = require("gemology_defs")
local GEM_LOOKUP, INVERTED_GEM_LOOKUP = DEFS.GEM_LOOKUP, DEFS.INVERTED_GEM_LOOKUP


local GemEnchantable = Class(function(self, inst)
    self.inst = inst

    self._enchant_data = net_string(inst.GUID, "gemology.enchant_data", "gemology.enchant_datadirty")
    self.enchant_data = {}
    --[enchantment name] = {t(ier), d(urability)}

    self.inst:ListenForEvent("gemology.enchant_datadirty", function(inst)
        self.enchant_data = json.decode(self._enchant_data:value())
    end)

    self._slots = net_int(inst.GUID, "gemology.slots", "gemology.onslotsdirty")
end)

function GemEnchantable:GetEnchantments()
    return self.enchant_data
end

function GemEnchantable:GetEnchantmentTier(enchantment)
    return self.enchant_data[enchantment].t
end

function GemEnchantable:GetEnchantmentDurability(enchantment)
    return self.enchant_data[enchantment].d
end

function GemEnchantable:HasEnchantment(enchantment)
    return self.enchant_data[enchantment] ~= nil
end

function GemEnchantable:GetEnchantmentNames()
    local names = {}
    for name, data in pairs(self.enchant_data) do
        table.insert(names, name)
    end
    return names
end

function GemEnchantable:GetSlots()
    return self._slots:value()
end

function GemEnchantable:GetLowestGemDurability()
    local lowest = nil
    local enchant = nil
    local tier = nil

    for name, data in pairs(self.enchant_data) do
        if lowest == nil or data.d ~= nil and data.d < lowest then
            lowest = data.d
            enchant = name
            tier = data.t
        end
    end

    return enchant, lowest, tier
end

function GemEnchantable:IsEnchanted()
    return next(self:GetEnchantments()) ~= nil
end

return GemEnchantable

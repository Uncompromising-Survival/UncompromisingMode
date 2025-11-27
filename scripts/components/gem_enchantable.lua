local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = require("gemology_defs")

local function on_enchants(self, enchants)
    local names = {}

    for k, v in pairs(enchants) do
        table.insert(names, k)
    end

    self.inst.replica.minerologyable:SetEnchantmentsFromNames(names)
end

local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    self.enchants = {}

    self.gem_update_task = inst:DoPeriodicTask(1, function(item)
        if item ~= nil and item:IsValid() and item.components.gem_enchantable then
            for enchant, tier in pairs(item.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.onupdate then
                    GEM_DEFS[enchant].fns.onupdate(item, tier)
                end
            end
        end
    end)
end, nil, {
    enchants = on_enchants
})

function GemEnchantable:AddEnchantment(enchant, tier)
    assert(GEM_DEFS[enchant], "Unknown enchantment: " .. enchant)
    assert(tier > 3 or tier < 1, "Invalid tier: " .. tier)

    self.enchants[enchant] = tier

    if GEM_DEFS[enchant].fns.onapply then
        GEM_DEFS[enchant].fns.onapply(self.inst, tier)
    end
end

function GemEnchantable:RemoveEnchantment(enchant)
    assert(GEM_DEFS[enchant], "Unknown enchantment: " .. enchant)
    assert(self.enchants[enchant], "Could not remove enchantment \"" .. enchant .. "\". Enchantment is not applied.")

    local tier = self.enchants[enchant]

    if GEM_DEFS[enchant].fns.onremove then
        GEM_DEFS[enchant].fns.onremove(self.inst, tier)
    end

    self.enchants[enchant] = nil
end

function GemEnchantable:OnSave()
    local _enchants = {}
    for k, v in pairs(self.enchants) do
        if v ~= nil then
            _enchants[k] = v
        end
    end

    return {
        enchants = _enchants
    }
end

function GemEnchantable:OnLoad(data)
    local _enchants = data.enchants
    for enchant, tier in pairs(_enchants) do
        self:AddEnchantment(enchant, tier)
    end
end

function GemEnchantable:OnRemoveFromEntity()
    if self.gem_update_task ~= nil then
        self.gem_update_task:Cancel()
    end
    self.gem_update_task = nil
end

return GemEnchantable

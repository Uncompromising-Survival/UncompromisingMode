local DEFS = require("gemology_defs")
local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = DEFS.GEM_DEFS, DEFS.GEM_LOOKUP, DEFS.INVERTED_GEM_LOOKUP

local function on_enchants(self, flag)
    if self.update_flag then
        local enchants = self.enchants

        local names = {}

        for k, v in pairs(enchants) do
            table.insert(names, k)
        end

        self.inst.replica.gem_enchantable:SetEnchantmentsFromNames(names)

        self.update_flag = false
    end
end

local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    self.enchants = {}
    self.slots = 1

    self.update_flag = false

    if self.inst.gemology_data == nil then
        self.inst.gemology_data = {}
    end

    for k,v in pairs(GEM_LOOKUP) do
        self.inst.gemology_data[v] = {}
    end

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
    update_flag = on_enchants
})

function GemEnchantable:AddEnchantment(enchant, tier)
    assert(self.enchants[enchant] == nil, "Enchantment \"" .. enchant .. "\" is already applied.")
    assert(GEM_DEFS[enchant] ~= nil, "Unknown enchantment: " .. enchant)
    assert(tier <= 3 and tier >= 1, "Invalid tier: " .. tier)

    self.enchants[enchant] = tier

    if GEM_DEFS[enchant].fns.onapply then
        GEM_DEFS[enchant].fns.onapply(self.inst, tier)
    end

    self.update_flag = true
end

function GemEnchantable:RemoveEnchantment(enchant)
    assert(GEM_DEFS[enchant], "Unknown enchantment: " .. enchant)
    assert(self.enchants[enchant], "Could not remove enchantment \"" .. enchant .. "\". Enchantment is not applied.")

    local tier = self.enchants[enchant]

    if GEM_DEFS[enchant].fns.onremove then
        GEM_DEFS[enchant].fns.onremove(self.inst, tier)
    end

    self.enchants[enchant] = nil

    self.inst.gemology_data[enchant] = {} --clear data for this effect.

    self.update_flag = true
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

function GemEnchantable:HasSlots()
    return self.slots > 0
end

function GemEnchantable:GetSlots()
    return self.slots
end

function GemEnchantable:AddSlot(num)
    self.slots = self.slots + num
end

return GemEnchantable

local GEM_DEFS = require("prefabs/gemology_defs")

local function set_enchant_client(inst, enchantments)
end

local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    --Note(Atobá): The prefix on the client will be the first entry - which the exception of chaotic. If there's the chaotic (greengem2) effect, which takes priority.
    self.enchantment_data = {
        --["enchantment"] = {
        --durability: float
        --tier: int (1-3)
        --use_durability: bool
        --}
    }
end, nil, {
    enchantment_data = set_enchant_client
})

local function ValidadeEnchantment(enchantment)
    return GEM_DEFS[enchantment] ~= nil
end

function GemEnchantable:AddEnchantment(enchantment, durability, tier, use_durability)
    print("DEBUG: Adding enchantment \"" .. enchantment .. "\" with durability " .. durability .. " and tier " .. tier .. " and use_durability " .. use_durability)
    assert(ValidadeEnchantment(enchantment), "Could not locate enchantment \"" .. enchantment .. "\" in Gemology definitions or its invalid!")
    self.enchantment_data[enchantment] = { durability = durability, tier = tier, use_durability = use_durability }
end

function GemEnchantable:RemoveEnchantment(enchantment)
    if self.enchantment_data[enchantment] == nil then
        print("WARN: Tried to remove enchantment " .. enchantment .. " from " .. self.inst.prefab .. ", but it doesn't have it!")
        return
    end

    self.enchantment_data[enchantment] = nil
end

function GemEnchantable:HasEnchantment(enchantment)
    return self.enchantment_data[enchantment] ~= nil
end

function GemEnchantable:GetEnchantment(enchantment)
    assert(ValidadeEnchantment(enchantment), "Could not locate enchantment \"" .. enchantment .. "\" in Gemology definitions or its invalid!")
    return enchantment, self.enchantment_data[enchantment]
end

return GemEnchantable

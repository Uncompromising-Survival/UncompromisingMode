local DEFS                 = require("gemology_defs")
local GEM_DEFS, GEM_LOOKUP = DEFS.GEM_DEFS, DEFS.GEM_LOOKUP
local GEM_UPDATE_RATE      = 1
local DEFAULT_SLOTS        = 1

local function on_enchants(self, flag)
    if self.dirty then
        local enchants = self.enchants

        local enchant_data = {}

        for k, v in pairs(enchants) do
            if not table.contains(self.hidden_enchants, k) then --only sync non-hidden gems.
                enchant_data[k] = { t = v, d = self.enchant_durabilty[k] }
            end
        end

        self.inst.replica.gem_enchantable._enchant_data:set(json.encode(enchant_data))
        self.inst.replica.gem_enchantable._slots:set(self.slots)

        self.dirty = false
    end
end

local GemEnchantable = Class(function(self, inst)
    self.inst = inst
    self.enchants = {}          --[enchantment name] = tier
    self.enchant_durabilty = {} --[enchantment name] = durability (0-1)%
    self.slots = DEFAULT_SLOTS
    self.hidden_enchants = {}   --WARNING: NOT SAVED
    self.slotless_enchants = {}
    self.dirty = true

    --this data saves
    if self.inst.persistent_gemology_data == nil then
        self.inst.persistent_gemology_data = {}
    end

    --this data does NOT save
    if self.inst.volatile_gemology_data == nil then
        self.inst.volatile_gemology_data = {}
    end


    for k, v in pairs(GEM_LOOKUP) do
        self.inst.persistent_gemology_data[v] = {}
        self.inst.volatile_gemology_data[v] = {}
    end

    --probably should add this
    self.inst:AddTag("gem_enchantable")

    self.gem_update_task = inst:DoPeriodicTask(GEM_UPDATE_RATE, function(item)
        if item ~= nil and item:IsValid() and item.components.gem_enchantable then
            for enchant, tier in pairs(item.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.onupdate then
                    GEM_DEFS[enchant].fns.onupdate(item, tier)
                end
            end
            item.components.gem_enchantable.dirty = true
        end
    end)

    self.inst:ListenForEvent("perishchange", function(inst, data)
        local new_durability = data.percent

        for gem, tier in pairs(self.inst.components.gem_enchantable.enchants) do
            if self.inst.components.gem_enchantable:HasDurabilityEnabled(gem) then
                for _gem, durability in pairs(self.inst.components.gem_enchantable.enchant_durabilty) do
                    if durability > new_durability and gem == _gem and not self.loading then
                        self.inst.components.gem_enchantable:SetDurability(gem, new_durability)
                    end
                end
            end
        end
    end)

    --for methods updating durability from fueled, armor and finiteuses, see init/init_gemology/common
end, nil, {
    dirty = on_enchants,
    slots = on_enchants,
})

function GemEnchantable:HasEnchantment(enchant, tier)
    assert(GEM_DEFS[enchant] ~= nil, "Attempted to check unknown enchantment: " .. enchant)
    if tier ~= nil then
        assert(tier <= MAX_GEM_TIER and tier >= MIN_GEM_ENCHANT_TIER, "Attempted to check gem enchantment with invalid tier: \"" .. tier .. "\" Gem tiers are " .. MIN_GEM_ENCHANT_TIER .. " to " .. MAX_GEM_TIER .. ".")
        assert(type(tier) == 'number', "Invalid argument #2 for HasEnchant, required type: number - provided type: " .. type(tier))
    end

    if tier == nil then
        return self.enchants[enchant] ~= nil
    else
        return self.enchants[enchant] == tier
    end
end

function GemEnchantable:GetEnchantmentTier(enchant)
    assert(GEM_DEFS[enchant] ~= nil, "Attempted to get unknown enchantment: " .. enchant)

    return self.enchants[enchant]
end

function GemEnchantable:SetDurability(enchantment, durability)
    durability = math.clamp(durability, 0, 1)

    --check for HasEnchantment in case something does a delayed durability delta.
    if durability <= 0 and self:HasEnchantment(enchantment) then
        if self.inst.SoundEmitter then
            self.inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
        end

        self:RemoveEnchantment(enchantment)
    end

    self.enchant_durabilty[enchantment] = durability
    self.dirty = true
end

function GemEnchantable:DoDurabilityDelta(enchantment, value)
    self:SetDurability(enchantment, self.enchant_durabilty[enchantment] + value)
end

function GemEnchantable:HasDurabilityEnabled(enchant)
    return self.enchant_durabilty[enchant] ~= nil
end

function GemEnchantable:GetDurability(enchantment)
    assert(self:HasDurabilityEnabled(enchantment), "Attempted to get durability of enchantment \"" .. enchantment .. "\", but it has no durability.")

    return self.enchant_durabilty[enchantment]
end

function GemEnchantable:AddEnchantment(enchant, tier, slotless, fix_tier)
    if self.enchants[enchant] ~= nil then
        print("[WARN] Added enchantment \"" .. enchant .. "\", was already applied.")
    end

    --for fixing saves where invalid gem tiers happened.
    --only doing this onsave, its best if it fails the assert below this so you know you're screwing up.
    if fix_tier then
        if tier > MAX_GEM_TIER then
            print("[WARN] Fixed invalid tier on load for enchantment \"" .. enchant .. "\". Tier was " .. tier .. ", should be between " .. MIN_GEM_ENCHANT_TIER .. " and " .. MAX_GEM_TIER .. ".")
            tier = MAX_GEM_TIER
        elseif tier < MIN_GEM_ENCHANT_TIER then
            print("[WARN] Fixed invalid tier on load for enchantment \"" .. enchant .. "\". Tier was " .. tier .. ", should be between " .. MIN_GEM_ENCHANT_TIER .. " and " .. MAX_GEM_TIER .. ".")
            tier = MIN_GEM_ENCHANT_TIER
        end
    end

    assert(GEM_DEFS[enchant] ~= nil, "Attempted to add unknown enchantment: " .. enchant)
    assert(tier <= MAX_GEM_TIER and tier >= MIN_GEM_ENCHANT_TIER, "Attempted to add gem enchantment with invalid tier: \"" .. tier .. "\" Gem tiers are " .. MIN_GEM_ENCHANT_TIER .. " to " .. MAX_GEM_TIER .. ".")

    self.enchants[enchant] = tier

    if GEM_DEFS[enchant].fns.onapply then
        GEM_DEFS[enchant].fns.onapply(self.inst, tier)
    end

    if slotless then
        self.slotless_enchants[enchant] = true
    else
        self.slots = self.slots - 1
    end

    self.dirty = true

    self.inst:PushEvent("onaddenchant", { enchant = enchant, tier = tier })
end

function GemEnchantable:RemoveEnchantment(enchant)
    assert(GEM_DEFS[enchant] ~= nil, "Attempted to remove unknown enchantment: " .. enchant)
    assert(self.enchants[enchant], "Could not remove enchantment \"" .. enchant .. "\". Enchantment is not applied.")

    local tier = self.enchants[enchant]


    if GEM_DEFS[enchant].fns.onremove then
        GEM_DEFS[enchant].fns.onremove(self.inst, tier)
    end

    self.enchant_durabilty[enchant] = nil

    self.inst:PushEvent("onremoveenchant", { enchant = enchant, tier = tier })

    self.enchants[enchant] = nil

    local slotless = self.slotless_enchants[enchant] ~= nil
    if slotless then
        self.slotless_enchants[enchant] = nil
    else
        self.slots = self.slots + 1
    end

    self.inst.persistent_gemology_data[enchant] = {} --clear data for this effect.
    self.inst.volatile_gemology_data[enchant] = {}   --clear data for this effect.

    self.dirty = true
end

function GemEnchantable:IsEnchanted()
    return next(self.enchants) ~= nil
end

function GemEnchantable:OnSave()
    local _enchants = {}
    for k, v in pairs(self.enchants) do
        --do not save hidden enchants (chaotic re-applies them on apply)
        if v ~= nil and not table.contains(self.hidden_enchants, k) then
            _enchants[k] = v
        end
    end


    return {
        enchants = _enchants,
        gem_data = self.inst.persistent_gemology_data,
        durability = self.enchant_durabilty
    }
end

function GemEnchantable:OnLoad(data)
    self.loading = true
    local _enchants = data.enchants

    self.inst.persistent_gemology_data = data.gem_data

    for enchant, tier in pairs(_enchants) do
        self:AddEnchantment(enchant, tier, nil, true) --running add enchant to re-apply onapply effects.
    end

    self.enchant_durabilty = data.durability

    self.inst:DoTaskInTime(0, function(inst)
        self.enchant_durabilty = data.durability
        self.dirty = true
        self.loading = false
    end)

    self.dirty = true
end

function GemEnchantable:RemoveAllEnchantments()
    for k, v in pairs(self.enchants) do
        self:RemoveEnchantment(k)
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

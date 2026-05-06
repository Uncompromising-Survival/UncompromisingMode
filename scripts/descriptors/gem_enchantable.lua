local GEM_DEFS = require("gemology_defs").GEM_DEFS

local function RGBToHex(r, g, b)
    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local default_color = RGBToHex(0.75, 0.75, 0.75)

local function Describe(self, context)
    local description = nil

    if self:IsEnchanted() then
        description = "<color=" .. default_color .. ">" .. STRINGS.UM_DESCRIPTOR.GEM_ENCHANTABLE.PREFIX .. "</color>\n"
        local effects = ""

        for enchant, tier in pairs(self.enchants) do
            if not table.contains(self.hidden_enchants, enchant) then
                local r, g, b, a = unpack(GEM_DEFS[enchant].color)
                local color = RGBToHex(r, g, b)
                if self:HasDurabilityEnabled(enchant) then
                    effects = effects .. string.format("<color=%s>%s</color> <color=%s>(%s %d - %d%%)</color>\n",
                        color,
                        GEM_DEFS[enchant].desc[tier],
                        default_color,
                        STRINGS.UM_DESCRIPTOR.GEM_TIER_PREFIX,
                        tier,
                        math.floor(self:GetDurability(enchant) * 100)
                    )
                else
                    effects = effects .. string.format("<color=%s>%s</color> <color=%s>(%s %d)</color>\n",
                        color,
                        GEM_DEFS[enchant].desc[tier],
                        default_color,
                        STRINGS.UM_DESCRIPTOR.GEM_TIER_PREFIX,
                        tier
                    )
                end
            end
        end

        description = description .. effects
    end

    local slot_str = "<color=" .. default_color .. ">" .. STRINGS.UM_DESCRIPTOR.GEM_ENCHANTABLE.SLOTS_PREFIX .. " " .. self:GetSlots() .. "</color>"
    description = description ~= nil and description .. slot_str or
        slot_str

    return {
        priority = 0,
        alt_description = description,
        append = true
    }
end

return {
    Describe = Describe,
}

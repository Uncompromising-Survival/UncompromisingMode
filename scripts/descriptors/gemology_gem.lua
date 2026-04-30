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

    local tier = self.inst:GetTier()
    local r, g, b, a = unpack(GEM_DEFS[self.inst.prefab].color)

    --transform into hex color for insights RichText
    local color = RGBToHex(r, g, b)

    local gem_name = string.upper(string.gsub(string.gsub(self.inst.prefab, "um_gemology", ""), "gem", ""))

    description = string.format("<color=%s>%s</color>\n<color=%s>%s</color> <color=%s>(%s %d)</color>",
        default_color,
        STRINGS.UM_DESCRIPTOR.GEMOLOGY_GEM.PREFIX,
        color,
        STRINGS.UM_DESCRIPTOR.GEMOLOGY_GEM[gem_name][tier],
        default_color,
        STRINGS.UM_DESCRIPTOR.GEM_TIER_PREFIX,
        tier
    )

    return {
        priority = 0,
        description = description,
        append = true
    }
end

return {
    Describe = Describe,
}

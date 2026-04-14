local function Describe(self, context)
    local description = nil

    local tier = self.tier ~= nil and self.tier or 1
    if self.enchant ~= nil then
        local gem_name = string.upper(string.gsub(string.gsub(self.enchant, "um_gemology", ""), "gem", ""))
        description = "Gemology Effects:\n " .. STRINGS.UM_DESCRIPTOR.GEM_ENCHANTABLE[gem_name][tier] .. "\nQuality: " .. tier
    end

    return {
        priority = 0,
        description = description,
        append = true
    }
end

return {
    Describe = Describe,
}

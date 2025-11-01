local function Describe(self, context)
    local description = nil

    --offset tier for stupid lua tables starting at 1 grrrr
    local tier = self.tier ~= nil and self.tier + 1 or 1
    if self.enchant ~= nil then
        local gem_name = string.gsub(string.gsub(self.enchant, "um_gemology", ""), "gem", "")
        description = "Gemology Effects:\n " .. STRINGS.UM_DESCRIPTORS.MINEROLOGYABLE[gem_name][tier] .. "\nQuality: " .. tier
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

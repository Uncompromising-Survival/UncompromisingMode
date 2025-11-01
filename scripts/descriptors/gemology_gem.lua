local function Describe(self, context)
    local description = nil

    --offset tier for stupid lua tables starting at 1 grrrr
    local tier = self.inst:GetTier()

    local gem_name = string.gsub(string.gsub(self.inst.prefab, "um_gemology", ""), "gem", "")
    description = "When applied to an item:\n " .. STRINGS.UM_DESCRIPTORS.GEMOLOGY_GEM[gem_name][tier] .. "\nQuality: " .. tier

    return {
        priority = 0,
        description = description,
        append = true
    }
end

return {
    Describe = Describe,
}

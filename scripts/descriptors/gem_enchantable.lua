local GEM_DEFS = require("gemology_defs").GEM_DEFS

local function Describe(self, context)
    local description = nil

    if self:IsEnchanted() then
        description = "Gemology Effects:\n "
        local effects = ""

        for enchant, tier in pairs(self.enchants) do
            if not table.contains(self.hidden_enchants, enchant) then
                effects = effects .. GEM_DEFS[enchant].desc[tier] .. " (Quality: " .. tier .. ")\n"
            end
        end

        description = description .. effects
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

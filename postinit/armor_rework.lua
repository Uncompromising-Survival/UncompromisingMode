--[[
Documentation: KoreanWaffles

Most armors in the game have been automatically nerfed to have lower protection values.

Rationale:
High protection values of armors trivialize certain combat encounters. Characters such as Wanda
and Maxwell, who are supposed to be frail, never have to worry about health due to armors such as
the Marble Suit giving so much protection (Maxwell's 75 health becomes an effective health with a
Marble Suit equipped). Bosses such as the Hooded Widow, who are supposed to be threatening, can be
tanked using even basic armors such as a Log Suit and Football Helmet. Instead of buffing mobs to
do absurd amounts of damage, we want to tackle the root of the issue which is armors giving too
much protection.

Note: ARMOR_ABSORPTION_OVERRIDES is a global table that can be accessed by any server-side mod to
add their own armors and protection values.
]]

local env = env
GLOBAL.setfenv(1, GLOBAL)

if not TheNet:GetIsServer() then
    return
end

-- Exceptions can be made for specific armors to change their absorption values directly instead of
-- using the armor_mappings table.
ARMOR_ABSORPTION_OVERRIDES = {
    ["beehat"] = 0.7,
    ["armorruins"] = 0.8,
	["shieldofterror"] = 0.75,
	["cookiecutterhat"] = 0.7,
	["wathgrithrhat"] = 0.7,
	["wathgrithr_improvedhat"] = 0.7,
	["armor_bramble"] = 0.7,
	["voidclothhat"] = 0.7,
	["armor_voidcloth"] = 0.7,
	["lunarplanthat"] = 0.7,
	["armor_lunarplant"] = 0.7,
	["armor_lunarplant_husk"] = 0.7,
	["slurtlehat"] = 0.7,
	["um_armor_bramble_rimeweed"] = 0.7,
}

-- Lower bounds are exclusive while upper bounds are inclusive. For example, a Log Suit with a
-- protection value of 0.8 will be lowered to 0.65, not 0.75.
local armor_mappings = {
    {min_val = 0.9, max_val = 0.95, new_absorb = 0.8},
    {min_val = 0.85, max_val = 0.9, new_absorb = 0.75},
    {min_val = 0.8, max_val = 0.85, new_absorb = 0.7},
    {min_val = 0.7, max_val = 0.8, new_absorb = 0.65},
    {min_val = 0.6, max_val = 0.7, new_absorb = 0.6},
}

-- Adjust armor protection values based on the above tables.
env.AddPrefabPostInitAny(function(inst)
    if inst.components.armor then
        -- If the armor is in the overrides table, prioritize using that protection value.
        if ARMOR_ABSORPTION_OVERRIDES[inst.prefab] then
            inst.components.armor:SetAbsorption(ARMOR_ABSORPTION_OVERRIDES[inst.prefab])
            return
        end
        local absorb_percent = inst.components.armor.absorb_percent
        -- If the armor is not in the overrides table, automatically adjust the protection value
        -- using the mapping table.
        for _, mapping in ipairs(armor_mappings) do
            if absorb_percent > mapping.min_val and absorb_percent <= mapping.max_val then
                inst.components.armor:SetAbsorption(mapping.new_absorb)
                return
            end
        end
    end
end)

local env = env
GLOBAL.setfenv(1, GLOBAL)

local armor_overrides = {
    ["beehat"] = 0.8,
    ["armorruins"] = 0.8,
    ["footballhat"] = 0.65,
    ["eyemaskhat"] = 0.65
}

local armor_mapping = {
    [0.95] = 0.8, --Tier 5
    [0.9] = 0.75, --Tier 4
    [0.85] = 0.7, --Tier 3.5
    [0.8] = 0.6,  --Tier 3
    [0.7] = 0.55,  --Tier 2
    [0.6] = 0.5   --Tier 1
}

env.AddPrefabPostInitAny(function(inst)
    if inst.components.armor then
        if armor_overrides[inst.prefab] then
            inst.components.armor:SetAbsorption(armor_overrides[inst.prefab])
            return
        end
        local absorb_percent = inst.components.armor.absorb_percent
        if armor_mapping[absorb_percent] then
            inst.components.armor:SetAbsorption(armor_mapping[absorb_percent])
            return
        end
        --If not in list, leave the value alone
    end
end)
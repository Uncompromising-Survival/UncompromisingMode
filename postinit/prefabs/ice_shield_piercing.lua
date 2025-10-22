local env = env
GLOBAL.setfenv(1, GLOBAL)

--Putting UM prefabs here just for organization's sake so we know all of them.
local pierces_ice_shield = {
    "torch",
    "firestaff",
    "blowdart_fire",
    "lighter",
    "slingshotammo_flare_projectile",
    "slingshotammo_flare_projectile_secondary",
    "slingshotammo_obsidian",
    "flamethrower_fx",   --willow
    "willow_shadowflame" --willow
}

local TOOLTIP = STRINGS.UNCOMP_TOOLTIP


for k, v in ipairs(pierces_ice_shield) do
    env.AddPrefabPostInit(v, function(inst)
        inst:AddTag("pierces_ice_shield")
    end)


    if AllRecipes[v] ~= nil then
        if TOOLTIP[string.upper(v)] ~= nil then
            TOOLTIP[string.upper(v)] = TOOLTIP[string.upper(v)] .. "\n- Pierces Icy Barriers"
        else
            TOOLTIP[string.upper(v)] = "- Pierces Icy Barriers"
        end
    end
end

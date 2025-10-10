--Putting UM prefabs here just for organization's sake so we know all of them.
local pierces_ice_shield = {
    "torch",
    "firestaff",
    "blowdart_fire",
    "lighter",
    "slingshotammo_flare_projectile",
    "slingshotammo_flare_projectile_secondary",
    "slingshotammo_obsidian",
    "flamethrower_fx", --willow 
    "willow_shadowflame" --willow
}

for k, v in ipairs(pierces_ice_shield) do
    AddPrefabPostInit(v, function(inst)
        inst:AddTag("pierces_ice_shield")
    end)
end

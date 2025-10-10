local pierces_ice_shield = {
    "torch",
    "firestaff",
    "blowdart_fire",
    "lighter"
}

for k, v in ipairs(pierces_ice_shield) do
    AddPrefabPostInit(v, function(inst)
        inst:AddTag("pierces_ice_shield")
    end)
end

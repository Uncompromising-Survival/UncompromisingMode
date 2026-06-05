_G = GLOBAL

print("HERE!!!")

local function AddDescriptors()
    print("HERE!!!")
    if not _G.rawget(_G, "Insight") then return end

    print("HERE INSIGHT!!!")

    _G.Insight.API.V1.AddComponentDescriptor("uncompromising_deerclopsspawner", _G.require("descriptors/uncompromising_deerclopsspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("mock_dragonflyspawner", _G.require("descriptors/mock_dragonflyspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("gmoosespawner", _G.require("descriptors/gmoosespawner"), { modname = modname })

    _G.Insight.API.V1.AddComponentDescriptor("gem_enchantable", _G.require("descriptors/gem_enchantable"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("gemology_gem", _G.require("descriptors/gemology_gem"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("um_guano_rain", _G.require("descriptors/um_guano_rain"), { modname = modname })
end

AddSimPostInit(AddDescriptors) -- _G.Insight.descriptors may not exist yet, but it will exist at AddSimPostInit.

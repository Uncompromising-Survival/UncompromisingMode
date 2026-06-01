_G = GLOBAL

local function AddDescriptors()
    if not _G.rawget(_G, "Insight") then return end

    _G.Insight.API.V1.AddComponentDescriptor("uncompromising_deerclopsspawner", _G.require("descriptors/uncompromising_deerclopsspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("mock_dragonflyspawner", _G.require("descriptors/mock_dragonflyspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("gmoosespawner", _G.require("descriptors/gmoosespawner"), { modname = modname })
end

AddSimPostInit(AddDescriptors) -- _G.Insight.descriptors may not exist yet, but it will exist at AddSimPostInit.
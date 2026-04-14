_G = GLOBAL

print("HERE!!!")

local function AddDescriptors()
    print("HERE!!!")
    if not _G.rawget(_G, "Insight") then return end

    print("HERE INSIGHT!!!")

    _G.Insight.descriptors.uncompromising_deerclopsspawner = _G.require("descriptors/uncompromising_deerclopsspawner")
    _G.Insight.descriptors.mock_dragonflyspawner = _G.require("descriptors/mock_dragonflyspawner")
    _G.Insight.descriptors.gmoosespawner = _G.require("descriptors/gmoosespawner")

    --TODO TODO
    --_G.Insight.descriptors.gem_enchantable = _G.require("descriptors/gem_enchantable") 
    _G.Insight.descriptors.gemology_gem = _G.require("descriptors/gemology_gem")
end

AddSimPostInit(AddDescriptors) -- _G.Insight.descriptors may not exist yet, but it will exist at AddSimPostInit.
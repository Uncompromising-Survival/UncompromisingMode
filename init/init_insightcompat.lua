_G = GLOBAL

print("Loaded insight compat")

local function AddDescriptors()
    if not _G.rawget(_G, "Insight") then return end


    --[00:01:29]: shard insight postinit	

    _G.Insight.API.V1.AddComponentDescriptor("uncompromising_deerclopsspawner", _G.require("descriptors/uncompromising_deerclopsspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("mock_dragonflyspawner", _G.require("descriptors/mock_dragonflyspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("gmoosespawner", _G.require("descriptors/gmoosespawner"), { modname = modname })

    _G.Insight.API.V1.AddComponentDescriptor("gem_enchantable", _G.require("descriptors/gem_enchantable"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("gemology_gem", _G.require("descriptors/gemology_gem"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("um_guano_rain", _G.require("descriptors/um_guano_rain"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("um_snow_stormspawner", _G.require("descriptors/um_snow_stormspawner"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("um_heatwaves", _G.require("descriptors/um_heatwaves"), { modname = modname })
    _G.Insight.API.V1.AddComponentDescriptor("um_stormspawner", _G.require("descriptors/um_stormspawner"), { modname = modname })

    _G.Insight.API.V1.AddPrefabDescriptor("widowweb", _G.require("descriptors/widowweb"), { modname = modname })
end

AddSimPostInit(AddDescriptors) -- _G.Insight.descriptors may not exist yet, but it will exist at AddSimPostInit.


AddComponentPostInit("shard_insight", function(self)
    function self:SetWidowSpawner(entity)
        self.shard_descriptors.widowweb = _G.Insight.prefab_descriptors.widowweb and _G.Insight.prefab_descriptors.widowweb.RemoteDescribe or nil

        if self.shard_data_fetcher.widowweb then
            return
        end

        self:RegisterWorldDataFetcher("widowweb", function()
            return _G.Insight.prefab_descriptors.widowweb
                and _G.Insight.prefab_descriptors.widowweb.GetRespawnData
                and _G.Insight.prefab_descriptors.widowweb.GetRespawnData(entity) or nil
        end)

        entity:ListenForEvent("onremove", function()
            self:RemoveWorldDataFetcher("widowweb")
        end)
    end
end)

AddPrefabPostInit("widowweb", function(inst)
    if not _G.TheWorld.ismastersim or not _G.rawget(_G, "Insight") then return end

    inst:DoTaskInTime(0, function()
        _G.TheWorld.shard.components.shard_insight:SetWidowSpawner(inst)
    end)
end)

local function RetrofitLayouts()
	if TheWorld.topology == nil or TheWorld.topology.nodes == nil or TheWorld.topology.ids == nil then
		print("Retrofitting for MushGnomeSpawnArea - World Topology does not exist yet. Skipping.")

		return false
	end

	local dirty = false

	local serenity_ids = 
	{
		"WormyMoonMushForest",
		"GrottoLightFloodNoise",
		"GrottoLightFlood",
		"GrottoHeavyFloodNoise",
		"GrottoHeavyFlood",
		"MoonMushForest"
	}

	local function NodeNeedsRetrofit(node, expected_tags)
		for _, tag in ipairs(expected_tags) do
			if not table.contains(node.tags or {}, tag) then
				return true
			end
		end
		return false
	end

	for i, node in ipairs(TheWorld.topology.nodes) do
		local id = TheWorld.topology.ids[i]
		node.tags = node.tags or {}

		for _, sid in ipairs(serenity_ids) do
			if string.find(id, sid) and NodeNeedsRetrofit(node, {"MushGnomeSpawnArea"}) then
				table.insert(node.tags, "MushGnomeSpawnArea")
				dirty = true
			end
		end
	end

	if dirty then
		for i, node in ipairs(TheWorld.topology.nodes) do
			if table.contains(node.tags, "MushGnomeSpawnArea") then
				TheWorld.Map:RepopulateNodeIdTileMap(i, node.x, node.y, node.poly, 10000, 2.1)
			end
		end
	end

	return dirty
end


AddComponentPostInit("retrofitcavemap_anr", function(self)
	local OldOnPostInit = self.OnPostInit
	function self:OnPostInit(...)
		local success = RetrofitLayouts()
		if success then
			print("MushGnomeSpawnArea retrofit succeess")
		end
		return OldOnPostInit(self, ...)
	end
end)
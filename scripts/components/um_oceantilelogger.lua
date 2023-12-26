return Class(function(self, inst)
	self.inst = inst
	assert(TheWorld.ismastersim, "um_oceantilelogger should not exist on client")
	--Tiles Occur Every 4 spaces

	local function AnalyzeWorld(tiletype) --207 For Hazardous
		local world_size = TheWorld.Map:GetWorldSize() * 4
		local max_x = world_size / 2
		local max_z = world_size / 2
	
		local tiletable = {}
		tiletable[1] = {}
		tiletable[2] = {}
		local i = 1
		for x = -max_x, max_x, 4 do --Instead relate to world size if accessible
			for z = -max_z, max_z, 4 do
				if TheWorld.Map:GetTileAtPoint(x, 0, z) == tiletype then
					tiletable[1][i] = x
					tiletable[2][i] = z
					i = i + 1
				end
			end
		end
		--[[print("finished logging hazardous")
		print("Here's the first entry")
		print("x = ")
		print(tiletable[1][1])
		print("z = ")
		print(tiletable[2][1])
		print("The total hazardous")
		print(#tiletable[1])]]

		return tiletable
	end

	local function FindAllTileTypes(self)
		self.Hazardous = AnalyzeWorld(WORLD_TILES["OCEAN_HAZARDOUS"])
	end

	--[[function self:OnSave()
		local data = {}
		data.Hazardous = self.Hazardous
		return data
	end]]

	--[[function self:OnLoad(data)
		if data then
			if data.Hazardous then
				self.Hazardous = data.Hazardous
			else
				self.inst:DoTaskInTime(0, function()
					self.Hazardous = AnalyzeWorld(WORLD_TILES["OCEAN_HAZARDOUS"])
				end)
			end
		end
	end]]

	function self:OnPostInit()
		if not self.Hazardous then
			self.inst:DoTaskInTime(0, function()
				self.Hazardous = AnalyzeWorld(WORLD_TILES["OCEAN_HAZARDOUS"])
			end)
		end
	end
end)

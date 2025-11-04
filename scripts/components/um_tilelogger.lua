return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_tilelogger should not exist on client")
    --Tiles Occur Every 4 spaces

    local function AnalyzeWorld(tiletype) --207 For Hazardous
        local world_size = TheWorld.Map:GetWorldSize() * 4
        local max_x = world_size / 2
        local max_z = world_size / 2

        local tileTable = {}
        for x = -max_x, max_x, 4 do --Instead relate to world size if accessible
            for z = -max_z, max_z, 4 do
                if TheWorld.Map:GetTileAtPoint(x, 0, z) == tiletype then
                    table.insert(tileTable, { x= x, z= z })
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

        return tileTable
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
        if not self.Hazardous and not TheWorld:HasTag("cave") then
            self.inst:DoTaskInTime(0, function()
                self.Hazardous = AnalyzeWorld(WORLD_TILES["OCEAN_HAZARDOUS"])
            end)
        end

        if not self.Magma and TheWorld:HasTag("cave") then
            self.inst:DoTaskInTime(0, function()
                self.Magma = AnalyzeWorld(WORLD_TILES["UM_MAGMA_LAVAMOLTEN"])
            end)
        end
    end
end)

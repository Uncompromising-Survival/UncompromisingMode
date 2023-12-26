return Class(function(self, inst)
	self.inst = inst
	assert(TheWorld.ismastersim, "um_ocupusappearinator should not exist on client")

	local function FindOcupi()
		local tag = "um_ocupus_core"
		local entities = {}
		for k, v in pairs(Ents) do
			if v:HasTag(tag) then
				table.insert(entities, v)
			end
		end
		return #entities
	end

	local function CheckForOtherOcupi(Hazardous, val)
		if Hazardous and val then
			if Hazardous[1][val] ~= nil and Hazardous[2][val] ~= nil and #TheSim:FindEntities(Hazardous[1][val], 0, Hazardous[2][val], 40, { "um_ocupus_core" }) == 0 then
				return true
			end
		end
	end

	local function IterateThroughTiles(Hazardous)
		for i = 1, #Hazardous[1] do
			local val = math.floor(#Hazardous[1] * math.random() + 1) --Returns a random table value for the x and z position of tiles
			if CheckForOtherOcupi(Hazardous, val) then
				local locationfornewoct = {}
				locationfornewoct.x = Hazardous[1][val]
				locationfornewoct.z = Hazardous[2][val]
				return locationfornewoct
			else
				table.remove(Hazardous[1], val)
				table.remove(Hazardous[2], val)
				IterateThroughTiles(Hazardous)
			end
		end
	end

	local function FindLocation()
		if TheWorld.components.um_oceantilelogger and TheWorld.components.um_oceantilelogger.Hazardous then
			return IterateThroughTiles(TheWorld.components.um_oceantilelogger.Hazardous)
		end
	end

	local function SpawnOcupi()
		local locationfornewoct = FindLocation()
		if locationfornewoct then --If you maxwelled the whole ocean I swear
			SpawnPrefab("um_ocupus").Transform:SetPosition(locationfornewoct.x, 0, locationfornewoct.z)
		end
	end

	local function OnSeasonTick(src, data)
		local Ocupus = FindOcupi()
		if Ocupus and Ocupus < 1 then
			SpawnOcupi()
			SpawnOcupi()
		elseif Ocupus < 3 then
			SpawnOcupi()
		elseif Ocupus < 4 and math.random() > 0.5 then
			SpawnOcupi()
		elseif Ocupus < 6 and math.random() > 0.75 then
			SpawnOcupi()
		elseif math.random() > 0.9 then
			SpawnOcupi()
		end
	end

	function self:FirstRun()
		SpawnOcupi()
		SpawnOcupi()
		SpawnOcupi()
	end

	function self:OnSave()
		local data = {}
		data.firstrun = self.firstrun
	end

	function self:OnLoad(data)
		if data then
			if data.firstrun then
				self.firstrun = data.firstrun
			end
		end
	end

	function self:OnPostInit()
		self.firstrun = true
		self.inst:DoTaskInTime(0, function(inst)
			if not self.firstrun then
				inst.components.um_ocupusappearinator:FirstRun()
			end
		end)
	end

	self.inst:ListenForEvent("seasontick", OnSeasonTick, TheWorld)
end)

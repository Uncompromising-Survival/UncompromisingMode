local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("temperature", function(self)
	local _DoDelta = self.DoDelta

	function self:DoDelta(delta)
		local inst = self.inst
		local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		if hat and hat.prefab == "um_hat_pepperdragon" then
			if hat.components.fueled then
				hat.components.fueled:DoDelta(-math.abs(delta),inst)
			end
			delta = -delta
		end
		return _DoDelta(self,delta)
	end


	local _OnUpdate = self.OnUpdate

	local updatecoef = 0.001 -- Coefficient for tuning the lost durability for onupdate, a majority of temperature handling is done through onupdate instead of dodelta
	function self:OnUpdate(dt, applyhealthdelta)
		local inst = self.inst
		local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
		if hat and hat.prefab == "um_hat_pepperdragon" then
			local old_current = self.current
			_OnUpdate(self,dt,applyhealthdelta)

			-- Whatever we just did, do it backwards
			local new_current = self.current
			local diff = new_current-old_current
			local mintemp = self.mintemp
			local maxtemp = self.maxtemp
			
			local delta = math.clamp(old_current-diff, mintemp, maxtemp)
			self:SetTemperature(delta)
			if hat.components.fueled then
				hat.components.fueled:DoDelta(-math.abs(delta)*updatecoef,inst)
			end
			
		else
			_OnUpdate(self,dt,applyhealthdelta)
		end
	end
end)

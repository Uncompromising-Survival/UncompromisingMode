local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("temperature", function(self)
	local _DoDelta = self.DoDelta
	
	function self:DoDelta(delta)
		local inst = self.inst
		local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab
		if hat and hat == "um_hat_pepperdragon" then
			delta = -delta
		end
		return _DoDelta(self,delta)
	end
	
	
	local _OnUpdate = self.OnUpdate
	
	function self:OnUpdate(dt, applyhealthdelta)
		local inst = self.inst
		local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab
		if hat and hat == "um_hat_pepperdragon" then
			local old_current = self.current
			_OnUpdate(self,dt,applyhealthdelta)
			
			-- Whatever we just did, do it backwards
			local new_current = self.current
			local diff = new_current-old_current
			local mintemp = self.mintemp
			local maxtemp = self.maxtemp
			self:SetTemperature(math.clamp(old_current-diff	, mintemp, maxtemp))	
		else
			_OnUpdate(self,dt,applyhealthdelta)
		end
	end
end)	

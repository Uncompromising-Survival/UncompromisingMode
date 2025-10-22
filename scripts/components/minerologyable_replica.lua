local Minerologyable = Class(function(self, inst)
    self.inst = inst
    self._enchantnum = net_smallbyte(inst.GUID, "minerologyable._enchantnum")
	self._chilling = net_smallbyte(inst.GUID, "minerologyable._chilling")
end)

function Minerologyable:SetEnchantClient(num)
    self._enchantnum:set(num)
end

function Minerologyable:SetChillingClient(chilling)
	local inst = self.inst 
	if chilling then
		if not inst:HasTag("show_spoilage") then
			inst:AddTag("show_spoilage")
			inst:AddTag("icebox_valid")
		end
	elseif inst:HasTag("show_spoilage") then
		inst:RemoveTag("show_spoilage")
		inst:RemoveTag("icebox_valid")
	end
	
end

return Minerologyable

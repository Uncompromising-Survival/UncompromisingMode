if not GLOBAL.TheNet:GetIsServer() then return end

AddComponentPostInit("fillable", function(self)
	local _fill = self.Fill
	
	function self:Fill(from_object)
		if from_object and from_object:HasTag("lava") and self and not self.inst:HasTag("um_bucket") then
			local x,y,z = self.inst.Transform:GetWorldPosition()
			GLOBAL.SpawnPrefab("ash").Transform:SetPosition(x,y,z)
			self.inst:Remove()
		else
			return _fill(self,from_object)
		end
	end
end)

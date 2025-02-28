local Um_Activatable_Item = Class(function(self, inst)
    self.inst = inst
end)


function Um_Activatable_Item:Activate(doer)
    if doer ~= nil then
		if self.act_fn ~= nil then
			self.act_fn(self.inst, doer)
			return true
		end
    end
end

return Um_Activatable_Item
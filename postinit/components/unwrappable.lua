env.AddComponentPostInit("unwrappable", function(self)
    local _UnWrap = self.Unwrap
	
    function self:Unwrap(doer)
		if self.inst.timebundled then
			local time_since_bundled = (GLOBAL.TheWorld.state.time+GLOBAL.TheWorld.state.cycles)*8*60 - self.inst.timebundled
			if self.itemdata then
				for i, v in ipairs(self.itemdata) do
					if v.data and v.data.perishable then
						local self = v.data.perishable
						if self.time - time_since_bundled > 0 then --If the amount of time that has passed is too much for perishable to handle, go ahead and make the item rot.
							self.time = self.time - time_since_bundled
						else
							self.time = 0
						end
					end
				end
			end
		end
		_UnWrap(self,doer)
    end
end)
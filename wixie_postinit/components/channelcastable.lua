local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("channelcastable", function(self)

	local function OnUnequipped(inst)
		inst.components.channelcastable:StopChanneling()
	end

	local _OldOnStartChanneling = self.OnStartChanneling
	
	function self:OnStartChanneling(user)
		if self.inst:HasTag("wixie_weapon") then
			if user ~= self.user then
				self:OnStopChanneling(self.user)

				if user and user.components.channelcaster and user:IsValid() then
					self.user = user

					self.inst:ListenForEvent("unequipped", OnUnequipped)

					if self.onstartchannelingfn then
						self.onstartchannelingfn(self.inst, user)
					end
				end
			end
		else
			return _OldOnStartChanneling(self, user)
		end
	end

	local _OldOnStopChanneling = self.OnStopChanneling
	
	function self:OnStopChanneling(user)
		if self.inst:HasTag("wixie_weapon") then
			if user and user == self.user then
				self.user = nil

				self.inst:RemoveEventCallback("unequipped", OnUnequipped)

				if self.onstopchannelingfn then
					self.onstopchannelingfn(self.inst, user)
				end
			end
		else
			return _OldOnStopChanneling(self, user)
		end
	end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")


-- klei does not have an easy way to access "bits" in the "Shave" function....
-- I created a duplicate function essentially that's called if direct deposit is enabled.
-- For everything else, the vanilla Shave function runs, hopefully limiting any issues if klei decides to update this component

env.AddComponentPostInit("beard", function(self)
	local _Shave = self.Shave	
	function self:Shave(who, withwhat)
		if self.direct_deposit and who and who.components.inventory then
			if self.bits == 0 then
				return false, "NOBITS"
			elseif self.canshavetest ~= nil then
				local pass, reason = self.canshavetest(self.inst, who)
				if not pass then
					return false, reason
				end
			end

			
			local oldbits = self.bits
			local currentflag = true
			local daysback = 0

			--print("Shave from",self.daysgrowth)
			for k = self.daysgrowth, 0, -1 do

				local cb = self.callbacks[k]
				if cb ~= nil then
					--skip past current level
					if currentflag == true then
						currentflag = false
					else
						cb(self.inst, self.skinname)
						break
					end
				end
				daysback = daysback +1
			end

			self.daysgrowth = self.daysgrowth - daysback

			if self.daysgrowth <= 0 then
				self:Reset()
			end

			local dropbits = oldbits - self.bits

			if self.prize ~= nil then
				for k = 1 , dropbits do
					local bit = SpawnPrefab(self.prize) -- need access to this....
					who.components.inventory:GiveItem(bit,nil,self.inst:GetPosition())
				end
			end

			if who == self.inst and who.components.sanity ~= nil then
				who.components.sanity:DoDelta(TUNING.SANITY_SMALL)
			end

			self:UpdateBeardInventory()

			self.inst:PushEvent("shaved")

			return true
		else
			_Shave(self,who, withwhat)
		end
	end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------Fire spread is less efficient in winter-----------------------------------------
env.AddComponentPostInit("burnable", function(self)
	local _OldExtendBurning = self.ExtendBurning
	local _OldStartWildfire = self.StartWildfire

	local function DoneBurning(inst, self)
		local isplant = inst:HasTag("plant") and
			not (inst.components.diseaseable ~= nil and inst.components.diseaseable:IsDiseased())
		local pos = isplant and inst:GetPosition() or nil

		inst:PushEvent("onburnt")

		if self.onburnt ~= nil then
			self.onburnt(inst)
		end

		if inst.components.explosive ~= nil then
			inst.components.explosive:OnBurnt()
		end

		if self.extinguishimmediately then
			self:Extinguish()
		end

		if isplant then
			TheWorld:PushEvent("plantkilled", { pos = pos })
		end
	end

	function self:ExtendBurning()
		if TheWorld.state.season == "winter" then
			if self.task ~= nil then
				self.task:Cancel()
			end
			self.task = self.burntime ~= nil and self.inst:DoTaskInTime(self.burntime * 0.24, DoneBurning, self) or nil
		else
			return _OldExtendBurning(self)
		end
	end

	function self:StartWildfire()
		local x, y, z = self.inst.Transform:GetWorldPosition()
		print(#TheSim:FindEntities(x, y, z, 12, { "canopy" }) <= 0)
		print(TheWorld:HasTag("heatwavestart"))
		print(self.inst:HasTag("plant"))
		if #TheSim:FindEntities(x, y, z, 12, { "canopy" }) <= 0 or TheWorld:HasTag("heatwavestart") then
			return _OldStartWildfire(self)
		end
	end

	function self:StartSmoldering() --copy of old StartWildfire, without the limitations imposed above.
		if not (self.burning or self.smoldering or self.inst:HasTag("fireimmune")) then
			self.smoldering = true
			if self.onsmoldering then
				self.onsmoldering(self.inst)
			end

			self.smoke = SpawnPrefab("smoke_plant")
			if self.smoke ~= nil then
				if #self.fxdata == 1 and self.fxdata[1].follow then
					if self.fxdata[1].followaschild then
						self.inst:AddChild(self.smoke)
					end
					local follower = self.smoke.entity:AddFollower()
					local xoffs, yoffs, zoffs = self.fxdata[1].x, self.fxdata[1].y, self.fxdata[1].z
					if self.fxoffset ~= nil then
						xoffs = xoffs + self.fxoffset.x
						yoffs = yoffs + self.fxoffset.y
						zoffs = zoffs + self.fxoffset.z
					end
					follower:FollowSymbol(self.inst.GUID, self.fxdata[1].follow, xoffs, yoffs, zoffs)
				else
					self.inst:AddChild(self.smoke)
				end
				self.smoke.Transform:SetPosition(0, 0, 0)
			end

			self.smoldertimeremaining =
				self.inst.components.propagator ~= nil and
				self.inst.components.propagator.flashpoint or
				math.random(TUNING.MIN_SMOLDER_TIME, TUNING.MAX_SMOLDER_TIME)

			if self.smolder_task ~= nil then
				self.smolder_task:Cancel()
			end
			self.smolder_task = self.inst:DoPeriodicTask(SMOLDER_TICK_TIME, SmolderUpdate,
				math.random() * SMOLDER_TICK_TIME, self)
		end
	end
end)

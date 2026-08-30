local env = env
GLOBAL.setfenv(1, GLOBAL)

--local UpvalueHacker = require("tools/upvaluehacker")

-- passive inspiration gain
TUNING.DSTU.INSPIRATION_LUNAR_GAIN_RATE = 0.35
TUNING.DSTU.INSPIRATION_LUNAR_GAIN_MAX = (100 * 1 / 6) +1 -- INSPIRATION_MAX * BATTLESONG_THRESHOLDS[1] + ROUNDING_FIX

TUNING.DSTU.INSPIRATION_LUNAR_RIDING_GAIN_RATE = 0.7
TUNING.DSTU.INSPIRATION_LUNAR_RIDING_GAIN_MAX = (100 * 3 / 6) + 1 -- INSPIRATION_MAX * BATTLESONG_THRESHOLDS[2]


env.AddComponentPostInit("singinginspiration", function(self)
    if not TheWorld.ismastersim then return end

	self.buffertimemultipliers = SourceModifierList(self.inst) 

	self.drainratemultipliers = SourceModifierList(self.inst) 

	function self:OnUpdate(dt)
		local current_time = GetTime()
	
		if self.last_attack_time ~= nil and (current_time - self.last_attack_time >= ( TUNING.INSPIRATION_DRAIN_BUFFER_TIME * self.buffertimemultipliers:Get()) ) then

			local delta = TUNING.INSPIRATION_DRAIN_RATE * dt * self.drainratemultipliers:Get()

			local _skilltreeupdater = self.inst ~= nil and self.inst.components.skilltreeupdater or nil
			if _skilltreeupdater ~= nil and _skilltreeupdater:IsActivated("wathgrithr_allegiance_lunar") then
				local min = TUNING.DSTU.INSPIRATION_LUNAR_GAIN_MAX

				if (self.current <= min) then
					self.is_draining = false
					return
				end
				if (self.current + delta) < min then
					delta = min - self.current
				end
			end
			self.is_draining = true
			self:DoDelta(delta)
		else
			self.is_draining = false
		end
	end

	function self:OnRidingTick(dt)
		self.is_draining = false
		self.last_attack_time = GetTime()

		local max
		local delta

		local _skilltreeupdater = self.inst ~= nil and self.inst.components.skilltreeupdater or nil
		if _skilltreeupdater ~= nil and _skilltreeupdater:IsActivated("wathgrithr_allegiance_lunar") then

			max = TUNING.DSTU.INSPIRATION_LUNAR_RIDING_GAIN_MAX
			if self.current >= max then
				return
			end
			delta = TUNING.DSTU.INSPIRATION_LUNAR_RIDING_GAIN_RATE * dt
		else
			max = TUNING.INSPIRATION_RIDING_GAIN_MAX
			if self.current >= max then
				return
			end
			delta = TUNING.INSPIRATION_RIDING_GAIN_RATE * dt
		end

		if (self.current + delta) > max then
			delta = max - self.current
		end

		if delta > 0 then
			self:DoDelta(delta)
		end
	end

	function self:OnLunarTick(dt)
		local max = TUNING.DSTU.INSPIRATION_LUNAR_GAIN_MAX

		if self.current >= max then
			return
		end

		self.is_draining = false
		self.last_attack_time = GetTime()

		local delta = TUNING.DSTU.INSPIRATION_LUNAR_GAIN_RATE * dt

		if (self.current + delta) > max then
			delta = max - self.current
		end

		if delta > 0 then
			self:DoDelta(delta)
		end
	end
	
end)

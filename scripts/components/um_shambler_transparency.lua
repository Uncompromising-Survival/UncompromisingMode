--NOTE: This is a client side component. No server
--      logic should be driven off this component!

local function PushAlpha(self, alpha, most_alpha)
	self.inst.AnimState:OverrideMultColour(0, 0, 0, alpha)
	if self.inst.SoundEmitter ~= nil then
		self.inst.SoundEmitter:OverrideVolumeMultiplier(alpha / most_alpha)
	end
	if self.onalphachangedfn ~= nil then
		self.onalphachangedfn(self.inst, alpha, most_alpha)
	end
end

local Um_Shambler_Transparency = Class(function(self, inst)
	self.inst = inst
	self.offset = math.random()
	self.osc_speed = .25 + math.random() * 2
	self.osc_amp = .25 --amplitude
	self.alpha = 0
	self.most_alpha = .4
	self.target_alpha = nil
	self.forcedtarget_alpha = nil
	
	self.tag = "shambler_target"

	--PushAlpha(self, 0, .4)
	inst:StartUpdatingComponent(self)

	self.inst.AnimState:UsePointFiltering(true)
end)

function Um_Shambler_Transparency:OnUpdate(dt)
	self:DoUpdate(dt, false)
end

function Um_Shambler_Transparency:ForceUpdate()
	self:DoUpdate(0, true)
end

function Um_Shambler_Transparency:DoUpdate(dt, force)

	self.offset = self.offset + dt

	if ThePlayer ~= nil and ThePlayer:HasTag(self.tag) then
		self.target_alpha = 1
	else
		self.target_alpha = 0
	end
		
	if force then
		self.alpha = self.target_alpha
		PushAlpha(self, self.alpha, self.most_alpha)
	elseif self.alpha ~= self.target_alpha then
		self.alpha = self.alpha > self.target_alpha and
			math.max(self.target_alpha, self.alpha - dt) or
			math.min(self.target_alpha, self.alpha + dt)
		PushAlpha(self, self.alpha, self.most_alpha)
	end
end

function Um_Shambler_Transparency:GetDebugString()
	return "alpha = "..self.alpha
end

return Um_Shambler_Transparency

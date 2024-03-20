local UM_ShadowCloaked = Class(function(self, inst)
    self.inst = inst
	self.shadowlevel = 0
	self.cloakregen = true
	self.shieldscale = 1
	
	self.inst.shadow_cloaked_event = self.inst:ListenForEvent("attacked", function()
		if self.inst.components.health.redirect ~= nil and self.inst.um_cloaksmoke then
			local fx = SpawnPrefab("um_shadowcloaked_shield"..math.random(3))
			fx.entity:SetParent(self.inst.entity)
			fx.AnimState:SetScale(self.shieldscale, self.shieldscale, self.shieldscale)
		end
	end)
			
	self.inst:StartUpdatingComponent(self)
end)

function UM_ShadowCloaked:DoDelta(amount)
    self.shadowlevel = self.shadowlevel + amount
end

local function onremovesmoke(smoke)
    smoke._owner.um_cloaksmoke = nil
end

local function onremovesmoke_2(smoke)
    smoke._owner.um_cloaksmoke_2 = nil
end

local function onremovelight(light)
    light._owner.um_shadowcloaked_light = nil
end

function UM_ShadowCloaked:HasShield()
	return self.inst.um_cloaksmoke
end

function UM_ShadowCloaked:SetOnCloakAdded(addedfn)
	self.cloakaddedfn = addedfn
end

function UM_ShadowCloaked:SetOnCloakRemoved(removedfn)
	self.cloakremovedfn = removedfn
end

function UM_ShadowCloaked:AddSmokeCloud()
	if self.inst.um_cloaksmoke == nil then
		if self.cloakaddedfn ~= nil then
			self.cloakaddedfn(self.inst)
		end
	
		local smoke_emitter = SpawnPrefab("um_shadowcloaked_smoke")
		smoke_emitter.entity:SetParent(self.inst.entity)
		smoke_emitter._owner = self.inst
		
		self.inst.um_cloaksmoke = smoke_emitter
		self.inst:ListenForEvent("onremove", onremovesmoke, self.inst.um_cloaksmoke)
	end
end

function UM_ShadowCloaked:RemoveSmokeCloud()
	if self.inst.um_cloaksmoke ~= nil then
		if self.cloakremovedfn ~= nil then
			self.cloakremovedfn(self.inst)
		end
		
		if self.inst.SoundEmitter then
			self.inst.SoundEmitter:PlaySound("dontstarve/common/fireOut")
		end

		self.inst.um_cloaksmoke:Remove()
		self.inst.um_cloaksmoke = nil
		
		if self.inst.components.health ~= nil then
			--if self.inst._cloak_old_health_redirect ~= nil then
				--self.inst.components.health.redirect = self.inst._cloak_old_health_redirect
			--else
				self.inst.components.health.redirect = nil
			--end
		end
	end
end

local function nodmgshielded(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    --return amount <= 0 and not ignore_absorb and (inst._cloak_old_health_redirect == nil or inst._cloak_old_health_redirect)
    return amount <= 0 and not ignore_absorb and inst._cloak_old_health_redirect == nil
end

function UM_ShadowCloaked:OnUpdate(dt)
	if self.inst ~= nil then
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local light = TheSim:GetLightAtPoint(x, y, z, .1)
		
		if light > .4 then
			--print("Burning the shadow cloak with "..light.." power")
			self.shadowlevel = self.shadowlevel - (dt * (1 + light))
			
			if self.inst.um_cloaksmoke ~= nil then
				if not self.inst.um_cloaksmoke.SoundEmitter:PlayingSound("smolder") then
					if self.inst.um_shadowcloaked_light == nil then
						local light_emitter = SpawnPrefab("um_shadowcloaked_light")
						light_emitter.entity:SetParent(self.inst.entity)
						light_emitter._owner = self.inst
						
						self.inst.um_shadowcloaked_light = light_emitter
						self.inst:ListenForEvent("onremove", onremovelight, self.inst.um_shadowcloaked_light)
					end
					
					self.inst.um_cloaksmoke.SoundEmitter:PlaySound("dontstarve_DLC001/summer/smolder", "smolder")
				elseif self.inst.um_cloaksmoke.SoundEmitter:PlayingSound("smolder") and self.shadowlevel <= 0 then
					if self.inst.um_shadowcloaked_light ~= nil then
						self.inst.um_shadowcloaked_light:Remove()
						self.inst.um_shadowcloaked_light = nil
					end
					
					self.inst.um_cloaksmoke.SoundEmitter:KillSound("smolder")
				end
			end
		else
			if self.shadowlevel < 10 then
				if self.cloakregen then
					self.shadowlevel = self.shadowlevel + .1--dt
				end
			
				if self.inst.um_cloaksmoke ~= nil then
					if self.inst.um_cloaksmoke.SoundEmitter:PlayingSound("smolder") then
						if self.inst.um_shadowcloaked_light ~= nil then
							self.inst.um_shadowcloaked_light:Remove()
							self.inst.um_shadowcloaked_light = nil
						end
					
					
						self.inst.um_cloaksmoke.SoundEmitter:KillSound("smolder")
					end
				end
			else
				self.shadowlevel = 10
			end
		end
		
		if self.shadowlevel <= 0 then
			self:RemoveSmokeCloud()
		elseif self.shadowlevel >= 10 then
			if self.inst.components.health ~= nil then
				--[[if self.inst.components.health.redirect ~= nil and self.inst._cloak_old_health_redirect == nil then
					self.inst._cloak_old_health_redirect = self.inst.components.health.redirect
				end]]
				
				self.inst.components.health.redirect = nodmgshielded
			end
			
			self:AddSmokeCloud()
		end
	end
end

function UM_ShadowCloaked:OnSave()
    local data = {}

    data.shadowlevel = self.shadowlevel

    return data
end

function UM_ShadowCloaked:OnLoad(data)
	if data then
        if data.shadowlevel ~= nil then
			self.shadowlevel = data.shadowlevel
		end
	end
end

return UM_ShadowCloaked

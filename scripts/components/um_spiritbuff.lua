local UM_SpiritBuff = Class(function(self, inst)
    self.inst = inst
	self.old_defaultdamage = nil
	self.old_attackrange = nil
	self.old_hitrange = nil
	self.old_min_attack_period = nil
	self.buffed = false
	self.chance_to_evolve = math.random()
	
	if self.chance_to_evolve <= 0.2 then
		self:Initialize(self.inst)
		self.inst:StartUpdatingComponent(self)
	end
end)

function UM_SpiritBuff:Initialize(inst)
	if inst.components.combat then
		self.old_defaultdamage = inst.components.combat.defaultdamage
		self.old_attackrange = inst.components.combat.attackrange
		self.old_hitrange = inst.components.combat.hitrange
		self.old_min_attack_period = inst.components.combat.min_attack_period
	end
	
	if inst.components.locomotor then
		self.old_runspeed = inst.components.locomotor.runspeed
		self.old_walkspeed = inst.components.locomotor.walkspeed
	end
end

function UM_SpiritBuff:OnEntitySleep()
	if self.chance_to_evolve <= 0.2 then
		self.inst:StopUpdatingComponent(self)
	end
end

function UM_SpiritBuff:OnEntityWake()
	if self.chance_to_evolve <= 0.2 then
		self.inst:StartUpdatingComponent(self)
	end
end

function UM_SpiritBuff:OnUpdate(dt)
	if self.inst ~= nil then
		if self.inst.components.combat ~= nil then
			if self.inst.components.combat.target ~= nil and self.inst.components.combat.target:HasTag("wathgrithr_vetcurse") then
				
				if not self.buffed then
					local fx = SpawnPrefab("oldager_become_younger_front_fx")
					fx.entity:SetParent(self.inst.entity)
				end
				
				self.buffed = true
	
				if self.old_defaultdamage ~= nil then
					self.inst.components.combat:SetDefaultDamage(self.old_defaultdamage * 1.25)
				end

				if self.old_attackrange ~= nil then
					self.inst.components.combat.attackrange = self.old_attackrange * 1.25
				end

				if self.old_hitrange ~= nil then
					self.inst.components.combat.hitrange = self.old_hitrange * 1.25
				end

				if self.old_min_attack_period ~= nil and not self.inst:HasTag("epic") then
					self.inst.components.combat.min_attack_period = self.old_min_attack_period * 0.75
				end
				
				self.inst.AnimState:SetScale(1.25, 1.25, 1.25)
	
				if self.inst.components.locomotor then
					self.inst.components.locomotor.runspeed = self.old_runspeed * 1.25
					self.inst.components.locomotor.walkspeed = self.old_walkspeed * 1.25
				end
			else				
				if self.buffed then
					local fx = SpawnPrefab("oldager_become_older_fx")
					fx.entity:SetParent(self.inst.entity)
				end
				
				self.buffed = false
	
				if self.old_defaultdamage ~= nil then
					self.inst.components.combat:SetDefaultDamage(self.old_defaultdamage)
					--self.inst.components.combat.defaultdamage = self.old_defaultdamage
				end

				if self.old_attackrange ~= nil then
					self.inst.components.combat.attackrange = self.old_attackrange
				end

				if self.old_hitrange ~= nil then
					self.inst.components.combat.hitrange = self.old_hitrange
				end

				if self.old_min_attack_period ~= nil and not self.inst:HasTag("epic") then
					self.inst.components.combat.min_attack_period = self.old_min_attack_period
				end
				
				self.inst.AnimState:SetScale(1, 1, 1)
				--self.inst.Transform:SetScale(1, 1, 1)
	
				if self.inst.components.locomotor then
					self.inst.components.locomotor.runspeed = self.old_runspeed
					self.inst.components.locomotor.walkspeed = self.old_walkspeed
				end
			end
		end
	end
end
return UM_SpiritBuff

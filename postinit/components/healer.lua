local env = env
GLOBAL.setfenv(1, GLOBAL)


-- This postinit exists to support the Walter Veterans Skull Curse -- not anymore, yoink.
env.AddComponentPostInit("healer", function(self)
	if not TheWorld.ismastersim then return end

	local _Heal = self.Heal
	function self:Heal(target, doer, ...)
		if target and target.walter_vetcurse and target.components and target.components.debuffable then
			for i, v in pairs(target.components.debuffable.debuffs) do
				if v and v.inst.prefab == "healthregenbuff_vetcurse_walter_curse" then
					v.inst:Remove()
				end
			end
		end
		if self.health and target:HasTag("vetcurse_wormwood") then
			if self.health > 3 and not self.inst:HasAnyTag("ignores_foodregen", "ignores_healthregen") then
        		target.components.debuffable:AddDebuff("healthregenbuff_vetcurse_"..self.inst.prefab, "healthregenbuff_vetcurse", {duration = (self.health * 0.1)})

				local health = target.components.health
    			if health == nil then
        			return false
    			end

    			if self.canhealfn then
        			local valid, reason = self.canhealfn(self.inst, target, doer)

        			if not valid then
            			return false, reason
        			end
    			end

				if self.onhealfn then
        			self.onhealfn(self.inst, target, doer)
    			end

    			if self.inst.components.stackable and self.inst.components.stackable:IsStack() then
        			self.inst.components.stackable:Get():Remove()
    			else
        			self.inst:Remove()
    			end
				return true
    		end
		end
		return _Heal(self, target, doer, ...)
	end
end)

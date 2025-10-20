local env = env
GLOBAL.setfenv(1, GLOBAL)


-- This postinit exists to support the Walter Veterans Skull Curse
env.AddComponentPostInit("healer", function(self)
	if not TheWorld.ismastersim then return end

	local _Heal = self.Heal
	function self:Heal(target, ...)
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
    		end
			self.health = 0
		end
		return _Heal(self, target, ...)
	end
end)

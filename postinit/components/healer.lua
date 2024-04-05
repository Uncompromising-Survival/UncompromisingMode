local env = env
GLOBAL.setfenv(1, GLOBAL)


-- This postinit exists to support the Walter Veterans Skull Curse
env.AddComponentPostInit("healer", function(self)
	if not TheWorld.ismastersim then return end

	local _Heal = self.Heal
	function self:Heal(target, ...)
		if target ~= nil and target.walter_vetcurse and target.components ~= nil and target.components.debuffable ~= nil then
			for i, v in pairs(target.components.debuffable.debuffs) do
				if v ~= nil and v.inst.prefab == "healthregenbuff_vetcurse_walter_curse" then
					v.inst:Remove()
				end
			end
		end
		
		return _Heal(self, target, ...)
	end
end)

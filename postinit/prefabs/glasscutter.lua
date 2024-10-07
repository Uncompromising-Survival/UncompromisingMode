local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("glasscutter", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	if inst.components.weapon ~= nil then
		local _OnAttack = inst.components.weapon.onattack

		inst.components.weapon:SetOnAttack(function(inst, attacker, target, ...)
			inst.components.weapon.attackwear = target ~= nil and target:IsValid()
				and target:HasTag("shadow_aligned")
				and TUNING.GLASSCUTTER.SHADOW_WEAR
				or 1

			if _OnAttack ~= nil then
				_OnAttack(inst, attacker, target, ...)
			end
		end)
	end

    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, 1+17 / 68)
end)

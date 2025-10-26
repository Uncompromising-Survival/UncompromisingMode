local env = env
GLOBAL.setfenv(1, GLOBAL)

local function OnUse(inst, target)
	if target.components.debuffable and target.components.health and not target.components.health:IsDead() then
		target:AddDebuff("confighealbuff_"..inst.prefab, "confighealbuff", {time = 10})
	end
end


env.AddPrefabPostInit("bandage", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.components.healer.onhealfn = OnUse
end)

env.AddPrefabPostInit("healingsalve_acid", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.components.healer.onhealfn = OnUse
end)
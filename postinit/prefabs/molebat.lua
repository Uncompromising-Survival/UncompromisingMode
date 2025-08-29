local env = env
GLOBAL.setfenv(1, GLOBAL)


env.AddPrefabPostInit("molebat", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local _ShouldSummonAllies = inst.ShouldSummonAllies
	local function ShouldSummonAllies(inst)
		if TheWorld:HasTag("cave") then
			return _ShouldSummonAllies(inst)
		end
	end
	inst.ShouldSummonAllies = ShouldSummonAllies
end)
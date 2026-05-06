local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local BANANABUSH_STAGE_TIME = TUNING.TOTAL_DAY_TIME * 1.25

env.AddPrefabPostInit("bananabush", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	if inst.components.growable ~= nil and inst.components.growable.stages ~= nil then
		for _, stage in ipairs(inst.components.growable.stages) do
			stage.time = function(inst)
				return BANANABUSH_STAGE_TIME
			end
		end
	end
end)

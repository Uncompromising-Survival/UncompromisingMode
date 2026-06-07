local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddPrefabPostInit("forest", function(inst)
    if not TheWorld.ismastersim then
        return
    end

	local function TentacleRegrowth()
		return (
			_worldstate.isspring and TUNING.CACTUS_REGROWTH_TIME_SUMMER_MULT or -- Bloom.
			_worldstate.iswinter and TUNING.CACTUS_REGROWTH_TIME_WINTER_MULT or -- Hibernation.
			TUNING.CACTUS_REGROWTH_TIME_BASE_MULT -- Generic.
		) * (
			_worldstate.israining and TUNING.CACTUS_REGROWTH_RAINING_MULT or 1
		) * TUNING.CACTUS_REGROWTH_TIME_MULT
	end
	
	if inst.components.regrowthmanager ~= nil then
		inst.components.regrowthmanager:SetRegrowthForType("tentacle", TUNING.CACTUS_REGROWTH_TIME, "tentacle", TentacleRegrowth)
	end
end)

env.AddPrefabPostInit("forest", function(inst)
	if not TheWorld.ismastersim then return end

	local function DropGoop(pt)
		local offset = FindWalkableOffset(pt, math.random() * TWOPI, math.random(3, 10), 8, true)
		local x = pt.x + (offset and offset.x or 0)
		local z = pt.z + (offset and offset.z or 0)
		local goop = SpawnPrefab("glommerfuel")
		if goop then
			goop.Physics:Teleport(x, 35, z)
		end
	end

	inst:ListenForEvent("megaflare_detonated", function(src, data)
		if data and data.sourcept and TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) and TheWorld.state.isspring then
			DropGoop(data.sourcept)
		end
	end)

	inst:ListenForEvent("megaflare_guardmet", function(src, data)
		if not (data and data.sourcept) then return end

		if data.iswinter then
			inst:DoTaskInTime(6, function()
				if #TheSim:FindEntities(data.sourcept.x, 0, data.sourcept.z, 60, {"flare_summoned"}) == 0 then
					DropGoop(data.sourcept)
				end
			end)
		else
			DropGoop(data.sourcept)
		end
	end)
end)
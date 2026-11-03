local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
--[[Documentation: Atobá Azul

Makes mushtrees drop spores if they're not blooming. 
Checks season instead of actually blooming because thats easier.
Keeps old copy of loot for mod compat, does not use SetLoot because that clears chanceloot, randomloot and numrandomloot. For some reason.
Uses lootsetupfn to dynamically give it loot based on the season, instead of changing it onseasontick.
]]

--[[Documentation Addendum: Axe
Make some mushtress petrify after they finish their sporing cycle. Checks whenever season ticks.
]]

local function PetrificationDisaster(inst,replacement,range,gemchance)
	local x,y,z = inst.Transform:GetWorldPosition()
	local mushtrees = TheSim:FindEntities(x,y,z,range,{"mushtree"})
	for i,tree in ipairs(mushtrees) do
		if tree.prefab == inst.prefab and inst ~= tree then
			if math.random() < gemchance then
				SpawnPrefab(replacement).Transform:SetPosition(tree.Transform:GetWorldPosition())
			else
				SpawnPrefab(replacement.."less").Transform:SetPosition(tree.Transform:GetWorldPosition())
			end
			tree:Remove()
		end
	end
	SpawnPrefab(replacement).Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
end


if TUNING.DSTU.MUSHROOM_CHANGES then
	local tree_data =
	{
		small =
		{ --Green
			season = SEASONS.SPRING,
			spore = "spore_small",
			loot = { "log" },
			uhohseason = SEASONS.SUMMER,
			replacement = "um_greenmushtree_gem",
			range = 24,
			gemchance = 0.025,
		},
		medium =
		{ --Red
			season = SEASONS.SUMMER,
			spore = "spore_medium",
			loot = { "log" },
			uhohseason = SEASONS.AUTUMN,
			replacement = "um_redmushtree_gem",
			range = 24,
			gemchance = 0.025,
		},
		tall =
		{ --Blue
			season = SEASONS.WINTER,
			spore = "spore_tall",
			loot = { "log", "log", },
			uhohseason = SEASONS.SPRING,
			replacement = "um_bluemushtree_gem",
			range = 16,
			gemchance = 0.025,
		},
	}

	for tree, data in pairs(tree_data) do
		env.AddPrefabPostInit("mushtree_" .. tree, function(inst)
			if not TheWorld.ismastersim then
				return
			end

			local old_loot = deepcopy(inst.components.lootdropper.loot)

			inst.components.lootdropper.lootsetupfn = function(lootdropper)
				if data.season ~= TheWorld.state.season then
					lootdropper.loot = { data.spore, unpack(data.loot), }
				else
					lootdropper.loot = old_loot
				end
			end
			
			inst:WatchWorldState("season", function(inst)
				if data.uhohseason == TheWorld.state.season and math.random() < 0.02 and not inst.entity:IsAwake() then
					PetrificationDisaster(inst,data.replacement,data.range,data.gemchance)
				end			
			end)
			
		end)
	end
end
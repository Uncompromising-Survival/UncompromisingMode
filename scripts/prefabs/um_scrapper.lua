require "prefabutil"

function Default_PlayAnimation(inst, anim, loop)
	inst.AnimState:PlayAnimation(anim, loop)
end

function Default_PushAnimation(inst, anim, loop)
	inst.AnimState:PushAnimation(anim, loop)
end

local function onopen(inst)
	if not inst:HasTag("burnt") then
		inst:AddTag("airconditioneropen")
		inst.AnimState:PlayAnimation("open")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
	end
end

local function onclose(inst)
	if not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("close")
		inst:RemoveTag("airconditioneropen")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
	end
end

local assets =
{
	Asset("ANIM", "anim/rain_meter.zip"),
}

local prefabs =
{
	"collapse_small",
}

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("place")
	inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_place")
	--the global animover handler will restart the check task
end

local function makeburnt(inst)
	inst:RemoveComponent("channelable")
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
		data.burnt = true
	end
end

local function OnCooldown(inst)
	inst._cdtask = nil
end

local function CheckSpawnedLoot(loot)
	if loot.components.inventoryitem ~= nil then
		loot.components.inventoryitem:TryToSink()
	else
		local lootx, looty, lootz = loot.Transform:GetWorldPosition()
		if ShouldEntitySink(loot, true) or TheWorld.Map:IsPointNearHole(Vector3(lootx, 0, lootz)) then
			SinkEntity(loot)
		end
	end
end

local function SpawnLootPrefab(inst, v, lootprefab)
	if lootprefab == nil then
		return
	end

	local loot = SpawnPrefab(lootprefab)
	if loot == nil then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()

	if loot.Physics ~= nil then
		local angle = math.random() * 2 * PI
		loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))

		if v.Physics ~= nil then
			local len = loot:GetPhysicsRadius(0) + v:GetPhysicsRadius(0)
			x = x + math.cos(angle) * len
			z = z + math.sin(angle) * len
		end

		loot:DoTaskInTime(1, CheckSpawnedLoot)
	end

	loot.Transform:SetPosition(x, y, z)

	loot:PushEvent("on_loot_dropped", { dropper = inst })

	return loot
end

local function DoPuff(inst, channeler)
	if inst._cdtask == nil and inst.components.container ~= nil then
		inst._cdtask = inst:DoTaskInTime(1, OnCooldown)
		local recipeitems = inst.components.container:FindItems(function(item) return AllRecipes[item.prefab] ~= nil end)
		local lootcount = 1
		for i, v in ipairs(recipeitems) do
			local recipe = AllRecipes[v.prefab]
			if recipe == nil or FunctionOrValue(recipe.no_deconstruction, v) then
				--Action filters should prevent us from reaching here normally
				return
			end

			local ingredient_percent =
				((v.components.finiteuses ~= nil and v.components.finiteuses:GetPercent()) or
					(v.components.fueled ~= nil and v.components.inventoryitem ~= nil and v.components.fueled:GetPercent()) or
					(v.components.armor ~= nil and v.components.inventoryitem ~= nil and v.components.armor:GetPercent()) or
					1
				) / recipe.numtogive

			local rollthedice =
				((v:HasTag("vetcurse_item") and 1.5) or
					(v.components.finiteuses ~= nil and math.max(v.components.finiteuses:GetPercent(), 0.5)) or
					(v.components.fueled ~= nil and v.components.inventoryitem ~= nil and math.max(v.components.fueled:GetPercent(), 0.5)) or
					(v.components.armor ~= nil and v.components.inventoryitem ~= nil and math.max(v.components.armor:GetPercent(), 0.5)) or
					(v.components.perishable ~= nil and v.components.inventoryitem ~= nil and math.max(v.components.perishable:GetPercent(), 0.5)) or
					1
				) / recipe.numtogive


			--V2C: Can't play sounds on the staff, or nobody
			--     but the user and the host will hear them!
			for i, v in ipairs(recipe.ingredients) do
				if string.sub(v.type, -3) ~= "gem" or string.sub(v.type, -11, -4) == "precious" then
					--V2C: always at least one in case ingredient_percent is 0%
					local amt = v.amount == 0 and 0 or math.max(1, math.ceil(v.amount --[[* ingredient_percent]]))
					for n = 1, amt do
						if math.random() <= rollthedice / 2 then
							lootcount = lootcount + .1
							inst:DoTaskInTime(lootcount, function()
								if inst ~= nil then
									SpawnLootPrefab(inst, v, v.type)
								end
							end)
						end
					end
				end
			end

			inst.SoundEmitter:PlaySound("dontstarve/common/staff_dissassemble")

			if v.components.inventory ~= nil then
				v.components.inventory:DropEverything()
			end

			if v.components.container ~= nil then
				v.components.container:DropEverything()
			end

			if v.components.spawner ~= nil and v.components.spawner:IsOccupied() then
				v.components.spawner:ReleaseChild()
			end

			if v.components.occupiable ~= nil and v.components.occupiable:IsOccupied() then
				local item = v.components.occupiable:Harvest()
				if item ~= nil then
					item.Transform:SetPosition(v.Transform:GetWorldPosition())
					item.components.inventoryitem:OnDropped()
				end
			end

			if v.components.trap ~= nil then
				v.components.trap:Harvest()
			end

			if v.components.dryer ~= nil then
				v.components.dryer:DropItem()
			end

			if v.components.harvestable ~= nil then
				v.components.harvestable:Harvest()
			end

			if v.components.stewer ~= nil then
				v.components.stewer:Harvest()
			end

			v:PushEvent("ondeconstructstructure", channeler)

			if v.components.stackable ~= nil then
				--if it's stackable we only want to destroy one of them.
				v.components.stackable:Get():Remove()
			else
				v:Remove()
			end
		end

		local fooditems = inst.components.container:FindItems(function(item) return item:HasTag("preparedfood") end)

		for i, v in ipairs(fooditems) do
			local cube = "um_bland_cube"
			local ed_comp = v.components.edible

			if v.prefab == "dustmeringue" then
				cube = "refined_dust"
			else
				if ed_comp.foodtype == "MEAT" then
					if ed_comp.secondaryfoodtype == "MONSTER" then
						cube = "um_monster_cube"
					else
						cube = "um_meat_cube"
					end
				elseif ed_comp.foodtype == "VEGGIE" then
					cube = "um_veggie_cube"
				elseif ed_comp.foodtype == "GOODIES" then
					cube = "um_sugar_cube"
				elseif ed_comp.foodtype == "ROUGHAGE" then
					cube = "um_roughage_cube"
				end
			end

			local stat_count = (ed_comp:GetHealth() + ed_comp:GetSanity() + ed_comp:GetHunger()) / 50
			local cube_count = 1 + stat_count

			if cube_count < 1 then
				cube_count = 1
			end

			for i = 1, cube_count do
				lootcount = lootcount + .1
				inst:DoTaskInTime(lootcount, function()
					if inst ~= nil then
						SpawnLootPrefab(inst, v, cube)
					end
				end)
			end

			v:Remove()
		end

		inst:_PlayAnimation("idle_fueled")

		inst.components.container:DropEverything()
	end

	inst.components.channelable:StopChanneling(true)
end

local function onhammered(inst, worker)
	if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
		inst.components.burnable:Extinguish()
	end
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function onhit(inst)
	if not inst.AnimState:IsCurrentAnimation("idle_fueled") then
		inst.AnimState:PlayAnimation("hit")
	end

	if inst.components.container ~= nil then
		inst.components.container:DropEverything()
		inst.components.container:Close()
	end
end

local function onload(inst, data)
	if data ~= nil and data.burnt then
		inst.components.burnable.onburnt(inst)
	end
end

local function OnStopChanneling(inst)
	if inst.channeler ~= nil then
		--inst.channeler.sg:GoToState("idle")
	end
	inst.channeler = nil
end

local function OnRefuseItem(inst, giver, item)
	--inst.sg:GoToState("unimpressed")
end

local function AbleToAcceptTest(inst, item, giver)
	if AllRecipes[item.prefab] ~= nil then
		--OnRefuseItem(inst, giver, item)
		return true
	end

	return false
end

local function AcceptTest(inst, item, giver)
	return AllRecipes[item.prefab] ~= nil
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .4)
	inst.MiniMapEntity:SetIcon("um_scrapper.tex")

	inst.AnimState:SetBank("airconditioner")
	inst.AnimState:SetBuild("airconditioner")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("air_conditioner")
	inst:AddTag("structure")
	inst:AddTag("chest")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst)
			if inst.replica.container ~= nil then
				inst.replica.container:WidgetSetup("um_scrapper")
			end
		end
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
	MakeSnowCovered(inst)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("um_scrapper")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst:AddComponent("channelable")
	inst.components.channelable:SetChannelingFn(DoPuff, OnStopChanneling)
	inst.components.channelable.use_channel_longaction = true
	inst.components.channelable.skip_state_stopchanneling = true
	inst.components.channelable.skip_state_channeling = true
	inst.components.channelable.ignore_prechannel = true

	inst:ListenForEvent("onbuilt", onbuilt)

	MakeMediumBurnable(inst, nil, nil, true)
	MakeSmallPropagator(inst)
	inst:ListenForEvent("burntup", makeburnt)

	MakeHauntableWork(inst)

	inst._PlayAnimation = Default_PlayAnimation
	inst._PushAnimation = Default_PushAnimation

	return inst
end

return Prefab("um_scrapper", fn, assets, prefabs),
	MakePlacer("um_scrapper_placer", "airconditioner", "airconditioner", "idle")

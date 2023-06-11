local prefabs = {
	"um_pyre_nettles",
	"houndfire"
}


--local onsurface = false
--local oncave = false
--local function WorldCheck(inst)
--	if TheWorld:HasTag("forest") then
--		onsurface = true
--	end
--	if TheWorld:HasTag("cave") then
--		oncave = true
--	end
--end


-- These tiles are where Smolder Spores can survive, when it isn't Summer.
-- ALL NON-MAGMA MAGMA CAVES TURFS SHOULD GO HERE.
local HOME_TILES =
{
	[WORLD_TILES.OCEAN_WATERLOG] = true, -- PLACEHOLDER
	--	[WORLD_TILES.MAGMA_ASH] = true,
	--	[WORLD_TILES.MAGMA_ROCK] = true,
	--	[WORLD_TILES.MAGMAFIELD] = true,
}


-- Use lootdropper to drop hound fires in a natural-looking way.
SetSharedLootTable('um_smolder_spore',
	{
		{ 'houndfire', 1.0 },
		{ 'houndfire', 1.0 },
		{ 'houndfire', 0.5 },
		{ 'houndfire', 0.25 },
		{ 'smog',      1.0 }
	})


-- This prefab just isn't complicated enough to need seperate files for movement. One block of code suffices.
local function SimpleWander(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		if math.random() > 0.5 then
			inst.components.locomotor:RunInDirection(math.random(1, 359))
			inst.components.locomotor:RunForward()
			inst:DoTaskInTime(math.random(4, 7), function()
				inst.components.locomotor:Stop()
			end)
		end
	end
end


local function PlantSelf(inst)
	local blockers = FindClosestEntity(inst, 1, true, { "blocker" },
		{ "invisible", "notarget", "noattack", "playerghost" })
	local nettlescrowding = FindClosestEntity(inst, 2, true, { "PyreNettle" })
	local x, y, z = inst.Transform:GetWorldPosition()
	local findnettles = TheSim:FindEntities(x, y, z, 50, { "PyreNettle" })

	if not inst:HasTag("BUSYSMOLDERSPORE")
		and blockers == nil
		and nettlescrowding == nil
		and #findnettles < 32
	then
		inst:AddTag("BUSYSMOLDERSPORE")

		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("divebomb", false)
		inst:ListenForEvent("animover", function()
			if TheWorld.Map:IsPassableAtPoint(x, y, z) then
				SpawnPrefab("um_pyre_nettles").Transform:SetPosition(x, y, z)
			end
			inst:DoTaskInTime(0, function()
				inst:Remove()
			end)
		end)
	end

	-- If the planting failed, wait a bit and try again.
	inst:DoTaskInTime(10, PlantSelf)
end


-- Spread some fire around!
local function FireSpread(inst)
	-- We make the spore uninterractable past this point, because it should be visually destroying itself by the time we get here.
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")
	inst:AddTag("noattack")

	-- Instantly ignites anything flammable within a radius.
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, nil,
		{ "FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	for i, v in pairs(ents) do
		if v.components.burnable ~= nil then
			v.components.burnable:Ignite()
		end
	end

	-- Slight AoE damage. Mainly to set off other nearby Smolder Spores.
	inst.components.combat:DoAreaAttack(inst, 3, nil, nil, nil,
		{ "SmolderSporeAvoid", "BUSYSMOLDERSPORE", "INLIMBO", "invisible", "notarget", "noattack" })

	inst.components.lootdropper:DropLoot(inst:GetPosition())
end


-- Suddenly pop!
local function PopSpore(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		inst:AddTag("BUSYSMOLDERSPORE")

		if inst.components.locomotor ~= nil then
			inst.components.locomotor:Stop()
		end

		inst.AnimState:PlayAnimation("explode", false)

		FireSpread(inst)
		inst:DoTaskInTime(2, function()
			inst:Remove()
		end)
	end
end

-- Divebomb the ground and explode!
local function Divebomb(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		inst:AddTag("BUSYSMOLDERSPORE")

		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("divebomb", false)
		inst:ListenForEvent("animover", function()
			inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/firehound_explo")
			SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())

			FireSpread(inst)
			inst:DoTaskInTime(1, function()
				inst:Remove()
			end)
		end)
	end
end

-- Check if we're in range of a suitable target.
local function TargetCheck(inst)
	local nextvictim = FindClosestEntity(inst, 1, true, nil,
		{ "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })

	if not inst:HasTag("BUSYSMOLDERSPORE")
		and nextvictim ~= nil
		and nextvictim.components.burnable ~= nil
		and not nextvictim:HasTag("plantkin")
		and not (nextvictim.components.health ~= nil and nextvictim.components.health:IsDead())
		and not (nextvictim:HasTag("SmolderSporeAvoid") and math.random() > 0.01) -- This keeps them from constantly seeking pyre nettles.
		and (nextvictim:HasTag("player") or math.random() > 0.5)            -- For anything but a player, chance to not activate.
	then
		Divebomb(inst)
	end
end

-- Check if we're allowed to be where we are.
local function TurfCheck(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tile_at_position = TheWorld.Map:GetTileAtPoint(x, y, z)

	if not HOME_TILES[tile_at_position] then
		Divebomb(inst)
	end
end

-- What happens when caught via bug net.
local function OnWorked(inst, worker)
	if worker.components.inventory ~= nil then
		worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
		worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
	end
end


-- Wormwood planting a spore.
local function OnDeploy(inst, pt)
	local plant = SpawnPrefab("um_pyre_nettles")
	plant.Transform:SetPosition(pt.x, 0, pt.z)
	plant.SoundEmitter:PlaySound("dontstarve/wilson/plant_seeds")
	inst:Remove()
end


local function OnPerish(inst)
	if inst.components.inventoryitem:IsHeld() then
		local holder = inst.components.inventoryitem:GetGrandOwner()

		if holder.components.talker ~= nil and holder.components.health ~= nil and not holder.components.health:IsDead() then
			holder.components.talker:Say(GetString(holder, "ANNOUNCE_SMOLDER_SPORE_INVENTORY_POP"))
		end

		SpawnPrefab("um_smolder_spore_pop").Transform:SetPosition(holder.Transform:GetWorldPosition())
		inst:Remove()
	else
		PopSpore(inst)
	end
end


local function OnEaten(inst, eater)
	if eater.components.sanity ~= nil then
		if eater:HasTag("plantkin") then -- The spores are alive. L for canibaLism.
			eater.components.sanity:DoDelta(-10)
		elseif eater.prefab == "wanda" then
			eater.components.sanity:DoDelta(10)
		end
	end

	if eater.components.talker ~= nil and eater.components.health ~= nil and not eater.components.health:IsDead() then
		eater.components.talker:Say(GetString(eater, "ANNOUNCE_SMOLDER_SPORE_EATEN"))
	end

	SpawnPrefab("um_smolder_spore_pop").Transform:SetPosition(eater.Transform:GetWorldPosition())
end


local function TaskStartup(inst)
	if inst.SimpleWanderTask == nil then
		inst.SimpleWanderTask = inst:DoPeriodicTask(9, SimpleWander, 2)
	end
	if inst.TargetCheckTask == nil then
		inst.TargetCheckTask = inst:DoPeriodicTask((FRAMES * 3), TargetCheck, 5)
	end
	if inst.PlantSelfTask == nil then
		inst.PlantSelfTask = inst:DoTaskInTime((math.random(1, 60) * math.random(1, 5)) + 30, PlantSelf)
	end
	if TheWorld.state.season ~= "summer" and inst.TurfCheckTask == nil then
		inst:DoPeriodicTask(10, TurfCheck, 10)
	end
end

local function TaskCancel(inst)
	if inst.SimpleWanderTask ~= nil then
		inst.SimpleWanderTask:Cancel()
		inst.SimpleWanderTask = nil
	end
	if inst.TargetCheckTask ~= nil then
		inst.TargetCheckTask:Cancel()
		inst.TargetCheckTask = nil
	end
	if inst.PlantSelfTask ~= nil then
		inst.PlantSelfTask:Cancel()
		inst.PlantSelfTask = nil
	end
	if inst.TurfCheckTask ~= nil then
		inst.TurfCheckTask:Cancel()
		inst.TurfCheckTask = nil
	end
end


local function OnDropped(inst)
	inst.Light:Enable(true)

	if inst:GetIsWet() then
		PlantSelf(inst)
	end

	TaskStartup(inst)
end

local function OnPickup(inst)
	inst.Light:Enable(false)

	TaskCancel(inst)

	-- Make it take longer to perish if Wormwood is holding it.
	if inst.components.inventoryitem:IsHeld() then
		local holder = inst.components.inventoryitem:GetGrandOwner()

		if holder:HasTag("plantkin") then
			inst.components.perishable:SetLocalMultiplier(TUNING.SEG_TIME * 3 / TUNING.PERISH_SLOW) -- From mushtree_spores.lua.
		end
	end
end


local function OnSeasonChange(inst)
	if TheWorld.state.season == "summer" then
		if inst.TurfCheckTask ~= nil then
			inst.TurfCheckTask:Cancel()
			inst.TurfCheckTask = nil
		end
	elseif inst.TurfCheckTask == nil then
		inst:DoPeriodicTask(10, TurfCheck, 10)
	end
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 1, 0.5)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("um_smolder_spore")
	inst.AnimState:SetBuild("um_smolder_spore")
	inst.Transform:SetScale(1.25, 1.25, 1.25)
	inst.AnimState:PlayAnimation("spawn", false)
	inst.AnimState:PushAnimation("idle", true)

	inst:AddTag("PyreToxinImmune")
	inst:AddTag("soulless") -- Prefab shouldn't die via health loss, but...just in case.
	inst:AddTag("scarytoprey")
	--inst:AddTag("flying")

	inst:AddTag("show_spoilage")

	inst.Light:Enable(true)
	inst.Light:SetRadius(0.5)
	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(0.75)
	inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = 1
	inst.components.locomotor.runspeed = 1
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	inst:AddComponent("inspectable")


	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("um_smolder_spore")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(6)    -- To make it poppable via ranged attacks or earthquake drops.
	inst.components.health:SetMinHealth(1)    -- We don't want it to die a 'normal' death.
	inst.components.health.fire_damage_scale = 0 -- Take no damage from fire.
	inst.components.health.canmurder = false
	inst:ListenForEvent("attacked", PopSpore)
	inst:ListenForEvent("explosion", PopSpore)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(3)

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(Divebomb)

	inst:AddComponent("moisture")
	inst.components.moisture.maxmoisture = 2
	inst:ListenForEvent("moisturedelta", function()
		if inst:GetIsWet() then
			PlantSelf(inst)
		end
	end)

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.TOTAL_DAY_TIME)
	inst.components.perishable:StartPerishing()
	inst.components.perishable:SetOnPerishFn(OnPerish)


	-- Catchable via bugnet.
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.NET)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnWorked)

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_smolder_spore.xml"
	inst.components.inventoryitem.canbepickedup = false
	inst:ListenForEvent("ondropped", OnDropped)
	inst:ListenForEvent("onputininventory", OnPickup)

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

	-- Let Wormwood plant it.
	inst:AddComponent("deployable")
	inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM) -- use inst._custom_candeploy_fn
	inst.components.deployable.ondeploy = OnDeploy
	inst.components.deployable.restrictedtag = "plantkin"

	-- Eating explosives goes about as well as you'd think.
	inst:AddComponent("edible")
	inst.components.edible.healthvalue = -10
	inst.components.edible.hungervalue = 0
	inst.components.edible.sanityvalue = 0
	inst.components.edible.foodtype = FOODTYPE.GOODIES
	inst.components.edible:SetOnEatenFn(OnEaten)


	--	inst:DoTaskInTime(0, WorldCheck) -- Only check for world tags after server startup is complete.

	TaskStartup(inst)

	OnSeasonChange(inst)
	inst:WatchWorldState("season", OnSeasonChange)


	inst.persists = false

	return inst
end

local function pop_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("um_smolder_spore")
	inst.AnimState:SetBuild("um_smolder_spore")
	inst.Transform:SetScale(1.25, 1.25, 1.25)

	inst:AddTag("PyreToxinImmune")
	inst:AddTag("scarytoprey")
	inst:AddTag("flying")


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("um_smolder_spore")

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(3)


	inst:DoTaskInTime(0, PopSpore)


	inst.persists = false

	return inst
end


return Prefab("um_smolder_spore", fn, nil, prefabs),
	MakePlacer("um_smolder_spore_placer", "um_pyre_nettles", "um_pyre_nettles", "pn1_idle"),
	Prefab("um_smolder_spore_pop", pop_fn, nil, prefabs)





-- https://cdn.discordapp.com/attachments/497450801191583787/1115361079950839829/Live_Wilson_Reaction.png

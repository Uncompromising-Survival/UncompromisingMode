local assets =
{
	Asset("ANIM", "anim/viperfruit_lesser.zip"),
}
local easing = require("easing")
local function create_light(eater, lightprefab)
    if eater.wormlight ~= nil then
        if eater.wormlight.prefab == lightprefab then
            eater.wormlight.components.spell.lifetime = 0
            eater.wormlight.components.spell:ResumeSpell()
            return
        else
            eater.wormlight.components.spell:OnFinish()
        end
    end

    local light = SpawnPrefab(lightprefab)
    light.components.spell:SetTarget(eater)
    if light:IsValid() then
        if light.components.spell.target == nil then
            light:Remove()
        else
            light.components.spell:StartSpell()
        end
    end
end

local function GetPendingVipers(eater)
	return eater.pending_viperling_spawns or 0
end

local function RemoveFriend(friend)
	if friend ~= nil and friend:IsValid() then
		local x, y, z = friend.Transform:GetWorldPosition()
		SpawnPrefab("shadow_despawn").Transform:SetPosition(x, y, z)
		friend:Remove()
	end
end

local function MakeFriend(eater)
	local x, y, z = eater.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 40, { "viperlingfriend" }, { "INLIMBO" })
	local friends = {}

	if eater.components.leader == nil then
		return friends
	end

	for _, v in ipairs(ents) do
		if v:IsValid() and eater.components.leader:IsFollower(v) then
			table.insert(friends, v)
		end
	end

	return friends
end

local function SpawnFriend(eater, count)
	if eater ~= nil and eater:IsValid() then

		local x, y, z = eater.Transform:GetWorldPosition()
		local projectile = SpawnPrefab("viperprojectile")
		projectile.Transform:SetPosition(x, y, z)

		local pt = eater:GetPosition()
		pt.x = pt.x + math.random(-3, 3)
		pt.z = pt.z + math.random(-3, 3)

		if TheWorld.Map:IsAboveGroundAtPoint(pt.x, 0, pt.z) or TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z) ~= nil then

			local speed = easing.linear(3, 7, 3, 10)

			projectile:AddTag("canthit")
			projectile:AddTag("friendly")

			projectile.max_worms = 6
			projectile.eater = eater

			projectile:ListenForEvent("onremove", function()
				if eater ~= nil and eater:IsValid() then
					eater.pending_viperling_spawns = math.max(0, (eater.pending_viperling_spawns or 1) - 1)
				end
			end)

			projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
			projectile.components.complexprojectile:Launch(pt, eater, eater)
		else
			projectile:Remove()
			eater:DoTaskInTime(0, function()
				SpawnFriend(eater, count)
			end)
		end
	end
end

local function ReplaceFriend(eater, desired_count)
	local friends = MakeFriend(eater)

	table.sort(friends, function(a, b)
		return (a.despawn_time or 0) < (b.despawn_time or 0)
	end)

	local MAX_VIPERS = 6
	local pending = GetPendingVipers(eater)
	local overflow = math.max(0, (#friends + pending + desired_count) - MAX_VIPERS)

	for i = 1, overflow do
		RemoveFriend(friends[i])
	end

	for i = 1, desired_count do
		eater.pending_viperling_spawns = (eater.pending_viperling_spawns or 0) + 1

		eater:DoTaskInTime(0, function()
			SpawnFriend(eater, desired_count)
		end)
	end
end

local function oneatenfn(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        create_light(eater, "wormlight_light")
		if inst.prefab == "viperfruit" then
			ReplaceFriend(eater, 3)
		else
			ReplaceFriend(eater, 1)
		end
    end
end

local function OnSpawnedFromHaunt(inst, data)
    Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
end

local function OnHauntWormlight(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_HALF then
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
        local prefab = inst.prefab == "viperfruit_lesser" and "wormlight_lesser" or "wormlight"
        local new = prefab ~= nil and SpawnPrefab(prefab) or nil
        if new ~= nil then
            new.Transform:SetPosition(x, y, z)
            if new.components.stackable ~= nil and inst.components.stackable ~= nil and inst.components.stackable:IsStack() then
                new.components.stackable:SetStackSize(inst.components.stackable:StackSize())
            end
            if new.components.inventoryitem ~= nil and inst.components.inventoryitem ~= nil then
                new.components.inventoryitem:InheritMoisture(inst.components.inventoryitem:GetMoisture(), inst.components.inventoryitem:IsWet())
            end
            if new.components.perishable ~= nil and inst.components.perishable ~= nil then
                new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
            end
            new:PushEvent("spawnedfromhaunt", { haunter = haunter, oldPrefab = inst })
            inst:PushEvent("despawnedfromhaunt", { haunter = haunter, newPrefab = new })
            inst.persists = false
            inst.entity:Hide()
            inst:DoTaskInTime(0, inst.Remove)
        end
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("viperfruit")
    inst.AnimState:SetBuild("viperfruit")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237 / 255, 100 / 255, 100 / 255)
    inst.Light:Enable(true)

    inst:AddTag("lightbattery")
    --inst:AddTag("vasedecoration")
    inst:AddTag("light")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_MOREMEDSMALL --15
    inst.components.edible.hungervalue = TUNING.CALORIES_LARGE --37.5
    inst.components.edible.sanityvalue = -TUNING.SANITY_LARGE --33
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible:SetOnEatenFn(oneatenfn)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.WORMLIGHT
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 1.33

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, OnHauntWormlight, true, false, true)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

	inst:AddComponent("tradable")

    return inst
end

local function fnlesser()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("viperfruit_lesser")
    inst.AnimState:SetBuild("viperfruit_lesser")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237 / 255, 100 / 255, 100 / 255)
    inst.Light:Enable(true)

    inst:AddTag("lightbattery")
    --inst:AddTag("vasedecoration")
    inst:AddTag("light")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL --3
    inst.components.edible.hungervalue = TUNING.CALORIES_MEDSMALL --18.8
    inst.components.edible.sanityvalue = -TUNING.SANITY_MED --15
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible:SetOnEatenFn(oneatenfn)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.WORMLIGHT
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, OnHauntWormlight, true, false, true)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)

	inst:AddComponent("tradable")

    return inst
end

return Prefab("viperfruit", fn, assets),
Prefab("viperfruit_lesser", fnlesser)

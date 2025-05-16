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

local function spawnfriends(inst,count)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("viperprojectile")
    projectile.Transform:SetPosition(x, y, z)
    local pt = inst:GetPosition()
    pt.x = pt.x + math.random(-3, 3)
    pt.z = pt.z + math.random(-3, 3)
    local speed = easing.linear(3, 7, 3, 10)
    projectile:AddTag("canthit")
    projectile:AddTag("friendly")
    --projectile.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS/2
	projectile.max_worms = count
	projectile.eater = inst
    projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
    if TheWorld.Map:IsAboveGroundAtPoint(pt.x, 0, pt.z) or TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z) ~= nil then
        projectile.components.complexprojectile:Launch(pt, inst, inst)
    else
        inst:DoTaskInTime(0, spawnfriends(inst,count))
        projectile:Remove()
    end
end

local function GetWorms(inst,count,time_to_add)
	local x,y,z = inst.Transform:GetWorldPosition()
	local worms = TheSim:FindEntities(x,y,z,40,{"viperlingfriend"})
	local worm_friends = {}
	for i,v in ipairs(worms) do
		if inst.components.leader and inst.components.leader:IsFollower(v) then
			table.insert(worm_friends,v)
		end
	end
	for i,v in ipairs(worm_friends) do -- need specifically *that players* worms
		SpawnPrefab("shadow_despawn").Transform:SetPosition(v.Transform:GetWorldPosition())
		local more_time = v.components.timer:GetTimeLeft("despawn") or 0
		v.components.timer:SetTimeLeft("despawn", time_to_add + more_time)
	end
	local nworms = #worm_friends
	if #worm_friends > count then
		nworms = count
	end
	return count-nworms
end


local function oneatenfn(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        create_light(eater, "wormlight_light")
		if inst.prefab == "viperfruit" then
			local i = GetWorms(eater,3,30)
			for k = 1, i do
				eater:DoTaskInTime(0, spawnfriends(eater,3))
			end
		else
			local i = GetWorms(eater,1,15)
			if i > 0 then 
				eater:DoTaskInTime(0, spawnfriends(eater,1)) -- Lesser only spawns 1.
			end
		end
    end
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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 25
    inst.components.edible.sanityvalue = -30
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(3 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    inst.components.edible:SetOnEatenFn(oneatenfn)
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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 12.5
    inst.components.edible.sanityvalue = -15
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(3 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    inst.components.edible:SetOnEatenFn(oneatenfn)
	inst:AddComponent("tradable")
	
	
    return inst
end

return Prefab("viperfruit", fn, assets),
Prefab("viperfruit_lesser", fnlesser)

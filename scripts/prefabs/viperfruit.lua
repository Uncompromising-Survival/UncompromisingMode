local assets =
{
    Asset("ANIM", "anim/zaspberry.zip"),
    Asset("ATLAS", "images/inventoryimages/zaspberry.xml"),
    Asset("IMAGE", "images/inventoryimages/zaspberry.tex"),
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

local function spawnfriends(inst)
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
    projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
    if TheWorld.Map:IsAboveGroundAtPoint(pt.x, 0, pt.z) or TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z) ~= nil then
        projectile.components.complexprojectile:Launch(pt, inst, inst)
    else
        inst:DoTaskInTime(0, spawnfriends(inst))
        projectile:Remove()
    end
end

local function oneatenfn(inst, eater)
    if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
        not (eater.components.health ~= nil and eater.components.health:IsDead()) and
        not eater:HasTag("playerghost") then
        create_light(eater, "wormlight_light")
        for k = 1, 3 do
            inst:DoTaskInTime(0, spawnfriends(inst))
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
    inst.components.inventoryitem.atlasname = "images/inventoryimages/viperfruit.xml"
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 25
    inst.components.edible.sanityvalue = -30
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible:SetOnEatenFn(oneatenfn)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(3 * TUNING.PERISH_TWO_DAY)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.WORMLIGHT
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 1.33

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, OnHauntWormlight, true, false, true)
    inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)
    return inst
end

return Prefab("viperfruit", fn, assets)

local assets =
{
    Asset("ANIM", "anim/zaspberry.zip"),
    Asset("ATLAS", "images/inventoryimages/zaspberry.xml"),
    Asset("IMAGE", "images/inventoryimages/zaspberry.tex"),
    Asset("ATLAS", "images/inventoryimages/zaspberry_lesser.xml"),
    Asset("IMAGE", "images/inventoryimages/zaspberry_lesser.tex"),
}

local function create_light(eater, lightprefab)
    if eater.wormlight then
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
        if not light.components.spell.target then
            light:Remove()
        else
            light.components.spell:StartSpell()
        end
    end
end

local function oneatenfn(inst, eater)
    eater:AddDebuff("buff_lesserelectricattack", "buff_lesserelectricattack")
    create_light(eater, "wormlight_light")
end

local function fn_common()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(237 / 255, 237 / 255, 209 / 255)
    inst.Light:Enable(true)

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("zaspberry")
    inst.AnimState:SetBuild("zaspberry")

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst:AddComponent("edible")

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

local function fn_normal()
    local inst = fn_common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PlayAnimation("idle")
    inst.components.edible.healthvalue = 20
    inst.components.edible.hungervalue = 25
    inst.components.edible.sanityvalue = -25    

    return inst
end

local function fn_lesser()
    local inst = fn_common()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AnimState:PlayAnimation("idle_lesser")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 12.5
    inst.components.edible.sanityvalue = -15

    return inst
end

return Prefab("zaspberry", fn_normal, assets),
    Prefab("zaspberry_lesser", fn_lesser)
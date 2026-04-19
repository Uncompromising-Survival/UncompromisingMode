local assets =
{
    Asset("ANIM", "anim/zaspberryparfait.zip"),
    Asset("ATLAS", "images/inventoryimages/zaspberryparfait.xml"),
    --Asset("IMAGE", "images/inventoryimages/zaspberryparfait.tex"),
}

local function oneatenfn(inst, eater)
    eater:AddDebuff("buff_electricretaliation", "buff_electricretaliation")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(206 / 255, 76 / 255, 37 / 255)
    inst.Light:Enable(true)

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("zaspberryparfait")
    inst.AnimState:SetBuild("zaspberryparfait")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 40
    inst.components.edible.hungervalue = 37.5
    inst.components.edible.sanityvalue = 15
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible.chargevalue = TUNING.WX78_CHARGE_LARGE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime((2 * TUNING.PERISH_TWO_DAY))
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    inst.components.edible:SetOnEatenFn(oneatenfn)
    inst:AddTag("preparedfood")
    return inst
end

return Prefab("zaspberryparfait", fn, assets)
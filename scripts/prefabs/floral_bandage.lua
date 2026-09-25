local assets =
{
    Asset("ANIM", "anim/floral_bandage.zip"),
    Asset("ATLAS", "images/inventoryimages/floral_bandage.xml"),
    Asset("IMAGE", "images/inventoryimages/floral_bandage.tex"),    
}

local function OnUse(inst, target)
    if target.components.health and not target.components.health:IsDead() then
        target:AddDebuff("confighealbuff_"..inst.prefab, "confighealbuff", {time = 15})
    end
end

--[[ Y Add This Item?
Cactus flower's "bonus" is supposedly flower salad, which has a super quick spoil time with a baseline
healing value. This is terrible, especially whenever this is a summer exclusive resource. [Which is also kinda lacking]
So here's the proposition, buff flower salad, add alternative healing item that does 40 health and is nonperishable,
allows you to decide whether you'd rather get more healing now or a decent amount of healing later.
If you feel it's absolutely necessary to nerf this item (it probably isn't) then I would recommend just
swapping the instant health to 20, then adding 20 overtime health. --AXE]]

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    anim:SetBank("floral_bandage")
    anim:SetBuild("floral_bandage")
    anim:PlayAnimation("idle")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local stackable = inst:AddComponent("stackable")
    stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    local healer = inst:AddComponent("healer")
    healer:SetHealthAmount(45)
    healer.onhealfn = OnUse

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("floral_bandage", fn, assets)
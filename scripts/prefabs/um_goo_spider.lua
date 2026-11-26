local assets = {
    Asset("ANIM", "anim/um_goo_spider.zip"),
}

local function spider_explosion()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.AnimState:SetBank("treegrowthsolution")
    inst.AnimState:SetBuild("um_goo_spider")
    inst.AnimState:PlayAnimation("use", false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", function(inst) inst:Remove() end)

    inst.persists = false

    return inst
end

return Prefab("um_goo_spider", spider_explosion,assets)
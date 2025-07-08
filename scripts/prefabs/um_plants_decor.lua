local assets =
{
    Asset("ANIM", "anim/um_plant_hotsprings.zip"),
}

local function fn(bank, build)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle", true)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableIgnite(inst)

        inst:AddComponent("inspectable")

        return inst
    end
end

return Prefab("um_plant_hotsprings", fn("um_plant_hotsprings", "um_plant_hotsprings"), assets)
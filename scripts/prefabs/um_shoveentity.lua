local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --inst.entity:AddAnimState()

    MakeCharacterPhysics(inst, 1000000000, .5):SetDontRemoveOnSleep(true)

    --[[inst.AnimState:SetBank("boards")
    inst.AnimState:SetBuild("boards")
    inst.AnimState:PlayAnimation("idle")]]

    --[[Non-networked entity]]
    inst:AddTag("um_shoveentity")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end

return Prefab("um_shoveentity", fn)
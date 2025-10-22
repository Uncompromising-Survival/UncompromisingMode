local assets =
{
	Asset("ANIM", "anim/shadow_skittish.zip"),
}

local function Disappear(inst)
    if inst.deathtask ~= nil then
        inst.deathtask:Cancel()
        inst.deathtask = nil
        inst.AnimState:PlayAnimation("disappear")
        inst:ListenForEvent("animover", inst.Remove)
    end
end

local function fn()

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadowcreatures")
    inst.AnimState:SetBuild("shadow_skittish")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1, 1, 1, 0)

    inst:AddComponent("transparentonsanity")
	inst:AddTag("NOCLICK")

	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(5, 8)
    inst.components.playerprox:SetOnPlayerNear(Disappear)
	
	inst.persists = false
    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
	    
	MakeSmallPropagator(inst)
	
    return inst
end

return Prefab("rneshadowskittish", fn, assets)
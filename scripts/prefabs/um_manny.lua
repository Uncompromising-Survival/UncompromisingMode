local assets =
{
    Asset("ANIM", "anim/um_manny.zip"),
}

local function Toggle(inst)
	if inst.hidden then
		inst.hidden = nil
		inst.AnimState:Show("manny_eyeclosed-2")
		inst.AnimState:Hide("manny_eyeclosed-5")
	else
		inst.hidden = true
		inst.AnimState:Hide("manny_eyeclosed-2")
		inst.AnimState:Show("manny_eyeclosed-5")
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("um_manny.tex")
    MakeInventoryPhysics(inst)


    inst.AnimState:SetBank("um_manny")
    inst.AnimState:SetBuild("um_manny")
    inst.AnimState:PlayAnimation("idle",true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:DoPeriodicTask(2,Toggle)

    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("um_manny", fn, assets)

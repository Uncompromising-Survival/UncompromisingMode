local assets =
{
    Asset("ANIM", "anim/um_gemologygems.zip"),
}
local gems = {"bluegem","redgem","purplegem","orangegem","yellowgem","palegem"}


local function fncommon(gem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("um_gemologygems")
    inst.AnimState:SetBuild("um_gemologygems")
    inst.AnimState:PlayAnimation(gem)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end



    MakeHauntableLaunch(inst)

    return inst
end

local function FullReturn(inst)
	if not TheWorld.ismastersim then
        return inst
    end
	
	return inst
end

local function fnblue1() local inst = fncommon("bluegem1") return FullReturn(inst) end


-- If any kind soul could convert this into a "for" loop, I'd appreciate it, I couldn't get it to work around the return, would cause a crash.
return Prefab("um_gemologybluegem1", fnblue1, assets)
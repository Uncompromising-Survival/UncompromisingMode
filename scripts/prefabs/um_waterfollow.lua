local assets =
{
	Asset("ANIM", "anim/um_waterfollow.zip"),
}

local function SetupBlob(inst, target)
	inst.entity:SetParent(target.entity)
	inst:DoTaskInTime(0.5,function(inst)
		inst.checktask = inst:DoPeriodicTask(3*FRAMES,function(inst)
			if not inst.stay then
				inst.checktask:Cancel()
				inst.KillFX(inst)
			else
				inst.stay = nil
			end
		end)
	end)
end

local function KillFX(inst)
	if inst:IsAsleep() then
		inst:Remove()
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local parent = inst.entity:GetParent()
	if parent then
		parent:RemoveTag("waterblobbed")
		inst.entity:SetParent(nil)
		parent.water_goo = nil
	end
	inst.Transform:SetPosition(x, y, z)
	inst.AnimState:PlayAnimation("attach_end")
	inst:ListenForEvent("animover", inst.Remove)
	inst.OnEntitySleep = inst.Remove
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(2, 1.5)

	inst:AddTag("FX")

	inst.AnimState:SetBank("um_waterfollow")
	inst.AnimState:SetBuild("um_waterfollow")
	inst.AnimState:PlayAnimation("attach_pre")
	inst.AnimState:SetFinalOffset(2)


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.AnimState:PushAnimation("attach_loop")

	inst.persists = false

	inst.SetupBlob = SetupBlob
	inst.KillFX = KillFX

	return inst
end

return Prefab("um_waterfollow", fn, assets)

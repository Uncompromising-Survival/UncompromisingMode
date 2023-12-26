local function Check2Kill(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	
	local ents = TheSim:FindEntities(x, y, z, 100, {"player"}, {"playerghost"})
	
	for i, v in ipairs(ents) do
		if v ~= nil and v:IsValid() then
			local distsq = v:GetDistanceSqToPoint(x, y, z)
			
			if distsq > 250 then
				if v.components.health ~= nil then
					v.components.health:DoDelta(-5)
				end
			end
		end
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_shadowcircle")
    inst.AnimState:SetBuild("um_shadowarena")
    inst.AnimState:PlayAnimation("circle", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetSortOrder(4)
	inst:AddTag("NOCLICK")
	inst.Transform:SetScale(2.2, 2.2, 2.2)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.AnimState:SetMultColour(0,0,0,0)
		
    inst:AddComponent("colourtweener")
	inst.components.colourtweener:StartTween({255/255,255/255,255/255,1}, 20)
	
	inst:DoPeriodicTask(.1, Check2Kill)

    return inst
end

return Prefab("um_shadowarena", fn)
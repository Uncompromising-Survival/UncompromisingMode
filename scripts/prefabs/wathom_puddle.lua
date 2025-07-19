local function ApplySlows(inst)
	--also scare enemies near wathom, at a smaller radius
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, { "_combat" },
		{ "companion", "INLIMBO", "notarget", "player", "playerghost", "wall", "abigail", "shadow", "trap" }) --added playertags because of the taunt.
	for i, v in ipairs(ents) do
		local debuffkey = inst.prefab
		
		if v.components.locomotor then
			v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, 0.5)
			v.um_wathom_speedmulttask = v:DoTaskInTime(10, function(i)
				i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
				i.um_wathom_speedmulttask = nil
			end)
		end
		if v.components.hauntable ~= nil and v.components.hauntable.panicable and not
			(
				v.components.follower ~= nil and v.components.follower:GetLeader() and
				v.components.follower:GetLeader():HasTag("player")) then
			v.components.hauntable:Panic(8) -- Fallback to TUNING.BATTLESONG_PANIC_TIME (6 seconds) if needed
		end
		if v.components.hauntable == nil or
			v.components.hauntable ~= nil and not v.components.hauntable.panicable and not (
				v.components.follower ~= nil and v.components.follower:GetLeader() and
				v.components.follower:GetLeader():HasTag("player")) and not v:HasTag("player") then
			if not v:HasTag("bird") and v.components.combat then
				v.components.combat:SetTarget(act.doer)
			end
		end
	end
end



local function puddle()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("treegrowthsolution")
    inst.AnimState:SetBuild("um_goo_blue")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	inst.Transform:SetScale(1.5,1.5,1.5)
    inst.AnimState:PlayAnimation("pre_idle", false)
	inst.AnimState:PushAnimation("idle", false)
	inst.AnimState:SetMultColour(0,0,0,1)
	inst:ListenForEvent("animover",function(inst) inst.AnimState:SetDeltaTimeMultiplier(0.4) end)
	inst:ListenForEvent("animqueueover",function(inst) inst:Remove() end)
	inst.persists = false
	
	inst:DoPeriodicTask(0.5,ApplySlows)

    return inst
end
return Prefab("wathom_puddle",puddle)

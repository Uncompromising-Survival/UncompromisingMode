local function AddFx(inst, followsymbol, followoffset, data)
	if inst.initialtarget ~= nil then
		local fx = SpawnPrefab("wixie_stinger_debuff_fx")
		fx.entity:SetParent(inst.initialtarget.entity)

		if inst.initialtarget.components.combat ~= nil and inst.initialtarget.components.combat.hiteffectsymbol ~= nil and inst.initialtarget.components.combat.hiteffectsymbol ~= "marker" then
			--[[fx.entity:AddFollower():FollowSymbol(inst.initialtarget.GUID, inst.initialtarget.components.combat.hiteffectsymbol, 0, 0, 0)
		else]]
			if inst.initialtarget:HasTag("smallcreature") then
				fx.Transform:SetPosition((math.random() - math.random()), .5 + (math.random() - math.random()), (math.random() - math.random()))
			elseif inst.initialtarget:HasTag("epic") then
				fx.Transform:SetPosition((math.random() - math.random()), 2.5 + (math.random() - math.random()), (math.random() - math.random()))
			else
				fx.Transform:SetPosition((math.random() - math.random()), 1.5 + (math.random() - math.random()), (math.random() - math.random()))
			end
		end
		
		table.insert(inst.stingercounter, fx)
		
		for i, v in ipairs(inst.stingercounter) do
			v:DoTaskInTime(i / 10, function()
				if inst.initialtarget:IsValid() and inst.initialtarget.components.health ~= nil then
					inst.initialtarget.components.health:DoDelta(-2, nil, inst)
				end
				
				v.SoundEmitter:PlaySound("dontstarve/bee/bee_attack")
				v.AnimState:PlayAnimation("spin_loop", false)
			end)
		end
	end
end

local function OnAttached(inst, target, followsymbol, followoffset, data)
	inst.initialtarget = target
	
	AddFx(inst, followsymbol, followoffset, data)
	
    inst.components.timer:StartTimer("buffover", 15)
	
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
		inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target, followsymbol, followoffset, data)
	AddFx(inst, followsymbol, followoffset, data)
    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", 15)
end

local function buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() and target.components.combat ~= nil then
		target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
	end
	
	for i, v in ipairs(inst.stingercounter) do
		v:Remove()
	end
	
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.persists = false
	inst.initialtarget = nil
    inst.stingercounter = {}

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

local function fxfn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
	
    inst.AnimState:SetBank("slingshotammo")
    inst.AnimState:SetBuild("slingshotammo")
    inst.AnimState:PlayAnimation("spin_loop", false)
	inst.AnimState:OverrideSymbol("rock", "slingshotammo", "stinger")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return Prefab("wixie_stinger_debuff", fn),
		Prefab("wixie_stinger_debuff_fx", fxfn)
local function ToggleSpawnFactor(inst)
	inst.spawnfactor = false
	inst:RemoveEventCallback("animover", ToggleSpawnFactor)
end

local function OnAttached(inst, target, followsymbol, followoffset, data)
	inst.SoundEmitter:PlaySound("dontstarve/sanity/creature1/taunt")

	inst.spawnfactor = true
	
	inst:ListenForEvent("animover", ToggleSpawnFactor)
	
    inst.components.timer:StartTimer("buffover", 20)

    inst.entity:SetParent(target.entity)
	
	if target ~= nil and target:IsValid() and target.components.combat ~= nil and target.components.locomotor ~= nil then
			local taunt_bonus = data ~= nil and data.inflicter ~= nil and 
								(data.inflicter:HasTag("wixie_taunteffect_3") and .06 or 
								data.inflicter:HasTag("wixie_taunteffect_2") and .04 or 
								data.inflicter:HasTag("wixie_taunteffect_1") and .02) or 0
		print(taunt_bonus)
							
		target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.1 + taunt_bonus)
		target.components.locomotor:SetExternalSpeedMultiplier(target, "wixie_taunt", 1.1 - taunt_bonus)
	
		inst:ListenForEvent("wixie_taunt_lvl2", function(target, data)
			local taunt_bonus = data ~= nil and data.inflicter ~= nil and 
								(data.inflicter:HasTag("wixie_taunteffect_3") and .06 or 
								data.inflicter:HasTag("wixie_taunteffect_2") and .04 or 
								data.inflicter:HasTag("wixie_taunteffect_1") and .02) or 0
		print(taunt_bonus)
		
			target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.15 + taunt_bonus)
			target.components.locomotor:SetExternalSpeedMultiplier(target, "wixie_taunt", 1.15 - taunt_bonus)
			inst.components.timer:StopTimer("buffover")
			inst.components.timer:StartTimer("buffover", 20)
			inst.AnimState:SetMultColour(1, .15, .15, 0.8)
		end, target)
		
		inst:ListenForEvent("wixie_taunt_lvl3", function(target, data)
			local taunt_bonus = data ~= nil and data.inflicter ~= nil and 
								(data.inflicter:HasTag("wixie_taunteffect_3") and .06 or 
								data.inflicter:HasTag("wixie_taunteffect_2") and .04 or 
								data.inflicter:HasTag("wixie_taunteffect_1") and .02) or 0
		print(taunt_bonus)
								
			target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.2 + taunt_bonus)
			target.components.locomotor:SetExternalSpeedMultiplier(target, "wixie_taunt", 1.2 - taunt_bonus)
			inst.components.timer:StopTimer("buffover")
			inst.components.timer:StartTimer("buffover", 20)
			inst.AnimState:SetMultColour(1, 0, 0, 1)
		end, target)
	end
	
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
		
		inst.spawnfactor = true
		inst.AnimState:PlayAnimation("despawn")
		inst.SoundEmitter:PlaySound("dontstarve/sanity/creature1/death")
		
		inst:ListenForEvent("animover", function()
			inst.components.debuff:Stop()
		end)
    end
end

local function OnExtended(inst, target, followsymbol, followoffset, data)
    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", 20)
end

local function buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() and target.components.combat ~= nil and target.components.locomotor ~= nil then
		target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
		target.components.locomotor:RemoveExternalSpeedMultiplier(target, "wixie_taunt")
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
	
    inst.AnimState:SetBank ("fx_book_web")
    inst.AnimState:SetBuild("fx_book_web")
    inst.AnimState:PlayAnimation("spawn", true)
	inst.Transform:SetScale(0.65, 0.65, 0.65)
	inst.AnimState:SetMultColour(1, .3, .3, 0.6)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.persists = false
    inst.spawnfactor = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(buff_OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("wixietaunt_debuff", fn)

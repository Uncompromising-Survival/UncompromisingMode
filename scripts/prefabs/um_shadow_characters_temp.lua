local brain = require "brains/swilsonbrain"
local assets =
{

}
local prefabs =
{

}

SetSharedLootTable('swilson',
{
    {'um_shadow_axe',     1.0},
})


local function PlaySound(inst,sound)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO") --Currently just does this... Until the real sounds are here
end




local SHARE_TARGET_DIST = 30

local function NormalRetarget(inst)
    local targetDist = 30
    if inst.components.knownlocations:GetLocation("investigate") then
        targetDist = 32
    end
    return FindEntity(inst, targetDist, 
        function(guy) 
            if inst.components.combat:CanTarget(guy) then
                return guy:HasTag("character") or guy:HasTag("pig")
            end
    end)
end

local function keeptargetfn(inst, target)
   return target
          and target.components.combat
          and target.components.health
          and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("swilson") and not dude.components.health:IsDead() end, 5)
end


local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function EquipItems(inst)
	if (inst.prefab == "swilson" or inst.prefab == "swilson_labotomized") and not inst.components.inventory then
		inst.AnimState:OverrideSymbol("swap_object", "swap_axe", "swap_axe")
		inst.AnimState:Show("ARM_carry")
		inst.AnimState:Hide("ARM_normal")
	elseif inst.prefab == "swathgrithr" or inst.prefab == "swathgrithr_labotomized" then
		inst.AnimState:OverrideSymbol("swap_object", "swap_spear_wathgrithr", "swap_spear_wathgrithr")
		inst.AnimState:Show("ARM_carry")
		inst.AnimState:Hide("ARM_normal")
		
		inst.AnimState:OverrideSymbol("swap_hat", "hat_wathgrithr", "swap_hat")
        inst.AnimState:Show("HAT")
        inst.AnimState:Show("HAIR_HAT")
        inst.AnimState:Hide("HAIR_NOHAT")
        inst.AnimState:Hide("HAIR")
		inst.AnimState:Hide("HEAD")
		inst.AnimState:Show("HEAD_HAT")
		inst.AnimState:Show("HEAD_HAT_NOHELM")
		inst.AnimState:Hide("HEAD_HAT_HELM")
	end
end

local function Split(inst)
	if not inst:HasTag("splitting") then
		inst:AddTag("splitting")
		inst:AddTag("INLIMBO")
		inst.sg:GoToState("death_split")
	end
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    
	local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize( 1.5, .5 )
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    inst.Transform:SetFourFaced()
	
	inst:AddTag("monster")
    inst:AddTag("hostile")   
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")

	MakeCharacterPhysics(inst, 10, .5)
	--MakePoisonableCharacter(inst)
	inst.AnimState:UsePointFiltering(true)
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.HostileToPlayerTest = function() return true end
	inst.AnimState:HideSymbol("face")
	inst.AnimState:SetBank("wilson")
	inst.AnimState:SetMultColour(0, 0, 0, 0.6)
   
    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    
    inst:AddComponent("lootdropper")
    ------------------
    inst:AddComponent("health")
    ------------------
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)    
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetHurtSound("dontstarve/sanity/creature1/death")
    ------------------
    
    ------------------
    
    inst:AddComponent("knownlocations")
    ------------------
    
    --inst:AddComponent("inspectable") --Shadows are not inspectable
    inst:ListenForEvent("attacked", OnAttacked)

    ------------------
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
    
    inst:SetStateGraph("SGum_shadow_characters_temp")
    inst:SetBrain(brain) 
	inst:DoTaskInTime(0,EquipItems)
	inst:WatchWorldState("isday", function(inst) inst:Remove() end)
	inst.PlaySound = PlaySound
	
    return inst
end

local function FadeOut(inst)
	inst.opacity = inst.opacity - 0.02
	local green = inst.green or 0
	inst.AnimState:SetMultColour(0, green, 0, inst.opacity)
	if inst.opacity > 0 then
		inst:DoTaskInTime(FRAMES,FadeOut)
	else
		if inst.dupe_toolweapon then
			inst.dupe_toolweapon:Remove()
			inst.dupe_toolweapon = nil
		end
		inst:Remove()
	end
end

local function LabotomizedAttack(inst,axeholder,target)
	inst.target = target
	if axeholder ~= inst then
		inst.axeholder = axeholder
	end
	if target then
		inst:ForceFacePoint(target:GetPosition())
		if inst.prefab == "swilson_labotomized" then
			inst.AnimState:PlayAnimation("atk_pre",false)
			inst.AnimState:PushAnimation("atk",false)
			inst:DoTaskInTime(FRAMES*11,function(inst)
				if inst.target and inst.target:IsValid() and inst.axeholder and inst:GetDistanceSqToInst(inst.target) < 3^2 and inst.target.components.combat and inst.target.components.health and not inst.target.components.health:IsDead() then
					inst.target.components.combat:GetAttacked(inst.axeholder,inst.attack)
				end
				if inst.prefab == "swathgrithr_labotomized" then
					inst:DoTaskInTime(0.5,function(inst) inst:Remove() end)
				end
				FadeOut(inst)
			end)
		elseif inst.prefab == "swathgrithr_labotomized" then
			inst.AnimState:PlayAnimation("lunge_pst",false)
			inst:ListenForEvent("animover",FadeOut)
			inst.Physics:SetMotorVelOverride(20,0,0)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/attack_VO")
			inst.do_periodic_damage = inst:DoPeriodicTask(0.1,function(inst)
				local x,y,z = inst.Transform:GetWorldPosition()
				local targets = TheSim:FindEntities(x,y,z,2,{"_health","_combat"},{"shadow"})
				for i,v in ipairs(targets) do
					v.components.combat:GetAttacked(inst.axeholder,inst.attack)
				end
			end)
			inst:DoTaskInTime(0.5,function(inst)
				inst.Physics:Stop()
				inst.Physics:SetMotorVelOverride(0,0,0)
				inst.do_periodic_damage:Cancel()
				inst.do_periodic_damage = nil
			end)
		end
	end
end

local function LabotomizedWork(inst,axeholder,target)
	inst.target = target
	inst.axeholder = axeholder
	if target then
		inst:ForceFacePoint(target:GetPosition())
		local time = 20 ---... I originally set up this system to have different times for each action, but that seems like it may be unnecessary
		if target:HasTag("CHOP_workable") then
			inst.AnimState:PlayAnimation("chop_pre",false)
			inst.AnimState:PushAnimation("chop_loop",false)
			time = 20
		end
		if target:HasTag("MINE_workable") or target:HasTag("HAMMER_workable") then
			if target:HasTag("MINE_workable") then
				PlayMiningFX(inst, target)
			end
			inst.AnimState:PlayAnimation("pickaxe_pre",false)
			inst.AnimState:PushAnimation("pickaxe_loop",false)
			time = 20		
		end
		if target:HasTag("DIG_workable") then
			inst.AnimState:PlayAnimation("shovel_loop",false)
			time = 20		
		end		
		inst:DoTaskInTime(FRAMES*time,function(inst)
			if inst.target and inst.target:IsValid() and inst.axeholder and inst:GetDistanceSqToInst(inst.target) < 9 and inst.target.components.workable then
				inst.target.components.workable:WorkedBy(inst.axeholder,inst.work)
			end
			FadeOut(inst)
		end)
	end
end

local function FadeIn(inst)
	inst.opacity = inst.opacity + 0.1
	local green = inst.green or 0
	inst.AnimState:SetMultColour(0, green, 0, inst.opacity)
	if inst.opacity ~= 0.6 then
		inst:DoTaskInTime(FRAMES,FadeIn)
	end
end

local function fnlabotomizedswilson(Sim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    
	local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize( 1.5, .5 )
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    inst.Transform:SetFourFaced()
	

	inst:AddTag("notraptrigger")
	inst:AddTag("INLIMBO")

	MakeCharacterPhysics(inst, 10, .5)
	--MakePoisonableCharacter(inst)
	inst.AnimState:UsePointFiltering(true)
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.AnimState:HideSymbol("face")
	RemovePhysicsColliders(inst)
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle",true)
	inst.AnimState:SetMultColour(0, 0, 0, 0)


    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
	inst.LabWork = LabotomizedWork
	inst.LabAttack = LabotomizedAttack
	inst:DoTaskInTime(0,EquipItems)
	inst.opacity = 0
	inst:DoTaskInTime(FRAMES,FadeIn)
	inst.persists = false --Fallback
	inst.work = 2
	inst.attack = 34
	inst:DoTaskInTime(3,function(inst) inst:Remove() end) --Fallback
	
	inst:AddComponent("inventory")
    return inst
end

local function fnlabotomizedswathgrithr(Sim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    
	local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize( 1.5, .5 )
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    inst.Transform:SetFourFaced()
	

	inst:AddTag("notraptrigger")
	inst:AddTag("INLIMBO")

	MakeCharacterPhysics(inst, 10, .5)
	--MakePoisonableCharacter(inst)
	inst.AnimState:UsePointFiltering(true)
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	inst.AnimState:HideSymbol("face")
	RemovePhysicsColliders(inst)
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wathgrithr")
    inst.AnimState:PlayAnimation("idle",true)
	inst.AnimState:SetMultColour(0, 0, 0, 0)


    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
	inst.LabAttack = LabotomizedAttack
	inst:DoTaskInTime(0,EquipItems)
	inst.opacity = 0
	inst:DoTaskInTime(FRAMES,FadeIn)
	inst.persists = false --Fallback
	inst.work = 2
	inst.attack = 51
	inst:DoTaskInTime(3,function(inst) inst:Remove() end) --Fallback
    return inst
end

local function SwilsonFn()
	local inst = fn()
    if not TheWorld.ismastersim then
        return inst
    end
	inst.AnimState:SetBuild("wilson")
	inst.AnimState:PlayAnimation("idle",true)
	inst.components.combat:SetDefaultDamage(51)
	inst.components.combat:SetAttackPeriod(4)
	inst.components.combat:SetRange(2, 2)
	inst:AddComponent("healthtrigger")
	inst.components.healthtrigger:AddTrigger(0.6666, Split)
	inst.components.healthtrigger:AddTrigger(0.3333, Split)
	inst.components.health:SetMaxHealth(450) -- Wilson's health is complicated, since you really kill him after 150 health, but you have to fight him 21 total times, equating to 3150 total health.
	inst.components.lootdropper:SetChanceLootTable('swilson')
	inst:AddTag("swilson") 
	inst:AddTag("shadowchar_swilson")
	
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "wilson_vetskull" })
	
	return inst
end

local function Attack(target)
	local inst = target.swiggybuff
	inst.count = inst.count + 1
	if inst.count >= 3 then
		inst.components.debuff:Stop()
		target.components.combat.damagemultiplier = inst.oldmult
		inst:Remove()
	end
end

local function ShadowBuffAttached(inst, target)
	target.swiggybuff = inst
	inst.count = 0
	inst.oldmult = target.components.combat.damagemultiplier or 1
	target.components.combat.damagemultiplier = inst.oldmult * 2 --Double damage... for 3 attacks
	target:ListenForEvent("onhitother",Attack)
	target:ListenForEvent("onmissother",Attack)
end

local function ShadowBuffExtended(inst, target)
	inst.count = 0
end

local function shadowattackbuff()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        --Not meant for client!
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    --inst.entity:SetCanSleep(false)
    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(ShadowBuffAttached)
    inst.components.debuff:SetExtendedFn(ShadowBuffExtended)
    inst.components.debuff.keepondespawn = false

    return inst
end

local function BuffShadows(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local shadows =  TheSim:FindEntities(x,y,z,100,{"shadow"})
	for i,v in ipairs(shadows) do
		if v.components.combat then
			if not v.components.debuffable then
				v:AddComponent("debuffable")
			end
			v.components.debuffable:AddDebuff("swathgrithr_shadebuff", "swathgrithr_shadebuff")
		end
	end
	if not inst.components.debuffable then
		inst:AddComponent("debuff")
	end
	inst.components.debuffable:AddDebuff("swathgrithr_shadebuff", "swathgrithr_shadebuff")
end

local function SWathgrithrFn()
	local inst = fn()
    if not TheWorld.ismastersim then
        return inst
    end
	inst.AnimState:SetBuild("wathgrithr")
	inst.AnimState:PlayAnimation("idle",true)
	inst.components.combat:SetDefaultDamage(68)
	inst.components.combat:SetAttackPeriod(4)
	inst.components.combat:SetRange(4, 4)
	inst.components.health:SetMaxHealth(200)
	inst.components.health:SetAbsorptionAmount(0.9) -- 90% damage res: Effective 2000 health 
	
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 4
	inst:ListenForEvent("onkilledother", function(inst) -- Vampirism for shadows (like DS, not DST)
		if inst.components.health then
			inst.components.health:SetPercent(1)
		end
	end)
	
	inst.combo = 0
	inst.rage = 0
	inst.BuffShadows = BuffShadows
	
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "wathgrithr_vetskull" })
	
	return inst
end

return Prefab("swilson",SwilsonFn),
Prefab("swathgrithr",SWathgrithrFn),
Prefab("swathgrithr_shadebuff", shadowattackbuff),
Prefab("swilson_labotomized", fnlabotomizedswilson), --"Labotomized" as in, doesn't have a brain (or a SG)
Prefab("swathgrithr_labotomized", fnlabotomizedswathgrithr)
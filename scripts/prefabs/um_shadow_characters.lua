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
	if inst.prefab == "swilson" or inst.prefab == "swilson_labotomized" then
		inst.AnimState:OverrideSymbol("swap_object", "swap_axe", "swap_axe")
		inst.AnimState:Show("ARM_carry")
		inst.AnimState:Hide("ARM_normal")
	end
end

local function Split(inst)
	if not inst:HasTag("splitting") then
		inst:AddTag("splitting")
		inst:AddTag("INLIMBO")
		inst.sg:GoToState("death_split")
	end
end

local function fn(Sim)
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
    inst:AddTag("swilson") 
	inst:AddTag("shadowchar_swilson")
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
	
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle",true)
	inst.AnimState:SetMultColour(0, 0, 0, 0.6)
   
    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('swilson')
    
    ---------------------            
    --MakeMediumBurnableCharacter(inst, "torso")
    --MakeMediumFreezableCharacter(inst, "torso")    
    --inst.components.burnable.flammability = 0.33
    ---------------------       
    
	

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(450)
    ------------------
	inst:AddComponent("healthtrigger")
    inst.components.healthtrigger:AddTrigger(0.6666, Split)
	inst.components.healthtrigger:AddTrigger(0.3333, Split)
	
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)    
    inst.components.combat:SetDefaultDamage(37)
    inst.components.combat:SetAttackPeriod(4)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetHurtSound("dontstarve/sanity/creature1/death")
    inst.components.combat:SetRange(2, 2)
    ------------------
    
    ------------------
    
    inst:AddComponent("knownlocations")
    ------------------
    
    inst:AddComponent("inspectable")
    inst:ListenForEvent("attacked", OnAttacked)

    ------------------
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
    
    inst:SetStateGraph("SGum_shadow_characters")
    inst:SetBrain(brain) 
	inst:DoTaskInTime(0,EquipItems)
	inst:WatchWorldState("isday", function(inst) inst:Remove() end)
	inst.PlaySound = PlaySound
    return inst
end

local function FadeOut(inst)
	inst.opacity = inst.opacity - 0.02
	inst.AnimState:SetMultColour(0, 0, 0, inst.opacity)
	if inst.opacity > 0 then
		inst:DoTaskInTime(FRAMES,FadeOut)
	else
		inst:Remove()
	end
end

local function LabotomizedAttack(inst,axeholder,target)
	inst.target = target
	inst.axeholder = axeholder
	if target then
		inst:ForceFacePoint(target:GetPosition())
		inst.AnimState:PlayAnimation("atk_pre",false)
		inst.AnimState:PushAnimation("atk",false)
		inst:DoTaskInTime(FRAMES*11,function(inst)
			if inst.target and inst.target:IsValid() and inst.axeholder and inst:GetDistanceSqToInst(inst.target) < 9 and inst.target.components.combat and inst.target.components.health and not inst.target.components.health:IsDead() then
				inst.target.components.combat:GetAttacked(inst.axeholder,inst.attack)
			end
			FadeOut(inst)
		end)
	end
end

local function LabotomizedWork(inst,axeholder,target)
	inst.target = target
	inst.axeholder = axeholder
	if target then
		inst:ForceFacePoint(target:GetPosition())
		inst.AnimState:PlayAnimation("chop_pre",false)
		inst.AnimState:PushAnimation("chop_loop",false)
		inst:DoTaskInTime(FRAMES*20,function(inst)
			if inst.target and inst.target:IsValid() and inst.axeholder and inst:GetDistanceSqToInst(inst.target) < 9 and inst.target.components.workable and not target:HasTag("stump") then
				inst.target.components.workable:WorkedBy(inst.axeholder,inst.work)
			end
			FadeOut(inst)
		end)
	end
end

local function FadeIn(inst)
	inst.opacity = inst.opacity + 0.1
	inst.AnimState:SetMultColour(0, 0, 0, inst.opacity)
	if inst.opacity ~= 0.6 then
		inst:DoTaskInTime(FRAMES,FadeIn)
	end
end

local function fnlabotomized(Sim)
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
	inst:DoTaskInTime(3,function(inst) inst:Remove() end) --Failsafe
    return inst
end

return Prefab("swilson", fn, assets, prefabs),
Prefab("swilson_labotomized", fnlabotomized, assets, prefabs) --"Labotomized" as in, doesn't have a brain (or a SG)
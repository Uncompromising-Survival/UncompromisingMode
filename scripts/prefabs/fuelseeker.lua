require "stategraphs/SGmindweaver"

--local brain = require "brains/swilsonbrain"
local assets =
{
    Asset("ANIM", "anim/mindweaver.zip"),
}

local prefabs =
{
}

SetSharedLootTable("fuelseeker",
{
    { "nightmarefuel",  0.5 },
})

local sounds =
{
    burst = "UCSounds/um_fuelseeker/burst",
    windup = "UCSounds/um_fuelseeker/windup",
    attacked = "UCSounds/um_fuelseeker/attacked",
    death = "UCSounds/um_fuelseeker/death",
    appear = "UCSounds/um_fuelseeker/appear",
    suck = "UCSounds/um_fuelseeker/suck",
    idle = "UCSounds/um_fuelseeker/idle",
}

local brain = require "brains/fuelseekerbrain"

local function ChangeFire(inst)
	inst.fire_num = inst.fire_num + 1
	print("firelevel == "..inst.firelevel)
	--inst.AnimState:OverrideSymbol("flames_wide_"..inst.old_fire_num, "um_fuelseeker", "flames_wide_"..inst.fire_num)
	--inst.AnimState:ClearOverrideSymbol("flames_wide")
	inst.AnimState:OverrideSymbol("flames_wide", "um_fuelseeker", "flames_wide_"..inst.firelevel.."_"..inst.fire_num)
	--inst.AnimState:OverrideSymbol("flames_wide", "um_fuelseeker", "flames_wide_1_"..inst.fire_num)

	inst.old_fire_num = inst.fire_num
	
	if inst.fire_num >= 8 then
		inst.fire_num = 0
	end
end

local function SeekerLevelUp(inst)
	inst.level = inst.level + 0.2
	print("level update"..inst.level)
	
	if inst.level <= 1 then
		print("level 1")
		inst.firelevel = 1
	elseif inst.level <= 2 then
		print("level 2")
		inst.firelevel = 2
	else
		print("level 3")
		inst.firelevel = 3
	end
end

local function SeekerReset(inst)
	inst.level = 0
	inst.firelevel = 1
end

local function fn(Sim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 1.5)
	RemovePhysicsColliders(inst)

	--inst.Transform:SetFourFaced()
	inst:AddTag("monster")
    inst:AddTag("hostile")   
    inst:AddTag("swilson") 
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")

    inst.AnimState:SetBank("um_fuelseeker")
    inst.AnimState:SetBuild("um_fuelseeker")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.AnimState:UsePointFiltering(true)
	
	inst.Transform:SetScale(1.15, 1.15, 1.15)

	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.old_fire_num = 1
	inst.fire_num = 1
	inst.level = 0
	inst.firelevel = 1
	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(400)
	
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 4
	
    inst:AddComponent("follower")
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('fuelseeker')
	
    inst:AddComponent("combat")

   -- inst:AddComponent("um_shadowcloaked") DO NOT GIVE THEM A SHADOW SHIELD THEY ARE A MENACE
	
    inst.sounds = sounds
	inst.cooldown = false
	
    inst:SetStateGraph("SGfuelseeker")
    inst:SetBrain(brain)
	
	inst.LevelUp = SeekerLevelUp
	inst.Reset = SeekerReset
	
	inst:DoPeriodicTask(.05, ChangeFire)

    return inst
end

local function circlefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("sporecloud")
    inst.AnimState:SetBuild("sporecloud")
	inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.Transform:SetScale(.44, .44, .44)

    inst.AnimState:PlayAnimation("sporecloud_pst")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.persists = false

    return inst
end

local function LevelUp(inst)
	inst.level = inst.level + 0.2
	inst.SoundEmitter:SetParameter("shadowfire", "intensity", inst.level / 6)
	inst.Transform:SetScale(inst.level / 2, inst.level / 2, inst.level / 2)
end

local function Reset(inst)
	inst.level = 0
	inst.SoundEmitter:SetParameter("shadowfire", "intensity", inst.level / 6)
	inst.Transform:SetScale(inst.level / 2, inst.level / 2, inst.level / 2)
end

local function darkfirefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("dragonfly_fx")
    inst.AnimState:SetBuild("dragonfly_fx")
    inst.AnimState:PlayAnimation("taunt")
	inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.persists = false

    return inst
end

local function darkfirepufffn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("halloween_embers")
    inst.AnimState:SetBuild("halloween_embers")
    inst.AnimState:PlayAnimation("puff_"..math.random(3))
	inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.persists = false

    return inst
end

local function darkfireringfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("shadow_teleport")
    inst.AnimState:SetBuild("shadow_teleport")
    inst.AnimState:PlayAnimation("portal_in")
	inst.AnimState:SetMultColour(0, 0, 0, .6)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)

    inst.persists = false

    return inst
end

return Prefab( "fuelseeker", fn, assets, prefabs),
		Prefab( "fuelseeker_circle", circlefn, assets, prefabs),
		Prefab( "fuelseeker_darkfire", darkfirefn, assets, prefabs),
		Prefab( "fuelseeker_darkfirepuff", darkfirepufffn, assets, prefabs),
		Prefab( "fuelseeker_darkfirering", darkfireringfn, assets, prefabs)
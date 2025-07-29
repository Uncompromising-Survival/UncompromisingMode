local normal_assets =
{
    Asset("ANIM", "anim/um_ribopod.zip"),
}

-----------------------------------------------------------------------------------------------------------------

local brain = require "brains/ribopodbrain"

local NORMAL_SOUNDS = {
    attack_spit  = "dontstarve/frog/attack_spit",
    attack_voice = "dontstarve/frog/attack_voice",
    die          = "dontstarve/frog/die",
    grunt        = "dontstarve/frog/grunt",
    walk         = "dontstarve/frog/walk",
    splat        = "dontstarve/frog/splat",
    wake         = "dontstarve/frog/wake",
}

-----------------------------------------------------------------------------------------------------------------

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "um_ribopod" }

local function retargetfn(inst)
	if not inst.components.health:IsDead() and not (inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep()) and inst.friend_tracking >= 3 then
        local target_dist = 12

        return FindEntity(inst, target_dist, function(guy)
            if not guy.components.health:IsDead() then
                return guy.components.inventory ~= nil
            end
        end,
        RETARGET_MUST_TAGS, -- see entityreplica.lua
        RETARGET_CANT_TAGS
        )
    end
end

local function ShouldSleep(inst)
    return false
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude) return dude:HasTag("um_ribopod") and not dude.components.health:IsDead() end, 5)
end

local function OnGoingHome(inst)
    SpawnPrefab("poof_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnTrapped(inst, data)
end

local function FriendTracking(inst)
	if inst.entity:IsAwake() then
		local x,y,z = inst.Transform:GetWorldPosition()
		local ribopods = TheSim:FindEntities(x,y,z,16,{"um_ribopod"})
		inst.friend_tracking = #ribopods
	end
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1, .3)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("um_ribopod")
    inst.AnimState:SetBuild("um_ribopod")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("animal")
    inst:AddTag("prey")
    inst:AddTag("hostile")
    inst:AddTag("smallcreature")
    inst:AddTag("um_ribopod")
    inst:AddTag("canbetrapped")



    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 4

    -- boat hopping enable.
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:SetStateGraph("SGum_ribopod")

    inst:SetBrain(brain)

    inst:AddComponent("health")

    inst:AddComponent("combat")
    inst.components.combat:SetRetargetFunction(3, retargetfn)

    inst:AddComponent("thief")

    MakeTinyFreezableCharacter(inst, "isopod_body")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("fishmeat_small", 1)
    inst.components.lootdropper:AddRandomLoot("boneshards", .25)
    inst.components.lootdropper.numrandomloot = 1

    inst:AddComponent("knownlocations")
    inst:AddComponent("inspectable")
	
	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
	inst.components.eater:SetCanEatHorrible()
	inst.components.eater:SetCanEatRaw()
	inst.components.eater.strongstomach = true -- can eat monster meat!
		
    inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("goinghome", OnGoingHome)

    MakeHauntablePanic(inst)
	
	inst.friend_tracking = 0
	inst:DoPeriodicTask(3,FriendTracking)
    return inst
end -- No burnable, fireproof

local function OnDropped(inst)

end

local function SoundPath(inst, event)
    return "dontstarve/creatures/spider/" .. event
end

local function normalfn()
    local inst = commonfn()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = NORMAL_SOUNDS

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetSleepTest(ShouldSleep)

    inst.components.health:SetMaxHealth(500)

    inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
    inst.components.combat:SetAttackPeriod(2.5)
	inst.components.combat:SetRange(1, 1)
	inst.Transform:SetScale(1.2,1.2,1.2)
	
	inst:ListenForEvent("ontrapped", OnTrapped)
	

    -----------------
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true    
	
	MakeFeedableSmallLivestock(inst, TUNING.RABBIT_PERISH_TIME, nil, OnDropped)
	
	inst.SoundPath = SoundPath
    return inst
end


return Prefab("um_ribopod", normalfn,normal_assets)

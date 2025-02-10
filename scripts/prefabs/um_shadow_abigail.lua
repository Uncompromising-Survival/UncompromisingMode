local assets =
{
    Asset("ANIM", "anim/player_ghost_withhat.zip"),
    Asset("ANIM", "anim/ghost_build.zip"),
    Asset("SOUND", "sound/ghost.fsb"),
}

local prefabs =
{
}

--local brain = require "brains/ghostbrain"
local brain = require "brains/um_shadow_abigailbrain"

local function retargetfn(inst)
    local maxrangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST
    local rangesq, rangesq1, rangesq2 = maxrangesq, math.huge, math.huge
    local target1, target2 = nil, nil
    for i, v in ipairs(AllPlayers) do
        if v.components.sanity:IsCrazy() and not v:HasTag("playerghost") then
            local distsq = v:GetDistanceSqToInst(inst)
            if distsq < rangesq then
                if inst.components.combat:CanTarget(v) then
                    target2 = v
                    rangesq2 = distsq
                    rangesq = math.max(rangesq1, rangesq2)
                end
            end
        end
    end

    if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
        --Targets with shadow dominance have higher priority within half targeting range
        --Force target switch if current target does not have shadow dominance
        return target1
    end
    return target2
end

local function OnAttacked(inst, data)
--    print("onattack", data.attacker, data.damage, data.damageresolved)

    if data.attacker == nil then
        inst.components.combat:SetTarget(nil)
    elseif not data.attacker:HasTag("noauradamage") then
       inst.components.combat:SetTarget(data.attacker)
    end
end

local COLLAPSIBLE_TAGS = { "player" }
local NON_COLLAPSIBLE_TAGS = { "playerghost" }

local function EmitBurst(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 3, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            if v.components.combat ~= nil
                and v.components.health ~= nil
                and not v:HasTag("bearger")
                and not v.components.health:IsDead() then
                if v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, 30)
                end
            end
        end
    end

    local cloud = SpawnPrefab("sporepack_circle")
    cloud.entity:SetParent(inst.entity)
	cloud.AnimState:SetMultColour(0,0,0,.6)
end

local function SpeedBoost(inst)
	inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED * 1.4
	inst.components.locomotor.runspeed = TUNING.GHOST_SPEED * 1.4
    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_girl_attack_LP", "angry")
	
	inst.speeddebuff_task = inst:DoTaskInTime(3, function()
		if inst.speeddebuff_task ~= nil then
			inst.speeddebuff_task:Cancel()
		end
		
		inst.speeddebuff_task = nil
		inst.SoundEmitter:KillSound("angry")
		
		inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED * .7
		inst.components.locomotor.runspeed = TUNING.GHOST_SPEED * .7
	end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
	
    inst.Light:Enable(false)

    MakeGhostPhysics(inst, .5, .5)

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild("ghost_abigail_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0,0,0,.6)
	inst.AnimState:HideSymbol("face")

    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("ghost")
    inst:AddTag("flying")
    inst:AddTag("noauradamage")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl_LP", "howl")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetBrain(brain)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED * .7
    inst.components.locomotor.runspeed = TUNING.GHOST_SPEED * .7
    inst.components.locomotor.pathcaps = { allowocean = true, ignorecreep = true }
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.directdrive = true

    inst:SetStateGraph("SGum_shadow_abigail")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("inspectable")
	
    inst:AddComponent("trader")
	
    inst:AddComponent("follower")
    inst.components.follower:KeepLeaderOnAttacked()
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.GHOST_HEALTH)
    inst.components.health.invincible = true

    inst:AddComponent("combat")
    inst.components.combat.defaultdamage = TUNING.GHOST_DAMAGE
    inst.components.combat.playerdamagepercent = TUNING.GHOST_DMG_PLAYER_PERCENT
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	
	inst:DoPeriodicTask(TUNING.GHOST_DMG_PERIOD, EmitBurst, .5)
	
    inst.SpeedBoost = SpeedBoost
	
	inst.persists = false

    inst:ListenForEvent("attacked", OnAttacked)
	
	inst:WatchWorldState("cycles", function() 
		if not inst.components.health:IsDead() then
			local x, y, z = inst.Transform:GetWorldPosition()
			SpawnPrefab("statue_transition").Transform:SetPosition(x, y, z)
			SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
			
			inst:Remove()
		end
	end)

    ------------------

    return inst
end

return Prefab("um_shadow_abigail", fn, assets, prefabs)
require("worldsettingsutil")

local prefabs =
{
    "bee",
    "killerbee",
    "honey",
    "honeycomb",
}

local assets =
{
    Asset("ANIM", "anim/um_beehive_moon.zip"),
    Asset("SOUND", "sound/bee.fsb"),
}

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/bee/bee_hive_LP", "loop")
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function StartSpawning(inst)
    if inst.components.childspawner ~= nil
        and not TheWorld.state.iswinter
        and not (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen()) then
        inst.components.childspawner:StartSpawning()
    end
end

local function StopSpawning(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:StopSpawning()
    end
end

-- local function OnIsDay(inst, isday)
    -- if isday then
        -- StartSpawning(inst)
    -- else
        -- StopSpawning(inst)
    -- end
-- end

local function BeginDegrade(inst)
	inst.components.timer:StartTimer("degrade",60*8+math.random()*60*8*4)
end

local function Revert(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local hives = TheSim:FindEntities(x,y,z,32,{"beehive"})
	if #hives < 3 and math.random() < 0.25 then
		SpawnPrefab("beehive").Transform:SetPosition(x,y,z)
	end
	local childspawner = inst.components.childspawner
	if childspawner then
		for i,bee in ipairs(childspawner.childrenoutside) do
			if bee.components.health and not bee.components.health:IsDead() then
				bee:RemoveComponent("lootdropper")
				bee:AddComponent("lootdropper") -- wipe the lootdropper component
				bee:RemoveComponent("workable")
				bee.components.health:Kill()
			end
		end
	end
	
	inst:Remove()
end

local function OnIgnite(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren()
    end
    inst.SoundEmitter:KillSound("loop")
    DefaultBurnFn(inst)
end

local function OnFreeze(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")
    inst.AnimState:PlayAnimation("frozen", true)
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")

    StopSpawning(inst)
end

local function OnThaw(inst)
    inst.AnimState:PlayAnimation("frozen_loop_pst", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
    inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
end

local function OnUnFreeze(inst)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:KillSound("thawing")
    inst.AnimState:ClearOverrideSymbol("swap_frozen")

    StartSpawning(inst)
end

local function OnKilled(inst)
    inst:RemoveComponent("childspawner")
    inst.AnimState:PlayAnimation("death", true)
    RemovePhysicsColliders(inst)

    inst.SoundEmitter:KillSound("loop")

    inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_destroy")
    inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function OnHit(inst, attacker, damage)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren(attacker, "um_bee_moon")
    end
    if not inst.components.health:IsDead() then
        inst.SoundEmitter:PlaySound("dontstarve/bee/beehive_hit")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", true)
    end
end
local HAUNTTARGET_MUST_TAGS = { "_combat" }
local HAUNTTARGET_CANT_TAGS = { "insect", "playerghost", "INLIMBO" }
local HAUNTTARGET_ONEOF_TAGS = { "character", "animal", "monster" }
local function OnHaunt(inst)
    if inst.components.childspawner == nil or
        not inst.components.childspawner:CanSpawn() or
        math.random() > TUNING.HAUNT_CHANCE_HALF then
        return false
    end

    local target = FindEntity(
        inst,
        25,
        function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        HAUNTTARGET_MUST_TAGS, --See entityreplica.lua (re: "_combat" tag)
        HAUNTTARGET_CANT_TAGS,
        HAUNTTARGET_ONEOF_TAGS
    )

    if target ~= nil then
        OnHit(inst, target)
        return true
    end
    return false
end

-- local function OnInit(inst)
    -- inst:WatchWorldState("isday", OnIsDay)
    -- OnIsDay(inst, TheWorld.state.isday)
-- end

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.BEEHIVE_RELEASE_TIME, TUNING.BEEHIVE_REGEN_TIME)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    --inst.MiniMapEntity:SetIcon("beehive.png")

    inst.AnimState:SetBank("um_beehive_moon")
    inst.AnimState:SetBuild("um_beehive_moon")
	inst.AnimState:PlayAnimation("enter", false)
    inst.AnimState:PushAnimation("idle", true)
	
    inst:AddTag("structure")
	inst:AddTag("lifedrainable") -- by batbat (since it normally doesn't drain from structures)
    inst:AddTag("beaverchewable") -- by werebeaver
    inst:AddTag("hive")
    inst:AddTag("beehive")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(900)
	inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)
    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "um_bee_moon"
    inst.components.childspawner.emergencychildname = "um_bee_moon"
	inst.components.childspawner.spawnperiod = 2
    inst.components.childspawner.emergencychildrenperplayer = 1
    inst.components.childspawner.canemergencyspawn = true
    inst.components.childspawner:SetMaxEmergencyChildren(2)
    inst.components.childspawner:SetEmergencyRadius(TUNING.BEEHIVE_EMERGENCY_RADIUS)
	
	inst.components.childspawner:SetRegenPeriod(60*4)
	inst.components.childspawner:SetSpawnPeriod(2)
	inst.components.childspawner:SetMaxChildren(3)
			
	inst:DoTaskInTime(0,function(inst) inst.components.childspawner:StartSpawning() end)
    -- if not TUNING.BEEHIVE_ENABLED then
        -- inst.components.childspawner.childreninside = 0
    -- end

    --inst:DoTaskInTime(0, OnInit)

    ---------------------
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "um_meathoney", "um_meathoney", "um_meathoney", "um_meatcomb" })
    ---------------------

    ---------------------
    MakeLargeBurnable(inst)
    inst.components.burnable:SetOnIgniteFn(OnIgnite)
    ---------------------

    ---------------------
    MakeMediumFreezableCharacter(inst)
    inst:ListenForEvent("freeze", OnFreeze)
    inst:ListenForEvent("onthaw", OnThaw)
    inst:ListenForEvent("unfreeze", OnUnFreeze)
    ---------------------

    inst:AddComponent("combat")
    inst.components.combat:SetOnHit(OnHit)
    inst:ListenForEvent("death", OnKilled)

    ---------------------
    MakeLargePropagator(inst)
    MakeSnowCovered(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    ---------------------

    inst.OnPreLoad = OnPreLoad

    inst:AddComponent("inspectable")
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

	inst.BeginDegrade = BeginDegrade
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone",Revert)
	
    return inst
end

return Prefab("um_beehive_moon", fn, assets, prefabs)

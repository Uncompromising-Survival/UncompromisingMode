local brain = require "brains/boulder_crabbrain"

local assets =
{
    Asset("ANIM", "anim/boulder_crab.zip"),
    Asset("ANIM", "anim/rock1_nobottom.zip"),
    Asset("ANIM", "anim/rock2_nobottom.zip"),
    Asset("ANIM", "anim/rock_flintless_nobottom.zip"),
    Asset("ANIM", "anim/rock7_nobottom.zip"),
    Asset("ANIM", "anim/rock_lichen_nobottom.zip"),
    Asset("ANIM", "anim/springrock1_nobottom.zip"),
    Asset("ANIM", "anim/springrock2_nobottom.zip"),
    Asset("ANIM", "anim/springrock3_nobottom.zip"),
}

local prefabs = 
{
    "boulder_crab_hole",
}

SetSharedLootTable('boulder_crab',
    {
        { 'rocks', 1.0 },
        { 'rocks', 1.0 },
        { 'meat',  1.0 },
        { 'rocks', 0.5 },
    })


local function NewCallBack(inst, worker, workleft, ...)
    local ret = inst._oldcallback(inst, worker, workleft, ...)
    if workleft <= 0 then
        --TheNet:Announce("rock broke")
        inst.crab.myrock = nil -- Tell the crab his rock broke
        inst.crab.rockdestroyedtime = GetTime()
    end
    return ret
end

local function GetRock(inst, rock)
    --TheNet:Announce("got my rock")
    if type(rock) ~= "string" then
        inst.myrock = nil
        return
    end

    inst.favoriterock = rock
    inst.myrock = SpawnPrefab(rock)
    inst.myrock:Hide()
    if inst.myrock:HasTag("boulder") then
        inst.myrock.AnimState:SetBuild(rock ~= "rock_moon" and rock.."_nobottom" or "rock7_nobottom")
    end
    RemovePhysicsColliders(inst.myrock)
    --inst.myrock.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.myrock.crab = inst

    inst.myrock._oldcallback = inst.myrock.components.workable.onwork
    inst.myrock.components.workable:SetOnWorkCallback(NewCallBack)

    if inst.components.health then -- Will leave this in incase it somehow bypasses.
        inst.components.health:SetAbsorptionAmount(rock == "rock_moon" and .9 or .75) -- .9 is Effective 5000 health (mine the rock off you hooligan). .75 is Effective 2000 health.
    end

    inst:DoTaskInTime(0, function(inst) -- Needs a delay.
        if inst.myrock and inst.myrock:IsValid() then
            inst.myrock.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.myrock.entity:AddFollower():FollowSymbol(inst.GUID, "swap_shell", 0, 110, 0, true)
            inst.myrock:Show()
        end
        if inst.temprock then
            inst.temprock:Remove()
            inst:Show()
        end
    end)
    inst.myrock.persists = false
end

local function GetStatus(inst, viewer)
    return inst.components.timer:TimerExists("startregenrock") and "NAKED" or "GENERIC"
end

local function onsave(inst, data)
    local rock = inst.myrock
    if rock and rock:IsValid() then data.myrock = rock.prefab end
    if inst.rockdestroyedtime ~= 0 then data.rockdestroyedtime = true end
    if inst.favoriterock then data.favoriterock = inst.favoriterock end
end

local function onload(inst, data)
    if data then
        if data.myrock and inst.components.health then GetRock(inst, data.myrock) end
        if data.rockdestroyedtime then inst.rockdestroyedtime = GetTime() end
        if data.favoriterock then inst.favoriterock = data.favoriterock end
    end
end

-- Combat
local SHARE_TARGET_DIST = 30
local function NormalRetarget(inst)
    local targetDist = 6
    return FindEntity(inst, targetDist, function(guy)
            if inst.components.combat:CanTarget(guy) and not guy:HasTag("bird") and not guy:HasTag("butterfly") and not guy:HasTag("bee") then
                return guy:HasTag("smallcreature") or guy:HasTag("tallbird")
            else
                return guy.prefab == "perd"
            end
        end)
end

local function keeptargetfn(inst, target)
    return target and target.components.combat and target.components.health
        and not target.components.health:IsDead() and not target:HasTag("epic")
end

local function ShouldRecoil(inst, attacker, weapon, damage)
    local rock = inst.myrock
    return rock and rock:IsValid() and attacker:HasTag("player"), damage
end

local function OnAttacked(inst, data)
    local attacker, damage = data and data.attacker, data and data.damage
    if attacker then
        local rock = inst.myrock
        if rock and rock:IsValid() and damage and math.abs(damage) > 0 then
            local workable = rock.components.workable
            if workable then
                local totalworkhits = 20
                local workamt = TUNING.ROCKS_MINE / totalworkhits
                local workamtpadding = .75 / workamt
                workable:WorkedBy(attacker, TUNING.ROCKS_MINE / (totalworkhits + workamtpadding))
            end -- 6 / 22
            PlayMiningFX(attacker, rock)
        end
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, function(dude)
            return dude:HasTag("rocky") and (dude.components.health and not dude.components.health:IsDead())
        end, 1)
    end
end

-- Sleep
local function ShouldSleep(inst)
    return DefaultSleepTest(inst)
end

local function ShouldWake(inst)
    return DefaultWakeTest(inst)
end

--[[local function Hide(inst)
    if inst._brainstopped then return end
    local rock = inst.myrock
    if not (inst.components.combat and inst.components.combat.target) and rock and rock:IsValid() and rock.AnimState:IsCurrentAnimation("full") then
        inst:PushEvent("hideunderrock")
    elseif rock and rock:IsValid() and rock.AnimState:IsCurrentAnimation("full") then
        inst:DoTaskInTime(5, Hide)
    end
end

local function Reveal(inst)
    if inst._brainstopped then return end
    inst:PushEvent("comeoutfromunderrock")
end

local function OnStartDay(inst)
    if inst._brainstopped then return end
    inst:DoTaskInTime(math.random(6, 10), Hide)
end

local function OnStartDusk(inst)
    if inst._brainstopped then return end
    if inst.hiding then inst:DoTaskInTime(math.random(6, 10), Reveal) end
end]]

local function SpawnHole(inst)
    local hole = SpawnPrefab("boulder_crab_hole")
    hole.Transform:SetPosition(inst.Transform:GetWorldPosition())
    hole.favoriterock = inst.favoriterock
    local timetilgrow = (8 * 60) * 6 -- 8 days standard
    hole.components.timer:StartTimer("regenrock", timetilgrow)
    inst:Remove()
end

local function RegenRockDone(inst, data)
    if data ~= nil then
        if data.name == "startregenrock" then
            if inst:IsAsleep() then
                inst.SpawnHole(inst)
            else
                inst.sg:GoToState("dig")
            end
        end
    end
end

local function OnCrabRemoved(inst)
    if inst.myrock and inst.myrock:IsValid() then inst.myrock:Remove() end
    inst:RemoveEventCallback("onremove", OnCrabRemoved)
end

local function OnCrabKilled(inst)
    if inst.myrock and inst.myrock:IsValid() then
        if inst.myrock.components.workable then
            inst.myrock.components.workable:Destroy(inst)
        else
            inst.myrock:Remove()
        end
    end
    inst:RemoveEventCallback("death", OnCrabKilled)
    inst:RemoveEventCallback("onremove", OnCrabRemoved)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()
    MakeCharacterPhysics(inst, 400, .5)

    inst.AnimState:SetBank("boulder_crab")
    inst.AnimState:SetBuild("boulder_crab")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('boulder_crab')

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    MakeMediumFreezableCharacter(inst, "body")

    inst:AddTag("animal")
    inst:AddTag("rocky") -- Boulder crab is same faction as Rock lobster (They're cousins)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(500)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetShouldRecoilFn(ShouldRecoil)
    inst.components.combat:SetDefaultDamage(34)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRange(3, 3)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)

    inst:AddComponent("knownlocations")
    ------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI, FOODTYPE.OMNI })
    inst.components.eater:SetCanEatHorrible()

    inst:SetStateGraph("SGboulder_crab")
    inst:SetBrain(brain)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", RegenRockDone)
    inst.lasthidetime = 0
    inst.rockdestroyedtime = 0

    --[[inst:WatchWorldState("startday", OnStartDay)
    inst:WatchWorldState("startdusk", OnStartDusk)]]
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death", OnCrabKilled)
    inst:ListenForEvent("onremove", OnCrabRemoved)

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst.SpawnHole = SpawnHole

    inst.GetRock = GetRock
    inst:DoTaskInTime(0, function(inst)
        if not inst.myrock and not inst.components.timer:TimerExists("startregenrock") then
            local rock = FindEntity(inst, 60, nil, {"boulder"})
            GetRock(inst, rock and rock.prefab or math.random() > .5 and "springrock1" or (math.random() > .5 and "springrock3" or "springrock2"))           
        end
    end)

    return inst
end

local function ReturnCrab(inst)
    local crab = SpawnPrefab("boulder_crab")
    crab.Transform:SetPosition(inst.Transform:GetWorldPosition())
    crab.favoriterock = inst.favoriterock
    GetRock(crab, crab.favoriterock)
    crab.sg:GoToState("emerge")
    inst:Remove()
end

local function HoleTimerDone(inst, data)
    if data ~= nil then
        if data.name == "regenrock" then
            ReturnCrab(inst)
        end
    end
end

local function onsavehole(inst, data)
    if inst.favoriterock then
        data.favoriterock = inst.favoriterock
    end
end

local function onloadhole(inst, data)
    if data and data.myrock and inst.components.health then
        GetRock(inst, data.myrock)
    end
    if data and data.favoriterock then
        inst.favoriterock = data.favoriterock
    end
end

local function fnhole()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity() -- May add hole icon later? Maybe not bc the hole is removed after the crab returns
    inst.entity:AddNetwork()

    inst.Transform:SetNoFaced()
    MakeCharacterPhysics(inst, 400, .5)
    RemovePhysicsColliders(inst)
    inst.AnimState:SetBank("boulder_crab")
    inst.AnimState:SetBuild("boulder_crab")
    inst.AnimState:PlayAnimation("im_dirt")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", HoleTimerDone)

    inst.OnSave = onsavehole
    inst.OnLoad = onloadhole
    inst.OnLoadPostPass = function(inst) 
        if inst.components.timer:TimerExists("regenrock") then 
            inst.AnimState:PlayAnimation("im_dirt") 
        else
            inst:Remove()
        end 
    end

    return inst
end

return Prefab("boulder_crab", fn, assets,prefabs),
    Prefab("boulder_crab_hole",fnhole)
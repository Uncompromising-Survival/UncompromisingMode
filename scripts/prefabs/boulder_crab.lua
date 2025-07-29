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
		{ 'meat',  1.0 },
        { 'rocks', 0.5 },
    })


local function NewCallBack(inst, worker, workleft)
    inst._oldcallback(inst, worker, workleft)
    if workleft <= 0 then
        --TheNet:Announce("rock broke")
        inst.crab.myrock = nil -- Tell the crab his rock broke
    end
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
    if rock ~= "rock_moon" then
        inst.myrock.AnimState:SetBuild(rock .. "_nobottom")
    else
        inst.myrock.AnimState:SetBuild("rock7_nobottom")
    end
    RemovePhysicsColliders(inst.myrock)
    --inst.myrock.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.myrock.crab = inst

    inst.myrock._oldcallback = inst.myrock.components.workable.onwork
    inst.myrock.components.workable:SetOnWorkCallback(NewCallBack)

    if inst.components.health ~= nil then                    -- Will leave this in incase it somehow bypasses
        if rock ~= "rock_moon" and rock ~= "rock_lichen" then
            inst.components.health:SetAbsorptionAmount(0.9)  -- Effective 5000 health (mine the rock off you hooligan)
        else
            inst.components.health:SetAbsorptionAmount(0.75) -- Effective 2000 health
        end
    end

    inst:DoTaskInTime(0, function(inst) -- Needs a delay.
        inst.myrock.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.myrock.entity:AddFollower():FollowSymbol(inst.GUID, "swap_shell", 0, 110, 0, true)

        if inst.temprock then
            inst.temprock:Remove()
            inst:Show()
        end
        inst.myrock:Show()
    end)
    inst.myrock.persists = false
end

local function GetStatus(inst, viewer)
    if inst.components.timer:TimerExists("regenrock") then
        return "HOLE"
    elseif inst.components.timer:TimerExists("startregenrock") then
        return "NAKED"
    else
        return "GENERIC"
    end
end


local function onsave(inst, data)
    if inst.myrock then
        data.myrock = inst.myrock.prefab
    end
    if inst.favoriterock then
        data.favoriterock = inst.favoriterock
    end
end

local function onload(inst, data)
    if data and data.myrock and inst.components.health then
        GetRock(inst, data.myrock)
    end
    if data and data.favoriterock then
        inst.favoriterock = data.favoriterock
    end
end

-- Combat
local SHARE_TARGET_DIST = 30

local function NormalRetarget(inst)
    local targetDist = 6
    return FindEntity(inst, targetDist,
        function(guy)
            if inst.components.combat:CanTarget(guy) and not guy:HasTag("bird") and not guy:HasTag("butterfly") and not guy:HasTag("bee") then
                return guy:HasTag("smallcreature") or guy:HasTag("tallbird")
            else
                return guy.prefab == "perd"
            end
        end)
end

local function keeptargetfn(inst, target)
    return target
        and target.components.combat
        and target.components.health
        and not target.components.health:IsDead() and not target:HasTag("EPIC")
end

local SHARE_TARGET_DIST = 30
local function OnAttacked(inst, data)
    if data and data.attacker then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
            function(dude) return dude:HasTag("rocky") and (dude.components.health and not dude.components.health:IsDead()) end, 1)
    end
end

-- Sleep
local function ShouldSleep(inst)
    return DefaultSleepTest(inst)
end

local function ShouldWake(inst)
    return DefaultWakeTest(inst)
end

local function Hide(inst)
    if not (inst.components.combat and inst.components.combat.target) and inst.myrock and (inst.myrock.components.workable.workleft == 5 or inst.myrock.components.workable.workleft == 6) then
        inst.sg:GoToState("hide_pre")
    elseif inst.myrock and (inst.myrock.components.workable.workleft == 5 or inst.myrock.components.workable.workleft == 6) then
        inst:DoTaskInTime(5, Hide)
    end
end

local function SpawnHole(inst)
	local hole = SpawnPrefab("boulder_crab_hole")
	hole.Transform:SetPosition(inst.Transform:GetWorldPosition())
	hole.favoriterock = inst.favoriterock
	local timetilgrow = (8*60)*8 -- 8 days standard
	hole.components.timer:StartTimer("regenrock",timetilgrow)
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
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(1, NormalRetarget)
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

    inst:WatchWorldState("startday", function(inst) inst:DoTaskInTime(math.random(6, 10), Hide) end)
    inst:WatchWorldState("startdusk", function(inst) if inst.hiding then inst:DoTaskInTime(math.random(6, 10), function(inst) inst.sg:GoToState("hide_pst") end) end end)
    inst:ListenForEvent("attacked", OnAttacked)


    inst.OnSave = onsave
    inst.OnLoad = onload
	
	inst.SpawnHole = SpawnHole
	

	
    inst.GetRock = GetRock
    inst:DoTaskInTime(0, function(inst)
        if not inst.myrock and not inst.components.timer:TimerExists("regenrock") then
			local rock = FindEntity(inst,60,nil,{"boulder"})
			if rock then
				GetRock(inst, rock.prefab)
			else
				if math.random() > 0.5 then
					GetRock(inst, "springrock1")
				else
					if math.random() > 0.5 then
						GetRock(inst, "springrock3")
					else
						GetRock(inst, "springrock2")
					end
				end			
			end
			if TheWorld.state.isday then
				inst.sg:GoToState("hide_pre")
			end			
		end
    end)

	inst.escape_stack = 0
    return inst
end

local function ReturnCrab(inst)
	local crab = SpawnPrefab("boulder_crab")
	crab.Transform:SetPosition(inst.Transform:GetWorldPosition())
	crab.favoriterock = inst.favoriterock
	GetRock(crab,crab.favoriterock)
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

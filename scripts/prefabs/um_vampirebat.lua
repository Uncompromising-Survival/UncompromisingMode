local assets =
{
    Asset("ANIM", "anim/bat_basic.zip"),
    Asset("ANIM", "anim/bat_vamp_build.zip"),
    Asset("ANIM", "anim/bat_vamp_shadow.zip"),
    Asset("SOUND", "sound/bat.fsb"),
    Asset("INV_IMAGE", "bat"),
}

local prefabs =
{
    "guano",
    "batwing",
    "teamleader",
    "pigskin",
    "monstersmallmeat",
}

local BrainCommon = require("brains/braincommon")
local brain = require "brains/batbrain"

local monstermeattype = TUNING.DSTU.MONSTERSMALLMEAT and "monstersmallmeat" or "monstermeat"

SetSharedLootTable("um_vampirebat",
{
    {monstermeattype, .25},
    {"pigskin", .05},
    {"batwing", .75},
})

SetSharedLootTable("um_vampirebat_acidinfused",
{
    {monstermeattype, .5},
    {"pigskin", .1},
    {"batwing", 1},
    {"nitre", .2},
})

local MAX_TARGET_SHARES = 100
local SHARE_TARGET_DIST = 100

local function IsValidMember(inst)
    return not BrainCommon.ShouldTriggerPanic(inst) and not BrainCommon.ShouldAvoidElectricFence(inst)
        and not (inst.components.burnable and inst.components.burnable:IsBurning())
end

local function CanMakeOrJoinTeam(inst, attacker)
    return IsValidMember(inst)
end

local function MakeTeam(inst, attacker)
    local leader = SpawnPrefab("teamleader")
    leader.components.teamleader:SetUp(attacker, inst)
    leader.components.teamleader:BroadcastDistress(inst)
end

local RETARGET_CANT_TAGS = {"bat", "batdisguise"}
local RETARGET_ONEOF_TAGS = {"character", "monster"}
local function IsValidTarget(guy, inst)
    return inst.components.combat:CanTarget(guy)
end

local function Retarget(inst)
    local ta = inst.components.teamattacker

    local newtarget = FindEntity(inst, TUNING.BAT_TARGET_DIST, IsValidTarget, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)

    if newtarget and not ta.inteam and CanMakeOrJoinTeam(inst, newtarget) and not ta:SearchForTeam() then
        MakeTeam(inst, newtarget)
    end

    if ta.inteam and not ta.teamleader:CanAttack() then
        return newtarget
    end
end

local function KeepTarget(inst, target)
    return (inst.components.teamattacker.inteam and not inst.components.teamattacker.teamleader:CanAttack())
        or inst.components.teamattacker.orders == ORDERS.ATTACK
end

local function IsBat(dude)
    return dude:HasTag("bat")
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if not attacker then
        return
    end

    if not inst.components.teamattacker.inteam and CanMakeOrJoinTeam(inst, data.attacker) and not inst.components.teamattacker:SearchForTeam() then
        MakeTeam(inst, data.attacker)
    elseif inst.components.teamattacker.teamleader then
        inst.components.teamattacker.teamleader:BroadcastDistress(inst) -- Ask for help!
    end

    if inst.components.teamattacker.inteam and not inst.components.teamattacker.teamleader:CanAttack() then
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsBat, MAX_TARGET_SHARES)
    end
end

local function OnNewCombatTarget(inst, data)
    local target = data and data.target or nil
    if target == nil then
        return
    end

    if not inst.components.teamattacker.inteam and CanMakeOrJoinTeam(inst, target) and not inst.components.teamattacker:SearchForTeam() then
        MakeTeam(inst, target)
    elseif inst.components.teamattacker.teamleader then
        inst.components.teamattacker.teamleader:BroadcastDistress(inst) -- Ask for help!
    end
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
    function(dude) return IsBat(dude) and not dude.components.health:IsDead() end, 5)
end

--[[local function onsave(inst, data)
    if inst:HasTag("batfrenzy") then
        data.batfrenzy = true
    end
end

local function onload(inst, data)
    if data then
        if data.batfrenzy then
            inst:AddTag("batfrenzy")
        end
    end
end]]

local function OnSleepGoHome(inst)
    inst._hometask = nil
    local home = inst.components.homeseeker and inst.components.homeseeker.home
    if home and home:IsValid() and home.components.childspawner then
        home.components.childspawner:GoHome(inst)
    end
end

local function OnIsDay(inst, isday)
    if isday then
        if not inst._hometask then
            inst._hometask = inst:DoTaskInTime(10 + math.random(), OnSleepGoHome)
        end
    elseif inst._hometask then
        inst._hometask:Cancel()
        inst._hometask = nil
    end
end

local function StopWatchingDay(inst)
    inst:StopWatchingWorldState("isday", OnIsDay)
    if inst._hometask then
        inst._hometask:Cancel()
        inst._hometask = nil
    end
end

local function StartWatchingDay(inst)
    inst:WatchWorldState("isday", OnIsDay)
    OnIsDay(inst, TheWorld.state.isday)
end

local function OnEntitySleep(inst)
    inst:ListenForEvent("enterlimbo", StopWatchingDay)
    inst:ListenForEvent("exitlimbo", StartWatchingDay)
    if not inst:IsInLimbo() then
        StartWatchingDay(inst)
    end
end

local function OnEntityWake(inst)
    inst:RemoveEventCallback("enterlimbo", StopWatchingDay)
    inst:RemoveEventCallback("exitlimbo", StartWatchingDay)
    if not inst:IsInLimbo() then
        StopWatchingDay(inst)
    end
end

local function OnPreLoad(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    if y > 0 then
        inst.Transform:SetPosition(x, 0, z)
    end
end

local function BatSleepTest(inst, ...)
    if inst.components.acidinfusible and inst.components.acidinfusible:IsInfused() then
        return false
    end
    return NocturnalSleepTest(inst, ...)
end

local DIET = {FOODTYPE.MEAT}
local ACIDDIET = {FOODTYPE.MEAT, FOODTYPE.NITRE}

local function OnInfuse(inst)
    inst.AnimState:SetSymbolAddColour("bat_eye", .2, .5, 0, 0)
    inst.AnimState:SetSymbolLightOverride("bat_eye", .5)

    inst.components.lootdropper:SetChanceLootTable("um_vampirebat_acidinfused")

    inst.components.combat:SetRetargetFunction(1, Retarget)

    inst.components.eater:SetDiet(ACIDDIET, ACIDDIET)
    inst.components.eater:ResetEdibleTagsCache()

    if not inst.components.thief then
        inst:AddComponent("thief")
    end
end

local function OnUninfuse(inst)
    inst.AnimState:SetSymbolAddColour("bat_eye", 0, 0, 0, 0)
    inst.AnimState:SetSymbolLightOverride("bat_eye", 0)

    inst.components.lootdropper:SetChanceLootTable("um_vampirebat")

    inst.components.combat:SetRetargetFunction(3, Retarget)

    inst.components.eater:SetDiet(DIET, DIET)
    inst.components.eater:ResetEdibleTagsCache()

    if inst.components.thief then
        inst:RemoveComponent("thief")
    end
end

local function CalcSanityAura(inst, observer)
    return inst.components.acidinfusible:IsInfused() and -TUNING.SANITYAURA_LARGE or -TUNING.SANITYAURA_MED
end

local function GetStatus(inst)--, viewer)
    return inst.components.acidinfusible:IsInfused() and "ACID" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeGhostPhysics(inst, 1, .5)

    inst.DynamicShadow:SetSize(1.5, .75)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(.9, .9, .9)

    inst.AnimState:SetBank("bat")
    inst.AnimState:SetBuild("bat_vamp_build")

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("bat")
    inst:AddTag("scarytoprey")
    inst:AddTag("flying")
    inst:AddTag("ignorewalkableplatformdrowning")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_scale = .9
    inst.override_combat_fx_size = "small"

    local locomotor = inst:AddComponent("locomotor")
    locomotor:EnableGroundSpeedMultiplier(false)
    locomotor:SetTriggersCreep(false)
    locomotor.walkspeed = 10
    locomotor.pathcaps = {allowocean = true}

    inst:SetStateGraph("SGum_vampirebat")
    inst:SetBrain(brain)

    local eater = inst:AddComponent("eater")
    eater:SetDiet(DIET, DIET)
    eater:SetStrongStomach(true)

    local sleeper = inst:AddComponent("sleeper")
    sleeper:SetResistance(3)
    sleeper.sleeptestfn = BatSleepTest
    sleeper.waketestfn = NocturnalWakeTest

    local combat = inst:AddComponent("combat")
    combat.hiteffectsymbol = "bat_body"
    combat:SetDefaultDamage(25)
    combat:SetAttackPeriod(1.8)
    combat:SetHitArc(TUNING.DEFAULT_HIT_ARC)
    combat:SetRetargetFunction(3, Retarget)
    combat:SetKeepTargetFunction(KeepTarget)

    local health = inst:AddComponent("health")
    health:SetMaxHealth(130)

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetChanceLootTable("um_vampirebat")

    inst:AddComponent("inventory")

    local periodicspawner = inst:AddComponent("periodicspawner")
    periodicspawner:SetPrefab("guano")
    periodicspawner:SetRandomTimes(120, 240)
    periodicspawner:SetDensityInRange(30, 2)
    periodicspawner:SetMinimumSpacing(8)
    periodicspawner:Start()

    local inspectable = inst:AddComponent("inspectable")
    inspectable.getstatus = GetStatus

    inst:AddComponent("knownlocations")

    local sanityaura = inst:AddComponent("sanityaura")
    sanityaura.aurafn = CalcSanityAura

    MakeMediumBurnableCharacter(inst, "bat_body")
    MakeMediumFreezableCharacter(inst, "bat_body")

    --inst:DoTaskInTime(1*FRAMES, function() inst.components.knownlocations:RememberLocation("home", Vector3(inst.Transform:GetWorldPosition()), true) end)

    --inst:AddComponent("tiletracker")
    --inst.components.tiletracker:SetOnWaterChangeFn(OnWaterChange)

    local teamattacker = inst:AddComponent("teamattacker")
    teamattacker:SetValidMemberFn(IsValidMember)
    teamattacker.team_type = "bat" --"um_vampirebat"

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
    inst:ListenForEvent("onattackother", OnAttackOther)
    --inst:ListenForEvent("death", OnKilled)

    local acidinfusible = inst:AddComponent("acidinfusible")
    acidinfusible:SetFXLevel(3)
    acidinfusible:SetDamageMultiplier(TUNING.ACIDRAIN_BAT_DAMAGE_MULT)
    acidinfusible:SetSpeedMultiplier(TUNING.ACIDRAIN_BAT_SPEED_MULT)
    acidinfusible:SetOnInfuseFn(OnInfuse)
    acidinfusible:SetOnUninfuseFn(OnUninfuse)

    MakeHauntablePanic(inst)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.OnPreLoad = OnPreLoad

    --[[inst.OnSave = onsave
    inst.OnLoad = onload]]

    return inst
end

--[[local function OnWingDownShadow(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_flap")
end

local function dodive(inst)
    if not TheCamera.interior and inst:IsOnValidGround() then
        local bat = SpawnPrefab("vampirebat")
        local spawn_pt = Vector3(inst.Transform:GetWorldPosition())
        if bat and spawn_pt then
            local x, y, z = spawn_pt:Get()
            bat.Transform:SetPosition(x, y + 30, z)
            bat:FacePoint(GetPlayer().Transform:GetWorldPosition())
            bat.sg:GoToState("glide")
            bat:AddTag("batfrenzy")

            bat:DoTaskInTime(2,
            function() bat:PushEvent("attacked", { attacker = GetPlayer(), damage = 0, weapon = nil }) end)
        end
        inst:Remove()
    else
        inst.task = inst:DoTaskInTime(5 + (math.random() * 2), function() dodive(inst) end)
    end
end


local function onsaveshadow(inst, data)
    if inst.task then
        data.task = inst:TimeRemainingInTask(inst.task)
    end
end

local function onloadshadow(inst, data)
    if data then
        if data.task then
            inst.task = inst:DoTaskInTime(data.task, function() dodive(inst) end)
        end
    end
end

local function circlingbatfn()
    local inst = CreateEntity()

    MakeAmphibiousGhostPhysics(inst, 1, .5)

    inst.AnimState:SetBank("bat_vamp_shadow")
    inst.AnimState:SetBuild("bat_vamp_shadow")
    inst.AnimState:PlayAnimation("shadow_flap_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 10

    inst:AddComponent("circler")
    inst.components.circler.track = 8

    inst.dodive = dodive

    inst.AnimState:SetMultColour(1, 1, 1, 0)
    inst:AddComponent("colourtweener")
    if not TheWorld.state.isnight then
        inst.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 3)
    end

    inst.persists = false

    inst:ListenForEvent("wingdown", OnWingDownShadow)
    -- flap sound
    inst:DoPeriodicTask(10 / 30, function() inst:PushEvent("wingdown") end)
    -- screech sound
    inst:DoPeriodicTask(1, function()
        if math.random() < 0.1 then
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/vampire_bat/distant_taunt")
        end
    end)

    inst:ListenForEvent("daytime", function()
        if not GetSeasonManager() or not GetSeasonManager():IsWinter() then
            inst.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 3)
        end
    end, GetWorld())

    inst:ListenForEvent("nighttime", function()
        inst.components.colourtweener:StartTween({ 1, 1, 1, 0 }, 3)
    end, GetWorld())

    inst.task = inst:DoTaskInTime(20 + (math.random() * 2), function() dodive(inst) end)

    inst.OnSave = onsaveshadow
    inst.OnLoad = onloadshadow

    return inst
end]]

return Prefab("um_vampirebat", fn, assets, prefabs) --[[,
    Prefab("badlands/objects/circlingbat", circlingbatfn, assets, prefabs)]]
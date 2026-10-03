local brain = require("brains/swilsonbrain")

local assets =
{
    Asset("ANIM", "anim/lavaarena_beetletaur.zip"),
    Asset("ANIM", "anim/lavaarena_beetletaur_basic.zip"),
    Asset("ANIM", "anim/lavaarena_beetletaur_actions.zip"),
    Asset("ANIM", "anim/lavaarena_beetletaur_block.zip"),
    Asset("ANIM", "anim/lavaarena_beetletaur_fx.zip"),
    Asset("ANIM", "anim/lavaarena_beetletaur_break.zip"),
    Asset("ANIM", "anim/uncompromising_buffrat.zip"),
    Asset("ANIM", "anim/healing_flower.zip"),
    Asset("ANIM", "anim/fossilized.zip"),
}

SetSharedLootTable('um_buffrat',
{
    {'chester',     1.0},
    {'glommer',     1.0},
})

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
    return target and target.components.combat and target.components.health and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    if data ~= nil and data.damage ~= nil then
        inst.damage = data.damage + inst.damage
        if inst.damage > 100 and inst.mode ~= "offense" and not inst.sg:HasStateTag("jumping") then
            inst.mode = "offense"
            inst.sg:GoToState("offense_pre")
        end
    end
end

local function UpdateMode(inst)
    if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
        if inst:GetDistanceSqToInst(inst.components.combat.target) > 60 and inst.mode ~= "defence" then
            inst.mode = "defence"
            inst.sg:GoToState("defence_pre")
        end
    else
        inst.mode = "offense"
        inst.sg:GoToState("offense_pre")
    end
    inst.damage = 0
end

local function ShouldSleep(inst)
    return false
end

local function ShouldWake(inst)
    return true
end

local function fn(Sim)
    local inst = CreateEntity()

    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    local shadow = inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    MakeCharacterPhysics(inst, 10, .5)

    shadow:SetSize( 1.5, .5 )
    trans:SetFourFaced()

    anim:SetBank("beetletaur")
    anim:SetBuild("uncompromising_buffrat")
    anim:PlayAnimation("idle_loop",true)

    inst:AddTag("raidrat")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local locomotor = inst:AddComponent("locomotor")
    locomotor.walkspeed = 3
    locomotor.runspeed = 6

    inst:SetStateGraph("SGum_buffrat")

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetChanceLootTable('um_buffrat')

    local health = inst:AddComponent("health")
    health:SetMaxHealth(2000)

    inst:SetBrain(brain)

    local combat = inst:AddComponent("combat")
    combat.hiteffectsymbol = "torso"
    combat:SetKeepTargetFunction(keeptargetfn)
    combat:SetDefaultDamage(34)
    combat:SetAttackPeriod(3)
    combat:SetRetargetFunction(1, NormalRetarget)
    combat:SetHurtSound("dontstarve/sanity/creature1/death")
    combat:SetRange(4, 4)
    inst:ListenForEvent("attacked", OnAttacked)

    local sleeper = inst:AddComponent("sleeper")
    sleeper:SetSleepTest(ShouldSleep)
    sleeper:SetWakeTest(ShouldWake)
    sleeper:SetResistance(5)   

    inst:AddComponent("knownlocations")

    --inst.Transform:SetScale(0.75,0.75,0.75)

    inst.punchcount = 0
    inst.damage = 0
    inst.mode = "offense"

    inst:DoPeriodicTask(2, UpdateMode)

    return inst
end

return Prefab("um_buffrat", fn, assets)
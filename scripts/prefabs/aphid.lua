require "stategraphs/SGaphid"

local assets =
{
    Asset("ANIM", "anim/aphid.zip"),
}

local prefabs =
{
    "monstersmallmeat",
}

SetSharedLootTable("aphid_loot",
{
	{ UM_CONFIG.MONSTERSMALLMEAT and 'monstersmallmeat' or 'monstermeat', 0.25 },
	{ 'steelwool', 0.33 },
})

local brain = require "brains/aphidbrain"

local function OnIsWinter(inst, iswinter)
    if iswinter then
        if not (inst.leavetask and inst:IsInLimbo()) then
            inst.leavetask = inst:DoTaskInTime(math.random(3, 8), function(_inst) -- AXE Add some randomization to their removal
                _inst.leavetask = nil
                if TheWorld.state.iswinter and not _inst:IsInLimbo() then
                    if not _inst:IsAsleep() then
                        _inst:PushEvent("flyintree")
                    else
                        _inst:Remove()
                    end
                end
            end)
        end
    else
        if inst.leavetask then
            inst.leavetask:Cancel()
            inst.leavetask = nil
        end
    end
end

local function OnPutInInventory(inst, owner)
    OnIsWinter(inst)
end

local function OnDropped(inst)
    inst.sg:GoToState("idle")
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(1)
    end
    if inst.components.stackable then
        while inst.components.stackable:StackSize() > 1 do
            local item = inst.components.stackable:Get()
            if item then
                if item.components.inventoryitem then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(inst.Transform:GetWorldPosition())
            end
        end
    end
    OnIsWinter(inst, TheWorld.state.iswinter)
end

local function retargetfn(inst)
    local dist = 12
    local notags = { "FX", "NOCLICK", "INLIMBO", "wall", "aphid", "structure", "aquatic", "smallcreature" }
    return FindEntity(inst, dist, function(guy)
        return inst.components.combat:CanTarget(guy)
    end, nil, notags)
end

local function keeptargetfn(inst, target)
    return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
        return dude:HasTag("aphid") and not dude.components.health:IsDead()
    end, 10)
end

local function OnFlyIn(inst)
    inst.DynamicShadow:Enable(false)
    inst.components.health:SetInvincible(true)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, 15, z)
end

local function OnWorked(inst, worker)
    if worker.components.inventory ~= nil then
        inst.SoundEmitter:KillAllSounds()
        worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
    end
end

local function OnEat(inst)
    inst.full_belly = true
    inst:DoTaskInTime(30, function(_inst)
        _inst.full_belly = nil
    end)
end

local DIET = {FOODGROUP.OMNI, FOODTYPE.WOOD, FOODTYPE.SEEDS, FOODTYPE.ROUGHAGE}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("weevole")
    inst.AnimState:SetBuild("aphid")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("insect")
    inst:AddTag("hostile")
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    inst:AddTag("aphid")
    inst:AddTag("animal")
    inst:AddTag("donotautopick")
    
    MakeInventoryFloatable(inst)

    MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    -- locomotor must be constructed before the stategraph!
    local locomotor = inst:AddComponent("locomotor")
    locomotor:SetSlowMultiplier(1)
    locomotor:SetTriggersCreep(false)
    locomotor.pathcaps = { ignorecreep = true }
    locomotor.walkspeed = 5

    inst:AddComponent("inventory")

    inst:AddComponent("stackable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem.canbepickedup = false
    inventoryitem.canbepickedupalive = true
    inventoryitem.nobounce = true
    inventoryitem.pushlandedevents = false

    inst:AddComponent("tradable")

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetChanceLootTable("aphid_loot")

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.NET)
    workable:SetWorkLeft(1)
    workable:SetOnFinishCallback(OnWorked)

    local health = inst:AddComponent("health")
    health:SetMaxHealth(100)

    local combat = inst:AddComponent("combat")
    combat.hiteffectsymbol = "body"
    combat:SetKeepTargetFunction(keeptargetfn)
    combat:SetRetargetFunction(3, retargetfn)
    combat:SetDefaultDamage(10)
    combat:SetAttackPeriod(GetRandomMinMax(1, 3))
    combat:SetRange(5, 2)
    combat:SetPlayerStunlock(PLAYERSTUNLOCK.RARELY)

	inst:AddComponent("follower")
    inst:AddComponent("knownlocations")

    inst:ListenForEvent("attacked", OnAttacked)

    local eater = inst:AddComponent("eater")
    eater:SetDiet(DIET, DIET)
    eater:SetOnEatFn(OnEat)

    inst:SetStateGraph("SGaphid")
    inst:SetBrain(brain)

    -- AXE if they spawn from a hole, we may want to consider removing this watch world state
    inst:WatchWorldState("iswinter", OnIsWinter)
    OnIsWinter(inst, TheWorld.state.iswinter)

    MakeFeedableSmallLivestock(inst, TUNING.BUTTERFLY_PERISH_TIME, OnPutInInventory, OnDropped)

    MakeSmallBurnableCharacter(inst, "body")
    MakeSmallFreezableCharacter(inst, "body")

    inst:ListenForEvent("fly_in", OnFlyIn) -- matches enter_loop logic so it does not happen a frame late

    if IsSWEnabled() then
        local appeasement = inst:AddComponent("appeasement")
        appeasement.appeasementvalue = TUNING.TOTAL_DAY_TIME
    end

    return inst
end

return Prefab("aphid", fn, assets, prefabs)

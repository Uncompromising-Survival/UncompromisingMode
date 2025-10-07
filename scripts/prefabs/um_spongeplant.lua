local assets =
{
    Asset("ANIM", "anim/um_spongeplant.zip"),
    Asset("ANIM", "anim/um_spongeplant.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local function OnRegen(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.components.shaveable.prize_count = 1
    if not inst.components.pickable then
        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil)
	    inst.components.pickable:SetStuck(true)
    end
end

local function OnShaved(inst, shaver, shave_item)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lichen")
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked", false)
    inst.components.shaveable.prize_count = 0
    if not inst.components.timer:TimerExists("regrow") then
        inst.components.timer:StartTimer("regrow", TUNING.TOTAL_DAY_TIME * 4)
    end
    inst:RemoveComponent("pickable")
end

local function CanShave(inst, shaver, shave_item)
    return inst.components.shaveable.prize_count > 0
end

local function mine_up(inst, worker)
    for i = 1, 3 do
        inst.components.lootdropper:SpawnLootPrefab("marble")
    end
    if inst.components.shaveable.prize_prefab and inst.components.shaveable.prize_count > 0 then
        inst.components.lootdropper:SpawnLootPrefab(inst.components.shaveable.prize_prefab)
    end
    inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "regrow" then
        OnRegen(inst)
    end
end

local function OnLoad(inst, data)
    if inst.components.timer:TimerExists("regrow") then
        inst.AnimState:PlayAnimation("picked")
    end
end

local function plant(name, stage)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        --inst.entity:AddMiniMapEntity() -- Remind Lidemo about Map Icon
        inst.entity:AddNetwork()

        --inst.MiniMapEntity:SetIcon("grass.png")

        inst.AnimState:SetBank("um_spongeplant")
        inst.AnimState:SetBuild("um_spongeplant")
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("plant")
        inst:AddTag("lunarplant_target")
        inst:AddTag("bearded")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --RemovePhysicsColliders(inst)
        inst.AnimState:SetTime(math.random() * 2)
        local color = .75 + math.random() * .25
        inst.AnimState:SetMultColour(color, color, color, 1)

        local shaveable = inst:AddComponent("shaveable")
        shaveable:SetPrize("um_spongeplant_item", 1)
        shaveable.can_shave_test = CanShave
        shaveable.on_shaved = OnShaved

        inst:AddComponent("pickable")
	    inst.components.pickable:SetUp(nil)
	    inst.components.pickable:SetStuck(true)

        --[[inst:AddComponent("witherable")

        if stage == 1 then
            inst.components.pickable:MakeBarren()
        end]]

        inst:AddComponent("lootdropper")

        inst:AddComponent("inspectable")

        if not GetGameModeProperty("disable_transplanting") then
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.MINE)
            inst.components.workable:SetOnFinishCallback(mine_up)
            inst.components.workable:SetWorkLeft(9)
        end

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)
        ---------------------

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)

        inst.OnLoad = OnLoad

        return inst
    end

    return Prefab(name, fn, assets)
end

local function oneatenfn(inst, eater)
    if eater.components.moisture then
        eater.components.moisture:DoDelta(-5)
    end
end

local function item()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_spongeplant_item")
    inst.AnimState:SetBuild("um_spongeplant")
    inst.AnimState:PlayAnimation("idle")
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    --inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDIUMITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 3
    inst.components.edible.hungervalue = 18.75
    inst.components.edible.sanityvalue = -10
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible:SetOnEatenFn(oneatenfn)

    inst:AddComponent("perishable")
    inst:AddComponent("tradable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST) -- 6 days
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return plant("um_spongeplant", 0),
    Prefab("um_spongeplant_item", item)
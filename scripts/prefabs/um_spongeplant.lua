local assets =
{
    Asset("ANIM", "anim/um_spongeplant.zip"),
    Asset("ANIM", "anim/um_spongeplant.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst.components.beard.bits = 1
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function onpickedfn(inst, picker)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lichen")
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked", false)
end

local function mine_up(inst, worker)
    for i = 1, 3 do
        inst.components.lootdropper:SpawnLootPrefab("marble")
    end
    if inst.components.beard and inst.components.beard.bits and inst.components.beard.bits > 0 then
        inst.components.beard:Shave(worker)
    end
    inst:Remove()
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

        inst:AddComponent("beard")
        inst.components.beard.bits = 1
        inst.components.beard.daysgrowth = TUNING.BEEFALO_HAIR_GROWTH_DAYS+1
        inst.components.beard.onreset = onpickedfn
        inst.components.beard.canshavetest = function() return true end
        inst.components.beard.prize = "um_spongeplant_item"
        inst.components.beard:AddCallback(TUNING.BEEFALO_HAIR_GROWTH_DAYS, onregenfn)
		inst.components.beard.direct_deposit = true

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
        ---------------------

        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)

        inst:DoTaskInTime(0, function(inst)
            inst.AnimState:PlayAnimation(inst.components.beard and inst.components.beard.bits and inst.components.beard.bits > 0 and "idle" or "picked")
        end)
        ---------------------
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
local assets =
{
    Asset("ANIM", "anim/um_fyrite.zip"),
}

local function OnExplodeFn(inst)
    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnPutInInv(inst, owner)
    if owner.prefab == "mole" then
        inst.components.explosive:OnBurnt()
    end
    if inst.explodetask then
        inst.explodetask:Cancel()
    end
    inst.explodetask = nil
    if inst.sparktask then
        inst.sparktask:Cancel()
    end
    inst.sparktask = nil
end

local function spark(inst)
    local fx = SpawnPrefab("electrichitsparks_electricimmune")
    local randomsize = math.random() + 0.33
    fx.entity:SetParent(inst.entity)
    fx.Transform:SetScale(randomsize * .66, randomsize * .66, randomsize * .66)
    if math.random() <= 0.3 then
        inst.sparktask = inst:DoTaskInTime(math.random() * 2, spark)
    else
        inst.sparktask = inst:DoTaskInTime(math.random() * 0.5, spark)
    end
end

local function OnQuakeBegin(inst)
    inst._quaking = true
    if not inst.components.inventoryitem.owner then
        if inst.sparktask == nil then
            inst.sparktask = inst:DoTaskInTime(math.random() + 1, spark)
        end
        inst.explodetask = inst:DoTaskInTime(math.random() + 8, function()
            if inst._quaking and not inst.components.inventoryitem.owner then
                inst.components.explosive:OnBurnt()
            end
        end)
    end
end

local function OnQuakeEnd(inst)
    inst._quaking = nil
    if inst.sparktask then
        inst.sparktask:Cancel()
    end
    inst.sparktask = nil
end

--[[local function OnDropped(inst)
    if inst._quaking then
        OnQuakeBegin(inst)
    end
end]]

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_fyrite")
    inst.AnimState:SetBuild("um_fyrite")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("quakedebris")
    inst:AddTag("explosive")

	MakeInventoryFloatable(inst, "med", nil, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("explosive")
    inst.components.explosive:SetOnExplodeFn(OnExplodeFn)
    inst.components.explosive.explosivedamage = TUNING.GUNPOWDER_DAMAGE / 4

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInv)
    --inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("bait")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    MakeHauntableLaunch(inst)

    inst._quaking = nil
    inst:ListenForEvent("startquake", function() OnQuakeBegin(inst) end, TheWorld.net)
    inst:ListenForEvent("endquake", function() OnQuakeEnd(inst) end, TheWorld.net)

    return inst
end

return Prefab("um_fyrite", fn, assets)
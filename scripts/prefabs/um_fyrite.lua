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
        inst.explodetask = nil
    end
    if inst.sparktask then
        inst.sparktask:Cancel()
        inst.sparktask = nil
    end
end

local function spark(inst)
    local fx = SpawnPrefab("electrichitsparks_electricimmune")
    local randomsize = (math.random() + .33) * .66
    fx.entity:SetParent(inst.entity)
    fx.Transform:SetScale(randomsize, randomsize, randomsize)
    inst.sparktask = inst:DoTaskInTime(math.random() * (math.random() <= .3 and 2 or .5), spark)
end

local function OnQuakeBegin(inst)
    inst._quaking = true
    if not inst.components.inventoryitem.owner then
        if not inst.sparktask then
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
        inst.sparktask = nil
    end
end

--[[local function OnDropped(inst)
    if inst._quaking then
        OnQuakeBegin(inst)
    end
end]]

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    local network = inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    anim:SetBank("um_fyrite")
    anim:SetBuild("um_fyrite")
    anim:PlayAnimation("idle")

    inst:AddTag("molebait")
    inst:AddTag("quakedebris")
    inst:AddTag("explosive")

    MakeInventoryFloatable(inst, "med", nil, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    local stackable = inst:AddComponent("stackable")
    stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    local explosive = inst:AddComponent("explosive")
    explosive:SetOnExplodeFn(OnExplodeFn)
    explosive.explosivedamage = TUNING.GUNPOWDER_DAMAGE / 4

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem:SetOnPutInInventoryFn(OnPutInInv)
    --inventoryitem:SetOnDroppedFn(OnDropped)
    inventoryitem:SetSinks(true)

    inst:AddComponent("bait")

    MakeHauntableLaunch(inst)

    inst._quaking = nil
    inst:ListenForEvent("startquake", function() OnQuakeBegin(inst) end, TheWorld.net)
    inst:ListenForEvent("endquake", function() OnQuakeEnd(inst) end, TheWorld.net)

    return inst
end

return Prefab("um_fyrite", fn, assets)
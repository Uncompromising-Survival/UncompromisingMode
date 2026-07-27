local assets =
{
    Asset("ANIM", "anim/um_moontear.zip"),
    Asset("ANIM", "anim/moonrock_seed.zip"),
}

local function startcrying(inst)
    local owner = inst.components.inventoryitem.owner

    if owner and owner.components.inventoryitem then
        owner = owner.components.inventoryitem.owner
    end

    local moisture = owner.components.moisture
    if owner and not owner:HasTag("waterproofer") and moisture and moisture:GetMoisture() < 48 then
        moisture:DoDelta(3)
    end
end

local function topockettear(inst, owner)
    if not inst.task then
        inst.task = inst:DoPeriodicTask(1, startcrying)
    end
end

local function togroundtear(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("moonrock_seed")
    inst.AnimState:SetBuild("moonrock_seed")
    inst.AnimState:OverrideSymbol("seed", "um_moontear", "seed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("donotautopick")--sucks to pick this up on accident lol

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem.nobounce = true
    inventoryitem:SetSinks(true)

    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("onputininventory", topockettear)
    inst:ListenForEvent("ondropped", togroundtear)

    return inst
end

return Prefab("moon_tear", fn, assets, prefabs)

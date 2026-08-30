local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_piggyback.zip"),
}

local function CreateBase()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("sporecloud_base")
    inst.AnimState:SetBuild("sporecloud_base")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(-1)

    inst.AnimState:PlayAnimation("sporecloud_base_pst")
    --inst.AnimState:PlayAnimation("sporecloud_base_pre")
    --inst.AnimState:PushAnimation("sporecloud_base_pst", false)

    inst.Transform:SetScale(.6, .6, .6)
    inst.AnimState:SetMultColour(1, 1, 1, .7)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .5)
    --inst:ListenForEvent("animqueueover", function(inst) inst:Remove() end)
    inst:ListenForEvent("animover", function(inst) inst:Remove() end)

    inst.persists = false

    return inst
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "swap_sporepack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_sporepack", "swap_body")
    inst.components.container:Open(owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    inst.components.container:Close(owner)
end

local function DoSporeRefresh(inst)
    for k, v in pairs(inst.components.container.slots) do
        if v.components.perishable and v:HasAnyTag("spore", "spore_special") then
            v.components.perishable:ReducePercent(-.005)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("sporepack_map.tex")

    inst.AnimState:SetBank("sporepack")
    inst.AnimState:SetBuild("sporepack")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst:AddTag("backpack")
    inst:AddTag("sporepack")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst, "med", .1, .65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("piggyback")
        end
        return inst
    end

    inst:AddComponent("inspectable")

    local inventoryitem = inst:AddComponent("inventoryitem")
    inventoryitem.cangoincontainer = false

    local equippable = inst:AddComponent("equippable")
    equippable.equipslot = EQUIPSLOTS.BACK or EQUIPSLOTS.BODY
    equippable:SetOnEquip(onequip)
    equippable:SetOnUnequip(onunequip)

    local waterproofer = inst:AddComponent("waterproofer")
    waterproofer:SetEffectiveness(0)

    local container = inst:AddComponent("container")
    container:WidgetSetup("piggyback")

    local preserver = inst:AddComponent("preserver")
    preserver:SetPerishRateMultiplier(2)

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst.sporerefresh_task = inst:DoPeriodicTask(3, DoSporeRefresh)

    return inst
end

return Prefab("sporepack", fn, assets),
    Prefab("sporepack_circle", CreateBase, assets)
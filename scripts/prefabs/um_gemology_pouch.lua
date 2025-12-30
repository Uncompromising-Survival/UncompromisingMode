local assets =
{
    Asset("ANIM", "anim/ui_slingshotammo_container_3x2.zip"),
    Asset("ANIM", "anim/slingshotammo_container.zip"),
    --Asset("INV_IMAGE", "um_gemology_pouch_open"),
}

local prefabs =
{

}

-----------------------------------------------------------------------------------------------

local SOUNDS =
{
    open  = "meta5/walter/ammo_bag_open",
    close = "meta5/walter/ammo_bag_close",
}

-----------------------------------------------------------------------------------------------

local function OnOpen(inst)
    inst.AnimState:PlayAnimation("open")

    --inst.components.inventoryitem:ChangeImageName("um_gemology_pouch_open")
    inst.SoundEmitter:PlaySound(inst._sounds.open)
end

local function OnClose(inst)
    if inst.components.inventoryitem.owner == nil then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)
    else
        inst.AnimState:PlayAnimation("closed", false)
    end

    --inst.components.inventoryitem:ChangeImageName("um_gemology_pouch")
    inst.SoundEmitter:PlaySound(inst._sounds.close)
end

local function OnPutInInventory(inst)
    inst.components.container:Close()
    inst.AnimState:PlayAnimation("closed", false)
end

-----------------------------------------------------------------------------------------------

local FLOATABLE_SWAP_DATA = { anim = "closed" }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("slingshotammo_container.png")

    inst.AnimState:SetBank("slingshotammo_container")
    inst.AnimState:SetBuild("slingshotammo_container")
    inst.AnimState:PlayAnimation("closed")

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "med", .05, .7, nil, nil, FLOATABLE_SWAP_DATA)

    inst.entity:SetPristine()

    inst:AddTag("portablestorage")
    inst:AddTag("wardrobe_item") -- Uncompromising mode

    if not TheWorld.ismastersim then
        return inst
    end

    inst._sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("um_gemology_pouch")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    --inst.components.inventoryitem:ChangeImageName("um_gemology_pouch")

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end


return Prefab("um_gemology_pouch", fn, assets, prefabs)
local assets =
{
    Asset("ANIM", "anim/um_gemology_pouch.zip"),
    Asset("IMAGE", "images/map_icons/um_gemology_pouch.tex"),
    Asset("ATLAS", "images/map_icons/um_gemology_pouch.xml"),
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
    inst.AnimState:PlayAnimation("idle_opened")

    inst.components.inventoryitem:ChangeImageName("um_gemology_pouch_open")
    inst.SoundEmitter:PlaySound(inst._sounds.open)
end

local function OnClose(inst)
    if inst.components.inventoryitem.owner == nil then
        inst.AnimState:PushAnimation("idle_closed", false)
    else
        inst.AnimState:PlayAnimation("idle_closed", false)
    end

    inst.components.inventoryitem:ChangeImageName("um_gemology_pouch")
    inst.SoundEmitter:PlaySound(inst._sounds.close)
end

local function OnPutInInventory(inst)
    inst.components.container:Close()
    inst.AnimState:PlayAnimation("idle_closed", false)
end

-----------------------------------------------------------------------------------------------

local FLOATABLE_SWAP_DATA = { anim = "idle_closed" }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("um_gemology_pouch.tex")

    inst.AnimState:SetBank("um_gemology_pouch")
    inst.AnimState:SetBuild("um_gemology_pouch")
    inst.AnimState:PlayAnimation("idle_closed")

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
    inst.components.inventoryitem.atlasname = "images/inventoryimages/um_gemology_pouch.xml"
    inst.components.inventoryitem:ChangeImageName("um_gemology_pouch")

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end


return Prefab("um_gemology_pouch", fn, assets, prefabs)

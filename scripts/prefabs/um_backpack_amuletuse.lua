local assets = {
    Asset("ANIM", "anim/um_backpack_amuletuse.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_red.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_red.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_blue.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_blue.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_purple.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_purple.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_green.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_green.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_orange.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_orange.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_yellow.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_yellow.zip"),

    --[[Asset("ANIM", "anim/um_backpack_amuletuse_pink.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_pink.zip"),

    Asset("ANIM", "anim/um_backpack_amuletuse_ice_blue.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse_ice_blue.zip"),]]
}

local function onequip(inst, owner)
    inst.owner = owner
    local amuseitem = inst.amuseitem and inst.amuseitem:IsValid() and inst.amuseitem
    if inst.AmusementEquipFn and amuseitem then
        inst.AmusementEquipFn(amuseitem, inst.owner)
        if inst.AmusementEquipFn2 then                               -- AXE Modded amulets can also define these if they so choose.
            inst:AmusementEquipFn2(inst.owner, amuseitem) -- Triggered for things relevent to the amusement pack
        end
        --AXE Undo anything that visually changed
        if owner.sg == nil or owner.sg.currentstate.name ~= "amulet_rebirth" then
            owner.AnimState:ClearOverrideSymbol("swap_body")
        end

        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end
    end

    -- At last step, change the symbols to be the amusementpack
    local swapbuild = "swap_um_backpack_amuletuse" .. (inst.color and ("_" .. inst.color) or "")
    owner.AnimState:OverrideSymbol("swap_body", swapbuild, "backpack")
    owner.AnimState:OverrideSymbol("swap_body", swapbuild, "swap_body")
    inst.components.container:Open(owner)
end

local function onunequip(inst, owner)
    local amuseitem = inst.amuseitem and inst.amuseitem:IsValid() and inst.amuseitem
    if inst.AmusementUnequipFn and amuseitem then
        inst.AmusementUnequipFn(amuseitem, inst.owner)
        if inst.AmusementUnequipFn2 then -- AXE Modded amulets can also define these if they so choose.
            inst:AmusementUnequipFn2(inst.owner, amuseitem)
        end
    end
    -- Last step.
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    inst.components.container:Close(owner)
    inst.owner = nil
end

local function ClearAmusementIfAny(inst)
    local amuseitem = inst.amuseitem and inst.amuseitem:IsValid() and inst.amuseitem
    if inst.AmusementUnequipFn and amuseitem and inst.owner then
        inst.AmusementUnequipFn(amuseitem, inst.owner)
        if inst.AmusementUnequipFn2 then -- AXE Modded amulets can also define these if they so choose.
            inst:AmusementUnequipFn2(inst.owner, amuseitem)
        end
    end

    inst.components.equippable.dapperness = 0
    inst.components.equippable.walkspeedmult = nil
    inst.AmusementEquipFn = nil
    inst.AmusementUnequipFn = nil
    inst.AmusementEquipFn2 = nil
    inst.AmusementUnequipFn2 = nil
    inst.amuseitem = nil
    inst.color = nil

    if inst.owner then
        onequip(inst, inst.owner)
    end
    inst.AnimState:SetBuild("um_backpack_amuletuse")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/um_backpack_amuletuse.xml"
    inst.components.inventoryitem:ChangeImageName("um_backpack_amuletuse")
end

local function SetupAmusement(inst, item)
    --its still the same item, so we skip doing anything.
    if inst.amuseitem == item then return end

    if inst.amuseitem then
        ClearAmusementIfAny(inst)
    end
    inst.amuseitem = item
    -- AXE make the dapperness more efficient if implemented through the amusement pack
    inst.components.equippable.dapperness = item.components.equippable.dapperness

    inst.AmusementEquipFn = item.components.equippable.onequipfn
    inst.AmusementUnequipFn = item.components.equippable.onunequipfn

    local buildname = inst.color and ("um_backpack_amuletuse_" .. inst.color) or "um_backpack_amuletuse"
    inst.AnimState:SetBuild(buildname)
    inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. buildname .. ".xml"
    inst.components.inventoryitem:ChangeImageName(buildname)

    if inst.owner then -- I'm being worn, I should activate the effects
        onequip(inst, inst.owner)
    end
end

local function CheckToSeeIfAmuletChanged(inst)
    local item = inst.components.container:GetItemInSlot(9)
    if item then
        local data = inst.supported_amulets[item.prefab]
        if data then
            -- AXE Also allow modded definition of function calls for the amusement pack from within modded prefabs
            inst.AmusementEquipFn2 = item.UM_AmusementEquipFn or data.onequipfn
            inst.AmusementUnequipFn2 = item.UM_AmusementUnequipFn or data.onunequipfn
            inst.color = item.UM_AmusementColor or data.color
            SetupAmusement(inst, item)
            return
        end
    end
    ClearAmusementIfAny(inst)
end

local function OnContainerChanged(inst)
    inst.components.inventoryitem.cangoincontainer = inst.components.container:IsEmpty() or false
    CheckToSeeIfAmuletChanged(inst)
end

-- AXE These functions are for additional things that may not be triggered by calling the amulet's onequip function, like heater
local function BlueEquip(inst, owner)
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = TUNING.BLUEGEM_COOLER
end

local function BlueUnEquip(inst, owner)
    inst:RemoveComponent("heater")
end

local function YellowEquip(inst, owner, amuseitem)
    local fueled = amuseitem and amuseitem.components.fueled
    if fueled and fueled:IsEmpty() then
        inst.components.equippable.dapperness = 0
        return
    end
    inst.components.equippable.walkspeedmult = 1.2
    inst.components.equippable.dapperness = amuseitem.components.equippable.dapperness
    if fueled then
        inst._yellow_orig_depleted = fueled.depleted
        fueled:SetDepletedFn(function(depleted_inst)
            inst.components.equippable.walkspeedmult = nil
            inst.components.equippable.dapperness = 0
            if inst._yellow_orig_depleted then
                inst._yellow_orig_depleted(depleted_inst)
            end
        end)
    end
end

local function YellowUnEquip(inst, owner, amuseitem)
    inst.components.equippable.walkspeedmult = 1
    if inst._yellow_orig_depleted ~= nil and amuseitem and amuseitem:IsValid() and amuseitem.components.fueled then
        amuseitem.components.fueled:SetDepletedFn(inst._yellow_orig_depleted)
    end
    inst._yellow_orig_depleted = nil
end

local supportedAmulets = {
    ["amulet"] = { name = "amulet", color = "red" },
    ["blueamulet"] = { name = "blueamulet", onequipfn = BlueEquip, onunequipfn = BlueUnEquip, color = "blue" },
    ["purpleamulet"] = { name = "purpleamulet", color = "purple" },
    ["yellowamulet"] = { name = "yellowamulet", onequipfn = YellowEquip, onunequipfn = YellowUnEquip, color = "yellow" },
    ["orangeamulet"] = { name = "orangeamulet", color = "orange" },
    ["greenamulet"] = { name = "greenamulet", color = "green" },
    ["ancient_amulet_red"] = { name = "ancient_amulet_red", color = "red" }
    --[[Mod compat: CF, WL
    ["cherryamulet"] = { name = "cherryamulet", color = "pink" },
    ["frostwalkeramulet"] = { name = "frostwalkeramulet", onequipfn = BlueEquip, onunequipfn = BlueUnEquip, color = "ice_blue" },]]
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("um_backpack_amuletuse.tex")

    inst.AnimState:SetBank("um_backpack_amuletuse")
    inst.AnimState:SetBuild("um_backpack_amuletuse")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst:AddTag("backpack")
    inst:AddTag("pocketbackpack")
    inst:AddTag("donotautopick")

    MakeInventoryFloatable(inst, "med", 0.1, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("um_backpack_amuletuse")
        end
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/um_backpack_amuletuse.xml"
    inst.components.inventoryitem:ChangeImageName("um_backpack_amuletuse")
    inst:ListenForEvent("itemlose", OnContainerChanged)
    inst:ListenForEvent("itemget", OnContainerChanged)

    inst:AddComponent("equippable")
    if EQUIPSLOTS["BACK"] ~= nil then
        inst.components.equippable.equipslot = EQUIPSLOTS.BACK
    else
        inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    end

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("container")
    inst.components.container.itemtestfn = function(container, item)
        return true --container.inst.components.equippable.isequipped or not container:IsEmpty()
    end
    inst.components.container:WidgetSetup("um_backpack_amuletuse")

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst.supported_amulets = supportedAmulets
    return inst
end

return Prefab("um_backpack_amuletuse", fn, assets)

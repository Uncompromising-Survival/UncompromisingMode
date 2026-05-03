local assets = {
    Asset("ANIM", "anim/um_backpack_amuletuse.zip"),
    Asset("ANIM", "anim/swap_um_backpack_amuletuse.zip"),
}

local function onequip(inst, owner)
    inst.owner = owner
    if inst.AmusementEquipFn and inst.amuseitem then
        TheNet:Announce("equip")

        inst.AmusementEquipFn(inst.amuseitem,inst.owner)
        if inst.AmusementEquipFn2 then -- AXE Modded amulets can also define these if they so choose.
            inst.AmusementEquipFn2(inst,inst.owner,inst.amuseitem) -- Triggered for things relevent to the amusement pack
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
    owner.AnimState:OverrideSymbol("swap_body", "swap_um_backpack_amuletuse", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_um_backpack_amuletuse", "swap_body")
    inst.components.container:Open(owner)
    
end

local function onunequip(inst, owner)
    if inst.AmusementUnequipFn and inst.amuseitem then
        TheNet:Announce("unequip")
        inst.AmusementUnequipFn(inst.amuseitem,inst.owner)
        if inst.AmusementUnequipFn2 then -- AXE Modded amulets can also define these if they so choose.
            inst.AmusementUnequipFn2(inst,inst.owner,inst.amuseitem)
        end
    end
    -- Last step.
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    inst.components.container:Close(owner)
    inst.owner = nil
end

local function ClearAmusementIfAny(inst)
    TheNet:Announce("clear amusement")
    if inst.AmusementUnequipFn and inst.amuseitem and inst.owner then
        TheNet:Announce("unequip")
        inst.AmusementUnequipFn(inst.amuseitem,inst.owner)
        if inst.AmusementUnequipFn2 then -- AXE Modded amulets can also define these if they so choose.
            inst.AmusementUnequipFn2(inst,inst.owner,inst.amuseitem)
        end       
    end
    
    inst.components.equippable.dapperness = 0
    inst.AmusementEquipFn = nil
    inst.AmusementUnequipFn = nil
    inst.AmusementEquipFn2 = nil
    inst.AmusementUnequipFn2 = nil  
    inst.amuseitem = nil

    if inst.owner then
        onequip(inst, inst.owner)
    end
end

local function SetupAmusement(inst,item,index)  
    TheNet:Announce("setup amusement")
    if inst.amuseitem then
        ClearAmusementIfAny(inst)
    end
    inst.amuseitem = item
    inst.components.equippable.dapperness = item.components.equippable.dapperness*1.5 -- AXE make the dapperness more efficient if implemented through the amusement pack

    inst.AmusementEquipFn = item.components.equippable.onequipfn
    inst.AmusementUnequipFn = item.components.equippable.onunequipfn
    if inst.owner then -- I'm being worn, I should activate the effects
        TheNet:Announce("re-equip")
        onequip(inst, inst.owner)
    end
end

local function CheckToSeeIfAmuletChanged(inst)
    local item = inst.components.container:GetItemInSlot(9)
    TheNet:Announce("moved")
    if item then
        TheNet:Announce("found item "..item.prefab)
    end

    local index
    if item then
        for i,v in pairs(inst.supported_amulets) do
            if v.name == item.prefab then
                index = i
                if v.onequipfn then
                    inst.AmusementEquipFn2 = v.onequipfn
                end
                if v.onunequipfn then
                    inst.AmusementUnequipFn2 = v.onunequipfn       
                end
                
                -- AXE Also allow modded definition of function calls for the amusement pack
                if item.UM_AmusementEquipFn then
                    inst.AmusementEquipFn2 = item.UM_AmusementEquipFn
                end
                if item.UM_AmusementUnequipFn then
                    inst.AmusementUnequipFn2 = item.UM_AmusementUnequipFn
                end                
                
                break
            end
        end
    end
    if index then
        SetupAmusement(inst,item)
    else
        ClearAmusementIfAny(inst)
    end
end

local function OnContainerChanged(inst)
    if inst.components.container:IsEmpty() then
        inst.components.inventoryitem.cangoincontainer = true
    else
        inst.components.inventoryitem.cangoincontainer = false 
    end
    CheckToSeeIfAmuletChanged(inst)
end

-- AXE These functions are for additional things that may not be triggered by calling the amulet's onequip function, like heater
local function BlueEquip(inst,owner)
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = TUNING.BLUEGEM_COOLER * 1.5
end

local function BlueUnEquip(inst,owner)
    inst:RemoveComponent("heater")
end

local function YellowEquip(inst,owner)
    inst.components.equippable.walkspeedmult = 1.3
end

local function YellowUnEquip(inst,owner)
    inst.components.equippable.walkspeedmult = 1
end

local supportedAmulets = {
    ["amulet"] = {name = "amulet"},
    ["blueamulet"] = {name = "blueamulet",onequipfn = BlueEquip, onunequipfn = BlueUnEquip},
    ["purpleamulet"] = {name = "purpleamulet"},
    ["yellowamulet"] = {name = "yellowamulet",onequipfn = YellowEquip, onunequipfn = YellowUnEquip},
    ["orangeamulet"] = {name = "orangeamulet"},
    ["greenamulet"] = {name = "greenamulet"},
    ["ancient_amulet_red"] = {name = "ancient_amulet_red"}
}


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("sporepack_map.tex")

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
        return true--container.inst.components.equippable.isequipped or not container:IsEmpty()
    end
    inst.components.container:WidgetSetup("um_backpack_amuletuse")


    MakeHauntableLaunchAndDropFirstItem(inst)


    inst.supported_amulets = supportedAmulets


    TheNet:Announce("AXE - WARNING")
    TheNet:Announce("This item is not complete yet. Interaction will likely result in crash.")
    TheNet:Announce("Execute ''c_removeall('um_backpack_amuletuse')'' to prevent crashing.")
    return inst
end

return Prefab("um_backpack_amuletuse", fn,assets)
local function AddSilk(inst)
    local silk = SpawnPrefab("silk")
    inst.components.container:GiveItem(silk, 9)

    inst.components.timer:StartTimer("webby", 480)
end

local function onequip(inst, owner)
    if not owner:HasTag("vetcurse") then
        inst:DoTaskInTime(0, function(inst)
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner --do we really need to get the owner again?
            if owner ~= nil and not owner:HasTag("vetcurse") then                                      --check (again)
                local tool = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                if tool ~= nil and owner ~= nil then
                    owner.components.inventory:Unequip(EQUIPSLOTS.BODY)
                    owner.components.inventory:DropItem(tool)
                    --owner.components.inventory:GiveItem(inst)
                    owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")

                    if owner.sg ~= nil then
                        owner.sg:GoToState("hit")
                    end
                end
            end
        end)
    else
        owner.AnimState:OverrideSymbol("swap_body", "swap_silksack", "backpack")
        owner.AnimState:OverrideSymbol("swap_body", "swap_silksack", "swap_body")
        inst.components.container:Open(owner)
    end

    if not inst.components.timer:TimerExists("webby") then
        inst.components.timer:StartTimer("webby", 480)
    else
        inst.components.timer:ResumeTimer("webby")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    inst.components.container:Close(owner)
    if inst.components.timer:TimerExists("webby") then
        inst.components.timer:PauseTimer("webby")
    end
end

local function OnTimerDone(inst, data)
    if data.name == "webby" then
        AddSilk(inst)
    end
end

local function CanWrap(inst) -- The backpack is good to go
    local container = inst.components.container

    if container then
        local silk, bundle
        for i = 1, 9 do
            local item = container:GetItemInSlot(i)
            if item then
                if item.prefab == "silk" then
                    silk = item
                elseif i ~= 7 and i ~= 8 and item.components.bundle then
                    bundle = item
                end

            end
        end
        return silk and silk.components.stackable.stacksize >= 6 and not bundle
    end
end

local function WrapStuff(inst, owner)
    if CanWrap(inst) then
        local bundle = SpawnPrefab("silken_bundle")
        local pos = inst:GetPosition()
        if owner then
            pos = owner:GetPosition()
        end

        --Consume Silk
        local silk = inst.components.container:GetItemInSlot(9)
        if silk.components.stackable and silk.components.stackable.stacksize > 6 then
            silk.components.stackable:SetStackSize(silk.components.stackable.stacksize - 6)
        else
            inst.components.container:RemoveItemBySlot(9)
        end

        local items = {}
        for i = 1, 6 do
            local item = inst.components.container:GetItemInSlot(i)
            if item ~= nil and not item:HasTag("irreplaceable") then -- and not (item.components.edible and item.components.perishable) then --Initially disallowed food, instead rework to not protect against spoilage
                table.insert(items, item)
                inst.components.container:RemoveItemBySlot(i)
            end
        end

        bundle.components.unwrappable:WrapItems(items, inst)
        for i, v in ipairs(items) do
            v:Remove()
        end
        bundle.timebundled = (TheWorld.state.time + TheWorld.state.cycles) * 8 * 60 --shouldn't we use GetTime instead?
        inst.components.container:GiveItem(bundle, inst.components.container:GetItemInSlot(7) == nil and 7 or 8, pos, true)
        return true
    elseif owner and owner.components.talker then
        owner.components.talker:Say(GetString(owner, "ACTIONFAIL_GENERIC"))
        return false
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("sporepack_map.tex")

    inst.AnimState:SetBank("silksack")
    inst.AnimState:SetBuild("silksack")
    inst.AnimState:PlayAnimation("idle")


    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst:AddTag("backpack")
    inst:AddTag("vetcurse_item")

    MakeInventoryFloatable(inst, "med", 0.1, 0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup("silksack")
        end
        return inst
    end

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.atlasname = "images/inventoryimages/silksack.xml"

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
    inst.components.container:WidgetSetup("silksack")


    MakeHauntableLaunchAndDropFirstItem(inst)

    inst.WrapStuff = WrapStuff

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("silksack", fn)

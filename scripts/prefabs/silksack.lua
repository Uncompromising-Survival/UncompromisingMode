
local function onequip(inst, owner)
    if not owner:HasTag("vetcurse") then
        inst:DoTaskInTime(0, function(inst, owner)
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner
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
        end)
    else
		owner.AnimState:OverrideSymbol("swap_body", "swap_silksack", "backpack")
		owner.AnimState:OverrideSymbol("swap_body", "swap_silksack", "swap_body")
		inst.components.container:Open(owner)
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	owner.AnimState:ClearOverrideSymbol("backpack")
	inst.components.container:Close(owner)
end

local function ChecksOut(inst) -- The backpack is good to go
	if inst.components.container then
		local _container = inst.components.container
		--return _container:GetItemInSlot(7). == "silk"
		return _container:GetItemInSlot(7) and _container:GetItemInSlot(7).prefab == "silk" and _container:GetItemInSlot(7).components.stackable and _container:GetItemInSlot(7).components.stackable:StackSize() >= 6 and 
		not _container:GetItemInSlot(8) and
		(_container:GetItemInSlot(1) or _container:GetItemInSlot(2) or _container:GetItemInSlot(6) or 
		_container:GetItemInSlot(4) or _container:GetItemInSlot(5) or _container:GetItemInSlot(6)) and 
		not (_container:GetItemInSlot(1) and _container:GetItemInSlot(1):HasTag("bundle")) and
		not (_container:GetItemInSlot(2) and _container:GetItemInSlot(2):HasTag("bundle")) and
		not (_container:GetItemInSlot(3) and _container:GetItemInSlot(3):HasTag("bundle")) and
		not (_container:GetItemInSlot(4) and _container:GetItemInSlot(4):HasTag("bundle")) and
		not (_container:GetItemInSlot(5) and _container:GetItemInSlot(5):HasTag("bundle")) and
		not (_container:GetItemInSlot(6) and _container:GetItemInSlot(6):HasTag("bundle"))
	end
end

local function WrapStuff(inst,owner)
	if ChecksOut(inst) then
		local bundle = SpawnPrefab("silken_bundle")
		local pos = inst:GetPosition()
		if owner then
			pos = owner:GetPosition()
		end
		
		--Consume Silk
		local silk = inst.components.container:GetItemInSlot(7)
		if silk.components.stackable and silk.components.stackable.stacksize > 6 then
			silk.components.stackable:SetStackSize(silk.components.stackable.stacksize-6)
		else
			inst.components.container:RemoveItemBySlot(7)
		end

		local items = {}
		for i = 1, 6 do
			local item = inst.components.container:GetItemInSlot(i)
			if item ~= nil then -- and not (item.components.edible and item.components.perishable) then --Initially disallowed food, instead rework to not protect against spoilage
				table.insert(items, item)
				inst.components.container:RemoveItemBySlot(i)
			end
		end
		bundle.components.unwrappable:WrapItems(items, inst)
		bundle.timebundled = (TheWorld.state.time+TheWorld.state.cycles)*8*60
		inst.components.container:GiveItem(bundle, 8, pos, true)
	elseif owner and owner.components.talker then
		owner.components.talker:Say(ACTIONFAIL_GENERIC)
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
    return inst
end

return Prefab("silksack", fn)

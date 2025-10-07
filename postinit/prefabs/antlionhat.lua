local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local ANTLIONHAT_PICKUP_MUST_TAGS = {"groundtile"}
local function pickup_UM(inst, owner)
    if not owner or not owner.components.inventory then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 1.2 * TUNING.ORANGEAMULET_RANGE, nil, nil, ANTLIONHAT_PICKUP_MUST_TAGS)
    for i, v in ipairs(ents) do
        if v.components.inventoryitem and --Inventory stuff
            v.components.inventoryitem.canbepickedup and
            v.components.inventoryitem.cangoincontainer and
            not v.components.inventoryitem:IsHeld() and
            owner.components.inventory:CanAcceptCount(v, 1) > 0 then
            if owner.components.minigame_participator then
                local minigame = owner.components.minigame_participator:GetMinigame()
                if minigame then
                    minigame:PushEvent("pickupcheat", {cheater = owner, item = v})
                end
            end

            --Amulet will only ever pick up items one at a time. Even from stacks.
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())

            local v_pos = v:GetPosition()
            if v.components.stackable then
                v = v.components.stackable:Get()
            end
            owner.components.inventory:GiveItem(v, nil, v_pos)
            return
        end
    end
end

env.AddPrefabPostInit("antlionhat", function(inst)
	if not TheWorld.ismastersim then
        return
    end

	local _antlion_onequip = inst.components.equippable.onequipfn
	local _antlion_onunequip = inst.components.equippable.onunequipfn

	local function antlion_onequip(inst, owner, ...)
        _antlion_onequip(inst, owner, ...)
		inst.task = inst:DoPeriodicTask(TUNING.ORANGEAMULET_ICD, pickup_UM, nil, owner)
    end
	
    local function antlion_onunequip(inst, owner, ...)
        _antlion_onunequip(inst, owner, ...)
		if inst.task ~= nil then
        	inst.task:Cancel()
        	inst.task = nil
    	end
	end

	inst.components.equippable:SetOnEquip(antlion_onequip)
    inst.components.equippable:SetOnUnequip(antlion_onunequip)
	inst.components.container:EnableInfiniteStackSize(true)
end)
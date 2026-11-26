local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------\

local function Working(owner, data)
	if owner ~= nil and owner:HasTag("player") then
		local tool = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		local ID = owner.FindHoneID and tool and owner.FindHoneID(owner,tool.prefab) -- Ask what it is incase someone changed it
		local scale = 0
    	if ID and owner.hone_amounts[ID] >= owner.hone_tiers[2] then
			scale = owner:HasTag("amped") and 1 or owner.components.adrenaline:GetPercent()
		end
		local x, y, z = owner.Transform:GetWorldPosition()
		owner:ShakeCamera(CAMERASHAKE.SIDE, 0.25, 0.02, 0.25)
		
		local ents = TheSim:FindEntities(x, y, z, 4 + 4 * scale, nil, { "INLIMBO", "DIG_workable" }, { "CHOP_workable", "MINE_workable" })
		if data.target ~= nil then
			local ring = SpawnPrefab("groundpoundring_fx")
			local x1, y1, z1 = data.target.Transform:GetWorldPosition()

			ring.Transform:SetPosition(x1, y1, z1)
            local scale2 = 0.55 + scale * 0.3
			ring.Transform:SetScale(scale2, scale2, scale2)
		end
		
		for k, v in ipairs(ents) do
			if v ~= data.target and v.components.workable ~= nil and (v.components.workable:GetWorkAction() == ACTIONS.MINE or v.components.workable:GetWorkAction() == ACTIONS.CHOP) and v.prefab ~= "moonstorm_glass_nub" then
				v.components.workable:WorkedBy(v, 1)
			end
		end
	end
end

env.AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnEquip = inst.components.equippable.onequipfn
    local _OnUnequip = inst.components.equippable.onunequipfn

    local function OnEquip(inst, owner)
        inst:ListenForEvent("working", inst.Working, owner)
        _OnEquip(inst, owner)
    end

    local function OnUnequip(inst, owner)
        inst:RemoveEventCallback("working", inst.Working, owner)
        _OnUnequip(inst, owner)
    end

	inst.Working = Working

	inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end)

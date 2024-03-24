local assets =
{
    Asset("ANIM", "anim/swap_exhumer.zip"),
	Asset("ANIM", "anim/swap_exhumer_powered.zip"),
}

local prefabs =
{
}

local function onfinishcallback(inst, worker)
    inst.AnimState:PlayAnimation("dug")
    inst:RemoveComponent("workable")

    if worker ~= nil then
        if worker.components.sanity ~= nil then
            worker.components.sanity:DoDelta(-TUNING.SANITY_SMALL)
        end
		
		local skeleton = SpawnPrefab("rneskeleton")
		skeleton.Transform:SetPosition(inst.Transform:GetWorldPosition())
		worker:PushEvent("makefriend")
		worker.components.leader:AddFollower(skeleton)
    end
end

local function GetStatus(inst)
    if not inst.components.workable then
        return "DUG"
    end
end

local function OnSave(inst, data)
    if inst.components.workable == nil then
        data.dug = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.dug or inst.components.workable == nil then
        inst:RemoveComponent("workable")
        inst.AnimState:PlayAnimation("dug")
    end
end

local function OnHaunt(inst, haunter)
    --#HAUNTFIX
    --return spawnghost(inst, TUNING.HAUNT_CHANCE_HALF)
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("gravestone")
    inst.AnimState:SetBuild("gravestones")
    inst.AnimState:PlayAnimation("gravedirt")

    inst:AddTag("grave")
	inst:AddTag("buried")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst:AddComponent("lootdropper")

    inst.components.workable:SetOnFinishCallback(onfinishcallback)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)
	
	inst:DoTaskInTime(60, inst.Remove)
	inst.persists = false

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function UpdateBuild(inst, powered)
	inst.charged = powered

	local owner = inst.components.inventoryitem.owner 
	inst.build = powered and "_powered" or ""
	
	if owner ~= nil and inst.components.equippable:IsEquipped() then
		owner.AnimState:OverrideSymbol("swap_object", "swap_exhumer"..inst.build, "swap_exhumer"..inst.build)
	end
	
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_exhumer"..inst.build..".xml"
	inst.components.inventoryitem:ChangeImageName("um_exhumer"..inst.build)
	
    --inst.AnimState:SetBuild(inst.build)
end

local function onequip(inst, owner)
	if not owner:HasTag("vetcurse") then
		inst:DoTaskInTime(0, function(inst, owner)
			local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner
			local tool = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if tool ~= nil and owner ~= nil then
				owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
				owner.components.inventory:DropItem(tool)
				owner.components.inventory:GiveItem(inst)
				owner.components.talker:Say(GetString(owner, "CURSED_ITEM_EQUIP"))
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/HUD_hot_level1")

				if owner.sg ~= nil then
					owner.sg:GoToState("hit")
				end
			end
		end)
	else
		owner.AnimState:OverrideSymbol("swap_object", "swap_exhumer"..inst.build, "swap_exhumer"..inst.build)
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")
	end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onattack(inst, attacker, target)
    if target ~= nil and target:IsValid() and target.components.health ~= nil then
		local health_value = target.components.health.currenthealth
		local maxhealth_value = target.components.health.maxhealth * 0.05
		local owner = inst.components.inventoryitem.owner
		
        if not (target:HasTag("wall") or target:HasTag("engineering") or target:HasTag("butterfly")) and health_value <= (maxhealth_value + 30) and target.components.combat ~= nil then
			if owner ~= nil then
				if owner.SoundEmitter ~= nil then
					owner.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe")
				end

				if owner.components.health ~= nil then
					owner.components.health:DoDelta(maxhealth_value / 2, false, "um_exhumer")
				end
			end

			target.components.combat:GetAttacked(attacker, maxhealth_value, nil)

			if target.components.health:IsDead() then
				SpawnPrefab("shadow_despawn").Transform:SetPosition(target.Transform:GetWorldPosition())
				SpawnPrefab("um_grave_mound").Transform:SetPosition(target.Transform:GetWorldPosition())
			end
		end
    end
end

local function OnCharged(inst)
    local fx = SpawnPrefab("dr_hot_loop")

    local owner = inst.components.inventoryitem:GetGrandOwner()

    if inst.components.equippable:IsEquipped() and owner ~= nil then
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -275, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    else
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, 2.35, 0)
        fx.Transform:SetScale(1.33, 1.33, 1.33)
    end
    inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/charge")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt_short", nil, .4)
end

local function CheckCharge(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner ~= nil then
		local x, y, z = owner.Transform:GetWorldPosition()
		local charging = false
		local ents = TheSim:FindEntities(x, y, z, 10, { "_health", "_combat" }, { "player", "playerghost", "companion", "abigail", "wall", "engineering", "INLIMBO", "notarget", "NOCLICK", "butterfly", "bird" })

		if ents ~= nil then
			for i, v in ipairs(ents) do
				if v.components.health ~= nil and v.components.combat ~= nil then
					local health_value = v.components.health.currenthealth
					local maxhealth_value = v.components.health.maxhealth * 0.05
						
					if health_value <= (maxhealth_value + 30) then
						charging = true
					end
				end
			end
		end
		
		if charging then
			if not inst.charged then
				OnCharged(inst)
				UpdateBuild(inst, charging)
			end
		else
			UpdateBuild(inst, charging)
		end
	else
		UpdateBuild(inst, false)
	end
end
		
local function shovelfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("exhumer")
    inst.AnimState:SetBuild("swap_exhumer_powered")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
	inst:AddTag("weapon")
    inst:AddTag("um_exhumer")
	
    MakeInventoryFloatable(inst, "med", 0.05, {0.8, 0.4, 0.8})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.DIG)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.SPEAR_DAMAGE)
	inst.components.weapon:SetOnAttack(onattack)

    inst:AddInherentAction(ACTIONS.DIG)

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(OnCharged)
	
	inst:DoPeriodicTask(.2, CheckCharge)

    MakeHauntableLaunch(inst)
	inst.build = ""
	
	inst.UpdateBuild = UpdateBuild
	UpdateBuild(inst, false)
	
    return inst
end

return Prefab("um_grave_mound", fn, assets, prefabs),
		Prefab("um_exhumer", shovelfn, assets, prefabs)
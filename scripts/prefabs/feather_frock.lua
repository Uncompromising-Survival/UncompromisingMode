--[[local assets =
{
    Asset("ANIM", "anim/armor_bramble.zip"),
}

local prefabs =
{
    "bramblefx_armor",
}]]

local MAXRANGE = 3
local NO_TAGS_NO_PLAYERS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "player", "playerghost",
	"companion" }
local COMBAT_TARGET_TAGS = { "_combat" }

local feather_defs =
{
	{
		name = "feather_robin",
		sound = "dontstarve/birds/takeoff_robin",
		damage = 20,
		damage_reduction = 5,
	},
	{
		name = "feather_robin_winter",
		sound = "dontstarve/birds/takeoff_junco",
		damage = 40,
		damage_reduction = 7,
	},
	{
		name = "feather_crow",
		sound = "dontstarve/birds/takeoff_crow",
		damage = 20,
		damage_reduction = 5,
	},
	{
		name = "feather_canary",
		sound = "dontstarve/birds/takeoff_canary",
		fx = "spikes_canary",
		damage = 30,
		damage_reduction = 7,
	},
	{
		name = "goose_feather",
		sound = "dontstarve_DLC001/creatures/mossling/honk",
		damage = 10,
		damage_reduction = 15,
	},
	{
		name = "malbatross_feather",
		sound = "saltydog/creatures/boss/malbatross/attack_call",
		damage = 50,
		damage_reduction = 10,
	},
}

local function SpawnThorns(inst, feather, owner, damage)

	local owner = inst.components.inventoryitem.owner
	local impactfx = SpawnPrefab("impact")
	inst.fxscale = 1
	inst.speedboost = 0

	if feather == "malbatross" then
		inst.speedboost = 1
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, 5, COMBAT_TARGET_TAGS, NO_TAGS_NO_PLAYERS)) do
		if v:IsValid() and
			v.entity:IsVisible() and
			v.components.combat ~= nil then
			if owner ~= nil and not owner:IsValid() then
				owner = nil
			end
			if owner ~= nil then
				if owner.components.combat ~= nil and owner.components.combat:CanTarget(v) then
					if feather == "feather_robin" and v.components.fueled == nil and
						v.components.burnable ~= nil and
						not v.components.burnable:IsBurning() and
						not v:HasTag("burnt") then
						v.components.burnable:Ignite(nil, owner, owner)
						v.components.combat:GetAttacked(owner, damage)

						if v.components.freezable then
							v.components.freezable:Unfreeze()
						end
					elseif feather == "feather_robin_winter" then
						v.components.combat:GetAttacked(owner, damage)

						inst.fxscale = 1.5
					elseif feather == "feather_crow" and v.components.locomotor ~= nil then
						local debuffkey = inst.prefab

						if v._wingsuit_speedmulttask ~= nil then
							v._wingsuit_speedmulttask:Cancel()
						end
						v._wingsuit_speedmulttask = v:DoTaskInTime(5,
							function(i) i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey) i._wingsuit_speedmulttask = nil end)

						local slowamount = 0.7

						v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, slowamount)
						v.components.combat:GetAttacked(owner, damage)
					elseif feather == "feather_canary" then
						SpawnPrefab("electricchargedfx"):SetTarget(v)
						SpawnPrefab("shockotherfx"):SetFXOwner(owner)
						v.components.combat:GetAttacked(owner, damage)
					elseif feather == "malbatross_feather" then
						v.components.combat:GetAttacked(owner, damage)
					end
				end

				if impactfx ~= nil and v.components.combat then
					local follower = impactfx.entity:AddFollower()
					follower:FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, 0, 0)
					if owner ~= nil and owner:IsValid() then
						impactfx:FacePoint(owner.Transform:GetWorldPosition())
						impactfx.Transform:SetScale(inst.fxscale, inst.fxscale, inst.fxscale)
					end
				end
			end
		end
	end

	if feather == "goose_feather" then
		local tornado1 = SpawnPrefab("mini_mothergoose_tornado")
		tornado1.WINDSTAFF_CASTER = owner
		tornado1.components.linearcircler:SetCircleTarget(owner)
		tornado1.components.linearcircler:Start()
		tornado1.components.linearcircler.randAng = 0
		tornado1.components.linearcircler.clockwise = false
		tornado1.components.linearcircler.distance_mod = 4

		local tornado2 = SpawnPrefab("mini_mothergoose_tornado")
		tornado2.WINDSTAFF_CASTER = owner
		tornado2.components.linearcircler:SetCircleTarget(owner)
		tornado2.components.linearcircler:Start()
		tornado2.components.linearcircler.randAng = 0.33
		tornado2.components.linearcircler.clockwise = false
		tornado2.components.linearcircler.distance_mod = 4

		local tornado3 = SpawnPrefab("mini_mothergoose_tornado")
		tornado3.WINDSTAFF_CASTER = owner
		tornado3.components.linearcircler:SetCircleTarget(owner)
		tornado3.components.linearcircler:Start()
		tornado3.components.linearcircler.randAng = 0.66
		tornado3.components.linearcircler.clockwise = false
		tornado3.components.linearcircler.distance_mod = 4
	end

	owner.components.locomotor:SetExternalSpeedMultiplier(inst, "wingsuit", 1.5 + inst.speedboost)
	owner:DoTaskInTime(1.5 + inst.speedboost,
		function(owner) owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wingsuit") end)

end

local function charged(inst)
	local fx = SpawnPrefab("dr_warm_loop_2")

	local owner = inst.components.inventoryitem.owner

	if inst.components.equippable:IsEquipped() and owner ~= nil then
		fx.entity:SetParent(owner.entity)
		fx.entity:AddFollower()
		fx.Follower:FollowSymbol(owner.GUID, "swap_body", 0, -275, 0)
		fx.Transform:SetScale(1.22, 1.22, 1.22)
	else
		fx.entity:SetParent(inst.entity)
		fx.Transform:SetPosition(0, 2.35, 0)
		fx.Transform:SetScale(1.22, 1.22, 1.22)
	end
end

local function OnCooldown(inst)
	inst._cdtask = nil
	inst.components.useableitem.inuse = false

	charged(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/charge")
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/moose/attack", nil, .7)
end

local function OnBlocked(owner, data, inst)
	if owner == nil then
		local owner = inst.components.inventoryitem.owner
	end

	if inst ~= nil then
		if inst.feather and inst._cdtask == nil and data ~= nil and not data.redirected then
			--V2C: tiny CD to limit chain reactions

			inst.components.useableitem.inuse = true
			inst._cdtask = inst:DoTaskInTime(0.33, OnCooldown)
			inst.components.rechargeable:Discharge(0.33)
			
			for i, v in ipairs(feather_defs) do
				if v.name == inst.feather.prefab then
					SpawnThorns(inst, v.name, owner, v.damage)
					SpawnPrefab("spikes_"..v.name).entity:SetParent(owner.entity)
					inst.SoundEmitter:PlaySound(v.sound)
					if owner.SoundEmitter ~= nil then
						owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
					end
				end
			end
			
			local item = inst.components.container:RemoveItem(inst.components.container:GetItemInSlot(1), false)
			item:Remove()
		end
	end
end

local function OnUse(inst)
	local owner = inst.components.inventoryitem.owner

	if inst ~= nil then
		if inst.feather ~= nil and inst._cdtask == nil then
			--V2C: tiny CD to limit chain reactions
			
			inst._cdtask = inst:DoTaskInTime(.33, OnCooldown)
			inst.components.rechargeable:Discharge(.33)
			
			for i, v in ipairs(feather_defs) do
				if v.name == inst.feather.prefab then
					SpawnThorns(inst, v.name, owner, v.damage)
					SpawnPrefab("spikes_"..v.name).entity:SetParent(owner.entity)
					inst.SoundEmitter:PlaySound(v.sound)
					if owner.SoundEmitter ~= nil then
						owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
					end
				end
			end
			
			local item = inst.components.container:RemoveItem(inst.components.container:GetItemInSlot(1), false)
			item:Remove()
		end
	end
end

local function onequip(inst, owner)
	if not owner:HasTag("vetcurse") then
		inst:DoTaskInTime(0, function(inst, owner)
			local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner
			local tool = owner ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			if tool ~= nil and owner ~= nil then
				owner.components.inventory:Unequip(EQUIPSLOTS.BODY)
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
		if inst.components.container ~= nil then
			inst.components.container:Open(owner)
		end

		local skin_build = inst:GetSkinBuild()
		if skin_build ~= nil then
			owner:PushEvent("equipskinneditem", inst:GetSkinName())
            --owner.AnimState:OverrideSymbol("swap_body", skin_build or "featherfrock_fancy", "swap_body")
			owner.AnimState:OverrideItemSkinSymbol("swap_body", "featherfrock_fancy", "swap_body", inst.GUID, "featherfrock")
		else
			owner.AnimState:OverrideSymbol("swap_body", "featherfrock", "swap_body")
		end

		inst:Hide()

		inst:ListenForEvent("blocked", inst._onblocked, owner)
		inst:ListenForEvent("attacked", inst._onblocked, owner)
	end
end

local function onunequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end

	if inst.components.container ~= nil then
		inst.components.container:Close()
	end
    owner.AnimState:ClearOverrideSymbol("swap_body")

    if owner.components.locomotor ~= nil then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wingsuit")
    end

	inst:RemoveEventCallback("blocked", inst._onblocked, owner)
	inst:RemoveEventCallback("attacked", inst._onblocked, owner)

	inst:Show()
end

local function onstopuse()
end

local function OnAmmoLoaded(inst, data)
	local feather = inst.components.container:GetItemInSlot(1)
	
	if feather ~= nil then
		for i, v in ipairs(feather_defs) do
			if v.name == feather.prefab then
				inst.feather = feather
				inst.frock_damage_reduction = v.damage_reduction
				
				return
			end
		end
	end
	
	inst.feather = nil
	inst.frock_damage_reduction = 0
end

local function OnAmmoUnloaded(inst, data)
	local feather = inst.components.container:GetItemInSlot(1)
	
	if feather ~= nil then
		for i, v in ipairs(feather_defs) do
			if v.name == feather.prefab then
				inst.feather = feather
				inst.frock_damage_reduction = v.damage_reduction
				
				return
			end
		end
	end
	
	inst.feather = nil
	inst.frock_damage_reduction = 0
end

local function frockfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("featherfrock_ground")
	inst.AnimState:SetBuild("featherfrock_ground")
	inst.AnimState:PlayAnimation("anim")

	--inst:AddTag("wingsuit")
	--inst:AddTag("backpack")
	inst:AddTag("vetcurse_item")
    inst:AddTag("donotautopick")
    inst:AddTag("um_feather_frock")
	--inst.foleysound = "dontstarve/movement/foley/cactus_armor"

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst)
			inst.replica.container:WidgetSetup("wingsuit")
		end
		return inst
	end
	
	inst.feather = nil
	inst.frock_damage_reduction = 0

    inst:AddComponent("tradable")
	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst:AddComponent("rechargeable")

	inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.AMULET_SHADOW_LEVEL)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY

	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("wingsuit")
	inst.components.container.canbeopened = false

	inst:AddComponent("useableitem")
	inst.components.useableitem:SetOnUseFn(OnUse)
	
    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

	MakeHauntableLaunch(inst)

	inst._onblocked = function(owner, data) OnBlocked(owner, data, inst) end

	return inst
end

return Prefab("feather_frock", frockfn)

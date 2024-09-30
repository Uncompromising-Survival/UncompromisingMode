local assets =
{
    Asset("ANIM", "anim/lighter.zip"),
    Asset("ANIM", "anim/swap_lighter.zip"),
    --Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
	"channel_absorb_fire_fx",
    "channel_absorb_fire",
    "channel_absorb_smoulder",
    "channel_absorb_embers",
}

--------------------------------------------------------------------------

local SNUFF_ONEOF_TAGS = { "smolder", "fire", "willow_ember" }
local SNUFF_NO_TAGS = { "INLIMBO","snuffed" }
local ABSORB_RANGE = 2.5

local function UpdateSnuff(inst, owner)
	if inst.components.fueled:GetPercent() <= 0 then
		owner.components.channelcaster:StopChanneling(inst)
	else
		local fx = nil
		local x, y, z = owner.Transform:GetWorldPosition()
		local smog = TheSim:FindEntities(x, y, z, TUNING.FEATHERFAN_RADIUS * 2, { "smog" }, { "INLIMBO" })
		for k, v in pairs(smog) do
			inst.components.fueled:SetPercent(inst.components.fueled:GetPercent() - 0.005)
			v:Remove()
			owner.SoundEmitter:PlaySound("dontstarve/creatures/mosquito/mosquito_death")
		end
		for i, v in ipairs(TheSim:FindEntities(x, 0, z, ABSORB_RANGE, nil, SNUFF_NO_TAGS, SNUFF_ONEOF_TAGS)) do
			if v:IsValid() and not v:IsInLimbo() then
				local giveember = nil
				if v.components.burnable then
					if v.components.burnable:IsBurning() then
						v.components.burnable:Extinguish()                    
						fx = "channel_absorb_fire"
					elseif v.components.burnable:IsSmoldering() then
						v.components.burnable:SmotherSmolder()
						fx = "channel_absorb_smoulder"
					end
				end

				if fx then
					owner.SoundEmitter:PlaySound("dontstarve/creatures/mosquito/mosquito_death")
					local fxprefab = SpawnPrefab(fx)
					fxprefab.Follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)

					if giveember then
						v.AnimState:PlayAnimation("idle_pst")
						v:DoTaskInTime(10*FRAMES,function()
							if not owner.components.health:IsDead() then
								owner.components.inventory:GiveItem(v, nil, owner:GetPosition())
							end
							v:RemoveTag("snuffed")
							v.AnimState:PlayAnimation("idle_pre")
							v.AnimState:PushAnimation("idle_loop",true)
						end)
					end
                end
            end
		end
	end
end

local function OnStartChanneling(inst, user)
	local owner = inst.components.inventoryitem.owner
	if inst.components.fueled:GetPercent() <= 0 then
		owner.components.channelcaster:StopChanneling(inst)
	else
		if inst.snuff_task then
			inst.snuff_task:Cancel()
		end
		inst.snuff_task = inst:DoPeriodicTask(0.3, UpdateSnuff, nil, user)

		user.SoundEmitter:PlaySound("meta3/willow_lighter/lighter_absorb_LP","channel_loop")

		if inst.snuff_fx then
			inst.snuff_fx:KillFX()
		end
		inst.snuff_fx = SpawnPrefab("channel_absorb_fire_fx")
		inst.snuff_fx.Follower:FollowSymbol(user.GUID, "swap_object", 56, -40, 0)
	end
end

local function OnStopChanneling(inst, user)

    user.SoundEmitter:KillSound("channel_loop")
    user.SoundEmitter:PlaySound("meta3/willow_lighter/extinguisher_deactivate")

	if inst.snuff_task then
		inst.snuff_task:Cancel()
		inst.snuff_task = nil
	end
	if inst.snuff_fx then
		inst.snuff_fx:KillFX()
		inst.snuff_fx = nil
	end
end

local function ForceChannel(inst, target, pos)
	local owner = inst.components.inventoryitem.owner
	
	if owner ~= nil then
		if owner.components.channelcaster:IsChanneling() then
			owner.components.channelcaster:StopChanneling(inst)
		else
			owner.components.channelcaster:StartChanneling(inst)
		end
	end
end

--------------------------------------------------------------------------
local function onequip(inst, owner)
	owner.components.channelcaster:StopChanneling(inst)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst,owner)
	owner.components.channelcaster:StopChanneling(inst)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")

end

local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function onequiptomodel(inst, owner, from_ground)
    if inst.fires ~= nil then
        for i, fx in ipairs(inst.fires) do
            fx:Remove()
        end
        inst.fires = nil
    end

    inst.components.burnable:Extinguish()
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

--[[local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        --when we burn out
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                    announce = "ANNOUNCE_TORCH_OUT",
                }
                inst:Remove()
                owner:PushEvent("itemranout", data)
                return
            end
        end
        inst:Remove()
    end
end]]--

local function OnRemoveEntity(inst)
	if inst.snuff_fx then
		inst.snuff_fx:KillFX()
		inst.snuff_fx = nil
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lighter")
    inst.AnimState:SetBuild("lighter")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("lighter.png")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "small", 0.05, 0.8)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LIGHTER_DAMAGE)

	inst:AddComponent("channelcastable")
	inst.components.channelcastable:SetStrafing(false)
	inst.components.channelcastable:SetOnStartChannelingFn(OnStartChanneling)
	inst.components.channelcastable:SetOnStopChannelingFn(OnStopChanneling)
    -----------------------------------
    -----------------------------------
    inst:AddComponent("inventoryitem")
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil
	
    inst:AddComponent("fueled")
	inst.components.fueled.fueltype = FUELTYPE.WOOL
    --inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetDepletedFn(inst.Depleted)
    inst.components.fueled:SetFirstPeriod(TUNING.TURNON_FUELED_CONSUMPTION, TUNING.TURNON_FULL_FUELED_CONSUMPTION)
    inst.components.fueled.accepting = true

    MakeHauntableLaunch(inst)

	inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("smogeater", fn, assets, prefabs)

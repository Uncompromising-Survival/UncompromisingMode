local assets =
{
    Asset("ANIM", "anim/scythe_jawed.zip"), -- Klei's convention is scythe_type in anim, but type_scythe in code. (Referencing voidcloth_scythe)
	Asset("IMAGE", "images/inventoryimages/jawed_scythe.tex"),
	Asset("ATLAS", "images/inventoryimages/jawed_scythe.xml"),
	
	Asset("IMAGE", "images/inventoryimages/snappy_jaw.tex"),
	Asset("ATLAS", "images/inventoryimages/snappy_jaw.xml"),
}

local function AttachClassified(inst, classified)
    inst._classified = classified
    inst.ondetachclassified = function() inst:DetachClassified() end
    inst:ListenForEvent("onremove", inst.ondetachclassified, classified)
end

local function DetachClassified(inst)
    inst._classified = nil
    inst.ondetachclassified = nil
end

local function OnRemoveEntity(inst)
    if inst._classified ~= nil then
        if TheWorld.ismastersim then
            inst._classified:Remove()
            inst._classified = nil
        else
            inst._classified._parent = nil
            inst:RemoveEventCallback("onremove", inst.ondetachclassified, inst._classified)
            inst:DetachClassified()
        end
    end
end

--------------------------------------------------------------------------

local function SetFxOwner(inst, owner)
	if inst._fxowner ~= nil and inst._fxowner.components.colouradder ~= nil then
		inst._fxowner.components.colouradder:DetachChild(inst.fx)
	end
	inst._fxowner = owner
    if owner ~= nil then
        inst.fx.entity:SetParent(owner.entity)
        inst.fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 2)
        inst.fx.components.highlightchild:SetOwner(owner)
        inst.fx:ToggleEquipped(true)
		if owner.components.colouradder ~= nil then
			owner.components.colouradder:AttachChild(inst.fx)
		end
    else
        inst.fx.entity:SetParent(inst.entity)
        --For floating
        inst.fx.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 2)
        inst.fx.components.highlightchild:SetOwner(inst)
        inst.fx:ToggleEquipped(false)
    end
end

local function PushIdleLoop(inst)
	inst.AnimState:PushAnimation("idle")
end

local function OnStopFloating(inst)
    inst.fx.AnimState:SetFrame(0)
    inst:DoTaskInTime(0, PushIdleLoop) --#V2C: #HACK restore the looping anim, timing issues
end



local function OnEquip(inst, owner)
    local skin_build = inst:GetSkinBuild()

	owner.AnimState:OverrideSymbol("swap_object", "scythe_jawed", "swap_scythe")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)

end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    SetFxOwner(inst, nil)

end

local function HarvestPickable(inst, ent, doer)
    if ent.components.pickable.picksound ~= nil then
        doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
    end

    local success, loot = ent.components.pickable:Pick(TheWorld)

    if loot ~= nil then
        for i, item in ipairs(loot) do
            Launch(item, doer, 1.5)
        end
    end	
end

local function IsEntityInFront(inst, entity, doer_rotation, doer_pos)
    local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

    return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
end

local HARVEST_MUSTTAGS  = {"pickable"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local function DoScythe(inst, target, doer)
    if target.components.pickable ~= nil then
        local doer_pos = doer:GetPosition()
        local x, y, z = doer_pos:Get()

        local doer_rotation = doer.Transform:GetRotation()
		inst.components.finiteuses:Use(1)
        local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS*1.2, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
        for _, ent in pairs(ents) do
            if ent:IsValid() and ent.components.pickable ~= nil then
                if inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                    inst:HarvestPickable(ent, doer)
					
					-- These finiteuses calls need to be here, and not within HarvestPickable, it has to be referenced whenever we make the scythe hoarding through gemology
					if ent.prefab ~= "hooded_fern" and inst.components.finiteuses ~= nil then
						inst.components.finiteuses:Use(0.25)
					end

				   if ent.prefab == "hooded_fern" and inst.components.finiteuses ~= nil then
						inst.components.finiteuses:Use(0.2)
				   end
				   
                end
            end
        end
    end
end

local function OnAttack(inst, attacker, target) -- Save for "wounded" effect

end

local function SetupComponents(inst)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.SPEAR_DAMAGE*1.3)--44.2
	inst.components.weapon:SetOnAttack(OnAttack)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.SCYTHE)
end

local function DisableComponents(inst)
	inst:RemoveComponent("equippable")
	inst:RemoveComponent("weapon")
    inst:RemoveComponent("tool")
end

local FLOAT_SCALE_BROKEN = { 0.8, 0.4, 0.8 }
local FLOAT_SCALE = { 1.2, 0.4, 1.2 }

local function OnIsBrokenDirty(inst)
	if inst.isbroken:value() then
		inst.components.floater:SetSize("med")
		inst.components.floater:SetVerticalOffset(0.25)
		inst.components.floater:SetScale(FLOAT_SCALE_BROKEN)
	else
		inst.components.floater:SetSize("med")
		inst.components.floater:SetVerticalOffset(0)
		inst.components.floater:SetScale(FLOAT_SCALE)
	end
end

local SWAP_DATA_BROKEN = { sym_build = "scythe_jawed", sym_name = "scythe_base_broken_float", bank = "scythe_voidcloth", anim = "broken" }
local SWAP_DATA = { sym_build = "scythe_jawed", sym_name = "swap_scythe", bank = "scythe_voidcloth" }

local function SetIsBroken(inst, isbroken)
	if isbroken then
		inst.components.floater:SetBankSwapOnFloat(true, -10, SWAP_DATA_BROKEN)
		if inst.fx ~= nil then
			inst.fx:Hide()
		end
	else
		inst.components.floater:SetBankSwapOnFloat(true, -20, SWAP_DATA)
		if inst.fx ~= nil then
			inst.fx:Show()
		end
	end
	inst.isbroken:set(isbroken)
	OnIsBrokenDirty(inst)
end

local function ScytheFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("scythe_voidcloth")
    inst.AnimState:SetBuild("scythe_jawed")
    inst.AnimState:PlayAnimation("idle", true)

    --inst.AttachClassified = AttachClassified
    --inst.DetachClassified = DetachClassified
    --inst.OnRemoveEntity   = OnRemoveEntity

    inst:AddTag("sharp")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")



	inst:AddComponent("floater")
	
    --Dedicated server does not need to spawn the local sound fx
    if not TheNet:IsDedicated() then
        inst.localsounds = CreateEntity()
        inst.localsounds:AddTag("FX")

        --[[Non-networked entity]]
        inst.localsounds.entity:AddTransform()
        inst.localsounds.entity:AddSoundEmitter()
        inst.localsounds.entity:SetParent(inst.entity)
        inst.localsounds:Hide()
        inst.localsounds.persists = false
    end


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		--inst:ListenForEvent("isbrokendirty", OnIsBrokenDirty)

        return inst
    end

    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(frame)
    --V2C: one networked fx for frame 3 (needed for floating)
    --     all other frames will be spawned locally client-side by this fx
    inst.fx = SpawnPrefab("jawed_scythe_fx")
    inst.fx.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/jawed_scythe.xml"
	
    local finiteuses = inst:AddComponent("finiteuses")
    finiteuses:SetMaxUses(100)
    finiteuses:SetUses(100)
    --finiteuses:SetConsumption(ACTIONS.SCYTHE, 0)
	finiteuses:SetOnFinished(inst.Remove)
	SetupComponents(inst)

    MakeHauntableLaunch(inst)

    inst.DoScythe = DoScythe
    inst.IsEntityInFront = IsEntityInFront
    inst.HarvestPickable = HarvestPickable

    return inst
end

--------------------------------------------------------------------------

local FX_DEFS =
{
    { anim = "swap_loop_1", frame_begin = 0, frame_end = 2 },
    --{ anim = "swap_loop_3", frame_begin = 2 },
    { anim = "swap_loop_6", frame_begin = 5 },
    { anim = "swap_loop_7", frame_begin = 6 },
    { anim = "swap_loop_8", frame_begin = 7 },
}

local function CreateFxFollowFrame()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBank("scythe_voidcloth")
    inst.AnimState:SetBuild("scythe_jawed")

    inst:AddComponent("highlightchild")

    inst.persists = false

    return inst
end

local function FxRemoveAll(inst)
    for i = 1, #inst.fx do
        inst.fx[i]:Remove()
        inst.fx[i] = nil
    end
end

local function FxOnEquipToggle(inst)
    local owner = inst.equiptoggle:value() and inst.entity:GetParent() or nil
    if owner ~= nil then
        if inst.fx == nil then
            inst.fx = {}
        end
        local frame = inst.AnimState:GetCurrentAnimationFrame()
        for i, v in ipairs(FX_DEFS) do
            local fx = inst.fx[i]
            if fx == nil then
                fx = CreateFxFollowFrame()
                fx.AnimState:PlayAnimation(v.anim, true)
                inst.fx[i] = fx
            end
            fx.entity:SetParent(owner.entity)
            fx.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, v.frame_begin, v.frame_end)
            fx.AnimState:SetFrame(frame)
            fx.components.highlightchild:SetOwner(owner)
        end
        inst.OnRemoveEntity = FxRemoveAll
    elseif inst.OnRemoveEntity ~= nil then
        inst.OnRemoveEntity = nil
        FxRemoveAll(inst)
    end
end

local function FxToggleEquipped(inst, equipped)
    if equipped ~= inst.equiptoggle:value() then
        inst.equiptoggle:set(equipped)
        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            FxOnEquipToggle(inst)
        end
    end
end

local function FollowSymbolFxFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("scythe_voidcloth")
    inst.AnimState:SetBuild("scythe_jawed")
    inst.AnimState:PlayAnimation("swap_loop_3", true) --frame 3 is used for floating

    inst:AddComponent("highlightchild")

    inst.equiptoggle = net_bool(inst.GUID, "jawed_scythe_fx.equiptoggle", "equiptoggledirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("equiptoggledirty", FxOnEquipToggle)
        return inst
    end

    inst.ToggleEquipped = FxToggleEquipped
    inst.persists = false

    return inst
end

local function fnjaw()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_bear_trap")
    inst.AnimState:SetBuild("um_bear_trap_old")
    inst.AnimState:PlayAnimation("item")

    MakeInventoryFloatable(inst, "med", nil, 0.77)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("inspectable")
	
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inventoryitem")

    return inst
end

return Prefab("jawed_scythe", ScytheFn, assets),
Prefab("jawed_scythe_fx", FollowSymbolFxFn),
Prefab("snappy_jaw", fnjaw)
local prefabs =
{
    "reticulearc",
    "reticulearcping",
}

------------------------------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

------------------------------------------------------------------------------------------------------------------------

local function OnBlocked(owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_dreadstone")
end

------------------------------------------------------------------------------------------------------------------------

local function DoRegen(inst, owner)
	if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
		local setbonus = inst.components.setbonus ~= nil and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or 1
		local rate = 1 / Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE, owner.components.sanity:GetPercent())
		inst.components.armor:Repair(inst.components.armor.maxcondition * rate * setbonus)
	end
	if not inst.components.armor:IsDamaged() then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

------------------------------------------------------------------------------------------------------------------------

local function OnTakeDamage(inst, amount)
	if inst.regentask == nil and inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil and owner.components.sanity ~= nil then
			StartRegen(inst, owner)
		end
	end
end

local function OnEquip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Show("lantern_overlay")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:HideSymbol("swap_object")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("lantern_overlay", skin_build, "swap_shield", inst.GUID, "swap_wathgrithr_shield_dreadstone")
        owner.AnimState:OverrideItemSkinSymbol("swap_shield_dreadstone",     skin_build, "swap_shield", inst.GUID, "swap_wathgrithr_shield_dreadstone")
    else
        owner.AnimState:OverrideSymbol("lantern_overlay", "swap_wathgrithr_shield_dreadstone", "swap_shield")
        owner.AnimState:OverrideSymbol("swap_shield",     "swap_wathgrithr_shield_dreadstone", "swap_shield")
    end

    if inst.components.rechargeable:GetTimeToCharge() < TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP then
        inst.components.rechargeable:Discharge(TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP)
    end

    inst:ListenForEvent("blocked", OnBlocked, owner)

	if owner.components.sanity ~= nil and inst.components.armor:IsDamaged() then
		StartRegen(inst, owner)
	else
		StopRegen(inst)
	end
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:ClearOverrideSymbol("swap_shield")

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Hide("lantern_overlay")
    owner.AnimState:Show("ARM_normal")
    owner.AnimState:ShowSymbol("swap_object")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    StopRegen(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function SpellFn(inst, doer, pos)
    local duration_mult =
        doer.components.skilltreeupdater ~= nil and
        doer.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_shield_2") and
        TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_DURATION_MULT or
        1

    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), TUNING.WATHGRITHR_SHIELD_PARRY_DURATION * duration_mult)
    inst.components.rechargeable:Discharge(TUNING.WATHGRITHR_SHIELD_COOLDOWN)
end

local function AddEnemyDebuffFx(fx, target)
    target:DoTaskInTime(math.random()*0.25, function()
        local x, y, z = target.Transform:GetWorldPosition()
        local fx = SpawnPrefab(fx)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end

        return fx
    end)
end

local function OnParry(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)

    if inst.components.rechargeable:GetPercent() < TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION then
        inst.components.rechargeable:SetPercent(TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION)
    end

    if doer.components.skilltreeupdater ~= nil and doer.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_shield_3") then
        inst._lastparrytime = GetTime()

        local tuning = TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE
        local scale =  TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_SCALE

        inst._bonusdamage = math.clamp(damage * scale, tuning.min, tuning.max)
    end

    local x, y, z = doer.Transform:GetWorldPosition()
    local fx = SpawnPrefab("willow_shadow_fire_explode")
    if fx then
        fx.Transform:SetPosition(x, y, z)
    end

    if attacker.components.hauntable ~= nil and attacker.components.hauntable.panicable then
        attacker.components.hauntable:Panic(TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_PANIC_TIME)

        AddEnemyDebuffFx("battlesong_instant_panic_fx", attacker)
    end

    local damageFix = 0.5
	inst.components.armor:TakeDamage(damage * TUNING.DSTU.WATHGRITHR_SHIELD_PARRY_DURABILITY_LOSS * 0.5)
end

local function DamageFn(inst)
    if inst._lastparrytime ~= nil and (inst._lastparrytime + TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_DURATION) >= GetTime() then
        return TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_DAMAGE + (inst._bonusdamage or 0)
    end

    return TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_DAMAGE
end

local function OnAttackFn(inst, attacker, target)
    inst._lastparrytime = nil
    inst._bonusdamage = nil

    inst.components.armor:TakeDamage(TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_USEDAMAGE * inst.components.weapon.attackwearmultipliers:Get())
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

------------------------------------------------------------------------------------------------------------------------

local function CalcDapperness(inst, owner)
    -- Dreadstone gear doesn't regen when enlightened (lunar island and grotto)
	local insanity = owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode()
	if not insanity then return 0 end

    -- Check of other armor pieces are currently equipped and regenerating
    local is_other_regenerating = false
    if owner.components.inventory ~= nil then
        -- dreadstonehat
        local hat =  owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
        hat = hat ~= nil and hat.prefab == "dreadstonehat" and hat or nil
        if hat~=nil and hat.regentask ~= nil then is_other_regenerating = true end
        -- armor_dreadstone
        local armor = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
        armor = armor ~= nil and armor.prefab == "dreadstonehat" and armor or nil
        if armor~=nil and armor.regentask ~= nil then is_other_regenerating = true end
    end

    -- If one or both armor pieces are regenerating the dapperness will be -20. Set this one to 0 to keep it as -20.
	if is_other_regenerating then return 0
    -- Current dapperness is 0. Set to -20 if this is regenerating or keep it at 0 if not.    
    else return inst.regentask ~= nil and TUNING.CRAZINESS_MED or 0 end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("wathgrithr_shield_dreadstone")
    inst.AnimState:SetBuild("wathgrithr_shield_dreadstone")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("toolpunch")
    inst:AddTag("battleshield")
    inst:AddTag("shield")

    --parryweapon (from parryweapon component) added to pristine state for optimization
    inst:AddTag("parryweapon")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --rechargeable (from rechargeable component) added to pristine state for optimization
    inst:AddTag("rechargeable")

    MakeInventoryFloatable(inst, nil, 0.2, {1.1, 0.6, 1.1})

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
    inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_weapondamage = TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_DAMAGE

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DamageFn)
    inst.components.weapon:SetOnAttack(OnAttackFn)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_PLANAR_DAMAGE)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_ARMOR, TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_ABSORPTION)
    inst.components.armor.ontakedamage = OnTakeDamage

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(TUNING.DSTU.WATHGRITHR_SHIELD_DREADSTONE_PLANAR_DEF)

    inst:AddComponent("equippable")
    inst.components.equippable.restrictedtag = "wathgrithrshielduser"
    inst.components.equippable.dapperfn = CalcDapperness
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMORDREADSTONE_SHADOW_RESIST)

    inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.ARMORDREADSTONE_SHADOW_LEVEL)

    local setbonus = inst:AddComponent("setbonus")
	setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(TUNING.WATHGRITHR_SHIELD_PARRY_ARC)
    --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("wathgrithr_shield_dreadstone", fn, nil, prefabs)
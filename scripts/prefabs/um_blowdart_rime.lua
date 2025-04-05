local prefabs = {
    "impact",
    "um_smolder_spore_pop",
    "umdebuff_pyre_toxin"
}


local DebuffDuration = 6 -- Length of Pyre Toxin on struck target; 6 is the debuff's default.
local DebuffDurationBonus = 10


local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_blowdart", "swap_blowdart")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end


-- What happens TO the target hit.
local function OnAttack(inst, attacker, target)
    if target:IsValid()
        and not target:HasTag("INLIMBO")
        and not target:HasTag("noattack") then
	
        if target.SoundEmitter ~= nil then
            target.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_impact_sleep")
        end
    end
end


-- What the dart object does when it hits a target.
local function OnHit(inst, attacker, target)
    local impactfx = SpawnPrefab("impact")
    if impactfx ~= nil and target.components.combat then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        if attacker ~= nil and attacker:IsValid() then
            impactfx:FacePoint(attacker.Transform:GetWorldPosition())
        end
    end

	if target and target.components.combat and target.components.freezable then
		local resistance = target.components.freezable:ResolveResistance()
		local coldness = target.components.freezable.coldness

		local coldval = 1 / resistance
		if resistance > coldness + 2 then
			target.components.freezable:AddColdness(coldval)
		elseif resistance > coldness + 1 then
			target.components.freezable:AddColdness(coldval / 4)
		else
			target.components.freezable:AddColdness(coldval / 8)
		end
		local bonusdamage = 100
		bonusdamage = bonusdamage * coldness / resistance

		if target.sg ~= nil and target.sg:HasStateTag("frozen") then
			SpawnPrefab("bramblefx_rime"):SetFXOwner(target)
		end


		target.components.combat:GetAttacked(attacker, bonusdamage) -- Frost-type damage, which is based on how close to freezing the enemy is
		target.components.freezable:SpawnShatterFX()
	end

    inst:Remove()
end

local function OnThrown(inst)
    inst.AnimState:PlayAnimation("dart_rime")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function OnThrownListened(inst, data)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.components.inventoryitem.pushlandedevents = false
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_blowdart_rime")
    inst.AnimState:SetBuild("um_blowdart_rime")
    inst.AnimState:PlayAnimation("dart_rime")

    MakeInventoryFloatable(inst, "small", 0.05, { 0.75, 0.5, 0.75 })
    local swap_data = { sym_build = "swap_blowdart", bank = "um_blowdart_rime", anim = "idle_rime" }
    inst.components.floater:SetBankSwapOnFloat(true, -4, swap_data)

    inst:AddTag("blowdart")
    inst:AddTag("sharp")
    inst:AddTag("donotautopick")
    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(75)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(60)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst:ListenForEvent("onthrown", OnThrownListened)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_blowdart_rime.xml"
    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable.equipstack = true

    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("um_blowdart_rime", fn, nil, prefabs)

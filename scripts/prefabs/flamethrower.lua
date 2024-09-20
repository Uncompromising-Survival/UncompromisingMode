local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local prefabs =
{
	"stafflight",
	"reticule",
}

local function getspawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0, z1 + .15 * (z2 - z1)
end

local function createlight(staff, target, pos)
	local caster = staff.components.inventoryitem.owner
	for i = 1, 4 do
		staff:DoTaskInTime(i/4, function(staff)
			if caster.wyroaimingx ~= nil then
				print("aiming acceptable") 
				local x, y, z = caster.Transform:GetWorldPosition()
				
				caster.wyroaimingx = caster.wyroaimingx + math.random(-1, 1)
				caster.wyroaimingz = caster.wyroaimingz + math.random(-1, 1)
				
				local targetpos = Vector3(caster.wyroaimingx, 0, caster.wyroaimingz)
				local projectile = SpawnPrefab("flamethrower_projectile")
				
				projectile.Transform:SetPosition(x, y, z)
				projectile.components.linearprojectile:SetHorizontalSpeed(10)
				projectile.components.linearprojectile:Launch(targetpos, caster, caster)
				projectile.attacker = caster
			end
		end)
	end
end

local function light_reticuletargetfn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_beargerclaw", "swap_shovel")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function can_cast_fn(doer, target, pos)
	if doer.wyroaimingx ~= nil then
		return true
	else
		return false
	end
end

local function staff_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

   -- inst.AnimState:SetBank("beargerclaw")
   -- inst.AnimState:SetBuild("beargerclaw")
   -- inst.AnimState:PlayAnimation("idle")

    inst:AddTag("nopunch")

    --Sneak these into pristine state for optimization
    inst:AddTag("flamethrower")
    --inst:AddTag("quickcast")
	
	MakeInventoryFloatable(inst)

    inst.spelltype = "SCIENCE"

    inst.entity:SetPristine()
	
    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	--inst.components.inventoryitem.atlasname = "images/inventoryimages/beargerclaw.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(3, 3)
	
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true

    MakeHauntableLaunch(inst)

    return inst
end

local function projectiletargetfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("flamethrower", staff_fn, assets, prefabs),
		Prefab("flamethrower_target", projectiletargetfn)
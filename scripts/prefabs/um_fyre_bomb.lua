local fyre_bomb_assets =
{
	Asset("ANIM", "anim/um_fyre_bomb.zip"),
    Asset("ANIM", "anim/swap_um_fyre_bomb.zip"),
}

local shouldnt_hit = { "FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost" }

local function OnHitFyre(inst, attacker, target)
	local x,y,z = inst.Transform:GetWorldPosition()
	local fx = SpawnPrefab("explosivehit")
	fx.Transform:SetPosition(x,y,z)
	fx.Transform:SetScale(1.25,1.25,1.25)
	fx:DoTaskInTime(2,function(fx) fx:Remove() end)
	local ents = TheSim:FindEntities(x, y, z, 3, nil,shouldnt_hit)
	if #ents > 0 then
		for i, v in pairs(ents) do
			if (not v:HasTag("player") or v == attacker) then
				if v.components.burnable ~= nil then
					v.components.burnable:Ignite()
				end
				if v.components.combat then
					v.components.combat:GetAttacked(attacker,100)
				end
			end
		end
	end
	local ents = TheSim:FindEntities(x,y,z,3,nil,{ "INLIMBO"}, { "CHOP_workable", "MINE_workable","HAMMER_workable","DIG_workable" })
	for i,v in ipairs(ents) do
		if v:HasTag("CHOP_workable") then
			v.components.workable:WorkedBy(attacker, 15)
		elseif v:HasTag("HAMMER_workable") then
			v.components.workable:WorkedBy(attacker,4)
		elseif v:HasTag("DIG_workable") then
			v.components.workable:WorkedBy(attacker,1)
		else
			v.components.workable:WorkedBy(attacker, 3)
		end
	end
    inst:Remove()
end

local function common_fn(bank, build, anim, tag, isinventoryitem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    if isinventoryitem then
        MakeInventoryPhysics(inst)
    else
        inst.entity:AddPhysics()
        inst.Physics:SetMass(1)
        inst.Physics:SetFriction(0)
        inst.Physics:SetDamping(0)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.Physics:SetCapsule(0.2, 0.2)
        inst.Physics:SetDontRemoveOnSleep(true) -- so the object can land and put out the fire, also an optimization due to how this moves through the world
    end

    if tag ~= nil then
        inst:AddTag(tag)
    end

    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")
	inst:AddTag("complexprojectile")

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)

    if type(anim) ~= "table" then
        inst.AnimState:PlayAnimation(anim, true)
    elseif #anim == 1 then
        inst.AnimState:PlayAnimation(anim[1], true)
    else
        for i, a in ipairs(anim) do
            if i == 1 then
                inst.AnimState:PlayAnimation(a, false)
            elseif i ~= #anim then
                inst.AnimState:PushAnimation(a, false)
            else
                inst.AnimState:PushAnimation(a, true)
            end
        end
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")


    inst:AddComponent("complexprojectile")

    return inst
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_fyre_bomb", "swap_um_fyre_bomb")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onthrown(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false

    inst.AnimState:PlayAnimation("spin_loop", true)

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Attack range is 8, leave room for error
    --Min range was chosen to not hit yourself (2 is the hit range)
    for r = 6.5, 3.5, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function fyre_bomb_fn()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = common_fn("um_fyre_bomb", "um_fyre_bomb", "idle", "weapon", true)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
	inst.components.reticule.ispassableatallpoints = true
	inst.components.reticule.validfn = function(inst) return true end
    MakeInventoryFloatable(inst, "med", 0.05, 0.65)
	inst:AddTag("allow_action_on_impassable")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitFyre)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true


    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("um_fyre_bomb", fyre_bomb_fn, fyre_bomb_assets)

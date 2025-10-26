local um_boomberry_bomb_assets =
{
	Asset("ANIM", "anim/um_boomberry_bomb.zip"),
    Asset("ANIM", "anim/swap_um_boomberry_bomb.zip"),
}
local shouldnt_hit = { "FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost" }
local function OnHitBoomBerry(inst, attacker, target)
	local x,y,z = inst.Transform:GetWorldPosition()
	SpawnPrefab("blueberryexplosion").Transform:SetPosition(x,y,z)
	local puddle = SpawnPrefab("blueberrypuddle")
	puddle.Transform:SetPosition(x,y,z)
	puddle.playermade = true

	puddle.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap")
	local ents = TheSim:FindEntities(x, y, z, 3, nil,shouldnt_hit)
	if #ents > 0 then
		for i, v in pairs(ents) do
			if (not v:HasTag("player") or v == attacker) then
				if v.components.combat then
					v.components.combat:GetAttacked(attacker,68)
				end
			end
		end
	end
	inst:Hide()
	inst.components.wateryprotection:SpreadProtection(inst)
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

    inst:AddComponent("wateryprotection")
    inst:AddComponent("complexprojectile")

    return inst
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_boomberry_bomb", "swap_um_boomberry_bomb")
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

local function um_boomberry_bomb()
    --weapon (from weapon component) added to pristine state for optimization
    local inst = common_fn("um_boomberry_bomb", "um_boomberry_bomb", "idle", "weapon", true)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
	inst.components.reticule.ispassableatallpoints = true
	inst.components.reticule.validfn = function(inst) return true end
    MakeInventoryFloatable(inst, "med", 0.05, 0.65)
    -- From watersource component
    inst:AddTag("watersource")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnHitBoomBerry)

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
	
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED/3)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
	
    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("um_boomberry_bomb", um_boomberry_bomb, um_boomberry_bomb_assets)

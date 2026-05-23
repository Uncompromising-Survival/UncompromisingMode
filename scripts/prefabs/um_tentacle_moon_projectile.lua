local assets =
{
    Asset("ANIM", "anim/um_lunartentacledart.zip"),
    Asset("ANIM", "anim/swap_um_tentaclespike_moon.zip"),
    Asset("ANIM", "anim/um_tentaclespike_moon.zip"),
}

local should_hit = { "_health","_combat"}
local shouldnt_hit = {"ghost","brightmare_gestalt","nightmarecreature","um_tentacle_moon"}

local function OnLand(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if not inst.nomine and TheWorld.Map:IsAboveGroundAtPoint(x,y,z) then
        local mine = SpawnPrefab("um_tentacle_moon_mine")
        if inst.attacker then
            mine.attacker = inst.attacker
            mine.attacker_faction = inst.attacker_faction
        end
        mine.SoundEmitter:PlaySound("dontstarve/impacts/impact_metal_armour_blunt")
        mine.components.mine:Reset()
        mine.Transform:SetPosition(x,y,z)
    end

    local ents = TheSim:FindEntities(x, y, z, 1.5, should_hit, shouldnt_hit)
    for i, v in ipairs(ents) do
        if v.prefab ~= inst.attacker.prefab and not (inst.attacker_faction and v:HasTag(inst.attacker_faction)) then
            v.components.combat:GetAttacked(inst.attacker and inst.attacker or nil,20,inst)
        end
    end
    inst:Remove()
end

local function onthrown(inst, attacker, targetPos)
    inst:AddTag("NOCLICK")
    --inst.persists = false
    inst.AnimState:SetBank("lunartentacledart")
    inst.AnimState:SetBuild("lunartentacledart")
    inst.AnimState:PlayAnimation("air_loop", true)

    inst.Physics:SetMass(1)
    inst.Physics:SetCapsule(0.2, 0.2)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    

    if attacker then
        inst.attacker = attacker
    end
end

local function lobbedprojectilefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()


    --[[
    inst.AnimState:SetBank("spat_bomb")
    inst.AnimState:SetBuild("web_net_shot")
    inst.AnimState:PlayAnimation("spin_loop", true)
    ]]


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnLand)

    inst.persists = false

    return inst
end
-- Projectile functions above

local function DoDamageEffect(inst,target)
	
	local mult = 1
	local plague
	if target.components.inventory then
		if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "plaguemask" then
				plague = true
			end
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "um_hat_nettlemask" then
				mult = mult * 0.25
			end
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "gasmask" then
				mult = mult * 0.25
			end
		end
		if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
			if target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "minifan" then
				mult = mult * 0.25
			end
		end
	end

	if not plague then
        if target.components.combat and not target.components.health:IsDead() then
            target.components.combat:GetAttacked(inst.attacker and inst.attacker or nil,20,inst)	
        end
		target:PushEvent("knockback", { knocker = inst, radius = 1.5, strengthmult = 1.5, forcelanded = true })
	end
end

local function OnExplode(inst, target)
    inst.DynamicShadow:Enable(false)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3)
    for i, v in ipairs(ents) do
        if inst.attacker and v.prefab ~= inst.attacker.prefab and v:HasAllTags(should_hit) and not v:HasAnyTag(shouldnt_hit) and not (inst.attacker_faction and v:HasTag(inst.attacker_faction)) then
            DoDamageEffect(inst,v)
        end
    end
	--inst:DoTaskInTime(0.1,function(inst) --AXE trigger the spoil after a delay, incase something was dropped from an enemy
		local ents = TheSim:FindEntities(x, y, z, TUNING.TRAP_TEETH_RADIUS)
		for i, v in ipairs(ents) do
			if v.components.inventoryitem and v.components.perishable then
				if v.components.inventoryitem:IsHeld() then
					v.components.perishable:SetPercent(v.components.perishable:GetPercent()-0.05)
				else
					v.components.perishable:SetPercent(0)
				end
			end
		end
	--end)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/infection_burst")
    inst.components.umripples:OnNoLongerLandedServer()
    inst.AnimState:PlayAnimation("explode")
    local poof = SpawnPrefab("air_conditioner_smoke")
    poof.AnimState:SetMultColour(1,1,0.2,1)
    poof.Transform:SetPosition(x,y,z)
    poof.Transform:SetScale(0.75,0.75,0.75)
    inst:ListenForEvent("animover",function(inst) inst:Remove() end)
end

-- AXE Just copying starfish again...
local function calculate_mine_test_time()
    return TUNING.STARFISH_TRAP_TIMING.BASE + (math.random() * TUNING.STARFISH_TRAP_TIMING.VARIANCE)
end

local function lobbedminefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local shadow = inst.entity:AddDynamicShadow()
    shadow:SetSize(1.5, 1)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lunartentacledart")
    inst.AnimState:SetBuild("lunartentacledart")
    inst.AnimState:PlayAnimation("impact_land"  )
    inst.AnimState:PushAnimation("idle_land",true)

    inst:AddTag("trap")
    inst:AddTag("bear_trap")
    
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    local mine = inst:AddComponent("mine")
    mine:SetRadius(0.5)
    mine:SetOnExplodeFn(OnExplode)
    mine:SetTestTimeFn(calculate_mine_test_time)
    mine:SetAlignment("tentacle")
    mine:Reset()

    --inst:AddComponent("deployable")
    --inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnExplode)

    inst.deathtask = inst:DoTaskInTime(math.random(2,6), OnExplode)

    return inst
end

local shouldnt_hit = {"INLIMBO", "notarget", "noattack", "playerghost"}


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
    owner.AnimState:OverrideSymbol("swap_object", "swap_um_tentaclespike_moon", "swap_um_tentaclespike_moon")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
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

local function thrownfn()
    --weapon (from weapon component) added to pristine state for optimization

    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_tentaclespike_moon")
    inst.AnimState:SetBuild("um_tentaclespike_moon")
    inst.AnimState:PushAnimation("idle",true)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true
    inst.components.reticule.validfn = function(inst) return true end
    MakeInventoryFloatable(inst, "med", 0.05, 0.65)
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("weapon")

    inst:AddTag("projectile")
    inst:AddTag("complexprojectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")


    inst:AddComponent("complexprojectile")

    inst.components.complexprojectile:SetHorizontalSpeed(20)
    inst.components.complexprojectile:SetGravity(-30)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
    inst.components.complexprojectile:SetOnHit(OnLand)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(16, 16)
    inst.components.weapon.toss_range_override = 16 --AXE override the usual toss range, additional code in init_actions passes this value

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    return inst
end

return Prefab("um_tentacle_moon_projectile", lobbedprojectilefn,assets),
Prefab("um_tentacle_moon_mine", lobbedminefn,assets),
Prefab("um_tentaclespike_moon", thrownfn, assets)

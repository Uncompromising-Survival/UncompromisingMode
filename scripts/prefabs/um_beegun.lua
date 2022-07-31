local assets =
{
    Asset("ANIM", "anim/slingshot.zip"),
    Asset("ANIM", "anim/swap_slingshot.zip"),
}

local prefabs =
{
	"slingshotammo_rock_proj",
}

local PROJECTILE_DELAY = 2 * FRAMES

local function OnEquip(inst, owner)
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
		owner.AnimState:OverrideSymbol("swap_object", "swap_um_beegun", "swap_um_beegun")
		owner.AnimState:Show("ARM_carry")
		owner.AnimState:Hide("ARM_normal")

		if inst.components.container ~= nil then
			inst.components.container:Open(owner)
		end
	end
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function OnProjectileLaunched(inst, attacker, target)
	if inst.components.container ~= nil then
		local ammo_stack = inst.components.container:GetItemInSlot(1)
		local item = inst.components.container:RemoveItem(ammo_stack, false)
		if item ~= nil then
            inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
			
			item:Remove()
		end
	end
end

local function OnAmmoLoaded(inst, data)
	if inst.components.weapon ~= nil then
		if data ~= nil and data.item ~= nil then
			inst.components.weapon:SetProjectile("um_"..data.item.prefab.."_proj")
		end
	end
end

local function OnAmmoUnloaded(inst, data)
	if inst.components.weapon ~= nil then
		inst.components.weapon:SetProjectile(nil)
	end
end

local floater_swap_data = {sym_build = "swap_um_beegun"}

local function ReticuleTargetFn(inst)
    return Vector3(inst.entity:LocalToWorldSpace(6.5, 0, 0))
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

local function collectbees(inst, target, pos)
	local owner = inst.components.inventoryitem.owner
	local ownerpos = owner ~= nil and owner:GetPosition()
	
	if owner ~= nil then
		if pos ~= nil then
			local findbees = TheSim:FindEntities(pos.x, 0, pos.z, 8, {"bee"})
			if findbees ~= nil then
				for i, v in pairs(findbees) do
					if v ~= nil and not v:IsInLimbo() and v:IsValid() and v.components.inventoryitem and not v.components.health:IsDead() then
						if inst.components.container ~= nil then
							local beeball = SpawnPrefab("um_"..v.prefab.."_ball")
							beeball.Transform:SetPosition(v.Transform:GetWorldPosition())
							beeball.components.complexprojectile:Launch(ownerpos, owner, owner)
							beeball.beegun = inst
							
							v:Remove()
							--inst.components.container:GiveItem(v)
						end
					end
				end
			end
		elseif target ~= nil then
			local x, y, z = target.Transform:GetWorldPosition()
		
			local findbees = TheSim:FindEntities(x, 0, z, 8, {"bee"})
			if findbees ~= nil then
				for i, v in pairs(findbees) do
					if v ~= nil and not v:IsInLimbo() and v:IsValid() and v.components.inventoryitem and not v.components.health:IsDead() then
						if inst.components.container ~= nil then
							local beeball = SpawnPrefab("um_"..v.prefab.."_ball")
							beeball.Transform:SetPosition(v.Transform:GetWorldPosition())
							beeball.components.complexprojectile:Launch(ownerpos, owner, owner)
							beeball.beegun = inst
							
							v:Remove()
							--inst.components.container:GiveItem(v)
						end
					end
				end
			end
		end
	end
end

local function can_cast_fn(doer, target, pos)
	if doer:HasTag("vetcurse") then
		return true
	else
		return false
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_beegun")
    inst.AnimState:SetBuild("um_beegun")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("rangedweapon")
    inst:AddTag("beegun")
    inst:AddTag("allow_action_on_impassable")
	inst:AddTag("vetcurse_item")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --inst.projectiledelay = PROJECTILE_DELAY

    MakeInventoryFloatable(inst, "med", 0.075, {0.5, 0.4, 0.5}, true, -7, floater_swap_data)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true
    inst.components.reticule.mouseenabled = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst) 
			inst.replica.container:WidgetSetup("um_beegun") 
		end
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/um_beegun.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(15)
    inst.components.weapon:SetRange(TUNING.SLINGSHOT_DISTANCE, TUNING.SLINGSHOT_DISTANCE_MAX)
    inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
    inst.components.weapon:SetProjectile(nil)
	inst.components.weapon:SetProjectileOffset(1)
	
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("um_beegun")
	inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", OnAmmoLoaded)
    inst:ListenForEvent("itemlose", OnAmmoUnloaded)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(collectbees)
    inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
	inst.components.spellcaster.canuseonpoint = true

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

local function onhit(inst, attacker, target)
    local impactfx = SpawnPrefab("impact")
    if impactfx ~= nil and target.components.combat then
        local follower = impactfx.entity:AddFollower()
        follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
        if attacker ~= nil and attacker:IsValid() then
            impactfx:FacePoint(attacker.Transform:GetWorldPosition())
        end
    end
	
	
	local bee = SpawnPrefab(inst.beetype)
	bee.Transform:SetPosition(inst.Transform:GetWorldPosition())
	
	if target ~= nil then
		bee.components.combat:SuggestTarget(target)
	end
	
    inst:Remove()
end

local function pipethrown(inst)
	inst.SoundEmitter:PlaySound(inst.sound)
    inst.AnimState:PlayAnimation(inst.anim)
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function common(anim, beetype, sound)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_beegun_dart")
    inst.AnimState:SetBuild("um_beegun_dart")
    inst.AnimState:PlayAnimation(anim)
	inst.Transform:SetScale(1.2, 1.2, 1.2)
    inst.Transform:SetFourFaced()

    --inst:AddTag("blowdart")
    inst:AddTag("sharp")

    --inst:AddTag("weapon")

    inst:AddTag("projectile")
	inst:AddTag("vetcurse_item")

	RemovePhysicsColliders(inst)

    --MakeInventoryFloatable(inst, "small", 0.05, {0.75, 0.5, 0.75})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.beetype = beetype
	inst.sound = sound
	inst.anim = anim

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(15)
    inst.components.weapon:SetRange(8, 10)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(20)
    inst.components.projectile:SetOnHitFn(onhit)
    inst.components.projectile:SetOnThrownFn(pipethrown)
    inst.components.projectile:SetLaunchOffset(Vector3(.5, .5, 0))
    --inst.components.projectile:SetLaunchOffset(Vector3(.5, 1.5, 0))
    inst.components.projectile:SetHitDist(math.sqrt(5))
    -------

    --inst:AddComponent("inspectable")

    --inst:AddComponent("inventoryitem")

    return inst
end

local function yellow()
    local inst = common("beedart_yellow", "bee", "dontstarve/bee/bee_attack")

    return inst
end
	
local function red()
    local inst = common("beedart_red", "killerbee", "dontstarve/bee/killerbee_attack")

    return inst
end

local function OnHitBall(inst, attacker, target)
	if inst.beegun ~= nil and inst.beegun:IsValid() then
		inst.beegun.components.container:GiveItem(SpawnPrefab(inst.beetype))
		local beefx = SpawnPrefab("bee_poof_small")
		
		local owner = inst.beegun.components.inventoryitem.owner
		
		if owner ~= nil then
			beefx.entity:SetParent(owner.entity)
			beefx.entity:AddFollower()
			beefx.Follower:FollowSymbol(owner.GUID, "swap_object", 30, 0, 0.1)
		else
			beefx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		end
		
		
	else
		SpawnPrefab(inst.beetype).Transform:SetPosition(inst.Transform:GetWorldPosition())
	end

    inst:Remove()
end

local function onthrown_ball(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.AnimState:PlayAnimation(inst.anim.."spin_loop", true)
	inst.SoundEmitter:PlaySound(inst.sound)
	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()

	inst.Physics:SetCapsule(0.02, 0.02)
	
    inst.Physics:SetCollisionCallback(nil)
end

local function commonball(anim, beetype, sound)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_beegun_ball")
    inst.AnimState:SetBuild("um_beegun_ball")
    inst.AnimState:PlayAnimation(anim.."spin_loop")
    inst.Transform:SetFourFaced()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.beetype = beetype
	inst.sound = sound
	inst.anim = anim

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(25)
    inst.components.complexprojectile:SetGravity(-30)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown_ball)
    inst.components.complexprojectile:SetOnHit(OnHitBall)
    inst.components.complexprojectile.usehigharc = true

    inst.persists = false

    inst:AddComponent("locomotor")

	inst:DoTaskInTime(5, inst.Remove)

    return inst
end

local function yellowball()
    local inst = commonball("yellow", "bee", "dontstarve/bee/bee_attack")

    return inst
end
	
local function redball()
    local inst = commonball("red", "killerbee", "dontstarve/bee/killerbee_attack")

    return inst
end
	
return Prefab("um_beegun", fn, assets, prefabs),
		Prefab("um_bee_proj", yellow, assets, prefabs),
		Prefab("um_bee_ball", yellowball, assets, prefabs),
		Prefab("um_killerbee_proj", red, assets, prefabs),
		Prefab("um_killerbee_ball", redball, assets, prefabs)
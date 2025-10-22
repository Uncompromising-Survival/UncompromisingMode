local flamethrowerassets =
{
    Asset("ANIM", "anim/swap_um_flamethrower.zip"),
	Asset("ANIM", "anim/um_flameburster.zip"),
}

local scrappylaserassets =
{
    Asset("ANIM", "anim/swap_um_scrappylaser.zip"),
}

local easing = require("easing") -- keep it for later?


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

local function ConsumeAmmo(inst)
    if inst.components.container ~= nil then
        local ammo_stack = inst.components.container:GetItemInSlot(1)
        local item = inst.components.container:RemoveItem(ammo_stack, false)
        if item ~= nil then
            inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
			local prefabname = item.prefab
            item:Remove()
			return prefabname
        end
    end
end

local pepper_pattern = {-20,-10,0,10,20}
local pepperflake_pattern = {-30,-20,-10,0,10,20,30} -- Not sure if I should make it really that much better, warly is already making hte ammo nonperishable and multiplied
local nettle_pattern = {-10,0,10}

local function Flamethrower(inst,caster, target)
	local ammo = ConsumeAmmo(inst)
	if ammo then
		if inst.components.finiteuses then
			inst.components.finiteuses:Use(1)
		end
		local pattern
		if ammo == "pepper" then
			pattern = pepper_pattern
		elseif ammo == "spice_chili" then
			pattern = pepperflake_pattern
		else
			pattern = nettle_pattern
		end
		local targetpos = target:GetPosition()
		local rot = caster.Transform:GetRotation() 
		local x,y,z = caster.Transform:GetWorldPosition() 
		
		-- Fix for shooting
		local fx = SpawnPrefab("explosivehit")
		local dx = 1.5*math.sin((rot+ 90) * DEGREES)
		local dz = 1.5*math.cos((rot+ 90) * DEGREES)
		fx.Transform:SetPosition(x + dx,0,z+dz)
		fx.Transform:SetScale(0.5,0.5,0.5)
			
		for i = 1,#pattern do
			local interval_rot = pattern[i]
			local random_rotation = math.random(-1,1)
			local projectile = SpawnPrefab("um_fire_projectile")
			local dx = 2.1*math.sin((rot+ 90+interval_rot+random_rotation) * DEGREES)
			local dz = 2.1*math.cos((rot+ 90+interval_rot+random_rotation) * DEGREES)
			projectile.Transform:SetPosition(x + dx,2,z+dz)
			projectile.Transform:SetRotation(rot+interval_rot+random_rotation)
			projectile.speed = 15
			projectile.scale = 1 + math.random(0,10)/100 -- scale up sometimes.
			projectile.damage = 3
			projectile.damager = caster
		end
	end
end

local function CalcKnockback(scale)
	if scale >= 1 then
		return nil, Lerp(1, 1.5, scale - 1)
	end
	return scale, scale * 1.3, true
end

local function CalcDamage(dist)
	local min = TUNING.ALTERGUARDIAN_PHASE3_LASERDAMAGE * TUNING.DAYWALKER2_CANNON_FAR_DAMAGE_MULT
	local max = TUNING.ALTERGUARDIAN_PHASE3_LASERDAMAGE * TUNING.DAYWALKER2_CANNON_NEAR_DAMAGE_MULT
	return math.clamp(Remap(dist, 5.4, 10, max, min), min, max), TUNING.ALTERGUARDIAN_PLAYERDAMAGEPERCENT
end

local function SpawnLaser(inst)
	local dist = 2
	local scale = 1
	local scorchscale = 1
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = (inst.Transform:GetRotation() + 90) * DEGREES
	local fx = SpawnPrefab("alterguardian_laser")
	fx.caster = inst
	fx.Transform:SetPosition(x + dist * math.cos(rot), 0, z - dist * math.sin(rot))

	local knockback = scale >= 1 and Lerp(1, 1.5, scale - 1) or nil
	local animscale = scale * (0.9 + math.random() * 0.2) * (inst.sg.mem.fliplaser and -1 or 1)
	inst.sg.mem.fliplaser = not inst.sg.mem.fliplaser

	local dmg, playerdamagepercent = CalcDamage(dist)
	local hitscale = math.max(1, scale)
	local heavymult, mult, forcelanded = CalcKnockback(scale)

	fx:OverrideDamage(dmg, playerdamagepercent)
	fx:Trigger(0, nil, nil, scorchscale < 0.2, animscale, scorchscale, hitscale, heavymult, mult, forcelanded)
	return dist + 0.4
end

local function getspawnlocation(inst, target)
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local x2, y2, z2 = target.Transform:GetWorldPosition()
    return x1 + .15 * (x2 - x1), 0, z1 + .15 * (z2 - z1)
end

local function createtarget(inst, target, pos) -- Need a stand-in target incase the player targets the ground
        local spittarget = SpawnPrefab("lavaspit_target")
        local caster = inst.components.inventoryitem.owner
        
        if pos ~= nil then
            spittarget.Transform:SetPosition(pos:Get())
            spittarget:DoTaskInTime(5, spittarget.Remove)
            inst.Fire(inst,caster, spittarget)
        elseif target ~= nil then
            spittarget.Transform:SetPosition(getspawnlocation(inst, target))
            spittarget:DoTaskInTime(5, spittarget.Remove)
            inst.Fire(inst,caster, target)
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
	owner.AnimState:OverrideSymbol("swap_object", inst.anims, inst.anims)
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	
	if inst.components.container ~= nil then
		inst.components.container:Open(owner)
	end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
	
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end
end

local function generalfn(anim,container_widget)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)



    inst:AddTag("nopunch")
    inst:AddTag("donotautopick")
    inst:AddTag("um_gun")
	
    --Sneak these into pristine state for optimization
    inst:AddTag("quickcast")
    inst:AddTag("inventoryitem")
    MakeInventoryFloatable(inst)

    inst.spelltype = "UM_GUNSHOOTY"

    inst.entity:SetPristine()
    
    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst)
            inst.replica.container:WidgetSetup(container_widget)
        end
        return inst
    end

	inst.anims = anim
    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    
    
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createtarget)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonworkable = true
    inst.components.spellcaster.canonlyuseoncombat = true
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
	
    local container = inst:AddComponent("container")
    container:WidgetSetup(container_widget)
    container.canbeopened = false
	
    MakeHauntableLaunch(inst)

    return inst
end

local function FlameFn(inst)
	local inst = generalfn("swap_um_flamethrower","um_flamethrower")
	inst.Fire = Flamethrower
    inst.AnimState:SetBank("um_flameburster")
    inst.AnimState:SetBuild("um_flameburster")
    inst.AnimState:PlayAnimation("idle")	
	
    inst:AddComponent("finiteuses")
	local uses = 400
    inst.components.finiteuses:SetMaxUses(uses)
    inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	
	return inst
end

local function ScrappyLaserFn(inst)
	local inst = generalfn("swap_um_scrappylaser","um_flamethrower")
	inst.Fire = SpawnLaser
    inst.AnimState:SetBank("um_scrappylaser")
    inst.AnimState:SetBuild("swap_um_scrappylaser")
    inst.AnimState:PlayAnimation("idle")	
	return inst
end


return Prefab("um_flamethrower", FlameFn, flamethrowerassets),
Prefab("um_scrappylaser", ScrappyLaserFn, scrappylaserassets)
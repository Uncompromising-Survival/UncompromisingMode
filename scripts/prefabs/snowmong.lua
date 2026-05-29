require "stategraphs/SGsnowmong"
local easing = require("easing")
local brain = require "brains/snowmongbrain"

local assets =
{
	Asset("ANIM", "anim/snowmong.zip"),
	Asset("ANIM", "anim/um_ice_tail.zip"),
}

SetSharedLootTable( 'snowmong',
{
    {'charcoal',            1.00},
	{'charcoal',            1.00},
    {'ice',  			 	1.00},
	{'ice',  			 	1.00},
	{'ice',  			 	1.00},
	{'snowball_item',  1.00},
	{'snowball_item',  2.00},
	
})

SetSharedLootTable( 'snowmong_melting',
{
    {'charcoal',            1.00},
	{'charcoal',            1.00},
    {'ice',  			 	1.00},
	{'snowball_item',  1.00},
	
})

local function SetUnder(inst)
	inst.State = true
	inst:AddTag("notdrawable")
	inst:AddTag("INLIMBO")
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
end

local function SetAbove(inst)
	inst.State = false
	inst:RemoveTag("INLIMBO")
	inst:RemoveTag("notdrawable")
	ChangeToCharacterPhysics(inst)
end

local function CanBeAttacked(inst, attacker)
	return inst.State == false
end

local AGGRO_RANGE = 30
local AGGRO_RANGE_SQ = AGGRO_RANGE * AGGRO_RANGE

local function Retarget(inst)
    local notags = {"FX", "NOCLICK","INLIMBO", "playerghost", "shadowcreature","webbedcreature","wall","structure","companion","snowish"}
    return FindEntity(inst, AGGRO_RANGE, function(guy)
        return guy:HasTag("player") and inst.components.combat:CanTarget(guy) and not guy.components.health:IsDead()
    end, nil, notags)
end

local function KeepTarget(inst, target)
    return target:IsValid()
        and inst.components.combat:CanTarget(target)
        and inst:GetDistanceSqToInst(target) <= AGGRO_RANGE_SQ
end

local function OnSleep(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function OnRemove(inst)
    inst.SoundEmitter:KillAllSounds()
end

local function melting(inst)
	if not TheWorld.state.iswinter then
		if not inst.components.health:IsDead() then
			inst.components.lootdropper:SetChanceLootTable('snowmong_melting')
			SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
			SpawnPrefab("washashore_puddle_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.components.health:DoDelta(-50)
		end
	else
		inst.components.lootdropper:SetChanceLootTable('snowmong')
	end
end

local function OnAttacked(inst, data)
    local attacker = data and data.attacker
    if attacker and attacker:IsValid()
        and attacker.components.health and not attacker.components.health:IsDead() then
        if inst.components.health:GetPercent() > 0.3 then
            inst.components.combat:SetTarget(attacker)
        else
            inst.components.combat:SetTarget(nil)
        end
    end
end

local function SetLevel(inst, level, no_fx)
	level = math.clamp(level, 1, 30)
	local current_hp = inst.components.health.currenthealth
	inst.components.health:SetMaxHealth(50*(level-1)+250)
	inst.components.health:SetPercent(current_hp / inst.components.health.maxhealth)
	inst.Transform:SetScale(2*(level)^0.1, 2*(level)^0.1, 2*math.sqrt(level)^0.1)
	inst.components.combat:SetDefaultDamage(30*(level)^0.25)
	local range = 2 + (level-1)/29*2
	inst.components.combat:SetRange(range, range)
	if not no_fx then
		local icefx = SpawnPrefab("deer_ice_flakes")
		if icefx then
			local x, y, z = inst.Transform:GetWorldPosition()
			icefx.Transform:SetPosition(x, y, z)
			icefx.Transform:SetScale(0.7, 1.2, 1.2)
			icefx.AnimState:PlayAnimation("idle")
			icefx:DoTaskInTime(0, icefx.KillFX)
		end
	end
end

local function IntegrateSnowStuff(inst) --AXE I'm using the mole's steal action as a psuedo eat action so I don't need to assign a food type for specifically 3 items
	local buffaction = inst:GetBufferedAction()
	local item = buffaction and buffaction.target and buffaction.target or nil
	if item and item:IsValid() and not (item.components.inventoryitem and item.components.inventoryitem:IsHeld()) then
		local level = 0
		local heal = 200
		if item.prefab == "um_gemologybluegem1" or item.prefab == "um_gemologybluegem2" then
			local tier = math.max(item:GetTier(), 1)
			local stacksize = (item.components.stackable and item.components.stackable:StackSize()) or 1
			local current_eaten = inst.gems_eaten or 0
			local gems_to_add = math.min(stacksize, 10 - current_eaten)
			if gems_to_add > 0 then
				inst.gem_level = math.clamp(tier, inst.gem_level and inst.gem_level or 0, 3)
				inst.gem_chance = (inst.gem_chance and inst.gem_chance or 0) + tier * gems_to_add
				inst.upgrade_level = (inst.upgrade_level or 1) + 10 * gems_to_add
				inst.gems_eaten = current_eaten + gems_to_add
				inst.gem_tier_list = inst.gem_tier_list or {}
				for i = 1, gems_to_add do
					table.insert(inst.gem_tier_list, { prefab = item.prefab, tier = tier })
				end
				heal = heal * 1.25
			end
		end
		if item.prefab == "bluegem" then
			inst.upgrade_level = (inst.upgrade_level or 1) + 10
			heal = heal * 1.25
		end
		if item.prefab == "ice" then
			inst.upgrade_level = (inst.upgrade_level or 1) + 3
		end
		if item.prefab == "snowball_item" then
			inst.upgrade_level = (inst.upgrade_level or 1) + 1
			heal = 200
		end
		SetLevel(inst,inst.upgrade_level)
		inst.components.health:DoDelta(heal)
		SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
		item:Remove() -- Mong ate the item, it's part of 'em now
		inst:ClearBufferedAction()
	end
end

local function OnSave(inst)
	local data = {}
	if inst.gem_level then
		data.gem_level = inst.gem_level
		data.gem_chance = inst.gem_chance
	end
	if inst.gems_eaten then
		data.gems_eaten = inst.gems_eaten
	end
	if inst.gem_tier_list then
		data.gem_tier_list = inst.gem_tier_list
	end
	if inst.upgrade_level then
		data.upgrade_level = inst.upgrade_level
	end
	return data
end

local function OnLoad(inst,data)
	if data then
		if data.gem_level then
			inst.gem_level = data.gem_level
			inst.gem_chance = data.gem_chance
		end
		if data.gems_eaten then
			inst.gems_eaten = data.gems_eaten
		end
		if data.gem_tier_list then
			inst.gem_tier_list = data.gem_tier_list
		end
		if data.upgrade_level then
			inst.upgrade_level = data.upgrade_level
			SetLevel(inst, inst.upgrade_level, true)
		end
	end
end

local function fn(Sim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLightWatcher()

    inst.Transform:SetFourFaced()

	MakeCharacterPhysics(inst, 99999, 0.5)
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.isunder = nil 
        return inst
    end

	inst.AnimState:SetBank("snowmong")
	inst.AnimState:SetBuild("snowmong")

	inst:AddTag("scarytoprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("snowish")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = 2

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(250) -- From 350
	inst.components.health.murdersound = "dontstarve/rabbit/scream_short"
	inst.components.health.fire_damage_scale = 0

	inst:AddComponent("inspectable")
	inst:AddComponent("sleeper")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('snowmong')

	inst:AddComponent("knownlocations")
	inst:DoTaskInTime(0, function() inst.components.knownlocations:RememberLocation("home", Point(inst.Transform:GetWorldPosition()), true) end)

    inst:AddComponent("groundpounder")
  	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 0
	inst.components.groundpounder.numRings = 1

	inst.CanGroundPound = true

    inst:AddComponent("hauntable")
		
	inst:AddComponent("combat")

	inst.components.combat:SetAttackPeriod(3)
	inst.components.combat:SetRange(3, 3)
	inst.components.combat:SetRetargetFunction(3, Retarget)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat.canbeattackedfn = CanBeAttacked

	inst:SetStateGraph("SGsnowmong")
	inst:SetBrain(brain)
	inst.data = {}
	
	inst.seasontask = inst:DoPeriodicTask(3, melting)

	inst.attackUponSurfacing = false
	
	inst.OnEntitySleep = OnSleep
    inst.OnRemoveEntity = OnRemove
    inst:ListenForEvent("enterlimbo", OnRemove)
	
	SetUnder(inst)
	
    inst.SetUnder = SetUnder
	inst.SetAbove = SetAbove

	inst:ListenForEvent("attacked", OnAttacked) 

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst.IntegrateSnowStuff = IntegrateSnowStuff

	inst:DoTaskInTime(0,function(inst)
		if not inst.upgrade_level then
			inst.upgrade_level = 1
			SetLevel(inst, inst.upgrade_level, true)
		end
	end)
	return inst	
end

local function fntail()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("um_ice_tail")
    inst.AnimState:SetBuild("um_ice_tail")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst)
	
    inst:AddTag("icebox_valid")
    inst:AddTag("show_spoilage")
    inst:AddTag("frozen")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "smallmeat"

	inst.Transform:SetScale(1.5,1.5,1.5)
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("snowmong", fn, assets),
    Prefab("um_ice_tail",fntail)
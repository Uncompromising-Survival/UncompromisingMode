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

local SEE_VICTIM_DIST = 25

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

local function Retarget(inst)
    local targetDist = 30
    local notags = {"FX", "NOCLICK","INLIMBO", "playerghost", "shadowcreature","webbedcreature","wall","structure","companion","snowish"}
    return FindEntity(inst, targetDist, function(guy) return inst.components.combat:CanTarget(guy) and not guy.components.health:IsDead() end, nil, notags)
end

local function KeepTarget(inst, target)
    return inst.components.combat:CanTarget(target)
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
	if data.attacker and data.attacker:IsValid() and data.attacker.components.health and not data.attacker.components.health:IsDead() then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function SetLevel(inst,level)
	level = math.clamp(level,1,30)
	inst.components.health:SetMaxHealth(50*(level-1)+250)
	inst.components.health:SetPercent(1)
	inst.Transform:SetScale(2*(level)^0.1, 2*(level)^0.1, 2*math.sqrt(level)^0.1)
	inst.components.combat:SetDefaultDamage(30*(level)^0.25)
	local range = 2 + (level-1)/29*2
	inst.components.combat:SetRange(range, range)
end

local function IntegrateSnowStuff(inst) --AXE I'm using the mole's steal action as a psuedo eat action so I don't need to assign a food type for specifically 3 items
	local buffaction = inst:GetBufferedAction()
	local item = buffaction and buffaction.target and buffaction.target or nil
	if item then
		local level = 0
		if item.prefab == "um_gemologybluegem1" or item.prefab == "um_gemologybluegem2" then
			local tier = item:GetTier()
			inst.gem_level = math.clamp(tier,inst.gem_level and inst.gem_level or 0,3)
			inst.gem_chance = (inst.gem_chance and inst.gem_chance or 0) + tier

			inst.upgrade_level = inst.upgrade_level + 10
		end
		if item.prefab == "bluegem" then
			inst.upgrade_level = inst.upgrade_level + 10	
		end
		if item.prefab == "ice" then
			inst.upgrade_level = inst.upgrade_level + 3	
		end
		if item.prefab == "snowball_item" then
			inst.upgrade_level = inst.upgrade_level + 1
		end
		SetLevel(inst,inst.upgrade_level)
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
		if data.upgrade_level then
			inst.upgrade_level = data.upgrade_level
			SetLevel(inst,inst.upgrade_level)
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
			SetLevel(inst,inst.upgrade_level)
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
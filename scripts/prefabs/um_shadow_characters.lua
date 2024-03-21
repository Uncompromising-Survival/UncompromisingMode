local brain = require "brains/swilsonbrain"
local um_shadow_warly = require "brains/um_shadow_warly"
local um_shadow_walter = require "brains/fuelseekerbrain"

local assets =
{
}

local prefabs =
{

}

SetSharedLootTable('swilson',
{
    {'nightmarefuel',     1.0},
	{'nightmarefuel',     1.0},
})

local function retargetfn(inst)
    --retarget nearby players if current target is fleeing or not a player
	local target = inst.components.combat.target

    local x, y, z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x, y, z, 40, { "player" })
    for i, v in ipairs(players) do
		if inst.components.combat:CanTarget(v) then
			target = v
		end
    end
	
    return target, true
end

local function KeepTargetFn(inst, target)
    return true
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude:HasTag("swilson") and not dude.components.health:IsDead() end, 5)
end

local function Normalize(inst)
	inst.components.combat:SetRange(2, 2)
	inst.rush = false
end

local function Rush(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:SetRange(0.5, 3)
		inst.rush = true
	end

	inst:DoTaskInTime(3, Normalize)
	inst:DoTaskInTime(7,Rush)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function fncommon(character, brainoverride, buildoverride)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.Transform:SetFourFaced(inst)

    MakeCharacterPhysics(inst, 10, .25)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild(buildoverride ~= nil and buildoverride or character)
	inst.AnimState:HideSymbol("face")
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("hat_hair")
    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
	
	inst.AnimState:AddOverrideBuild("waxwell_minion_spawn")
    inst.AnimState:AddOverrideBuild("waxwell_minion_appear")
    inst.AnimState:AddOverrideBuild("lavaarena_shadow_lunge")
    inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.AnimState:UsePointFiltering(true)

	inst.AnimState:PlayAnimation("idle")

    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("hat_hair")

    inst:AddTag("um_shadow_character")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadowchesspiece")
	inst:AddTag("shadowcreature")
	inst:AddTag("shadow_aligned")
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
    
    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 6
	inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor:SetSlowMultiplier(.6)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ character.."_vetskull" })
    
    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(500)
    inst.components.health.destroytime = 3
    inst.components.health.fire_damage_scale = TUNING.WILLOW_FIRE_DAMAGE
    ------------------

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetDefaultDamage(10)
    inst.components.combat:SetAttackPeriod(1)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetHurtSound("dontstarve/sanity/creature1/death")
    inst.components.combat:SetRange(2, 2)
    ------------------
	
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.penalty = TUNING.OLD_SHADOWWAXWELL_SANITY_PENALTY
    
    ------------------
	
    inst:ListenForEvent("attacked", OnAttacked)
	
	inst.charactertype = character
	
    ------------------

	local brain = require"brains/shadow_wixie"
	inst:SetBrain(brainoverride ~= nil and brainoverride or brain)

	inst:SetStateGraph("SGum_shadow_characters")

    ------------------
	--[[ AXE I COMMENTED OUT SHADOW WILSONS STUFF DONT HATE ME
	SpawnPrefab("maxwell_smoke")
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
    
    inst:SetStateGraph("SGswilson")
    inst:SetBrain(brain) 
	inst.rush = false
	inst:DoTaskInTime(7,Rush)
	]]
	
	inst:WatchWorldState("cycles", function() 
		if not inst.components.health:IsDead() then
			local x, y, z = inst.Transform:GetWorldPosition()
			SpawnPrefab("statue_transition").Transform:SetPosition(x, y, z)
			SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
			
			inst:Remove()
		end
	end)
	
	inst.persists = false
	
    return inst
end

--return Prefab( "swilson", fn, assets, prefabs)

local function WendyInit(inst)
	local abby = SpawnPrefab("um_shadow_abigail")
	abby.Transform:SetPosition(inst.Transform:GetWorldPosition())
	abby.components.follower.leader = inst
	inst.abigail = abby
end

local function OnWendyDeath(inst)
	if inst.abigail ~= nil then
		SpawnPrefab("statue_transition").Transform:SetPosition(inst.abigail.Transform:GetWorldPosition())
		SpawnPrefab("statue_transition_2").Transform:SetPosition(inst.abigail.Transform:GetWorldPosition())
		inst.abigail:Remove()
	end
end

local function RefeshShield(inst)
	--inst.components.um_shadowcloaked.shadowlevel = 20
		
	if inst.abigail ~= nil and inst.components.combat.target ~= nil then
		inst.abigail.components.combat:SetTarget(inst.components.combat.target)
	end
end

local function CommandAbby(inst)
	if inst.abigail ~= nil and inst.components.combat.target ~= nil then
		inst.abigail:SpeedBoost()
		inst.abigail.components.combat:SuggestTarget(inst.components.combat.target)
	end
end

local function WendyCloakAdded(inst)
	if inst.abigail ~= nil then
		inst.abigail.components.locomotor.walkspeed = TUNING.GHOST_SPEED * 1.2
		inst.abigail.components.locomotor.runspeed = TUNING.GHOST_SPEED * 1.2
	end
end

local function WendyCloakRemoved(inst)
	if inst.abigail ~= nil then
		inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED * 0.8
		inst.components.locomotor.runspeed = TUNING.GHOST_SPEED * 0.8
	end
end
	
local function wendy()
    local inst = fncommon("wendy")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 6
	
    inst.components.combat:SetAttackPeriod(12)
    inst.components.combat:SetRange(10)
	
	--[[inst:AddComponent("um_shadowcloaked")
	inst.components.um_shadowcloaked:SetOnCloakAdded(WendyCloakAdded)
	inst.components.um_shadowcloaked:SetOnCloakRemoved(WendyCloakRemoved)
	inst.components.um_shadowcloaked.cloakregen = false]]
	
	inst.RefeshShield = RefeshShield
	inst.CommandAbby = CommandAbby
	
	inst:DoTaskInTime(0, WendyInit)
    inst:ListenForEvent("death", OnWendyDeath)
    inst:ListenForEvent("removed", OnWendyDeath)

    return inst
end

local SINKHOLD_BLOCKER_TAGS = { "hound_lightning" }
local function DoSpell(inst, bookspellprefab)
	print(bookspellprefab)

	if bookspellprefab ~= nil then
		for i = 1, 5 do
			local x, y, z = inst.Transform:GetWorldPosition()
			
			if bookspellprefab == "hound_lightning" then
				inst:DoTaskInTime(i / 5, function()
					if inst.components.combat.target ~= nil then
						local posx, posy, posz = inst.components.combat.target.Transform:GetWorldPosition()
						local spellprefab = SpawnPrefab(bookspellprefab)
							
						if posx ~=  nil then
							local x = GetRandomWithVariance(posx, TUNING.ANTLION_SINKHOLE.RADIUS)
							local z = GetRandomWithVariance(posz, TUNING.ANTLION_SINKHOLE.RADIUS)

							local function IsValidSinkholePosition(offset)
								local x1, z1 = x + offset.x, z + offset.z
								if #TheSim:FindEntities(x1, 0, z1, TUNING.ANTLION_SINKHOLE.RADIUS * 1.9, SINKHOLD_BLOCKER_TAGS) > 0 then
									return false
								end
								return true
							end

							local offset = Vector3(0, 0, 0)
							offset =
								IsValidSinkholePosition(offset) and offset or
								FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 1.8 + math.random(), 9,
									IsValidSinkholePosition) or
								FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 2.9 + math.random(), 17,
									IsValidSinkholePosition) or
								FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 3.9 + math.random(), 17,
									IsValidSinkholePosition) or
								nil
									
									
							if offset ~= nil then
								spellprefab.MustTags = { "_health", "player" }
								spellprefab.shadowy = true
								spellprefab.sparks = "shadowhand_fx"
								spellprefab.Transform:SetPosition(x + offset.x, 0, z + offset.z)
							end
						end
					end
				end)
			end
			
			if bookspellprefab == "bigshadowtentacle" then
				local spellprefab = SpawnPrefab(bookspellprefab)
				spellprefab:PushEvent("arrive")
				spellprefab.Transform:SetPosition(x + math.random(-10, 10), 0, z + math.random(-10, 10))
			end
			
			if bookspellprefab == "um_shadow_canary" then
				local spellprefab = SpawnPrefab(bookspellprefab)
				spellprefab.Physics:Teleport(x + math.random(-10, 10), 15, z + math.random(-10, 10))

				if math.random() < .5 then
					spellprefab.Transform:SetRotation(180)
				end
			end
		end
	end
end

local function wickerbottom()
    local inst = fncommon("wickerbottom")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 6
	
    inst.components.combat:SetAttackPeriod(12)
    inst.components.combat:SetRange(6, 6)
	
	inst.DoSpell = DoSpell

    return inst
end

local COLLAPSIBLE_TAGS = { "player" }
local NON_COLLAPSIBLE_TAGS = { "playerghost" }

local easing = require("easing")

local function OnHitDumbell(inst, attacker, target)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 4.5, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            if v.components.combat ~= nil
                and v.components.health ~= nil
                and not v:HasTag("bearger")
                and not v.components.health:IsDead() then
                if v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, 30)
                end
            end
        end
    end
	
    inst.SoundEmitter:KillSound("spin_loop")
    inst.SoundEmitter:PlaySound("wolfgang1/dumbbell/stone_impact")
	
	local ring = SpawnPrefab("groundpoundring_fx")
	ring.Transform:SetPosition(x, 0, z)
	ring.Transform:SetScale(0.65, 0.65, 0.65)
	
    inst:Remove()
end

local function oncollide(inst, other)
	local x, y, z = inst.Transform:GetWorldPosition()
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("bearger_boulder") or y <= inst:GetPhysicsRadius() + 0.001 then
		OnHitDumbell(inst, other)
	end
end

local function OnThrownDumbell(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
    
    inst.SoundEmitter:PlaySound("wolfgang1/dumbbell/throw_twirl", "spin_loop")
	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst:SetPhysicsRadiusOverride(2.5)
	--inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)
	
    inst.Physics:SetCollisionCallback(oncollide)
end

local function dumbellfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("dumbbell")
    inst.AnimState:SetBuild("dumbbell")
    inst.AnimState:PlayAnimation("spin_loop", true)
    inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, .1, 0))
    inst.components.complexprojectile:SetOnLaunch(OnThrownDumbell)
    inst.components.complexprojectile:SetOnHit(OnHitDumbell)
    inst.components.complexprojectile.usehigharc = true

    inst.persists = false

	inst:DoTaskInTime(5, inst.Remove)

    return inst
end

local function Toss_Dumbell(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target

    if target ~= nil then
		local targetpos = target:GetPosition()
		
		if targetpos.x ~= nil then
			local projectile = SpawnPrefab("um_shadow_wolfgang_dumbell")
			projectile.Transform:SetPosition(x, 3, z)

			local dx = targetpos.x - x
			local dz = targetpos.z - z
			local rangesq = dx * dx + dz * dz
			local maxrange = TUNING.WATERPUMP.MAXRANGE
			local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
			projectile.components.complexprojectile:SetHorizontalSpeed(speed)
			projectile.components.complexprojectile:SetGravity(-25)
			projectile.components.complexprojectile:Launch(targetpos, inst, inst)
		end
    end
end

local function wolfgang()
    local inst = fncommon("wolfgang")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 8
	
    inst.components.combat:SetAttackPeriod(4)
    inst.components.combat:SetRange(6, 6)
	
	inst.wolfstate = "wimpy"
	inst.AnimState:SetBuild("wolfgang_skinny")

	inst.wolflift = 0

    inst.AnimState:OverrideSymbol("swap_object", "swap_dumbbell", "swap_dumbbell")
	inst.AnimState:Show("ARM_carry") 
	inst.AnimState:Hide("ARM_normal")

	inst.Toss_Dumbell = Toss_Dumbell
	
    return inst
end

local function StoryTime(inst)
end

local function walter()
    local inst = fncommon("walter", um_shadow_walter)
	
	inst:AddTag("um_shadow_walter")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 8
	
	--inst:SetBrain("fuelseekerbrain")
	
	inst:AddComponent("talker")
	
	inst.StoryTime = StoryTime

    return inst
end

local function MakeBalloon(inst)
	local balloon = SpawnPrefab("um_shadow_balloon")
	balloon.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function wes()
    local inst = fncommon("wes")
	
	inst:AddTag("um_shadow_wes")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 6
	
	inst.swes_balloon_count = 0
	
    inst.components.combat:SetAttackPeriod(8)
    inst.components.combat:SetRange(8, 8)
	
	inst.MakeBalloon = MakeBalloon

    return inst
end

local function wortox()
    local inst = fncommon("wortox", nil, "um_wortox_shadow")

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.AnimState:ShowSymbol("face")
	
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 8
	
    inst.components.combat:SetAttackPeriod(10)
    inst.components.combat:SetRange(8, 8)

    return inst
end

local function willow()
    local inst = fncommon("willow")

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function Toss_Food(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local target = TheSim:FindFirstEntityWithTag("um_shadow_warly_crockpot")

    if target ~= nil then
		local targetpos = target:GetPosition()
		
		if targetpos.x ~= nil then
			local projectile = SpawnPrefab("um_shadow_warly_food")
			projectile.Transform:SetPosition(x, 3, z)
			projectile.returntosender = true

			local dx = targetpos.x - x
			local dz = targetpos.z - z
			local rangesq = dx * dx + dz * dz
			local maxrange = TUNING.WATERPUMP.MAXRANGE
			local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
			projectile.components.complexprojectile:SetHorizontalSpeed(speed)
			projectile.components.complexprojectile:SetGravity(-25)
			projectile.components.complexprojectile:Launch(targetpos, inst, inst)
		end
    end
end

local function OnWarlyDeath(inst)
	local crockpot = TheSim:FindFirstEntityWithTag("um_shadow_warly_crockpot")
		
	if crockpot ~= nil then
		SpawnPrefab("statue_transition").Transform:SetPosition(crockpot.Transform:GetWorldPosition())
		SpawnPrefab("statue_transition_2").Transform:SetPosition(crockpot.Transform:GetWorldPosition())
		crockpot:Remove()
	end
end

local function warly()
    local inst = fncommon("warly", um_shadow_warly)
	
	inst:AddTag("um_shadow_warly")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 8
	
	inst.crockpot = nil
	
	inst:DoTaskInTime(1, function()
		local target = TheSim:FindFirstEntityWithTag("um_voxolophone")
		
		if target == nil then
			target = TheSim:FindFirstEntityWithTag("player")
		end
		
		if target ~= nil then
			local x, y, z = target.Transform:GetWorldPosition()
			SpawnPrefab("um_shadow_warly_crockpot").Transform:SetPosition(x + math.random(-5, 5), 0, z + math.random(-5, 5))
		end
	end)
	
    inst:ListenForEvent("death", OnWarlyDeath)
    inst:ListenForEvent("removed", OnWarlyDeath)
	
	inst.Toss_Food = Toss_Food
	
    return inst
end

local function winky()
    local inst = fncommon("winky")

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.AnimState:ShowSymbol("face")

    return inst
end

local function woodie()
    local inst = fncommon("woodie")

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.AnimState:ShowSymbol("face")

    inst.AnimState:OverrideSymbol("swap_object", "swap_lucy_axe", "swap_lucy_axe")
	inst.AnimState:Show("ARM_carry") 
	inst.AnimState:Hide("ARM_normal")

    return inst
end

local function wanda()
    local inst = fncommon("wanda")

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 6
	
    inst.components.combat:SetRange(3, 3)
	
    inst.AnimState:OverrideSymbol("swap_object", "pocketwatch_weapon", "swap_object")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")

    return inst
end

local function wandupe()
    local inst = fncommon("wanda")
	
    inst.AnimState:SetMultColour(0, 0, 0, .5)

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor.runspeed = 6
	
    inst.components.combat:SetRange(3, 3)
	
	inst.components.health:SetMaxHealth(1)
	
    owner.AnimState:OverrideSymbol("swap_object", "pocketwatch_weapon", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	
	inst.clone = true

    return inst
end

local function wathgrithr()
    local inst = fncommon("wathgrithr")

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function wormwood()
    local inst = fncommon("wormwood")

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local BALLOONS = require "prefabs/balloons_common"
local NUM_BALLOON_SHAPES = 9

local function SetBalloonShape(inst, num)
    inst.balloon_num = num
    inst.AnimState:OverrideSymbol("swap_balloon", "balloon_shapes2", "balloon_"..tostring(num))
end

local function DeactiveBalloon(inst)
    RemovePhysicsColliders(inst)
	inst:AddTag("notarget")
    inst:AddTag("NOCLICK")
end

local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost" }
local function doareaattack(inst, remove)
    inst.components.combat:DoAreaAttack(inst, TUNING.BALLOON_ATTACK_RANGE, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
	if remove then
		inst:Remove()
	end
end

local function DoPop_Floating(inst)
	DeactiveBalloon(inst)

	inst.AnimState:PlayAnimation("pop")
	inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")

	local time_mult = 0.7 + math.random() * 0.4
	inst.AnimState:SetDeltaTimeMultiplier(time_mult)

	local attack_delay = (.1 + math.random() * .2)*time_mult
	inst:DoTaskInTime(attack_delay, doareaattack)

	local remove_delay = math.max(attack_delay, inst.AnimState:GetCurrentAnimationLength() * time_mult) + FRAMES
	inst:DoTaskInTime(remove_delay, inst.Remove)
end

local function WalkToPlayer(inst)
	local target = inst:GetNearestPlayer(true)
	
	if target ~= nil then
		inst.components.locomotor:GoToEntity(target)
	end
	
	local x, y, z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x, y, z, 3, { "player" }, { "playerghost" })
	
	if players ~= nil and #players > 0 then
		DoPop_Floating(inst)
	end
end

local function shadow_balloon()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	BALLOONS.MakeFloatingBallonPhysics(inst)

    inst.AnimState:SetBank("balloon2")
    inst.AnimState:SetBuild("balloon2")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.AnimState:UsePointFiltering(true)

    inst.DynamicShadow:SetSize(1, .5)

    inst:AddTag("nopunch")
    inst:AddTag("cattoyairborne")
    inst:AddTag("balloon")
    inst:AddTag("noepicmusic")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.GHOST_SPEED * 1.2
    inst.components.locomotor.runspeed = TUNING.GHOST_SPEED * 1.2
    inst.components.locomotor.pathcaps = { allowocean = true, ignorecreep = true }
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.directdrive = true

	inst.balloon_build = "balloon_shapes2"

    inst.AnimState:SetTime(math.random() * 2)

	SetBalloonShape(inst, math.random(NUM_BALLOON_SHAPES))

    BALLOONS.SetRopeShape(inst)

	--inst.colour_idx = BALLOONS.SetColour(inst)
	
	inst:DoPeriodicTask(.5, WalkToPlayer)
	
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.BALLOON_DAMAGE)
	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1)
    inst.components.health.nofadeout = true
	
    inst:ListenForEvent("death", DoPop_Floating)
	inst:DoTaskInTime(6, DoPop_Floating)
	
	inst.persists = false

    return inst
end


local function EXPLODE(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x, y, z, 8, { "player" }, { "playerghost" })
	
	if inst.scaletask ~= nil then
		inst.scaletask:Cancel()
	end
		
	inst.scaletask = nil
	
    for i, v in ipairs(players) do
        if v:IsValid() then
            if v.components.combat ~= nil
                and v.components.health ~= nil
                and not v.components.health:IsDead() then
                if v.components.combat:CanBeAttacked() then
                    v.components.combat:GetAttacked(inst, 30)
                end
            end
        end
    end
end

local function ScaleUp(inst)
	inst.incscale = inst.incscale + FRAMES
	inst.Transform:SetScale(inst.incscale, inst.incscale, inst.incscale)
end

local function StartExplodeTimer(inst)
	if inst.glidetask ~= nil then
		inst.glidetask:Cancel()
	end
		
	inst.glidetask = nil
		
	inst.AnimState:PlayAnimation("struggle_explode")
	
	if inst.scaletask == nil then
		inst.scaletask = inst:DoPeriodicTask(FRAMES, ScaleUp)
	end
		
	inst:ListenForEvent("animover", inst.Remove)
	inst:DoTaskInTime(1.65, EXPLODE)
end

local function ExplodeCheck(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x, y, z, 3, { "player" }, { "playerghost" })
	
	if players ~= nil and #players > 0 and inst.glidetask ~= nil then
		StartExplodeTimer(inst)
	end
end

local function ForceExplode(inst)
	if inst.glidetask ~= nil then
		StartExplodeTimer(inst)
	end
end

local function ShadowCanaryInit(inst)
	inst.AnimState:PlayAnimation("glide", true)
	inst.Physics:SetMotorVel(0, math.random() * 10 - 20, 0)
	
	inst.glidetask = inst:DoPeriodicTask(FRAMES, function()
		local x, y, z = inst.Transform:GetWorldPosition()
	
		if y < 2 then
			inst.Physics:SetMotorVel(0, 0, 0)
		end
		
		if y <= 0.1 then
			inst.Physics:Stop()
			inst.Physics:Teleport(x, 0, z)
			inst.AnimState:PlayAnimation("struggle_land2", false)
			
			if inst.glidetask ~= nil then
				inst.glidetask:Cancel()
			end
			
			inst.glidetask = inst:DoPeriodicTask(.33, ExplodeCheck, 1.25)
			inst:DoTaskInTime(5, ForceExplode)
		end
	end)
end

local function shadow_canary()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddPhysics()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
    inst.AnimState:SetMultColour(0, 0, 0, .6)
	inst.AnimState:UsePointFiltering(true)
	
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:SetMass(1)
	inst.Physics:SetSphere(1)
	
	inst:AddTag("fx")

	inst.Transform:SetTwoFaced()
	
	inst.AnimState:SetBank("canary")
	inst.AnimState:SetBuild("canary_build")
	inst.AnimState:PlayAnimation("idle")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.incscale = 1
	
	inst:DoTaskInTime(0, ShadowCanaryInit)
	
	inst.persists = false

    return inst
end

local function CrockPotHit(inst)
	if inst.launching then
		inst.AnimState:PlayAnimation("hit_cooking")
		inst.AnimState:PushAnimation("cooking_loop", true)
	--[[elseif inst.components.stewer:IsDone() then
		inst.AnimState:PlayAnimation("hit_full")
		inst.AnimState:PushAnimation("idle_full", false)]]
	else
		inst.AnimState:PlayAnimation("hit_empty")
		inst.AnimState:PushAnimation("idle_empty", false)
	end
end

local easing = require("easing")

local function LaunchFoodProjectile(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst:GetNearestPlayer(true)
	local targetpos = nil
	local shadow_warly = TheSim:FindFirstEntityWithTag("um_shadow_warly")
	
	if math.random() > 0.8 and shadow_warly then 
		targetpos = shadow_warly:GetPosition()
	elseif target ~= nil then
		targetpos = target:GetPosition()
	end
	
	
	if targetpos ~= nil and targetpos.x ~= nil then
		local projectile = SpawnPrefab("um_shadow_warly_food")
		projectile.Transform:SetPosition(x, 3, z)
			
		targetpos.x = targetpos.x + math.random(-2, 2)
		targetpos.z = targetpos.z + math.random(-2, 2)

		local dx = targetpos.x - x
		local dz = targetpos.z - z
		local rangesq = dx * dx + dz * dz
		local maxrange = TUNING.WATERPUMP.MAXRANGE
		local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
		projectile.components.complexprojectile:SetHorizontalSpeed(speed)
		projectile.components.complexprojectile:SetGravity(-25)
		projectile.components.complexprojectile:Launch(targetpos, inst, inst)
	end
end

local function StartLaunching(inst)
	for i = 1, inst.ingredients do
		inst:DoTaskInTime(.33 * i, function()
			inst.AnimState:PlayAnimation("cooking_pst")
			inst.AnimState:PushAnimation("idle_full", false)
			inst.SoundEmitter:KillSound("snd")
			inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
			inst.ingredients = inst.ingredients - 1
			LaunchFoodProjectile(inst)
			
			if i <= 0 then
				inst.SoundEmitter:KillSound("snd")
				inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_open")
				inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot", "snd")
				inst.launching = false
			end
		end)
    end
	
	if inst.forcethrow ~= nil then
		inst.forcethrow:Cancel()
		inst.forcethrow = nil
	end
	
	inst.forcethrow = inst:DoTaskInTime(30, function()
		inst.ingredients = 10
		inst.StartCooking(inst)
	end)
end

local function StartCooking(inst)
	
	inst.launching = true
	inst.AnimState:PlayAnimation("cooking_loop", true)
	inst.SoundEmitter:KillSound("snd")
	inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
	
	inst:DoTaskInTime(5, StartLaunching)
end

local function AddIngredient(inst)
	inst.SoundEmitter:PlaySound("dontstarve/common/together/portable/cookpot/place")
	inst.ingredients = inst.ingredients + 1
	inst.AnimState:PlayAnimation("hit_empty")
	inst.AnimState:PushAnimation("idle_empty", false)
	
	if inst.ingredients >= 10 then
		StartCooking(inst)
	end
end

local function crockpotfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
	
	inst:AddTag("um_shadow_warly_crockpot")

    inst.AnimState:SetBank("portable_cook_pot")
    inst.AnimState:SetBuild("portable_cook_pot")
	inst.AnimState:PlayAnimation("place")
	inst.AnimState:PushAnimation("idle_empty", false)
    inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	

	inst.launching = false
	inst.ingredients = 10
	inst.AddIngredient = AddIngredient
	inst.StartCooking = StartCooking
	inst.persists = false
	
	inst:DoTaskInTime(0, function()
		inst.SoundEmitter:PlaySound("dontstarve/common/together/portable/cookpot/place")
	end)
	
	inst:DoTaskInTime(0, StartCooking)
	
	--inst:DoPeriodicTask(1, AddIngredient)
	
	inst:ListenForEvent("attacked", CrockPotHit)

    return inst
end

local function DoFoodProjectileHit(inst, other)
    local caster = (inst._caster ~= nil and inst._caster:IsValid()) and inst._caster or nil
	local x, y, z = inst.Transform:GetWorldPosition()
	
	if inst.returntosender then
		local target = TheSim:FindFirstEntityWithTag("um_shadow_warly_crockpot")
		if target ~= nil then
			target.AddIngredient(target)
		end
	else
		local others = TheSim:FindEntities(x,y,z, 3,{ "_combat", "player" }, { "INLIMBO", "shadow","minotaur" }) --I messed around with the funni goo, its range is actually a bit small, so I bumped it up a tad.
		for i,other in ipairs(others) do
			if other ~= nil and other ~= caster and other.components.combat ~= nil  then
				if other.components.sanity ~= nil and other.components.health ~= nil and not other.components.health:IsDead() and other.components.sanity:IsInsane() and other.components.inkable and not other:HasTag("shadowdominant") then
					other.components.inkable:Ink()
					other.components.combat:GetAttacked(caster, TUNING.WARG_GOO_DAMAGE/2)
				elseif other.components.sanity ~= nil and not other:HasTag("shadowdominant") then
					other.components.sanity:DoDelta(-5)
				end
			end
		end
	
		SpawnPrefab("ink_splash").Transform:SetPosition(x, 0, z)
		local food = SpawnPrefab("um_shadow_warly_food")
		food.Transform:SetPosition(x, 0, z)
		food:AddTag("um_shadow_warly_food")
	end
	
    inst:Remove()
end

local function OnFoodCollide(inst, other)
	local x, y, z = inst.Transform:GetWorldPosition()
	if other ~= nil and other:IsValid() and other:HasTag("_combat") and not other:HasTag("um_shadow_warly_projectile") or y <= inst:GetPhysicsRadius() + 0.001 then
		DoFoodProjectileHit(inst, other)
	end
end

local function OnThrownFood(inst)
    inst:AddTag("NOCLICK")
    inst.persists = false
	
    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst:SetPhysicsRadiusOverride(2.5)
	--inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:SetCapsule(1.5, 1.5)
	
	inst.AnimState:SetBank("squid_watershoot")
	inst.AnimState:SetBuild("squid_watershoot")
	inst.AnimState:PlayAnimation("spin_loop",true)
	
    inst.Physics:SetCollisionCallback(OnFoodCollide)
end

local function warly_food()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()
	
	local rando = math.random()
	if rando > 0.66 then
		inst.AnimState:SetBank("monstermeat")
		inst.AnimState:SetBuild("meat_monster")
		inst.AnimState:PlayAnimation("idle")
	elseif rando <= 0.66 and rando > 0.33 then
		inst.AnimState:SetBank("carrot")
		inst.AnimState:SetBuild("carrot")
		inst.AnimState:PlayAnimation("idle")
	else
		inst.AnimState:SetBank("durian")
		inst.AnimState:SetBuild("durian")
		inst.AnimState:PlayAnimation("idle")
	end
	
	inst.AnimState:SetMultColour(0, 0, 0, 0.6)
	
	inst:AddTag("um_shadow_warly_projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.returntosender = false
	
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-20)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0, .1, 0))
    inst.components.complexprojectile:SetOnLaunch(OnThrownFood)
    inst.components.complexprojectile:SetOnHit(DoFoodProjectileHit)
    inst.components.complexprojectile.usehigharc = true
	
	inst:DoTaskInTime(30, function()
		local x, y, z = inst.Transform:GetWorldPosition()
		SpawnPrefab("statue_transition").Transform:SetPosition(x, y, z)
		SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
			
		inst:Remove()
	end)
	
	return inst
end

return Prefab( "um_shadow_wendy", wendy, assets, prefabs),
		Prefab( "um_shadow_wickerbottom", wickerbottom, assets, prefabs),
		Prefab( "um_shadow_wolfgang", wolfgang, assets, prefabs),
		Prefab( "um_shadow_walter", walter, assets, prefabs),
		Prefab( "um_shadow_wes", wes, assets, prefabs),
		Prefab( "um_shadow_wortox", wortox, assets, prefabs),
		Prefab( "um_shadow_willow", willow, assets, prefabs),
		Prefab( "um_shadow_warly", warly, assets, prefabs),
		Prefab( "um_shadow_winky", winky, assets, prefabs),
		Prefab( "um_shadow_woodie", woodie, assets, prefabs),
		Prefab( "um_shadow_wanda", wanda, assets, prefabs),
		Prefab( "um_shadow_wathgrithr", wathgrithr, assets, prefabs),
		Prefab( "um_shadow_wormwood", wormwood, assets, prefabs),
		
		Prefab( "um_shadow_wolfgang_dumbell", dumbellfn, assets, prefabs),
		Prefab( "um_shadow_balloon", shadow_balloon, assets, prefabs),
		Prefab( "um_shadow_canary", shadow_canary, assets, prefabs),
		Prefab( "um_shadow_warly_crockpot", crockpotfn, assets, prefabs),
		Prefab( "um_shadow_warly_food", warly_food, assets, prefabs)
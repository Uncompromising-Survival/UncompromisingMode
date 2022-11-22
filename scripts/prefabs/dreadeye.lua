local prefabs =
{
    "nightmarefuel",
}

local assets =
{
    Asset("ANIM", "anim/dreadeye.zip"), -----------------------------------------
}

local shadowrock_assets =
{
    Asset("ANIM", "anim/rock.zip"),
    Asset("MINIMAP_IMAGE", "rock"),
}

local shadowtree_assets =
{
    Asset("ANIM", "anim/evergreen_new.zip"), --build
    Asset("ANIM", "anim/evergreen_new_2.zip"), --build
    Asset("ANIM", "anim/evergreen_tall_old.zip"),
    Asset("ANIM", "anim/evergreen_short_normal.zip"),

    Asset("SOUND", "sound/forest.fsb"),
    Asset("MINIMAP_IMAGE", "evergreen_lumpy"),

    Asset("MINIMAP_IMAGE", "evergreen_burnt"),
    Asset("MINIMAP_IMAGE", "evergreen_stump"),
}

local shadowgrass_assets =
{
    Asset("ANIM", "anim/grass.zip"),
    Asset("ANIM", "anim/grass1.zip"),
    Asset("ANIM", "anim/grass_diseased_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local shadowsapling_assets =
{
    Asset("ANIM", "anim/sapling.zip"),
    Asset("ANIM", "anim/sapling_diseased_build.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local sounds =
{
    attack = "dontstarve/sanity/creature1/attack",
    attack_grunt = "dontstarve/sanity/creature2/attack_grunt",
    death = "dontstarve/sanity/creature2/die",
    idle = "dontstarve/sanity/creature2/idle",
    taunt = "dontstarve/sanity/creature2/taunt",
    appear = "dontstarve/sanity/creature2/appear",
    disappear = "dontstarve/sanity/creature2/dissappear",
}

local brain = require("brains/dreadeyebrain") -----------------------------------------

--local original_tile_type = TheWorld.Map:GetTileAtPoint(pt:Get())
--local function dreadeyetimer(inst)
--inst.disguise_cd = inst.disguise_cd - 1
--end

local NOTAGS = { "playerghost", "INLIMBO" }

local function retargetfn(inst)
    local maxrangesq = TUNING.SHADOWCREATURE_TARGET_DIST * TUNING.SHADOWCREATURE_TARGET_DIST
    local rangesq, rangesq1, rangesq2 = maxrangesq, math.huge, math.huge
    local target1, target2 = nil, nil
    for i, v in ipairs(AllPlayers) do
        if v.components.sanity:IsInsane() and not v:HasTag("playerghost") and not v:HasTag("notarget_shadow") then
            local distsq = v:GetDistanceSqToInst(inst)
            if distsq < rangesq then
                if inst.components.shadowsubmissive:TargetHasDominance(v) then
                    if distsq < rangesq1 and inst.components.combat:CanTarget(v) then
                        target1 = v
                        rangesq1 = distsq
                        rangesq = math.max(rangesq1, rangesq2)
                    end
                elseif distsq < rangesq2 and inst.components.combat:CanTarget(v) then
                    target2 = v
                    rangesq2 = distsq
                    rangesq = math.max(rangesq1, rangesq2)
                end
            end
        end
    end

    if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
        --Targets with shadow dominance have higher priority within half targeting range
        --Force target switch if current target does not have shadow dominance
        return target1, not inst.components.shadowsubmissive:TargetHasDominance(inst.components.combat.target)
    end
    return target2
end

local function NotifyBrainOfTarget(inst, target)
    if inst.brain ~= nil and inst.brain.SetTarget ~= nil then
        inst.brain:SetTarget(target)
    end
end

local function onkilledbyother(inst, attacker)
    if attacker ~= nil and attacker.components.sanity ~= nil then
		inst.sanityreward = 20
		
        attacker.components.sanity:DoDelta(inst.sanityreward)
		
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 15, { "player" }, { "playerghost" } )
		
		if inst.sanityreward ~= nil then
			inst.halfreward = inst.sanityreward / 2
		end
		
		if inst.sanityreward ~= nil then
			inst.quarterreward = inst.sanityreward / 4
		end
		
		for i, v in ipairs(ents) do
			if v ~= attacker and v.components.sanity ~= nil then
				if v.components.sanity:IsInsane() then
					v.components.sanity:DoDelta(inst.halfreward)
				else
					v.components.sanity:DoDelta(inst.quarterreward)
				end
			end
		end
    end
end

local function CalcSanityAura(inst, observer)
    return inst.components.combat:HasTarget()
        and observer.components.sanity:IsCrazy()
        and -TUNING.SANITYAURA_LARGE
        or 0
end

local function ShareTargetFn(dude)
    return dude:HasTag("shadowcreature") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, 30, ShareTargetFn, 1)
end

local function OnNewCombatTarget(inst, data)
    NotifyBrainOfTarget(inst, data.target)
end

local function OnDeath(inst, data)
    if data ~= nil and data.afflicter ~= nil and data.afflicter:HasTag("crazy") then
        --max one nightmarefuel if killed by a crazy NPC (e.g. Bernie)
        inst.components.lootdropper:SetLoot({ "nightmarefuel" })
        inst.components.lootdropper:SetChanceLootTable(nil)
    end
end

local function ShadowSuprise(inst)
	if inst.isdisguised and not inst.components.health:IsDead() then 
		inst.sg:GoToState("disguise_attack")
		inst.isdisguised = false
		
		if inst.suprise_task ~= nil then
			inst.suprise_task:Cancel()
			inst.suprise_task = nil
		end
		
		if inst.shadoweye_task ~= nil then
			inst.shadoweye_task:Cancel()
			inst.shadoweye_task = nil
		end
		
		--inst.components.health:DoDelta(100)
		
		if inst.disguiseprefab ~= nil then
			local px, py, pz = inst.disguiseprefab.Transform:GetWorldPosition()
			SpawnPrefab("mini_dreadeye_fx").Transform:SetPosition(px, py, pz)
			--inst.SoundEmitter:PlaySound("dontstarve/maxwell/disappear")
			inst.disguiseprefab:Remove()
			inst.disguiseprefab = nil
		end
	end
end

local function TryEyeSpawn(v)

	local x1, y1, z1 = v.Transform:GetWorldPosition()
	if x1 ~= nil and z1 ~= nil and v.components.sanity and v.components.sanity:IsInsane() then
		SpawnPrefab("mini_dreadeye").Transform:SetPosition(v.Transform:GetWorldPosition())
		--SpawnPrefab("mini_dreadeye").Transform:SetPosition(x1 + math.random(-5,5), 0, z1 + math.random(-5,5))
	end
	
end

local function ShadowEyeSpawn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 50, nil, NOTAGS, { "player" })
	
	for i, v in ipairs(ents) do
        TryEyeSpawn(v)
    end
end

local function Disguise(inst)
	if not inst.components.health:IsDead() then
		inst.isdisguised = true
	
		local disguise = SpawnPrefab("dreadeye_disguise")
		disguise.Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst.disguiseprefab = disguise
		disguise.host = inst
		
		if inst.suprise_task ~= nil then
			inst.suprise_task:Cancel()
			inst.suprise_task = nil
		end
		
		inst.suprise_task = inst:DoTaskInTime(20, ShadowSuprise)
		
		if inst.shadoweye_task ~= nil then
			inst.shadoweye_task:Cancel()
			inst.shadoweye_task = nil
		end
		
		if inst.components.combat:HasTarget() then
			inst.shadoweye_task = inst:DoPeriodicTask(4, ShadowEyeSpawn)
		end
	end
end

local function TryDisguise(inst, target)
	inst.disguisetarget = target
	inst.sg:GoToState("disguise_pre")
	--Disguise(inst)
end

local function onnear(inst, target)
	if inst.oncooldown == nil then
		if inst.isdisguised and not inst.components.health:IsDead() then
			if target ~= nil and target.components.sanity ~= nil and target.components.sanity:GetPercent() <= .7 then
				print("disguse attack")
				inst.sg:GoToState("disguise_attack")
				inst.isdisguised = false
				
				if inst.suprise_task ~= nil then
					inst.suprise_task:Cancel()
					inst.suprise_task = nil
				end
				
				if inst.shadoweye_task ~= nil then
					inst.shadoweye_task:Cancel()
					inst.shadoweye_task = nil
				end
				
				if target ~= nil then
					
					target:PushEvent("spooked", { source = inst })
						
					if not IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and target.components.sanity ~= nil and target.components.sanity:IsSane() then
						target.components.sanity:DoDelta(-10)
					end
					
					SpawnPrefab("mini_dreadeye_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
				end
				
				if inst.disguiseprefab ~= nil then
					inst.disguiseprefab:Remove()
					inst.disguiseprefab = nil
				end
			end
		elseif not inst.isdisguised and not inst.components.health:IsDead() and not inst.components.combat:HasTarget() then	
			if target ~= nil and target.components.sanity ~= nil and target.components.sanity:GetPercent() <= .7 and target.components.sanity:GetPercent() > .2 then
				TryDisguise(inst, target)
			else
				inst.sg:GoToState("teleport_to")
			end
		end
	end
end

local function onfar(inst, target)
	if inst.oncooldown == nil then
		if not inst.isdisguised and not inst.components.health:IsDead() and not inst.components.combat:HasTarget() then	
			TryDisguise(inst, target)
		end
	end
end

local function OnEntitySleep(inst)
	inst.sg:GoToState("disguise_attack")
end

local function OnSave(inst, data)
    data.atkcount = inst.atkcount or nil
end

local function OnPreLoad(inst, data)
    if data ~= nil then
        if data.atkcount then
            inst.atkcount = data.atkcount
        end
    end
end

local function CLIENT_ShadowSubmissive_HostileToPlayerTest(inst, player)
	if player:HasTag("shadowdominance") then
		return false
	end
	local combat = inst.replica.combat
	if combat ~= nil and combat:GetTarget() == player then
		return true
	end
	local sanity = player.replica.sanity
	if sanity ~= nil and sanity:IsCrazy() then
		return true
	end
	return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 3, 0.5)
    RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)

    --inst.Transform:SetScale(1.12, 1.12, 1.12)
    --inst.Transform:SetFourFaced()

    inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")

	--shadowsubmissive (from shadowsubmissive component) added to pristine state for optimization
	inst:AddTag("shadowsubmissive")
	
	inst.suprise_task = nil

    inst.AnimState:SetBank("dreadeye")
    inst.AnimState:SetBuild("dreadeye")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(1, 1, 1, .5)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    --inst:AddComponent("transparentonsanity_dreadeye")
    if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity_dreadeye")
		inst.components.transparentonsanity_dreadeye:ForceUpdate()
	end

	inst.HostileToPlayerTest = CLIENT_ShadowSubmissive_HostileToPlayerTest

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	
	inst.isdisguised = false
    inst.atkcount = 3
    --inst.disguise_form = nil
    --inst.disguise_cd = -1

    inst:AddComponent("uncompromising_shadowfollower")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = TUNING.DSTU.DREADEYE_SPEED
    --inst.components.locomotor.pathcaps = { allowocean = true }
    inst.components.locomotor.pathcaps = { ignorecreep = true }
	inst.components.locomotor:SetTriggersCreep(false)
    inst.sounds = sounds
    inst:SetStateGraph("SGdreadeye")

    inst:SetBrain(brain)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    inst:AddComponent("health")
    inst.components.health.nofadeout = true
	
	inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 5) --set specific values
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onnear)
    inst.components.playerprox:SetPlayerAliveMode(inst.components.playerprox.AliveModes.AliveOnly)
	
    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(TUNING.DSTU.DREADEYE_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.DSTU.DREADEYE_RANGE_1, TUNING.DSTU.DREADEYE_RANGE_2)
    inst.components.combat.onkilledbyother = onkilledbyother
    inst.components.combat:SetRetargetFunction(3, retargetfn)

    inst.components.health:SetMaxHealth(TUNING.DSTU.DREADEYE_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.DSTU.DREADEYE_DAMAGE)

    inst:AddComponent("shadowsubmissive")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({ "nightmarefuel" })

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
    inst:ListenForEvent("death", OnDeath)

	inst.Disguise = Disguise
	
    --inst.OnEntitySleep = OnEntitySleep

    --inst.OnSave = OnSave
    --inst.OnPreLoad = OnPreLoad

    --inst:DoPeriodicTask(FRAMES, function() dreadeyetimer(inst) end)

    inst.persists = false

    return inst
end


local disguises =
{
	{
		name = "rock1",
		bank = "rock",
		build = "rock",
		anim = "full",
	},
	{
		name = "rock2",
		bank = "rock2",
		build = "rock2",
		anim = "full",
	},
	{
		name = "reeds",
		bank = "grass",
		build = "reeds",
		anim = "idle",
	},
	{
		name = "marsh_tree",
		bank = "marsh_tree",
		build = "tree_marsh",
		anim = "swap_1_loop",
	},
	{
		name = "rock_flintless",
		bank = "rock_flintless",
		build = "rock_flintless",
		anim = "full",
	},
	{
		name = "evergreen",
		bank = "evergreen_short",
		build = "evergreen_new",
		anim = "idle_normal",
	},
	{
		name = "grass",
		bank = "grass",
		build = "grass1",
		anim = "idle",
	},
	{
		name = "sapling",
		bank = "sapling",
		build = "sapling",
		anim = "sway",
	},
	{
		name = "deciduoustree",
		bank = "tree_leaf",
		build = "tree_leaf_trunk_build",
		anim = "idle_tall",
	},
	{
		name = "berrybush",
		bank = "berrybush",
		build = "berrybush",
		anim = "idle",
	},
	{
		name = "carrot_planted",
		bank = "carrot",
		build = "carrot",
		anim = "planted",
	},
}


local function shadowdisguise_fn(bank, build, anim, icon, tag, multcolour)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeSnowCoveredPristine(inst)

    inst:AddComponent("transparentonsanity_dreadeye_objects")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:DoTaskInTime(0, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 15)
		local disguisechoice = math.random(#disguises)
		for i, v in ipairs(disguises) do
		
			for n, b in ipairs(ents) do
				if v.name == b.prefab then
					inst.AnimState:SetBank(v.bank)
					inst.AnimState:SetBuild(v.build)
					
					if v.name == "deciduoustree" then
						if not TheWorld.state.iswinter then
							if TheWorld.state.isautumn then
								inst.AnimState:OverrideSymbol("swap_leaves", "tree_leaf_orange_build", "swap_leaves")
							else
								inst.AnimState:OverrideSymbol("swap_leaves", "tree_leaf_green_build", "swap_leaves")
							end
						end
							
						inst.color = .5 + math.random() * .5
						inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
					end
					
					inst.AnimState:PlayAnimation(v.anim, true)
					break
				end
			end
			
			if i == disguisechoice then
				inst.AnimState:SetBank(v.bank)
				inst.AnimState:SetBuild(v.build)
					
				if v.name == "deciduoustree" then
					if not TheWorld.state.iswinter then
						if TheWorld.state.isautumn then
							inst.AnimState:OverrideSymbol("swap_leaves", "tree_leaf_orange_build", "swap_leaves")
						else
							inst.AnimState:OverrideSymbol("swap_leaves", "tree_leaf_green_build", "swap_leaves")
						end
					end
						
					inst.color = .5 + math.random() * .5
					inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
				end
				
				inst.AnimState:PlayAnimation(v.anim)
			end
		end
	end)
	
	inst.persists = false
	
    return inst
end
	
return Prefab("dreadeye", fn, assets),
		Prefab("dreadeye_disguise", shadowdisguise_fn)
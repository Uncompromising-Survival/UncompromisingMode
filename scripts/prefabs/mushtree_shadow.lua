local function dig_up_stump(inst)
    inst.components.lootdropper:SpawnLootPrefab("log")
    inst:Remove()
end

local function inspect_tree(inst)
    return (inst:HasTag("stump") and "CHOPPED")
        or nil
end

local data =
{
    shadow =
    {
        bank = "gloomcap",
        build = "gloomcap",
        icon = "gloomcap.tex",
        lightradius = 1.25,
        lightcolour = { 227/255, 0/255, 0/255 },
    },
}

local function onsave(inst, data)
    data.stump = inst:HasTag("stump") or nil
	data.scale = inst.scale
end

local function swapbuild(inst, build)
    inst._changetask = nil
    if not inst:HasTag("stump") then
        inst.AnimState:SetBuild(build)
    end
end

local function startchange(inst, build, soundname)
    if inst:HasTag("stump") then
        inst._changetask = nil
    else
        inst.AnimState:PlayAnimation("change")
        inst.AnimState:PushAnimation("idle_loop", true)
        inst.SoundEmitter:PlaySound(soundname)
        inst._changetask = inst:DoTaskInTime(14 * FRAMES, swapbuild, build)
    end
end

local function workcallback(inst, worker, workleft)
    if not (worker ~= nil and worker:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_mushroom")
    end
    if workleft > 0 then
        inst.AnimState:PlayAnimation("chop")
        inst.AnimState:PushAnimation("idle_loop", true)

    end
    --V2C: different anims are played in workfinishcallback if workleft <= 0
end

local function maketree(name, data, state)

	local function onspawnfn(inst, spawn)
    inst.AnimState:PlayAnimation("cough")
    inst.AnimState:PushAnimation("idle_loop", true)

    inst.SoundEmitter:PlaySound("dontstarve/cave/mushtree_tall_spore_fart")

    local pos = inst:GetPosition()
    local radius = spawn:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + 0.75
    local offset = FindWalkableOffset(pos, math.random() * TWOPI, radius, 8)

    if offset ~= nil then
        pos = pos + offset
    end

    spawn.Transform:SetPosition(pos.x, 0, pos.z)
	end
	
	local function ontimerdone(inst, data)
		if data.name == "regrow" then
			inst.AnimState:PlayAnimation("regrow")
			inst.AnimState:PushAnimation("idle_loop")
			inst.normal_tree(inst, true)
		end
	end
	
    local function makestump(inst)
		if inst.components.sanityaura then
			inst:RemoveComponent("sanityaura")
		end
        if inst._changetask ~= nil then
            inst._changetask:Cancel()
            inst._changetask = nil
        end

        RemovePhysicsColliders(inst)

        inst:AddTag("stump")
        inst:RemoveTag("shelter")

        inst:RemoveComponent("propagator")
		inst.components.raindome:SetRadius(0)
        MakeSmallPropagator(inst)

        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetOnWorkCallback(nil)
        inst.components.workable:SetOnFinishCallback(dig_up_stump)
        inst.components.workable:SetWorkLeft(1)

        inst.AnimState:PlayAnimation("idle_stump")

        inst.MiniMapEntity:SetIcon("mushroom_tree_stump.png")

        inst.Light:Enable(false)

        inst:ListenForEvent("timerdone", ontimerdone)

        if not inst.components.timer:TimerExists("regrow") then
            inst.components.timer:StartTimer("regrow", math.random(1,2)*1/2*60*80*15)
        end
		if inst.components.periodicspawner then
			inst:RemoveComponent("periodicspawner")
		end
		inst:StopWatchingWorldState("nightmarephase",inst.SporeTask)
	end
	local function workfinishcallback(inst,other)
		inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
		makestump(inst)
		if other.components.sanity ~= nil and other.components.health ~= nil and not other.components.health:IsDead() and other.components.inkable then
			other.components.inkable:Ink()
			other.components.sanity:DoDelta(-5)
		elseif other.components.sanity ~= nil then
			other.components.sanity:DoDelta(-5)
		end
		inst.AnimState:PlayAnimation("fall")
		inst.AnimState:PushAnimation("idle_stump")

		inst.components.lootdropper:DropLoot(inst:GetPosition())
	end
	
    local function normal_tree(inst, instant)
		inst:AddComponent("sanityaura")
		inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
        if inst._changetask ~= nil then
            inst._changetask:Cancel()
        end
		if inst:HasTag("stump") then
			inst:RemoveTag("stump")
		end
		
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetWorkLeft(5)
        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot({
            "log",
            "gloomcap",
        })
        inst.components.workable:SetOnWorkCallback(workcallback)
        inst.components.workable:SetOnFinishCallback(workfinishcallback)
		inst.Light:Enable(true)
		inst.components.raindome:SetRadius(TUNING.VOIDCLOTH_UMBRELLA_DOME_RADIUS)
        if instant then
            swapbuild(inst, data.build)
        else
            inst._changetask = inst:DoTaskInTime(math.random() * 3 * TUNING.SEG_TIME, startchange, data.build, "dontstarve/cave/mushtree_tall_shrink")
        end
		
        inst:AddComponent("periodicspawner")
        inst.components.periodicspawner:SetPrefab("spore_shadow")
        inst.components.periodicspawner:SetOnSpawnFn(onspawnfn)
        inst.components.periodicspawner:SetDensityInRange(TUNING.MUSHSPORE_MAX_DENSITY_RAD, TUNING.MUSHSPORE_MAX_DENSITY)
        inst.components.periodicspawner:Stop()
		
		inst:WatchWorldState("nightmarephase",inst.SporeTask)
    end



	local function onload(inst, loaddata)
		if loaddata ~= nil then
			if loaddata.stump then
				makestump(inst)
			else
				normal_tree(inst, true)
			end
			if loaddata.scale then
				inst.scale = loaddata.scale
			end
		end
	end
	


    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .25)

        inst.AnimState:SetBuild(data.build)
        inst.AnimState:SetBank(data.bank)
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.scrapbook_anim = "idle_loop"

        inst.MiniMapEntity:SetIcon(data.icon)

        inst.Light:SetFalloff(.5)
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(data.lightradius)
        inst.Light:SetColour(unpack(data.lightcolour))

        inst:AddTag("cavedweller")
        inst:AddTag("mushtree")
        inst:AddTag("plant")
        inst:AddTag("shelter")
        inst:AddTag("tree")
		
		inst:AddComponent("raindome")
		
        inst:SetPrefabName(name)

        inst.entity:SetPristine()
		
		
        if not TheWorld.ismastersim then
            return inst
        end

        inst.scrapbook_specialinfo = "TREE"

        local color = .5 + math.random() * .5
        inst.AnimState:SetMultColour(color, color, color, 1)
		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

        MakeMediumPropagator(inst)

	

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree


		inst.normal_tree = normal_tree

        inst:AddComponent("timer")
		
		
		inst.SporeTask = function(inst,phase,instant)
			if phase == "calm" then
				inst.components.periodicspawner:Stop()
			elseif phase == "warn" or phase == "dawn" then
				inst.components.periodicspawner:Start(math.random(10,30))
			elseif phase == "wild" then
				inst.components.periodicspawner:Start(math.random(5,10))
			end		
		end

        MakeHauntableIgnite(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload
		inst:DoTaskInTime(0,function(inst)
			if not inst.scale then
				inst.scale = math.random(10,17)/10
			end
			inst.Transform:SetScale(inst.scale,inst.scale,inst.scale)
		end)
        if state == "stump" then
            makestump(inst)
        else
            normal_tree(inst, true)
        end

        return inst
    end
end

local treeprefabs = {}
function treeset(name, data, build_file_name)
    local buildasset = Asset("ANIM", build_file_name)
    local assets =
    {
        buildasset,
		Asset("IMAGE", "images/map_icons/gloomcap.tex"),
		Asset("ATLAS", "images/map_icons/gloomcap.xml"),
        Asset("MINIMAP_IMAGE", data.icon),
        Asset("MINIMAP_IMAGE", "mushroom_tree_stump"),
    }

    local prefabs =
    {
        data.spore,
        name.."_stump",
        "ash",
        "charcoal",
        "log",
        "small_puff",
    }

    table.insert(treeprefabs, Prefab(name, maketree(name, data), assets, prefabs))
    table.insert(treeprefabs, Prefab(name.."_stump", maketree(name, data, "stump"), assets, prefabs))
end

require "tuning"

local assetsregular =
{
	Asset("ANIM", "anim/gloomcap_item.zip"),
	Asset("ATLAS", "images/inventoryimages/gloomcap.xml"),
	Asset("IMAGE", "images/inventoryimages/gloomcap.tex"),
}

local assets_cooked =
{
	Asset("ANIM", "anim/gloomcap_item.zip"),
	Asset("ATLAS", "images/inventoryimages/gloomcap_cooked.xml"),
	Asset("IMAGE", "images/inventoryimages/gloomcap_cooked.tex"),
}


local easing = require("easing")

local function SpawnMushroomBombProjectile(inst,targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("mushroombomb_projectile")
    projectile.Transform:SetPosition(x, y, z)
    projectile.components.entitytracker:TrackEntity("toadstool", inst)

    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.

    local dx = targetpos.x 
    local dz = targetpos.z 
	targetpos.x = targetpos.x + x
	targetpos.z = targetpos.z + z
    local rangesq = dx * dx + dz * dz
    local maxrange = 15
    local bigNum = 10 -- 13 + (math.random()*4)
    local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange)
    projectile.components.complexprojectile:SetHorizontalSpeed(speed)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end

local function oneatenregular(inst, eater)
	if eater.components.skilltreeupdater and eater.components.skilltreeupdater:IsActivated("wormwood_moon_cap_eating") then

		-- Launch 4 Boomshrooms
		local targetpos = Vector3(3,0,3)
		SpawnMushroomBombProjectile(inst,targetpos)
		targetpos = Vector3(-3,0,3)
		SpawnMushroomBombProjectile(inst,targetpos)		
		targetpos = Vector3(-3,0,-3)
		SpawnMushroomBombProjectile(inst,targetpos)	
		targetpos = Vector3(3,0,-3)
		SpawnMushroomBombProjectile(inst,targetpos)			
		
		eater.components.sanity:DoDelta(50)
	end
end
			
local function fnregular()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("gloomcap_item")
	inst.AnimState:SetBuild("gloomcap_item")
	inst.AnimState:PlayAnimation("idle")
	MakeInventoryFloatable(inst, "med", 0.05, 0.68)
	--cookable (from cookable component) added to pristine state for optimization
	inst:AddTag("cookable")
    inst:AddTag("mushroom")	
	inst:AddTag("mushroom_fuel")
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	

	inst:AddComponent("edible")
	inst.components.edible.healthvalue = -20
	inst.components.edible.hungervalue = 18.8
	inst.components.edible.sanityvalue = -50
	inst.components.edible.foodtype = FOODTYPE.VEGGIE
	
	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime((3*TUNING.PERISH_TWO_DAY))
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"
	inst.components.edible:SetOnEatenFn(oneatenregular)
	
	inst:AddComponent("stackable")

	inst:AddComponent("inspectable")
	
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/gloomcap.xml"


	MakeSmallPropagator(inst)
    ---------------------        

    inst:AddComponent("bait")

    ------------------------------------------------
    inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 0
    ------------------------------------------------  

    inst:AddComponent("cookable")
    inst.components.cookable.product = "gloomcap_cooked"
	
    return inst
end

local function oneatenfncooked(inst, eater)
    if eater:HasTag("player") then
        if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and not (eater.components.health ~= nil and eater.components.health:IsDead()) and not eater:HasTag("playerghost") then
            eater.components.debuffable:AddDebuff("buff_smallcourage", "buff_smallcourage")
			eater.components.debuffable:AddDebuff("healingsalve_acidbuff", "healingsalve_acidbuff")
        end
		
    end
end

local function fn_cooked()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("gloomcap")
	inst.AnimState:SetBuild("gloomcap")
	inst.AnimState:PlayAnimation("cooked")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime((4*TUNING.PERISH_TWO_DAY))
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	inst:AddComponent("edible")
	inst.components.edible.healthvalue = -3
	inst.components.edible.hungervalue = 18.8
	inst.components.edible.sanityvalue = -10
	inst.components.edible.foodtype = FOODTYPE.VEGGIE
	inst.components.edible:SetOnEatenFn(oneatenfncooked)
	
	inst:AddComponent("stackable")

	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/gloomcap_cooked.xml"


	MakeSmallPropagator(inst)
	---------------------        

	inst:AddComponent("bait")

	------------------------------------------------
	inst:AddComponent("tradable")

	inst.components.tradable.goldvalue = 0
	MakeHauntableLaunchAndPerish(inst)

	return inst
end


local function stop_testing(inst)
    if inst._prox_task ~= nil then
        inst._prox_task:Cancel()
        inst._prox_task = nil
    end
end

local function depleted(inst)
    if inst:IsInLimbo() then
        inst:Remove()
    else
        stop_testing(inst)

        inst:AddTag("NOCLICK")
        inst.persists = false

        inst.components.workable:SetWorkable(false)
        inst:PushEvent("pop")

        inst:RemoveTag("spore") -- so crowding no longer detects it

        -- clean up when offscreen, because the death event is handled by the SG
        inst:DoTaskInTime(3, inst.Remove)
    end
end

local function onworked(inst, worker)
    inst:PushEvent("pop")
    inst:RemoveTag("spore")
end

local SPORE_TAGS = {"spore"}
local function checkforcrowding(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spores = TheSim:FindEntities(x,y,z, TUNING.MUSHSPORE_MAX_DENSITY_RAD, SPORE_TAGS)
    if #spores > TUNING.MUSHSPORE_MAX_DENSITY then
        inst.components.perishable:SetPercent(0)
    else
        inst.crowdingtask = inst:DoTaskInTime(TUNING.MUSHSPORE_DENSITY_CHECK_TIME + math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)
    end
end

local AREAATTACK_EXCLUDETAGS = { "spore", "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "shadow", "brightmare", "moon_spore_protection" }
local function onpopped(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
    inst.components.combat:DoAreaAttack(inst, TUNING.MOONSPORE_ATTACK_RANGE, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
end

local function onload(inst)
    -- If we loaded, then just turn the light on
    inst.Light:Enable(true)
    inst.DynamicShadow:Enable(true)
end

local PROXIMITY_MUSTHAVE = { "_combat" }
local PROXIMITY_ONEOF = { "player", "monster", "character" }
local function do_proximity_test(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local target = FindEntity(inst, TUNING.MOONSPORE_ATTACK_PROXIMITY, nil, PROXIMITY_MUSTHAVE, AREAATTACK_EXCLUDETAGS, PROXIMITY_ONEOF)

    if target ~= nil then
        stop_testing(inst)
        if inst._alwaysinstantpops then
            inst:PushEvent("pop")
        else
            inst:PushEvent("preparedpop")
        end
    end
end

local function spore_entity_sleep(inst)
    do_proximity_test(inst)
    stop_testing(inst)
end

local PROXIMITY_TEST_TIME = 15 * FRAMES
local function schedule_testing(inst)
    stop_testing(inst)
    inst._prox_task = inst:DoPeriodicTask(PROXIMITY_TEST_TIME, do_proximity_test)
end

local function spore_entity_wake(inst)
    schedule_testing(inst)
    do_proximity_test(inst)
end

local function OnHitOther(inst,data)
	local other = data.target
	if other and other.components.sanity then
		other.components.sanity:DoDelta(-15)
	end
end

local COLOUR_R, COLOUR_G, COLOUR_B = 0/255, 0/255, 0/255
local ZERO_VEC = Vector3(0,0,0)
local function fnspore()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("mushroom_spore_moon")
    inst.AnimState:SetBank("spore_moon")
    inst.AnimState:PlayAnimation("idle_flight_loop", true)

    inst.DynamicShadow:Enable(false)

    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetRadius(0.5)
    inst.Light:Enable(false)

    inst.DynamicShadow:SetSize(.8, .5)

    inst:AddTag("spore")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.AnimState:SetMultColour(0.4, 0, 0, 0.6)
    inst.scrapbook_anim = "idle_flight_loop"
    inst.scrapbook_animoffsety = 65
    inst.scrapbook_animpercent = 0.36

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.MOONSPORE_PERISH_TIME)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(depleted)

    inst:AddComponent("stackable")

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(1)
    inst.components.burnable:SetBurnTime(1)
    inst.components.burnable:AddBurnFX("fire", ZERO_VEC, "spore_body")
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)


    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(1)
	inst:ListenForEvent("onhitother", OnHitOther)
    MakeHauntablePerish(inst, .5)

    inst:ListenForEvent("popped", onpopped)

    inst:SetStateGraph("SGmoonspore")

    -- note: the first check is faster, because this might be from dropping a stack
    inst.crowdingtask = inst:DoTaskInTime(1 + math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)

    inst.OnLoad = onload
    inst.OnEntitySleep = spore_entity_sleep
    inst.OnEntityWake = spore_entity_wake

    inst:DoTaskInTime(0, schedule_testing)

    return inst
end



treeset("mushtree_shadow", data.shadow, "anim/gloomcap.zip")

return unpack(treeprefabs),
Prefab("gloomcap", fnregular, assetsregular),
		Prefab("gloomcap_cooked", fn_cooked, assets_cooked),
		Prefab("spore_shadow", fnspore)

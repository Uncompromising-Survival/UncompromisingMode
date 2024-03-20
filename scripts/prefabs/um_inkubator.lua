require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/compostingbin.zip"),
    Asset("MINIMAP_IMAGE", "compostingbin"),
}

local prefabs =
{
    "collapse_small",
    "compost",
    "poopcloud",
}

local DONT_ACCEPT_FOODTYPES =
{
    [FOODTYPE.ELEMENTAL] = true,
    [FOODTYPE.GEARS] = true,
    [FOODTYPE.INSECT] = true,
    [FOODTYPE.BURNT] = true,
}

local sounds =
{
    place = "farming/common/farm/compost/place",
    loop = "farming/common/farm/compost/LP",
    spin = "farming/common/farm/compost/spin",
    finish_compost = "farming/common/farm/compost/fertalizer",
    door = "farming/common/farm/compost/use",
}

local WETDRYBALANCE_TO_INDEX =
{
    DRY = 1,
    BALANCED = 2,
    WET = 3,
}

local DURATION_MULTIPLIER =
{
    FAST = 0.7,
    MEDIUM = 0.85,
    SLOW = 1,
}

local EXPERIMENTS =
{
    {
		result = "bat",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "monstermeat",
		binding = "batwing",
		binding_2 = "guano",
		timer = 30,
	},
    {
		result = "hound",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "houndstooth",
		timer = 60,
	},
    {
		result = "firehound",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "redgem",
		timer = 60,
	},
    {
		result = "icehound",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "bluegem",
		timer = 60,
	},
    {
		result = "lightninghound",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "goldnugget",
		timer = 60,
	},
    {
		result = "sporehound",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "shroom_skin_fragment",
		timer = 60,
	},
    {
		result = "houndcorpse",
		fuel = "moonglass",
		flesh = "monstermeat",
		binding = "houndstooth",
		timer = 60,
	},
    {
		result = "merm",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "pondfish",
		binding = "frogleg",
		timer = 60,
	},
    {
		result = "squid",
		fuel = "moonglass",
		flesh = "monstermeat",
		binding = "lightbulb",
		timer = 30,
	},
    {
		result = "slurper",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "lightbulb",
		timer = 30,
	},
    {
		result = "mushgnome",
		fuel = "moonglass",
		flesh = "moon_cap",
		binding = "livinglog",
		timer = 60,
	},
    {
		result = "molebat",
		fuel = "moonglass",
		flesh = "monstermeat",
		binding = "batnose",
		timer = 60,
	},
    {
		result = "penguin",
		fuel = "nightmarefuel",
		flesh = "drumstick",
		binding = "feather_crow",
		timer = 60,
	},
    {
		result = "mutated_penguin",
		fuel = "moonglass",
		flesh = "drumstick",
		binding = "feather_crow",
		timer = 60,
	},
    {
		result = "werepig",
		fuel = "moonglass",
		flesh = "meat",
		binding = "pigskin",
		timer = 60,
	},
    {
		result = "pigman",
		fuel = "nightmarefuel",
		flesh = "meat",
		binding = "pigskin",
		timer = 60,
	},
    {
		result = "rabbit",
		fuel = "nightmarefuel",
		flesh = "smallmeat",
		binding = "any",
		timer = 60,
	},
    {
		result = "rocky",
		fuel = "nightmarefuel",
		flesh = "meat",
		binding = "wobster_sheller_land",
		timer = 60,
	},
    {
		result = "rocky",
		fuel = "moonglass",
		flesh = "meat",
		binding = "wobster_sheller_land",
		timer = 60,
	},
    {
		result = "slurtle",
		fuel = "nightmarefuel",
		flesh = "slurtleslime",
		binding = "slurtle_shellpieces",
		timer = 60,
	},
    {
		result = "snurtle",
		fuel = "moonglass",
		flesh = "slurtleslime",
		binding = "slurtle_shellpieces",
		timer = 60,
	},
    {
		result = "monkey",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "smallmeat",
		binding = "cave_banana",
		timer = 30,
	},
    {
		result = "spider",
		fuel = "nightmarefuel",
		flesh = "monstersmallmeat",
		binding = "spidergland",
		binding_2 = "silk",
		timer = 30,
	},
    {
		result = "spider_warrior",
		fuel = "nightmarefuel",
		flesh = "monstermeat",
		binding = "spidergland",
		binding_2 = "silk",
		timer = 60,
	},
    {
		result = "spider_moon",
		fuel = "moonglass",
		flesh = "monstermeat",
		binding = "spidergland",
		binding_2 = "silk",
		timer = 60,
	},
    {
		result = "fruitdragon",
		fuel = "moonglass",
		flesh = "plantmeat",
		binding = "dragonfruit",
		timer = 60,
	},
    {
		result = "snapdragon",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "plantmeat",
		binding = "Pale_vomit",
		timer = 60,
	},
    {
		result = "smallbird",
		fuel = "moonglass",
		flesh = "smallmeat",
		binding = "tallbirdegg",
		timer = 30,
	},
    {
		result = "teenbird",
		fuel = "moonglass",
		flesh = "meat",
		binding = "tallbirdegg",
		timer = 60,
	},
    {
		result = "catcoon",
		fuel = "nightmarefuel",
		flesh = "meat",
		binding = "coontail",
		timer = 60,
	},
    {
		result = "aphid",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "monstersmallmeat",
		binding = "steelwool",
		timer = 60,
	},
    {
		result = "fruitbat",
		fuel = "moonglass",
		flesh = "giant_blueberry",
		binding = "batwing",
		timer = 60,
	},
    {
		result = "buzzard",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "smallmeat",
		binding = "feather_crow",
		timer = 60,
	},
    {
		result = "mole",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "smallmeat",
		binding = "rocks",
		timer = 60,
	},
    {
		result = "lightninggoat",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "goatmilk",
		binding_2 = "lightninggoathorn",
		timer = 60,
	},
    {
		result = "bunnyman",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "manrabbit_tail",
		timer = 60,
	},
    {
		result = "worm",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "monstermeat",
		binding = "wormlight",
		timer = 60,
	},
    {
		result = "spat",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "phlegm",
		binding_2 = "steelwool",
		timer = 60,
	},
    {
		result = "frog",
		fuel = "nightmarefuel",
		flesh = "froglegs",
		binding = "froglegs",
		timer = 30,
	},
    {
		result = "lunarfrog",
		fuel = "moonglass",
		flesh = "froglegs",
		binding = "froglegs",
		timer = 30,
	},
    {
		result = "perd",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "drumstick",
		binding = "berries",
		binding_2 = "berries_juicy",
		timer = 60,
	},
    {
		result = "koalefant_summer",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "trunk_summer",
		timer = 60,
	},
    {
		result = "koalefant_winter",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "trunk_winter",
		timer = 60,
	},
    {
		result = "beefalo",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "horn",
		binding_2 = "beefalowool",
		timer = 60,
	},
    {
		result = "babybeefalo",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "meat",
		binding = "beefalowool",
		timer = 60,
	},
    {
		result = "dustmoth",
		fuel = "nightmarefuel",
		fuel_2 = "moonglass",
		flesh = "smallmeat",
		binding = "dustmeringue",
		timer = 60,
	},
    {
		result = "nightmarebeak",
		fuel = "nightmarefuel",
		flesh = "skeletonmeat",
		binding = "any",
		timer = 30,
	},
    {
		result = "gestalt",
		fuel = "moonglass",
		flesh = "skeletonmeat",
		binding = "any",
		timer = 30,
	},
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
	
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if not inst.AnimState:IsCurrentAnimation("spin") and not inst.AnimState:IsCurrentAnimation("place") then
            inst.AnimState:PlayAnimation("hit")
            if inst.components.timer:TimerExists("create_creature") then
                inst.AnimState:PushAnimation("working_nospin", false)
            else
                inst.AnimState:PushAnimation("idle", false)
            end
        end
    end
end

local function getstatus(inst)
    if inst.components.timer:TimerExists("create_creature") then
        return "CREATING"
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound(sounds.place)
end

local function animqueueover(inst)
    if inst.components.timer:TimerExists("create_creature") then
        inst.AnimState:PlayAnimation("working", false)
        inst.SoundEmitter:PlaySound(sounds.spin)

        local materialcount = inst.components.compostingbin:GetMaterialTotal()
        if materialcount < 5 then
            inst.AnimState:PushAnimation("working_nospin", false)
            if materialcount < 3 then
                inst.AnimState:PushAnimation("working_nospin", false)
            end
        end
    end
end

local function OnEntitySleep(inst)
    if inst.components.timer:TimerExists("create_creature") then
        inst.SoundEmitter:KillSound("lp")
    end
end

local function OnEntityWake(inst)
    if inst.components.timer:TimerExists("create_creature") then
        inst.SoundEmitter:PlaySound(sounds.loop, "lp")
    end
end

local function onsave(inst, data)
	data.creating_creature = inst.creating_creature
	data.creature_created = inst.creature_created
	data.experiment_result = inst.experiment_result
end

local function onload(inst, data)
    if data ~= nil then
		inst.creating_creature = data.creating_creature
		inst.creature_created = data.creature_created
		inst.experiment_result = data.experiment_result
		
		if inst.creating_creature then
			inst.components.container:Close()
			inst.components.container.canbeopened = false
			inst.AnimState:PushAnimation("working_nospin", true)
			inst.SoundEmitter:PlaySound(sounds.loop, "lp")
		end
    end
end

local function onopen(inst)
	inst.SoundEmitter:PlaySound(sounds.door)
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound(sounds.door)
end

local function OnCooldown(inst)
    inst._cdtask = nil
end

local function DoPuff(inst, channeler)
	if inst._cdtask == nil and inst.components.container ~= nil and not inst.creating_creature then
		if inst.creature_created then
			inst.components.container.canbeopened = true
			
			inst.SoundEmitter:PlaySound("dontstarve/sanity/creature"..math.random(2).."/idle")
			
			inst.creating_creature = false
			inst.creature_created = false
			
			local x, y, z = inst.Transform:GetWorldPosition()
			local creature = SpawnPrefab(inst.experiment_result)
			creature.Transform:SetPosition(x, y, z)

			local fx1 = SpawnPrefab("ink_splash")
			fx1.Transform:SetPosition(x, y, z)

			local fx2 = SpawnPrefab("washashore_puddle_fx")
			fx2.Transform:SetPosition(x, y, z)

			if fx2.AnimState ~= nil then
				fx2.AnimState:SetMultColour(0, 0, 0, 1)
			end
			
			creature._inkubator_count = 0
			if creature.AnimState ~= nil then
				creature.AnimState:SetMultColour(1, 1, 1, creature._inkubator_count)
			end
				
			creature._inkubator_task = creature:DoPeriodicTask(.1, function()
				creature._inkubator_count = creature._inkubator_count + .1
				
				if creature.AnimState ~= nil then
					creature.AnimState:SetMultColour(creature._inkubator_count, creature._inkubator_count, creature._inkubator_count, 1)
				end
				
				if creature._inkubator_count >= 1 then
					if creature._inkubator_task ~= nil then
						creature._inkubator_task:Cancel()
						creature._inkubator_task = nil
					end
				end
			end)
			
			if creature.components.sleeper ~= nil then
				creature.components.sleeper:AddSleepiness(500, 10)
			end
			
			inst.experiment_result = nil
		else
			local slot1 = inst.components.container:GetItemInSlot(1) ~= nil and inst.components.container:GetItemInSlot(1).prefab
			local slot2 = inst.components.container:GetItemInSlot(2) ~= nil and inst.components.container:GetItemInSlot(2).prefab
			local slot3 = inst.components.container:GetItemInSlot(3) ~= nil and inst.components.container:GetItemInSlot(3).prefab
			
			inst._cdtask = inst:DoTaskInTime(1, OnCooldown)
				
			if slot1 ~= nil and slot2 ~= nil and slot3 ~= nil then
				inst.components.container:Close()
				inst.components.container.canbeopened = false
			
				inst.AnimState:PlayAnimation("use")
				
				local final_result = "wetgoop"
				local final_time = 10
			
				for i, v in pairs(EXPERIMENTS) do
					if slot1 and slot1 == v.fuel or slot1 and slot1 == v.fuel_2 then
						if slot2 and slot2 == v.flesh then
							if slot3 and v.binding == "any" or slot3 and slot3 == v.binding or slot3 and slot3 == v.binding_2 then
								final_result = v.result
								final_time = v.timer
								
								break
							end
						end
					end
				end
				
				inst.creating_creature = true
				inst.experiment_result = final_result
				inst.components.timer:StartTimer("create_creature", final_time)
				inst.AnimState:PushAnimation("working_nospin", true)
				inst.SoundEmitter:PlaySound(sounds.loop, "lp")
			end
		end
	end
	
	inst.components.channelable:StopChanneling(true)
end

local function ontimerdone(inst, data)
    if data ~= nil and data.name == "create_creature" then
		inst.components.container:DestroyContents()
		inst.SoundEmitter:KillSound("lp")
		inst.creating_creature = false
		inst.creature_created = true
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
		inst.SoundEmitter:PlaySound(sounds.finish_compost)
    end
end

local function OnStopChanneling(inst)
	if inst.channeler ~= nil then
		--inst.channeler.sg:GoToState("idle")
	end
	inst.channeler = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("compostingbin.png")

    inst:AddTag("structure")

    inst.AnimState:SetBank("compostingbin")
    inst.AnimState:SetBuild("compostingbin")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.creating_creature = false
	inst.creature_created = false
	inst.experiment_result = nil
		
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("timer")
	
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
	
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("um_inkubator")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose
	
    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(DoPuff, OnStopChanneling)
    inst.components.channelable.use_channel_longaction_noloop = true
    inst.components.channelable.skip_state_channeling = true

    MakeSnowCovered(inst)
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("timerdone", ontimerdone)

    --inst:ListenForEvent("animqueueover", animqueueover)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

return Prefab("um_inkubator", fn, assets, prefabs),
    MakePlacer("um_inkubator_placer", "compostingbin", "compostingbin", "placer")
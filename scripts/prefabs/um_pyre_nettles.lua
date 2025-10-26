local plant_maxhealth = 300
local spore_cooldown_max = 60

local HOME_TILES = {
    [WORLD_TILES.UM_MAGMA] = true,
    [WORLD_TILES.UM_GRASSMAGMA] = true,
}

if WORLD_TILES.MAGMA_ASH then
    HOME_TILES[WORLD_TILES.MAGMA_ASH] = true --IA compat teehee
    HOME_TILES[WORLD_TILES.MAGMA_ROCK] = true
    HOLE_TILES[WORLD_TILES.MAGMAFIELD] = true
end

SetSharedLootTable('um_pyre_nettles_1',
    {
        { 'firenettles', 1.0 }
    })
SetSharedLootTable('um_pyre_nettles_2',
    {
        { 'firenettles', 0.75 }
    })
SetSharedLootTable('um_pyre_nettles_3',
    {
        { 'firenettles', 0.75 },
        { 'firenettles', 0.25 }
    })
SetSharedLootTable('um_pyre_nettles_4',
    {
        { 'firenettles', 1.0 },
        { 'firenettles', 1.0 },
        { 'firenettles', 0.75 },
        { 'firenettles', 0.25 }
    })
SetSharedLootTable('um_pyre_nettles_5',
    {
        { 'firenettles', 1.0 },
        { 'firenettles', 1.0 },
        { 'firenettles', 0.75 },
        { 'firenettles', 0.5 },
        { 'firenettles', 0.25 }
    })

local function TrySpawnSpore(inst)
    if not inst:IsAsleep() then
        SpawnPrefab("um_smolder_spore").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function ScheduledSpore(inst)
	inst.AnimState:PlayAnimation("pn"..inst.stage.."_coof", false)
	inst.AnimState:PushAnimation("pn"..inst.stage.."_idle", true)		
	TrySpawnSpore(inst)
	if inst.sporetask then
		inst.sporetask:Cancel()
		inst.sporetask = nil
	end
	if not inst:IsAsleep() then
		inst.sporetask = inst:DoTaskInTime(math.random(60,120),ScheduledSpore)
	end
end

local function StartSpores(inst)
	if inst.stage > 3 then
		inst.sporetask = inst:DoTaskInTime(math.random(5,15),ScheduledSpore)
	end
end

local function StopSpores(inst)
	if inst.sporetask then
		inst.sporetask:Cancel()
		inst.sporetask = nil
	end
end

local function pyrenettle_bumped(inst,nextvictim)
    if nextvictim:IsValid() then 
        inst.AnimState:PlayAnimation("pn" .. inst.stage .. "_bump", false)
        inst.AnimState:PushAnimation("pn" .. inst.stage .. "_idle", true)
		if inst.stage ~= 1 then
			inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
		end

        -- Apply debuff if it's a valid target.
        if not (nextvictim.components.health and nextvictim.components.health:IsDead()) and inst.stage > 1 then
            local DebuffDuration = inst.stage > 3 and 10 or 6
            nextvictim:AddDebuff("umdebuff_pyre_toxin", "umdebuff_pyre_toxin", DebuffDuration)
        end
    end
end
-- Timer reset for small nettle growth.
local function SmallPyreNettleGrowthTimerReset(inst,cancel)
    local time_remaining = inst.components.timer:GetTimeLeft("SmallPyreNettleGrowthTimer")
    local timer_duration = math.random(8,12)/10 * 480
	if inst.stage > 2 then
		timer_duration = timer_duration * 3
	end
	if cancel and time_remaining then
		inst.components.timer:StopTimer("SmallPyreNettleGrowthTimer")
	end
    if inst.stage < inst.target_stage then
		inst.components.timer:StartTimer("SmallPyreNettleGrowthTimer", timer_duration)
    end
end
-- This sets up the plant's stage-unique traits.
local function SetStage(inst)
    -- Remove and then add a tag to identify current stage, for spawning checks.
    for i = 1, 5 do
        inst:RemoveTag("PyreNettle" .. i)
    end
    inst:AddTag("PyreNettle" .. inst.stage)

    -- Safety mechanisms, in case we're at an invalid stage (loading shenanigans probably).
    if inst.stage > 5 then
        print("um_pyre_nettles.lua has auto-recovered from an invalid SetStage! Stage was: " .. inst.stage)
        inst.stage = 5
    elseif inst.stage < 1 then
        print("um_pyre_nettles.lua has auto-recovered from an invalid SetStage! Stage was: " .. inst.stage)
        inst:Remove()
    end

    -- Anim selector.
    inst.AnimState:PushAnimation("pn" .. inst.stage .. "_idle", true)

    --[[if not TheWorld.ismastersim then
        return
    end]] -- uncomment if this actually does something.

    -- Loot selector.
    inst.components.lootdropper:SetChanceLootTable("um_pyre_nettles_" .. inst.stage)

    inst.components.pickable.remove_when_picked = inst.stage == 1 or false

    -- Flammability stage properties.
    inst.components.burnable:SetFXLevel(inst.stage > 3 and 3 or 2)
    local multsize = 0.5 + (math.random() * 0.2)
    if inst.stage ~= 1 then
        multsize = 0.75 + (math.random() * 0.2)
        inst.components.pickable.canbepicked = true
    end
    inst.AnimState:SetScale(math.random() < .5 and -multsize or multsize, multsize, multsize)
end

local function QueueSetStage(inst)
	SetStage(inst)
	inst:RemoveEventCallback("animover",QueueSetStage)
end

local function OnGrow(inst)
    local targetstage = inst.stage and math.clamp(inst.stage + 1, 1, 6) or 1
	inst.AnimState:PlayAnimation("pn" .. inst.stage .. "_grow", false)
	inst.stage = targetstage
	inst:ListenForEvent("animover", QueueSetStage)
	if inst.stage < inst.target_stage then
		SmallPyreNettleGrowthTimerReset(inst)
	end
	if inst.stage > 3 and not inst:IsAsleep() and not inst.sporetask then
		inst.sporetask = inst:DoTaskInTime(math.random(10,20),ScheduledSpore) -- Cough sooner if we just grew
	end
end

local function OnPicked(inst)
    local targetstage = math.clamp(inst.stage - 1, 1, 5)
    inst.AnimState:PlayAnimation("pn" .. inst.stage .. "_shrink", false)
    inst.stage = targetstage
	SmallPyreNettleGrowthTimerReset(inst,true)
	inst:ListenForEvent("animover", QueueSetStage)
	StopSpores(inst)	
end

-- Make the plant destroyable instantly with explosives, dropping the current stage's loot and all below it.
local function OnExplosion(inst)
    for i = 1, inst.stage do
        inst.components.lootdropper:SetChanceLootTable("um_pyre_nettles_" .. i)
        inst.components.lootdropper:DropLoot(inst:GetPosition())
    end

    if inst.stage == 4 or inst.stage == 5 then
        for i = 1, math.random(2, 5) do
            TrySpawnSpore(inst)
        end
    end

    inst:DoTaskInTime(0, function() inst:Remove() end)
end

local function OnTimerDone(inst, data)
    --print("timerdone", data.name)
    if data.name == "SmallPyreNettleGrowthTimer" then	
        OnGrow(inst)
    end
end

local function OnSave(inst, data)
    if inst.stage then
        data.stage = inst.stage
		data.target_stage = inst.target_stage
    end
end

local function OnLoad(inst, data)
    if data and data.stage then
        inst.stage = data.stage
		inst.target_stage = data.target_stage
    end

    SetStage(inst)
end

local function StageSpawner(name, SpawnAtStage)
    local SpawnAtStage = SpawnAtStage

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        --inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.prefab = "um_pyre_nettles" -- In case we're a spawned-in stage-specifying prefab.

        -- Stage setting
        if not inst.stage then
            inst.stage = SpawnAtStage
			inst.target_stage = math.random(3,5)
        end

        inst.AnimState:SetBank("um_pyre_nettles")
        inst.AnimState:SetBuild("um_pyre_nettles")

        local multcolor = 0.85 + (math.random() * 0.15)
        inst.AnimState:SetMultColour(multcolor, multcolor, multcolor, 1)

        -- UM tags
        inst:AddTag("PyreNettle")
        inst:AddTag("PyreToxinImmune")
        inst:AddTag("SmolderSporeAvoid")
        inst:AddTag("snowpileblocker") -- SNOOOOOWWWW BLOCKERRRRRR
        -- Vanilla tags
        inst:AddTag("plant")
        inst:AddTag("scarytoprey")
        inst:AddTag("thorny")

        inst:SetDeployExtraSpacing(1)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --inst:DoPeriodicTask(1 --[[(30 * math.random()) + 30]], OnGrow, 2)

        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst:AddComponent("pickable")
        inst.components.pickable:SetUp(nil)
        inst.components.pickable.use_lootdropper_for_product = true
        inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
        inst.components.pickable.onpickedfn = OnPicked
		if inst.stage ~= 1 then
			inst.components.pickable.canbepicked = true
		end

        inst:AddComponent("combat")

        inst:ListenForEvent("explosion", OnExplosion)

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnPicked)

        inst:AddComponent("burnable")
        inst.components.burnable:AddBurnFX("character_fire", Vector3(0, 0, 0))
        inst.components.burnable:SetBurnTime(6)
		
        MakeSmallPropagator(inst)

        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", OnTimerDone)

        --inst:DoTaskInTime(0, WorldCheck)
        inst:DoTaskInTime(0, SetStage)
		
		inst.pyrenettle_bumped = pyrenettle_bumped
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad

		inst:ListenForEvent("entitywake", StartSpores)
		inst:ListenForEvent("entitysleep", StopSpores)
        return inst
    end

    return Prefab(name, fn)
end

local pyre_nettle_prefabs = {}
for i = 1, 5 do
    table.insert(pyre_nettle_prefabs, StageSpawner("um_pyre_nettles_stage_" .. i, i))
end
table.insert(pyre_nettle_prefabs, StageSpawner("um_pyre_nettles", math.random(2,5)))

return unpack(pyre_nettle_prefabs)
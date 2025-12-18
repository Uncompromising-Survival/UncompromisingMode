local assets =
{
    Asset("ANIM", "anim/um_hotspring.zip")
}

local function SpawnPlants(inst, plantname, count, maxradius)
    if inst.decor then
        for i, item in ipairs(inst.decor) do
            item:Remove()
        end
    end
    inst.decor = {}

    local plant_offsets = {}

    for i = 1, math.random(math.ceil(count / 2), count) do
        local a = math.random() * math.pi * 2
        local x = math.sin(a) * maxradius + math.random() * 0.2
        local z = math.cos(a) * maxradius + math.random() * 0.2
        table.insert(plant_offsets, { x, 0, z })
    end

    for k, offset in pairs(plant_offsets) do
        local plant = SpawnPrefab(plantname)
        plant.entity:SetParent(inst.entity)
        plant.Transform:SetPosition(offset[1], offset[2], offset[3])
        table.insert(inst.decor, plant)
    end
end

local sizes =
{
    { anim = "small_idle", rad = 2.0, plantcount = 2, plantrad = 2.0 },
    { anim = "med_idle",   rad = 2.6, plantcount = 3, plantrad = 2.9 },
    { anim = "big_idle",   rad = 3.6, plantcount = 4, plantrad = 3.8 },
}

local function SetSize2(inst, size)
    inst.AnimState:PlayAnimation(sizes[size].anim, true)
    inst.components.bathingpool:SetRadius(sizes[size].rad)
	inst.Physics:SetCapsule(sizes[size].rad, 2)

    SpawnPlants(inst, "um_plant_hotsprings", sizes[inst.size].plantcount, sizes[inst.size].plantrad)
end

local function DetermineSize(inst, fitting, removepond)
    if not inst.size or fitting then
        inst.size = math.random(1, fitting or #sizes)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, sizes[inst.size].rad, nil, nil, { "plant", "pond", "boulder", "rock", "tree" })
        for i, v in ipairs(ents) do
            if v ~= inst and inst.size ~= 1 then
                DetermineSize(inst, 2)
                break
            end
        end
        if removepond then
            local ents = TheSim:FindEntities(x, y, z, sizes[3].rad * 2, { "watersource" })
            for i, v in ipairs(ents) do
                if v ~= inst and v.prefab == "um_hotspring" then
                    inst:Remove()
                end
            end
        end
        SetSize2(inst, inst.size)
    end
end

local function SetSize(inst, size)
    inst.size = size or math.random(1, #sizes)
    SetSize2(inst, inst.size)
end

local function DoFx(inst) -- This is the hotspring's passive FX
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local spawnrad = math.random(1, 8) * sizes[inst.size].rad / 10
    local offset = FindWalkableOffset(pos, math.random() * 2 * PI, spawnrad)
    if offset then
        local fx
        if not inst:HasTag("pond_inducedinsanity") then
            fx = SpawnPrefab(math.random() > .75 and "crab_king_bubble" .. tostring(math.random(1, 3))
                or (math.random() > .5 and "crater_steam_fx" .. tostring(math.random(1, 4))
                    or "slow_steam_fx" .. tostring(math.random(1, 4))))
        else
            fx = SpawnPrefab("tophat_shadow_fx")
            fx:DoTaskInTime(1.5, function(fx) fx:Remove() end)
        end
        fx.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
    end
    --[[if TheWorld.state.isnewmoon then
        fx.AnimState:SetMultColour(0, 0, 0, 1)
    end]]
end

local function OnBathBombed(inst)
    inst.Light:Enable(true)
    if not inst.fxtask2 then
        inst.fxtask2 = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
    end
    if not inst.components.timer:TimerExists("bubbly") then
        inst.components.timer:StartTimer("bubbly", 60)
    end
    inst.components.heater.heat = 165
end

local function OnBathingPoolTick_PerOccupant(inst, occupant, dt)
    if inst.components.bathbombable.is_bathbombed then
        if occupant.components.health then
            occupant.components.health:DeltaPenalty(-0.009)
        end

        if occupant.components.inventory then
            local waterproofness = occupant.components.inventory and math.min(occupant.components.inventory:GetWaterproofness(), 1) or 0
            if occupant.components.moisture then
                occupant.components.moisture:DoDelta(4 * (1 - waterproofness), true)
            end
        end
    end

    if occupant.components.temperature then
        occupant.components.temperature:DoDelta(0.3)
    end

    if occupant.components.sanity and inst:HasTag("pond_inducedinsanity") then
        occupant.components.sanity:SetInducedInsanity(inst, true)
        if not occupant:HasTag("fuelfarming") then
            occupant:AddTag("fuelfarming")
        end
    end
end

local function OnBathingPoolTick(inst)
    local bathingpool = inst.components.bathingpool
    if bathingpool then
        bathingpool:ForEachOccupant(OnBathingPoolTick_PerOccupant, TUNING.HERMITHOTSPRING_TICK_PERIOD)
    end
end

local function OnStartBeingOccupiedBy(inst, ent)
    if not inst.bathingpoolents then
        inst.bathingpoolents = {
            [ent] = true,
        }
        inst.bathingpooltask = inst:DoPeriodicTask(TUNING.HERMITHOTSPRING_TICK_PERIOD, OnBathingPoolTick)
    else
        inst.bathingpoolents[ent] = true
    end
end

local function OnStopBeingOccupiedBy(inst, ent)
    if inst.bathingpoolents then
        inst.bathingpoolents[ent] = nil
        if ent.components.sanity then
            ent.components.sanity:SetInducedInsanity(inst, false)
        end

        if ent:HasTag("fuelfarming") then
            ent:RemoveTag("fuelfarming")
        end


        if next(inst.bathingpoolents) == nil then
            if inst.bathingpooltask then
                inst.bathingpooltask:Cancel()
                inst.bathingpooltask = nil
            end
            inst.bathingpoolents = nil
        end
    end
end


local function OnTimerDone(inst)
    inst.Light:Enable(false)
    if inst.fxtask2 then
        inst.fxtask2:Cancel()
        inst.fxtask2 = nil
    end
    inst.components.bathbombable:Reset()
    inst.components.heater.heat = 300
end

local function FadeToNormal(inst)
    if not inst.color then
        inst.color = 0
    end
    inst:RemoveTag("pond_inducedinsanity")
    inst.color = inst.color + FRAMES
    if inst.color > 1 then
        inst.color = 1
    else
        inst:DoTaskInTime(2 * FRAMES, FadeToNormal)
    end
    inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
    inst.components.bathbombable:Reset()
end

local function FadeToDark(inst)
    if not inst.color then
        inst.color = 1
    end
    inst:AddTag("pond_inducedinsanity")
    inst.color = inst.color - FRAMES
    if inst.color < .2 then
        inst.color = .1
    else
        inst:DoTaskInTime(2 * FRAMES, FadeToDark)
    end
    inst.AnimState:SetMultColour(inst.color, inst.color, inst.color, 1)
    inst.components.bathbombable:DisableBathBombing()
end

local function EmitSteam(inst)
    if not TheWorld.state.isnewmoon then
        local x, y, z = inst.Transform:GetWorldPosition()
        if inst.size == 1 then
            SpawnPrefab("um_steamcloud").Transform:SetPosition(x, y, z)
        else
            for i = 1, (inst.size * 2 - 1) do
                inst:DoTaskInTime(i * .66, function(inst)
                    local steam = SpawnPrefab("um_steamcloud")
                    local offset = FindWalkableOffset(inst:GetPosition(), math.random(PI * 2 * ((i - 1) / 3), PI * 2 * (i / 3)), inst.size * math.random(1, 2))
                    steam.Transform:SetPosition(x + offset.x, y, z + offset.z)
                end)
            end
        end
    end
end

local function OnSave(inst, data)
    if inst.size then
        data.size = inst.size
    end
    if inst.components.bathbombable.is_bathbombed then
        data.isbathbombed = true
    end
end

local function OnLoad(inst, data)
    if data then
        if data.size then
            SetSize(inst, data.size)
        end
        if data.isbathbombed then
            inst.components.bathbombable:OnBathBombed()
        elseif TheWorld.state.isnewmoon and not data.isbathbombed then
            inst.shadowfx = {}
            FadeToDark(inst)
        end
    end
end

local function OnEntitySleep(inst)
    if inst.fxtask then
        inst.fxtask:Cancel()
        inst.fxtask = nil
    end
    if inst.fxtask2 then
        inst.fxtask2:Cancel()
        inst.fxtask2 = nil
    end
    --[[if inst.steamy then
        inst.steamy:Cancel()
        inst.steamy = nil
    end]]
end

local function OnEntityWake(inst)
    if not inst.fxtask then
        inst.fxtask = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
    end
    if inst.components.bathbombable.is_bathbombed and not inst.fxtask2 then
        inst.fxtask2 = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
    end
    -- if math.random() > .5 then
    -- EmitSteam(inst)
    -- end
    -- inst.steamy = inst:DoPeriodicTask(math.random(30, 60),EmitSteam)
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local network = inst.entity:AddNetwork()
    local light = inst.entity:AddLight()
    local sound = inst.entity:AddSoundEmitter()
    local trans = inst.entity:AddTransform()
    local minimap = inst.entity:AddMiniMapEntity()
    MakePondPhysics(inst, 1)

    --MakeObstaclePhysics( inst, 3.5)

    anim:SetBuild("um_hotspring")
    anim:SetBank("um_hotspring")
    anim:SetOrientation(ANIM_ORIENTATION.OnGround)
    anim:SetSortOrder(3)
    anim:SetLayer(LAYER_BACKGROUND)

    minimap:SetIcon("pond_cave.png")

    light:Enable(false)
    light:SetRadius(TUNING.HOTSPRING_GLOW.RADIUS)
    light:SetIntensity(TUNING.HOTSPRING_GLOW.INTENSITY)
    light:SetFalloff(TUNING.HOTSPRING_GLOW.FALLOFF)
    light:SetColour(.1, 1.6, 2)

    inst:AddTag("watersource")
    inst:AddTag("HASHEATER")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")

    inst.no_wet_prefix = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("heater")
    inst.components.heater.heat = 300

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("timer")

    inst:AddComponent("bathbombable")
    inst.components.bathbombable:SetOnBathBombedFn(OnBathBombed)

    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    inst:DoTaskInTime(0, DetermineSize, nil, true)

    inst:WatchWorldState("isnewmoon", function(inst)
        if not inst.components.bathbombable.is_bathbombed then
            inst.shadowfx = {}
            FadeToDark(inst)
        end
    end)
    inst:WatchWorldState("isday", function(inst)
        if not inst.components.bathbombable.is_bathbombed and inst.color and inst.color < 1 then
            FadeToNormal(inst)
        end
    end)

    inst:AddComponent("bathingpool")
    inst.components.bathingpool:SetOnStartBeingOccupiedBy(OnStartBeingOccupiedBy)
    inst.components.bathingpool:SetOnStopBeingOccupiedBy(OnStopBeingOccupiedBy)


    return inst
end

return Prefab("um_hotspring", fn, assets)

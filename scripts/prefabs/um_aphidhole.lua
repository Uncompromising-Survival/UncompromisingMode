local assets =
{
    Asset("ANIM", "anim/um_aphidhole.zip"),
}

local function StartSpawning(inst)
    if inst.components.spawner ~= nil then
        inst.components.spawner:SetQueueSpawning(false)
        if not inst.components.spawner:IsSpawnPending() then
            inst.components.spawner:SpawnWithDelay(math.random(60, 180))
        end
    end
end

local function StopSpawning(inst)
    if inst.components.spawner ~= nil then
        inst.components.spawner:SetQueueSpawning(true, math.random(60, 120))
    end
end

local function OnIsDay(inst, isday)
    if isday then
       StartSpawning(inst)
    else
       StopSpawning(inst)
    end
end

local function Threatened(inst, attacker, damage)
    if inst.components.spawner:IsOccupied() then
        inst.components.lootdropper:SpawnLootPrefab("aphid")
    end
end

local HAUNTTARGET_MUST_TAGS = { "_combat" }
local HAUNTTARGET_CANT_TAGS = { "insect", "playerghost", "INLIMBO" }
local HAUNTTARGET_ONEOF_TAGS = { "character", "animal", "monster" }
local function OnHaunt(inst)
    if inst.components.spawner == nil or
        not inst.components.spawner:CanSpawn() or
        math.random() > TUNING.HAUNT_CHANCE_HALF then
        return false
    end

    local target = FindEntity(
        inst,
        25,
        function(guy)
            return inst.components.combat:CanTarget(guy)
        end,
        HAUNTTARGET_MUST_TAGS, --See entityreplica.lua (re: "_combat" tag)
        HAUNTTARGET_CANT_TAGS,
        HAUNTTARGET_ONEOF_TAGS
    )

    if target ~= nil then
        Threatened(inst, target)
        return true
    end
    return false
end

local function OnInit(inst)
    inst:WatchWorldState("isday", OnIsDay)
    OnIsDay(inst, TheWorld.state.isday)

    if not inst.type then
        inst.type = math.random(0,2)
    end

    inst.AnimState:PlayAnimation("idle"..inst.type)
end

local function OnLoad(inst, data)
    if data and data.type then
        inst.type = data.type
    end
end

local function OnSave(inst)
    local data = {}
    data.type = inst.type
    return data
end

local function dig_up(inst)
    if inst.components.spawner:IsOccupied() then
        inst.components.lootdropper:SpawnLootPrefab("aphid")
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()


    inst.AnimState:SetBank("um_aphidhole")
    inst.AnimState:SetBuild("um_aphidhole")

    inst:AddTag("structure")
    inst:AddTag("beaverchewable") -- by werebeaver

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("spawner") -- Use rabbit hole as a base.
    WorldSettings_Spawner_SpawnDelay(inst, TUNING.RABBIT_RESPAWN_TIME, TUNING.RABBIT_ENABLED)
    inst.components.spawner:Configure("aphid", TUNING.RABBIT_RESPAWN_TIME)


    inst:DoTaskInTime(0, OnInit)

    ---------------------
    ---------------------
    ---------------------
    MakeLargePropagator(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    ---------------------

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)


    return inst
end

local NOTENTCHECK_CANT_TAGS = { "FX", "INLIMBO" }

local function noentcheckfn(pt)
    return not TheWorld.Map:IsPointNearHole(pt) and #TheSim:FindEntities(pt.x, pt.y, pt.z, 1, nil, NOTENTCHECK_CANT_TAGS) == 0
end

local function Populate(inst)
    local pos = inst:GetPosition()
    local x,y,z = inst.Transform:GetWorldPosition()
    for i = 1,math.random(6,8) do
        local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 2, 8, false, true, noentcheckfn, true, true)
        if offset then
            SpawnPrefab("um_aphidhole").Transform:SetPosition(x+offset.x, y, z + offset.z)
        end
    end
    inst:Remove()
end

local function fncluster()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0,Populate)
    return inst
end

return Prefab("um_aphidhole", fn, assets),
Prefab("um_aphidhole_clusterspawner", fncluster, assets)

local assets =
{
    Asset("ANIM", "anim/fern_fox.zip"),
}


local brain = require("brains/fern_foxbrain")

SetSharedLootTable('fern_fox',
{
    {'plantmeat',              1.00},
    {'um_moss',              1},
    {'um_moss',              1},
    {'um_moss',              0.5},
})
require("constants")
NAUGHTY_VALUE["um_fern_fox"] = 25
--------------------------------------------------------------------------

--[[local function onsave(inst, data)

end

local function onload(inst, data)

end]]

local function MakeGrowFast(plant)
    if plant.entity:IsAwake() then
        local x,y,z = plant.Transform:GetWorldPosition()
        SpawnPrefab("spider_heal_target_fx").Transform:SetPosition(x,y,z)
    end
    if plant.components.pickable then
        plant.components.pickable:LongUpdate(10)
    end
    if plant.components.growable then
        plant.components.growable:LongUpdate(10)
    end
end

local plant_tags_oneof_tags = {"plant", "farm_plant", "bush", "pickable"}
local function MakePlantsGrowFast(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local plants = TheSim:FindEntities(x, y, z, 4, nil, nil, plant_tags_oneof_tags)
    local found = nil
    for i, plant in ipairs(plants) do
        if not plant.growbuff and not found then
            local x,y,z = plant.Transform:GetWorldPosition()
            SpawnPrefab("farm_plant_happy").Transform:SetPosition(x,y,z)
            plant.growbuff = plant:DoPeriodicTask(5, MakeGrowFast)
            plant:DoTaskInTime(3 * 480,function(plant) 
                if plant.growbuff then 
                    plant.growbuff:Cancel() 
                    plant.growbuff = nil
                end
            end)
            found = true
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.75, .75)

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 100, .5)

    inst.AnimState:SetBank("fern_fox")
    inst.AnimState:SetBuild("fern_fox")
    inst.AnimState:PlayAnimation("idle", true)

    ------------------------------------------

    inst:AddTag("animal")
    inst:AddTag("plantkin")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("timer")
    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.DEER_DAMAGE)
    inst.components.combat.hiteffectsymbol = "fire"
    inst.components.combat:SetHurtSound("dontstarve/creatures/together/deer/hit")

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('fern_fox')

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.DEER_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.DEER_RUN_SPEED

    MakeHauntablePanic(inst)
    inst:SetBrain(brain)

    ------------------------------------------

    inst:SetStateGraph("SGfern_fox")

    MakeSmallBurnableCharacter(inst, "fire")
    MakeSmallFreezableCharacter(inst, "fire")

    --inst.OnSave = onsave
    --inst.OnLoad = onload

    inst.OnEntityWake  = function(inst)
        if not inst.plants_will_grow then
            inst.plants_will_grow = inst:DoPeriodicTask(3,MakePlantsGrowFast)
        end
    end

    inst.OnEntitySleep = function(inst)
        if inst.plants_will_grow then
            inst.plants_will_grow:Cancel()
            inst.plants_will_grow = nil
        end
    end

    return inst
end

-- local function canspawn(inst)
    -- return inst:IsAsleep() -- no art, only spawn when players aren't near
-- end

local function fnden()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    --MakeSmallObstaclePhysics(inst, .5)

    --inst.MiniMapEntity:SetIcon("catcoonden.png")

    inst.AnimState:SetBank("catcoon_den")
    inst.AnimState:SetBuild("catcoon_den")
    inst.AnimState:PlayAnimation("idle")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "um_fern_fox"
    inst.components.childspawner:SetRegenPeriod(480*3) -- 3 days
    inst.components.childspawner:SetSpawnPeriod(TUNING.CATCOONDEN_RELEASE_TIME)
    inst.components.childspawner:SetMaxChildren(TUNING.CATCOONDEN_MAXCHILDREN)
    --inst.components.childspawner.canspawnfn = canspawn
    inst.components.childspawner:StartSpawning()

    ---------------------

    MakeMediumBurnable(inst)
    AddToRegrowthManager(inst)
    MakeSmallPropagator(inst)

    ---------------------
    inst:AddComponent("inspectable")

    MakeSnowCovered(inst)
    SetLunarHailBuildupAmountSmall(inst)

    MakeHauntableIgnite(inst)

    inst:Hide()

    return inst
end

return Prefab("um_fern_fox", fn, assets),
    Prefab("um_fern_fox_den", fnden)
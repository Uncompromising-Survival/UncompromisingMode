--[[
    ]] local assets = {
    Asset("ANIM", "anim/water_rock_01.zip"), Asset("MINIMAP_IMAGE", "seastack")
}

local prefabs = {"rock_break_fx", "waterplant_baby", "waterplant_destroy"}

SetSharedLootTable('sludgestack', {
    {'rocks', 1.00}, {'rocks', 1.00}, {'sludge', 1.00}, {'sludge', 0.5}
})

local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        TheWorld:PushEvent("CHEVO_seastack_mined", {
            target = inst,
            doer = worker
        })
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())

        local loot_dropper = inst.components.lootdropper

        inst:SetPhysicsRadiusOverride(nil)

        loot_dropper:DropLoot(pt)

        inst:Remove()
    end
end

local function fling_loot(loot)
    loot:ReturnToScene()
    Launch2(loot, loot, 2, 2, 5, 0, 10)
end

local function OnUpgraded(inst)
    inst.upgraded = true
    -- upgradedable onsave/load is aparently, from what I've learnt from the winona stuff, unreliable.
    -- so I'll use this variable instead.
    inst.components.pickable:Pause()
    -- play anim of cork topping off the vent
    if not inst.components.timer:TimerExists("pop_cork") then
        inst.components.timer:StartTimer("pop_cork", TUNING.GRASS_REGROW_TIME)
    end
end

local function CanUpgrade(inst)
    if inst.components.pickable:CanBePicked() then
        return false, "NOT_HARVESTED"
    elseif not inst.upgraded then
        return true
    end
end

local function DoLootExplosion(inst)
    local MAX_LOOTFLING_DELAY = 0.8

    local cork_pop_loot = {
        "sludge", "sludge", "sludge", "sludge", "sludge_cork"
    }

    if math.random() > 0.66 then
        table.insert(cork_pop_loot, "nitre")
        table.insert(cork_pop_loot, "nitre")
        table.insert(cork_pop_loot, "nitre")
    end

    if math.random() > 0.5 then
        if math.random() > 0.5 then
            table.insert(cork_pop_loot, "redgem")
        else
            table.insert(cork_pop_loot, "bluegem")
        end
        table.insert(cork_pop_loot, "sludge")
    end

    for i, v in ipairs(cork_pop_loot) do
        local loot = SpawnPrefab(v)
        loot:RemoveFromScene()
        loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
        loot:DoTaskInTime(MAX_LOOTFLING_DELAY * math.random(), fling_loot)
    end
    inst.components.pickable:Resume()
    inst.components.pickable:Regen()

    inst.upgraded = false

    -- revert the art back, play an animation of the cork popping off

end

local function TimerDone(inst, data)
    if data.name == "pop_cork" then
        if not inst:IsAsleep() then 
            DoLootExplosion(inst)
        else
            inst.explode_when_loaded = true
        end
    end
end

local function OnEntityWake(inst)
    if inst.explode_when_loaded then
        DoLootExplosion(inst)
    end
end

local function OnSave(inst, data)
    if data ~= nil then
        data.upgraded = inst.upgraded

        data.paused = inst.components.pickable.paused
        data.explode_when_loaded = inst.explode_when_loaded
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.upgraded ~= nil then OnUpgraded(inst) end
        if data.paused then
            inst.components.pickable:Pause()
        else
            inst.components.pickable:Resume()
        end
        inst.explode_when_loaded = data.explode_when_loaded
    end
    inst:AddTag("SLUDGE_CORK_upgradeable") -- GOD DAMNIT KEEP THE DAMN TAG!!!
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("seastack.png")

    inst:SetPhysicsRadiusOverride(2.35)

    MakeWaterObstaclePhysics(inst, 0.80, 2, 0.75)

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("seastack")

    inst.AnimState:SetBank("water_rock01")
    inst.AnimState:SetBuild("water_rock_01")
    inst.AnimState:PlayAnimation("1_full")
    inst.AnimState:SetMultColour(0.5, 0.5, 0.5, 1)

    MakeInventoryFloatable(inst, "med", 0.1, {1.1, 0.9, 1.1})
    inst.components.floater.bob_percent = 0

    local land_time = (POPULATING and math.random() * 5 * FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)

    -- Have to add to pristine state.
    inst:AddTag("SLUDGE_CORK_upgradeable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('sludgestack')
    inst.components.lootdropper.max_speed = 2
    inst.components.lootdropper.min_speed = 0.3
    inst.components.lootdropper.y_speed = 14
    inst.components.lootdropper.y_speed_variance = 4
    inst.components.lootdropper.spawn_loot_inside_prefab = true

    inst:AddComponent("inspectable")

    inst:AddComponent("pickable")
    inst.components.pickable:SetUp("sludge", TUNING.GRASS_REGROW_TIME)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.SEASTACK_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)
    inst.components.workable.savestate = true

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.SLUDGE_CORK
    inst.components.upgradeable.onupgradefn = OnUpgraded
    inst.components.upgradeable.canupgradefn = CanUpgrade

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", TimerDone)
    MakeHauntableWork(inst)

    --------SaveLoad 
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.OnEntityWake = OnEntityWake

    return inst
end

return Prefab("sludgestack", fn, assets, prefabs)
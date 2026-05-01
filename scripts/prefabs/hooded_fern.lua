local assets =
{
    Asset("ANIM", "anim/um_thicket.zip"),
}

local PF_DIMS = 4 --equal to 4x4 grid of walls

local function UnregisterPathFinding(inst)
    print("UNREGISTRING WALLS")
    local x = inst._pfpos.x - (PF_DIMS - 1) / 2
    local z = inst._pfpos.z - (PF_DIMS - 1) / 2
    local pathfinder = TheWorld.Pathfinder
    for i = 0, PF_DIMS - 1 do
        for j = 0, PF_DIMS - 1 do
            pathfinder:RemoveWall(x + i, 0, z + j)
        end
    end
end

local function RegisterPathFinding(inst)
    print("REGISTERING WALLS")
    inst._pfpos = inst:GetPosition()
    local x = inst._pfpos.x - (PF_DIMS - 1) / 2
    local z = inst._pfpos.z - (PF_DIMS - 1) / 2
    local pathfinder = TheWorld.Pathfinder
    for i = 0, PF_DIMS - 1 do
        for j = 0, PF_DIMS - 1 do
            pathfinder:AddWall(x + i, 0, z + j)
        end
    end
    inst.OnRemoveEntity = UnregisterPathFinding
end

local function OnBurnt(inst)
    local node = TheWorld.Map:FindNodeAtPoint(inst.Transform:GetWorldPosition())

    if node ~= nil and node.tags ~= nil and not table.contains(node.tags, "hoodedcanopy") then
        inst:Remove()
        return
    end

    inst.components.pickable:Pick(nil) --nil doesn't give any loot.
end

local function onregenfn(inst)
    inst:Show()
    inst.hidden = nil
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    inst:AddTag("briar_plants")

    if not inst.components.burnable then
        MakeMediumBurnable(inst)
        inst.components.burnable:SetBurnTime(0.75)
        inst.components.burnable:SetOnBurntFn(OnBurnt)
    end
    print("regen, registering")
    inst:DoTaskInTime(0, RegisterPathFinding)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("pick")
    inst.AnimState:PushAnimation("empty")
    print("empty, unregistering")
    inst:DoTaskInTime(0, UnregisterPathFinding)
end

local function makebarrenfn(inst, wasempty)
    if not POPULATING and
        (inst.components.witherable ~= nil and
            inst.components.witherable:IsWithered()
        ) then
        inst.AnimState:PlayAnimation(wasempty and "empty" or "empty")
        inst.AnimState:PushAnimation("empty", false)
    else
        inst.AnimState:PlayAnimation("empty")
    end

    print("barren,, unregistering")
    inst:DoTaskInTime(0, UnregisterPathFinding)
end

local function ToggleBusyAnimation(inst)
    inst.busyanimation = false
    inst:RemoveEventCallback("animover", ToggleBusyAnimation)
end

local function GetCropSeeds()
    local weighted_briar_loot = {}
    local all_seeds = { "carrot", "corn", "dragonfruit", "durian", "eggplant", "pomegranate", "pumpkin", "asparagus", "tomato", "potato", "onion", "pepper", "garlic", "watermelon" }
    for i, v in ipairs(all_seeds) do
        weighted_briar_loot[v] = 0.1
    end
    if TheWorld.state.isspring then
        local spring_seeds = { "carrot", "corn", "dragonfruit", "durian", "eggplant", "pomegranate", "pumpkin", "asparagus", "tomato", "potato", "onion", "garlic", "watermelon" }
        for i, v in ipairs(spring_seeds) do
            weighted_briar_loot[v] = 0.4
        end
    elseif TheWorld.state.iswinter then
        --nothing
    elseif TheWorld.state.issummer then
        local summer_seeds = { "corn", "dragonfruit", "pomegranate", "tomato", "onion", "pepper", "garlic", "watermelon", "carrot" }
        for i, v in ipairs(summer_seeds) do
            weighted_briar_loot[v] = 0.4
        end
    else
        local fall_seeds = { "carrot", "corn", "eggplant", "pumpkin", "asparagus", "tomato", "potato", "onion", "pepper", "garlic" }
        for i, v in ipairs(fall_seeds) do
            weighted_briar_loot[v] = 0.4
        end
    end
    return weighted_random_choice(weighted_briar_loot) .. "_seeds"
end

local function GenerateLoot(inst, picker)
    local weighted_briar_loot = {}
    weighted_briar_loot["seeds"] = 0.2
    weighted_briar_loot["crop_seed"] = 0.2
    weighted_briar_loot["cutgrass"] = 0.4
    weighted_briar_loot["twigs"] = 0.15
    if not IsIslandWorld() then
        weighted_briar_loot["aphid"] = 0.025
    else
        weighted_briar_loot["snake"] = 0.025
        weighted_briar_loot["snake_poison"] = 0.025
        weighted_briar_loot["vine"] = 0.4
    end
    weighted_briar_loot["spider"] = 0.0125
    weighted_briar_loot["mound"] = 0.0125

    local loot = weighted_random_choice(weighted_briar_loot)
    if loot == "crop_seed" then
        loot = GetCropSeeds()
    end
    if inst:IsValid() then
        if loot == "mound" then
            local mound = SpawnPrefab("mound")
            mound.Transform:SetPosition(inst.Transform:GetWorldPosition())
            mound.persists = false
            mound:DoTaskInTime(60 * 8, function(mound) mound:Remove() end) -- disappear after a day
        else
            if picker and picker.components.inventory and loot ~= "spider" and loot ~= "aphid" and loot ~= "snake" and loot ~= "snake_poison" then
                picker.components.inventory:GiveItem(SpawnPrefab(loot), nil, inst:GetPosition())
            else
                Launch(inst.components.lootdropper:SpawnLootPrefab(loot), inst, 1.5)
            end
        end
    end
end

local function onpickedfn(inst, picker)
    if inst.busyanimation == true then
        ToggleBusyAnimation(inst)
    end
    if inst.BrushingTest then
        inst.BrushingTest:Cancel()
        inst.BrushingTest = nil
    end
    if picker and picker.components.combat and not (picker.components.inventory and (picker.components.inventory:EquipHasTag("bramble_resistant") or picker.components.inventory:EquipHasTag("lazy_forager"))) and not picker:HasAnyTag("shadowminion", "aphid", "channelingpicker") then
        picker.components.combat:GetAttacked(inst, TUNING.CACTUS_DAMAGE)
        picker:PushEvent("thorns")
    end
    inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
    inst.AnimState:PlayAnimation("pick")
    SpawnPrefab("oceantree_leaf_fx_chop").Transform:SetPosition(inst.Transform:GetWorldPosition())
    if math.random() < 0.2 then
        if picker == nil then --picker being nil assuming its fire.
            Launch(inst.components.lootdropper:SpawnLootPrefab("ash"), inst, 1.5)
        else
            GenerateLoot(inst, picker)
        end
    end
    inst.AnimState:PushAnimation("empty", false)
    inst:RemoveTag("briar_plants")
    inst:RemoveComponent("burnable")
    print("picked, unregistering")
    inst:DoTaskInTime(0, UnregisterPathFinding)
end

local thicket_equipment = { "um_hat_leafwing", "armor_bramble", "um_armor_bramble_rimeweed", "armor_lunarplant_husk" }
local function WearingThicketResist(inst)
    local head
    local body
    if inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) then
        head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab
    end
    if inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) then
        body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY).prefab
    end
    return (head and table.contains(thicket_equipment, head)) or (body and table.contains(thicket_equipment, body))
end

local function OutOfTheWoodsYet(target)
    local the_bush = FindEntity(target, 1.75, nil, { "briar_plants" })
    if not the_bush or WearingThicketResist(target) then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "thicket")
        target.thicketcheck:Cancel()
        target.thicketcheck = nil
    end
end

local function CheckToSeeIfTargetsMoving(inst)
    for i, v in ipairs(inst.playertracking) do
        if v:IsValid() and inst:GetDistanceSqToInst(v) <= 1.5 ^ 2 then
            if v.sg:HasStateTag("moving") and inst.busyanimation == false then
                inst.AnimState:PlayAnimation("bounce", false)
                inst.busyanimation = true
                inst:ListenForEvent("animover", ToggleBusyAnimation)
            end
        else
            table.remove(inst.playertracking, i)
        end
    end
    if #inst.playertracking == 0 then
        inst.BrushingTest:Cancel()
        inst.BrushingTest = nil
        inst.AnimState:PlayAnimation("unpress")
        inst.AnimState:PushAnimation("idle")
    end
end

local function onnear(inst, target)
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        if not WearingThicketResist(target) then
            if math.random() > 0.8 then
                if not IsIslandWorld() then
                    SpawnPrefab("aphid").Transform:SetPosition(inst.Transform:GetWorldPosition())
                else
                    SpawnPrefab("snake").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end

            target.components.locomotor:SetExternalSpeedMultiplier(target, "thicket", 0.3)
            if not target.thicketcheck then
                target.thicketcheck = target:DoPeriodicTask(0.1, OutOfTheWoodsYet)
            end
        end
        table.insert(inst.playertracking, target)

        if #inst.playertracking > 0 and not inst.BrushingTest then
            inst.BrushingTest = inst:DoPeriodicTask(0.3, CheckToSeeIfTargetsMoving)
            if #inst.playertracking == 1 then
                inst.AnimState:PlayAnimation("depress", false)
                inst.busyanimation = true
                inst:ListenForEvent("animover", ToggleBusyAnimation)
            end
        end
    end
end

local function grass(name, stage)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("um_thicket")
        inst.AnimState:SetBuild("um_thicket")
        inst.AnimState:PlayAnimation("idle", true)

        inst:AddTag("plant")
        inst:AddTag("briar_plants")
        inst:AddTag("thorny")
        inst:AddTag("walrus_trap_spot")

        -- local multcolour = 0.5
        -- if 0 <= multcolour and multcolour < 1 then
        -- local colour = multcolour + math.random() * (1.0 - multcolour)
        -- inst.AnimState:SetMultColour(colour, colour, colour, 1)
        -- end
        print("startup, registering")
        inst:DoTaskInTime(0, RegisterPathFinding)

        inst.entity:SetPristine()
        inst.AnimState:SetTime(math.random() * 2)

        if IsIslandWorld() then
            inst.AnimState:SetMultColour(1, .9, .75, 1)
        end

        if not TheWorld.ismastersim then
            return inst
        end



        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

        inst.components.pickable:SetUp(nil, TUNING.GRASS_REGROW_TIME, 2)
        inst.components.pickable.onregenfn = onregenfn
        inst.components.pickable.onpickedfn = onpickedfn
        inst.components.pickable.makeemptyfn = makeemptyfn
        inst.components.pickable.makebarrenfn = makebarrenfn
        inst.components.pickable.max_cycles = 2  -- Not transplantable, shouldn't matter.
        inst.components.pickable.cycles_left = 2 -- Not transplantable, shouldn't matter.

        inst:AddComponent("lootdropper")

        inst:AddComponent("inspectable")

        ---------------------
        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(1.75, 3) --set specific values
        inst.components.playerprox:SetOnPlayerNear(onnear)
        inst.components.playerprox:SetPlayerAliveMode(inst.components.playerprox.AliveModes.AliveOnly)
        MakeNoGrowInWinter(inst)
        MakeHauntableIgnite(inst)
        MakeMediumBurnable(inst)
        inst.components.burnable:SetBurnTime(0.75)
        inst.components.burnable:SetOnBurntFn(OnBurnt)



        inst.playertracking = {}

        inst.OnSave = function(inst, data)
            if inst.hidden then
                data = {}
                data.hidden = true
            end
        end

        inst.OnLoad = function(inst, data)
            if data and data.hidden then
                inst.hidden = true
                inst:Hide()
            end
        end

        inst:DoTaskInTime(0, function(inst)
            if math.random() > 0.5 then
                inst.AnimState:SetScale(-1, 1)
            end
        end)
        MakeMediumPropagator(inst)
        return inst
    end

    return Prefab(name, fn, assets)
end

return grass("hooded_fern", 0),
    grass("depleted_hooded_fern", 1)

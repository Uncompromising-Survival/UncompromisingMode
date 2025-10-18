local env = env
GLOBAL.setfenv(1, GLOBAL)

local RADIUS = TUNING.FIRE_DETECTOR_RANGE * 1.1
local PLACER_SCALE = math.sqrt(RADIUS * 300 / 1900)

local function StartSoundLoop(inst)
    if not inst.playingsound then
        inst.playingsound = true
        OnEntityWake(inst)
    end
end

---ORANGE
local ORANGE_PICKUP_MUST_TAGS = {"_inventoryitem", "plant", "witherable", "kelp", "structure", "lureplant", "mush-room", "waterplant", "oceanvine", "lichen", "pickable"}

-- from simutil.lua @l 356
local PICKUP_CANT_TAGS = {
    -- Items
    "INLIMBO",
    "NOCLICK",
    "irreplaceable",
    "knockbackdelayinteraction",
    "event_trigger",
    "minesprung",
    "mineactive",
    "catchable",
    "fire",
    "light",
    "spider",
    "cursed",
    "paired",
    "bundle",
    "heatrock",
    "deploykititem",
    "boatbuilder",
    "singingshell",
    "archive_lockbox",
    "simplebook",
    "furnituredecor",
    -- Pickables
    "flower",
    "gemsocket", -- "structure",
    -- Either
    "donotautopick",
    "moonglass_geode",
    "engineeringbatterypowered"
}

local function pickup(inst, channeler)
    if channeler == nil or channeler.components.inventory == nil then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, RADIUS, nil, PICKUP_CANT_TAGS, ORANGE_PICKUP_MUST_TAGS)
    for i, v in ipairs(ents) do
        if v.components.inventoryitem ~= nil and -- Inventory stuff
        v.components.inventoryitem.canbepickedup and v.components.inventoryitem.cangoincontainer and not v.components.inventoryitem:IsHeld() and channeler.components.inventory:CanAcceptCount(v, 1) > 0 then
            if channeler.components.minigame_participator ~= nil then
                local minigame = channeler.components.minigame_participator:GetMinigame()
                if minigame ~= nil then
                    minigame:PushEvent("pickupcheat", {cheater = channeler, item = v})
                end
            end

            -- Amulet will only ever pick up items one at a time. Even from stacks.
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())

            local v_pos = v:GetPosition()
            if v.components.stackable ~= nil then
                v = v.components.stackable:Get()
            end

            if v.components.trap ~= nil and v.components.trap:IsSprung() then
                v.components.trap:Harvest(channeler)
            else
                channeler.components.inventory:GiveItem(v, nil, v_pos)
            end
            return
        end

        if v.components.crop ~= nil and v.components.crop.matured then -- Farmplots/Wild Crops
            v.components.crop:Harvest(channeler)
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.5) -- Can't take too much sanity if the purpose is to use in large farms
            return
        end
        if v.components.harvestable ~= nil and v.components.harvestable:CanBeHarvested() then -- and v:HasTag("mushroom_farm") then --Mushroom Farms
            v.components.harvestable:Harvest(channeler)
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.25) -- Can't take too much sanity if the purpose is to use in large farms
            return
        end
        if v.components.stewer ~= nil and v.components.stewer:IsDone() then -- Crockpot dishes, not sure who's gonna do this though lol
            v.components.stewer:Harvest(channeler)
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.25) -- Can't take too much sanity if the purpose is to use in large farms
            return
        end
        if v.components.pickable ~= nil and v.components.pickable:CanBePicked() and v.prefab ~= "flower" then -- Pickable stuff
            channeler:AddTag("channelingpicker")
            v.components.pickable:Pick(channeler)
            channeler:RemoveTag("channelingpicker")
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.25) -- Can't take too much sanity if the purpose is to use in large farms
            return
        end
        if v.components.dryer ~= nil and v.components.dryer:IsDone() then -- Drying racks
            v.components.dryer:Harvest(channeler)
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.25)
            return
        end
        if v.components.shelf ~= nil and v.components.shelf.itemonshelf ~= nil and not TheWorld.state.iswinter then -- Lureplants
            v.components.shelf:TakeItem(channeler)
            SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            inst.channeler.components.sanity:DoDelta(-0.25)
            return
        end
    end
end

local function OnStartChanneling(inst, channeler)
    inst.AnimState:PlayAnimation("turn_on")
    inst.AnimState:PushAnimation("idle_on_loop")
    StartSoundLoop(inst)
    TheWorld:PushEvent("townportalactivated", inst)
    inst.task = inst:DoPeriodicTask(TUNING.ORANGEAMULET_ICD / 1.2, pickup, nil, channeler)

    inst.MiniMapEntity:SetIcon("townportalactive.png")
    inst.MiniMapEntity:SetPriority(20)

    if inst.icon ~= nil then
        inst.icon.MiniMapEntity:SetIcon("townportalactive.png")
        inst.icon.MiniMapEntity:SetPriority(20)
        inst.icon.MiniMapEntity:SetDrawOverFogOfWar(true)
    end

    inst.channeler = channeler.components.sanity ~= nil and channeler or nil
    if inst.channeler ~= nil then
        inst.channeler.components.sanity:DoDelta(-TUNING.SANITY_MED)
        inst.channeler.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_SUPERHUGE)
    end
end

local function OnStopChanneling(inst, aborted)
    TheWorld:PushEvent("townportaldeactivated", inst)

    inst.MiniMapEntity:SetIcon("townportal.png")
    inst.MiniMapEntity:SetPriority(0)

    if inst.icon ~= nil then
        inst.icon.MiniMapEntity:SetIcon("townportal.png")
        inst.icon.MiniMapEntity:SetPriority(0)
    end

    if inst.channeler ~= nil and inst.channeler:IsValid() and inst.channeler.components.sanity ~= nil then
        inst.channeler.components.sanity.externalmodifiers:RemoveModifier(inst)
    end
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function OnEnableHelper(inst, enabled)
    if enabled then
        if inst.helper == nil then
            inst.helper = CreateEntity()

            --[[Non-networked entity]]
            inst.helper.entity:SetCanSleep(false)
            inst.helper.persists = false

            inst.helper.entity:AddTransform()
            inst.helper.entity:AddAnimState()

            inst.helper:AddTag("CLASSIFIED")
            inst.helper:AddTag("NOCLICK")
            inst.helper:AddTag("placer")

            inst.helper.Transform:SetScale(PLACER_SCALE, PLACER_SCALE, PLACER_SCALE)

            inst.helper.AnimState:SetBank("firefighter_placement")
            inst.helper.AnimState:SetBuild("firefighter_placement")
            inst.helper.AnimState:PlayAnimation("idle")
            inst.helper.AnimState:SetLightOverride(1)
            inst.helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.helper.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.helper.AnimState:SetSortOrder(1)
            inst.helper.AnimState:SetAddColour(1, 1, 0, 0) -- Set to yellow glow

            inst.helper.entity:SetParent(inst.entity)
        end
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
end

env.AddPrefabPostInit("townportal", function(inst)
    if not TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
        -- inst.components.deployhelper:AddKeyFilter("lazytown_harvestable")

        -- To ensure future compatibility, consider overriding the global defined method deployhelper.TriggerDeployHelpers.
        -- Add a StartHelper check that does not rely on placerinst.deployhelper_key, 
        -- this is to prevent conflicts caused by overlapping deployhelper_key values of the being placed instances.
        -- For now, do not implement a filter; which means this place helper will show to all items.
    end

    if not TheWorld.ismastersim then
        return
    end

    inst.components.channelable:SetChannelingFn(OnStartChanneling, OnStopChanneling)
    -- return inst
end)

local function placer_postinit_fn(inst)
    -- Show the flingo placer on top of the flingo range ground placer

    local placer2 = CreateEntity()

    --[[Non-networked entity]]
    placer2.entity:SetCanSleep(false)
    placer2.persists = false

    placer2.entity:AddTransform()
    placer2.entity:AddAnimState()

    placer2:AddTag("CLASSIFIED")
    placer2:AddTag("NOCLICK")
    placer2:AddTag("placer")

    placer2.AnimState:SetBank("firefighter_placement")
    placer2.AnimState:SetBuild("firefighter_placement")
    placer2.AnimState:PlayAnimation("idle")
    placer2.AnimState:SetLightOverride(1)
    placer2.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    placer2.Transform:SetScale(PLACER_SCALE, PLACER_SCALE, PLACER_SCALE)

    placer2.entity:SetParent(inst.entity)

    inst.components.placer:LinkEntity(placer2)
end

env.AddPrefabPostInit("townportal_placer", placer_postinit_fn)

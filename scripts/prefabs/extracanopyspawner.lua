require "prefabutil"
local CANOPY_SHADOW_DATA = require("prefabs/giant_tree_canopy")

local MIN = TUNING.SHADE_CANOPY_RANGE_SMALL
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER

local DROP_ITEMS_DIST_MIN = 6
local DROP_ITEMS_DIST_VARIANCE = 10

local NUM_DROP_SMALL_ITEMS_MIN_LIGHTNING = 3
local NUM_DROP_SMALL_ITEMS_MAX_LIGHTNING = 5

--[[local function RemoveCanopyShadow(inst)
    if inst.canopy_data ~= nil then
        for _, shadetile_key in ipairs(inst.canopy_data.shadetile_keys) do
            if TheWorld.hooded_forest_shadetiles[shadetile_key] ~= nil then
                TheWorld.hooded_forest_shadetiles[shadetile_key] = TheWorld.hooded_forest_shadetiles[shadetile_key] - 1

                if TheWorld.hooded_forest_shadetiles[shadetile_key] <= 0 then
                    if TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key] ~= nil then
                        DespawnHoodedforestCanopy(TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key])
                        TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key] = nil
                    end
                end
            end
        end

        for _, ray in ipairs(inst.canopy_data.lightrays) do
            ray:Remove()
        end
    end
end]]

local lightningprods =
{
    "twigs",
    "cutgrass",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
    "oceantree_leaf_fx_fall",
}

local function DropLightningItems(inst, items)
    local x, _, z = inst.Transform:GetWorldPosition()
    local num_items = #items

    for i, item_prefab in ipairs(items) do
        local dist = DROP_ITEMS_DIST_MIN + DROP_ITEMS_DIST_VARIANCE * math.random()
        local theta = TWOPI * math.random()

        inst:DoTaskInTime(i * 5 * FRAMES, function(inst2)
            local item = SpawnPrefab(item_prefab)
            item.Transform:SetPosition(x + dist * math.cos(theta), 20, z + dist * math.sin(theta))

            if i == num_items then
                inst._lightning_drop_task:Cancel()
                inst._lightning_drop_task = nil
            end
        end)
    end
end

local function OnLightningStrike(inst)
    if inst._lightning_drop_task ~= nil then
        return
    end

    local num_small_items = math.random(NUM_DROP_SMALL_ITEMS_MIN_LIGHTNING, NUM_DROP_SMALL_ITEMS_MAX_LIGHTNING)
    local items_to_drop = {}

    for i = 1, num_small_items do
        table.insert(items_to_drop, lightningprods[math.random(1, #lightningprods)])
    end

    inst._lightning_drop_task = inst:DoTaskInTime(20 * FRAMES, DropLightningItems, items_to_drop)
end

local function OnFar(inst, player)
    if player.canopytrees then   
        player.canopytrees = player.canopytrees - 1
        --player:PushEvent("onchangecanopyzone", player.canopytrees > 0)
    end
    inst.players[player] = nil
end

local function OnNear(inst, player)
    inst.players[player] = true
    player.canopytrees = (player.canopytrees or 0) + 1
    --player:PushEvent("onchangecanopyzone", player.canopytrees > 0)
end

local function OnRemoveEntity(inst)
    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.canopytrees then
                OnFar(inst, player)
            end
        end
    end
    inst._hascanopy:set(false)
end

local function makefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddDynamicShadow()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("shadecanopysmall")

    if not TheNet:IsDedicated() then
        local distancefade = inst:AddComponent("distancefade")
        distancefade:Setup(15, 25)

        local canopyshadows = inst:AddComponent("canopyshadows")
        canopyshadows.range = math.floor(TUNING.SHADE_CANOPY_RANGE_SMALL / 4)
		canopyshadows.um_canopyshadows = true

        inst:ListenForEvent("hascanopydirty", function()
            if not inst._hascanopy:value() then
                inst:RemoveComponent("canopyshadows")
            end
        end)
    end

    inst._hascanopy = net_bool(inst.GUID, "extracanopyspawner._hascanopy", "hascanopydirty")
    inst._hascanopy:set(true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.players = {}

    local playerprox = inst:AddComponent("playerprox")
    playerprox:SetTargetMode(playerprox.TargetModes.AllPlayers)
    playerprox:SetDist(MIN, MAX)
    playerprox:SetOnPlayerFar(OnFar)
    playerprox:SetOnPlayerNear(OnNear)

    local lightningblocker = inst:AddComponent("lightningblocker")
    lightningblocker:SetBlockRange(TUNING.SHADE_CANOPY_RANGE_SMALL)
    lightningblocker:SetOnLightningStrike(OnLightningStrike)

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("extracanopyspawner", makefn)
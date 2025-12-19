local assets =
{
    Asset("ANIM", "anim/um_gemforge.zip"),
}

local GEM_DEFS = require("gemology_defs").GEM_DEFS

local function ShouldAcceptItem(inst, item)
    if (item.components.gem_enchantable and item.components.gem_enchantable:HasSlots() or GEM_DEFS[item.prefab] ~= nil) then
        return true
    end
end

local ALLPLAYERS_CHECK_RADIUS_SQ = 16 * 16

local function LearnGem(inst)

    local x, y, z = inst.Transform:GetWorldPosition()

    local sender_list = {}
    for k, v in pairs(AllPlayers) do
        if v:GetDistanceSqToPoint(x, y, z) <= ALLPLAYERS_CHECK_RADIUS_SQ then
            table.insert(sender_list, v.userid)
        end
    end

    SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "LearnGemologyGem"), sender_list, json.encode({ gem = inst.gem.prefab, tier = 1 }))
end

local function TrueForge(inst)
    inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
    inst.SoundEmitter:PlaySound("dontstarve/HUD/collect_newitem")
    --TODO: GEM DURABILITY
    --local should_use_durability = false
    if inst.forge_tool.components.gem_enchantable ~= nil and inst.forge_tool.components.gem_enchantable:HasSlots() then
        inst.forge_tool.components.gem_enchantable:AddEnchantment(inst.gem.prefab, inst.gem:GetTier())
    end

    LearnGem(inst)

    inst.gem:Remove()
    inst.gem = nil
    inst.forge_tool = nil

    inst.components.inventory:DropEverything()

    inst._gem:Remove()
    inst._gem = nil

    inst._forge_tool:Remove()
    inst._forge_tool = nil
end

local function Forge(inst)
    inst._forge_tool.components.pickable.canbepicked = true
    inst._gem.components.pickable.canbepicked = true

    inst.AnimState:PlayAnimation("smith", false)
    inst.AnimState:PushAnimation("idle", false)
    inst:DoTaskInTime(0.8, TrueForge)
end

local function ShowGem(inst)
    inst._gem = SpawnPrefab(inst.gem.prefab)
    if inst._gem ~= nil then
        inst._gem.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst._gem.components.inventoryitem.canbepickedup = false
        inst._gem.entity:SetParent(inst.entity)
        inst._gem.entity:AddFollower()
        inst._gem.entity:AddFollower():FollowSymbol(inst.GUID, "gem", 0, 20, 0)
        inst._gem:AddComponent("pickable")
        inst._gem.components.pickable.canbepicked = true
        inst._gem.components.pickable.onpickedfn = function()
            inst._gem:Remove()
            inst._gem = nil
            inst.components.inventory:DropEverything()
        end
    end
end

local function ShowTool(inst)
    inst._forge_tool = SpawnPrefab(inst.forge_tool.prefab)
    if inst._forge_tool ~= nil then
        inst._forge_tool.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst._forge_tool.components.inventoryitem.canbepickedup = false
        inst._forge_tool.entity:SetParent(inst.entity)
        inst._forge_tool.entity:AddFollower()
        inst._forge_tool.entity:AddFollower():FollowSymbol(inst.GUID, "smithed_tool", 0, 40, 0)
        inst._forge_tool:AddComponent("pickable")
        inst._forge_tool.components.pickable.canbepicked = true
        inst._forge_tool.components.pickable.onpickedfn = function()
            inst._forge_tool:Remove()
            inst._forge_tool = nil
            inst.components.inventory:DropEverything()
        end
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item:HasTag("gemology_gem") then
        if inst.gem and inst._gem then
            inst._gem:Remove()
            inst._gem = nil
            inst.components.inventory:DropItem(inst.gem, true, true)
            inst.gem = nil
        end
        inst.gem = item
        ShowGem(inst)
        if inst.forge_tool then
            Forge(inst)
        end
    end
    if item.components.equippable then
        if inst.forge_tool and inst._forge_tool then
            inst._forge_tool:Remove()
            inst._forge_tool = nil
            inst.components.inventory:DropItem(inst.forge_tool, true, true)
            inst.forge_tool = nil
        end
        inst.forge_tool = item
        ShowTool(inst)
        if inst.gem then
            Forge(inst)
        end
    end
end

local function OnSave(inst, data)
    inst.components.inventory:DropEverything()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)
    -- local minimap = inst.entity:AddMiniMapEntity() -- Add back later...
    -- inst.MiniMapEntity:SetIcon("houndious_observious_map.tex")

    inst.AnimState:SetBank("um_gemforge")
    inst.AnimState:SetBuild("um_gemforge")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("structure")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("trader")
    inst:AddComponent("inventory")

    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.deleteitemonaccept = false

    inst.OnSave = OnSave
    return inst
end


return Prefab("um_gemologyforge", fn, assets)

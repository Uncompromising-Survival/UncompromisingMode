local assets =
{
    Asset("ANIM", "anim/um_gemologygems.zip"),
}
local GEM_DEFS = require("gemology_defs").GEM_DEFS
local function OnSave(inst, data)
    data.tier = inst:GetTier()
    data.revealed = inst:IsRevealed()
end

local function OnLoad(inst, data)
    if data then
        if data.tier ~= nil then
            inst:SetTier(data.tier)
        end
        if data.revealed ~= nil then
            inst:SetRevealed(data.revealed)
        end
    end
end

function IsGemKnown(inst)
    if TheNet:IsDedicated() then
        return true
    end

    return TheMineralLogbook:IsGemKnown(inst.prefab)
end

local function IsRevealed(inst)
    return inst._is_revealed:value()
end

local function SetRevealed(inst, reveal)
    if reveal ~= nil then
        inst._is_revealed:set(reveal)
    end
end

local function GetTierPrefix(inst)
    if not IsRevealed(inst) then return "" end

    return STRINGS.NAMES.UM_GEMOLOGYGEM_PREFIX[inst:GetTier()] .. " "
end

local function GetMainName(inst)
    local known, tier = IsGemKnown(inst)
    --only reveal name

    local color = "DEFAULT"
    if string.find(inst.prefab, "um_gemology") ~= nil then --just UM has the color stuff idk if any addons will apply, so we'll use the default.
        color = string.upper(string.gsub(string.gsub(inst.prefab, "um_gemology", ""), "gem%d", ""))
    end

    return (tier ~= nil and tier > 0 or not known) and STRINGS.NAMES[string.upper(inst.prefab)] or STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN[color]
end

local function Shine(inst)
    if not inst:HasTag("INLIMBO") and not inst:IsAsleep() and inst:IsRevealed() then
        local fx = SpawnPrefab("crab_king_shine")
        fx.Transform:SetScale(0.25, 0.25, 0.25)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "symbol0", 0, -100, 0)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end

    if inst.tier == 3 then
        inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, Shine)
    end
end

local function GetDisplayName(inst)
    return GetTierPrefix(inst) .. GetMainName(inst)
end

local function SetTier(inst, tier)
    inst._tier:set(tier)

    if inst.tier ~= nil then
        inst.tier = tier

        if inst.tier == 3 and inst:IsRevealed() then
            inst.shinetask = inst:DoTaskInTime(0, Shine)
        end
    end
end

local function GetTier(inst)
    if not TheWorld.ismastersim then
        return inst._tier:value()
    end

    return inst.tier
end

local function OnEntityWake(inst)
    if inst.shinetask == nil and inst.tier == 3 then
        inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, Shine)
    end
end

local function OnWorked(inst)
    local fx = SpawnPrefab("winona_battery_high_shatterfx")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx.AnimState:PlayAnimation("opalgem_shatter")

    --local dust = SpawnPrefab("um_gemologygemdust")
    --dust.Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:Remove()
end

local function OnDestack(new, inst)
    new:SetTier(inst:GetTier())
    new:SetRevealed(inst:IsRevealed())
end

local function MakeGem(gem, bank, build, anim, postfn)
    local function fncommon()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.entity:AddSoundEmitter()

        MakeInventoryPhysics(inst)
        RemovePhysicsColliders(inst)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        --client-side netvar for tier
        inst._tier = net_shortint(inst.GUID, "gemologygem.tier")
        --tiers go from 1-3
        inst._tier:set(1)

        inst._is_revealed = net_bool(inst.GUID, "gemologygem.is_revealed") --no real need for a dirty event
        inst._is_revealed:set(false)

        inst.displaynamefn = GetDisplayName
        inst.GetTier = GetTier
        inst.SetTier = SetTier
        inst.SetRevealed = SetRevealed
        inst.IsRevealed = IsRevealed

        inst:AddTag("gemology_gem")

        inst.pickupsound = "gem"

        inst.entity:SetPristine()

        --THANK YOU KLEI
        --also this needs to be on common side.
        inst.stackable_CanStackWithFn = function(inst, item)
            if inst:HasTag("gemology_gem") and item:HasTag("gemology_gem") and inst.GetTier ~= nil and item.GetTier ~= nil and inst.IsRevealed ~= nil and item.IsRevealed ~= nil then
                return inst:GetTier() == item:GetTier() and item:IsRevealed() == inst:IsRevealed()
            end
        end

        inst:DoTaskInTime(0, function(inst)
            if postfn ~= nil then
                postfn(inst)
            end
        end)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:ListenForEvent("reveal_gem", function(inst, data)
            inst._is_revealed:set(true)
            SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "LearnGemologyGem"), { data.doer.userid }, json.encode({ gem = inst.prefab, tier = inst:GetTier() }))
        end)

        inst.tier = 1

        inst:DoTaskInTime(0, function(inst)
            if inst.tier == 3 then
                inst.shinetask = inst:DoTaskInTime(0, Shine)
            end
        end)

        --dummy comp for insight.
        inst:AddComponent("gemology_gem")

        inst:AddComponent("inspectable")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnWorked)

        inst:AddComponent("inventoryitem")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = 10 --? idk.
        inst.components.stackable:SetOnDeStack(OnDestack)


        inst:AddComponent("tradable")
        inst.components.tradable.rocktribute = 8

        inst:AddComponent("edible")
        inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
        inst.components.edible.hungervalue = 10

        MakeHauntableLaunch(inst)

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnEntityWake = OnEntityWake



        return inst
    end

    return Prefab(gem, fncommon, assets)
end

local prefabs = {}

for gem, defs in pairs(GEM_DEFS) do
    if defs.createprefab then
        table.insert(prefabs, MakeGem(gem, defs.bank, defs.build, defs.anim, defs.postfn), assets)
    end
end

return unpack(prefabs)

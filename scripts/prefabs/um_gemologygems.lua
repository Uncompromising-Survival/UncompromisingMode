local assets =
{
    Asset("ANIM", "anim/um_gemologygems.zip"),
}
local gems = { "bluegem", "redgem", "purplegem", "orangegem", "yellowgem", "palegem" }


local function OnSave(inst, data)
    data.tier = inst:GetTier()
    data.revealed = inst:IsRevealed()
    return data
end

local function OnLoad(inst, data)
    if data and data.tier then
        --wait for netvar to init, just in case
        inst:DoTaskInTime(0, function(inst)
            inst:SetTier(data.tier)
            inst:SetRevealed(data.revealed)
        end)
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
    inst._is_revealed:set(reveal)
end

local function GetTierPrefix(inst)
    if not IsRevealed(inst) then return "" end

    return STRINGS.NAMES.UM_GEMOLOGYGEM_PREFIX[inst:GetTier()].." "
end

local function GetMainName(inst)
    local known, tier = IsGemKnown(inst)
    --only reveal name
    return (tier ~= nil and tier > 0 or not known) and STRINGS.NAMES[string.upper(inst.prefab)] or STRINGS.NAMES.UM_GEMOLOGYGEM_UNKNOWN
end

local function Shine(inst)
    if not inst:HasTag("INLIMBO") and not inst:IsAsleep() then
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

        if inst.tier == 3 then
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

local function fncommon(gem)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("um_gemologygems")
    inst.AnimState:SetBuild("um_gemologygems")
    inst.AnimState:PlayAnimation(gem)

    --client-side netvar for tier
    inst._tier = net_shortint(inst.GUID, "gemologygem.tier")
    --tiers go from 1-3
    inst._tier:set(1)

    inst._is_revealed = net_bool(inst.GUID, "gemologygem.is_revealed") --no real need for a dirt event
    inst._is_revealed:set(false)                                       --TODO: TEMP VALUE

    inst.displaynamefn = GetDisplayName
    inst.GetTier = GetTier
    inst.SetTier = SetTier
    inst.SetRevealed = SetRevealed
    inst.IsRevealed = IsRevealed
    
    inst:AddTag("gemology_gem")

    inst.entity:SetPristine()

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


    MakeHauntableLaunch(inst)

    inst:AddComponent("inspectable")

    MakeHauntableLaunchAndIgnite(inst)

    inst:AddComponent("inventoryitem")


    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnEntityWake = OnEntityWake

    return inst
end

local function FullReturn(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

local function fnblue1()
    local inst = fncommon("bluegem1")
    return FullReturn(inst)
end
local function fnblue2()
    local inst = fncommon("bluegem2")
    return FullReturn(inst)
end
local function fnred1()
    local inst = fncommon("redgem1")
    return FullReturn(inst)
end
local function fnred2()
    local inst = fncommon("redgem2")
    return FullReturn(inst)
end
local function fnpurple1()
    local inst = fncommon("purplegem1")
    return FullReturn(inst)
end
local function fnpurple2()
    local inst = fncommon("purplegem2")
    return FullReturn(inst)
end
local function fnyellow1()
    local inst = fncommon("yellowgem1")
    return FullReturn(inst)
end
local function fnyellow2()
    local inst = fncommon("yellowgem2")
    return FullReturn(inst)
end
local function fngreen1()
    local inst = fncommon("greengem1")
    return FullReturn(inst)
end
local function fngreen2()
    local inst = fncommon("greengem2")
    return FullReturn(inst)
end
local function fnorange1()
    local inst = fncommon("orangegem1")
    return FullReturn(inst)
end
local function fnorange2()
    local inst = fncommon("orangegem2")
    return FullReturn(inst)
end
local function fnpale1()
    local inst = fncommon("palegem1")
    return FullReturn(inst)
end
local function fnpale2()
    local inst = fncommon("palegem2")
    return FullReturn(inst)
end

-- If any kind soul could convert this into a "for" loop, I'd appreciate it, I couldn't get it to work around the return, would cause a crash.
return Prefab("um_gemologybluegem1", fnblue1, assets),
    Prefab("um_gemologybluegem2", fnblue2),
    Prefab("um_gemologyredgem1", fnred1),
    Prefab("um_gemologyredgem2", fnred2),
    Prefab("um_gemologypurplegem1", fnpurple1),
    Prefab("um_gemologypurplegem2", fnpurple2),
    Prefab("um_gemologyyellowgem1", fnyellow1),
    Prefab("um_gemologyyellowgem2", fnyellow2),
    Prefab("um_gemologygreengem1", fngreen1),
    Prefab("um_gemologygreengem2", fngreen2),
    Prefab("um_gemologyorangegem1", fnorange1),
    Prefab("um_gemologyorangegem2", fnorange2),
    Prefab("um_gemologypalegem1", fnpale1),
    Prefab("um_gemologypalegem2", fnpale2)

local function CopyItemSymbol(inst, owner, item, symbolToOverride)
    if item == nil then return end
    local build, symbol = owner.AnimState:GetSymbolOverride(symbolToOverride)
    local skinBuild = item:GetSkinBuild()
    local skinBuildSymbol = item.wieneke_ownerOverrideItemSkinSymbol_buildSymbol

    if skinBuild == nil or skinBuildSymbol == nil then
        if build ~= nil and symbol ~= nil then
            inst.AnimState:OverrideSymbol(symbolToOverride, build, symbol)
        end
    else
        inst.AnimState:OverrideItemSkinSymbol(symbolToOverride, skinBuild, skinBuildSymbol, item.GUID, skinBuildSymbol)
    end
end

local function Start(inst, owner, fadeDuration, anim, animPercent, startOpacity)
    local colourtweener = inst ~= nil and inst.components.colourtweener or nil
    if colourtweener == nil or anim == nil then return end

    if inst.wathom_trace_fx_removeTask ~= nil then
        inst.wathom_trace_fx_removeTask:Cancel()
    end

    -- Hide/show the arm carry and items as well.
    local ownerInventory = owner.components.inventory
    local handItem = ownerInventory ~= nil and ownerInventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local bodyItem = ownerInventory ~= nil and ownerInventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    local headItem = ownerInventory ~= nil and ownerInventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    CopyItemSymbol(inst, owner, handItem, "swap_object")
    CopyItemSymbol(inst, owner, bodyItem, "swap_body")
    CopyItemSymbol(inst, owner, headItem, "headbase_hat")
    CopyItemSymbol(inst, owner, headItem, "swap_hat")

    inst.AnimState:Show(handItem ~= nil and "ARM_carry" or "ARM_normal")
    inst.AnimState:Hide(handItem ~= nil and "ARM_normal" or "ARM_carry")

    -- Do fx!
    inst.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.Transform:SetRotation(owner.Transform:GetRotation())
    inst.AnimState:SetPercent(anim, animPercent)

    inst:DoTaskInTime(0, function()
        colourtweener:StartTween({ 1, 1, 1, startOpacity or 1 }, fadeDuration * 0.3, function()
            inst:DoTaskInTime(0, function()
                colourtweener:StartTween({ 1, 1, 1, 0 }, fadeDuration * 0.7, inst.Remove)
            end)
        end)
    end)
end

local function CommonInit()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wathom")
    inst.AnimState:PlayAnimation("idle")
    inst.Transform:SetFourFaced()
    inst.AnimState:UsePointFiltering(true)
    inst.AnimState:SetLightOverride(0.5)
    --inst.AnimState:SetMultColour(1, 1, 1, 0)
    inst.AnimState:SetFinalOffset(-1)
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colourtweener")

    local skinner = inst:AddComponent("skinner")
    skinner:SetupNonPlayerData()

    inst.wathom_trace_fx_removeTask = inst:DoTaskInTime(1, inst.Remove)
    inst.persists = false
    inst.Start = Start

    -- Ok, idk. Ownership check fails for modded base skins? Tell it to ignore the player head when we copy skins.
    local _CopySkinsFromPlayer = skinner.CopySkinsFromPlayer
    skinner.CopySkinsFromPlayer = function(_, player, ...)
        local playerSkinner = player.components.skinner
        local _PlayerGetClothing = playerSkinner.GetClothing

        playerSkinner.GetClothing = function(...)
            local ret = _PlayerGetClothing(...)
            if ret ~= nil and ret.base == "wathom_none" then ret.base = "" end
            return ret
        end

        local ret = _CopySkinsFromPlayer(_, player, ...)
        playerSkinner.GetClothing = _PlayerGetClothing
        return ret
    end

    return inst
end

return Prefab("um_wathom_trace", CommonInit)

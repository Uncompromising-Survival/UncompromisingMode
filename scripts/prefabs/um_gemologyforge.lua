local assets =
{
    Asset("ANIM", "anim/um_gemforge.zip"),
    Asset("IMAGE", "images/map_icons/um_gemologyforge.tex"),
    Asset("ATLAS", "images/map_icons/um_gemologyforge.xml"),
}

local GEM_DEFS = require("gemology_defs").GEM_DEFS

local ALLPLAYERS_CHECK_RADIUS_SQ = 16 * 16

local function LearnGem(inst, gem_name)
    local x, y, z = inst.Transform:GetWorldPosition()

    local sender_list = {}
    for k, v in pairs(AllPlayers) do
        if v:GetDistanceSqToPoint(x, y, z) <= ALLPLAYERS_CHECK_RADIUS_SQ then
            table.insert(sender_list, v.userid)
        end
    end

    SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "LearnGemologyGem"), sender_list, json.encode({ gem = gem_name, tier = 1 }))
end

local function CanApplyGem(gem, tool)
    local fn = GEM_DEFS[gem].fns.canapply
    return fn ~= nil and fn(tool) or fn == nil
end

local function ForgeGem(inst)
    local tool = inst.components.container:GetItemInSlot(1)
    local gem = inst.components.container:GetItemInSlot(2)
    local can_apply = CanApplyGem(gem.prefab, tool)
    if tool.components.gem_enchantable ~= nil and GEM_DEFS[gem.prefab] ~= nil and can_apply then
        inst.components.container:Close()
        inst.AnimState:PlayAnimation("smith", false)
        inst.AnimState:PushAnimation("idle", false)
        inst.components.container.canbeopened = false
        inst:DoTaskInTime(.8, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
            --remove enchants if you're at max slots.
            if not tool.components.gem_enchantable:HasSlots() then
                for enchant, tier in pairs(tool.components.gem_enchantable.enchants) do
                    tool.components.gem_enchantable:RemoveEnchantment(enchant)
                end
            end
            tool.components.gem_enchantable:AddEnchantment(gem.prefab, gem:GetTier())
            tool.components.gem_enchantable:SetDurability(gem.prefab, 1)

            LearnGem(inst, gem.prefab)
            gem:Remove()
            inst.components.container.canbeopened = true
            --inst.components.container:DropEverything()
        end)
        return true
    end

    return false, (not can_apply) and "NOT_COMPATIBLE" or nil
end

--{ slot = in_slot, item = item, src_pos = src_pos, }
function ShowItems(inst, data)
    --delay a frame.
    inst:DoTaskInTime(0, function(inst)
        if inst.tool_fx ~= nil then
            inst.tool_fx:Remove()
            inst.tool_fx = nil
        end

        if inst.gem_fx ~= nil then
            inst.gem_fx:Remove()
            inst.gem_fx = nil
        end


        local tool = inst.components.container:GetItemInSlot(1)
        local gem = inst.components.container:GetItemInSlot(2)

        if tool ~= nil then
            inst.tool_fx = SpawnPrefab(tool.prefab, tool.skinname, tool.skin_id)
            inst.tool_fx:RemoveAllEventCallbacks()
            inst.tool_fx.components.inventoryitem.canbepickedup = false

            inst.tool_fx.persists = false
            inst.tool_fx.AnimState:SetBank(tool.AnimState:GetCurrentBankName())
            inst.tool_fx.AnimState:SetBuild(tool.AnimState:GetBuild())
            inst.tool_fx:AddTag("FX")
            inst.tool_fx.entity:SetParent(inst.entity)
            inst.tool_fx:AddComponent("highlightchild")


            local follower = inst.tool_fx.entity:AddFollower()
            follower:FollowSymbol(inst.GUID, "smithed_tool", 0, 40, 0)
        end

        if gem ~= nil then
            inst.gem_fx = SpawnPrefab(gem.prefab)
            inst.gem_fx:RemoveAllEventCallbacks()
            inst.gem_fx.components.inventoryitem.canbepickedup = false

            inst.gem_fx.persists = false
            inst.gem_fx.AnimState:SetBank(gem.AnimState:GetCurrentBankName())
            inst.gem_fx.AnimState:SetBuild(gem.AnimState:GetBuild())
            inst.gem_fx:AddTag("FX")
            inst.gem_fx:AddComponent("highlightchild")

            inst.gem_fx.entity:SetParent(inst.entity)
            local follower = inst.gem_fx.entity:AddFollower()
            follower:FollowSymbol(inst.GUID, "gem", 0, 20, 0)
        end
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)
    inst.MiniMapEntity:SetIcon("um_gemologyforge.tex")

    inst.AnimState:SetBank("um_gemforge")
    inst.AnimState:SetBuild("um_gemforge") --TODO: IA VISUAL VARIANT
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("structure")
    inst:AddTag("gem_forge")
    
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("gem_forge")

    inst.ForgeGem = ForgeGem

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("um_gemologyforge")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.acceptsstacks = false
    inst:ListenForEvent("itemget", ShowItems)
    inst:ListenForEvent("itemlose", ShowItems)

    ShowItems(inst)

    return inst
end

return Prefab("um_gemologyforge", fn, assets)

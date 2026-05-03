STRINGS = GLOBAL.STRINGS

local env = env
GLOBAL.setfenv(1, GLOBAL)

--Classic DS Red Amulet revive (only when worn upon death), and health tick changes

local function CLIENT_PlayFuelSound(inst)
    local parent = inst.entity:GetParent()
    local container = parent and (parent.replica.inventory or parent.replica.container)
    if container and container:IsOpenedBy(ThePlayer) then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    end
end

local function SERVER_PlayFuelSound(inst)
    local owner = inst.components.inventoryitem.owner
    if not owner then
        inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter then
        owner.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
    else
        inst.playfuelsound:push()
        --Dedicated server does not need to trigger sfx
        if not TheNet:IsDedicated() then
            CLIENT_PlayFuelSound(inst)
        end
    end
end

local function AmuletPostInit(inst)
    local function healowner(inst, owner)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner

        local amusement
        if owner.prefab == "um_backpack_amuletuse" then -- AXE Need to redirect!
            amusement = true
            owner = owner.components.inventoryitem and owner.components.inventoryitem.owner and owner.components.inventoryitem.owner or owner
        end 

        if inst.components.fueled and inst.components.fueled:IsEmpty() then
            if inst.task then
                inst.task:Cancel()
                inst.task = nil
            end
            return
        end

        if (owner.components.health and owner.components.health:IsHurt())
            and (owner.components.hunger and owner.components.hunger.current > 5) and not owner:HasTag("deathamp") and not owner.components.oldager then
            owner.components.health:DoDelta((amusement and 1.5 or 1) * TUNING.REDAMULET_CONVERSION, false, "redamulet")
            owner.components.hunger:DoDelta(-TUNING.REDAMULET_CONVERSION)
            inst.components.fueled:DoDelta(-18)

            local healtime = 10

            if owner.components.health and owner.components.health:GetPercent() <= 0.5 then
                healtime = 0.33 + (8 * owner.components.health:GetPercent())
            end

            inst.task = inst:DoTaskInTime(healtime, healowner, owner)
        end
    end

    local function onequip_red(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "torso_amulets")
        else
            owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "redamulet")
        end

        local healtime = 10

        if owner.components.health and owner.components.health:GetPercent() <= 0.5 then
            healtime = 1 + (8 * owner.components.health:GetPercent())
        end
        inst.task = inst:DoTaskInTime(healtime, healowner, nil, owner)
        --inst.task = inst:DoPeriodicTask(10, healowner, nil, owner)
    end

    local function onunequip_red(inst, owner)
        if not owner.sg or owner.sg.currentstate.name ~= "amulet_rebirth" then
            owner.AnimState:ClearOverrideSymbol("swap_body")
        end

        local skin_build = inst:GetSkinBuild()
        if skin_build then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end

        if inst.task then
            inst.task:Cancel()
            inst.task = nil
        end
    end

    local function nofuel_red(inst)
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
    end

    local function ontakefuel_red(inst)
        SERVER_PlayFuelSound(inst)
        if inst.components.equippable and inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner

            if not inst.task and owner and not owner:HasTag("deathamp") and not owner.components.oldager then --don't bother healing a dead man walking or the person who cannot heal.
                local healtime = 10

                if owner.components.health and owner.components.health:GetPercent() <= 0.5 then
                    healtime = 1 + (8 * owner.components.health:GetPercent())
                end

                inst.task = inst:DoTaskInTime(healtime, healowner, owner)
            end
        end
    end

    inst:RemoveComponent("finiteuses")

    local fueled = inst:AddComponent("fueled")
    fueled:InitializeFuelLevel(TUNING.LARGE_FUEL * 2)
    fueled.fueltype = FUELTYPE.NIGHTMARE
    fueled:SetDepletedFn(nofuel_red)
    fueled:SetTakeFuelFn(ontakefuel_red)
    fueled.accepting = true

    local equippable = inst.components.equippable
    if equippable then
        equippable:SetOnEquip(onequip_red)
        equippable:SetOnUnequip(onunequip_red)
    end

    inst:RemoveComponent("hauntable")
end

env.AddPrefabPostInit("amulet", function(inst)
    inst.playfuelsound = net_event(inst.GUID, "amulet.playfuelsound")

    if not TheWorld.ismastersim then
        --delayed because we don't want any old events
        inst:DoTaskInTime(0, inst.ListenForEvent, "amulet.playfuelsound", CLIENT_PlayFuelSound)

        return
    end

    AmuletPostInit(inst)
end)

--[[local function AmuletResurrectPostInit(inst)
    local function amulet_resurrect(inst)
        if inst.components.inventory and inst.components.inventory.equipslots then
            for k, v in pairs(inst.components.inventory.equipslots) do
                if v.prefab == "amulet" then
                    inst:ListenForEvent("animover", function(inst)
                        inst:PushEvent(inst:HasTag("playerghost") and "respawnfromghost" or "respawnfromcorpse", {source = v})
                        v.AnimState:SetMultColour(0, 0, 0, 0) --go invis
                        v:AddTag("NOCLICK")
                        v:AddTag("NOBLOCK")
                        v.components.inventoryitem.canbepicked = false
                        v:DoTaskInTime(5, v.Remove) --lenient time
                    end)
                end
            end
        end
    end

    inst:ListenForEvent("death", amulet_resurrect)
end

env.AddPlayerPostInit(function(inst)
	AmuletResurrectPostInit(inst)
end)]]
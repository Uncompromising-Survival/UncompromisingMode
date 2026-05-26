local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function onlightningground(inst)
    inst.components.fueled:DoDelta(TUNING.MED_FUEL)
    inst.components.fueled.ontakefuelfn(inst, TUNING.SMALL_FUEL)
    if inst.components.fueled:GetPercent() > 1 then
        inst.components.fueled:SetPercent(1)
    end
end

local function Strike(owner)
    --onlightningground(inst)

    if owner ~= nil then
        local fx = SpawnPrefab("electrichitsparks")

        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -145, 0)
        --fx.Transform:SetScale(.66, .66, .66)
        local item = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        item.components.fueled:DoDelta(TUNING.MED_FUEL)
        item.components.fueled.ontakefuelfn(item, TUNING.SMALL_FUEL)
        if item.components.fueled:GetPercent() > 1 then
            item.components.fueled:SetPercent(1)
        end
    end
end

env.AddPrefabPostInit("nightstick", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _onequip = inst.components.equippable.onequipfn
    local _onunequip = inst.components.equippable.onunequipfn

    inst.components.equippable:SetOnEquip(function(inst, owner)
        _onequip(inst, owner)

        owner:AddTag("lightningrod")
        owner.lightningpriority = 0
        owner:ListenForEvent("lightningstrike", Strike, owner)
    end)

    inst.components.equippable:SetOnUnequip(function(inst, owner)
        _onunequip(inst, owner)

        owner:RemoveTag("lightningrod")
        owner.lightningpriority = nil
        owner:ListenForEvent("lightningstrike", nil)
    end)

    if inst.components.fueled ~= nil then
        inst.components.fueled.fueltype = FUELTYPE.BATTERYPOWER
        inst.components.fueled.accepting = true
        inst.components.fueled.rate = 1

        inst:AddTag("lightningrod")
        inst:ListenForEvent("lightningstrike", onlightningground)
    end
end)

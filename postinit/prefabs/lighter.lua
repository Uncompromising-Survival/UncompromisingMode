GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local require = GLOBAL.require
local assert = GLOBAL.assert

local function turnon(inst)
    if not inst.components.fueled:IsEmpty() then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_on")
        inst.components.fueled:StartConsuming()
        inst:AddComponent("lighter")

        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil

        -- turn on fire fx
        if inst.fires == nil then
        inst.fires = {}

            for i, fx_prefab in ipairs(inst:GetSkinName() == nil and { "lighterfire" } or SKIN_FX_PREFAB[inst:GetSkinName()] or {}) do
                local fx = SpawnPrefab(fx_prefab)
                fx.entity:SetParent(owner.entity)
                fx.entity:AddFollower()
                fx.Follower:FollowSymbol(owner.GUID, "swap_object", fx.fx_offset_x, fx.fx_offset_y, 0)
                fx:AttachLightTo(owner)

                table.insert(inst.fires, fx)
            end
        end
    end
end

local function turnoff(inst)
    --inst.SoundEmitter:KillSound("torch")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end

    inst:RemoveComponent("lighter")

    -- turn off fire fx
    if inst.fires ~= nil then
        for i, fx in ipairs(inst.fires) do
            fx:Remove()
        end
        inst.fires = nil
    end

    inst.components.burnable:Extinguish()
end

local function onfuelchange(newsection, oldsection, inst)
    if newsection <= 0 then
        --when we burn out
        if inst.components.burnable ~= nil then
            inst.components.burnable:Extinguish()
        end
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                    announce = "ANNOUNCE_TORCH_OUT",
                }

                if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("willow_embers") then
                    turnoff(inst)
                else
                    inst:Remove()
                end
                owner:PushEvent("itemranout", data)
                return
            end
            inst:Remove()
        end
    end
end

local function ondepleted(inst)
    local equippable = inst.components.equippable
    if equippable ~= nil and equippable:IsEquipped() then
        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if owner ~= nil then
            local data =
            {
                prefab = inst.prefab,
                equipslot = equippable.equipslot,
                announce = "ANNOUNCE_TORCH_OUT",
            }

            if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("willow_embers") then
                turnoff(inst)
            else
                inst:Remove()
            end         
            owner:PushEvent("itemranout", data)
            return
        end
        inst:Remove()
    end
end

AddPrefabPostInit("lighter", function(inst)
    if not TheWorld.ismastersim then
		return
	end

    oldonattack = inst.components.weapon.onattack
    inst.components.weapon:SetOnAttack(function(weapon, attacker, target)
        if not inst.components.fueled:IsEmpty() then
            oldonattack(weapon, attacker, target)
        end
    end)

    oldonequip = inst.components.equippable.onequipfn
    inst.components.equippable:SetOnEquip(function(inst, owner)
        oldonequip(inst, owner)
        if inst.components.fueled:IsEmpty() then
            turnoff(inst)
        end
    end)

    inst.components.fueled:SetDepletedFn(ondepleted)
    inst.components.fueled:SetSectionCallback(onfuelchange)

    local oldontakefuel = inst.components.fueled.ontakefuelfn
    inst.components.fueled:SetTakeFuelFn(function(inst, owner)
        oldontakefuel(inst, owner)
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            turnon(inst)
        end
    end)
end)
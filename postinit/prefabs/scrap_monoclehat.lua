local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("scrap_monoclehat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnEquip = inst.components.equippable.onequipfn
    inst.components.equippable.onequipfn = function(inst, owner)
        _OnEquip(inst, owner)
        if not owner.mapexplorerbonus then
            -- Increases map exploration radius
            local radius = 3 * 10
            local intervals = 25
            local theta = 0
            owner.mapexplorerbonus = owner:DoPeriodicTask(FRAMES, function()
                local pt = Vector3(owner.Transform:GetWorldPosition())
                local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
                theta = theta + (2 * PI / intervals)
                if owner.player_classified ~= nil then
                    owner.player_classified.MapExplorer:RevealArea((pt + offset):Get())
                    owner.player_classified.MapExplorer:RevealArea((pt - offset):Get())
                end
            end)
        end
    end

    local _OnUnequip = inst.components.equippable.onunequipfn
    inst.components.equippable.onunequipfn = function(inst, owner)
        _OnUnequip(inst, owner)
        if owner.mapexplorerbonus then
            owner.mapexplorerbonus:Cancel()
            owner.mapexplorerbonus = nil
        end
    end
end)

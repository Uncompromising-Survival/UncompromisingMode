local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------


env.AddPrefabPostInit("cave_vent_mite", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(0, function(inst)
        if math.random() > 0.5 and not inst.isGeode then
            inst.isGeode = true
            inst.AnimState:SetBuild("um_mite_cave")
            inst.components.lootdropper:AddChanceLoot("um_gemology_geode_vent", 1)
        end
    end)


    local _OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        if inst.isGeode then
            data.isGeode = true
        end

        if _OnSave ~= nil then
            return _OnSave(inst, data)
        end
        return data
    end

    local _OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if data and data.isGeode then
            inst.isGeode = true
        end

        if _OnLoad ~= nil then
            return _OnLoad(inst, data)
        end
    end
end)

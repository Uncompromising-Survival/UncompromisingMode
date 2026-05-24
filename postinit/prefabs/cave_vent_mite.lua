local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local UpvalueHacker = require("tools/upvaluehacker")

local function BecomeGemMite(inst)
    inst.isGeode = true
    inst.AnimState:SetBuild("um_mite_cave")
    inst.components.lootdropper:AddChanceLoot("um_gemology_geode_vent", 1)
end

env.AddPrefabPostInit("world", function(inst) -- Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not TheWorld.ismastersim then return end
    local _SetUpChanceLoot = UpvalueHacker.SetUpvalue(Prefabs.cave_vent_mite.fn, "SetShield", "SetUpChanceLoot")
    if _SetUpChanceLoot then
        local function SetUpChanceLoot(inst, ...)
            local ret = _SetUpChanceLoot(inst, ...)
            --print("is geode?", inst.isGeode)
            if inst.isGeode then
                --print("add gem vent")
                inst.components.lootdropper:AddChanceLoot("um_gemology_geode_vent", 1)
            end
            return ret
        end
        UpvalueHacker.SetUpvalue(inst.SetShield, SetUpChanceLoot, "SetUpChanceLoot")
    end
end)

env.AddPrefabPostInit("cave_vent_mite", function(inst)
    if not TheWorld.ismastersim then return end

    inst:DoTaskInTime(0, function(inst)
        if math.random() > .5 and not inst.isGeode then
            BecomeGemMite(inst)
        end
    end)

    local _OnSave = inst.OnSave
    inst.OnSave = function(inst, data, ...)
        if inst.isGeode then
            data.isGeode = true
        end

        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data, ...)
        if data and data.isGeode then
            BecomeGemMite(inst)
        end

        return _OnLoad and _OnLoad(inst, data, ...)
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local UpvalueHacker = require("tools/upvaluehacker")

local function BecomeGemMite(inst)
    inst.isGeode = true
    inst.AnimState:SetBuild("um_mite_cave")
    inst.components.lootdropper:AddChanceLoot("um_gemology_geode_vent", 1)
end

env.AddPrefabPostInit("cave_vent_mite", function(inst)
    if not TheWorld.ismastersim then return end

    local function SetUpChanceLoot(inst)
        inst.components.lootdropper.chanceloot = nil

        inst.components.lootdropper:AddChanceLoot("rocks", inst.shielded and 1.0 or .5)

        --print("is geode?", inst.isGeode)
        if inst.isGeode then
            --print("add gem vent")
            inst.components.lootdropper:AddChanceLoot("um_gemology_geode_vent", 1)
        end

        if inst.components.planarentity then
            inst.components.lootdropper:AddChanceLoot("horrorfuel", .5)
        end
    end

    UpvalueHacker.SetUpvalue(inst.SetShield, SetUpChanceLoot, "SetUpChanceLoot")

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
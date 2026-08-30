local env = env
GLOBAL.setfenv(1, GLOBAL)

local RETARGET_MUST_TAGS = {"_combat", "bat"}
local RETARGET_CANT_TAGS = {"INLIMBO", "player", "eyeturret", "engineering"}
local function umtargetfn(inst)
    local target = inst.components.combat.target
    if target and target:IsValid() and inst:IsNear(target, TUNING.EYETURRET_RANGE + 3) then
        --keep current target
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.EYETURRET_RANGE + 3, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS)
    for i, v in ipairs(ents) do
        if v ~= inst and v ~= target and v.entity:IsVisible() and inst.components.combat:CanTarget(v) then
            return v
        end
    end
    return nil
end

env.AddPrefabPostInit("eyeturret", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _retargetfn = inst.components.combat.targetfn
    inst.components.combat:SetRetargetFunction(1, function(_inst)
        return _retargetfn(_inst) or umtargetfn(_inst)
    end)
end)

local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")

local function GestaltHungrySleep(target)
    if target.components.grogginess and target.components.grogginess:IsKnockedOut() and target.components.hunger then
        target.components.hunger:DoDelta(-12.5)
        local fx = SpawnPrefab("abigail_gestalt_hit_fx")
        fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        fx.Transform:SetScale(0.4,0.4,0.4)
    else
        target.gestalt_hungry_sleep:Cancel()
        target.gestalt_hungry_sleep = nil
    end
end

local function HasSkill(inst,name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

env.AddStategraphPostInit("gestalt", function(inst)
    local attackstate = inst.states["attack"]
    local _DoSpecialAttack = attackstate and UpvalueHacker.GetUpvalue(attackstate.onupdate, "DoSpecialAttack")
    if _DoSpecialAttack then
        local function DoSpecialAttack(inst, target, ...)
            if target.components.hunger then -- additional hunger lost per hit
                target.components.hunger:DoDelta(-12.5)
            end
            if HasSkill(target,"wathom_allegiance_shadow") and target.components.health then
                target.components.health:DeltaPenalty(1/6)
            end
            --if grogginess then grogginess:SetPercent(1) end
            local ret = _DoSpecialAttack(inst, target, ...)
            target:DoTaskInTime(2, function(target)
                if target.components.grogginess and target.components.grogginess:IsKnockedOut() and not target.gestalt_hungry_sleep then
                    target.gestalt_hungry_sleep = target:DoPeriodicTask(2, GestaltHungrySleep)
                end
            end)
            return ret
        end
        UpvalueHacker.SetUpvalue(attackstate.onupdate, DoSpecialAttack, "DoSpecialAttack")
    end
end)
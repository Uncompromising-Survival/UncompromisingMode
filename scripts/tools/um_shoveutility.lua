--[[local UMShove = {}

local REPEL_RADIUS = 3
local REPEL_RADIUS_SQ = REPEL_RADIUS * REPEL_RADIUS

local function UpdateRepel(inst, x, z, creatures)
    for i = #creatures, 1, -1 do
        local v = creatures[i]
        if not (v.inst:IsValid() and v.inst.entity:IsVisible()) then
            table.remove(creatures, i)
        elseif v.speed == nil then
            local distsq = v.inst:GetDistanceSqToPoint(x, 0, z)
            if distsq < REPEL_RADIUS_SQ then
                if distsq > 0 then
                    v.inst:ForceFacePoint(x, 0, z)
                end
                local k = .5 * distsq / REPEL_RADIUS_SQ - 1
                v.speed = 25 * k
                v.dspeed = 2
                v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
            end
        else
            v.speed = v.speed + v.dspeed
            if v.speed < 0 then
                local x1, y1, z1 = v.inst.Transform:GetWorldPosition()
                if x1 ~= x or z1 ~= z then
                    v.inst:ForceFacePoint(x, 0, z)
                end
                v.dspeed = v.dspeed + .25
                v.inst.Physics:SetMotorVelOverride(v.speed, 0, 0)
            else
                v.inst.Physics:ClearMotorVelOverride()
                v.inst.Physics:Stop()
                table.remove(creatures, i)
            end
        end
    end
end

local function TimeoutRepel(inst, creatures, task)
    task:Cancel()

    for i, v in ipairs(creatures) do
        if v.speed ~= nil then
            v.inst.Physics:ClearMotorVelOverride()
            v.inst.Physics:Stop()
        end
    end
end

local SLEEPREPEL_MUST_TAGS = { "locomotor" }
local SLEEPREPEL_CANT_TAGS = { "fossil", "shadow", "playerghost", "INLIMBO" }

UMShove.ShoveSingle = function(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local creatures = {}
    if target.components.combat then
        if target.components.locomotor and target.Physics then
            table.insert(creatures, {inst = target})
        end
    end

    if #creatures > 0 then
        inst:DoTaskInTime(10 * FRAMES, TimeoutRepel, creatures, inst:DoPeriodicTask(0, UpdateRepel, nil, x, z, creatures))
    end
end

UMShove.Shove = function(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local creatures = {}
    for i, v in ipairs(TheSim:FindEntities(x, y, z, REPEL_RADIUS, SLEEPREPEL_MUST_TAGS, SLEEPREPEL_CANT_TAGS)) do
        if inst.components.combat:CanTarget(v) and not inst.components.combat:IsAlly(v) then
            if v.components.combat then
                v.components.combat:GetAttacked(inst, 10)
                if v.Physics then
                    table.insert(creatures, { inst = v })
                end
            end
        end
    end

    if #creatures > 0 then
        inst:DoTaskInTime(10 * FRAMES, TimeoutRepel, creatures, inst:DoPeriodicTask(0, UpdateRepel, nil, x, z, creatures))
    end
end

return UMShove]]
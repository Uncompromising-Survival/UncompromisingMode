local UMShove = {}

local function UpdateRepel(inst)
    local speed = inst.um_shovespeed
    if speed then
        speed = speed + inst.um_shovedspeed
        if speed < 0 then
            inst.um_shovespeed = speed
            inst.um_shovedspeed = inst.um_shovedspeed + 0.075
            inst.Physics:SetMotorVelOverride(inst.um_shovereverse and -speed or speed, 0, 0)
        else
            inst.um_shovespeed = nil
            inst.um_shovedspeed = nil
            inst.um_shovereverse = nil
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            inst:RestartBrain("um_shoving")
            if inst.um_shoveupdatetask then
                inst.um_shoveupdatetask:Cancel()
                inst.um_shoveupdatetask = nil
            end
        end
    end
end

local function DoRepel(inst, data)
    local x1, _, z1 = data.knocker.Transform:GetWorldPosition()
    local x, _, z = inst.Transform:GetWorldPosition()
    local dx = x1 - x
    local dz = z1 - z
    local dsq = dx * dx + dz * dz
    local rangesq = data.radius * data.radius
    local k = dsq < rangesq and 0.3 * dsq / rangesq - 1 or -0.7
    local speed = (data.strengthmult or 1) * 10 * k
    if speed < 0 then
        local rot = inst.Transform:GetRotation()
        local rot1 = dsq > 0 and math.atan2(-dz, dx) * RADIANS or data.knocker.Transform:GetRotation() + 180
        inst:StopBrain("um_shoving")
        local locomotor = inst.components.locomotor
        if locomotor then
            locomotor:Stop()
            locomotor:Clear()
        end
        if DiffAngle(rot, rot1) > 90 then
            inst.um_shovereverse = true
            inst.Transform:SetRotation(rot1 + 180)
            inst.Physics:SetMotorVelOverride(-speed, 0, 0)
        else
            inst.Transform:SetRotation(rot1)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
        end
        inst.um_shovespeed = speed
        inst.um_shovedspeed = 0
    end
    if inst.um_shoveupdatetask then inst.um_shoveupdatetask:Cancel() end
    inst.um_shoveupdatetask = inst:DoPeriodicTask(0, UpdateRepel)
end

--[[local function TimeoutRepel(inst)
    if inst.um_shovetimeouttask then
        inst.um_shovetimeouttask:Cancel()
        inst.um_shovetimeouttask = nil
    end

    if inst.um_shovetask then
        inst.um_shovetask:Cancel()
        inst.um_shovetask = nil
    end

    if inst.um_shovespeed then
        inst.Physics:ClearMotorVelOverride()
        inst.Physics:Stop()
        inst.um_shovespeed = nil
    end

    inst.um_shovedspeed = nil

    inst:RestartBrain("um_shoving")
end

local function UpdateRepel(inst, x, z, radiussq)
    if not inst.um_shovespeed then
        local distsq = inst:GetDistanceSqToPoint(x, 0, z)
        if distsq < radiussq then
            if distsq > 0 then
                inst:ForceFacePoint(x, 0, z)
            end
            local k = .5 * distsq / radiussq - 1
            inst.um_shovespeed = 25 * k
            inst.um_shovedspeed = 2
            inst:StopBrain("um_shoving")
            local locomotor = inst.components.locomotor
            if locomotor then
                locomotor:Stop()
                locomotor:Clear()
            end
            inst.Physics:SetMotorVelOverride(inst.um_shovespeed, 0, 0)
        end
    else
        inst.um_shovespeed = inst.um_shovespeed + inst.um_shovedspeed
        if inst.um_shovespeed < 0 then
            local x1, y1, z1 = inst.Transform:GetWorldPosition()
            if x1 ~= x or z1 ~= z then
                inst:ForceFacePoint(x, 0, z)
            end
            inst.um_shovedspeed = inst.um_shovedspeed + .25
            inst.Physics:SetMotorVelOverride(inst.um_shovespeed, 0, 0)
        else
            TimeoutRepel(inst)
        end
    end
end]]

function UMShove.SingleShove(inst, target, radius, x, z, range)
    if target.sg and target.sg.sg.events.knockback then
        target:PushEvent("knockback", {knocker = inst, radius = radius})
    elseif target.Physics then
        DoRepel(target, {knocker = inst, radius = radius})
        --[[TimeoutRepel(target)
        target.um_shovetask = target:DoPeriodicTask(0, UpdateRepel, nil, x, z, range * range)
        target.um_shovetimeouttask = target:DoTaskInTime(10 * FRAMES, TimeoutRepel)]]
    end
end

--[[local SLEEPREPEL_MUST_TAGS = { "locomotor" }
local SLEEPREPEL_CANT_TAGS = { "fossil", "shadow", "playerghost", "INLIMBO" }

function UMShove.Shove(inst, radius) -- WIP DON'T USE YET!
    local x, y, z = inst.Transform:GetWorldPosition()
    local creatures = {}
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, SLEEPREPEL_MUST_TAGS, SLEEPREPEL_CANT_TAGS)) do
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
        inst:DoTaskInTime(10 * FRAMES, TimeoutRepel, creatures, inst:DoPeriodicTask(0, UpdateRepel, nil, x, z, radius * radius, creatures))
    end
end]]

return UMShove
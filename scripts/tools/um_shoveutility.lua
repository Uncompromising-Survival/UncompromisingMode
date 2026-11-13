local UMShove = {}

local function UpdateRepel(inst)
    local speed = inst.um_shovespeed
    if speed then
        speed = speed + inst.um_shovedspeed
        if speed < 0 then
            inst.um_shovespeed = speed
            inst.um_shovedspeed = inst.um_shovedspeed + .075
            local angle = (inst.um_shoverot - inst.Transform:GetRotation()) * DEGREES
            inst.Physics:SetMotorVelOverride(speed * math.cos(angle), 0, -speed * math.sin(angle))
        else
            inst.um_shovespeed = nil
            inst.um_shovedspeed = nil
            inst.um_shoverot = nil
            inst.um_shoveposz = nil
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
    local k = dsq < rangesq and .3 * dsq / rangesq - 1 or -.7
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
        inst:ClearBufferedAction()
        local angle = (rot1 - rot) * DEGREES
        inst.Physics:SetMotorVelOverride(speed * math.cos(angle), 0, -speed * math.sin(angle))
        inst.um_shoverot = rot1
        inst.um_shovespeed = speed
        inst.um_shovedspeed = 0
    end
    if inst.um_shoveupdatetask then inst.um_shoveupdatetask:Cancel() end
    inst.um_shoveupdatetask = inst:DoPeriodicTask(0, UpdateRepel)
end

--local UMShove = require("tools/um_shoveutility") UMShove.DoShove(c_select(), {knocker = ThePlayer, radius = 3}) -- Debugging Purposes.
function UMShove.DoShove(target, data)
    if target.sg and target.sg.sg.events.knockback and not target.sg.mem.noknockback then
        target:PushEvent("knockback", data)
    elseif target.Physics then
        DoRepel(target, data)
    end
end

return UMShove
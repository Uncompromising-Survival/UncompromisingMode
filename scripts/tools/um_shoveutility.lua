local UMShove = {}

local function RemoveShoveEntity(inst)
    if inst.um_shoveentity and inst.um_shoveentity:IsValid() then
        inst.um_shoveentity:RemoveEventCallback("onremove", RemoveShoveEntity, inst)
        inst.um_shoveentity:Remove()
        inst.um_shoveentity = nil
    end
end

local function UpdateProperties(inst)
    local child = inst.um_child and inst.um_child:IsValid() and inst.um_child
    if child then inst:UMUpdateProperties(child, true) end
end

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
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            local child = inst.um_child and inst.um_child:IsValid() and inst.um_child
            if child then RemoveShoveEntity(child) end
            inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateProperties)
            inst.components.updatelooper:RemoveOnUpdateFn(UpdateRepel)
        end
    end
end

local function SpawnShoveEntity(inst, x, y, z)
    local shoveentity = SpawnPrefab("um_shoveentity")
    shoveentity:UMSetChild(inst, x, y, z)
    shoveentity:ListenForEvent("onremove", RemoveShoveEntity, inst)
    return shoveentity
end

local function DoRepel(inst, data)
    RemoveShoveEntity(inst)
    local x1, _, z1 = data.knocker.Transform:GetWorldPosition()
    local x, y, z = inst.Transform:GetWorldPosition()
    local dx = x1 - x
    local dz = z1 - z
    local dsq = dx * dx + dz * dz
    local rangesq = data.radius * data.radius
    local k = dsq < rangesq and .3 * dsq / rangesq - 1 or -.7
    local speed = (data.strengthmult or 1) * 10 * k
    if speed < 0 then
        inst.um_shoveentity = SpawnShoveEntity(inst, x, y, z)
        local rot = inst.um_shoveentity.Transform:GetRotation()
        local rot1 = dsq > 0 and math.atan2(-dz, dx) * RADIANS or data.knocker.Transform:GetRotation() + 180
        local angle = (rot1 - rot) * DEGREES
        inst.um_shoveentity.Physics:SetMotorVelOverride(speed * math.cos(angle), 0, -speed * math.sin(angle))
        inst.um_shoveentity.um_shoverot = rot1
        inst.um_shoveentity.um_shovespeed = speed
        inst.um_shoveentity.um_shovedspeed = 0
        inst.um_shoveentity.components.updatelooper:AddOnWallUpdateFn(UpdateProperties)
        inst.um_shoveentity.components.updatelooper:AddOnUpdateFn(UpdateRepel)
    end
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
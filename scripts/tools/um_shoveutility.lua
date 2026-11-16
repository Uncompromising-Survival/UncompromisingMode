local UMShove = {}

local function RemoveShoveEntity(inst)
    if inst.um_shoveentity and inst.um_shoveentity:IsValid() then
        inst.um_shoveentity:RemoveEventCallback("onremove", RemoveShoveEntity, inst)
        inst.um_shoveentity:Remove()
        inst.um_shoveentity = nil
    end
end

local function UpdateProperties(inst, child, updaterad)
    --inst.Physics:SetMass(child.Physics:GetMass())
    local collision_group = child.Physics:GetCollisionGroup()
    local collision_mask = child.Physics:GetCollisionMask()
    local rad = child:GetPhysicsRadius(.5)
    if inst.Physics:GetCollisionGroup() ~= collision_group then
        inst.Physics:SetCollisionGroup(collision_group)
    end
    if inst.Physics:GetCollisionMask() ~= collision_mask then
        inst.Physics:SetCollisionMask(collision_mask)
    end
    if inst:GetPhysicsRadius(.5) ~= rad then
        if updaterad then child.Physics:ConstrainTo(nil) end
        if child.physicsradiusoverride then inst:SetPhysicsRadiusOverride(child.physicsradiusoverride) end
        inst.Physics:SetCapsule(rad, 1)
        if updaterad then child.Physics:ConstrainTo(inst.entity) end
    end
    if child:GetCurrentPlatform() then
        if inst:HasTag("ignorewalkableplatforms") then inst:RemoveTag("ignorewalkableplatforms") end
    elseif not inst:HasTag("ignorewalkableplatforms") then
        inst:AddTag("ignorewalkableplatforms")
    end
end

local function UpdateRepel(inst)
    local speed = inst.um_shovespeed
    if speed then
        speed = speed + inst.um_shovedspeed
        local child = inst.um_child and inst.um_child:IsValid() and inst.um_child
        if speed < 0 then
            inst.um_shovespeed = speed
            inst.um_shovedspeed = inst.um_shovedspeed + .075
            local angle = (inst.um_shoverot - inst.Transform:GetRotation()) * DEGREES
            inst.Physics:SetMotorVelOverride(speed * math.cos(angle), 0, -speed * math.sin(angle))
            if child then UpdateProperties(inst, child, true) end
        else
            --[[inst.um_shovespeed = nil
            inst.um_shovedspeed = nil
            inst.um_shoverot = nil]]
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:Stop()
            if child then RemoveShoveEntity(child) end
            --inst:RestartBrain("um_shoving")
            if inst.um_shoveupdatetask then
                inst.um_shoveupdatetask:Cancel()
                inst.um_shoveupdatetask = nil
            end
        end
    end
end

local function RemoveConstrains(inst)
    inst.Physics:SetActive(false)
    if inst.um_child and inst.um_child:IsValid() then
        inst.um_child.Physics:ConstrainTo(nil)
        inst.um_child.Physics:SetDontRemoveOnSleep(false)
        inst.um_child.um_shoveentity = nil
    end
    inst:RemoveEventCallback("onremove", RemoveConstrains)
end

local function SpawnShoveEntity(inst, x, z)
    local shoveentity = SpawnPrefab("um_shoveentity")
    UpdateProperties(shoveentity, inst)
    shoveentity.Transform:SetPosition(x, 0, z)
    shoveentity.um_child = inst
    shoveentity:ListenForEvent("onremove", RemoveConstrains)
    shoveentity:ListenForEvent("onremove", RemoveShoveEntity, inst)
    inst.Physics:SetDontRemoveOnSleep(true)
    inst.Physics:ConstrainTo(shoveentity.entity)
    return shoveentity
end

local function DoRepel(inst, data)
    RemoveShoveEntity(inst)
    local x1, _, z1 = data.knocker.Transform:GetWorldPosition()
    local x, _, z = inst.Transform:GetWorldPosition()
    local dx = x1 - x
    local dz = z1 - z
    local dsq = dx * dx + dz * dz
    local rangesq = data.radius * data.radius
    local k = dsq < rangesq and .3 * dsq / rangesq - 1 or -.7
    local speed = (data.strengthmult or 1) * 10 * k
    if speed < 0 then
        inst.um_shoveentity = SpawnShoveEntity(inst, x, z)
        local rot = inst.um_shoveentity.Transform:GetRotation()
        local rot1 = dsq > 0 and math.atan2(-dz, dx) * RADIANS or data.knocker.Transform:GetRotation() + 180
        --[[inst:StopBrain("um_shoving")
        local locomotor = inst.components.locomotor
        if locomotor then
            locomotor:Stop()
            locomotor:Clear()
        end
        inst:ClearBufferedAction()]]
        local angle = (rot1 - rot) * DEGREES
        inst.um_shoveentity.Physics:SetMotorVelOverride(speed * math.cos(angle), 0, -speed * math.sin(angle))
        inst.um_shoveentity.um_shoverot = rot1
        inst.um_shoveentity.um_shovespeed = speed
        inst.um_shoveentity.um_shovedspeed = 0
    end
    inst.um_shoveentity.um_shoveupdatetask = inst.um_shoveentity:DoPeriodicTask(0, UpdateRepel)
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
local function UpdateProperties(inst, child, update)
    local mass = child.Physics:GetMass()
    local collision_group = child.Physics:GetCollisionGroup()
    local collision_mask = child.Physics:GetCollisionMask()
    local rad = child:GetPhysicsRadius(.5)
    if inst.Physics:GetMass() ~= mass then
        inst.Physics:SetMass(mass)
    end
    if inst.Physics:GetCollisionGroup() ~= collision_group then
        inst.Physics:SetCollisionGroup(collision_group)
    end
    if inst.Physics:GetCollisionMask() ~= collision_mask then
        inst.Physics:SetCollisionMask(collision_mask)
    end
    if inst:GetPhysicsRadius(.5) ~= rad then
        if child.physicsradiusoverride then inst:SetPhysicsRadiusOverride(child.physicsradiusoverride) end
        inst.Physics:SetCapsule(rad, 1)
    end
    if child:GetCurrentPlatform() then
        if inst:HasTag("ignorewalkableplatforms") then inst:RemoveTag("ignorewalkableplatforms") end
    elseif not inst:HasTag("ignorewalkableplatforms") then
        inst:AddTag("ignorewalkableplatforms")
    end
    if child:HasTag("no_collision_callback_for_other") then
        if not inst:HasTag("no_collision_callback_for_other") then inst:AddTag("no_collision_callback_for_other") end
    elseif inst:HasTag("no_collision_callback_for_other") then
        inst:RemoveTag("no_collision_callback_for_other")
    end
    if update then
        local x, y, z = inst.Transform:GetWorldPosition()
        child.Transform:SetPosition(x, y, z)
    end
end

local function SetChild(inst, child, x, y, z)
    inst.um_child = child
    inst:UMUpdateProperties(child)
    inst.Transform:SetPosition(x, y, z)
    child.um_shovedphysicsactive = child.Physics:IsActive()
    child.Physics:SetActive(false)
    inst:UMSetShovePhysicsActiveListener(child, true)
end

local function SetShovePhysicsActiveListener(inst, child, toggle)
    local Physics = child.Physics
    if toggle then
        if Physics then UMShovePhysics[Physics] = child end
        child.um_shovedphysicsactive_onremove = function(_inst) inst:UMSetShovePhysicsActiveListener(_inst) end
        child:ListenForEvent("onremove", child.um_shovedphysicsactive_onremove)
    else
        if Physics and UMShovePhysics[Physics] then UMShovePhysics[Physics] = nil end
        if child.um_shovedphysicsactive_onremove then
            inst:RemoveEventCallback("onremove", child.um_shovedphysicsactive_onremove)
            child.um_shovedphysicsactive_onremove = nil
        end
    end
end

local function OnCollide(inst, other, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames)
    if inst.um_child and inst.um_child:IsValid() then
        local fn = PhysicsCollisionCallbacks[inst.um_child.GUID]
        if fn then
            fn(inst.um_child, other, world_position_on_a_x, world_position_on_a_y, world_position_on_a_z, world_position_on_b_x, world_position_on_b_y, world_position_on_b_z, world_normal_on_b_x, world_normal_on_b_y, world_normal_on_b_z, lifetime_in_frames)
        end
    end
end

local function OnRemoveShoveEntity(inst)
    inst.Physics:SetActive(false)
    if inst.um_child and inst.um_child:IsValid() then
        inst:UMSetShovePhysicsActiveListener(inst.um_child)
        if inst.um_child.um_shovedphysicsactive then
            inst.um_child.Physics:SetActive(true)
            inst.um_child.um_shovedphysicsactive = nil
        end
        inst.um_child.um_shoveentity = nil
    end
    inst:RemoveEventCallback("onremove", OnRemoveShoveEntity)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --inst.entity:AddAnimState()

    MakeCharacterPhysics(inst, 75, .5)

    --[[inst.AnimState:SetBank("boards")
    inst.AnimState:SetBuild("boards")
    inst.AnimState:PlayAnimation("idle")]]

    --[[Non-networked entity]]
    inst:AddTag("um_shoveentity")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOBLOCK")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.UMUpdateProperties = UpdateProperties
    inst.UMSetChild = SetChild
    inst.UMSetShovePhysicsActiveListener = SetShovePhysicsActiveListener

    inst.Physics:SetCollisionCallback(OnCollide)

    inst:ListenForEvent("onremove", OnRemoveShoveEntity)

    inst.persists = false

    return inst
end

return Prefab("um_shoveentity", fn)
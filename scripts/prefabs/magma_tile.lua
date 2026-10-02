local function SetLit(inst, lit)
    inst.Light:Enable(lit)
    inst.is_lit = lit
end

local function OnMagmaCooled(inst)
    inst:SetLit(false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireOut")
end

local function OnMagmaMelted(inst)
    inst:SetLit(true)
end

local function OnSave(inst, data)
    data.lit = inst.is_lit
end

local function OnLoad(inst, data)
    if data.lit then
        inst:SetLit(data.lit)
    end
end

local function SpawnFX(inst)
    --client doesn't have synced access to is_lit so we instead check the tile it's on. basically the same thing.
    local is_lit = TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN

    local t = GetRandomWithVariance(4, 2)
    if TheWorld.net ~= nil and TheWorld.net.components.quaker ~= nil and TheWorld.net.components.quaker:IsQuaking() then
        t = GetRandomWithVariance(0.75, 0.25)
    end

    if inst:IsAsleep() or TheWorld.ismastersim or not is_lit then
        inst:DoTaskInTime(t, SpawnFX)
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local px, py, pz = x + GetRandomWithVariance(0, 2), 0, z + GetRandomWithVariance(0, 2)

    if TheWorld.Map:IsVisualGroundAtPoint(px, py, pz) then
        inst:DoTaskInTime(t, SpawnFX)
        return
    end

    local fx = SpawnPrefab("um_lava_bubble_fx")
    fx.Transform:SetPosition(px, py, pz)

    inst:DoTaskInTime(t, SpawnFX)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()

    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(4)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(0.2, 0.1, 0.05)
    inst.Light:Enable(true)
    inst.is_lit = true

    inst:AddTag("magma_tile")
    --inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    --inst:AddTag("NOCLICK") --can'ty have those tags or else flingos wont target
    inst:AddTag("ignorewalkableplatforms")


    --Dedicated server does not need to spawn the fx
    if not TheNet:IsDedicated() then
        local quaking = TheWorld.net ~= nil and TheWorld.net.components.quaker ~= nil and TheWorld.net.components.quaker:IsQuaking() or false

        if math.random() > (quaking and 0.5 or 0.9) then
            inst:DoTaskInTime(GetRandomWithVariance(0.75, 0.25), SpawnFX)
        end
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SetLit = SetLit

    inst:DoTaskInTime(0, function(inst)
        if TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
            inst:SetLit(true)
        else
            inst:SetLit(false)
        end
    end)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("onmagmamelted", OnMagmaMelted)
    inst:ListenForEvent("onmagmacooled", OnMagmaCooled)

    return inst
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("gridicecrack")
    inst.AnimState:SetBank("gridplacer")
    inst.AnimState:PlayAnimation(math.random() < 0.5 and "left" or "right")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.AnimState:SetMultColour(1, 1, 0, 1)
    inst.AnimState:SetLightOverride(1)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("lava_crack_fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function bubble_fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBuild("um_lava_bubble_fx")
    inst.AnimState:SetBank("um_lava_bubble_fx")

    inst.AnimState:PlayAnimation("bubbles_" .. math.random(1, 3), false)

    if math.random() > 0.5 and TheWorld.net ~= nil and TheWorld.net.components.quaker ~= nil and TheWorld.net.components.quaker:IsQuaking() then
        inst.AnimState:PushAnimation("waterspout", false)
        inst:ListenForEvent("animqueueover", inst.Remove)
    else
        inst:ListenForEvent("animover", inst.Remove)
    end

    inst.AnimState:SetLightOverride(1)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("lava_bubble_fx")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("magma_tile", fn),
    Prefab("magma_tile_crack_grid_fx", fx_fn),
    Prefab("um_lava_bubble_fx", bubble_fx_fn)

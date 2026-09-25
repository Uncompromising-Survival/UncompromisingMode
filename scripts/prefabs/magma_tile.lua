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

return Prefab("magma_tile", fn),
    Prefab("magma_tile_crack_grid_fx", fx_fn)

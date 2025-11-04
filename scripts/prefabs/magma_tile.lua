local function OnMagmaChanged(inst)
    inst:DoTaskInTime(0, function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)

        if TheWorld.Map:GetTile(tile_x, tile_z) == WORLD_TILES.UM_MAGMA_LAVAMOLTEN then
            inst.Light:Enable(true)
            inst.is_lit = true
        else
            inst.Light:Enable(false)
            inst.is_lit = false
        end
    end)
end

local function OnSave(inst)
    return {
        lit = inst.is_lit
    }
end

local function OnLoad(inst, data)
    if data.lit then
        inst.Light:Enable(true)
        inst.is_lit = true
    end
end

local function DoFX(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    if inst.is_lit and not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
        local fx = SpawnPrefab("deer_fire_burst")
        fx.Transform:SetPosition(x, y, z)
    end
    inst.shinetask = inst:DoTaskInTime(8 + math.random() * 10, DoFX)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork() --does this actually need to be networked?
    inst.entity:AddLight()

    inst.Light:SetIntensity(0.07)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(235 / 255, 0,0)
    inst.Light:Enable(true)
    inst.is_lit = true

    inst:AddTag("magma_tile")
    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")
    inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    DoFX(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("check_magma_melt", OnMagmaChanged)
    inst:ListenForEvent("check_magma_cooled", OnMagmaChanged)

    return inst
end

return Prefab("magma_tile", fn)

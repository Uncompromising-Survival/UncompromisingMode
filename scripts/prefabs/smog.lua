local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("smog")
    inst.AnimState:SetBuild("marshmist")
    inst.AnimState:SetBank("marshmist")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(10, 8, 5)
    inst.AnimState:SetMultColour(0.4, 0.4, 0.4, 0.0)

    inst:DoTaskInTime(0, function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if #TheSim:FindEntities(x, y, z, 4, { "smog" }) > 1 then
            inst:Remove()
        end
    end)

    inst.mult = 0
    inst.fadeintask = inst:DoPeriodicTask(0.125, function(inst)
        inst.AnimState:SetMultColour(0.4, 0.4, 0.4, inst.mult)
        inst.mult = inst.mult + 0.025
        if inst.mult >= 0.4 then
            inst.mult = 0.4
            inst.fadeintask:Cancel()
            inst.fadeintask = nil
        end
    end)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst:DoTaskInTime(math.random(60, 120), function(inst)
        inst:DoPeriodicTask(0.125, function(inst)
            inst.AnimState:SetMultColour(0.4, 0.4, 0.4, inst.mult)
            inst.mult = inst.mult - 0.025
            if inst.mult <= 0 then
                inst:Remove()
            end
        end)
    end)

    inst:DoPeriodicTask(5 + math.random(5), function(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local players = TheSim:FindEntities(x, y, z, 12, { "player" }, { "playerghost" })
        for k, v in ipairs(players) do
            if v.components.health ~= nil and v.prefab ~= "willow" and not v:HasTag("has_gasmask") then
                v.components.health:DeltaPenalty(0.0125)
                if v.components.talker ~= nil then
                    v.components.talker:Say(GetString(v, "GAS_DAMAGE"))
                end
            end
        end
    end)

    --inst:AddComponent("areaaware")

    return inst
end

return Prefab("smog", fn)

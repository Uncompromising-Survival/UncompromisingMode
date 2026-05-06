local function ApplySlows(inst)
    --also scare enemies near wathom, at a smaller radius
    local debuffkey = inst.prefab
    local wathom = inst.wathom and inst.wathom:IsValid() and inst.wathom or nil
    local wathomcombat = wathom and wathom.components.combat or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, {"_combat"}, {"companion", "INLIMBO", "notarget", "player", "playerghost", "wall", "abigail", "shadowminion", "shadow", "trap"}) --added playertags because of the taunt.
    for i, v in ipairs(ents) do
        if v ~= wathom and v.entity:IsVisible()
            and not (v.components.health and v.components.health:IsDead())
            and not (wathomcombat and wathomcombat:IsAlly(v)) then
            if v.components.locomotor then
                v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, 0.5)
                v.um_wathom_speedmulttask = v:DoTaskInTime(10, function(i)
                    i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                    i.um_wathom_speedmulttask = nil
                end)
            end
            if v.components.hauntable and v.components.hauntable.panicable then
                v.components.hauntable:Panic(8) -- Fallback to TUNING.BATTLESONG_PANIC_TIME (6 seconds) if needed
            end
            if not v:HasTag("bird") and v.components.combat and (not v.components.hauntable or v.components.hauntable and not v.components.hauntable.panicable) then
                v.components.combat:SetTarget(wathom)
            end
        end
    end
end

local function puddle()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("treegrowthsolution")
    inst.AnimState:SetBuild("um_goo_blue")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.Transform:SetScale(1.5, 1.5, 1.5)

    inst.AnimState:PlayAnimation("pre_idle", false)
    inst.AnimState:PushAnimation("idle", false)
    inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst:ListenForEvent("animover",function(inst) inst.AnimState:SetDeltaTimeMultiplier(.4) end)
    inst:ListenForEvent("animqueueover",function(inst) inst:Remove() end)

    inst.persists = false
    
    inst:DoPeriodicTask(.5, ApplySlows)

    return inst
end

return Prefab("wathom_puddle", puddle)
local function NoHoles(pt) -- AXE Maybe should become global, or a global tentacle spawn call since it's reused
    return (TheWorld ~= nil) and not TheWorld.Map:IsPointNearHole(pt)
end

local function ApplySlows(inst) -- Also has a chance to summon a tentacle...
    --also scare enemies near wathom, at a smaller radius
    local debuffkey = inst.prefab
    local wathom = inst.wathom and inst.wathom:IsValid() and inst.wathom or nil
    local wathomcombat = wathom and wathom.components.combat or nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, {"_combat"}, {"companion", "INLIMBO", "notarget", "player", "playerghost", "wall", "abigail", "shadowminion", "shadow", "trap","flying"}) --added playertags because of the taunt.
    for i, v in ipairs(ents) do
        if v ~= wathom and v.entity:IsVisible()
            and not (v.components.health and v.components.health:IsDead())
            and not (wathomcombat and wathomcombat:IsAlly(v)) then
            
            if v.components.locomotor and not v.um_wathom_speedmulttask then
                v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, 0.25)
                v.um_wathom_speedmulttask = v:DoTaskInTime(10, function(i)
                    i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey)
                    i.um_wathom_speedmulttask = nil
                end)
            elseif TryLuckRoll(wathom, 0.01, LuckFormulas.ShadowTentacleSpawn) then
                local pt
                if v ~= nil and v:IsValid() then
                    pt = v:GetPosition()
                end
                if pt then
                    local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true)
                    if offset ~= nil then
                        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                        inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
                        local tentacle = SpawnPrefab("shadowtentacle")
                        if tentacle ~= nil then
                            tentacle.wathom = wathom
                            tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                            tentacle.components.combat:SetTarget(v)
                        end
                    end
                end
            end 
        end
    end


    -- Do Work
    local works = {"CHOP_workable","MINE_workable"}
    local ents = TheSim:FindEntities(x, y, z, 2, nil, {"INLIMBO", "wall"},works) --added playertags because of the taunt.
    for i, v in ipairs(ents) do
        v.components.workable:WorkedBy(inst.owner and inst.owner or inst, 0.1)
    end
end


local function Init(inst)
    inst.AnimState:PlayAnimation("pre_idle", false)
    inst:ListenForEvent("animover",function(inst) 
        inst.AnimState:PushAnimation("idle", false)
        inst.AnimState:SetDeltaTimeMultiplier(inst.mult)
        inst.AnimState:SetFrame(150)
        -- Flip animation directions to make it seem like it's pulsating
        inst:DoPeriodicTask(0.1*math.random(4,6),function(inst)
            if math.random() > 0.75 and inst.AnimState:GetCurrentAnimationFrame() > 50 then -- Can't make it finish the animation too early by going backwards
                inst.AnimState:SetDeltaTimeMultiplier(-inst.mult)
            else
                inst.AnimState:SetDeltaTimeMultiplier(inst.mult)
            end
        end)
        inst:ListenForEvent("animover",function(inst)
            inst:Remove()
        end)
    end)
end

local function puddle()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    
    inst.AnimState:SetBank("treegrowthsolution")
    inst.AnimState:SetBuild("um_goo_blue")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.entity:SetPristine()
    
    inst:AddTag("FX")
    if not TheWorld.ismastersim then return inst end

    inst.Transform:SetScale(1.5, 1.5, 1.5)

    
   
    inst.AnimState:SetMultColour(0, 0, 0, .6)

    inst.mult = 0.5

    inst:DoTaskInTime(0,Init)
    
    

    inst.persists = false
    
    inst:DoPeriodicTask(0.5, ApplySlows)

    return inst
end

return Prefab("wathom_puddle", puddle)
local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddStategraphPostInit("worm", function(inst)
    local attackstate = inst.states["attack"]
    if attackstate then
        local attackstate_onenter = attackstate.onenter
        attackstate.onenter = function(inst, ...)
            if inst:HasTag("viperworm") then
                local target = inst.components.combat and inst.components.combat.target
                if target and target:IsValid() then inst:ViperlingBelch(target) end
            end
            return attackstate_onenter(inst, ...)
        end
        local attackstate_timeline1_fn = attackstate.timeline[1] and attackstate.timeline[1].fn
        if attackstate_timeline1_fn then
            attackstate.timeline[1].fn = function(inst, ...)
                if inst:HasTag("shockworm") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/bite")
                    inst.components.combat:DoAttack(nil, nil, nil, "electric")
                    local x, y, z = inst.Transform:GetWorldPosition()
                    for i = 1, 3 do
                        SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
                    end
                    return
                end
                return attackstate_timeline1_fn(inst, ...)
            end
        end
        table.insert(attackstate.timeline, TimeEvent(1 * FRAMES, function(inst)
            if inst:HasTag("shockworm") then
                local x, y, z = inst.Transform:GetWorldPosition()
                for i = 1, 2 do
                    SpawnPrefab("sparks").Transform:SetPosition(x, y + .25 + math.random() * 2, z)
                end
            end
        end))
        table.sort(attackstate.timeline, function(a, b) return a.time < b.time end)
        --[[local attackstate_animover_fn = attackstate.events["animover"].fn
        attackstate.events["animover"].fn = function(inst, ...)
            return attackstate_animover_fn(inst, ...)
        end]]
    end
end)
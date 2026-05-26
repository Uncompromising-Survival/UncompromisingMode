local env = env
GLOBAL.setfenv(1, GLOBAL)

local function DoAreaDamageEffect(inst)
    local dodamageRadius = 5.5
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.platformPushingRings = 1
    inst.components.groundpounder.numRings = 1
    
    local ringfx = SpawnPrefab("firering_fx")
    ringfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    ringfx.Transform:SetScale(0.8, 0.8, 0.8)
    
    inst.components.groundpounder.destructionRings = 1
    inst.components.groundpounder.platformPushingRings = 1
    inst.components.groundpounder.numRings = 1
    inst.components.groundpounder:GroundPound()
    
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, dodamageRadius, { "_combat" }, { "playerghost", "worm", "ghost", "prey", "bird", "shadowcreature" })
    
    for i, ent in ipairs(ents) do
        if ent.components.health ~= nil and not ent.components.health:IsDead() then
            local insulated = (ent:HasTag("electricdamageimmune") or
                (ent.components.inventory ~= nil and ent.components.inventory:IsInsulated()))
                
            local mult = ent:HasTag("player") and not insulated
                and TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (ent.components.moisture ~= nil and ent.components.moisture:GetMoisturePercent() or (ent:GetIsWet() and 1 or 0))
                or 1
                
            ent.components.combat:GetAttacked(inst, (TUNING.LIGHTNING_GOAT_DAMAGE * 1.5) * mult, nil, "electric")
                
            if ent:HasTag("player") and ent.sg ~= nil and not ent.sg:HasStateTag("nointerrupt") and not insulated and not
                (ent.components.health ~= nil and not ent.components.health:IsDead()) then
                ent.sg:GoToState("electrocute")
            end
        end
    end
end

local function Charging(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local x1 = x + math.random(-0.5, 0.5)
    local z1 = z + math.random(-0.5, 0.5)

    if math.random() >= 0.8 then
        SpawnPrefab("electricchargedfx").Transform:SetPosition(x1, 0, z1)
    end

    SpawnPrefab("sparks").Transform:SetPosition(x1, 0 + 0.25 * math.random(), z1)
end

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
    end

    local states = {
        State{
            name = "shock_pre",
            tags = {"attack", "canrotate", "busy"},

            onenter = function(inst, target)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("shocking_pre")
                inst.SoundEmitter:KillAllSounds()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
                if inst.loop_sound then
                    inst.SoundEmitter:PlaySound(inst.loop_sound, "custom_loop")
                end
            end,
            events =
            {
                EventHandler("animover", function(inst) 
                    --inst.SpreadingShock(inst)
                    inst.sg:GoToState("shock_loop") 
                end),
            },
        },
        State{
            name = "shock_loop",
            tags = {"attack", "canrotate", "busy"},

            onenter = function(inst, target)
                inst.Physics:Stop()
                Charging(inst)
                inst.AnimState:PlayAnimation("shocking_loop")
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/emerge")
                if not inst.shock_loop then
                    inst.shock_loop = 0
                end

                -- Extend to 4 more tiles
                for i = 1,4 do
                    inst.components.um_electrifies_tiles:ExtendTiles()
                end
            end,

            --onupdate = function(inst) end,

            timeline =
            {
                SoundFrameEvent(7, "dontstarve/creatures/worm/hurt"),
                TimeEvent(8 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/shocked_electric")
                    SpawnPrefab("electricchargedfx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    -- Only shock the tiles 4 times, on these frames
                    if inst.shock_loop == 2 or inst.shock_loop == 5 or inst.shock_loop == 8 or inst.shock_loop == 12 then
                        inst.components.um_electrifies_tiles:ElectrifyMyTiles()
                    end
                end),
            },

            events =
            {
                EventHandler("animover", function(inst) 
                    if inst.shock_loop > 12 then
                        inst.shock_loop = nil
                        inst.sg:GoToState("shock_pst") 
                    else
                        inst.shock_loop = inst.shock_loop + 1
                        inst.sg:GoToState("shock_loop") 
                    end
                end),
            },
        },
        State{
            name = "shock_pst",
            tags = {"attack", "canrotate", "busy"},

            onenter = function(inst, target)
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("shocking_pst_1")
                inst.AnimState:PushAnimation("taunt",false)
                inst.SoundEmitter:KillAllSounds()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/retract")
                if inst.loop_sound then
                    inst.SoundEmitter:PlaySound(inst.loop_sound, "custom_loop")
                end
                inst.components.um_electrifies_tiles:ClearAllMyTiles()
            end,
            events =
            {
                EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
            },
        },
    }

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

end)
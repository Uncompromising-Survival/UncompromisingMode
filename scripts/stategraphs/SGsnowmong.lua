require("stategraphs/commonstates")

local AOE_TARGET_MUSTHAVE_TAGS = {"_combat"}
local AOE_TARGET_CANT_TAGS = {"INLIMBO", "flight", "invisible", "notarget", "noattack", "snowish", "wall", "structure"}

local function DoAOEAttack(inst)
    inst.components.combat.ignorehitrange = true
    local radius = inst.components.combat:GetHitRange()
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, ent in ipairs(TheSim:FindEntities(x, y, z, radius + 3, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        local range = radius + ent:GetPhysicsRadius(0)
        if ent ~= inst and ent:IsValid() and not (ent.components.health and ent.components.health:IsDead())
            and inst.components.combat:CanTarget(ent) and inst:IsNear(ent, range) then
            inst.components.combat:DoAttack(ent)
        end
    end
    inst.components.combat.ignorehitrange = nil
end

local actionhandlers =
{
    ActionHandler(ACTIONS.STEALMOLEBAIT, function(inst)
        return inst.State and "steal_pre_under" or "steal"
    end),
}

local events =
{
    CommonHandlers.OnSleep(),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data)
        if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
            if inst.State == false then
                inst.sg:GoToState("attack", data.target)
            else
                inst.sg:GoToState("enter", "attack")
            end
        end
    end),
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then
            return
        elseif inst.components.locomotor:WantsToMoveForward() then
            if inst.State then
                if not inst.sg:HasStateTag("moving") then
                    inst.sg:GoToState("walk_pre")
                end
            else
                inst.sg:GoToState("exit")
            end
        elseif inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("walk_pst")
        else
            if not inst.sg:HasStateTag("idle") then
                inst.sg:GoToState("idle")
            end
        end
    end),
}

local states =
{
    State
    {
        name = "enter",
        tags = {"busy"},

        onenter = function(inst, nextState)
            --inst.attackUponSurfacing = (nextState == "attack")
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst:SetAbove()
            inst.SoundEmitter:KillSound("walkloop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    local nextState = "idle"

                    if inst.attackUponSurfacing then
                        nextState = "attack"
                    end

                    inst.sg:GoToState(nextState)
                end
            end)
        },
        
        timeline =
        {
            TimeEvent(16 * FRAMES,function (inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/emerge") end),
        },

    },

    State
    {
        name = "exit",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("exit")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:SetUnder()
                inst.sg:GoToState("idle") 
            end)
        },

        timeline = 
        {
            
            TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/jump") end),
            TimeEvent(22 * FRAMES, DoAOEAttack),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/submerge") end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/dig") end),
            TimeEvent(39 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/dig") end),
            TimeEvent(49 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/dig") end),
            TimeEvent(54 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/dig") end),
        },
    },

    State
    {
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.SoundEmitter:KillSound("walkloop")

            if playanim then
                inst.AnimState:PlayAnimation(playanim)

                if inst.State == false then
                    inst.AnimState:PushAnimation("idle", true)
                elseif inst.State then
                    inst.AnimState:PushAnimation("idle_under", true)
                end
            else
                if inst.State == false then
                    inst.AnimState:PlayAnimation("idle", true)
                elseif inst.State then
                    inst.AnimState:PlayAnimation("idle_under", true)
                end
            end       
        end,
    },

    State
    {
        name = "walk_pre",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
            if not inst.SoundEmitter:PlayingSound("walkloop") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/worm/move", "walkloop")
            end
            inst.components.locomotor:WalkForward()
        end,

        events =
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("walk") end end),
        }
    },

    State
    {
        name = "walk",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
        end,
    },

    State
    {
        name = "walk_pst",
        tags = {"canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()

            local should_softstop = false
            if should_softstop then
                inst.AnimState:PushAnimation("walk_pst")
            else
                inst.AnimState:PlayAnimation("walk_pst")
            end

            inst.SoundEmitter:KillSound("walkloop")
        end,

        events =
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        }
    },

    State
    {
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("action")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) inst.components.combat:DoAttack() end),
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/attack") end),
        },

        events =
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        }
    },
    State
    {
        name = "sleep",
        tags = {"busy", "sleeping"},

        onenter = function(inst) 
            inst.components.locomotor:StopMoving()
            if inst.State then
                inst.AnimState:PlayAnimation("enter")
                inst.SoundEmitter:PlaySound("UCSounds/Grub/emerge")
                inst.AnimState:PushAnimation("sleep_pre", false)
            else
                inst.AnimState:PlayAnimation("sleep_pre")
            end
        end,

        events =
        {   
            EventHandler("animqueueover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("sleeping") end end),        
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst:SetAbove()
                inst.SoundEmitter:KillSound("sniff")
                inst.SoundEmitter:KillSound("stunned")
            end)
        }
    },
        
    State
    {
        name = "sleeping",
        tags = {"busy", "sleeping"},

        onenter = function(inst) 
            inst.AnimState:PlayAnimation("sleep_loop")
        end,

        events =
        {   
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("sleeping") end end),
            EventHandler("onwakeup", function(inst) inst.sg:GoToState("wake") end),
        },

       timeline =
        {

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/sleepin") end),
            TimeEvent(37 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/sleepout") end),
        },
    },        

    State
    {
        name = "wake",
        tags = {"busy", "waking"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("sleep_pst")
            if inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) if inst.AnimState:AnimDone() then inst.sg:GoToState("idle") end end),
        },

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:KillSound("sleep")
            end)
        },
    },

    State
    {
        name = "death",
        tags = {"busy", "stunned"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            
            if TheWorld.state.iswinter and math.random() > 0.75 then
                inst.components.lootdropper:SpawnLootPrefab("um_ice_tail")
            else
                inst.components.lootdropper:SpawnLootPrefab("smallmeat")
            end
            
            inst.TryGemologyLoot(inst)
            RemovePhysicsColliders(inst)
        end,

        timeline=
        {
            TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Grub/death") end),
        }

    },
    State{
        name = "steal_pre_under",
        tags = {"busy"},
        onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("enter")
            inst:SetAbove()
            inst.SoundEmitter:KillSound("walkloop")
        end,

        timeline =
        {
            TimeEvent(1*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("UCSounds/Grub/emerge")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("steal") end),
        },
    },

    State{
        name = "steal",
        tags = {"busy", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("action")
        end,

        timeline =
        {
            TimeEvent(9*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("UCSounds/Grub/attack")
            end),
            TimeEvent(12*FRAMES, function(inst)
                inst:IntegrateSnowStuff()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("exit") end),
        },
    },
}

return StateGraph("snowmong", states, events, "idle", actionhandlers)
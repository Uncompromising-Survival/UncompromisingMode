local WALK_SPEED = 4
local RUN_SPEED = 7
-- update pawn
require("stategraphs/commonstates")

--[[local actionhandlers = 
{
}]]

local events=
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnLocomote(true, true),
    EventHandler("attacked", function(inst) if not inst.components.health:IsDead() then inst.sg:GoToState("hit") end end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("trapped", function(inst) inst.sg:GoToState("trapped") end),
    EventHandler("locomote",
        function(inst)
            if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end

            if not inst.components.locomotor:WantsToMoveForward() then
                if not inst.sg:HasStateTag("idle") then
                    if not inst.sg:HasStateTag("running") then
                        inst.sg:GoToState("idle")
                    end
                        inst.sg:GoToState("idle")
                end
            elseif inst.components.locomotor:WantsToRun() then
                if not inst.sg:HasStateTag("running") then
                    inst.sg:GoToState("run")
                end
            else
                if not inst.sg:HasStateTag("hopping") then
                    inst.sg:GoToState("hop")
                end
            end
        end),
    EventHandler("stunned", function(inst) inst.sg:GoToState("stunned") end),
    EventHandler("um_hide_away", function(inst)
        if inst.sg:HasStateTag("busy") then return end
        if inst.pawntype == "_nightmare" then
            inst.sg:GoToState("hide_pre_nightmare")
        else
            inst.sg:GoToState("hide_pre")
        end
    end),
}

local states=
{
 
    State{
        name = "look",
        tags = {"idle", "canrotate" },
        onenter = function(inst)
            
            inst.lookingup = nil
            inst.donelooking = nil
            
            if math.random() > .5 then
                inst.AnimState:PlayAnimation("idle")
                inst.AnimState:PushAnimation("idle", true)
                inst.lookingup = true
            else
                inst.AnimState:PlayAnimation("idle")
                inst.AnimState:PushAnimation("idle", true)
            end
            
            inst.sg:SetTimeout(2.5 + math.random()*0.5)
        end,
        
        ontimeout = function(inst)
            inst.donelooking = true
            if inst.lookingup then
                inst.AnimState:PlayAnimation("idle")
            else
                inst.AnimState:PlayAnimation("idle")
            end
        end,
        
        events=
        {
            EventHandler("animover", function (inst, data)
                if inst.donelooking then
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },
    
    State{
        
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end                                
            inst.sg:SetTimeout(1 + math.random()*1)
        end,
        
        ontimeout= function(inst)
            --inst.sg:GoToState("idle")
        end,

    },
    
    State{
        
        name = "rattle_and_shake",
        tags = {"canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("rattle_and_shake") end ),
        },

    },
    
    State{
        
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst, data) inst.sg:GoToState("idle") end),
        }
    },    

    State{
        name = "hop",
        tags = {"moving", "canrotate", "hopping"},

        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(28*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(52*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
        },

        onenter = function(inst) 
            inst.AnimState:PlayAnimation("walk_pre")
            inst.AnimState:PushAnimation("walk_loop")
            inst.components.locomotor:WalkForward()
            inst.sg:SetTimeout(1.25+math.random())
        end,

        onupdate= function(inst)
            if not inst.components.locomotor:WantsToMoveForward() then
                inst.sg:GoToState("idle", "walk_pst")
            end
        end,

        ontimeout= function(inst)
           inst.sg:GoToState("hop")
        end,
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst) 
            local play_scream = true
            if inst.components.inventoryitem then
                play_scream = inst.components.inventoryitem.owner == nil
            end
            if play_scream then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            end
            inst.AnimState:PlayAnimation("walk_pre")
            inst.components.locomotor:RunForward()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run_loop") end ),
        },
    },

    State{
        name = "run_loop",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst) 
            inst.AnimState:PlayAnimation("walk_loop")
            inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk")
            inst.components.locomotor:RunForward()
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run_loop") end ),
        },
    },

    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)        
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,

    }, 

    State{
        name = "stunned",
        tags = {"busy", "stunned"},
        
        onenter = function(inst) 
            --inst.Physics:Stop()
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2) )
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = true
            end
        end,
        
        onexit = function(inst)
            if inst.components.inventoryitem then
                inst.components.inventoryitem.canbepickedup = false
            end
        end,
        
        ontimeout = function(inst) inst.sg:GoToState("idle") end,
    },    

    State{
        name = "stunned_post",
        tags = {"busy", "stunned"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("frozen_loop_pst")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "trapped",
        tags = {"busy", "trapped"},

        onenter = function(inst) 
            inst.Physics:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("frozen", true)
            inst.sg:SetTimeout(1)
        end,

        ontimeout = function(inst) inst.sg:GoToState("idle") end,
    },

    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()            
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },

    State{
        name = "hide_pre",
        tags = {"busy", "invisible"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.AnimState:PlayAnimation("dig")

            inst.Physics:Stop()
            --inst:PerformBufferedAction()
            ChangeToInventoryPhysics(inst)
            inst.components.health:SetInvincible(true)
            
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 20, { "uncompromising_pawn" }, { "uncompromising_nightmarepawn" })
            
            if ents ~= nil then
                for k,v in pairs(ents) do
                    if not v.sg:HasStateTag("busy") and v ~= inst then
                        v:AddTag("removingpawn")
                        v.sg:GoToState("hide_disarm")
                    end
                end
            end
        end,

        onexit = function(inst)
            ChangeToCharacterPhysics(inst)
            inst.components.health:SetInvincible(false)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst:Remove() end),
        },
    },

    State{
        name = "hide_disarm",
        tags = {"busy", "invisible"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.AnimState:PlayAnimation("idle")
            inst.Physics:Stop()
            --inst:PerformBufferedAction()
            ChangeToInventoryPhysics(inst)
            inst.components.health:SetInvincible(true)
        end,

        onexit = function(inst)
            ChangeToCharacterPhysics(inst)
            inst.components.health:SetInvincible(false)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst:Remove() end),
        },
    },
    
    State{
        name = "hide_pre_nightmare",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "pawn_hiss")
            inst.Physics:Stop()
            inst.sg:SetTimeout(.25)
        end,
        
        ontimeout = function(inst)
            if not inst.components.health:IsDead() then
                inst.components.explosive:OnBurnt()
            end
        end,
    },

    State{
        name = "hide_loop",
        tags = {"busy", "invisible"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hide_idle")
            inst.Physics:Stop()
            ChangeToInventoryPhysics(inst)
            inst.components.health:SetInvincible(true)
            if inst.components.workable then
                inst.components.workable.workable = true
                inst.components.workable:SetWorkLeft(1)
            end
            inst.sg:SetTimeout(GetRandomWithVariance(6, 2))
        end,

        onexit = function(inst)
            if inst.components.workable then
                inst.components.workable.workable = false
            end
            ChangeToCharacterPhysics(inst)
            inst.components.health:SetInvincible(false)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("hide_check")
        end,

    },

    State{
        name = "hide_check",
        tags = {"busy", "invisible"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("look_pre")
            inst.AnimState:PushAnimation("look")
            inst.AnimState:PushAnimation("look_pst", false)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.Physics:Stop()
            ChangeToInventoryPhysics(inst)
            inst.components.health:SetInvincible(true)
            if inst.components.workable then
                inst.components.workable.workable = true
                inst.components.workable:SetWorkLeft(1)
            end
        end,

        onexit = function(inst)
            if inst.components.workable then
                inst.components.workable.workable = false
            end
            ChangeToCharacterPhysics(inst)
            inst.components.health:SetInvincible(false)
        end,

        events=
        {
            EventHandler("animqueueover", function(inst)
                local danger = FindEntity(inst, 7, nil, {"scarytoprey"}, {'notarget'}) ~= nil
                if not danger then
                    inst.sg:GoToState("hide_post")
                else
                    inst.sg:GoToState("hide_loop")
                end
            end),
        },
    },

    State{
        name = "hide_post",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/hurt")
            inst.AnimState:PlayAnimation("emerge")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

}
-- CommonStates.AddWalkStates(states,
-- {
--     walktimeline = {
--         TimeEvent(0*FRAMES, PlayCrabFootstep),
--         TimeEvent(3*FRAMES, PlayCrabFootstep),
--         TimeEvent(7*FRAMES, PlayCrabFootstep),
--         TimeEvent(12*FRAMES, PlayCrabFootstep),
--         TimeEvent(16*FRAMES, PlayCrabFootstep),
--         TimeEvent(20*FRAMES, PlayCrabFootstep),
--         TimeEvent(24*FRAMES, PlayCrabFootstep),
--         TimeEvent(28*FRAMES, PlayCrabFootstep),
--     },
-- }, {walk = "walk"})
-- CommonStates.AddRunStates(states,
-- {
--     starttimeline = {
--         TimeEvent(0, function(inst) 
--             local play_scream = true
--             if inst.components.inventoryitem then
--                 play_scream = inst.components.inventoryitem.owner == nil
--             end
--             if play_scream then
--                 inst.SoundEmitter:PlaySound(inst.sounds.scream)
--             end
--         end)
--     },
-- }, {run = "run", stoprun = "idle"})
CommonStates.AddSleepStates(states)
CommonStates.AddFrozenStates(states)

return StateGraph("uncompromising_pawn", states, events, "idle") --actionhandlers
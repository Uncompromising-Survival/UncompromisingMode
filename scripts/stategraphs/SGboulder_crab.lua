require("stategraphs/commonstates")

local function TestIfShouldReHome(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local burrows = TheSim:FindEntities(x,y,z,16,{""})
    if #burrows > 4 then
        inst.components.knownlocations:RememberLocation("home", Point(self.inst.Transform:GetWorldPosition()))
    end
end

local function LaunchItem(inst, target, item)
    if item.Physics and item.Physics:IsActive() then
        local x, y, z = item.Transform:GetWorldPosition()
        item.Physics:Teleport(x, .1, z)

        x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = math.atan2(z1 - z, x1 - x) + (math.random() * 20 - 10) * DEGREES
        local speed = 5 + math.random() * 2
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end

local function KnockOutWeapon(inst,data)
    if data.redirected then return end

    if data.target and data.target.components.inventory and not data.target:HasTag("stronggrip") then
        local item = data.target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item and not item:HasTag("nosteal") then
            data.target.components.inventory:DropItem(item)
            LaunchItem(inst, data.target, item)
        end
    end
end

-- Spirit wanted the boulder crab to explode into rocks upon death. I can't remember where 12 came from, but that's how many rocks we're going with I guess.
-- Wanted nitre less than flint for some reason, can't recall at the moment of coding.
local function ExplodeIntoRockyLoot(inst)
    local weighted_rock_loot = {}
    weighted_rock_loot["rocks"] = 0.6
    weighted_rock_loot["flint"] = 0.2
    weighted_rock_loot["nitre"] = 0.15
    weighted_rock_loot["goldnugget"] = 0.05
    for i = 1, 12 do
        local pt = inst:GetPosition()
        local r = math.random()
        local theta = TWOPI * math.random()
        local offset = FindWalkableOffset(pt, theta, r, 1, true, true, nil, true, true)
        if offset then
            inst.components.lootdropper:FlingItem(SpawnPrefab(weighted_random_choice(weighted_rock_loot)), pt+offset)
        end
    end
end


local actionhandlers =
{
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.INVESTIGATE, "investigate"),
}

local events=
{
    EventHandler("attacked", function(inst)
        if inst.hiding and not inst.components.timer:TimerExists("regenrock") then -- This shouldn't happen, but if it does!
            inst.sg:GoToState("hide_pst")
        else
            if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasAnyStateTag("busy", "attack") and not inst.components.timer:TimerExists("regenrock") then 
                inst.sg:GoToState("hit")  -- can't attack during hit reaction
            end
        end
    end),
    EventHandler("doattack", function(inst, data) 
        if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasAnyStateTag("busy", "evade") and data and data.target and not inst.components.timer:TimerExists("regenrock") then 
            inst.sg:GoToState("attack", data.target) 
        elseif not inst.components.health and not inst.components.timer:TimerExists("regenrock") then
            inst.sg:GoToState("dig")
        end
    end),
    EventHandler("hideunderrock", function(inst)
        local rock = inst.myrock
        if not (inst.sg:HasStateTag("busy") or inst.components.health and inst.components.health:IsDead()) and rock and rock:IsValid() and rock.AnimState:IsCurrentAnimation("full") then
            inst.sg:GoToState("hide_pre")
        end
    end),
    EventHandler("comeoutfromunderrock", function(inst)
        if not (inst.components.health and inst.components.health:IsDead()) and inst.hiding then
            inst.sg:GoToState("hide_pst")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("locomote", function(inst) 
        if not inst.sg:HasStateTag("busy") and not inst.components.timer:TimerExists("regenrock") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit")) and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("pstmoving")
                end
            end
        end
    end),
}

local function SoundPath(inst, event)
    local creature = "spider"

    if inst:HasTag("spider_warrior") then
        creature = "spiderwarrior"
    elseif inst:HasTag("spider_hider") or inst:HasTag("spider_spitter") then
        creature = "cavespider"
    else
        creature = "spider"
    end
    return "dontstarve/creatures/" .. creature .. "/" .. event
end

local states =
{
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            --inst.SoundEmitter:PlaySound("UCSounds/Scorpion/death") --Crab needs death
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            ExplodeIntoRockyLoot(inst)
        end,
    },
    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.Transform:SetFourFaced() -- Incase somehow it got stuck on nofaced
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline =
        {
            TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/walk") end),
            --TimeEvent(3*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/mumble") end), -- Crab sounds please?
        },
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("moving") end),
        },
    },
    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline =
        {
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.myrock then
                    if inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) < 6^2 and not inst.uppercooldown and inst.myrock then
                        inst.uppercooldown = true
                        inst:DoTaskInTime(math.random(8,10),function(inst) inst.uppercooldown = nil end)
                        inst.sg:GoToState("uppercut")
                    else
                        inst.sg:GoToState("moving") 
                    end
                else
                    if (inst.components.combat and inst.components.combat.target) and inst:GetDistanceSqToInst(inst.components.combat.target) < 3^2 then
                        inst.sg:GoToState("dig")
                    else
                        inst.sg:GoToState("moving") 
                    end
                end
            end),
        },
        
    },
    State{
        name = "uppercut",
        tags = {"moving", "canrotate", "attack"},

        onenter = function(inst, target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("uppercut")
            inst:ListenForEvent("onhitother", KnockOutWeapon)
			inst.sg.statemem.target = target
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/attack_whoosh") end),
            --TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/clawsnap") end),
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(42*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(46*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
            TimeEvent(50*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        onexit = function(inst)
            inst.Physics:Stop()
            inst:RemoveEventCallback("onhitother", KnockOutWeapon)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("taunt") end),
        },
    },
    State{
        name = "pstmoving",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            inst.AnimState:PlayAnimation("walk_pst", false)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            inst.AnimState:PlayAnimation("idle", true)
        end,
    },
    State{
        name = "fuckingsad",
        tags = {"idle", "evade"},

        onenter = function(inst, start_anim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("fuck", true)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "eat",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("grab")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    State{
        name = "hide_pre",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hide_pre")
            TestIfShouldReHome(inst)
        end,

        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("hide") end),
        },
    },
    State{
        name = "hide",
        tags = {"busy", "noattack"},--You can only mine the boulder, they can't be attacked in this phase

        onenter = function(inst)
            inst.Transform:SetNoFaced()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hide_loop")
            inst.hiding = true
            local x,y,z = inst.Transform:GetWorldPosition()
            MakeObstaclePhysics(inst, 1)
            inst.Transform:SetPosition(x,y,z)
        end,

        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        onexit = function(inst)
            inst.Transform:SetFourFaced()
            inst.hiding = false
            inst.lasthidetime = GetTime()
            local x,y,z = inst.Transform:GetWorldPosition()
            MakeCharacterPhysics(inst, 400, .5)
            inst.Transform:SetPosition(x,y,z)
        end,
    },
    State{
        name = "hide_pst",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.Transform:SetFourFaced()
            inst.AnimState:PlayAnimation("hide_pst")
        end,

        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        events =
        {
            EventHandler("animover", function(inst) 
                if inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) < 5^2 then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    State{
        name = "investigate",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("UCSounds/Scorpion/taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:PerformBufferedAction()
                inst.sg:GoToState("idle")
            end),
        },
    },
    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.target = target
        end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/clawsnap") end),
            TimeEvent(24*FRAMES, function(inst) inst.components.combat:DoAttack(inst.sg.statemem.target) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if not inst.uppercooldown and inst.components.combat and inst.components.combat.target and inst:GetDistanceSqToInst(inst.components.combat.target) < 6^2 then
                    inst.uppercooldown = true
                    inst:DoTaskInTime(math.random(8,10),function(inst) inst.uppercooldown = nil end)
                    inst.sg:GoToState("uppercut", inst.sg.statemem.target)
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
    State{
        name = "dig",
        tags = {"busy"},

        onenter = function(inst)
            inst.Transform:SetNoFaced()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("dig")
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move") end),
            --TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move") end),
            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(47*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:AddStateTag("noattack")
                inst.SpawnHole(inst)
            end),
        },

        onexit = function(inst)
            if inst.SoundEmitter:PlayingSound("move") then inst.SoundEmitter:KillSound("move") end
        end,
    },
--[[State{
        name = "dirt",
        tags = {"busy", "noattack"},-- You can only mine the boulder, they can't be attacked in this phase.

        onenter = function(inst)
            inst.Transform:SetNoFaced()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("im_dirt")
            inst.hiding = true
            RemovePhysicsColliders(inst)
            if inst.components.health then
                inst:RemoveComponent("health")
            end
        end,
    },]]
    State{
        name = "emerge",
        tags = {"busy", "noattack"},-- You can only mine the boulder, they can't be attacked in this phase.

        onenter = function(inst)
            --inst.Transform:SetNoFaced()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emerge_pop")
            inst.hiding = true
        end,

        timeline =
        {
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(34*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(45*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(50*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(53*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(63*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/attack_whoosh") end),
            TimeEvent(72*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(80*FRAMES, function(inst) inst.SoundEmitter:PlaySound("UCSounds/Scorpion/snap") end),
            TimeEvent(90*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/clawsnap") end),
            TimeEvent(111*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(119*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(126*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/rocklobster/footstep") end),
            TimeEvent(155*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move") end),
            TimeEvent(166*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move") end),
            TimeEvent(170*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/move", "move") end),
        },

        onexit = function(inst)
            inst.Transform:SetFourFaced()
            inst.hiding = false
            local x,y,z = inst.Transform:GetWorldPosition()
            MakeCharacterPhysics(inst, 400, .5)
            inst.Transform:SetPosition(x,y,z)
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}

CommonStates.AddSleepStates(states,
{
    starttimeline = {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "fallAsleep")) end ),
    },
    sleeptimeline = 
    {
        TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "sleeping")) end ),
    },
    waketimeline = {
        TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound(SoundPath(inst, "wakeUp")) end ),
    },
})
CommonStates.AddFrozenStates(states)

return StateGraph("boulder_crab", states, events, "idle", actionhandlers)
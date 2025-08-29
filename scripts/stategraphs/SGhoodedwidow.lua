require("stategraphs/commonstates")
local easing = require("easing")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "jumphome"),
}

local function TryResetTargetCD(inst) -- Sometimes doing "special abilities" doesn't refresh Widow's aggro, meaning she may jump away if you don't tell her to retarget
    if inst.components.combat and inst.components.combat.target then
        inst.components.combat:SetTarget(inst.components.combat.target)
    end
end

local function ShootWebBomb(inst)
    if inst.components.combat and inst.components.combat.target then
        local target = inst.components.combat.target
        local web_attack = SpawnPrefab("web_bomb")
        web_attack.Transform:SetPosition(inst.Transform:GetWorldPosition())
        web_attack.components.projectile:Throw(inst, target, inst)
    end
end

local function RunningForAbility(inst) --Widow is making some space to use her ability
    if inst.components.timer and (not inst.components.timer:TimerExists("pounce") or not inst.components.timer:TimerExists("mortar")) then
        return true
    end
end

local function PlayPreyAnimations(inst) --Our Prey plays these animations
    local anim = inst:HasTag("smallcocoon") and "_small" or inst:HasTag("mediumcocoon") and "_medium" or "_large"
    inst.AnimState:PlayAnimation("hit"..anim, false)
    inst.AnimState:PushAnimation("idle"..anim, true)
end

local function ReadyToLeapOrStick(inst)
    if inst.components.timer and (not inst.components.timer:TimerExists("mortar") or not inst.components.timer:TimerExists("pounce")) then
        return true
    end
end

local function Eat(inst)
    local webbedcreature = FindEntity(inst, 2, nil, {"webbedcreature"})
    if webbedcreature then -- Food's here! Time to dine
        inst.prey = webbedcreature
        inst.sg:GoToState("eat_pre")
    else -- The prey was fake or was removed before we could eat it. Bummer.
        inst.prey = nil
    end
end

local function EndLeapFunction(inst, attack)
    inst.components.locomotor:Stop()
    if attack then
        inst.components.combat:DoAreaAttack(inst, 1.2 * TUNING.SPIDERQUEEN_ATTACKRANGE) --GroundPound Is purely visual --Had to reduce the AOE range a little bit, since Widow now tries to line up her jumps
        inst.components.groundpounder:GroundPound()
    end
    local x,y,z = inst.Transform:GetWorldPosition()
    MakeCharacterPhysics(inst, 1000, 1)
    inst.components.locomotor.pathcaps = {ignorecreep = true}
    inst.Transform:SetPosition(x, y, z) --I know this seems strange, but if I don't the widow actually teleports 
                                      --back to where it started its jump from right as MakeCharacterPhysics is called
                                      --this code makes it to where it moves the queen right back to where the end of the jump left it off.
end

local function RestartTimer(inst, name, time)
    if inst.components.timer:TimerExists(name) then
        inst.components.timer:SetTimeLeft(name, time)
    else
        inst.components.timer:StartTimer(name, time)
    end
end

local events =
{
    EventHandler("attacked", function(inst, data)
        if not (inst.components.health and inst.components.health:IsDead()) then
            if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
                return
            elseif inst.components.sleeper and inst.components.sleeper:IsAsleep() then
                inst.components.sleeper:WakeUp()
            elseif inst.sg:HasStateTag("charge") and (inst._bear_trap_speedmulttask or inst.components.sleeper.sleepiness > 0) then
                inst.sg:GoToState("chargeover")
            elseif not inst.sg:HasStateTag("electrocute") then
                if not inst.sg:HasStateTag("ability") and not inst.sg:HasStateTag("attack") and not RunningForAbility(inst) then 
                    inst.sg:GoToState("hit") 
                end
                if inst.sg:HasStateTag("eating") then -- If we're eating we definately need to go to hit
                    RestartTimer(inst, "pounce", math.random(3, 5)) --Restart Pounce (Make her do it soon)
                    RestartTimer(inst, "mortar", math.random(20, 30)) --Restart Mortar
                    inst.sg:GoToState("hit") 
                end
            end
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health and inst.components.health:IsDead()) then
            inst.sg:GoToState("attack", data.target)
        end
    end),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnElectrocute(),
}

local function ShadowFade(inst)
    inst.scaleFactor = inst.scaleFactor - 0.01
    inst.Transform:SetScale(inst.scaleFactor, inst.scaleFactor, inst.scaleFactor)
    if inst.scaleFactor < 0.05 then
        inst:Remove()
    end
end

local splashprefabs =
{
    "web_splash_fx_melted",
    "web_splash_fx_low",
    "web_splash_fx_med",
    "web_splash_fx_full",
}

local function WebMortar(inst, angle)
    if inst.components.combat.target ~= nil then
        local target = inst.components.combat.target
        local x, y, z = inst.Transform:GetWorldPosition()
        local projectile = SpawnPrefab("web_mortar")
        projectile.Transform:SetPosition(x,y,z)
        local scaleFactor = Lerp(.5, 1.5, 1)
        projectile.shadow = SpawnPrefab("warningshadow")
        projectile.shadow.scaleFactor = scaleFactor
        projectile.shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
        projectile.shadow = projectile.shadow:DoPeriodicTask(FRAMES, ShadowFade, nil, 5)
        local a, b, c = target.Transform:GetWorldPosition()
        local targetpos = target:GetPosition()
        if not angle then
            angle = 0
        end
        local theta = inst.Transform:GetRotation() + angle
        theta = theta*DEGREES
        targetpos.x = targetpos.x + 15 * math.cos(theta)
        targetpos.z = targetpos.z - 15 * math.sin(theta)

        projectile.components.complexprojectile:SetHorizontalSpeed(20)
        projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    end
end

local function Watercheck(inst)
    local angle = inst.Transform:GetRotation()
    local x,y,z = inst.Transform:GetWorldPosition()
    x = x + 4 * math.cos(angle)
    z = z + 4 * math.sin(angle)
    return not TheWorld.Map:IsVisualGroundAtPoint(x,y,z)
end


local function Charge_ReAssess(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, 6, {"_combat"}, {"webbedcreature"})
    local should_attack = false
    local should_exit = false
    local should_turnaround = false
    local should_climb = false
    for i,target in ipairs(targets) do
        local angle = inst:GetAngleToPoint(target:GetPosition())
        local my_angle = inst.Transform:GetRotation()
        if target and ((math.abs(angle-my_angle) < 60 and inst:GetDistanceSqToInst(target) < 12 ^ 2)) then
            --TheNet:Announce("Told To Attack")
            should_attack = true
        end
    end
    if inst.components.combat and not inst.components.combat.target then
        --TheNet:Announce("Told To Exit (No Target)")
        should_exit = true
    else
        local angle = inst:GetAngleToPoint(inst.components.combat.target:GetPosition())
        local my_angle = inst.Transform:GetRotation()
        if math.abs(angle-my_angle) > 90 and math.abs(angle-my_angle) < 270 and inst:GetDistanceSqToInst(inst.components.combat.target) > 14 ^ 2  then
            --TheNet:Announce("Told To Turn Around (Not Facing Target)")
            should_turnaround = true
        end
    end

    if Watercheck(inst) then
        --TheNet:Announce("Told To Turn Around (Water)")
        should_turnaround = true
    end

    if should_turnaround and inst.turns > 0 then
        --TheNet:Announce("Reducing Turns")
        inst.turns = inst.turns - 1
    elseif should_turnaround then
        --TheNet:Announce("Told To Exit (No more Turns)")
        should_turnaround = false
        should_exit = true
    end

    -- Decide what to do
    inst.sg:GoToState(should_exit and "chargeover" or should_turnaround and not inst.treetarget and "chargeturnaround"
        or should_attack and not inst.treetarget and "chargeattack" or "charge")
end

local function ChargeTurn(inst)
    inst.Physics:SetMotorVelOverride(inst.chargespeed*inst.components.locomotor.walkspeed*inst.components.locomotor:GetSpeedMultiplier(),0,0) -- Bear traps work...
    if inst.treetarget then
        inst:ForceFacePoint(inst.treetarget:GetPosition())
    else
        if inst.components.combat and inst.components.combat.target and inst.components.combat.target:IsValid() then
            local angle = inst:GetAngleToPoint(inst.components.combat.target:GetPosition())
            local my_angle = inst.Transform:GetRotation()

            local max_turning = 2 -- Only allow a certain maximum turning speed
            if angle > my_angle and math.abs(angle-my_angle) > 3 and inst.turn_speed < max_turning then
                inst.turn_speed = inst.turn_speed + 0.1
            elseif angle < my_angle and math.abs(angle-my_angle) > 3 and inst.turn_speed > -max_turning then
                inst.turn_speed = inst.turn_speed - 0.1
            end

            inst.go_up_fucking_tree = true
            if math.abs(angle-my_angle) > 90 and math.abs(angle-my_angle) < 270 and inst:GetDistanceSqToInst(inst.components.combat.target) > 12^2 then
                if inst.turns > 0 then
                    inst.turns = inst.turns - 1
                    inst.sg:GoToState("chargeturnaround")
                elseif not inst.go_up_fucking_tree then
                    inst.sg:GoToState("chargeover")
                elseif not inst.treetarget then
                    inst.DecideWhatTreeToBe(inst)
                    if inst.treetarget then
                        inst.sg:GoToState("chargeturnaround")
                    else
                        inst.sg:GoToState("chargeover")
                    end
                end
            end
            --TheNet:Announce("turning")
            inst.Transform:SetRotation(my_angle+inst.turn_speed)
        else
            inst.sg:GoToState("chargeover")
        end
    end
end
-- From Bearger
local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "FX", --[["NOCLICK",]] "DECOR", "INLIMBO" }

local function DestroyStuff(inst,x,y,z,rot, dist, radius, arc, nofx)
    if dist ~= 0 then
        x = x + dist * math.cos(rot)
        z = z - dist * math.sin(rot)
    end
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)) do
        if v:IsValid() and not v:IsInLimbo() and v.components.workable ~= nil then
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            if arc == nil or ((x1 ~= x or z1 ~= z) and DiffAngleRad(rot, math.atan2(z - z1, x1 - x)) < arc) then
                local work_action = v.components.workable:GetWorkAction()
                --V2C: nil action for NPC_workable (e.g. campfires)
                if (work_action == nil and v:HasTag("NPC_workable")) or
                    (v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
                then
                    if not nofx then
                        SpawnPrefab("collapse_small").Transform:SetPosition(x1, y1, z1)
                    end
                    v.components.workable:Destroy(inst)
                end
            end
        end
    end
end
-- From Bearger

local function ChargeAttacked(inst) -- Charge uses a slightly different attack, could probably be unified before going to live
    local x,y,z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation()
    DestroyStuff(inst,x,y,z,rot, 3, 3, 90, false)
    local targets = TheSim:FindEntities(x,y,z,inst.components.combat:GetHitRange(),{"_combat"},{"webbedcreature","ghost","bear_trap"})
    for i,target in ipairs(targets) do
        local angle = inst:GetAngleToPoint(target:GetPosition())
        if target and (math.abs(angle-rot) < 90 or inst:GetDistanceSqToInst(target) < 3^2) and target ~= inst then -- Relatively wide, but not completely to her side. (FUCKING SHE WAS KILLING HERSELF GODDAMN IT)
            local dmg = inst.components.combat:CalcDamage(target)
            target.components.combat:GetAttacked(inst,dmg)
        end
    end
end

-- From Bearger...

local ARC = 90 * DEGREES --degrees to each side
local AOE_RANGE_PADDING = 0
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "notarget", "noattack"}
local MAX_SIDE_TOSS_STR = 0.8

local function DoArcAttack(inst, dist, radius, heavymult, mult, forcelanded, targets, web)
    inst.components.combat.ignorehitrange = true
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation() * DEGREES
    local x0, z0
    local web_other
    if dist ~= 0 then
        if dist > 0 and ((mult ~= nil and mult > 1) or (heavymult ~= nil and heavymult > 1)) then
            x0, z0 = x, z
        end
        x = x + dist * math.cos(rot)
        z = z - dist * math.sin(rot)
    end
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and
            not (targets ~= nil and targets[v]) and
            v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead())
        then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and
                DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC and
                inst.components.combat:CanTarget(v)
            then
                if v:HasTag("webbedcreature") then
                    v.PlayHitAnimations(v)
                    local xv, yv, zv = v.Transform:GetWorldPosition()
                    SpawnPrefab("widow_web_combat").Transform:SetPosition(math.random(-1, 1) + xv, 0, math.random(-1, 1) + zv)
                else
                    if web then
                        if v.components.pinnable ~= nil then
                            v.components.pinnable:Stick("web_net_trap",splashprefabs)
                            v:DoTaskInTime(1, function(v) v.components.pinnable:Unstick() end)
                        end
                        web_other = true
                    elseif v:IsValid() then
                        inst.components.combat:DoAttack(v)
                    end
                end
                inst.hit_other = true
            end
        end
    end

    if web_other == true then
        inst.sg:GoToState("attack")
    end
    inst.components.combat.ignorehitrange = false
end


local states =
{

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            --if inst.should_go_tired then
                --inst.should_go_tired = false
                --inst.sg:GoToState("tired")
            --else
                inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle", true)
                if math.random() < .2 then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                end
            --end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.Physics:Stop()
            if inst.prey then --If we manage to pull off a melee attack, we should forget about trying to heal
                inst.prey = nil
            end
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.sg.statemem.original_target = target and target or inst.components.combat.target
            inst.hit_other = nil
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack")
            end),
            TimeEvent(10*FRAMES, function(inst) 
                inst.sg.statemem.tracking = false
            end),
            TimeEvent(25*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
            end),
            TimeEvent(29*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/swipe")
            end),
            TimeEvent(30*FRAMES, function(inst)
                DoArcAttack(inst, 0, TUNING.SPIDERQUEEN_ATTACKRANGE, nil, nil, nil, inst.sg.statemem.targets)
                if not inst.hit_other then
                    inst:PushEvent("onmissother", {target = inst.sg.statemem.original_target})
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle") 
            end),
        },
    },

    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/hurt")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.prey then --If we were hit out of snacking, then reposition
                    inst.prey = nil
                end
                inst.sg:GoToState("idle") 
            end),
        },
    },

    State{
        name = "tired",
        tags = {"busy", "ability"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("tired",false)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "eat_pre",
        tags = {"busy", "eating"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
            if inst.prey then --If we have prey, face it.
                inst:ForceFacePoint(inst.prey:GetPosition())
            end
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("eat_loop") end),
        },
    },

    State{
        name = "eat_loop",
        tags = {"eating"}, --not busy! we want the player to hit widow out of this

        onenter = function(inst, cb)
            inst.AnimState:SetDeltaTimeMultiplier(1.5)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_loop")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,

        timeline =
        {
            TimeEvent(25*FRAMES/1.5, function(inst)
                inst.components.health:DoDelta(200)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt")
                if inst.prey then
                    PlayPreyAnimations(inst.prey)
                end
            end),
        },

        onexit = function(inst)
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end,

        events =
        {
            EventHandler("animover",
                function(inst)
                    if inst.components.health and inst.components.health:GetPercent() < 1 then
                        inst.sg:GoToState("eat_loop")
                    else
                        if inst.prey then
                            inst.prey = nil
                        end
                        inst.sg:GoToState("idle")
                    end
                end),
        },
    },

    State{
        name = "eat_small",
        tags = {"busy", "ability", "eating"}, -- don't get taken out of the animation 

        onenter = function(inst, cb)
            inst.AnimState:HideSymbol("c1")
            inst.AnimState:SetBank("widow")
            inst.Transform:SetTwoFaced()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eatslow")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream")
        end,
        onexit = function(inst)
            inst.Transform:SetFourFaced()
        end,

        events =
        {
        EventHandler("animover", 
            function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/die")
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
        end,
    },

    State{
        name = "launchprojectile",
        tags = {"attack", "busy", "ability"},
        
        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shoot_pre")
            inst.AnimState:PushAnimation("shoot_loop", false)
            inst.AnimState:PushAnimation("shoot_pst", false)
        end,

        timeline =
        {
            TimeEvent(47*FRAMES, function(inst)
                ShootWebBomb(inst)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "lobprojectile",
        tags = {"attack", "busy", "ability"},

        onenter = function(inst)
            inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("shoot_pre")
            inst.AnimState:PushAnimation("shoot_loop", false)
            inst.AnimState:PushAnimation("shoot_pst", false)
            inst.AnimState:SetDeltaTimeMultiplier(1.5)
            if inst.components.combat.target then
                inst.sg.statemem.original_target = inst.components.combat.target
            end
        end,

        timeline =
        {
            TimeEvent(47*FRAMES/1.5, function(inst)
                DoArcAttack(inst, 0, TUNING.SPIDERQUEEN_ATTACKRANGE, nil, nil, nil, inst.sg.statemem.targets, true)
                if not inst.hit_other then
                    inst:PushEvent("onmissother", {target = inst.sg.statemem.original_target})
                end
                WebMortar(inst, -15)
                WebMortar(inst, 15)
                WebMortar(inst, 0)
                WebMortar(inst, -30)
                WebMortar(inst, 30)
                RestartTimer(inst, "mortar", (inst.components.health:GetPercent() < 0.5 and 25 or 30) + math.random(-3, 5)) --Under half health she speeeeds up
            end),
        },

        onexit = function(inst)
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)

            if not inst.components.timer:TimerExists("pounce") then --If Widow is planning on leaping get a new dodge destination
                inst.ShouldDodge(inst)
            end
            inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "tossplayer", --Not Finished
        tags = {"attack", "busy", "ability"},

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("poop_pre")
            inst.AnimState:PushAnimation("poop_loop", false)
            inst.AnimState:PushAnimation("poop_pst", false)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) 
        
            inst.sg:GoToState("attack") end),
        },
    },

    State{
        name = "fall",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            if inst:HasTag("notarget") then
                inst:RemoveTag("notarget")
            end
            inst.AnimState:PlayAnimation("fall")
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) 
                inst.components.combat:DoAreaAttack(inst, TUNING.SPIDERQUEEN_ATTACKRANGE*0.8) --GroundPound Is purely visual
                inst.components.groundpounder:GroundPound() 
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
            inst.sg:GoToState("taunt") end),
        },
    },

    State{
        name = "preleapattack",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("prejump")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("leapattack") end),
        },
    },

    State{
        name = "leapattack",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.physicschanged = true
            local speed = 10
            inst.components.locomotor:Stop()
            if inst.components.combat and inst.components.combat.target then
                inst.oldtarget = inst.components.combat.target
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            if inst.brain then
                inst.brain:Stop()
            end
            --inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
            inst.AnimState:PlayAnimation("leap", true)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(20*FRAMES, function(inst) EndLeapFunction(inst, true) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                RestartTimer(inst, "pounce", (inst.components.health:GetPercent() < 0.5 and 15 or 20) + math.random(-3, 5)) --Under half health she speeeeds up
                if inst.oldtarget and inst.oldtarget:IsValid() and inst.components.combat then
                    inst.components.combat:SuggestTarget(inst.oldtarget)
                end
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if not inst.components.timer:TimerExists("mortar") then --If Widow is still planning on Mortaring, we need to get a new dodge position
                inst.ShouldDodge(inst)
            end
            if inst.brain then
                inst.brain:Start()
            end
            if inst.physicschanged then
                EndLeapFunction(inst)
                inst.physicschanged = nil
            end
        end,
    },

    State{
        name = "leaptoprey_pre",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            if inst.prey then
                inst:ForceFacePoint(inst.prey:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("prejump")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("leaptoprey") end),
        },
    },

    State{
        name = "leaptoprey",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.physicschanged = true
            local speed = inst:GetDistanceSqToInst(inst.prey) ^ 0.5 / (FRAMES * 20)
            if speed > 15 then
                speed = 15
            end
            if inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.components.locomotor:Stop()
            if inst.prey then
                inst:ForceFacePoint(inst.prey:GetPosition())
            end
            if inst.brain then
                inst.brain:Stop()
            end
            --inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
            inst.AnimState:PlayAnimation("leap", true)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(20*FRAMES, function(inst) EndLeapFunction(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                if inst._dodgedest then -- If telling me to dodge to a point, move it closer to where I am
                    inst.ShouldDodge(inst)
                end
                if FindEntity(inst, 2, nil, {"webbedcreature"}) then
                    Eat(inst)
                else
                    inst.sg:GoToState(inst.prey and "leaptoprey_pre" or "idle")
                end
            end),
        },

        onupdate = function(inst)
            if inst:IsValid() and inst.prey and inst.prey:IsValid() and inst:GetDistanceSqToInst(inst.prey) < 2 ^ 2 then
                inst.Physics:SetMotorVelOverride(0, 0, 0)
            elseif inst.prey and not inst.prey:IsValid() then
                --[[print("found prey")
                print(inst.prey)
                print(inst.prey.prefab)]]
                local x, y, z = inst.prey.Transform:GetWorldPosition()
                inst.Transform:SetPosition(x, y, z)
                inst.Physics:SetMotorVelOverride(0, 0, 0)
            end
        end,

        onexit = function(inst)
            if inst.brain then
                inst.brain:Start()
            end
            if inst.components.combat then
                inst.components.combat:ResetCooldown()
            end
            if inst.physicschanged then
                EndLeapFunction(inst)
                inst.physicschanged = nil
            end
        end,
    },
-- [Charge -> Treeleap]
    State{
        name = "leaptotree",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.physicschanged = true
            local speed = inst:GetDistanceSqToInst(inst.treetarget)^ 0.5 / (FRAMES * 20)
            inst.components.locomotor:Stop()
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
            if inst.brain then
                inst.brain:Stop()
            end
            --inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
            inst.AnimState:PlayAnimation("leap_pre", false)
            inst.AnimState:PushAnimation("leap_loop", false)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(20*FRAMES, function(inst) EndLeapFunction(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                inst.sg:GoToState("tree_rebound") 
            end),
        },

        onupdate = function(inst)
            if inst:IsValid() and inst.treetarget and inst.treetarget:IsValid() and inst:GetDistanceSqToInst(inst.treetarget) < 2 ^ 2 then
                inst.Physics:SetMotorVelOverride(0, 0, 0)
            elseif inst.treetarget and not inst.treetarget:IsValid() then
                local x, y, z = inst.treetarget.Transform:GetWorldPosition()
                inst.Transform:SetPosition(x, y, z)
                inst.Physics:SetMotorVelOverride(0, 0, 0)
            end
        end,

        onexit = function(inst)
            if inst.brain then
                inst.brain:Start()
            end
            if inst.components.combat then
                inst.components.combat:ResetCooldown()
            end
            if inst.physicschanged then
                EndLeapFunction(inst)
                inst.physicschanged = nil
            end
        end,
    },

    State{
        name = "leaptotree_shake_pre",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            inst.AnimState:SetBank("widow")
            inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("prejump")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("leaptotree_shake_jump") end),
        },
    },

    State{
        name = "leaptotree_shake_jump",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.physicschanged = true
            local speed = inst:GetDistanceSqToInst(inst.treetarget) ^ 0.5 / (FRAMES * 20)
            inst.components.locomotor:Stop()
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
            if inst.brain then
                inst.brain:Stop()
            end
            --inst.components.inventory:Equip(inst.weaponitems.meleeweapon)
            inst.AnimState:PushAnimation("leap", false)
            inst.Physics:SetMotorVelOverride(speed,0,0)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(20*FRAMES, function(inst) EndLeapFunction(inst) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                inst.AnimState:PlayAnimation("shaketree_pre")
                inst.count = 0
                inst.sg:GoToState("leaptotree_shake_loop") 
            end),
        },

        onupdate = function(inst)
            if inst:IsValid() and inst.treetarget and inst.treetarget:IsValid() and inst:GetDistanceSqToInst(inst.treetarget) < 2^2 then
                inst.Physics:SetMotorVelOverride(0,0,0)
            elseif inst.treetarget and not inst.treetarget:IsValid() then
                local x,y,z = inst.treetarget.Transform:GetWorldPosition()
                inst.Transform:SetPosition(x,y,z)
                inst.Physics:SetMotorVelOverride(0,0,0)
            end
        end,

        onexit = function(inst)
            if inst.brain then
                inst.brain:Start()
            end
            if inst.components.combat then
                inst.components.combat:ResetCooldown()
            end
            if inst.physicschanged then
                EndLeapFunction(inst)
                inst.physicschanged = nil
            end
        end,
    },

    State{
        name = "leaptotree_shake_loop",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
            inst.count = inst.count + 1
            inst.components.locomotor:Stop()
            inst.AnimState:PushAnimation("shaketree_loop", false)
            if inst.brain then
                inst.brain:Stop()
            end
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) 
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, .03, 1, inst, 40)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") 
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) 
                if inst.count < 5 then
                    inst.sg.statemem.exitcondition = true
                    inst.sg:GoToState("leaptotree_shake_loop") 
                else
                    inst.sg:GoToState("leaptotree_shake_pst") 
                end
            end),
        },

        onexit = function(inst)
            inst.ShakeTree(inst,inst.treetarget)
            if inst.count < 5 and not inst.sg.statemem.exitcondition then
                if not inst.searching_for_tree then
                    inst.FindTreeToShake(inst) -- didn't get to finish ability, retry after done sleeping or being frozen
                end
            elseif inst.exitcondition then
                inst.sg.statemem.exitcondition = nil
            end
            if inst.brain then
                inst.brain:Start()
            end
        end,
    },

    State{
        name = "leaptotree_shake_pst",
        tags = {"busy", "noweb", "ability"},
        onenter = function(inst)
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
            inst.AnimState:PlayAnimation("shaketree_pst",false)
            if inst.brain then
                inst.brain:Stop()
            end
        end,
        
        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        
        onexit = function(inst)
            if inst.brain then
                inst.brain:Start()
            end
            inst.treetarget = nil
            inst.Retarget(inst)
        end,
    },

    State{
        name = "tree_rebound",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            inst.components.locomotor.walkspeed = 3 --Reset the running speed back to normal
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hang_switch")
            if inst.brain then
                inst.brain:Stop()
            end
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("tree_leapattack") end),
        },

        onexit = function(inst)
            if inst.brain then
                inst.brain:Start()
            end
            inst.treetarget = nil
        end,
    },

    State{
        name = "tree_leapattack",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.physicschanged = true
            local speed = 15
            inst.components.locomotor:Stop()
            if inst.components.combat and inst.components.combat.target then
                inst.oldtarget = inst.components.combat.target
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
            if inst.brain then
                inst.brain:Stop()
            end
            inst.AnimState:PlayAnimation("hang_leap_pre")
            inst.AnimState:PushAnimation("hang_leap_loop", false)
            inst.AnimState:PushAnimation("leap_pst", false)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(20*FRAMES, function(inst)
                --SpawnPrefab("antlion_sinkhole").Transform:SetPosition(inst.Transform:GetWorldPosition())
                EndLeapFunction(inst, true)
                TryResetTargetCD(inst)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/scream_short")
                if inst.oldtarget and inst.oldtarget:IsValid() and inst.components.combat then
                    inst.components.combat:SuggestTarget(inst.oldtarget)
                end
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            RestartTimer(inst, "pounce", math.random(40, 60)) -- Charging has a long cooldown
            if not inst.components.timer:TimerExists("mortar") then --If Widow is still planning on Mortaring, we need to get a new dodge position
                inst.ShouldDodge(inst)
            end
            if inst.brain then
                inst.brain:Start()
            end
            inst.Retarget(inst)
            if inst.physicschanged then
                EndLeapFunction(inst)
                inst.physicschanged = nil
            end
        end,
    },
-- [Leap Home Related] (Like fleeing combat)
    State{
        name = "jumphome",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst:AddTag("notarget")
            inst.AnimState:PlayAnimation("precanopy")
            inst.AnimState:PushAnimation("canopy", false)
            if inst.components.locomotor then -- Check to make sure 
                inst.components.locomotor:Stop()
            end
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) 
                inst:DoDespawn()
            end),
        },   
    },

    State{
        name = "precanopy",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("prejump")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("canopyjump") end),
        },
    },

    State{
        name = "canopyjump", --depricated
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("leap", true)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVel(0, 20, 0)
        end,

        events =
        {
            EventHandler("animover", function(inst) 
            inst:DoTaskInTime(1.5 + math.random(-1, 1), function(inst) inst.sg:GoToState("canopyland") end) end),
        },
    },

    State{
        name = "canopyland",
        tags = {"busy", "noweb", "ability"},
        onenter = function(inst, data)
            if inst:HasTag("notarget") then
                inst:RemoveTag("notarget")
            end
            inst.AnimState:PlayAnimation("fall")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
            inst.components.groundpounder:GroundPound()
            inst.components.combat:DoAreaAttack(inst, TUNING.SPIDERQUEEN_ATTACKRANGE * 1.2) --GroundPound Is purely visual
            inst.sg:GoToState("taunt") end),
        },
    },
-- [Charge Attack Related]
    State{
        name = "prechargeattack",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.turn_speed = 0
            inst.turns = 3
            inst.AnimState:PlayAnimation("charge_pre")
        end,

        onupdate = function(inst)
            if inst.components.combat and inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) 
                -- inst.Physics:ClearCollisionMask()
                -- inst.Physics:CollidesWith(COLLISION.WORLD)
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                if inst.brain then
                    inst.brain:Stop()
                end
                inst.components.sleeper.sleepiness = 0
                Charge_ReAssess(inst) --May need to immediately attack or turn
            end),
        },
    },

    State{
        name = "charge",
        tags = {"busy", "noweb", "ability", "charge"},

        onenter = function(inst, data)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            if inst.brain then
                inst.brain:Stop()
            end
            inst.AnimState:PlayAnimation("charge_loop", true)
            inst.treetarget = nil
        end,

        onupdate = ChargeTurn,

        timeline =
        {
            TimeEvent(0*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(7*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(10*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(13*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(17*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(25*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(32*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(38*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },

        events =
        {
            EventHandler("animover", Charge_ReAssess),
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            if inst.brain then
                inst.brain:Start()
            end
        end,
    },

    State{
        name = "chargeattack",
        tags = {"busy", "noweb", "ability", "charge"},

        onenter = function(inst, data)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            if inst.brain then
                inst.brain:Stop()
            end
            inst.AnimState:PlayAnimation("charge_strike", true)
        end,

        onupdate = ChargeTurn,

        timeline =
        {
            --Attack
            TimeEvent(0*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack") end),
            TimeEvent(0.4*25*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/attack_grunt") end),
            TimeEvent(0.4*30*FRAMES, function(inst) inst:PerformBufferedAction() inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/swipe") end),
            TimeEvent(0.4*30*FRAMES, ChargeAttacked),
            --Walk
            TimeEvent(0*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(7*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(10*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(13*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(17*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(25*0.4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(32*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(38*0.48*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },

        events =
        {
            EventHandler("animover", Charge_ReAssess),
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            if inst.brain then
                inst.brain:Start()
            end
        end,
    },

    State{
        name = "chargeturnaround",
        tags = {"busy", "noweb", "ability", "charge"},

        onenter = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            if inst.brain then
                inst.brain:Stop()
            end
            inst.turn_speed = 0
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_turn")
            if inst.treetarget then
                inst:ForceFacePoint(inst.treetarget:GetPosition())
            end
        end,

        onupdate = function(inst)
            if inst.components.combat and inst.components.combat.target and not inst.treetarget then
                inst:ForceFacePoint(inst.components.combat.target:GetPosition())
            end
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst) 
                inst.sg:GoToState(inst.treetarget and "leaptotree" or "charge") 
            end),
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            if inst.brain then
                inst.brain:Start()
            end
        end,
    },

    State{
        name = "chargeover",
        tags = {"busy", "noweb", "ability"},

        onenter = function(inst)
            --TheNet:Announce("ToldToStop")
            inst.Physics:ClearMotorVelOverride()
            local x,y,z = inst.Transform:GetWorldPosition()
            MakeCharacterPhysics(inst, 1000, 1)
            inst.components.locomotor.pathcaps = {ignorecreep = true}
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.components.locomotor:Stop()
            inst.Transform:SetPosition(x,y,z)
            inst.AnimState:SetBank("widow")
            inst.AnimState:PlayAnimation("charge_pst", false)
            RestartTimer(inst, "pounce", math.random(40, 60)) -- Charging has a long cooldown
            inst.sg:SetTimeout(0.8) --Won't leave?
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_voice") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/givebirth_foley") end),
        },

        onexit = function(inst)
            inst.AnimState:SetBank("widow")
            if not inst.components.timer:TimerExists("mortar") then --If Widow is still planning on Mortaring, we need to get a new dodge position
                inst.ShouldDodge(inst)
            end
            if inst.brain then
                inst.brain:Start()
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("tired")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("tired") end),
        },
    },
}

CommonStates.AddSleepStates(states,
    {
        sleeptimeline = {
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/sleeping") end),
        },
    },
    {
        onsleep = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/fallasleep")
        end,
        onwake = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/wakeup")
        end
    }
)
local backupanim =
{
    startrun = "backup_pre",
    run = "backup_loop",
    stoprun = "backup_pst",
}

CommonStates.AddWalkStates(states,
    {
        walktimeline = {
            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(7*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
            TimeEvent(38*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderqueen/walk_spiderqueen") end),
        },
    }, nil, nil, nil,
    {
        startonenter = function(inst)
            if inst._dodgedest and ReadyToLeapOrStick(inst) and inst._enemypos and inst:GetDistanceSqToPoint(inst._enemypos) < inst:GetDistanceSqToPoint(inst._dodgedest) then
                inst.AnimState:SetBank("widow_backup")
                inst.AnimState:SetDeltaTimeMultiplier(-1)
            else
                inst.AnimState:SetBank("widow")
            end
        end,
        walkonexit = function(inst)
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end,
    }
)

CommonStates.AddFrozenStates(states)
CommonStates.AddElectrocuteStates(states)

return StateGraph("hoodedwidow", states, events, "fall", actionhandlers)
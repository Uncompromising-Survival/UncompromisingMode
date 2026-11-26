local brain = require "brains/hoodedwidowbrain"

local loot =
{
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "monstermeat",
    "silk",
    "silk",
    "silk",
    "silk",
    "widowsgrasp",
    "widowshead",
}

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "structure", "bird", "um_fern_fox" }
local RETARGET_ONE_OF_TAGS = { "player" }

local function Retarget(inst)
    if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() and not inst.sg:HasStateTag("attack") then
        local newtarget = FindEntity(inst, 64,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONE_OF_TAGS
        )

        if newtarget then
            inst.components.combat:SetTarget(newtarget)
        end
    end
end

local function CalcSanityAura(inst, observer)
    return -TUNING.SANITYAURA_HUGE
end

local function OnAttacked(inst, data)
    if data.attacker and not inst.sg:HasStateTag("attack") then
        inst.components.combat:SetTarget(data.attacker)
    end

    -- AXE Reduce the timer every time I take damage by an amount proportional to the damage
    if data and data.damage and inst.components.timer:TimerExists("summon") then
        local Timer = inst.components.timer
        local time = Timer:GetTimeLeft("summon")
        if time > data.damage * 3 / 50 then
            time = time - data.damage * 3 / 50
            Timer:SetTimeLeft("summon",time)
        end
    end

    if not inst.searching_for_tree and not inst.count and inst.components.health and inst.components.health:GetPercent() < 0.75 and inst.components.timer and not inst.components.timer:TimerExists("summon") then
        UMCommonFns.RestartTimer(inst, { name = "summon", time = 60})
    end
end

local function DoDespawn(inst)
    --Schedule new spawn time
    --Called at the time the hooded widow actually leaves the world.
    local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
    if home then
        home.components.childspawner:GoHome(inst)
        inst:AddTag("home")

        if home.components.timer:TimerExists("reroll_cocoons") then
            home.components.timer:ResumeTimer("reroll_cocoons")
        else
            home.components.timer:StartTimer("reroll_cocoons", TUNING.TOTAL_DAY_TIME * 20)
        end
    else
        inst:Remove() --Hooded Widow was probably debug spawned in?
    end
end



local function ShouldDodge(inst)
    --TheNet:Announce("Redefining")
    local x, y, z = inst.Transform:GetWorldPosition() --This is actually a fallback incase widow somehow doesn't have a target when attempting to do a special (her abilities really depend on her having a target)
    if inst.components.combat and inst.components.combat.target then
        x, y, z = inst.components.combat.target.Transform:GetWorldPosition()
    end
    local mindist = 99999
    local xtest, ztest, xnew, znew
    xnew = x --Fallback if somehow xnew and znew aren't redefined in the loop below (they should be)
    znew = z
    for i = 1, 8 do
        xtest = x + 10 * math.cos(3.14 * i / 4 + .01 * math.random(-50, 50))
        ztest = z + 10 * math.sin(3.14 * i / 4 + .01 * math.random(-50, 50))
        --SpawnPrefab("maxwell_smoke").Transform:SetPosition(xtest,y,ztest) --For testing which points widow will dodge to with visuals
        if mindist > inst:GetDistanceSqToPoint(xtest, y, ztest) and TheWorld.Map:IsAboveGroundAtPoint(xtest, y, ztest) and #TheSim:FindEntities(xtest, y, ztest, 3, { "giant_tree" }) == 0 then --We're looking for the dodge position closest to widow
            mindist = inst:GetDistanceSqToPoint(xtest, y, ztest)
            xnew = xtest
            znew = ztest
        end
    end
    inst._dodgedest = Vector3(xnew, y, znew)
    if inst.components.combat.target then
        inst._enemypos = inst.components.combat.target:GetPosition()
    end
end

local function EpicsCheck(inst) -- Widow will not tolerate being bullied by epics, you go fight them yourself!
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, { "epic" }, { "hoodedwidow", "leif" })
    for i, v in pairs(ents) do
        if v and v.components.combat and v.components.combat.target and v.components.combat.target == inst then
            inst.bullier = true
        end
    end
end

local function OtherFollowSymbol(inst, other)
    other.components.lootdropper:SetLoot(nil)
    local diff = 3
    other.DynamicShadow:Enable(false)
    other:AddTag("notarget")
    other:DoTaskInTime(10,function(other)
        if other then -- Fallback incase
            other:Remove()
        end
    end)
    other.entity:AddFollower():FollowSymbol(inst.GUID, "c1", math.random(-diff, diff), 0, math.random(-diff, diff) / 2)
    table.insert(inst.eatin_stuff,other)
end

local edible_creatures = { "spider", "aphid", "hound", "spider_trapdoor", "spider_trapdoor_hooded" }

local function ThisIsEdible(other)
    return table.contains(edible_creatures, other.prefab)
end

local function OnEatOther(inst, other)
    if not other.components.health:IsDead() and not inst.sg:HasStateTag("ability") and not inst.components.health:IsDead() then
        inst.to_heal = inst.to_heal + 1
        if not inst.sg:HasStateTag("eating") then 
            inst.sg:GoToState("eat_chew_pre") 
        end
        if other.brain then 
            other.brain:Stop() 
        end
        OtherFollowSymbol(inst, other)
    end
end

local function DoChewingHeal(inst)
    inst.components.health:DoDelta(200/inst.components.health.maxhealth*12000) -- Amount widow heals per spider (need to keep the default max health here, the tuning value may change.)
    local puddle = SpawnPrefab("um_goo_spider")
    puddle.Transform:SetPosition(inst.Transform:GetWorldPosition())
    puddle.AnimState:SetMultColour(0.5,0.5,0.5,1)
    inst.to_heal = inst.to_heal - 1
    if inst.to_heal > 0 then
        inst:DoTaskInTime(0.2,DoChewingHeal)
    end
end

----------------------------- Shake Loot Tables
local impact_loot =
{
    twigs = 1,
    log = .5,
}

local minion_loot =
{
    spider = 1,
}

local fx_loot =
{
    oceantree_leaf_fx_fall = 1,
}

local minion_loot2 =
{
    spider = 1,
    spider_trapdoor = 1,
}

local minion_loot3 =
{
    spider_trapdoor = 1,
}

-- tree.SpawnDebris(inst, target, loottable,target) -> tree.SpawnDebris(tree, who_to_attack, what_loot,where_to_appear)

local function ShadowFade(inst)
    inst.scaleFactor = inst.scaleFactor - .01
    inst.Transform:SetScale(inst.scaleFactor, inst.scaleFactor, inst.scaleFactor)
    if inst.scaleFactor < .05 then
        inst:Remove()
    end
end

local function ShakeTree(inst, tree)
    local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
    local target = nil
    if inst.components.combat and inst.components.combat.target then
        target = inst.components.combat.target
    end

    -- Spawn some near the player that will target the player
    if target then
        tree.SpawnDebris(tree, nil, minion_loot, target)
    end

    -- Spawn some near home that don't necessarily have any idea what they're doing
    if home then
        for i = 1, 4 do
            tree.SpawnDebris(tree, nil, fx_loot, home)
        end
        tree.SpawnDebris(tree, nil, minion_loot, home)
    end

    -- Spawn some near widow
    -- FX
    for i = 1, 4 do
        tree.SpawnDebris(tree, nil, fx_loot)
    end

    -- Enemies
    tree.SpawnDebris(tree, nil, inst.components.health:GetPercent() >= .5 and minion_loot
        or inst.components.health:GetPercent() < .5 and minion_loot2
        or inst.components.health:GetPercent() < .25 and minion_loot3)

    -- Other players
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 25)
    for i, player in ipairs(players) do
        if not (target and player == target) then
            -- FX
            for i = 1, 2 do
                tree.SpawnDebris(tree, nil, fx_loot, target)
            end

            -- Watch your head
            for i = 1, 2 do
                tree.SpawnDebris(tree, nil, minion_loot, player)
            end
        end
    end
end

local function ChooseTreeTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tree_dist = 50
    local trees = TheSim:FindEntities(x, y, z, tree_dist, { "giant_tree" })
    local mindist = tree_dist ^ 2
    for i, tree in ipairs(trees) do
        local treedist = inst:GetDistanceSqToInst(tree)
        if treedist < mindist then
            inst.treetarget = tree
            mindist = treedist
        end
    end
end

local function FindTreeToShake(inst)
    if inst.searching_for_tree then
        inst.searching_for_tree:Cancel()
    end
    inst.searching_for_tree = nil
    ChooseTreeTarget(inst)
    if inst.treetarget and not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("ability")) then
        inst.sg:GoToState("leaptotree_shake_pre")
    else
        inst.searching_for_tree = inst:DoTaskInTime(2, FindTreeToShake)
    end
end

local function PrepareTreeToShake(inst) -- Give a small delay
    inst.should_taunt_health_thresh = true
    if not inst.searching_for_tree then
        if inst.lasttrigger then
            if inst.components.health:GetPercent() < inst.lasttrigger then
                inst.searching_for_tree = inst:DoTaskInTime(8, FindTreeToShake)
            end
        else
            inst.searching_for_tree = inst:DoTaskInTime(8, FindTreeToShake)
        end
    end
    inst.lasttrigger = inst.components.health:GetPercent()
end

local function InitializeTreeShaking(inst)
    PrepareTreeToShake(inst)
end

local function CancelDodgeTimeOut(inst)
    if inst.dodgetimeouttask then
        inst.dodgetimeouttask:Cancel()
        inst.dodgetimeouttask = nil
    end
    inst._dodgetimeout = nil
end

local function SetDodgeTimeout(inst)
    inst.dodgetimeouttask = inst:DoTaskInTime(5,function(inst)
        inst._dodgetimeout = true
    end)
end

local function TryPowerMove(inst,data)
    if data.name == "special" then
        SetDodgeTimeout(inst)
        ShouldDodge(inst) --Timer's up, lets get a position to dodge to
    elseif data.name == "summon" then
        PrepareTreeToShake(inst)
    end
end

local function OnNewState(inst)
    if inst.components.timer:TimerExists("summon") then
        if inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("frozen") or inst.sg:HasStateTag("thawing") then
            inst.components.timer:PauseTimer("summon")
        else
            inst.components.timer:ResumeTimer("summon")
        end
    end
end

local function OnLoad(inst)
    inst.investigated = false
    if inst.components.health:GetPercent() < 0.75 then
        InitializeTreeShaking(inst)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLightWatcher()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, 1)

    inst.DynamicShadow:SetSize(7, 3)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("epic")
    inst:AddTag("largecreature")
    inst:AddTag("hoodedwidow")
    inst:AddTag("spider")

    inst.AnimState:SetBank("widow")
    inst.AnimState:SetBuild("widow1")
    inst.AnimState:PlayAnimation("idle", true)
    inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:SetStateGraph("SGhoodedwidow")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("drownable")

    ---------------------
    MakeLargeBurnableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.DSTU.WIDOW_HEALTH)
    inst:AddComponent("healthtrigger")


    inst.components.healthtrigger:AddTrigger(.75, InitializeTreeShaking) -- Also enables shaking

    ------------------
    inst:AddComponent("knownlocations")
    inst:AddComponent("combat")
    inst.components.combat.battlecryenabled = false -- We want to taunt in only specific instances
    inst.components.combat:SetRange(TUNING.SPIDERQUEEN_ATTACKRANGE)
    inst.components.combat:SetDefaultDamage(150)
    inst.components.combat.customdamagemultfn = function(inst, target)
        return target:HasTag("player") and .5 or 1
    end
    inst.components.combat:SetAttackPeriod(3)
    inst.Retarget = Retarget
    inst.components.combat:SetRetargetFunction(1, Retarget)
    ------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(4)
    ------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    ------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 0
    inst.components.groundpounder.destructionRings = 2
    inst.components.groundpounder.platformPushingRings = 2
    inst.components.groundpounder.numRings = 3
    ------------------

    inst.investigated = false -- Dictates Widow's urge to leave if she hasn't seen any people, will eventually be made true after no action.
    inst.DoDespawn = DoDespawn
    inst:SetBrain(brain)
    inst.OnLoad = OnLoad
    inst:ListenForEvent("attacked", OnAttacked)


    inst:AddComponent("timer")


    inst:ListenForEvent("timerdone", TryPowerMove)
    UMCommonFns.RestartTimer(inst, { name = "special", time = 15})
    
    inst:DoPeriodicTask(3, EpicsCheck)

    -- Called from SG to check if Widow should be dodging.
    inst.ShouldDodge = ShouldDodge

    
    -- Charge Variables
    inst.turn_speed = 0
    inst.turns = 0
    inst.chargespeed = 7 / 3

    -- Widow's SG calls this when she successfully lands a hit on an edible target, 5 of them may be eaten.
    inst.ThisIsEdible = ThisIsEdible
    inst.OnEatOther = OnEatOther

    -- For her ally devouring mechanic
    inst.to_heal = 0
    inst.DoChewingHeal = DoChewingHeal
    inst.eatin_stuff = {} -- temp table holding the prefabs she's got in her claws when she's about to eat them

    inst.ChooseTreeTarget = ChooseTreeTarget -- This looks for which tree she's gonna hop to.
    inst.FindTreeToShake = FindTreeToShake
    inst.ShakeTree = ShakeTree
    inst.CancelDodgeTimeOut = CancelDodgeTimeOut

    -- Freezing nerfs
    local freezable = MakeLargeFreezableCharacter(inst, "body")
    freezable:SetResistance(TUNING.DRAGONFLY_FREEZE_THRESHOLD / 3)
    freezable.damagetobreak = TUNING.DRAGONFLY_FREEZE_RESIST / 3
    freezable.diminishingreturns = true

    inst:ListenForEvent("onremove",function(inst) -- Fallback: Remove the stuff we grabbed if we're removed while holding things
        if inst.eatin_stuff and #inst.eatin_stuff > 0 then
            for i,v in ipairs(inst.eatin_stuff) do
                v:Remove()
            end
            inst.eatin_stuff = {} -- Reset the table      
        end
    end)


    -- Make Widow pause her summon timer if she's stunned
    inst:ListenForEvent("newstate", OnNewState)

    return inst
end

return Prefab("hoodedwidow", fn)

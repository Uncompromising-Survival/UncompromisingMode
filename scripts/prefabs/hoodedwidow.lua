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
    --"silksack",
}

local RETARGET_MUST_TAGS = {"_combat"}
local RETARGET_CANT_TAGS = {"INLIMBO", "structure", "bird", "um_fern_fox"}
local RETARGET_ONE_OF_TAGS = {"player"}
local function Retarget(inst)
    if not inst.components.health:IsDead() and not inst.components.sleeper:IsAsleep() and not inst.sg:HasStateTag("attack") then
        local newtarget = FindEntity(inst, 20,
            function(guy)
                return inst.components.combat:CanTarget(guy)
                --distsq(spx, spz, dx, dz) >= (TUNING.DRAGONFLY_RESET_DIST * 12)
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
    --return (inst.components.health and inst.components.health:GetPercent() < .5) and -TUNING.SANITYAURA_HUGE*2 or -TUNING.SANITYAURA_HUGE
    return -TUNING.SANITYAURA_HUGE
end

local function OnAttacked(inst, data)
    if data.attacker and not inst.sg:HasStateTag("attack") then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function DoDespawn(inst)
    --Schedule new spawn time
    --Called at the time the hooded widow actually leaves the world.
    local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
    if home then
        home.components.childspawner:GoHome(inst)
        --home.components.childspawner:StartSpawning()
        inst:AddTag("home")
    else
        inst:Remove() --Hooded Widow was probably debug spawned in?
    end
end

local function OnLoad(inst)
    inst.investigated = false
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
        if mindist > inst:GetDistanceSqToPoint(xtest, y, ztest) and TheWorld.Map:IsAboveGroundAtPoint(xtest, y, ztest) and #TheSim:FindEntities(xtest, y, ztest, 3, {"giant_tree"}) == 0 then --We're looking for the dodge position closest to widow
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

local function TryPowerMove(inst)
    ShouldDodge(inst) --Timer's up, lets get a position to dodge to
end

local function Reset(inst)
    inst.reset = true
end

local function EpicsCheck(inst) -- Widow will not tolerate being bullied by epics, you go fight them yourself!
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20, {"epic"}, {"hoodedwidow", "leif"})

    -- if inst.components.homeseeker and inst.components.homeseeker.home and inst:GetDistanceSqToInst(inst.components.homeseeker.home) > TUNING.DRAGONFLY_RESET_DIST * 20 then
    -- inst.bullier = true
    -- end

    for i, v in pairs(ents) do
        if v and v.components.combat and v.components.combat.target and v.components.combat.target == inst then
            inst.bullier = true
        end
    end
end

local function OtherFollowSymbol(inst, other)
    other.components.lootdropper:SetLoot(nil)
    local diff = 10
    other.DynamicShadow:Enable(false)
    other.entity:AddFollower():FollowSymbol(inst.GUID, "c1", math.random(-diff, diff), 0, math.random(-diff, diff) / 2)
    other:DoTaskInTime(1, function(other) other:Remove() end) -- Give it a second before removal.
end

local function OnHitOther(inst, data)
    local other = data.target
    if other.prefab == "spider" or other.prefab == "aphid" or other.prefab == "hound" or (other.prefab == "spider_trapdoor" and other.components.health:GetPercent() < .5) then -- these guys get KO-ed
        if not inst.components.health:IsDead() and (not inst.sg:HasStateTag("ability") or inst.sg:HasStateTag("eating")) then
            inst.components.health:DoDelta(100)
            --[[if other.prefab == "spider_trapdoor" then
                inst.components.health:DoDelta(50)
            end]]
            if not inst.sg:HasStateTag("eating") then inst.sg:GoToState("eat_small") end
            if other.brain then other.brain:Stop() end
            OtherFollowSymbol(inst, other)
        end
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

local function WebMortarCanopy(inst, target)
    local projectile = SpawnPrefab("web_mortar")

    local scaleFactor = Lerp(.5, 1.5, 1)
    projectile.shadow = SpawnPrefab("warningshadow")
    projectile.shadow.scaleFactor = scaleFactor
    projectile.shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
    projectile.shadow = projectile.shadow:DoPeriodicTask(FRAMES, ShadowFade, nil, 5)
    local targetpos = target:GetPosition()
    targetpos.x = targetpos.x + math.random(-6, 6)
    targetpos.z = targetpos.z + math.random(-6, 6)
    projectile.components.complexprojectile:SetHorizontalSpeed(1)
    projectile.Transform:SetPosition(targetpos.x, 20, targetpos.z)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
end

local function ShakeTree(inst, tree)
    local home = inst.components.homeseeker and inst.components.homeseeker.home or nil
    local target = nil
    if inst.components.combat and inst.components.combat.target then
        target = inst.components.combat.target
    end

    -- Spawn some near the player that will target the player
    if target then
        --WebMortarCanopy(inst, target)
        for i = 1, 4 do
            tree.SpawnDebris(tree, target, fx_loot, target)           -- FX
            tree.SpawnDebris(tree, target, impact_loot, target, true) -- Watch your head
        end

        -- Enemies
        --tree.SpawnDebris(tree, target, minion_loot, target)
        --tree.SpawnDebris(tree, target, minion_loot, target)
        tree.SpawnDebris(tree, nil, minion_loot, target)
    end

    -- Spawn some near home that don't necessarily have any idea what they're doing
    if home then
        -- FX
        WebMortarCanopy(inst, home)
        for i = 1, 4 do
            tree.SpawnDebris(tree, nil, fx_loot, home)
        end

        -- Watch your head
        for i = 1, 2 do
            tree.SpawnDebris(tree, nil, impact_loot, home, true)
        end

        -- Enemies
        --tree.SpawnDebris(tree, nil, minion_loot, home)
        --tree.SpawnDebris(tree, nil, minion_loot, home)
        tree.SpawnDebris(tree, nil, minion_loot, home)
    end

    -- Spawn some near widow, these guys want to attack her
    -- FX
    for i = 1, 4 do
        tree.SpawnDebris(tree, inst, fx_loot)
    end

    -- Watch your head
    for i = 1, 2 do
        tree.SpawnDebris(tree, inst, impact_loot, nil, true)
    end

    -- Enemies
    --tree.SpawnDebris(tree, inst, minion_loot)
    --tree.SpawnDebris(tree, inst, minion_loot)
    tree.SpawnDebris(tree, nil, inst.components.health:GetPercent() >= .5 and minion_loot
        or inst.components.health:GetPercent() < .5 and minion_loot2
        or inst.components.health:GetPercent() < .25 and minion_loot3)

    --WebMortarCanopy(inst,inst)
    -- Other players
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 25)
    for i, player in ipairs(players) do
        if not (target and player == target) then
            -- FX
            for i = 1, 2 do
                tree.SpawnDebris(tree, player, fx_loot, target)
            end

            -- Watch your head
            for i = 1, 4 do
                tree.SpawnDebris(tree, player, impact_loot, player, true)
            end

            -- Enemies
            --tree.SpawnDebris(tree, target, minion_loot, target)
            --tree.SpawnDebris(tree, target, minion_loot, target)

            tree.SpawnDebris(tree, nil, minion_loot, player)
        end
    end
end

local function DecideWhatTreeToBe(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local trees = TheSim:FindEntities(x, y, z, 50, {"giant_tree"})
    local mindist = 15 ^ 2
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
    DecideWhatTreeToBe(inst)
    if inst.treetarget and not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("ability")) then
        inst.sg:GoToState("leaptotree_shake_pre")
    else
        inst.searching_for_tree = inst:DoTaskInTime(2, FindTreeToShake)
    end
end

local function RestartTimer(inst, name, time)
    if inst.components.timer:TimerExists(name) then
        inst.components.timer:SetTimeLeft(name, time)
    else
        inst.components.timer:StartTimer(name, time)
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

    local function PrepareTreeToShake(inst) -- Give a small delay
        if not inst.searching_for_tree then
            if inst.lasttrigger then
                if inst.components.health:GetPercent() < inst.lasttrigger then
                    inst.searching_for_tree = inst:DoTaskInTime(5, FindTreeToShake)
                end
            else
                inst.searching_for_tree = inst:DoTaskInTime(5, FindTreeToShake)
            end
        end
        inst.lasttrigger = inst.components.health:GetPercent()
    end

    inst.components.healthtrigger:AddTrigger(.75, PrepareTreeToShake)
    inst.components.healthtrigger:AddTrigger(.5, PrepareTreeToShake)
    inst.components.healthtrigger:AddTrigger(.25, PrepareTreeToShake)

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
    inst.components.locomotor.pathcaps = {ignorecreep = true}
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    ------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({FOODTYPE.MEAT}, {FOODTYPE.MEAT})
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater.strongstomach = true -- can eat monster meat!

    ------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("leader")

    MakeHauntableGoToState(inst, "poop", TUNING.HAUNT_CHANCE_OCCASIONAL, TUNING.HAUNT_COOLDOWN_MEDIUM, TUNING.HAUNT_CHANCE_LARGE)
    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 0
    inst.components.groundpounder.destructionRings = 2
    inst.components.groundpounder.platformPushingRings = 2
    inst.components.groundpounder.numRings = 3
    ------------------
    inst.investigated = false
    inst.Reset = Reset
    inst.DoDespawn = DoDespawn
    inst:SetBrain(brain)
    inst.OnLoad = OnLoad
    inst:ListenForEvent("attacked", OnAttacked)
    inst.combo = 1
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", TryPowerMove)
    RestartTimer(inst, "pounce", 10 + math.random(-3, 1))
    RestartTimer(inst, "mortar", 20 + math.random(-1, 5))
    inst:DoPeriodicTask(3, EpicsCheck)
    inst.ShouldDodge = ShouldDodge
    inst.combosucceed = true
    inst.docombo = false

    inst.turn_speed = 0
    inst.turns = 0
    inst.chargespeed = 7 / 3

    inst:ListenForEvent("onhitother", OnHitOther)

    inst.DecideWhatTreeToBe = DecideWhatTreeToBe -- This looks for which tree she's gonna hop to.
    inst.FindTreeToShake = FindTreeToShake
    inst.ShakeTree = ShakeTree

    local freezable = MakeLargeFreezableCharacter(inst, "body")
    freezable:SetResistance(TUNING.DRAGONFLY_FREEZE_THRESHOLD / 3)
    freezable.damagetobreak = TUNING.DRAGONFLY_FREEZE_RESIST / 3
    freezable.diminishingreturns = true

    return inst
end

return Prefab("hoodedwidow", fn)

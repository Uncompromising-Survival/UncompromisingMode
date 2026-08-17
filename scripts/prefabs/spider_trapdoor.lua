SetSharedLootTable('spider_trapdoor',
{
    { 'monstermeat', 1.00 },
})

SetSharedLootTable('spider_trapdoor_hooded',
{
    { 'silk', 1.00 },
})

local brain = require "brains/spiderbrain_trapdoor"

local function ShouldAcceptItem(inst, item, giver)
    if inst.components.health ~= nil and inst.components.health:IsDead() then
        return false, "DEAD"
    end

    if inst.components.inventoryitem:IsHeld() and not inst.components.eater:CanEat(item) then
        return false, "SPIDERNOHAT"
    end

    return
        (giver:HasTag("spiderwhisperer") and inst.components.eater:CanEat(item)) or
        (item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD)
end

local SPIDER_TAGS = { "spider" }
local SPIDER_IGNORE_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "creaturecorpse" }
local function GetOtherSpiders(inst)
    tags = tags or SPIDER_TAGS
    local x, y, z = inst.Transform:GetWorldPosition()

    local spiders = TheSim:FindEntities(x, y, z, 15, nil, SPIDER_IGNORE_TAGS, tags)
    local valid_spiders = {}

    for _, spider in ipairs(spiders) do
        if spider:IsValid() and not spider.components.health:IsDead() and not spider:HasTag("playerghost") then
            table.insert(valid_spiders, spider)
        end
    end

    return valid_spiders
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.eater:CanEat(item) then
        inst.components.eater:Eat(item)

        if inst.components.inventoryitem.owner ~= nil then
            inst.sg:GoToState("idle")
        else
            inst.sg:GoToState("eat", true)
        end

        local playedfriendsfx = false
        if inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        elseif giver.components.leader ~= nil and
            inst.components.follower ~= nil then
            if giver.components.minigame_participator == nil then
                giver:PushEvent("makefriend")
                giver.components.leader:AddFollower(inst)
                playedfriendsfx = true
            end
        end

        if giver.components.leader ~= nil then
            local spiders = GetOtherSpiders(inst) --note: also returns the calling instance of the spider in the list
            local maxSpiders = TUNING.SPIDER_FOLLOWER_COUNT

            for i, v in ipairs(spiders) do
                if v ~= inst then
                    if maxSpiders <= 0 then
                        break
                    end

                    local effectdone = true

                    if v.components.combat.target == giver then
                        v.components.combat:SetTarget(nil)
                    elseif giver.components.leader ~= nil and
                        v.components.follower ~= nil and
                        v.components.follower:GetLeader() == nil then
                        if not playedfriendsfx then
                            giver:PushEvent("makefriend")
                            playedfriendsfx = true
                        end
                        giver.components.leader:AddFollower(v)
                    else
                        effectdone = false
                    end

                    if effectdone then
                        maxSpiders = maxSpiders - 1

                        if v.components.sleeper:IsAsleep() then
                            v.components.sleeper:WakeUp()
                        end
                    end
                end
            end
        end
    -- I also wear hats
    elseif item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("taunt")
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function IsSpiderAlly(inst, target)
    if inst.components.combat:IsAlly(target) then
        return true
    elseif target:HasTag("companion") then
        local target_leader = target.components.follower and target.components.follower:GetLeader()
        return target_leader ~= nil and target_leader:HasTag("spiderwhisperer")
    end
    return false
end

local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "spiderwhisperer", "spiderdisguise", "INLIMBO" }
local function FindTarget(inst, radius)
    if not inst.no_targeting then
        return FindEntity(
            inst,
            SpringCombatMod(radius),
            function(guy)
                return (not inst.bedazzled and (guy.isplayer or not guy:HasTag("monster")))
                    and inst.components.combat:CanTarget(guy)
                    and not IsSpiderAlly(inst, guy)
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )
    end
end

local function NormalRetarget(inst)
    return FindTarget(inst, inst.components.knownlocations:GetLocation("investigate") ~= nil and TUNING.SPIDER_INVESTIGATETARGET_DIST or TUNING.SPIDER_TARGET_DIST)
end

local function WarriorRetarget(inst)
    return FindTarget(inst, TUNING.SPIDER_TARGET_DIST)
end

local function keeptargetfn(inst, target)
   return target ~= nil
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and not (inst.components.follower ~= nil and
                (inst.components.follower:GetLeader() == target or inst.components.follower:IsLeaderSame(target)))
end

local function BasicWakeCheck(inst)
    return inst.components.combat:HasTarget()
        or (inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome())
        or inst.components.burnable:IsBurning()
        or inst.components.freezable:IsFrozen()
        or inst.components.health.takingfiredamage
        or inst.components.follower:GetLeader() ~= nil
        or inst.summoned
end

local function ShouldSleep(inst)
    return TheWorld.state.iscaveday and not BasicWakeCheck(inst)
end

local function ShouldWake(inst)
    return not TheWorld.state.iscaveday
        or BasicWakeCheck(inst)
        or (inst:HasTag("spider_warrior") and
            FindTarget(inst, TUNING.SPIDER_WARRIOR_WAKE_RADIUS) ~= nil)
end

local function DoReturn(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    if home ~= nil and
        home.components.childspawner ~= nil and
        not (inst.components.follower ~= nil and
            inst.components.follower:GetLeader() ~= nil) then
        home.components.childspawner:GoHome(inst)
    end
end

local function OnIsCaveDay(inst, iscaveday)
    if not iscaveday then
        inst.components.sleeper:WakeUp()
    elseif inst:IsAsleep() then
        DoReturn(inst)
    end
end

local function OnEntitySleep(inst)
    if TheWorld.state.iscaveday then
        DoReturn(inst)
    end
end

local SPIDERDEN_TAGS = {"spiderden"}
local function SummonFriends(inst, attacker)
    local radius = (inst.prefab == "spider" or inst.prefab == "spider_warrior") and
                    SpringCombatMod(TUNING.SPIDER_SUMMON_WARRIORS_RADIUS) or
                    TUNING.SPIDER_SUMMON_WARRIORS_RADIUS

    local den = GetClosestInstWithTag(SPIDERDEN_TAGS, inst, radius)

    if den ~= nil and den.components.combat ~= nil and den.components.combat.onhitfn ~= nil then
        den.components.combat.onhitfn(den, attacker)
    end
end

local function FruitBatRetreat(inst)
    inst.fruitbat_panic = true
    inst:DoTaskInTime(60, function(inst) inst.fruitbat_panic = false end) -- Hide away for a minute.
end

local function IsHost(dude)
    return dude:HasTag("shadowthrall_parasite_hosted")
end

local function OnAttacked(inst, data)
    if inst.no_targeting then
        return
    end

    inst.defensive = false
    if data.attacker:HasTag("fruitbat") then FruitBatRetreat(inst) end
    inst.components.combat:SetTarget(data.attacker)

    if inst:HasTag("shadowthrall_parasite_hosted") then
        inst.components.combat:ShareTarget(data.attacker, 30, IsHost, 10)
    else
        inst.components.combat:ShareTarget(data.attacker, 30, function(dude)
                local should_share = dude:HasTag("spider")
                    and not dude.components.health:IsDead()
                    and dude.components.follower ~= nil
                    and dude.components.follower:GetLeader() == inst.components.follower:GetLeader()

                if should_share and dude.defensive and not dude.no_targeting then
                    dude.defensive = false
                end

                return should_share
            end, 10)
    end
end

local function SetHappyFace(inst, is_happy) --Trapdoor spiders don't *actually* smile.
    if is_happy then
        inst.AnimState:OverrideSymbol("face", inst.build, "happy_face")
    else
        inst.AnimState:ClearOverrideSymbol("face")
    end
end

local function OnStartLeashing(inst, data)
    inst:SetHappyFace(true)
    inst.components.inventoryitem.canbepickedup = true

    if inst.recipe then
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        if leader.components.builder and not leader.components.builder:KnowsRecipe(inst.recipe) and leader.components.builder:CanLearn(inst.recipe) then
            leader.components.builder:UnlockRecipe(inst.recipe)
        end
    end
end

local function OnStopLeashing(inst, data)
    inst.defensive = false
    inst.no_targeting = false
    inst.components.inventoryitem.canbepickedup = false

    if not inst.bedazzled then
        inst:SetHappyFace(false)
    end
end

local function OnTrapped(inst, data)
    inst.components.inventory:DropEverything()
end

local function OnEat(inst, data)
    if data.food.components.spidermutator and data.food.components.spidermutator:CanMutate(inst) then
        data.food.components.spidermutator:Mutate(inst)
    end
end

local function OnDropped(inst, data)
    if ShouldWake(inst) then
        inst.sg:GoToState("idle")
    elseif ShouldSleep(inst) then
        inst.sg:GoToState("sleep")
    end
end

local function OnGoToSleep(inst)
    inst.components.inventoryitem.canbepickedup = true
end

local function OnWakeUp(inst)
    if inst.components.follower:GetLeader() == nil then
        inst.components.inventoryitem.canbepickedup = false
    end
end

local function CalcSanityAura(inst, observer)
    if observer:HasTag("spiderwhisperer") or inst.bedazzled or
    (inst.components.follower:GetLeader() ~= nil and inst.components.follower:GetLeader():HasTag("spiderwhisperer")) then
        return 0
    end

    return inst.components.sanityaura.aura
end

local function HalloweenMoonMutate(inst, new_inst)
    local leader = inst ~= nil and inst.components.follower ~= nil
        and new_inst ~= nil and new_inst.components.follower ~= nil
        and inst.components.follower:GetLeader()
        or nil

    if leader ~= nil then
        new_inst.components.follower:SetLeader(leader)
    end
end

local function OnPickup(inst)
    inst:PushEvent("detachchild")
    if inst.components.homeseeker then
        inst.components.homeseeker:SetHome(nil)
        inst:RemoveComponent("homeseeker")
    end
end

local function SoundPath(inst, event)
    return "dontstarve/creatures/spiderwarrior/" .. event
end

local function OnChangedLeader(inst, new_leader, prev_leader)
    inst._last_leader = prev_leader -- We lose leader on death, so save it here.
end

local function SaveCorpseData(inst, corpse)
    local leader = inst._last_leader
    if leader ~= nil and leader:IsValid() then
        corpse.components.entitytracker:TrackEntity("remember_leader", leader)
    end

    local home = inst.components.homeseeker and inst.components.homeseeker:GetHome()
    if home ~= nil then
        corpse.components.entitytracker:TrackEntity("spider_home", home)

        if home.components.childspawner and home.components.childspawner.emergencychildrenoutside[inst] then
            return { isemergencychild = true }
        end
    end
end

local DIET = { FOODTYPE.MEAT }
local BASE_PATHCAPS = { ignorecreep = true }
local function create_common(build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(1.5, .5)
    inst.Transform:SetFourFaced()

    inst:AddTag("cavedweller")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("canbetrapped")
    inst:AddTag("smallcreature")
    inst:AddTag("spider")
    inst:AddTag("drop_inventory_onpickup")
    inst:AddTag("drop_inventory_onmurder")
    inst:AddTag("spider_warrior")
    inst:AddTag("eatsrawmeat")
    inst:AddTag("strongstomach")
    inst:AddTag("trader")

    inst.AnimState:SetBank("spider")
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    MakeFeedableSmallLivestockPristine(inst)

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Transform:SetScale(1.1, 1.1, 1.1)
    ----------
    inst.OnEntitySleep = OnEntitySleep

    -- locomotor must be constructed before the stategraph!
    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier(1)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = BASE_PATHCAPS
    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:SetStateGraph("SGspider")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("monstermeat", 1)
    --inst.components.lootdropper:AddRandomLoot("silk", .5)
    inst.components.lootdropper:AddRandomLoot("spidergland", 1)
    inst.components.lootdropper:AddRandomHauntedLoot("spidergland", 1)
    inst.components.lootdropper.numrandomloot = 1

    ---------------------
    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    inst.components.burnable.flammability = TUNING.SPIDER_FLAMMABILITY
    ---------------------

    inst:AddComponent("health")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetOnHit(SummonFriends)

    inst:AddComponent("follower")
    inst.components.follower.OnChangedLeader = OnChangedLeader
    --inst.components.follower.maxfollowtime = TUNING.TOTAL_DAY_TIME

    ------------------

    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper:SetResistance(2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------

    inst:AddComponent("knownlocations")

    ------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet(DIET, DIET)
    inst.components.eater:SetCanEatHorrible()
    inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
    inst.components.eater:SetCanEatRawMeat(true)

    ------------------

    inst:AddComponent("inspectable")

    ------------------

    inst:AddComponent("inventory")
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetAbleToAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    -----------------
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.canbepickedup = false
    inst.components.inventoryitem.canbepickedupalive = true
    inst.components.inventoryitem:SetSinks(true)

    ------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------

    inst:AddComponent("acidinfusible")
    inst.components.acidinfusible:SetFXLevel(1)
    inst.components.acidinfusible:SetMultipliers(TUNING.ACID_INFUSION_MULT.STRONGER)

    ------------------

    inst:AddComponent("halloweenmoonmutable")
    inst.components.halloweenmoonmutable:SetPrefabMutated("spider_moon")
    inst.components.halloweenmoonmutable:SetOnMutateFn(HalloweenMoonMutate)

    ------------------

    MakeFeedableSmallLivestock(inst, TUNING.SPIDER_PERISH_TIME)
    MakeHauntablePanic(inst)

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:ListenForEvent("startleashing", OnStartLeashing)
    inst:ListenForEvent("stopleashing", OnStopLeashing)

    inst:ListenForEvent("ontrapped", OnTrapped)
    inst:ListenForEvent("oneat", OnEat)

    inst:ListenForEvent("ondropped", OnDropped)

    inst:ListenForEvent("gotosleep", OnGoToSleep)
    inst:ListenForEvent("onwakeup", OnWakeUp)

    inst:ListenForEvent("onpickup", OnPickup)

    inst:WatchWorldState("iscaveday", OnIsCaveDay)
    OnIsCaveDay(inst, TheWorld.state.iscaveday)

    inst.SoundPath = SoundPath
    inst.SaveCorpseData = SaveCorpseData

    inst.incineratesound = SoundPath(inst, "die")
    inst.spawn_lunar_mutated_tuning = "MOONSPIDERDEN_ENABLED"
    inst.lunar_mutation_chance = TUNING.SPIDER_WARRIOR_PRERIFT_MUTATION_SPAWN_CHANCE

    inst.build = build
    inst.SetHappyFace = SetHappyFace

    return inst
end

local function create_trapdoor()
    local inst = create_common("spider_trapdoor")

    inst:AddTag("trapdoorspider")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('spider_trapdoor')

    inst.components.health:SetMaxHealth(200)

    inst.components.combat:SetDefaultDamage(34)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_WARRIOR_ATTACK_PERIOD + math.random() * 2)
    inst.components.combat:SetRange(TUNING.SPIDER_WARRIOR_ATTACK_RANGE, TUNING.SPIDER_WARRIOR_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, WarriorRetarget)

    inst.components.locomotor.walkspeed = TUNING.SPIDER_WARRIOR_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_WARRIOR_RUN_SPEED * 1.1

    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst.recipe = "mutator_trapdoor"

    return inst
end

local function create_trapdoor_hooded()
    local inst = create_common("spider_trapdoor_hooded")

    inst:AddTag("trapdoorspider")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('spider_trapdoor_hooded')

    inst.components.health:SetMaxHealth(200)

    inst.components.combat:SetDefaultDamage(34)
    inst.components.combat:SetAttackPeriod(TUNING.SPIDER_WARRIOR_ATTACK_PERIOD + math.random() * 2)
    inst.components.combat:SetRange(TUNING.SPIDER_WARRIOR_ATTACK_RANGE, TUNING.SPIDER_WARRIOR_HIT_RANGE)
    inst.components.combat:SetRetargetFunction(2, WarriorRetarget)

    inst.components.locomotor.walkspeed = TUNING.SPIDER_WARRIOR_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.SPIDER_WARRIOR_RUN_SPEED * 1.1

    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst.hooded = true

    inst:ListenForEvent("onattackother", function(inst, data)
        if TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then
            if data.target.components.poisonable then
                data.target.components.poisonable:Poison(true)
            end
        end
    end)

    --inst.components.inspectable.nameoverride = "SPIDER_TRAPDOOR"

    inst.recipe = "mutator_trapdoor_hooded"

    return inst
end

return Prefab("spider_trapdoor", create_trapdoor),
    Prefab("spider_trapdoor_hooded", create_trapdoor_hooded)
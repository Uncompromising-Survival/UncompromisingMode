local assets =
{
    Asset("ANIM", "anim/hound_basic.zip"),
    Asset("ANIM", "anim/hound_basic_water.zip"),
    Asset("ANIM", "anim/hound.zip"),
    Asset("ANIM", "anim/hound_ocean.zip"),
    Asset("ANIM", "anim/hound_red.zip"),
    Asset("ANIM", "anim/hound_red_ocean.zip"),
    Asset("ANIM", "anim/hound_ice.zip"),
    Asset("ANIM", "anim/hound_ice_ocean.zip"),
    Asset("ANIM", "anim/hound_mutated.zip"),
    Asset("ANIM", "anim/rnehound.zip"),
    Asset("SOUND", "sound/hound.fsb"),
}

local assets_clay =
{
    Asset("ANIM", "anim/clayhound.zip"),
}

local prefabs =
{
    "houndstooth",
    "monstermeat",
    "redgem",
    "bluegem",
    "splash_green",
    "houndcorpse",
}

local prefabs_clay =
{
    "houndstooth",
    "redpouch",
    "eyeflame",
}

local gargoyles =
{
    "gargoyle_houndatk",
    "gargoyle_hounddeath",
}
local prefabs_moon = {}
for i, v in ipairs(gargoyles) do
    table.insert(prefabs_moon, v)
end
for i, v in ipairs(prefabs) do
    table.insert(prefabs_moon, v)
end

local brain = require("brains/houndbrain")
local rnebrain = require("brains/rnehoundbrain")
local moonbrain = require("brains/moonbeastbrain")
local sporebrain = require "brains/sporehoundbrain"

local sounds =
{
    pant = "dontstarve/creatures/hound/pant",
    attack = "dontstarve/creatures/hound/attack",
    bite = "dontstarve/creatures/hound/bite",
    bark = "dontstarve/creatures/hound/bark",
    death = "dontstarve/creatures/hound/death",
    sleep = "dontstarve/creatures/hound/sleep",
    growl = "dontstarve/creatures/hound/growl",
    howl = "dontstarve/creatures/together/clayhound/howl",
    hurt = "dontstarve/creatures/hound/hurt",
}

SetSharedLootTable('hound_lightning',
    {
        { 'monstermeat', 1.0 },
        { 'houndstooth', 1.0 },
        { 'goldnugget',  1.0 },
        { 'goldnugget',  0.5 },
    })

SetSharedLootTable('hound_magma',
    {
        { 'monstermeat', 1.00 },
        { 'monstermeat', 1.00 },
        { 'monstermeat', 1.00 },
        { 'monstermeat', 0.50 },
        { 'houndstooth', 1.00 },
        { 'houndstooth', 0.33 },
        { 'monstermeat', 1.0 },
        { 'flint',       1.0 },
        { 'rocks',       1.0 },
        { 'rocks',       0.5 },
        { 'redgem',      1.0 },
    })

SetSharedLootTable('hound_rne',
    {
        { 'monstermeat',   1.0 },
        { 'nightmarefuel', 1.0 },
        { 'nightmarefuel', 0.5 },
        { 'purplegem',     0.25 },
    })

SetSharedLootTable('hound_glacial',
    {
        { 'monstermeat', 1.00 },
        { 'monstermeat', 1.00 },
        { 'monstermeat', 1.00 },
        { 'monstermeat', 0.50 },
        { 'houndstooth', 1.00 },
        { 'houndstooth', 0.33 },
        { 'ice',         1.0 },
        { 'ice',         0.5 },
        { 'bluegem',     1.0 },
    })

SetSharedLootTable('hound_spore',
    {
        { 'spoiled_food',         1.0 },
        { 'houndstooth',          1.0 },
        { 'shroom_skin_fragment', 0.5 },

    })

local WAKE_TO_FOLLOW_DISTANCE = 8
local SLEEP_NEAR_HOME_DISTANCE = 10
local SHARE_TARGET_DIST = 30
local HOME_TELEPORT_DIST = 30

local NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
local FREEZABLE_TAGS = {"freezable"}

local SINKHOLD_BLOCKER_TAGS = {"hound_lightning"}

local function Zap(inst, posx, posz)
    --local projectile = SpawnPrefab("hound_lightning")
    --projectile.Transform:SetPosition(posx, 0, posz)

    local x = GetRandomWithVariance(posx, TUNING.ANTLION_SINKHOLE.RADIUS)
    local z = GetRandomWithVariance(posz, TUNING.ANTLION_SINKHOLE.RADIUS)

    local function IsValidSinkholePosition(offset)
        local x1, z1 = x + offset.x, z + offset.z
        if #TheSim:FindEntities(x1, 0, z1, TUNING.ANTLION_SINKHOLE.RADIUS * 1.9, SINKHOLD_BLOCKER_TAGS) > 0 then
            return false
        end
        return true
    end

    local offset = Vector3(0, 0, 0)
    offset = IsValidSinkholePosition(offset) and offset
        or FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 1.8 + math.random(), 9, IsValidSinkholePosition)
        or FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 2.9 + math.random(), 17, IsValidSinkholePosition)
        or FindValidPositionByFan(math.random() * 2 * PI, TUNING.ANTLION_SINKHOLE.RADIUS * 3.9 + math.random(), 17, IsValidSinkholePosition)
        or nil

    if offset then
        UMCommonFns.SpawnHoundLightning(inst, {pos = {x = x + offset.x, z = z + offset.z}})
    end
end

local function LaunchProjectile(inst, targetpos)
    local x, y, z = targetpos.Transform:GetWorldPosition()
    for i = 0, 2 do
        inst:DoTaskInTime(i * .4, function(inst) Zap(inst, x, z) end)
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

local function CancelCharge(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function Charge(inst)
    inst.task = inst:DoPeriodicTask(0.15, function(inst) Charging(inst) end)
end

local function ShouldWakeUp(inst)
    if DefaultWakeTest(inst) then
        return true
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    return leader and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
end

local function ShouldSleep(inst)
    return inst:HasTag("pet_hound")
        and not TheWorld.state.isday
        and not (inst.components.combat and inst.components.combat.target)
        and not (inst.components.burnable and inst.components.burnable:IsBurning())
        and (not inst.components.homeseeker or inst:IsNear(inst.components.homeseeker.home, SLEEP_NEAR_HOME_DISTANCE))
end

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local RETARGET_CANT_TAGS = { "wall", "houndmound", "hound", "houndfriend" }
local function IsValidTarget(guy, inst)
    -- Horror hounds won't attack our reviver! (Crystal-Crested Buzzards)
    if inst:HasTag("lunar_aligned") and guy:HasTag("mutantdominant") then
        return false
    end
    --
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    return guy ~= leader and inst.components.combat:CanTarget(guy)
end

local function retargetfn(inst)
    if inst.sg:HasStateTag("statue") then
        return
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader ~= nil and leader.sg ~= nil and leader.sg:HasStateTag("statue") then
        return
    end
    local playerleader = leader ~= nil and leader:HasTag("player")
    local ispet = inst:HasTag("pet_hound")
    return (leader == nil or
            (ispet and not playerleader) or
            inst:IsNear(leader, TUNING.HOUND_FOLLOWER_AGGRO_DIST))
        and FindEntity(inst, (ispet or leader ~= nil) and TUNING.HOUND_FOLLOWER_TARGET_DIST or TUNING.HOUND_TARGET_DIST, IsValidTarget, nil, RETARGET_CANT_TAGS)
        or nil
end

local function KeepTarget(inst, target)
    if inst.sg:HasStateTag("statue") then
        return false
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    local playerleader = leader ~= nil and leader:HasTag("player")
    local ispet = inst:HasTag("pet_hound")
    return (leader == nil or
            (ispet and not playerleader) or
            inst:IsNear(leader, TUNING.HOUND_FOLLOWER_RETURN_DIST))
        and inst.components.combat:CanTarget(target)
        and (not (ispet or leader ~= nil) or
            inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP))
end

local function IsNearMoonBase(inst, dist)
    local moonbase = inst.components.entitytracker:GetEntity("moonbase")
    return moonbase == nil or inst:IsNear(moonbase, dist)
end

local MOON_RETARGET_CANT_TAGS = { "wall", "houndmound", "hound", "houndfriend", "moonbeast" }
local function moon_retargetfn(inst)
    return IsNearMoonBase(inst, TUNING.MOONHOUND_AGGRO_DIST)
        and FindEntity(
            inst,
            TUNING.HOUND_FOLLOWER_TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            nil,
            MOON_RETARGET_CANT_TAGS
        )
        or nil
end

local function moon_keeptargetfn(inst, target)
    return IsNearMoonBase(inst, TUNING.MOONHOUND_RETURN_DIST)
        and inst.components.combat:CanTarget(target)
        and inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP)
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
        function(dude)
            return not (dude.components.health ~= nil and dude.components.health:IsDead())
                and (dude:HasTag("hound") or dude:HasTag("houndfriend"))
                and data.attacker ~= (dude.components.follower ~= nil and dude.components.follower:GetLeader() or nil)
        end, 5)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
        function(dude)
            return not (dude.components.health ~= nil and dude.components.health:IsDead())
                and (dude:HasTag("hound") or dude:HasTag("houndfriend"))
                and data.target ~= (dude.components.follower ~= nil and dude.components.follower:GetLeader() or nil)
        end, 5)
end

local function GetReturnPos(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rad = 2
    local angle = math.random() * TWOPI
    return x + rad * math.cos(angle), y, z - rad * math.sin(angle)
end

local function DoReturn(inst)
    if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
        if inst:HasTag("pet_hound") then
            if inst.components.homeseeker.home:IsAsleep() and not inst:IsNear(inst.components.homeseeker.home, HOME_TELEPORT_DIST) then
                inst.Physics:Teleport(GetReturnPos(inst.components.homeseeker.home))
            end
        elseif inst.components.homeseeker.home.components.childspawner ~= nil then
            inst.components.homeseeker.home.components.childspawner:GoHome(inst)
        end
    end
end

local function OnEntitySleep(inst)
    if not TheWorld.state.isday then
        DoReturn(inst)
    end
end

local function OnStopDay(inst)
    if inst:IsAsleep() then
        DoReturn(inst)
    end
end

local function OnSpawnedFromHaunt(inst)
    if inst.components.hauntable ~= nil then
        inst.components.hauntable:Panic()
    end
end

local function OnEnterWater(inst)
    inst.landspeed = inst.components.locomotor.runspeed
    inst.components.locomotor.runspeed = TUNING.HOUND_SWIM_SPEED
    inst.hop_distance = inst.components.locomotor.hop_distance
    inst.components.locomotor.hop_distance = 4
end

local function OnExitWater(inst)
    if inst.landspeed then
        inst.components.locomotor.runspeed = inst.landspeed
    end
    if inst.hop_distance then
        inst.components.locomotor.hop_distance = inst.hop_distance
    end
end

local function OnSave(inst, data)
    data.ispet = inst:HasTag("pet_hound") or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.ispet then
        inst:AddTag("pet_hound")
        if inst.sg ~= nil then
            inst.sg:GoToState("idle")
        end
    end
end

local function GetStatus(inst)
    return (inst.sg:HasStateTag("statue") and "STATUE")
        or nil
end

local function OnEyeFlamesDirty(inst)
    if TheWorld.ismastersim then
        if not inst._eyeflames:value() then
            inst.AnimState:SetLightOverride(0)
            inst.SoundEmitter:KillSound("eyeflames")
        else
            inst.AnimState:SetLightOverride(.07)
            if not inst.SoundEmitter:PlayingSound("eyeflames") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "eyeflames")
                inst.SoundEmitter:SetParameter("eyeflames", "intensity", 1)
            end
        end
        if TheNet:IsDedicated() then
            return
        end
    end

    if inst._eyeflames:value() then
        if inst.eyefxl == nil then
            inst.eyefxl = SpawnPrefab("eyeflame")
            inst.eyefxl.entity:SetParent(inst.entity) --prevent 1st frame sleep on clients
            inst.eyefxl.entity:AddFollower()
            inst.eyefxl.Follower:FollowSymbol(inst.GUID, "hound_eye_left", 0, 0, 0)
        end
        if inst.eyefxr == nil then
            inst.eyefxr = SpawnPrefab("eyeflame")
            inst.eyefxr.entity:SetParent(inst.entity) --prevent 1st frame sleep on clients
            inst.eyefxr.entity:AddFollower()
            inst.eyefxr.Follower:FollowSymbol(inst.GUID, "hound_eye_right", 0, 0, 0)
        end
    else
        if inst.eyefxl ~= nil then
            inst.eyefxl:Remove()
            inst.eyefxl = nil
        end
        if inst.eyefxr ~= nil then
            inst.eyefxr:Remove()
            inst.eyefxr = nil
        end
    end
end

local function OnStartFollowing(inst, data)
    if inst.leadertask ~= nil then
        inst.leadertask:Cancel()
        inst.leadertask = nil
    end
    if data == nil or data.leader == nil then
        inst.components.follower.maxfollowtime = nil
    elseif data.leader:HasTag("player") then
        inst.components.follower.maxfollowtime = TUNING.HOUNDWHISTLE_EFFECTIVE_TIME * 1.5
    else
        inst.components.follower.maxfollowtime = nil
        if inst.components.entitytracker:GetEntity("leader") == nil then
            inst.components.entitytracker:TrackEntity("leader", data.leader)
        end
    end
end

local function RestoreLeader(inst)
    inst.leadertask = nil
    local leader = inst.components.entitytracker:GetEntity("leader")
    if leader ~= nil and not leader.components.health:IsDead() then
        inst.components.follower:SetLeader(leader)
        leader:PushEvent("restoredfollower", { follower = inst })
    end
end

local function OnStopFollowing(inst, data)
    inst.leader_offset = nil
    local leader = inst.components.entitytracker:GetEntity("leader")
    if not inst.components.health:IsDead() then
        if leader ~= nil and not leader.components.health:IsDead() then
            inst.leadertask = inst:DoTaskInTime(.2, RestoreLeader)
        end
    else
        --temp bridge until replaced by an actual hound_corpse.
        --otherwise, there's a tiny window during the death anim for too many
        --hounds to be summoned.
        if leader == nil and data ~= nil and data.leader ~= nil and data.leader:IsValid() then
            leader = data.leader
        end
        if leader.RememberFollowerCorpse ~= nil and inst:IsValid() then
            leader:RememberFollowerCorpse(inst)
        end
    end
end

local function OnChangedLeader(inst, new, old)
    --ignore if new is nil, (always nil upon death)
    if new ~= nil then
        if new.prefab == "mutatedwarg" then
            inst.forcemutate = true
            inst.wargleader = new
            inst.components.follower:KeepLeaderOnAttacked()
        else
            inst.forcemutate = nil
            inst.wargleader = nil
            inst.components.follower:LoseLeaderOnAttacked()
        end
    end
end

local function SaveCorpseData(inst, corpse)
    if inst.wargleader ~= nil and inst.wargleader:IsValid() and not inst.wargleader.components.health:IsDead() then
        corpse.components.entitytracker:TrackEntity("warg", inst.wargleader)
        inst.wargleader:RememberFollowerCorpse(corpse)
    end

    local home = inst.components.homeseeker and inst.components.homeseeker:GetHome()
    if home ~= nil then
        corpse.components.entitytracker:TrackEntity("hound_home", home)
    end
end

local function fncommon(bank, build, morphlist, custombrain, stategraph, tags, data)
    data = data or {}

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("scarytoprey")
    inst:AddTag("scarytooceanprey")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("hound")
    inst:AddTag("canbestartled")

    if tags then
        for _, tag in pairs(tags) do
            inst:AddTag(tag)
            if tag == "clay" then
                inst:AddTag("electricdamageimmune")

                --inst._eyeflames = net_bool(inst.GUID, "magmahound._eyeflames", "eyeflamesdirty")   Eye flame no work :(
                --inst:ListenForEvent("eyeflamesdirty", OnEyeFlamesDirty)
            elseif tag == "lunar_aligned" then
                inst:AddTag("soulless") -- no wortox souls
            end
        end
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    if data.amphibious and build ~= "hound_ocean" then
        inst.AnimState:OverrideSymbol("shadow_ripple", "hound_ocean", "shadow_ripple")
        inst.AnimState:OverrideSymbol("water_ripple", "hound_ocean", "water_ripple")
    end

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = tags and table.contains(tags, "clay") and TUNING.CLAYHOUND_SPEED or TUNING.HOUND_SPEED

    inst:SetStateGraph(stategraph or "SGhound")
    inst.sg.mem.nocorpse = true
    inst.sg.mem.nolunarmutate = not data.canlunarmutate

    if data.amphibious then
        inst:AddComponent("embarker")
        inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
        inst.components.embarker.antic = true

        inst.components.locomotor:SetAllowPlatformHopping(true)

        inst:AddComponent("amphibiouscreature")
        inst.components.amphibiouscreature:SetBanks(bank, bank .. "_water")
        inst.components.amphibiouscreature:SetEnterWaterFn(OnEnterWater)
        inst.components.amphibiouscreature:SetExitWaterFn(OnExitWater)

        inst.components.locomotor.pathcaps = { allowocean = true }
    end

    inst:SetBrain(custombrain or brain)

    inst:AddComponent("follower")
    inst.components.follower.OnChangedLeader = OnChangedLeader

    inst:AddComponent("entitytracker")

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.HOUND_HEALTH)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound(inst.sounds.hurt)
    inst.components.combat.lastwasattackedtime = -math.huge --for brain

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('hound')

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    if tags and (table.contains(tags, "clay") or table.contains(tags, "unfathomable")) then
        inst.sg.mem.noelectrocute = true
        --inst.sg:GoToState("statue")

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    else
        inst:AddComponent("eater")
        inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
        inst.components.eater:SetCanEatHorrible()
        inst.components.eater:SetStrongStomach(true) -- can eat monster meat!

        inst:AddComponent("sleeper")
        inst.components.sleeper:SetResistance(3)
        inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
        inst.components.sleeper:SetSleepTest(ShouldSleep)
        inst.components.sleeper:SetWakeTest(ShouldWakeUp)
        inst:ListenForEvent("newcombattarget", OnNewTarget)

        if morphlist ~= nil then
            MakeHauntableChangePrefab(inst, morphlist)
            inst.components.hauntable.panicable = true
            inst:ListenForEvent("spawnedfromhaunt", OnSpawnedFromHaunt)
        else
            MakeHauntablePanic(inst)
        end
    end

    inst:WatchWorldState("stopday", OnStopDay)
    inst.OnEntitySleep = OnEntitySleep

    inst.SaveCorpseData = SaveCorpseData

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)

    return inst
end

local function ontimerdone(inst, data)
    if data.name == "lightningshot_cooldown" then inst.lightningshot = true end
end

local function DoLightningExplosion(inst)
    UMCommonFns.SpawnHoundLightning(inst, {pos = inst:GetPosition()})
end

local function OnLightningAttacked(inst, data)
    if not data then return end
    local attacker, weapon = data.attacker, data.weapon
    if inst.sg and inst.sg:HasStateTag("charging") and attacker and attacker.components.health and not attacker.components.health:IsDead() and data.stimuli ~= "soul"
        and (not weapon or ((not weapon.components.weapon or not weapon.components.weapon.projectile) and not weapon.components.projectile))
        and not (attacker.components.inventory and attacker.components.inventory:IsInsulated()) and not attacker:HasTag("catapult") then
        local damage_mult = 1
        if not IsEntityElectricImmune(attacker) then
            damage_mult = TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * attacker:GetWetMultiplier()
        end
        attacker.components.combat:GetAttacked(inst, damage_mult * TUNING.HOUND_DAMAGE, nil, "electric")
    end
end

local ISALLY_TAGS = {"hound", "houndfriend", "houndmound"}

local function IsAlly(inst, guy)
    -- Prevents lightning from forking from a Lightning Hound's target to other Hounds and friends.
    return UMCommonFns.IsAlly(inst, guy, ISALLY_TAGS)
end

local function fnlightning()
    local inst = fncommon("hound", "hound_lightning_ocean", { "firehound", "icehound" }, nil, nil, { "lightninghound", "electricdamageimmune" }, { amphibious = true })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.UMIsAlly = IsAlly

    inst.sg.mem.noelectrocute = true

    inst:AddComponent("electricattacks")
    inst.components.electricattacks:AddSource(inst)

    MakeMediumFreezableCharacter(inst, "hound_body")

    inst.components.lootdropper:SetChanceLootTable("hound_lightning")

    inst.components.combat:SetRange(10, 3)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.task = nil

    inst.LaunchProjectile = LaunchProjectile
    inst.CancelCharge = CancelCharge
    inst.Charge = Charge

    inst:ListenForEvent("attacked", OnLightningAttacked)
    inst:ListenForEvent("death", DoLightningExplosion)

    inst.lightningshot = true

    return inst
end

local function DoGlacialExplosion(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local spell = SpawnPrefab("deer_ice_circle")
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(6, spell.KillFX)
end

local function GlacialProjectile(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local numspikes = inst:HasTag("ice_shielded") and 25 or 15

    local target_pos = target:GetPosition()
    local angle = inst:GetAngleToPoint(target_pos)
    local rad = math.rad(angle)
    local speed = inst:HasTag("ice_shielded") and 25 or 30

    for i = 0, numspikes, 2 do
        inst:DoTaskInTime(i / speed, function(inst)
            if target == nil then
                return
            end

            local x1 = x + i * math.cos(rad) + math.random(-1, 1) / 5
            local z1 = z + i * -math.sin(rad) + math.random(-1, 1) / 5

            if #TheSim:FindEntities(x1, y, z1, 1, nil, nil, { "groundspike", "hound" }) >= 1 or not TheWorld.Map:IsVisualGroundAtPoint(x1, y, z1) then
                return
            end

            local spike = SpawnPrefab("glacialhound_icespike")
            spike.owner = inst
            spike.Transform:SetRotation(rad)
            spike.Transform:SetPosition(x1, y, z1)

            local size = Lerp(1.0, 0.75, i / numspikes)
            spike.Transform:SetScale(size, size, size)
        end)
    end
end

local function CancelGlacialCharge(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function GlacialCharging(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local x1 = x + math.random(-2, 2)
    local z1 = z + math.random(-2, 2)
    local y1 = 0 + 0.25 * math.random()

    local flakes = SpawnPrefab("deer_ice_flakes")
    flakes.AnimState:PlayAnimation("idle")
    flakes.Transform:SetPosition(x1, y1, z1)
    flakes:DoTaskInTime(1, flakes.Remove)
end

local function GlacialCharge(inst)
    inst.task = inst:DoPeriodicTask(.25, function(inst) GlacialCharging(inst) end)
end

local function OnGlacialAttacked(inst, data)
    if not data then return end
    local attacker, weapon = data.attacker, data.weapon
    if inst.sg and inst.sg:HasStateTag("charging") and attacker and attacker.components.health and not attacker.components.health:IsDead() and data.stimuli ~= "soul"
        and (not weapon or ((not weapon.components.weapon or not weapon.components.weapon.projectile) and not weapon.components.projectile)) and not attacker:HasTag("catapult") then
        if attacker.components.freezable then
            attacker.components.freezable:AddColdness(4)
            attacker.components.freezable:SpawnShatterFX()
        end

        if attacker.components.temperature then
            local mintemp = math.max(attacker.components.temperature.mintemp, 0)
            local curtemp = attacker.components.temperature:GetCurrent()
            if mintemp < curtemp then
                attacker.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
            end
        end
    end
end

local function RemoveFreezeProtection(inst)
    inst:RemoveTag("um_freezeprotection")
end

local function OnHitOtherFreeze(inst, data)
    local other = data.target

    if other and not data.weapon then
        if not (other.components.health and other.components.health:IsDead()) then
            if not other:HasTag("um_freezeprotection") and other.components.freezable and not other.components.freezable:IsFrozen() then
                other.components.freezable:AddColdness(2)
                other.components.freezable:SpawnShatterFX()

                if other:HasTag("player") and other.components.freezable:IsFrozen() then
                    other:AddTag("um_freezeprotection")

                    if other.freeze_protection_task then
                        other.freeze_protection_task:Cancel()
                        other.freeze_protection_task = nil
                    end

                    other.freeze_protection_task = other:DoTaskInTime(3, RemoveFreezeProtection)
                end
            end

            if other.components.temperature then
                local mintemp = math.max(other.components.temperature.mintemp, 0)
                local curtemp = other.components.temperature:GetCurrent()
                if mintemp < curtemp then
                    other.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
                end
            end
        end
    end
end

local function AddIceShield(inst, tier)
    local iceShield = SpawnPrefab("um_ice_shield")
    iceShield:Init(inst, "hound_body", tier)
end

local function RemoveIceShield(inst)
    inst:DoTaskInTime(50, function(inst)
        inst:PushEvent("regen_iceshield")
    end)
end

local function fnglacial()
    local inst = fncommon("um_ice_warg", "um_ice_warg", nil, nil, nil, { "glacialhound" } --[[, { amphibious = true }]])

    if not TheWorld.ismastersim then
        return inst
    end

    inst.UMIsAlly = IsAlly

    inst:ListenForEvent("ice_shield_death", RemoveIceShield)

    MakeMediumBurnableCharacter(inst, "hound_body")

    inst.RegenIceShield = AddIceShield

    inst:DoTaskInTime(0, function(inst)
        inst:PushEvent("regen_iceshield")
    end)

    inst.components.lootdropper:SetChanceLootTable('hound_glacial')

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)
    inst.Transform:SetScale(1.3, 1.3, 1.3)

    inst.components.combat:SetDefaultDamage(TUNING.DSTU.GLACIAL_HOUND_DAMAGE)
    inst.components.health:SetMaxHealth(TUNING.DSTU.GLACIAL_HOUND_HEALTH)

    inst.task = nil

    inst:ListenForEvent("attacked", OnGlacialAttacked)
    inst:ListenForEvent("death", DoGlacialExplosion)
    inst:ListenForEvent("onhitother", OnHitOtherFreeze)

    inst.LaunchProjectile = GlacialProjectile
    inst.CancelCharge = CancelGlacialCharge
    inst.Charge = GlacialCharge

    inst.lightningshot = true

    return inst
end

local function pipethrown(inst)
    RemovePhysicsColliders(inst)

    --inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:PlayAnimation("shoot")
    inst:AddTag("NOCLICK")
    inst.persists = false
end

local function onhit(inst, attacker, target)
    if not target:IsValid() or target:HasTag("hound") or target:HasTag("warg") then
        --target killed or removed in combat damage phase
        return
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.burnable ~= nil then
        if target.components.burnable:IsBurning() then
            target.components.burnable:Extinguish()
        elseif target.components.burnable:IsSmoldering() then
            target.components.burnable:SmotherSmolder()
        end
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    if target.components.freezable ~= nil and target.sg ~= nil and not target.sg:HasStateTag("frozen") then
        target.components.freezable:AddColdness(1.5, 1, true)
        target.components.freezable:SpawnShatterFX()
    end

    if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
        target.components.combat:GetAttacked(attacker, 25, inst)
        --target:PushEvent("attacked", { attacker = attacker, damage = 25, weapon = inst })
    end

    inst:Remove()
end

local function fnglacial_proj()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()

    inst.DynamicShadow:SetSize(2, 2)

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("glacial_hound_projectile")
    inst.AnimState:SetBuild("glacial_hound_projectile")
    inst.AnimState:PlayAnimation("shoot_side")
    inst.Transform:SetEightFaced()
    inst:AddTag("NOCLICK")
    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("projectile")

    RemovePhysicsColliders(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(25)
    inst.components.projectile:SetOnThrownFn(pipethrown)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(math.sqrt(3))
    inst.components.projectile:SetOnHitFn(onhit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    --inst.components.projectile:SetLaunchOffset(Vector3(0, 2, 0))

    inst:DoTaskInTime(5, inst.Remove)
    inst:DoTaskInTime(0, function(inst) SpawnPrefab("fx_ice_pop").Transform:SetPosition(inst.Transform:GetWorldPosition()) end)
    inst.persists = false

    return inst
end

local function DoMagmaExplosion(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local spell = SpawnPrefab("deer_fire_circle")
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(4, spell.KillFX)
end

local easing = require("easing")

local function ShootProjectile(inst, target)
    local target = inst.components.combat.target
    if target ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local projectile = SpawnPrefab("fireball_throwable")
        projectile.Transform:SetPosition(x, y, z)
        local a, b, c = target.Transform:GetWorldPosition()
        local targetpos = target:GetPosition()
        targetpos.x = targetpos.x + math.random(-1, 1)
        targetpos.z = targetpos.z + math.random(-1, 1)
        local dx = a - x
        local dz = c - z
        local rangesq = dx * dx + dz * dz
        local maxrange = 20
        local bigNum = 15
        local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange * 2)
        projectile:AddTag("canthit")
        --projectile.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS/2
        projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
        --projectile.components.complexprojectile:SetGravity(-25)
        projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    end
end

local function MagmaCharging(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local x1 = x + math.random(-2, 2)
    local z1 = z + math.random(-2, 2)
    local y1 = 0 + .25 * math.random()
    local chance = math.random()
    SpawnPrefab(chance >= .66 and "halloween_firepuff_1" or chance >= .33 and chance < .66 and "halloween_firepuff_2" or "halloween_firepuff_3").Transform:SetPosition(x1, y1, z1)
    local magmafire = SpawnPrefab("magmafire")
    magmafire.Transform:SetPosition(x1, 0, z1)
    magmafire.damager = inst
end

local function CancelMagmaCharge(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function MagmaCharge(inst)
    inst.task = inst:DoPeriodicTask(.25, function(inst) MagmaCharging(inst) end)
end

local function OnMagmaAttacked(inst, data)
    if not data then return end
    local attacker, weapon = data.attacker, data.weapon
    if inst.sg and inst.sg:HasStateTag("charging") and attacker and attacker.components.health and not attacker.components.health:IsDead() and data.stimuli ~= "soul"
        and (not weapon or ((not weapon.components.weapon or not weapon.components.weapon.projectile) and not weapon.components.projectile)) and not attacker:HasTag("catapult") then
        attacker.components.health:DoFireDamage(5, inst, true)
        if not attacker.components.fueled and attacker.components.burnable and not attacker.components.burnable:IsBurning() and not attacker:HasTag("burnt") then
            attacker.components.burnable:Ignite(true, inst, inst)
        end
    end
end

local ARC = 90 * DEGREES --degrees to each side
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "notarget", "noattack" }
local function PoofNearby(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation() * DEGREES
    local x0, z0
    local radius = 4
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, nil, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead()) then
            local attackable = UMCommonFns.IsNotFriendly(inst, v)
            if not attackable then return end
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC then
                if not v.components.fueled and v.components.burnable and not v.components.burnable:IsBurning() and not v:HasTag("burnt") then
                    v.components.burnable:Ignite()
                end
                if v.components.health then
                    v.components.health:DoFireDamage(10, nil, true)
                end
            end
        end
    end
end

local function SetUpFire(inst, degrand, speed, scale, damage)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("um_fire_projectile")
    local rot = inst.Transform:GetRotation()
    local dx = 1 * math.sin((rot + 90 + degrand) * DEGREES)
    local dz = 1 * math.cos((rot + 90 + degrand) * DEGREES)
    rot = rot + math.random(-20, 20)
    projectile.Transform:SetPosition(x + dx, 1, z + dz)
    projectile.Transform:SetRotation(rot)
    projectile.speed = speed
    projectile.scale = scale -- scale up sometimes.
    projectile.damage = damage
    projectile.damager = inst
end

local function ShootFireMagmaHound(inst, total_flame) --AXE obviously called by magmahound to perform its continuous fire breath attack
    for i = 1, total_flame do
        inst:DoTaskInTime(0 + math.random(1, 15) * FRAMES, function(inst)
            local degrand = 5
            local speed = 20
            local scale = 0.8 + math.random(0, 10) / 100
            SetUpFire(inst, 5, speed, scale, TUNING.DSTU.MAGMA_HOUND_FIRE_DAMAGE)
            PoofNearby(inst)
        end)
    end
end

local function FirePoof(inst) --AXE Visual support for when the fire hound is briefly charging the spitfire attack
    local x, y, z = inst.Transform:GetWorldPosition()
    local x1 = x + 0.05 * math.random(-10, 10)
    local z1 = z + 0.05 * math.random(-10, 10)
    local y1 = 0 + .25 * math.random()
    SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(x1, y1, z1)
    local magmafire = SpawnPrefab("magmafire")
    magmafire.Transform:SetPosition(x1, 0, z1)
    magmafire.damager = inst
end

local function OnHitOtherBurn(inst, data)
    local other = data.target
    local burntarget = other.components.rideable and other.components.rideable:GetRider() or other
    if burntarget and not (burntarget.components.health and burntarget.components.health:IsDead())
        and not burntarget.components.fueled and burntarget.components.burnable and not burntarget.components.burnable:IsBurning() and not burntarget:HasTag("burnt") then
        burntarget.components.burnable:Ignite(true, inst, inst)
        FirePoof(burntarget)
    end
end

local function fnmagma()
    local inst = fncommon("clayhound", "magmahound", nil, nil, nil, { "magmahound", "clay" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.UMIsAlly = IsAlly

    inst.ShootFire = ShootFireMagmaHound

    --[[if inst.sg ~= nil then
        inst.sg:GoToState("idle")
    end]]

    --MakeMediumFreezableCharacter(inst, "hound_body") No freeze bc haha FIRE
    inst.Transform:SetScale(1.2, 1.2, 1.2)
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.task = nil

    inst.components.combat:SetDefaultDamage(TUNING.DSTU.MAGMA_HOUND_DAMAGE)
    inst.components.health:SetMaxHealth(TUNING.DSTU.MAGMA_HOUND_HEALTH)

    inst.components.combat:SetRange(10, 3)

    --inst.components.freezable:SetResistance(4)

    inst.components.lootdropper:SetChanceLootTable('hound_magma')

    inst.LaunchProjectile = ShootProjectile
    inst.CancelCharge = CancelMagmaCharge
    inst.Charge = MagmaCharge

    inst:ListenForEvent("attacked", OnMagmaAttacked)
    inst:ListenForEvent("death", DoMagmaExplosion)
    inst:ListenForEvent("onhitother", OnHitOtherBurn)

    inst.foogley = 0

    inst.lightningshot = true
    inst.components.health.fire_damage_scale = 0 --AXE Magma hounds should take zero damage from the fire damage stimuli

    return inst
end

local function OnSporeCloudRemoved(inst)
    inst:RemoveEventCallback("attacked", inst.OnAttacked, inst.owner)
    inst:RemoveEventCallback("leaderchanged", inst.OnLeaderChanged, inst.owner)
    inst:RemoveEventCallback("onremove", inst.OnSporeHoundRemoved, inst.owner)
    inst:RemoveEventCallback("onremove", inst.OnSporeHoundRemoved)
end

local function SpawnSporeCloud(inst)
    local sporecloud = SpawnPrefab("sporecloud_toad")
    sporecloud.Transform:SetPosition(inst.Transform:GetWorldPosition())
    sporecloud.owner = inst
    sporecloud.NoTags = ISALLY_TAGS
    local follower = inst.components.follower
    local leader = follower and follower:GetLeader()
    if leader then sporecloud.ownerleader = leader end -- Look into refining and making this a thing for the other follower projectiles/traps.
    sporecloud.OnAttacked = function(_inst, data)
        if sporecloud.ownerleader == data.attacker then
            sporecloud.ownerleader = nil
        end
    end
    sporecloud.OnLeaderChanged = function(_inst, data)
        local health = _inst.components.health
        if not (health and health:IsDead()) then
            local newleader = data.new
            if sporecloud.ownerleader ~= newleader then
                sporecloud.ownerleader = newleader
            end
        end
    end
    sporecloud.OnSporeHoundRemoved = function(_inst) OnSporeCloudRemoved(sporecloud) end
    sporecloud:ListenForEvent("attacked", sporecloud.OnAttacked, sporecloud.owner)
    sporecloud:ListenForEvent("leaderchanged", sporecloud.OnLeaderChanged, sporecloud.owner)
    sporecloud:ListenForEvent("onremove", sporecloud.OnSporeHoundRemoved, sporecloud.owner)
    sporecloud:ListenForEvent("onremove", sporecloud.OnSporeHoundRemoved)
end

local function SporeCloudAttack(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2.5, {"_combat"}, {"wall", "hound", "houndfriend", "houndmound"})
    for i, v in ipairs(ents) do
        if not (v.components.health and v.components.health:IsDead()) and UMCommonFns.IsNotFriendly(inst, v) then
            v.components.combat:GetAttacked(inst, 25, nil)
        end
    end
    SpawnSporeCloud(inst)
end

local function DoSporeExplosion(inst)
    SpawnSporeCloud(inst)
end

local function OnHitOther_Spore(inst, data)
    if data.target and data.target:HasTag("player") and not data.target:HasAnyTag("hasplaguemask", "automaton") and TUNING.DSTU.MAXHPHITTERS then
        data.target.components.health:DeltaPenalty(.05)
    end
end

local function fnspore()
    --local inst = fncommon("hound", "hound_spore_ocean", nil, nil, nil, {"sporehound"}, {amphibious = true})
    local inst = fncommon("hound", "hound_spore", nil, nil, nil, {"sporehound"})

    if not TheWorld.ismastersim then
        return inst
    end

    inst.UMIsAlly = IsAlly

    --inst:SetBrain(sporebrain)

    inst.lightningshot = true

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.components.lootdropper:SetChanceLootTable('hound_spore')

    MakeMediumFreezableCharacter(inst, "hound_body")
    MakeMediumBurnableCharacter(inst, "hound_body")

    inst.LaunchProjectile = SporeCloudAttack

    inst:ListenForEvent("death", DoSporeExplosion)
    inst:ListenForEvent("onhitother", OnHitOther_Spore)

    return inst
end

local function AdjustVisibility(inst)
    local player = FindEntity(inst, 20 ^ 2, nil, { "player" })
    if player and player:IsValid() and inst:IsValid() then
        local dist = inst:GetDistanceSqToInst(player) / 50
        if dist < 1 then
            inst.AnimState:SetMultColour(1, 1, 1, 1 - dist)
            if inst:HasTag("notarget") then
                inst:RemoveTag("notarget")
            end
        else
            if not inst:HasTag("notarget") then
                inst:AddTag("notarget")
            end
            inst.AnimState:SetMultColour(1, 1, 1, 0)
        end
    else
        if not inst:HasTag("notarget") then
            inst:AddTag("notarget")
        end
        inst.AnimState:SetMultColour(1, 1, 1, 0)
    end
end

local function fnrne()
    local inst = fncommon("hound", "rnehound", nil, nil, nil, { "unfathomable", "shadow" })

    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.locomotor:SetTriggersCreep(false)
    inst:SetBrain(rnebrain)

    inst:DoPeriodicTask(FRAMES, AdjustVisibility)

    inst.components.lootdropper:SetChanceLootTable('hound_rne')
    inst.DynamicShadow:Enable(false)

    return inst
end

return Prefab("lightninghound", fnlightning, assets, prefabs),
    Prefab("glacialhound", fnglacial, assets, prefabs),
    Prefab("glacialhound_projectile", fnglacial_proj, assets, prefabs),
    Prefab("magmahound", fnmagma, assets, prefabs),
    Prefab("sporehound", fnspore, assets, prefabs),
    Prefab("rnehound", fnrne)
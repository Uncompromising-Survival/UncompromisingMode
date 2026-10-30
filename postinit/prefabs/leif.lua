local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddComponentPostInit("wisecracker", function(self)
    self.inst:ListenForEvent("rooting", function(_inst, data)
        _inst.components.talker:Say(GetString(_inst, "ANNOUNCE_ROOTING"))
    end)
end)

local prefabs = {
    "rootspike",
}

local function OnNewCombatTarget(inst, data)
	if data and data.target and not data.oldtarget then
        inst.um_engaged = true
        UMCommonFns.RestartTimer(inst, {name = "snare_cd", time = TUNING.STALKER_ABILITY_RETRY_CD, dontrestarttimer = true})
	end
end

local function OnDroppedTarget(inst)
    inst.um_engaged = nil
end

local function TrySnare(inst)
    local target = inst.components.combat.target
    if target and target:IsValid() and inst:GetDistanceSqToInst(target) < 200 then
        inst:PushEvent("snare", target)
    else
        if inst.um_engaged then inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_ABILITY_RETRY_CD) end
    end
end

local function OnTimerDone(inst, data)
    if data.name == "snare_cd" then
        TrySnare(inst)
    end
end

local SNARE_OVERLAP_MIN = 1
local SNARE_OVERLAP_MAX = 3
local SNARE_TAGS = { "_combat", "locomotor" }
local SNARE_NO_TAGS = { "flying", "ghost", "playerghost", "tallbird", "fossil", "shadow", "shadowminion", "INLIMBO",
    "epic", "smallcreature" }
local SNARE_MAX_TARGETS = 20

local function NoSnareOverlap(x, z, r)
    return #TheSim:FindEntities(x, 0, z, r or SNARE_OVERLAP_MIN, { "rootspike", "groundspike" }) <= 0
end

local function FindSnareTargets(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = {}
    local priorityindex = 1
    local priorityindex2 = 1
    local ents = TheSim:FindEntities(x, y, z, TUNING.STALKER_SNARE_RANGE, SNARE_TAGS, SNARE_NO_TAGS)
    for i, v in ipairs(ents) do
        if not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v:HasTag("player") then
            elseif v.components.combat:TargetIs(inst) then
                table.insert(targets, priorityindex2, v)
                priorityindex2 = priorityindex2 + 1
            else
                table.insert(targets, v)
            end
            if #targets >= SNARE_MAX_TARGETS then
                return targets
            end
        end
    end
    return #targets > 0 and targets or nil
end

local function SpawnSnare(inst, target)
    -- find target position
    local x, y, z = target.Transform:GetWorldPosition()
    local islarge = target:HasTag("largecreature")
    local r = target:GetPhysicsRadius(0) + (islarge and 1.5 or .5)
    local num = islarge and 12 or 6


    local vars = { 1, 2, 3, 4, 5, 6, 7 }
    local used = {}
    local queued = {}
    local count = 0
    local dtheta = PI * 2 / num
    local thetaoffset = math.random() * PI * 2
    local delaytoggle = 0
    local map = TheWorld.Map


    if x ~= nil and z ~= nil then
        for theta = math.random() * dtheta, PI * 2, dtheta do
            local x1 = x + r * math.cos(theta)
            local z1 = z + r * math.sin(theta)
            local boat = map:GetPlatformAtPoint(x, z)
            if boat then
                if boat.components.health ~= nil and not boat.components.health:IsDead() then
                    boat.components.health:DoDelta(-25)
                    boat:PushEvent("spawnnewboatleak",
                        { pt = target:GetPosition(), leak_size = "med_leak", playsoundfx = true, cause = "leif" })
                    break
                end
            elseif map:IsPassableAtPoint(x1, 0, z1) and not map:IsPointNearHole(Vector3(x1, 0, z1)) then
                local spike = SpawnPrefab("rootspike")
                spike.Transform:SetPosition(x1, 0, z1)

                local delay = delaytoggle == 0 and 0 or .2 + delaytoggle * math.random() * .2
                delaytoggle = delaytoggle == 1 and -1 or 1

                local duration = GetRandomWithVariance(TUNING.STALKER_SNARE_TIME, TUNING.STALKER_SNARE_TIME_VARIANCE)

                local variation = table.remove(vars, math.random(#vars))
                table.insert(used, variation)
                if #used > 3 then
                    table.insert(queued, table.remove(used, 1))
                end
                if #vars <= 0 then
                    local swap = vars
                    vars = queued
                    queued = swap
                end

                spike:RestartSpike(delay, duration, variation)
                count = count + 1
            end
        end
    end
    if count <= 0 then
        return false
    elseif target:IsValid() then
        if target.components.talker then
            target:PushEvent("rooting", { attacker = inst })
        end
    end
    return true
end

local function spawn_stumpling(target)
    local stumpling = SpawnPrefab(target:HasTag("deciduous") and "birchling" or "stumpling")

    if target.chopper then
        stumpling.components.combat:SuggestTarget(target.chopper)
    end

    local x, y, z = target.Transform:GetWorldPosition()
    local effect = SpawnPrefab("round_puff_fx_hi")
    effect.Transform:SetPosition(x, y, z)
    stumpling.Transform:SetPosition(x, y, z)
    stumpling.sg:GoToState("hit")
    target:Remove()
end

local STUMP_MUST_TAGS = {"stump"}
local STUMP_CANT_TAGS = {"leif", "burnt"}
local STUMP_ONEOF_TAGS = {"evergreens", "deciduoustree"}

local function find_leif_spawn_target(item)
    return not item.noleif
        and item.components.growable ~= nil
        and item.components.growable.stage <= 3
end

local function FindStump(inst, target)
    return FindEntity(target, TUNING.LEIF_MAXSPAWNDIST, find_leif_spawn_target, STUMP_MUST_TAGS, STUMP_CANT_TAGS, STUMP_ONEOF_TAGS)
end

local function SummonStumplings(inst, target)
    for k = 1, 3 do
        local stump = inst.UMFindStump and inst:UMFindStump(target)
        if stump then
            stump.noleif = true
            stump.chopper = target
            spawn_stumpling(stump)
        end
    end
end

--[[local function UnHide(inst, data)
    if data.statename ~= "sleeping" then
        inst.sg:RemoveStateTag("hiding")
        inst:RemoveEventCallback("newstate", UnHide)
    end
end

local function BossCheck(inst, data)
    if not inst.components.health:IsDead() and data.attacker ~= nil and data.attacker:HasTag("epic") then
        inst:PushEvent("bosshide")

        if inst.components.combat.target ~= nil and not inst.components.combat.target:HasTag("player") then
            inst.components.combat:DropTarget()
        end

        if data.attacker.components.combat:HasTarget() and not data.attacker.components.combat:TargetIs(inst) then
            data.attacker.components.combat:DropTarget()
        end
    end
end]]

local function OnHitOther(inst, other)
    if UMCommonFns.ShouldKnockback(other) then
        local x, y, z = other.Transform:GetWorldPosition()
        local roots = TheSim:FindEntities(x, y, z, 4, {"rootspike"})
        for k, v in ipairs(roots) do
            v.Physics:SetActive(false) --putting this here since the actual KillSpike has a ~1s delay from *actually* disabling physics.
            v.KillSpike(v, true)
        end
        other:PushEvent("knockback", {knocker = inst, radius = 75, strengthmult = 1})
    end
end

--[[local function isnottree(ent)
    if ent ~= nil and not ent:HasAnyTag("leif", "stumpling") then -- fix to friendly AOE: refer for later AOE mobs -Axe
        return true
    end
end]]

local AOE_EXCLUDE_TAGS = {"leif", "stumpling"}
local function ShouldDoConeCheck(ent, inst)
    return not inst.sg:HasStateTag("snare")
end

local function GetAreaHitRange(combat)
    return combat:GetHitRange()
end

local function GetAreaCircleRadius(combat)
    return GetAreaHitRange(combat) / 2
end

local function TreeguardFunctions(inst)
    local combat = inst.components.combat
    if combat then
        combat.onhitotherfn = OnHitOther
        -- Treeguard now has AOE - Axe
        combat:UMSetAreaDamage(GetAreaHitRange, AOE_EXCLUDE_TAGS, 120, GetAreaCircleRadius, ShouldDoConeCheck)
        --combat:SetAreaDamage(3, TUNING.DEERCLOPS_AOE_SCALE, isnottree) -- you can edit these values to your liking -Axe
    end

    local lootdropper = inst.components.lootdropper
    if lootdropper then
        lootdropper:SetLoot({"livinglog", "livinglog", "livinglog", "livinglog", "livinglog", "livinglog", "plantmeat"})
    end

    --inst:ListenForEvent("attacked", BossCheck)
	inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)

    inst.UMFindStump = FindStump
    inst.SummonStumplings = SummonStumplings
    inst.FindSnareTargets = FindSnareTargets
    inst.SpawnSnare = SpawnSnare
end

local treeguards = {"leif", "leif_sparse"}
for _, prefab in pairs(treeguards) do 
    env.AddPrefabPostInit(prefab, function(inst)
        TreeguardFunctions(inst)
    end)
end
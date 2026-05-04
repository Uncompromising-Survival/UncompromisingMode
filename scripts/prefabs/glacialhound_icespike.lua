local assets =
{
    Asset("ANIM", "anim/sharkboi_icespike.zip"),
    Asset("ANIM", "anim/sharkboi_iceplow_fx.zip"),
}

local prefabs_spike =
{
    "ice",
}

--------------------------------------------------------------------------

local RADIUS = 0.8
local RADIUS_LARGE = 1.4
local NUM_VARIATIONS = 3


--------------------------------------------------------------------------

local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then
            inst._pfpos = inst:GetPosition()
            --inflate pathfinder size a bit to prevent the varglets (which are apparently slightly larger than the player) from getting stuck.
            for x = -1, 1, .5 do
                for z = -1, 1, .5 do
                    local new_pos = Vector3(inst._pfpos.x + x, inst._pfpos.y, inst._pfpos.z + z)
                    TheWorld.Pathfinder:AddWall(new_pos:Get())
                end
            end
        end
    elseif inst._pfpos ~= nil then
        for x = -1, 1, .5 do
            for z = -1, 1, .5 do
                local new_pos = Vector3(inst._pfpos.x + x, inst._pfpos.y, inst._pfpos.z + z)
                TheWorld.Pathfinder:RemoveWall(new_pos:Get())
            end
        end

        inst._pfpos = nil
    end
end

local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty)
    OnIsPathFindingDirty(inst)
end

local function makeobstacle(inst)
    inst.Physics:SetActive(true)
    inst._ispathfinding:set(true)
end

local function clearobstacle(inst)
    inst.Physics:SetActive(false)
    inst._ispathfinding:set(false)
end

local function onremove(inst)
    inst._ispathfinding:set_local(false)
    OnIsPathFindingDirty(inst)
end

--------------------------------------------------------------------------


local DAMAGE_RADIUS_PADDING = 1.0

local function SpikeLaunch(inst, launcher, basespeed, startheight, startradius)
    local x0, y0, z0 = launcher.Transform:GetWorldPosition()
    local x1, y1, z1 = inst.Transform:GetWorldPosition()
    local dx, dz = x1 - x0, z1 - z0
    local dsq = dx * dx + dz * dz
    local angle
    if dsq > 0 then
        local dist = math.sqrt(dsq)
        angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
    else
        angle = TWOPI * math.random()
    end
    local sina, cosa = math.sin(angle), math.cos(angle)
    local speed = basespeed + math.random()
    inst.Physics:Teleport(x0 + startradius * cosa, startheight, z0 + startradius * sina)
    inst.Physics:SetVel(cosa * speed, speed * 5 + math.random() * 2, sina * speed)
end

local WORK_AMOUNTS =
{
    CHOP = 3,
    DIG = 1,
    HAMMER = 1,
    MINE = 3,
}

local COLLAPSIBLE_TAGS = { "frozen" --[[ for "ice" ]], "player", "pickable", "NPC_workable", "_combat" }

for action, _ in pairs(WORK_AMOUNTS) do
    table.insert(COLLAPSIBLE_TAGS, action .. "_workable")
end

local NON_COLLAPSIBLE_TAGS = { "hound", "flying", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO", "groundspike", "trap" }
local TOSSITEM_MUST_TAGS = { "_inventoryitem" }
local TOSSITEM_CANT_TAGS = { "locomotor", "INLIMBO", "trap" }

local function IsNotFriendly(attacker, target) -- Is the target an ally or my leader's ally?
    local attackercombat = attacker and attacker.components.combat
    local leader = attacker and attacker.components.follower and attacker.components.follower:GetLeader()
    local leadercombat = leader and leader.components.combat
    return attackercombat and attackercombat:CanTarget(target) and not attackercombat:IsAlly(target)
        and (not leader or leadercombat and leadercombat:CanTarget(target) and not leadercombat:IsAlly(target))
end

local function TargetHasHealth(target)
    return target and target:IsValid() and target.components.health
end

local function DealSpikeDamage(attacker, target, spike, damage)
    if not TargetHasHealth(target) then return end

    if target.components.combat then
        target.components.combat:GetAttacked(attacker, damage)
    else
        target.components.health:DoDelta(-damage, nil, attacker and attacker.prefab or "glacialhound_icespike")
    end

    spike.components.health:Kill()
end

local function DoWork(worker, target)
    if not (target and target:IsValid() and target.components.workable) then return false end

    local workable = target.components.workable
    if not workable:CanBeWorked() then return false end

    local work_action = workable:GetWorkAction()
    if not work_action then -- nil action for NPC_workable (e.g. campfires)
        if target:HasTag("NPC_workable") then
            workable:Destroy(worker)

            if target:IsValid() and target:HasTag("stump") then
                target:Remove()
            end

            return true
        end
        return false
    end

    -- Things with health should take damage instead of work.
    if TargetHasHealth(target) then return false end

    local work_amount = WORK_AMOUNTS[work_action.id]
    if work_amount then
        workable:WorkedBy(worker, work_amount)

        if target:IsValid() and target:HasTag("stump") and workable:GetWorkLeft() <= 0 then
            target:Remove()
        end

        return true
    end

    return false
end

local function DoDamage(inst)
    inst.dmgtask = nil
    local attacker = inst.owner and inst.owner:IsValid() and inst.owner or inst
    local radius = inst.islarge:value() and RADIUS_LARGE or RADIUS
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, radius + DAMAGE_RADIUS_PADDING, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v ~= inst and not (inst.targets and inst.targets[v]) and v:IsValid() then
            local attackable = IsNotFriendly(attacker, v)
            if v.prefab == "ice" then
                v:Remove()
            elseif v:HasTag("player") and attackable then
                --NOTE: inst.targets will prevent multiple knockbacks, but
                --      CreatePhysicsPush should still keep them in bounds
                v:PushEvent("knockback", { knocker = inst, radius = radius, strengthmult = .3, forcelanded = not inst.islarge:value() })
            end

            --TODO: Make not destroy for glacial hound?
            if attackable then
                DealSpikeDamage(attacker, v, inst, 30)

                if v.components.freezable then
                    v.components.freezable:AddColdness(2)
                end
            else
                local worked = DoWork(inst, v)

                if not worked and v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
                    v.components.pickable:Pick(inst)
                end
            end

            if inst.targets then
                inst.targets[v] = true
            end
        end
    end

    --Tossing we don't care about repeat targets
    local totoss = TheSim:FindEntities(x, 0, z, radius + DAMAGE_RADIUS_PADDING, TOSSITEM_MUST_TAGS, TOSSITEM_CANT_TAGS)
    for i, v in ipairs(totoss) do
        if v.prefab == "ice" then
            v:Remove()
        else
            if v.components.mine then
                v.components.mine:Deactivate()
            end
            if not v.components.inventoryitem.nobounce and v.Physics and v.Physics:IsActive() then
                SpikeLaunch(v, inst, .8 + radius, radius * .4, radius + v:GetPhysicsRadius(0))
            end
        end
    end
end

local function RefreshWorkLevel(inst, workleft)
    if inst.islarge:value() then
        if workleft <= TUNING.SHARKBOI_ICE_LARGE_MINE / 3 then
            inst.AnimState:PlayAnimation("spike4_low")
            return true
        elseif workleft <= TUNING.SHARKBOI_ICE_LARGE_MINE * 2 / 3 then
            inst.AnimState:PlayAnimation("spike4_med")
            return true
        end
    elseif workleft <= TUNING.SHARKBOI_ICE_MINE / 2 then
        inst.AnimState:PlayAnimation("spike" .. tostring(inst.variation) .. "_low")
        return true
    end
end
local function CreatePhysicsPush(parent)
    local inst = CreateEntity()

    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(TheWorld.ismastersim)
    inst.persists = false

    inst.entity:AddTransform()

    inst.entity:AddPhysics()
    inst.Physics:SetMass(999999)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        COLLISION.ITEMS,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS,
        COLLISION.WORLD
    )
    inst.Physics:SetCapsule(parent.islarge:value() and RADIUS_LARGE or RADIUS, 2)

    --inst:DoTaskInTime(0, inst.Remove)

    inst.Transform:SetPosition(parent.Transform:GetWorldPosition())

    return inst
end

local function SetVariation(inst, variation)
    variation = math.clamp(variation, 1, NUM_VARIATIONS + 1)
    if inst.variation ~= variation then
        if variation > NUM_VARIATIONS then
            if not inst.islarge:value() then
                inst.islarge:set(true)
                inst.Physics:SetCapsule(RADIUS_LARGE, 2)
                if inst.components.workable then
                    local workdone = TUNING.SHARKBOI_ICE_MINE - inst.components.workable:GetWorkLeft()
                    local workleft = math.clamp(TUNING.SHARKBOI_ICE_LARGE_MINE - workdone, 1, TUNING.SHARKBOI_ICE_LARGE_MINE)
                    inst.components.workable:SetWorkLeft(workleft)
                end
            end
        elseif inst.islarge:value() then
            inst.islarge:set(false)
            inst.Physics:SetCapsule(RADIUS, 2)
            if inst.components.workable then
                local workdone = TUNING.SHARKBOI_ICE_LARGE_MINE - inst.components.workable:GetWorkLeft()
                local workleft = math.clamp(TUNING.SHARKBOI_ICE_MINE - workdone, 1, TUNING.SHARKBOI_ICE_MINE)
                inst.components.workable:SetWorkLeft(workleft)
            end
        end

        if inst.AnimState:IsCurrentAnimation("spike" .. tostring(inst.variation) .. "_pre") then
            local t = inst.AnimState:GetCurrentAnimationTime()
            inst.AnimState:PlayAnimation("spike" .. tostring(variation) .. "_pre")
            inst.AnimState:SetTime(t)
            inst.AnimState:PushAnimation("spike" .. tostring(variation), false)
        elseif not (inst.components.workable and RefreshWorkLevel(inst, inst.components.workable:GetWorkLeft())) then
            inst.AnimState:PlayAnimation("spike" .. tostring(variation))
        end
        inst.variation = variation
    end
end

local function OnSave(inst, data)
    data.variation = inst.variation ~= 1 and inst.variation or nil
    if inst.dmgtask then
        data.dodmg = true
    elseif inst.components.workable then
        local totalwork = inst.islarge:value() and TUNING.SHARKBOI_ICE_LARGE_MINE or TUNING.SHARKBOI_ICE_MINE
        local workdone = totalwork - inst.components.workable:GetWorkLeft()
        if workdone > 0 then
            data.worked = workdone
        end
    end
end

local function OnLoad(inst, data)
    if not (data and data.dodmg) then
        if inst.dmgtask then
            inst.dmgtask:Cancel()
            inst.dmgtask = nil
        end
        inst.AnimState:PlayAnimation("spike" .. tostring(inst.variation))
    end
    inst:SetVariation(data and data.variation or 1)
    if data and data.worked and inst.components.workable then
        local totalwork = inst.islarge:value() and TUNING.SHARKBOI_ICE_LARGE_MINE or TUNING.SHARKBOI_ICE_MINE
        local workleft = totalwork - data.worked
        if workleft > 0 and workleft < totalwork then
            inst.components.workable:SetWorkLeft(workleft)
            RefreshWorkLevel(inst, workleft)
        end
    end
end

local function OnHealthDelta(inst, oldpercent, newpercent)
    if newpercent <= 0 then
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_smash")

        inst.persists = false
        inst.Physics:SetActive(false)
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst.AnimState:SetBuild("sharkboi_iceplow_fx")

        local variation = math.random(2)

        inst.AnimState:SetBankAndPlayAnimation("sharkboi_iceplow_fx", "iceplow" .. tostring(variation) .. "_pre")
        inst.AnimState:PushAnimation("iceplow" .. tostring(variation) .. "_pst", false)

        if math.random() < 0.5 then
            inst.AnimState:SetScale(-1, 1)
        end

        inst:ListenForEvent("animqueueover", inst.Remove)

        clearobstacle(inst)

        return
    end

    inst.SoundEmitter:PlaySound("meta3/sharkboi/ice_spike_break")

    local animname = "spike" .. tostring(inst.variation) .. "_low"

    if newpercent <= 0.5 and not inst.AnimState:IsCurrentAnimation(animname) then
        inst.AnimState:PlayAnimation(animname)
    end
end

local function spikefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddPhysics()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("sharkboi_icespike")
    inst.AnimState:SetBuild("sharkboi_icespike")
    inst.AnimState:PlayAnimation("spike1_pre")

    MakeObstaclePhysics(inst, RADIUS, 2)
    --inst:DoTaskInTime(0, CreatePhysicsPush)

    inst:AddTag("groundspike")
    inst:AddTag("frozen")

    inst.islarge = net_bool(inst.GUID, "glacialhound_icespike.islarge")

    inst.scrapbook_inspectonseen = true


    inst._pfpos = nil
    inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty")
    makeobstacle(inst)
    --Delay this because makeobstacle sets pathfinding on by default
    --but we don't to handle it until after our position is set
    inst:DoTaskInTime(0, InitializePathFinding)

    inst.OnRemoveEntity = onremove

    inst.entity:SetPristine()


    if not TheWorld.ismastersim then
        return inst
    end

    inst.owner = nil --set when the spike is spawned by the glacial hounds.

    inst.variation = 1
    inst.AnimState:PushAnimation("spike1", false)

    inst.dmgtask = inst:DoTaskInTime(0, DoDamage)

    inst:AddComponent("combat")
    inst.components.combat.noimpactsound = true

    inst:AddComponent("health")
    inst.components.health.nofadeout = true
    inst.components.health.save_maxhealth = true
    inst.components.health.canheal = false
    inst.components.health.ondelta = OnHealthDelta
    inst.components.health:SetMaxHealth(TUNING.CRABKING_ICEWALL_HEALTH)

    inst:DoPeriodicTask(1.25, function(inst)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.health:DoDelta(-50)
        end
    end)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("sharkboi_icespike")

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")

    inst.SetVariation = SetVariation
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    if not POPULATING then
        inst:SetVariation(math.random(NUM_VARIATIONS))
    end

    return inst
end

return Prefab("glacialhound_icespike", spikefn, assets, prefabs_spike)
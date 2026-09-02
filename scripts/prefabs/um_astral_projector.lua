--[[
ASTRAL PROJECTOR / RECEPTIONATOR
Im doing this small doc so I don't forget the details later, because this is a lot of moving parts and just having the code is not enough to remember how it all fits together, so i can come back easily if anything stops working properly
----------------------------------------------------------------
Two structures work as a linked pair
- "um_astral_projector"        (le projectinator) -where the player starts a projection
- "um_astral_projector_target" (the receptionator) -where t he projection travels to

*each projector/receptionator always links to its nearest counterpart
(FindNearestTarget / FindNearestProjector), rather than a saved 1:1 paring

PROJECTION TRIP
1. A player channels the projector (OnStartChanneling). Both structures play their
"active" animation immediately, before the trip even completes, so the pair visibly
lights up together.
2. Once the channeling finishes, the player becomes invincible, loses control, and enters
"enterastralportal". The projector's teleporter component activates and sends them
toward the receptionator.
3. On arrival (OnStartTeleporting), the player is *tagged um_astral_projected, given the
erosion/hologram look, and a watchdog task starts and a warning ring fx
spawns around the receptionator to mark how far they're allowed to walk

WHILE PROJECTED
1. A player can freely walk away from the receptionator up to ASTRAL_CIRCLE_DISTSQ.
A periodic watchdog (0.5s) auto-triggers the return trip if they wander past that
- Mote thatdying, disconnecting, or the projector/receptionator being destroyed all route through
CleanupPlayerProjection / ForceReturnPlayer instead of the normal channeled return.

RETURN TRIP
1. Channeling the receptionator (OnStartChanneling_Target) checks that the player actually
belongs to that receptionator, then sends them back the same way, through
"enterastralportal_nofx"
2. On arrival back at the projector (OnExitingTeleporter / OnStartTeleporting_Target),
all the projection state/tags/listeners get cleared and both structures play their
"pst" animation and power down - but only once nobody else is still using that
specific pair (CountProjectedPlayers is scoped per pair, not global)

FORCED RETURNS (ForceReturnPlayer / OnReturn)
Hammering either structure, dying while projected, or losing the receptionator entirely
all skip the normal teleporter flow and hand the player straight to ForceReturnPlayer,
which fades them out, drops them near the projector via OnReturn (which is a small random-angle
offset, so they don't land exactly on top of it because it looks ugly), and fades them back in

COSMETIC FX
1. Ring: a persistent ring of alterguardian_lasertrail shows marking the allowed
boundary around an active receptionator (Start/StopLeashRing, um_astral_leash_warning)
2. Pool: a ground glow at the receptionator, borrowed from the cc's meteor VFX, timed to 
appear once an arriving player is actually visible
(Start/StopPool, um_astral_arrival_pool)

pending_teleports on each structure is a simple refcount so that one player finishing
their trip doesntrip the teleporter target out from under another player still using
the same structure.
]]--

require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/um_archives_projectinator.zip"),
    Asset("ANIM", "anim/um_archives_receptionator.zip"),
    Asset("MINIMAP_IMAGE", "townportalactive"),
    Asset("ANIM", "anim/alterguardian_meteor.zip"),
}

local prefabs =
{
    "collapse_small",
    "globalmapicon",
    "alterguardian_lasertrail",
    "um_astral_leash_warning",
    "um_astral_arrival_pool",
}

-- tuning constants
local FORCE_RETURN_FADE = 1
local ASTRAL_GROGGINESS_NORMAL = 0.5
local ASTRAL_GROGGINESS_FORCED = 0.9
local ASTRAL_TELEPORT_TIMEOUT = 1
local ASTRAL_CIRCLE_DISTSQ = 530
local ASTRAL_RING_ANGLEDIFF = PI / 60
local ASTRAL_RING_SPAWNS_PER_TICK = 4
local ASTRAL_RETURN_OFFSET = 3

-- lookup + query helpers

-- finds the closest receptionator to a given projector
local function FindNearestTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    -- 10000 radius might be overkill??? idk
    local ents = TheSim:FindEntities(x, y, z, 10000, {"um_astral_projector_target"})
    local nearest, bestdsq = nil, math.huge
    for _, ent in ipairs(ents) do
        local dsq = inst:GetDistanceSqToInst(ent)
        if dsq < bestdsq then
            nearest, bestdsq = ent, dsq
        end
    end
    return nearest
end

-- finds the closest projector to a given receptionator
local function FindNearestProjector(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10000, {"um_astral_projector"})
    local nearest, bestdsq = nil, math.huge
    for _, ent in ipairs(ents) do
        local dsq = inst:GetDistanceSqToInst(ent)
        if dsq < bestdsq then
            nearest, bestdsq = ent, dsq
        end
    end
    return nearest
end

local function CountProjectedPlayers(home, target)
    local count = 0
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_projected
            and (home == nil or player.um_astral_home == home)
            and (target == nil or player.um_astral_target == target) then
            count = count + 1
        end
    end
    return count
end

-- player state helpers (erosion + sound loop)

-- clears erosion from the player and from the minions stored at projection start
local function ClearProjectionErosion(player)
    if player.AnimState ~= nil then
        player.AnimState:SetErosionParams(0, 0, 0)
    end
    if player.um_astral_minions ~= nil then
        for i, v in ipairs(player.um_astral_minions) do
            if v:IsValid() and v.AnimState ~= nil then
                v.AnimState:SetErosionParams(0, 0, 0)
            end
        end
        player.um_astral_minions = nil
    end
end

-- sound loop helpers, tied to entity sleep/wake so sounds stop when the screen unloads
local function OnEntityWake(inst)
    if inst.playingsound and not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("loop")) then
        inst.SoundEmitter:PlaySound("rifts6/vault_portal/turn_on_powered_LP", "loop")
    end
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function StartSoundLoop(inst)
    if not inst.playingsound then
        inst.playingsound = true
        OnEntityWake(inst)
    end
end

local function StopSoundLoop(inst)
    if inst.playingsound then
        inst.playingsound = nil
        inst.SoundEmitter:KillSound("loop")
    end
end

-- leash ring fx: the persistent boundary-warning ring around an active receptionator

-- stops and removes the persistent ring-burst fx around a receptionator, if any
local function StopLeashRing(target)
    if target.um_astral_leash_ring ~= nil then
        if target.um_astral_leash_ring:IsValid() then
            if target.um_astral_leash_ring.spawn_task ~= nil then
                target.um_astral_leash_ring.spawn_task:Cancel()
            end
            target.um_astral_leash_ring:Remove()
        end
        target.um_astral_leash_ring = nil
    end
end

local function LeashRingGeneratePoints(inst)
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local radius = math.sqrt(ASTRAL_CIRCLE_DISTSQ)

    local angle = 0
    while angle < TWOPI do
        local x = ix + radius * math.cos(angle)
        local z = iz + radius * math.sin(angle)
        table.insert(inst._points, { x, z })
        angle = angle + ASTRAL_RING_ANGLEDIFF
    end

    shuffleArray(inst._points)
end

local function LeashRingSpawnFx(inst)
    for i = 1, ASTRAL_RING_SPAWNS_PER_TICK do
        if #inst._points <= 0 then
            LeashRingGeneratePoints(inst)
        end

        local next_point = table.remove(inst._points)
        local x, z = next_point[1], next_point[2]

        local fx = SpawnPrefab("alterguardian_lasertrail")
        fx.Transform:SetPosition(x, 0, z)
    end
end

local function LeashRingFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst._points = {}

    inst.spawn_task = inst:DoPeriodicTask(3 * FRAMES, LeashRingSpawnFx)

    return inst
end

-- spawns the persistent ring-burst fx around a receptionator, if not already running
local function SpawnLeashRing(inst)
    if inst.um_astral_leash_ring == nil then
        inst.um_astral_leash_ring = SpawnPrefab("um_astral_leash_warning")
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.um_astral_leash_ring.Transform:SetPosition(x, y, z)
    end
end

-- arrival pool fx: the ground-decal glow that appears once a player is visible at the receptionator

local function StartPool(inst)
    if inst.um_astral_pool == nil then
        inst.um_astral_pool = SpawnPrefab("um_astral_arrival_pool")
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.um_astral_pool.Transform:SetPosition(x, y, z)
    end
end

local function StopPool(target, instant)
    if target.um_astral_pool ~= nil then
        if target.um_astral_pool:IsValid() then
            if instant then
                target.um_astral_pool:Remove()
            else
                target.um_astral_pool.AnimState:PlayAnimation("meteorground_pst")
            end
        end
        target.um_astral_pool = nil
    end
end

local function PoolRemove(inst)
    inst:Remove()
end

local function PoolAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation("meteorground_pst") then
        PoolRemove(inst)
    end
end

local function ArrivalPoolFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(1.5)
    inst.Light:SetFalloff(0.85)
    inst.Light:SetColour(0.05, 0.05, 1)

    inst.AnimState:SetBank("alterguardian_meteor")
    inst.AnimState:SetBuild("alterguardian_meteor")
    inst.AnimState:PlayAnimation("meteorground_pre")
    inst.AnimState:PushAnimation("meteorground_loop", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_traps")

    inst.persists = false
    inst:ListenForEvent("animover", PoolAnimOver)

    return inst
end

-- pair lifecycle: stopping both structures together

-- hard stop both structures, skipping the pst animation (used when hammering)
local function StopPairPortals(projector, target)
    if projector ~= nil and projector:IsValid() and CountProjectedPlayers(projector, nil) == 0 then
        StopSoundLoop(projector)
        projector.AnimState:PlayAnimation("idle", true)
        projector.components.teleporter:Target(nil)
    end
    if target ~= nil and target:IsValid() and CountProjectedPlayers(nil, target) == 0 then
        StopSoundLoop(target)
        target.AnimState:PlayAnimation("idle", true)
        target.components.teleporter:Target(nil)
        StopLeashRing(target)
        StopPool(target, true)
    end
end

-- graceful stop, plays the deactivation animation on both structures
local function StopPairAnimations(projector, target)
    if projector ~= nil and projector:IsValid() and CountProjectedPlayers(projector, nil) == 0 then
        StopSoundLoop(projector)
        projector.SoundEmitter:PlaySound("rifts6/vault_portal/turn_off")
        projector.AnimState:PlayAnimation("active_pst")
        projector.AnimState:PushAnimation("idle", true)
        projector.components.teleporter:Target(nil)
        projector.pending_teleports = 0
    end
    if target ~= nil and target:IsValid() and CountProjectedPlayers(nil, target) == 0 then
        StopSoundLoop(target)
        target.SoundEmitter:PlaySound("rifts6/vault_portal/turn_off")
        target.AnimState:PlayAnimation("active_pst")
        target.AnimState:PushAnimation("idle", true)
        target.components.teleporter:Target(nil)
        target.pending_teleports = 0
        StopLeashRing(target)
        StopPool(target)
    end
end

-- teleporter target refcounting + self-heal

local function ReleaseTeleporterTarget(inst)
    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)
    if inst.pending_teleports == 0 and not inst.components.teleporter:IsBusy() then
        inst.components.teleporter:Target(nil)
    end
end

local function OnRemove(structure, channeler, flagname)
    if channeler[flagname] then
        channeler[flagname] = nil
        channeler.um_astral_outbound_home = nil
        if channeler.components.health ~= nil then
            channeler.components.health:SetInvincible(false)
        end
        if channeler.components.playercontroller ~= nil then
            channeler.components.playercontroller:Enable(true)
        end
        if structure:IsValid() then
            structure:ReleaseTeleporterTarget()
        end
    end
end

-- player projection cleanup

-- strips all projection state from a player and stops structure animations if nobody else is projected.
-- called on disconnect, shard change, hammering, or any abnormal exit, bc youu never know...
local function CleanupPlayerProjection(player)
    if not player.um_astral_projected then return end

    -- save references before clearing them
    local home   = player.um_astral_home
    local target = player.um_astral_target

    player:RemoveTag("um_astral_projected")
    player.um_astral_projected = false
    player.um_astral_home      = nil
    player.um_astral_target    = nil
    player.um_astral_returning = nil
    player.um_astral_outbound_pending = nil
    player.um_astral_outbound_home = nil

    if player.components.sanity ~= nil then
        player.components.sanity.externalmodifiers:RemoveModifier("um_astral_projector")
    end

    if player.um_astral_projected_returntask ~= nil then
        player.um_astral_projected_returntask:Cancel()
        player.um_astral_projected_returntask = nil
    end

    -- use snippet so death instance still clears followers even after RemoveAllFollowersOnDeath triggers
    ClearProjectionErosion(player)

    if player.um_astral_deactivated_fn ~= nil then
        player:RemoveEventCallback("playerdeactivated", player.um_astral_deactivated_fn)
        player:RemoveEventCallback("onremove", player.um_astral_deactivated_fn)
        player.um_astral_deactivated_fn = nil
    end

    if player.um_astral_death_fn ~= nil then
        player:RemoveEventCallback("death", player.um_astral_death_fn)
        player.um_astral_death_fn = nil
    end

    -- defer one frame so CountProjectedPlayers reflects the updated state
    if home ~= nil and home:IsValid() then
        home:DoTaskInTime(0, function(h)
            if h ~= nil and h:IsValid() then
                local tgt = (target ~= nil and target:IsValid()) and target or FindNearestTarget(h)
                StopPairAnimations(h, tgt)
                if tgt ~= nil and tgt.active_home ~= nil and CountProjectedPlayers(nil, tgt) == 0 then
                    tgt.active_home = nil
                end
            end
        end)
    end
end

-- forced-return helpers: used by anything that isn't a normal channeled return

local function OnReturn(dest_x, dest_y, dest_z)
    local angle = math.random() * TWOPI
    return dest_x + math.cos(angle) * ASTRAL_RETURN_OFFSET, dest_y, dest_z + math.sin(angle) * ASTRAL_RETURN_OFFSET
end

-- teleports a player back to their projectors position without going through the normal return flow
local function ForceReturnPlayer(player, dest_x, dest_y, dest_z)
    CleanupPlayerProjection(player)

    local px, py, pz = player.Transform:GetWorldPosition()
    SpawnPrefab("halloween_firepuff_cold_" .. math.random(3)).Transform:SetPosition(px, py, pz)
    player.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_fx")

    player.components.health:SetInvincible(true)
    if player.components.playercontroller ~= nil then
        player.components.playercontroller:Enable(false)
    end
    player.DynamicShadow:Enable(false)
    player:Hide()
    player:ScreenFade(false, FORCE_RETURN_FADE)

    player:DoTaskInTime(FORCE_RETURN_FADE, function(pl)
        -- player may have gone, vanished, explored, deported into limbo (shard travel) during the fade
        if pl == nil or not pl:IsValid() or pl:HasTag("INLIMBO") then
            if pl ~= nil and pl:IsValid() then
                pl.components.health:SetInvincible(false)
                if pl.components.playercontroller ~= nil then
                    pl.components.playercontroller:Enable(true)
                end
                pl.DynamicShadow:Enable(true)
                pl:Show()
                pl:ScreenFade(true, 1)
            end
            return
        end

        if dest_x ~= nil and pl.Physics ~= nil then
            pl.Physics:Teleport(OnReturn(dest_x, dest_y, dest_z))
        end

        pl.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")
        pl:ScreenFade(true, 1)

        -- never touch the stategraph of a dead player, death state has assert(false) in its onexit
        local is_dead = pl.components.health ~= nil and pl.components.health:IsDead()
        local sg_dead = pl.sg ~= nil and pl.sg:HasStateTag("dead")

        --  apply grogginess on forced return, only if alive
        if not is_dead and pl.components.grogginess ~= nil then
            pl.components.grogginess:SetPercent(ASTRAL_GROGGINESS_FORCED)
        end

        if pl.sg ~= nil and not is_dead and not sg_dead then
            pl.sg:GoToState("exitastralportal_pre")
        else
            pl.components.health:SetInvincible(false)
            if pl.components.playercontroller ~= nil then
                pl.components.playercontroller:Enable(true)
            end
            pl.DynamicShadow:Enable(true)
            pl:Show()
        end
    end)
end

-- force-returns all players that were projected through a specific projector
local function ReturnAllProjectedPlayers(projector)
    local sx, sy, sz
    if projector ~= nil and projector:IsValid() then
        sx, sy, sz = projector.Transform:GetWorldPosition()
    end
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_projected and player.um_astral_home == projector then
            ForceReturnPlayer(player, sx, sy, sz)
        end
    end
end

-- force-returns all players currently at a specific receptionator, regardless of which projector each one came from
local function ReturnAllPlayersAtTarget(target)
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_projected and player.um_astral_target == target then
            local home = player.um_astral_home
            local hx, hy, hz
            if home ~= nil and home:IsValid() then
                hx, hy, hz = home.Transform:GetWorldPosition()
            end
            ForceReturnPlayer(player, hx, hy, hz)
        end
    end
end

-- restores anyone still mid-channeling on a projector thats about to be destroyed, since they're not yet tagged and ReturnAllProjectedPlayers won't catch them
local function RestorePendingChannelers(projector)
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_outbound_pending and player.um_astral_outbound_home == projector then
            OnRemove(projector, player, "um_astral_outbound_pending")
        end
    end
end

-- projectinator: channel / teleport / hammer handlers

-- starts when a player starts channeling the projector, plays the activation animation, then sets up the projection state and sends the player through
local function OnStartChanneling(inst, channeler)
    if channeler.um_astral_outbound_pending then return end

    local target = FindNearestTarget(inst)

    -- always play animation regardless of whether projection proceeds
    if not inst.AnimState:IsCurrentAnimation("active_loop") then
        inst.AnimState:PlayAnimation("active_pre")
        inst.AnimState:PushAnimation("active_loop", true)
    end
    StartSoundLoop(inst)

    if target == nil then return end
    if channeler.um_astral_projected then return end

    if not target.AnimState:IsCurrentAnimation("active_loop") then
        target.AnimState:PlayAnimation("active_pre")
        target.AnimState:PushAnimation("active_loop", true)
    end
    StartSoundLoop(target)

    channeler.um_astral_outbound_pending = true
    channeler.um_astral_outbound_home = inst

    channeler.components.health:SetInvincible(true)
    if channeler.components.playercontroller ~= nil then
        channeler.components.playercontroller:Enable(false)
    end

    inst.components.teleporter:Target(target)
    inst.pending_teleports = (inst.pending_teleports or 0) + 1
    inst:DoTaskInTime(ASTRAL_TELEPORT_TIMEOUT, OnRemove, channeler, "um_astral_outbound_pending")

    channeler.sg:GoToState("enterastralportal", { teleporter = inst })
end

-- triggers when the player stops channeling before the teleport completes
local function OnStopChanneling(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    StopPairAnimations(inst, FindNearestTarget(inst))
end

-- triggers  when the teleporter activates and the player is actually in transit.
-- sets up the return task and disconnect handler
local function OnStartTeleporting(inst, doer)
    inst.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_fx")

    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)

    if not doer:HasTag("player") then return end

    local target = FindNearestTarget(inst)

    -- followers now so ClearProjectionErosion works even after death clears the leader component
    local minions = doer.components.leader and doer.components.leader:GetFollowersByTag("_health") or {}
    doer.um_astral_minions = minions
    for i, v in ipairs(minions) do
        v.AnimState:SetErosionParams(-0.5, -0.2, -1.0)
    end

    doer.AnimState:SetErosionParams(-0.5, -0.2, -1.0)
    doer:AddTag("um_astral_projected")
    doer.um_astral_projected = true
    doer.um_astral_home      = inst
    doer.um_astral_target    = target
    doer.um_astral_outbound_pending = nil
    doer.um_astral_outbound_home = nil

    if doer.components.sanity ~= nil then
        doer.components.sanity.externalmodifiers:SetModifier(
            "um_astral_projector",
            -TUNING.DAPPERNESS_SUPERHUGE
        )
    end

    if doer.components.talker ~= nil then
        doer.components.talker:ShutUp()
    end

    if target ~= nil and target:IsValid() then
        target.SpawnLeashRing(target)
    end

    if doer.um_astral_projected_returntask ~= nil then
        doer.um_astral_projected_returntask:Cancel()
    end

    -- clean up if the player disconnects or despawns while projected, very bad scary
    if doer.um_astral_deactivated_fn ~= nil then
        doer:RemoveEventCallback("playerdeactivated", doer.um_astral_deactivated_fn)
        doer:RemoveEventCallback("onremove", doer.um_astral_deactivated_fn)
    end
    local function on_player_deactivated(doer_inst)
        CleanupPlayerProjection(doer_inst)
    end
    doer.um_astral_deactivated_fn = on_player_deactivated
    doer:ListenForEvent("playerdeactivated", on_player_deactivated)
    doer:ListenForEvent("onremove", on_player_deactivated)

    -- on death, force return the ghost to the projector instead of just cleaning up
    if doer.um_astral_death_fn ~= nil then
        doer:RemoveEventCallback("death", doer.um_astral_death_fn)
    end
    local home_inst = inst
    local function on_player_death(doer_inst)
        local hx, hy, hz
        if home_inst ~= nil and home_inst:IsValid() then
            hx, hy, hz = home_inst.Transform:GetWorldPosition()
        end
        ForceReturnPlayer(doer_inst, hx, hy, hz)
        -- wx78 backup body spawns during the death event, defer one frame so it exists
        if hx ~= nil and doer_inst.wx78_classified ~= nil then
            doer_inst:DoTaskInTime(0, function(pl)
                if pl == nil or not pl:IsValid() then return end
                local body = pl.wx78_backupbody_save_inst
                if body ~= nil and body:IsValid() then
                    body.Transform:SetPosition(hx + 2, hy, hz + 2)
                end
            end)
        end
    end
    doer.um_astral_death_fn = on_player_death
    doer:ListenForEvent("death", on_player_death)

    local home = inst
    -- periodic task that watches whether the player is too far from the exit or the projector got destroyed
    doer.um_astral_projected_returntask = doer:DoPeriodicTask(0.5, function()
        -- shard travel - clean up silently, sneak 100
        if doer:HasTag("INLIMBO") then
            CleanupPlayerProjection(doer)
            return
        end

        -- player is dead: death handler already called ForceReturnPlayer, don't pile on
        if doer.components.health ~= nil and doer.components.health:IsDead() then
            return
        end

        -- recover target reference if it was destroyed and a new one exists
        local tgt = doer.um_astral_target
        if tgt ~= nil and not tgt:IsValid() then
            tgt = doer.um_astral_home and doer.um_astral_home:IsValid() and FindNearestTarget(doer.um_astral_home) or nil
            doer.um_astral_target = tgt
        end

        if home ~= nil and home:IsValid() then
            if tgt ~= nil and tgt:IsValid() then
                -- auto-return if the player wanders too far from the receptionator
                local dist_to_exit = doer:GetDistanceSqToInst(tgt)
                if dist_to_exit >= ASTRAL_CIRCLE_DISTSQ and not doer.um_astral_returning then
                    tgt.OnStartChanneling_Target(tgt, doer)
                end
            else
                -- no receptionator exists, force return to projector, it used to kill you btw, looking at you Scrimbles
                local hx, hy, hz = home.Transform:GetWorldPosition()
                ForceReturnPlayer(doer, hx, hy, hz)
            end
        else
            -- projector was destroyed while player was projected, find a safe landing spot
            local safe = TheWorld.Map:FindValidPositionByFan(
                math.random() * 2 * PI, 1, 12,
                function(px, py, pz)
                    return TheWorld.Map:IsPassableAtPoint(px, py, pz)
                        and not TheWorld.Map:IsOceanAtPoint(px, py, pz)
                end
            )
            if safe ~= nil then
                ForceReturnPlayer(doer, safe.x, safe.y, safe.z)
            else
                ForceReturnPlayer(doer, nil, nil, nil)
            end
        end
    end)
end

-- for when the player finishes teleporting through the projector side
local function OnExitingTeleporter(inst, obj)
    inst.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")
    if obj ~= nil and obj:HasTag("player") then
        if obj.Physics ~= nil then
            local ix, iy, iz = inst.Transform:GetWorldPosition()
            obj.Physics:Teleport(OnReturn(ix, iy, iz))
        end
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport")
        --  grogginess on arrival at receptionator, only if alive
        if obj.components.grogginess ~= nil
            and obj.components.health ~= nil
            and not obj.components.health:IsDead() then
            obj.components.grogginess:SetPercent(ASTRAL_GROGGINESS_NORMAL)
        end
    end
    -- save the receptionator reference before clearing the teleporter (FindNearestTarget after clear is unreliable in multi-pair setups)
    local tgt = (obj ~= nil and obj.um_astral_target ~= nil and obj.um_astral_target:IsValid()) and obj.um_astral_target or FindNearestTarget(inst)
    inst.components.teleporter:Target(nil)
    inst.pending_teleports = 0
    if tgt ~= nil and tgt:IsValid() then
        tgt.components.teleporter:Target(nil)
        tgt.pending_teleports = 0
    end
end

-- projector is hammered: force return all linked players then destroy
local function OnHammered(inst)
    local target = FindNearestTarget(inst)
    ReturnAllProjectedPlayers(inst)
    RestorePendingChannelers(inst)
    StopPairPortals(inst, target)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function OnHit(inst)
    local was_active = inst.AnimState:IsCurrentAnimation("active_loop")
    inst.AnimState:PlayAnimation("hammer")
    if was_active then
        inst.AnimState:PushAnimation("active_loop", true)
    end
end

-- shared behavior used by both structures' constructors

local function OnBuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

-- returns ACTIVE to the inspect string when the teleporter is active, otherwise nil so it doesn't show up at all
local function GetStatus(inst)
    return inst.components.teleporter:IsActive() and "ACTIVE" or nil
end

local function init(inst)
    if inst.icon == nil then
        inst.icon = SpawnPrefab("globalmapicon")
        inst.icon:TrackEntity(inst)
    end
end

-- projectinator constructor
local function Fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("um_astral_projector.tex")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    MakeObstaclePhysics(inst, .1)

    inst.AnimState:SetBank("um_archives_projectinator")
    inst.AnimState:SetBuild("um_archives_projectinator")
    inst.AnimState:PlayAnimation("idle", true)
    inst.Transform:SetScale(1.35, 1.35, 1.35)

    inst:AddTag("structure")
    inst:AddTag("um_astral_projector")
    inst:AddTag("vault_teleporter")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeHauntableWork(inst)
    MakeSnowCovered(inst)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling, OnStopChanneling)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleporting
    inst.components.teleporter.offset           = 0
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.travelcameratime = 1.5
    inst.components.teleporter.travelarrivetime = 1.5

    inst:ListenForEvent("doneteleporting", OnExitingTeleporter)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst.OnEntityWake  = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst.ReleaseTeleporterTarget = ReleaseTeleporterTarget

    inst:DoTaskInTime(0, init)

    return inst
end

-- receptionator: channel / teleport / hammer handlers

-- func for when a projected player channels the receptionator to return.
-- animation plays unconditionally, teleport only proceeds if this is the correct receptionator
local function OnStartChanneling_Target(inst, channeler)
    if channeler.um_astral_returning then
        return
    end

    local home = channeler.um_astral_home

    -- always animate, the modmain STARTCHANNELING override handles blocking wrong receptionators
    if not inst.AnimState:IsCurrentAnimation("active_loop") then
        inst.AnimState:PlayAnimation("active_pre")
        inst.AnimState:PushAnimation("active_loop", true)
    end
    StartSoundLoop(inst)

    if (home == nil or not home:IsValid()) or not channeler.um_astral_projected or channeler.um_astral_target ~= inst then
        channeler.components.talker:Say(GetActionFailString(channeler, "GENERIC"))
        return
    end

    inst.active_home = home
    channeler.um_astral_returning = true

    channeler.components.health:SetInvincible(true)
    if channeler.components.playercontroller ~= nil then
        channeler.components.playercontroller:Enable(false)
    end

    inst.components.teleporter:Target(home)
    inst.pending_teleports = (inst.pending_teleports or 0) + 1
    inst:DoTaskInTime(ASTRAL_TELEPORT_TIMEOUT, OnRemove, channeler, "um_astral_returning")

    channeler.sg:GoToState("enterastralportal_nofx", { teleporter = inst })
end

-- when the player stops channeling the receptionator before completing the return
local function OnStopChanneling_Target(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    StopPairAnimations(inst.active_home, inst)
    if CountProjectedPlayers(nil, inst) == 0 then
        inst.active_home = nil
    end
end

-- player finishes teleporting back through the receptionator
local function OnExitingTeleporter_Target(inst, obj)
    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport")
        -- apply grogginess on normal return, only if alive
        if obj.components.grogginess ~= nil
            and obj.components.health ~= nil
            and not obj.components.health:IsDead() then
            obj.components.grogginess:SetPercent(ASTRAL_GROGGINESS_NORMAL)
        end

        inst:DoTaskInTime(32 * FRAMES, StartPool)
    end
    inst.components.teleporter:Target(nil)
    inst.pending_teleports = 0
    local home = inst.active_home
    inst.active_home = nil
    if home ~= nil and home:IsValid() then
        home.components.teleporter:Target(nil)
        home.pending_teleports = 0
    end
    StopPairAnimations(home, inst)
end

-- fires when the return teleport activates on the receptionator side
local function OnStartTeleporting_Target(inst, doer)
    local home = inst.active_home

    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)

    inst.AnimState:PlayAnimation("active_pst")
    inst.AnimState:PushAnimation("idle", true)
    StopSoundLoop(inst)
    StopLeashRing(inst)
    StopPool(inst)

    if home ~= nil and home:IsValid() then
        home.AnimState:PlayAnimation("active_pst")
        home.AnimState:PushAnimation("idle", true)
        StopSoundLoop(home)
    end

    if not doer:HasTag("player") then return end

    -- clear erosion from player and their boplets
    ClearProjectionErosion(doer)

    doer:RemoveTag("um_astral_projected")
    doer.um_astral_projected = false
    doer.um_astral_home      = nil
    doer.um_astral_target    = nil
    doer.um_astral_returning = nil

    if doer.components.sanity ~= nil then
        doer.components.sanity.externalmodifiers:RemoveModifier("um_astral_projector")
    end

    if doer.components.talker ~= nil then
        doer.components.talker:ShutUp()
    end

    if doer.um_astral_projected_returntask ~= nil then
        doer.um_astral_projected_returntask:Cancel()
    end
    doer.um_astral_projected_returntask = nil

    if doer.um_astral_deactivated_fn ~= nil then
        doer:RemoveEventCallback("playerdeactivated", doer.um_astral_deactivated_fn)
        doer:RemoveEventCallback("onremove", doer.um_astral_deactivated_fn)
        doer.um_astral_deactivated_fn = nil
    end

    if doer.um_astral_death_fn ~= nil then
        doer:RemoveEventCallback("death", doer.um_astral_death_fn)
        doer.um_astral_death_fn = nil
    end
end

-- receptionator is hammered -- -- > find its linked projector, force-return players, then destroy
local function OnHammeredTarget(inst)
    local home = FindNearestProjector(inst)
    ReturnAllPlayersAtTarget(inst)
    StopPairPortals(home, inst)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

-- hammer hit callback
local function OnHitTarget(inst)
    local was_active = inst.AnimState:IsCurrentAnimation("active_loop")
    inst.AnimState:PlayAnimation("hammer")
    if was_active then
        inst.AnimState:PushAnimation("active_loop", true)
    end
end

-- receptionator constructor
local function TargetFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("um_astral_projector_target.tex")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    --MakeObstaclePhysics(inst, .0001)

    inst.AnimState:SetBank("um_archives_receptionator")
    inst.AnimState:SetBuild("um_archives_receptionator")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("um_astral_projector_target")
    inst:AddTag("vault_teleporter")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammeredTarget)
    inst.components.workable:SetOnWorkCallback(OnHitTarget)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling_Target, OnStopChanneling_Target)
    --inst.components.channelable:SetEnabled(false)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleporting_Target
    inst.components.teleporter.offset           = 0
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.travelcameratime = 2.9
    inst.components.teleporter.travelarrivetime = 2.8

    inst:ListenForEvent("doneteleporting", OnExitingTeleporter_Target)

    inst.OnStartChanneling_Target = OnStartChanneling_Target
    inst.ReleaseTeleporterTarget  = ReleaseTeleporterTarget
    inst.SpawnLeashRing           = SpawnLeashRing

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:DoTaskInTime(0, init)

    return inst
end

return
    Prefab("um_astral_projector", Fn, assets, prefabs),
    MakePlacer("um_astral_projector_placer", "um_archives_projectinator", "um_archives_projectinator", "idle"),
    Prefab("um_astral_projector_target", TargetFn, assets, prefabs),
    MakePlacer("um_astral_projector_target_placer", "um_archives_receptionator", "um_archives_receptionator", "idle"),
    Prefab("um_astral_leash_warning", LeashRingFn, nil, { "alterguardian_lasertrail" }),
    Prefab("um_astral_arrival_pool", ArrivalPoolFn, assets)
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

local FORCE_RETURN_FADE = 1
local ASTRAL_GROGGINESS_NORMAL = 0.5
local ASTRAL_GROGGINESS_FORCED = 0.9
local ASTRAL_TELEPORT_TIMEOUT = 2
local ASTRAL_CIRCLE_DISTSQ = 530
local ASTRAL_RING_ANGLEDIFF = PI / 60
local ASTRAL_RING_SPAWNS_PER_TICK = 4
local ASTRAL_RETURN_OFFSET = 3

-- lookup + query helpers
-- finds the closest receptionator to a given projector
local function FindNearestReceptor(inst)
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

-- counts players currently projected, optionally filtered by home projector and/or target receptionator
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

-- leash ring fx: the persistent boundary warning ring around an active receptionator
-- stops and removes the persistent ring burst fx around a receptionator, if any
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

-- builds points around the receptionator in a circle, shuffles them, and stores them for use
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

-- spawns a handful of laser trail vfx along the ring radius each tick
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

-- constructor for the leash ring fx entity itself
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

-- spawns the persistent ring burst fx around a receptionator, if not already running
local function SpawnLeashRing(inst)
    if inst.um_astral_leash_ring == nil then
        inst.um_astral_leash_ring = SpawnPrefab("um_astral_leash_warning")
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.um_astral_leash_ring.Transform:SetPosition(x, y, z)
    end
end

-- arrival pool fx: the ground decal glow that appears once a player is visible at the receptionator
-- spawns the pool at a receptionator, if not already running
local function StartPool(inst)
    if inst.um_astral_pool == nil then
        inst.um_astral_pool = SpawnPrefab("um_astral_arrival_pool")
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.um_astral_pool.Transform:SetPosition(x, y, z)
    end
end

-- stops the pool, either playing its pst or removing it
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

-- self removes once the pools own outro animation finishes playing
local function PoolAnimOver(inst)
    if inst.AnimState:IsCurrentAnimation("meteorground_pst") then
        PoolRemove(inst)
    end
end

-- constructor for the arrival pool fx entity itself
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
    --  unsure about this sfx
    --inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_traps")

    inst.persists = false
    inst:ListenForEvent("animover", PoolAnimOver)

    return inst
end

-- pair lifecycle, stopping both structures together
-- hard stop both structures, skipping the pst animation (used when hammering)
local function StopPairPortals(projector, target)
    if projector ~= nil and projector:IsValid() and CountProjectedPlayers(projector, nil) == 0
        and (projector.pending_teleports or 0) == 0 then
        StopSoundLoop(projector)
        projector.AnimState:PlayAnimation("idle", true)
        projector.components.teleporter:Target(nil)
    end
    if target ~= nil and target:IsValid() and CountProjectedPlayers(nil, target) == 0
        and (target.pending_teleports or 0) == 0 then
        StopSoundLoop(target)
        target.AnimState:PlayAnimation("idle", true)
        target.components.teleporter:Target(nil)
        StopLeashRing(target)
        StopPool(target, true)
    end
end

-- graceful stop, plays the deactivation animation on both structures
local function StopPairAnimations(projector, target)
    if projector ~= nil and projector:IsValid() and CountProjectedPlayers(projector, nil) == 0
        and (projector.pending_teleports or 0) == 0 then
        StopSoundLoop(projector)
        projector.SoundEmitter:PlaySound("rifts6/vault_portal/turn_off")
        projector.AnimState:PlayAnimation("active_pst")
        projector.AnimState:PushAnimation("idle", true)
        projector.components.teleporter:Target(nil)
        projector.pending_teleports = 0
    end
    if target ~= nil and target:IsValid() and CountProjectedPlayers(nil, target) == 0
        and (target.pending_teleports or 0) == 0 then
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

-- teleporter target refcounting
-- decrements a structures in flight teleport count, clearing its Target once nobody is left using it
local function ReleaseTeleporterTarget(inst)
    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)
    if inst.pending_teleports == 0 and not inst.components.teleporter:IsBusy() then
        inst.components.teleporter:Target(nil)
    end
end

-- scheduled on OnStartChannelingProjector and OnStartChannelingReceptor, guards the channeling wind up
local function OnRemove(structure, channeler, flagname)
    if channeler[flagname] then
        channeler[flagname] = nil
        local outtarget = channeler.um_astral_outbound_target
        if outtarget ~= nil and outtarget:IsValid() then
            outtarget.pending_teleports = math.max(0, (outtarget.pending_teleports or 1) - 1)
        end
        channeler.um_astral_outbound_home = nil
        channeler.um_astral_outbound_target = nil
        if channeler.components.health ~= nil then
            channeler.components.health:SetInvincible(false)
        end
        if channeler.components.playercontroller ~= nil then
            channeler.components.playercontroller:Enable(true)
        end
        if structure ~= nil and structure:IsValid() then
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
    player.um_astral_outbound_target = nil

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
                local tgt = (target ~= nil and target:IsValid()) and target or nil
                StopPairAnimations(h, tgt)
                if tgt ~= nil and tgt.active_home ~= nil and CountProjectedPlayers(nil, tgt) == 0 then
                    tgt.active_home = nil
                end
            end
        end)
    end
end

-- forced return helpers: used by anything that isnt a normal channeled return
-- offsets a destination point a small random distance away, so a forced return doesnt land in the center
local function OnReturn(dest_x, dest_y, dest_z)
    local angle = math.random() * TWOPI
    return dest_x + math.cos(angle) * ASTRAL_RETURN_OFFSET, dest_y, dest_z + math.sin(angle) * ASTRAL_RETURN_OFFSET
end

-- teleports a player back to their projectors position without going through the normal return flow
local function ForceReturnPlayer(player, dest_x, dest_y, dest_z)
    local minions = player.um_astral_minions
    local was_dead = player.components.health ~= nil and player.components.health:IsDead()

    CleanupPlayerProjection(player)

    local px, py, pz = player.Transform:GetWorldPosition()
    SpawnPrefab("halloween_firepuff_cold_" .. math.random(3)).Transform:SetPosition(px, py, pz)
    player.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_fx")

    -- actually moves the player and any minions that came along to the destination
    local function DoReturn(pl)
        if pl:HasTag("INLIMBO") then return end

        if dest_x ~= nil and pl.Physics ~= nil then
            pl.Physics:Teleport(OnReturn(dest_x, dest_y, dest_z))

            if minions ~= nil then
                for _, minion in ipairs(minions) do
                    if minion:IsValid() and minion.Physics ~= nil then
                        minion.Physics:Teleport(OnReturn(dest_x, dest_y, dest_z))
                    end
                end
            end
        end

        pl.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")

        if (pl.components.health == nil or not pl.components.health:IsDead()) and pl.components.grogginess ~= nil then
            pl.components.grogginess:SetPercent(ASTRAL_GROGGINESS_FORCED)
        end
    end

    if was_dead then
        player.components.health:SetInvincible(true)
        if player.components.playercontroller ~= nil then
            player.components.playercontroller:Enable(false)
        end
        player.DynamicShadow:Enable(false)
        player:Hide()
        player:ScreenFade(false, FORCE_RETURN_FADE)

        player:DoTaskInTime(FORCE_RETURN_FADE, function(pl)
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

            DoReturn(pl)
            pl:ScreenFade(true, 1)

            if pl.sg ~= nil and not pl.sg:HasStateTag("dead") then
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
    else
        -- "forceexitastralportal" state is defined in postinit/stategraphs/SGwilson.lua
        player.sg:GoToState("forceexitastralportal", {
            fadetime = FORCE_RETURN_FADE,
            onreturn = DoReturn,
        })
    end
end

-- force returns all players that were projected through a specific projector
local function ReturnAllPlayersFromProjector(projector)
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

-- force returns all players currently at a specific receptionator, regardless of which projector each one came from
local function ReturnAllPlayersAtReceptor(target)
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

-- restores anyone still mid channeling on a projector thats about to be destroyed, since they are not yet tagged and ReturnAllPlayersFromProjector wont catch them
local function RestorePendingChannelersAtProjector(projector)
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_outbound_pending and player.um_astral_outbound_home == projector then
            OnRemove(projector, player, "um_astral_outbound_pending")
        end
    end
end

-- same as above, but for when the receptionator someones mid channeling toward gets destroyed instead of their projector
local function RestorePendingChannelersAtReceptor(target)
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_outbound_pending and player.um_astral_outbound_target == target then
            OnRemove(player.um_astral_outbound_home, player, "um_astral_outbound_pending")
        end
    end
end

-- projectinator stuff below
-- starts when a player starts channeling the projector, plays the activation animation, then sets up the projection state and sends the player through
local function OnStartChannelingProjector(inst, channeler)
    if channeler.um_astral_outbound_pending then return end

    local target = FindNearestReceptor(inst)

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
    channeler.um_astral_outbound_target = target

    channeler.components.health:SetInvincible(true)
    if channeler.components.playercontroller ~= nil then
        channeler.components.playercontroller:Enable(false)
    end

    inst.components.teleporter:Target(target)
    inst.pending_teleports = (inst.pending_teleports or 0) + 1
    target.pending_teleports = (target.pending_teleports or 0) + 1
    inst:DoTaskInTime(ASTRAL_TELEPORT_TIMEOUT, OnRemove, channeler, "um_astral_outbound_pending")

    channeler.sg:GoToState("enterastralportal", { teleporter = inst })
end

-- triggers when the player stops channeling before the teleport completes
local function OnStopChannelingProjector(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    StopPairAnimations(inst, FindNearestReceptor(inst))
end

-- triggers  when the teleporter activates and the player is actually in transit.
-- sets up the return task and disconnect handler
local function OnStartTeleportingProjector(inst, doer)
    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)

    local outtarget = doer.um_astral_outbound_target
    if outtarget ~= nil and outtarget:IsValid() then
        outtarget.pending_teleports = math.max(0, (outtarget.pending_teleports or 1) - 1)
    end

    if not doer:HasTag("player") then return end

    local target = FindNearestReceptor(inst)

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
    doer.um_astral_outbound_target = nil

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

    -- clean up if the player disconnects or despawns while projected
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
        -- shard travel, clean up silently, sneak 100
        if doer:HasTag("INLIMBO") then
            CleanupPlayerProjection(doer)
            return
        end

        -- player is dead: death handler already called ForceReturnPlayer, dont pile on
        if doer.components.health ~= nil and doer.components.health:IsDead() then return end

        -- recover target reference if it was destroyed and a new one exists
        local tgt = doer.um_astral_target
        if tgt ~= nil and not tgt:IsValid() then
            tgt = doer.um_astral_home and doer.um_astral_home:IsValid() and FindNearestReceptor(doer.um_astral_home) or nil
            doer.um_astral_target = tgt
        end

        if home ~= nil and home:IsValid() then
            if tgt ~= nil and tgt:IsValid() then
                -- auto return if the player wanders too far from the receptionator
                local dist_to_exit = doer:GetDistanceSqToInst(tgt)
                if dist_to_exit >= ASTRAL_CIRCLE_DISTSQ and not doer.um_astral_returning then
                    local hx, hy, hz = home.Transform:GetWorldPosition()
                    ForceReturnPlayer(doer, hx, hy, hz)
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
local function OnExitingTeleporterProjector(inst, obj)
    inst.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")
    if obj ~= nil and obj:HasTag("player") then
        if obj.Physics ~= nil then
            local ix, iy, iz = inst.Transform:GetWorldPosition()
            obj.Physics:Teleport(OnReturn(ix, iy, iz))
        end
        --  grogginess on arrival at receptionator, only if alive
        if obj.components.grogginess ~= nil
            and obj.components.health ~= nil
            and not obj.components.health:IsDead() then
            obj.components.grogginess:SetPercent(ASTRAL_GROGGINESS_NORMAL)
        end
    end
    -- save the receptionator reference before clearing the teleporter (FindNearestReceptor after clear is unreliable in multi pair setups)
    local tgt = (obj ~= nil and obj.um_astral_target ~= nil and obj.um_astral_target:IsValid()) and obj.um_astral_target
        or inst.components.teleporter.targetTeleporter
    inst.components.teleporter:Target(nil)
    if tgt ~= nil and tgt:IsValid() then
        tgt.components.teleporter:Target(nil)
    end
end

-- projector is hammered, force return all linked players then destroy
local function OnHammeredProjector(inst)
    local target = FindNearestReceptor(inst)
    ReturnAllPlayersFromProjector(inst)
    RestorePendingChannelersAtProjector(inst)
    StopPairPortals(inst, target)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

-- hammer hit callback, defaults to active_loop, if it was already active
local function OnHitProjector(inst)
    local was_active = inst.AnimState:IsCurrentAnimation("active_loop")
    inst.AnimState:PlayAnimation("hammer")
    if was_active then
        inst.AnimState:PushAnimation("active_loop", true)
    end
end

-- shared behavior used by both structures constructors
-- plays the placement animation/sound when either structure is first built
local function OnBuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

-- returns ACTIVE to the inspect string when the teleporter is active, otherwise nil so it doesnt show up at all
local function GetStatus(inst)
    return inst.components.teleporter:IsActive() and "ACTIVE" or nil
end

-- spawns the minimap icon once, one frame after construction
local function init(inst)
    if inst.icon == nil then
        inst.icon = SpawnPrefab("globalmapicon")
        inst.icon:TrackEntity(inst)
    end
end

-- projectinator constructor
local function ProjectorFn()
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
    inst.components.workable:SetOnFinishCallback(OnHammeredProjector)
    inst.components.workable:SetOnWorkCallback(OnHitProjector)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChannelingProjector, OnStopChannelingProjector)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleportingProjector
    inst.components.teleporter.offset           = 0
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.stopcamerafades  = true
    inst.components.teleporter.travelcameratime = 0
    inst.components.teleporter.travelarrivetime = 0

    inst:ListenForEvent("doneteleporting", OnExitingTeleporterProjector)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst.OnEntityWake  = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst.ReleaseTeleporterTarget = ReleaseTeleporterTarget

    inst:DoTaskInTime(0, init)

    return inst
end

-- receoptionator stuff below
-- func for when a projected player channels the receptionator to return.
-- animation plays unconditionally, teleport only proceeds if this is the correct receptionator
local function OnStartChannelingReceptor(inst, channeler)
    if channeler.um_astral_returning then return end

    local home = channeler.um_astral_home

    -- always animate, the init_actions STARTCHANNELING override handles blocking wrong receptionators
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

    channeler.sg:GoToState("enterastralportal", { teleporter = inst })
end

-- when the player stops channeling the receptionator before completing the return
local function OnStopChannelingReceptor(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    StopPairAnimations(inst.active_home, inst)
    if CountProjectedPlayers(nil, inst) == 0 then
        inst.active_home = nil
    end
end

-- player finishes teleporting back through the receptionator
local function OnExitingTeleporterReceptor(inst, obj)
    inst.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")
    if obj ~= nil and obj:HasTag("player") then
        -- apply grogginess on normal return, only if alive
        if obj.components.grogginess ~= nil
            and obj.components.health ~= nil
            and not obj.components.health:IsDead() then
            obj.components.grogginess:SetPercent(ASTRAL_GROGGINESS_NORMAL)
        end

        inst:DoTaskInTime(32 * FRAMES, StartPool)
    end
    inst.components.teleporter:Target(nil)
    local home = inst.active_home
    inst.active_home = nil
    if home ~= nil and home:IsValid() then
        home.components.teleporter:Target(nil)
    end
end

-- fires when the return teleport activates on the receptionator side
local function OnStartTeleportingReceptor(inst, doer)
    local home = inst.active_home

    inst.pending_teleports = math.max(0, (inst.pending_teleports or 1) - 1)

    if doer:HasTag("player") then
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

    if CountProjectedPlayers(nil, inst) == 0 and (inst.pending_teleports or 0) == 0 then
        inst.active_home = nil
        inst.AnimState:PlayAnimation("active_pst")
        inst.AnimState:PushAnimation("idle", true)
        StopSoundLoop(inst)
        StopLeashRing(inst)
        StopPool(inst)
    end

    if home ~= nil and home:IsValid() and CountProjectedPlayers(home, nil) == 0
        and (home.pending_teleports or 0) == 0 then
        home.AnimState:PlayAnimation("active_pst")
        home.AnimState:PushAnimation("idle", true)
        StopSoundLoop(home)
    end
end

-- receptionator hammered, find its linked projector, force return players, then destroy
local function OnHammeredReceptor(inst)
    local home = FindNearestProjector(inst)
    ReturnAllPlayersAtReceptor(inst)
    RestorePendingChannelersAtReceptor(inst)
    StopPairPortals(home, inst)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

-- hammer hit callback
local function OnHitReceptor(inst)
    local was_active = inst.AnimState:IsCurrentAnimation("active_loop")
    inst.AnimState:PlayAnimation("hammer")
    if was_active then
        inst.AnimState:PushAnimation("active_loop", true)
    end
end

-- receptionator constructor
local function ReceptorFn()
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
    inst.components.workable:SetOnFinishCallback(OnHammeredReceptor)
    inst.components.workable:SetOnWorkCallback(OnHitReceptor)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChannelingReceptor, OnStopChannelingReceptor)
    --inst.components.channelable:SetEnabled(false)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleportingReceptor
    inst.components.teleporter.offset           = 0
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.stopcamerafades  = true
    inst.components.teleporter.travelcameratime = 0
    inst.components.teleporter.travelarrivetime = 0

    inst:ListenForEvent("doneteleporting", OnExitingTeleporterReceptor)

    inst.ReleaseTeleporterTarget = ReleaseTeleporterTarget
    inst.SpawnLeashRing          = SpawnLeashRing

    inst.OnEntityWake  = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", OnBuilt)

    inst:DoTaskInTime(0, init)

    return inst
end

return
    Prefab("um_astral_projector", ProjectorFn, assets, prefabs),
    MakePlacer("um_astral_projector_placer", "um_archives_projectinator", "um_archives_projectinator", "idle"),
    Prefab("um_astral_projector_target", ReceptorFn, assets, prefabs),
    MakePlacer("um_astral_projector_target_placer", "um_archives_receptionator", "um_archives_receptionator", "idle"),
    Prefab("um_astral_leash_warning", LeashRingFn, nil, { "alterguardian_lasertrail" }),
    Prefab("um_astral_arrival_pool", ArrivalPoolFn, assets)
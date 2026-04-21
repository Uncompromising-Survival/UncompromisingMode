require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/um_archives_projectinator.zip"),
    Asset("ANIM", "anim/um_archives_receptionator.zip"),
    Asset("MINIMAP_IMAGE", "townportalactive"),
}

local fx_assets =
{
    Asset("ANIM", "anim/um_lunar_spark.zip"),
    Asset("ANIM", "anim/teleport_sand_fx.zip"),
    Asset("ANIM", "anim/sand_splash_fx.zip"),
}

local prefabs =
{
    "collapse_small",
    "globalmapicon",
}

-- how long the screen stays dark when a player is force-returned (hammering, disconnect, etc.)
local FORCE_RETURN_FADE = 1

-- finds the closest receptionator to a given projector
local function FindNearestTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    --10000 radius might be overkill??? idfk
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

-- counts how many players are currently projected across all pairs
local function CountProjectedPlayers()
    local count = 0
    for _, player in ipairs(AllPlayers) do
        if player.um_astral_projected then
            count = count + 1
        end
    end
    return count
end

-- sound loop helpers, tied to entity sleep/wake so sounds stop when the chunk unloads
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

-- hard stop both structures, skipping the pst animation (used when hammering yeeeee)
local function StopPairPortals(projector, target)
    if projector ~= nil and projector:IsValid() then
        StopSoundLoop(projector)
        projector.AnimState:PlayAnimation("idle", true)
        projector.components.teleporter:Target(nil)
    end
    if target ~= nil and target:IsValid() then
        StopSoundLoop(target)
        target.AnimState:PlayAnimation("idle", true)
        target.components.teleporter:Target(nil)
    end
end

-- graceful stop, plays the deactivation animation on both structures
local function StopPairAnimations(projector, target)
    if projector ~= nil and projector:IsValid() then
        StopSoundLoop(projector)
        projector.SoundEmitter:PlaySound("rifts6/vault_portal/turn_off")
        projector.AnimState:PlayAnimation("active_pst")
        projector.components.teleporter:Target(nil)
    end
    if target ~= nil and target:IsValid() then
        StopSoundLoop(target)
        target.SoundEmitter:PlaySound("rifts6/vault_portal/turn_off")
        target.AnimState:PlayAnimation("active_pst")
        target.components.teleporter:Target(nil)
    end
end

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

    if player.components.sanity ~= nil then
        player.components.sanity.externalmodifiers:RemoveModifier("um_astral_projector")
    end

    if player.um_astral_projected_returntask ~= nil then
        player.um_astral_projected_returntask:Cancel()
        player.um_astral_projected_returntask = nil
    end

    if player.AnimState ~= nil then
        player.AnimState:SetErosionParams(0, 0, 0)
    end

    if player.um_astral_deactivated_fn ~= nil then
        player:RemoveEventCallback("playerdeactivated", player.um_astral_deactivated_fn)
        player:RemoveEventCallback("onremove", player.um_astral_deactivated_fn)
        player:RemoveEventCallback("death", player.um_astral_deactivated_fn)
        player.um_astral_deactivated_fn = nil
    end

    -- defer one frame so CountProjectedPlayers reflects the updated state
    if home ~= nil and home:IsValid() then
        home:DoTaskInTime(0, function(h)
            if h ~= nil and h:IsValid() and CountProjectedPlayers() == 0 then
                local tgt = (target ~= nil and target:IsValid()) and target or FindNearestTarget(h)
                StopPairAnimations(h, tgt)
                if tgt ~= nil and tgt.active_home ~= nil then
                    tgt.active_home = nil
                end
            end
        end)
    end
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
            pl.Physics:Teleport(dest_x, dest_y, dest_z)
        end

        pl.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_arrive_FX")
        pl:ScreenFade(true, 1)

        if pl.sg ~= nil then
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

-- starts when a player starts channeling the projector.
-- plays the activation animation, then sets up the projection state and sends the player through
local function OnStartChanneling(inst, channeler)
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

    channeler:AddTag("um_astral_projected")
    channeler.um_astral_projected = true
    channeler.um_astral_home      = inst    -- which projector sent this player
    channeler.um_astral_target    = target  -- which receptionator they're linked to, smart right?

    inst.components.teleporter:Target(target)

    if channeler.components.sanity ~= nil then
        channeler.components.sanity.externalmodifiers:SetModifier(
            "um_astral_projector",
            -TUNING.DAPPERNESS_SUPERHUGE
        )
    end

    channeler.sg:GoToState("enterastralportal", { teleporter = inst })
end

-- triggers when the player stops channeling before the teleport completes (they walk away or sum)
local function OnStopChanneling(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    if CountProjectedPlayers() == 0 then
        StopPairAnimations(inst, FindNearestTarget(inst))
    end
end

-- triggers  when the teleporter activates and the player is actually in transit.
-- sets up the return task and disconnect handler
local function OnStartTeleporting(inst, doer)
    inst.SoundEmitter:PlaySound("rifts6/vault_portal/teleport_fx")

    if not doer:HasTag("player") then return end

    local target = FindNearestTarget(inst)

    doer.AnimState:SetErosionParams(-0.5, -0.2, -1.0)
    doer:AddTag("um_astral_projected")
    doer.um_astral_projected = true
    doer.um_astral_home      = inst

    if doer.components.talker ~= nil then
        doer.components.talker:ShutUp()
    end

    if target ~= nil and target:IsValid() then
        target.SpawnPool(target)
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
    doer:ListenForEvent("death", on_player_deactivated)

    local home = inst
    -- periodic task that watches whether the player is too far from the exit or the projector got destroyed
    doer.um_astral_projected_returntask = doer:DoPeriodicTask(0.5, function()
        -- shard travel - clean up silently, sneak 100
        if doer:HasTag("INLIMBO") then
            CleanupPlayerProjection(doer)
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
                -- auto-return if the player wanders too far from the receptionator, bad gamer boi
                local dist_to_exit = doer:GetDistanceSqToInst(tgt)
                if dist_to_exit >= 530 then
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
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport")
    end
    inst.components.teleporter:Target(nil)
    local tgt = FindNearestTarget(inst)
    if tgt ~= nil and tgt:IsValid() then
        tgt.components.teleporter:Target(nil)
    end
end

-- projector is hammered: force return all linked players then destroy
local function onhammered(inst)
    local target = FindNearestTarget(inst)
    StopPairPortals(inst, target)
    ReturnAllProjectedPlayers(inst)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst)
    inst.AnimState:PlayAnimation("hammer")
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle")
end

local function GetStatus(inst)
    return inst.components.teleporter:IsActive() and "ACTIVE" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("townportal.png")
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

    --common components ye
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling, OnStopChanneling)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleporting
    inst.components.teleporter.offset           = 2
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.travelcameratime = 1.5
    inst.components.teleporter.travelarrivetime = 1.5

    inst:ListenForEvent("doneteleporting", OnExitingTeleporter)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnEntityWake  = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

local function KillFX(inst)
    if inst.killtask ~= nil then
        inst.killtask:Cancel()
        inst.killtask = nil
        inst.AnimState:PlayAnimation("spark_pst")
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .5, inst.Remove)
    end
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_lunar_spark")
    inst.AnimState:SetBuild("um_lunar_spark")
    inst.AnimState:PlayAnimation("spark_loop", true)
    inst.AnimState:SetFinalOffset(7)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.KillFX   = KillFX

    return inst
end

-- func for when a projected player channels the receptionator to return.
-- animation plays unconditionally, teleport only proceeds if this is the correct receptionator
local function OnStartChanneling_Target(inst, channeler)
    local home = channeler.um_astral_home

    -- always animate, the modmain STARTCHANNELING override handles blocking wrong receptionators
    if not inst.AnimState:IsCurrentAnimation("active_loop") then
        inst.AnimState:PlayAnimation("active_pre")
        inst.AnimState:PushAnimation("active_loop", true)
    end
    StartSoundLoop(inst)

    if home == nil or not home:IsValid() then return end
    if not channeler.um_astral_projected then return end
    if channeler.um_astral_target ~= inst then return end

    -- store home on the receptionator for use during the return trip, since we're about to clear it from the player, fooshizzle
    inst.active_home = home

    channeler:RemoveTag("um_astral_projected")
    channeler.um_astral_projected = false
    channeler.um_astral_home      = nil
    channeler.um_astral_target    = nil

    inst.components.teleporter:Target(home)

    if channeler.components.sanity ~= nil then
        channeler.components.sanity.externalmodifiers:RemoveModifier("um_astral_projector")
    end

    if channeler.um_astral_projected_returntask ~= nil then
        channeler.um_astral_projected_returntask:Cancel()
        channeler.um_astral_projected_returntask = nil
    end

    if channeler.um_astral_deactivated_fn ~= nil then
        channeler:RemoveEventCallback("playerdeactivated", channeler.um_astral_deactivated_fn)
        channeler:RemoveEventCallback("onremove", channeler.um_astral_deactivated_fn)
        channeler:RemoveEventCallback("death", channeler.um_astral_deactivated_fn)
        channeler.um_astral_deactivated_fn = nil
    end

    channeler.sg:GoToState("enterastralportal_nofx", { teleporter = inst })
end

-- when the player stops channeling the receptionator before completing the return
local function OnStopChanneling_Target(inst, aborted)
    if inst.components.teleporter.targetTeleporter ~= nil then return end
    if CountProjectedPlayers() == 0 then
        StopPairAnimations(inst.active_home, inst)
        inst.active_home = nil
    end
end

-- player finishes teleporting back through the receptionator
local function OnExitingTeleporter_Target(inst, obj)
    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport")
    end
    inst.components.teleporter:Target(nil)
    local home = inst.active_home
    inst.active_home = nil
    if home ~= nil and home:IsValid() then
        home.components.teleporter:Target(nil)
    end
    if CountProjectedPlayers() == 0 then
        StopPairAnimations(home, inst)
    end
end

-- spawns the whirlpool fx at the receptionator when a player arrives
local function SpawnPool(inst)
    if inst.astralpool == nil then
        inst.astralpool = SpawnPrefab("um_astral_pool")
        inst.astralpool.entity:SetParent(inst.entity)
        inst.astralpool.Transform:SetPosition(0, 0, 0)
        inst.astralpool.owner = inst
    end
end

-- fires when the return teleport activates on the receptionator side
local function OnStartTeleporting_Target(inst, doer)
    -- use the stored home reference, cleared from the player in OnStartChanneling_Target
    local home = inst.active_home

    inst.AnimState:PlayAnimation("active_pst")
    StopSoundLoop(inst)

    if home ~= nil and home:IsValid() then
        home.AnimState:PlayAnimation("active_pst")
        StopSoundLoop(home)
    end

    if not doer:HasTag("player") then return end

    doer.AnimState:SetErosionParams(0, 0, 0)
    doer:RemoveTag("um_astral_projected")
    doer.um_astral_projected = false
    doer.um_astral_home      = nil

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
end

-- receptionator is hammered ----> find its linked projector, force-return players, then destroy
local function onhammered_target(inst)
    local home = FindNearestProjector(inst)
    StopPairPortals(home, inst)
    ReturnAllProjectedPlayers(home)
    local fx = SpawnPrefab("collapse_small")
    inst.components.lootdropper:DropLoot()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit_target(inst)
    inst.AnimState:PlayAnimation("hammer")
end

local function targetfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("townportal.png")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    MakeObstaclePhysics(inst, .1)

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
    inst.components.workable:SetOnFinishCallback(onhammered_target)
    inst.components.workable:SetOnWorkCallback(onhit_target)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling_Target, OnStopChanneling_Target)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate       = OnStartTeleporting_Target
    inst.components.teleporter.offset           = 0  -- player spawns at the exact structure position, not 2 anymore, 2 is cringe
    inst.components.teleporter.saveenabled      = false
    inst.components.teleporter.travelcameratime = 2.9
    inst.components.teleporter.travelarrivetime = 2.8

    inst:ListenForEvent("doneteleporting", OnExitingTeleporter_Target)

    inst.OnStartChanneling_Target = OnStartChanneling_Target
    inst.SpawnPool                = SpawnPool

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:ListenForEvent("onbuilt", onbuilt)

    return inst
end

-- checks if there are any projected players nearby, kills the pool if not
local function Vac(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local projectors = TheSim:FindEntities(x, y, z, 23, { "um_astral_projected" })
    if projectors ~= nil and #projectors == 0 then
        if not inst.components.timer:TimerExists("kill_whirlpool") then
            inst.components.timer:StartTimer("kill_whirlpool", 1)
        end
    end
end

local function StartChecks(inst)
    if inst.vactask == nil then
        inst.vactask = inst:DoPeriodicTask(.5, Vac)
    end
end

local function Init(inst)
    inst.SoundEmitter:PlaySound("UCSounds/um_whirlpool/um_whirlpool_loop", "whirlpool")
end

local function RemoveWhirlpool(inst)
    inst.components.colourtweener:StartTween({ 1, 1, 1, 0 }, 5, inst.Remove)
    inst.SoundEmitter:KillSound("whirlpool")
    if inst.owner ~= nil then
        inst.owner.astralpool = nil
    end
    inst:Remove()
end

local function poolfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    -- start transparent, tween to a soft blue, less eye strain
    inst.AnimState:SetMultColour(0.5, 0.7, 1, 0)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("um_whirlpool")
    inst.AnimState:SetBuild("um_astralpool")
    inst.AnimState:PlayAnimation("spin2", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.Transform:SetScale(3, 3, 3)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("colourtweener")
    -- fade in over 3 seconds, then start the proximity check task
    inst.components.colourtweener:StartTween({ 0.5, 0.7, 1, 0.6 }, 3, StartChecks)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", RemoveWhirlpool)

    inst:DoTaskInTime(0, Init)

    return inst
end


return
    Prefab("um_lunar_spark", fx_fn, fx_assets, prefabs),
    Prefab("um_astral_projector", fn, assets, prefabs),
    MakePlacer("um_astral_projector_placer", "um_archives_projectinator", "um_archives_projectinator", "idle"),
    Prefab("um_astral_projector_target", targetfn, assets, prefabs),
    MakePlacer("um_astral_projector_target_placer", "um_archives_receptionator", "um_archives_receptionator", "idle"),
    Prefab("um_astral_pool", poolfn, assets, prefabs)
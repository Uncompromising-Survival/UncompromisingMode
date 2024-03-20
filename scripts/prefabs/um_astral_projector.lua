require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/townportal.zip"),
    Asset("MINIMAP_IMAGE", "townportalactive"),
}

local fx_assets =
{
    Asset("ANIM", "anim/teleport_sand_fx.zip"),
    Asset("ANIM", "anim/sand_splash_fx.zip"),
}

local prefabs =
{
    "collapse_small",
    "globalmapicon",
    "townportalsandcoffin_fx",
}

local function OnEntityWake(inst)
    if inst.playingsound and not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("active")) then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/talisman_active", "active")
    end
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("active")
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
        inst.SoundEmitter:KillSound("active")
    end
end

local function OnStartChanneling(inst, channeler)
	local target = TheSim:FindFirstEntityWithTag("um_astral_projector_target")
	
    inst.AnimState:PlayAnimation("turn_on")
    inst.AnimState:PushAnimation("idle_on_loop")
    StartSoundLoop(inst)
	
	if target ~= nil and not channeler.um_astral_projected then
		channeler:AddTag("um_astral_projected")
		channeler.um_astral_projected = true
		inst.components.teleporter:Target(target)

		if channeler ~= nil then
			channeler.components.sanity.externalmodifiers:SetModifier("um_astral_projector", -TUNING.DAPPERNESS_SUPERHUGE)
		end
		
		channeler.sg:GoToState("enterastralportal", { teleporter = inst })
	end
end

local function OnStopChanneling(inst, aborted)
    if inst.channeler ~= nil and inst.channeler:IsValid() and inst.channeler.components.sanity ~= nil then
        --inst.channeler.components.sanity.externalmodifiers:RemoveModifier(inst)
    end
end

local function OnStartTeleporting(inst, doer)
    if doer:HasTag("player") then
		doer:AddTag("um_astral_projected")
		doer.um_astral_projected = true
		
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
		
		local target = TheSim:FindFirstEntityWithTag("um_astral_projector_target")
		if target ~= nil then
			target.SpawnPool(target)
		end
		
		if doer.um_astral_projected_returntask ~= nil then
			doer.um_astral_projected_returntask:Cancel()
		end
		
		doer.um_astral_projected_returntask = doer:DoPeriodicTask(0.5, function()
			local target = TheSim:FindFirstEntityWithTag("um_astral_projector_target")
			local home = TheSim:FindFirstEntityWithTag("um_astral_projector")
			local dist_to_exit = target ~= nil and target:IsValid() and doer:GetDistanceSqToInst(target)
			
			if home ~= nil then
				if dist_to_exit ~= nil then
					if dist_to_exit >= 530 then
						target.OnStartChanneling_Target(target, doer)
					end
				else
					if doer.components.health ~= nil then
						doer.components.health:Kill()
					end
				end
			else
				if doer.components.health ~= nil then
					doer.components.health:Kill()
				end
			end
		end)
    end
end

local function OnExitingTeleporter(inst, obj)
    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport") -- for wisecracker
    end
end

local function onhammered(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst:Remove()
end

local function onhit(inst)
    if inst.components.channelable:IsChanneling() then
        inst.components.channelable:StopChanneling(true)
        inst.AnimState:PlayAnimation("hit_on")
    else
        if inst.components.teleporter.targetTeleporter ~= nil then
            TheWorld:PushEvent("townportaldeactivated")
            inst.AnimState:PlayAnimation("hit_on")
        else
            inst.AnimState:PlayAnimation("hit_off")
        end
    end
    inst.AnimState:PushAnimation("idle_off")
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_off")

    if inst.components.teleporter.targetTeleporter ~= nil then
        inst.AnimState:PushAnimation("turn_on", false)
        inst.AnimState:PushAnimation("idle_on_loop")
        StartSoundLoop(inst)
    end
end

local function GetStatus(inst)
    return (inst.components.channelable:IsChanneling() or
            inst.components.teleporter:IsActive())
        and "ACTIVE"
        or nil
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

    inst.AnimState:SetBank("townportal")
    inst.AnimState:SetBuild("townportal")
    inst.AnimState:PlayAnimation("idle_off", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("structure")
    inst:AddTag("um_astral_projector")
	
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    MakeHauntableWork(inst)
    MakeSnowCovered(inst)

    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling, OnStopChanneling)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnStartTeleporting
    inst.components.teleporter.offset = 2
    inst.components.teleporter.saveenabled = false
    inst.components.teleporter.travelcameratime = 2.9
    inst.components.teleporter.travelarrivetime = 2.8

    --inst:ListenForEvent("starttravelsound", StartTravelSound) -- triggered by player stategraph
    inst:ListenForEvent("doneteleporting", OnExitingTeleporter)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    -----------------------------
    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    return inst
end

local function KillFX(inst)
    if inst.killtask ~= nil then
        inst.killtask:Cancel()
        inst.killtask = nil
        inst.Physics:SetActive(false)
        inst.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/out")
        inst.AnimState:PlayAnimation("portal_out")
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .5, inst.Remove)
    end
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.AnimState:SetBank("teleport_sand_fx")
    inst.AnimState:SetBuild("teleport_sand_fx")
    inst.AnimState:OverrideSymbol("sand_splash", "sand_splash_fx", "sand_splash")
    inst.AnimState:PlayAnimation("portal_in")
	inst.AnimState:SetFinalOffset(7)

    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/in")

    inst.persists = false
    inst.KillFX = KillFX
    inst.killtask = inst:DoTaskInTime(35 * FRAMES, KillFX)

    return inst
end

local function OnStartChanneling_Target(inst, channeler)
	local target = TheSim:FindFirstEntityWithTag("um_astral_projector")
	
    inst.AnimState:PlayAnimation("turn_on")
    inst.AnimState:PushAnimation("idle_on_loop")
    StartSoundLoop(inst)
	
	if target ~= nil and channeler.um_astral_projected then
		channeler:RemoveTag("um_astral_projected")
		channeler.um_astral_projected = false
		inst.components.teleporter:Target(target)

		if channeler ~= nil then
			channeler.components.sanity.externalmodifiers:RemoveModifier("um_astral_projector")
		end
		
		channeler.sg:GoToState("enterastralportal_nofx", { teleporter = inst })
	end
end

local function OnStopChanneling_Target(inst, aborted)
    if inst.channeler ~= nil and inst.channeler:IsValid() and inst.channeler.components.sanity ~= nil then
        --inst.channeler.components.sanity.externalmodifiers:RemoveModifier(inst)
    end
end

local function OnExitingTeleporter_Target(inst, obj)
    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "townportalteleport") -- for wisecracker
    end
end

local function SpawnPool(inst)
	if inst.astralpool == nil then
		inst.astralpool = SpawnPrefab("um_astral_pool")
		inst.astralpool.entity:SetParent(inst.entity)
		inst.astralpool.Transform:SetPosition(0, 0, 0)
		inst.astralpool.owner = inst
	end
end

local function OnStartTeleporting_Target(inst, doer)
    if doer:HasTag("player") then
		doer:RemoveTag("um_astral_projected")
		doer.um_astral_projected = false
		
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
		
		if doer.um_astral_projected_returntask ~= nil then
			doer.um_astral_projected_returntask:Cancel()
		end
		
		doer.um_astral_projected_returntask = nil
    end
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

    inst.AnimState:SetBank("townportal")
    inst.AnimState:SetBuild("townportal")
    inst.AnimState:PlayAnimation("idle_off", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetMultColour(0, 0, 1, 1)

    inst:AddTag("structure")
    inst:AddTag("um_astral_projector_target")
	
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("channelable")
    inst.components.channelable:SetChannelingFn(OnStartChanneling_Target, OnStopChanneling_Target)

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnStartTeleporting_Target
    inst.components.teleporter.offset = 2
    inst.components.teleporter.saveenabled = false
    inst.components.teleporter.travelcameratime = 2.9
    inst.components.teleporter.travelarrivetime = 2.8
	
    inst:ListenForEvent("doneteleporting", OnExitingTeleporter_Target)
	
	inst.SpawnPool = SpawnPool
	inst.OnStartChanneling_Target = OnStartChanneling_Target

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    return inst
end

local function Vac(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local projectors = TheSim:FindEntities(x, y, z, 23, {"um_astral_projected"})
	
	if projectors ~= nil and #projectors == 0 then
		inst.components.timer:StartTimer("kill_whirlpool", 1)
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
	inst.components.colourtweener:StartTween({1,1,1,0}, 5, inst.Remove)
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
	
	inst.AnimState:SetMultColour(1,1,1,0)

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
	inst.components.colourtweener:StartTween({1,1,1,1}, 3, StartChecks)
	
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone", RemoveWhirlpool)
	
	inst:DoTaskInTime(0, Init)
	
    return inst
end

return Prefab("um_astral_projector", fn, assets, prefabs),
    MakePlacer("um_astral_projector_placer", "townportal", "townportal", "idle"),
	Prefab("um_astral_projector_target", targetfn, assets, prefabs),
    MakePlacer("um_astral_projector_target_placer", "townportal", "townportal", "idle"),
    Prefab("townportalsandcoffin_fx", fx_fn, fx_assets),
	Prefab("um_astral_pool", poolfn, assets, prefabs)

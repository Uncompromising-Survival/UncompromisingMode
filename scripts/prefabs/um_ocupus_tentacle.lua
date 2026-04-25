local brain = require "brains/um_ocupus_tentaclebrain"

SetSharedLootTable( 'um_ocupus_tentacle',
{
    {'um_ocupus_tentacle_item', 1.00},
    {'monstermeat', 1.00},
})

local function releaseclamp(inst, immediate)
	if inst.boat and inst.boat:IsValid() then
		if inst.boat.components.boatphysics ~= nil then
			inst.boat.components.boatphysics:RemoveBoatDrag(inst)
		end

        if inst._releaseclamp then
            inst:RemoveEventCallback("onremove", inst._releaseclamp, inst.boat)
            inst._releaseclamp = nil
        end
    end
    inst.boat = nil
    inst:PushEvent("releaseclamp", {immediate = immediate} )

    if inst.clamptask then
        inst.clamptask:Cancel()
        inst.clamptask = nil
    end
end

local function crunchboat(inst,boat)
    inst:PushEvent("clamp_attack",boat)
    if inst.clamptask then
        inst.clamptask:Cancel()
        inst.clamptask = nil
    end
    inst.clamptask = inst:DoTaskInTime(math.random()+3,function() inst.crunchboat(inst,inst.boat) end)
end

local CLAMPDAMAGE_CANT_TAGS = {"flying", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}
local function clamp(inst)
    if inst.boat and not inst.boat.components.health:IsDead() then
        inst.boat.components.health:DoDelta(-12)
        ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.03, 0.5, inst.boat, inst.boat:GetPhysicsRadius(4))
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 3, nil, CLAMPDAMAGE_CANT_TAGS)

        --[[for i, v in pairs(ents)do
            if v ~= inst and v:IsValid() and not v:IsInLimbo() then
                if      v.components.workable ~= nil and
                        v.components.workable:CanBeWorked() and
                        v.components.workable.action ~= ACTIONS.NET then
                    v.components.workable:Destroy(inst)
                end
                if      v.components.health ~= nil and
                        not v.components.health:IsDead() and
                        inst.components.combat:CanTarget(v) then
                    --inst.components.combat:DoAttack(v)
                end
            end
        end]]

		ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.03, 0.5, inst.boat, inst.boat:GetPhysicsRadius(4))

		if inst.boat.components.boatphysics ~= nil then
			inst.boat.components.boatphysics:AddBoatDrag(inst)
        end
        inst._releaseclamp = function() inst:releaseclamp() end
        inst:ListenForEvent("onremove", inst._releaseclamp, inst.boat)
        inst.clamptask = inst:DoTaskInTime(math.random()+3,function() inst.crunchboat(inst,inst.boat) end)
    end
end

local function teleport_override_fn(inst)
    local pt = inst:GetPosition()
    local offset = FindSwimmableOffset(pt, math.random() * 2 * PI, 3, 8, true, false) or
					FindSwimmableOffset(pt, math.random() * 2 * PI, 8, 8, true, false)
    if offset ~= nil then
		pt = pt + offset
    end

	return pt
end

local function OnTeleported(inst)
	inst:releaseclamp(true)
end

local function OnRemove(inst)
    if inst.shadow then
        inst.shadow:Remove()
    end
    inst.releaseclamp(inst)
end

local function OnDead(inst)
    inst.releaseclamp(inst)
	local loot = SpawnPrefab("ocupus_tentacle")
	loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
	loot.AnimState:PlayAnimation("tentacle_item_flop")
	loot.AnimState:PushAnimation("tentacle_item",true)
	inst:ListenForEvent("animover",function(inst) 
		inst:PushEvent("detachchild")
		if inst.shadow then
			inst.shadow:Remove()
			inst.shadow = nil
		end
		inst:Remove() 
	end)
end

local function isnotocupus(ent)
	if ent ~= nil and not ent:HasTag("ocupus") then -- fix to friendly AOE: refer for later AOE mobs -Axe
		return true
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 1000, 0.1)
	MakeInventoryFloatable(inst, "med", nil, 0.68)
    inst.Transform:SetFourFaced()

    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("animal")
    inst:AddTag("scarytoprey")
    inst:AddTag("hostile")
	inst:AddTag("ocupus")
    inst:AddTag("um_ocupus_tentacle")
	inst:AddTag("soulless")
    inst:AddTag("noember")

    local s  = 1.2
    inst.Transform:SetScale(s, s, s)

    inst.AnimState:SetBank("um_ocupus_tentacle")
    inst.AnimState:SetBuild("ocupus")
	
    inst.AnimState:PlayAnimation("idle", true)
    local land_time = (POPULATING and math.random()*5*FRAMES) or 0
    inst:DoTaskInTime(land_time, function(inst)
        inst.components.floater:OnLandedServer()
    end)	
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
	end

	inst:AddComponent("boatdrag")
	inst.components.boatdrag.drag = TUNING.CRABKING_ANCHOR_DRAG
	inst.components.boatdrag.forcedampening = 1
	inst.components.boatdrag.max_velocity_mod = TUNING.CRABKING_MAX_VELOCITY_MOD
    inst.components.boatdrag.sailforcemodifier = 0

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.CRABKING_CLAW_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.CRABKING_CLAW_RUN_SPEED
    ------------------------------------------

    inst:SetStateGraph("SGocupus_tentacle")

    ------------------

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(300)

    ------------------

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(50)
	inst.components.combat:SetAreaDamage(4, TUNING.DEERCLOPS_AOE_SCALE/2, isnotocupus) 
    inst.components.combat:SetRange(0)
    --inst.components.combat.hiteffectsymbol = "claw_parts_shoulder"
    inst.components.combat:SetAttackPeriod(0)

    ------------------------------------------

    inst:AddComponent("lootdropper")

    ------------------------------------------

    inst:AddComponent("inspectable")

    ------------------------------------------

    inst:AddComponent("timer")

    ------------------------------------------

    inst:AddComponent("knownlocations")

    ------------------------------------------

    inst:AddComponent("entitytracker")

    ------------------------------------------

    inst:SetBrain(brain)

    inst:ListenForEvent("death", OnDead)
    inst:ListenForEvent("onremove", OnRemove)
    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)

    inst.releaseclamp = releaseclamp
    inst.clamp = clamp
    inst.crunchboat = crunchboat

    MakeLargeBurnableCharacter(inst, "claw_parts_forearm")
    MakeHugeFreezableCharacter(inst, "claw_parts_forearm")

	inst:AddComponent("teleportedoverride")
	inst.components.teleportedoverride:SetDestPositionFn(teleport_override_fn)
	inst:ListenForEvent("teleported", OnTeleported)


	inst.shadow = inst:SpawnChild("crabking_claw_shadow")
	inst:DoTaskInTime(0,function(inst) inst.Appear(inst) end)
	inst.Appear = function(inst)
		local splash = SpawnPrefab("splash_ocean")
		splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
		splash.Transform:SetScale(1.5,1.5,1.5)
		inst.sg:GoToState("appear")
	end
	inst.Leave = function(inst)
		if inst.Transform:GetWorldPosition() then
			local splash = SpawnPrefab("splash_ocean")
			splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
			splash.Transform:SetScale(1.5,1.5,1.5)
			inst:Remove() --CK claw doesn't appear to have a state where it leaves...?
		end
	end
	inst.KillSelf = function(inst)
		if inst.Transform:GetWorldPosition() then
			local splash = SpawnPrefab("splash_ocean")
			splash.Transform:SetPosition(inst.Transform:GetWorldPosition())
			splash.Transform:SetScale(1.5,1.5,1.5)
			if inst.components.health then
				inst.components.health:Kill()
			end
		end
	end	
	inst.persists = false
    return inst
end

return Prefab("um_ocupus_tentacle",fn)
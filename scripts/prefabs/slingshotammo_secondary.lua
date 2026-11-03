-- wonder if this will work
if not TUNING.DSTU.WIXIE then
    return
end

local assets = { Asset("ANIM", "anim/slingshotammo.zip") }

local easing = require("easing")
require("wixie_shove")

local function UpdateFlash(target, data, id, r, g, b)
	if data.flashstep < 4 then
		local value = (data.flashstep > 2 and 4 - data.flashstep or data.flashstep) * 0.05
		if target.components.colouradder == nil then
			target:AddComponent("colouradder")
		end
		target.components.colouradder:PushColour(id, value * r, value * g, value * b, 0)
		data.flashstep = data.flashstep + 1
	else
		target.components.colouradder:PopColour(id)
		data.task:Cancel()
	end
end

local function StartFlash(inst, target, r, g, b)
	local data = { flashstep = 1 }
	local id = inst.prefab.."::"..tostring(inst.GUID)
	data.task = target:DoPeriodicTask(0, UpdateFlash, nil, data, id, r, g, b)
	UpdateFlash(target, data, id, r, g, b)
end

-- temp aggro system for the slingshots
local function no_aggro(attacker, target)
    local targets_target = target.components.combat ~= nil and target.components.combat.target or nil
    return targets_target ~= nil and targets_target:IsValid() and targets_target ~= attacker and attacker:IsValid() and (GetTime() - target.components.combat.lastwasattackedbytargettime) < 4 and (targets_target.components.health ~= nil and not targets_target.components.health:IsDead())
end

local function ImpactFx(inst, attacker, target)
    if target ~= nil and target:IsValid() then
        local impactfx = SpawnPrefab(inst.ammo_def.impactfx)
        impactfx.Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function OnAttack(inst, attacker, target)
    if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() then
        if target:HasDebuff("wixiecurse_debuff") then
            inst.powerlevel = inst.powerlevel + 1
            target:PushEvent("wixiebite")
        end

        if inst.ammo_def ~= nil and inst.ammo_def.onhit ~= nil then
            inst.ammo_def.onhit(inst, attacker, target)
        end
		
        local weapon = attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil

        if inst.ammo_def ~= nil and inst.ammo_def.damage ~= nil then
            inst.finaldamage = (inst.ammo_def.damage * (1 + (inst.powerlevel / 2))) * (attacker.components.combat ~= nil and attacker.components.combat.externaldamagemultipliers:Get() or 1)

		
            if no_aggro(attacker, target) and target.components.combat ~= nil then
                target.components.combat:SetShouldAvoidAggro(attacker)
            end

            if target:HasTag("shadowcreature") or target.sg == nil or target.wixieammo_hitstuncd == nil and not (target.sg:HasStateTag("busy") or target.sg:HasStateTag("caninterrupt")) or target.sg:HasStateTag("frozen") then
                target.wixieammo_hitstuncd = target:DoTaskInTime(8, function()
                    if target.wixieammo_hitstuncd ~= nil then
                        target.wixieammo_hitstuncd:Cancel()
                    end

                    target.wixieammo_hitstuncd = nil
                end)

				target.components.combat:GetAttacked(weapon ~= nil and attacker or inst, inst.planar_ammo and 0 or inst.finaldamage, weapon, nil, {planar = inst.planar_ammo and inst.finaldamage or 0})
            else
                target.components.combat:GetAttacked(weapon ~= nil and attacker or inst, 0, weapon)

				if target.components.planarentity then
					if not inst.planar_ammo then
						inst.finaldamage = (math.sqrt(inst.finaldamage * 4 + 64) - 8) * 4
						target.components.planarentity:OnResistNonPlanarAttack(attacker)
					else
						target.components.planarentity:OnPlanarAttackUndefended(target)
					end
				end
			
                target.components.health:DoDelta(-inst.finaldamage, false, attacker, false, attacker, false)
            end
        end

        ImpactFx(inst, attacker, target)

        if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
            target.components.sleeper:WakeUp()
        end

        if target.components.combat ~= nil then
            target.components.combat:RemoveShouldAvoidAggro(attacker)
        end

        if attacker.components.combat ~= nil then
            attacker.components.combat:SetTarget(target)
        end
					
		if target.components.health ~= nil and target.components.health:IsDead() then
			attacker:PushEvent("killed", { victim = target, attacker = attacker })
		end
    end
end

local function OnPreHit(inst, attacker, target) target.components.combat.temp_disable_aggro = no_aggro(attacker, target) end

local function OnHit(inst, attacker, target)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        target.components.combat.temp_disable_aggro = false
    end
end

local function NoHoles(pt) return not TheWorld.Map:IsPointNearHole(pt) end

local function SpawnShadowTentacle(target, pt, starting_angle)
    local offset = FindWalkableOffset(pt, starting_angle, 1.25, 3, false, true, NoHoles)
    if offset ~= nil then
        local tentacle = SpawnPrefab("shadowtentacle")
        if tentacle ~= nil then
            tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
            tentacle.components.combat:SetTarget(target)

            tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_1")
            tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_2")
        end
    end
end

local function OnHit_Thulecite(inst, attacker, target)
    ImpactFx(inst, attacker, target)

    if target ~= nil and target:IsValid() then
        target:AddDebuff("wixiecurse_debuff", "wixiecurse_debuff", { powerlevel = inst.powerlevel })
    end

    inst:Remove()
end

local function onloadammo_ice(inst, data)
    if data ~= nil and data.slingshot then
        data.slingshot:AddTag("extinguisher")
    end
end

local function onunloadammo_ice(inst, data)
    if data ~= nil and data.slingshot then
        data.slingshot:RemoveTag("extinguisher")
    end
end

local FREEZE_CANT_TAGS = { "noclaustrophobia", "player", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function GenerateSpiralSpikes(inst, powerlevel)
    local spawnpoints = {}
    local source = inst
    local x, y, z = source.Transform:GetWorldPosition()
    local spacing = 12 / powerlevel -- 2.5
    local radius = powerlevel       -- 5
    local deltaradius = .2
    local angle = 2 * PI * math.random()
    local deltaanglemult = (inst.reversespikes and -2 or 2) * PI * spacing
    inst.reversespikes = not inst.reversespikes
    local delay = 0
    local deltadelay = 2 * FRAMES
    local num = powerlevel * 3 -- 15
    local map = TheWorld.Map
    for i = 1, num do
        local oldradius = radius
        radius = radius -- + deltaradius
        local circ = PI * (oldradius + radius)
        local deltaangle = deltaanglemult / circ
        angle = angle + deltaangle
        local x1 = x + radius * math.cos(angle)
        local z1 = z + radius * math.sin(angle)
        if map:IsPassableAtPoint(x1, 0, z1) then
            table.insert(spawnpoints, { t = delay, level = i / num, pts = { Vector3(x1, 0, z1) } })
            delay = delay + deltadelay
        end
    end
    return spawnpoints, source
end

local function DoSpawnSpikes(inst, pts, level)
    for i, v in ipairs(pts) do
        local spike = SpawnPrefab("icespike_fx_" .. math.random(4))
        spike.Transform:SetPosition(v:Get())
        spike.persists = false
    end
end

local function SpawnSpikes(inst, powerlevel)
    local spikes, source = GenerateSpiralSpikes(inst, powerlevel)
    if #spikes > 0 then
        for i, v in ipairs(spikes) do
            inst:DoTaskInTime(0, DoSpawnSpikes, v.pts, v.level)
        end
    end
end

local function DoFreeze(inst, target)
    local pos = Vector3(target.Transform:GetWorldPosition())

    local power = 1 + (inst.powerlevel * 2)
    local forloopvalue = power * 2

    SpawnSpikes(target, power)

    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, power, nil, FREEZE_CANT_TAGS)
    for i, v in pairs(ents) do
        if v ~= target and v.components.freezable ~= nil then
            v.components.freezable:AddColdness((TUNING.SLINGSHOT_AMMO_FREEZE_COLDNESS / 2) + inst.powerlevel / 2)
            v.components.freezable:SpawnShatterFX()
        end
    end
end

local function OnHit_Ice(inst, attacker, target)
    ImpactFx(inst, attacker, target)

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

    if target.components.freezable ~= nil then
        target.components.freezable:AddColdness((TUNING.SLINGSHOT_AMMO_FREEZE_COLDNESS / 2) + inst.powerlevel)
        target.components.freezable:SpawnShatterFX()
        DoFreeze(inst, target)
    else
        local fx = SpawnPrefab("shatter")
        fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        fx.components.shatterfx:SetLevel(2)
        DoFreeze(inst, target)
    end

    if not no_aggro(attacker, target) and target.components.combat ~= nil then
        target.components.combat:SetTarget(attacker)
    end

    inst:Remove()
end

local function OnHit_Vortex(inst, attacker, target)
    ImpactFx(inst, attacker, target)

    if target ~= nil and target:IsValid() then
        local vortex = SpawnPrefab("slingshot_vortex")
        vortex.Transform:SetPosition(target.Transform:GetWorldPosition())
        vortex.powerlevel = inst.powerlevel
    end

    inst:Remove()
end

local function OnHit_Distraction(inst, attacker, target)
    ImpactFx(inst, attacker, target)

    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        local targets_target = target.components.combat.target
        if targets_target == nil or targets_target == attacker then
            attacker._doesnotdrawaggro = true
            target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
            attacker._doesnotdrawaggro = nil

            if not target:HasTag("epic") and target.components.combat ~= nil then
                target.components.combat:DropTarget()
            end

            if target.components.hauntable ~= nil and target.components.hauntable.panicable then
                target.components.hauntable:Panic(4 * inst.powerlevel)
            end

            -- local stinkcloud = SpawnPrefab("wixie_stinkcloud")
            -- stinkcloud.Transform:SetPosition(target.Transform:GetWorldPosition())
            -- stinkcloud.components.timer:StartTimer("disperse", 10 * inst.powerlevel)
        end
    end

    inst:Remove()
end

local AURA_EXCLUDE_TAGS = { "noclaustrophobia", "rabbit", "playerghost", "abigail", "companion", "ghost", "shadow", "shadowminion", "noauradamage", "INLIMBO", "notarget", "noattack", "invisible" }

if not TheNet:GetPVPEnabled() then
    table.insert(AURA_EXCLUDE_TAGS, "player")
end

local function OnHit_Marble(inst, attacker, target)
    -- ImpactFx(inst, attacker, target)

    if target ~= nil and target:IsValid() and target.components and target.components.locomotor and not target:HasTag("stageusher") and not target:HasTag("toadstool") then
		WixieShove(attacker, target, inst.powerlevel, false, nil, true, false)
    end

    inst:Remove()
end

local function OnHit_Melty(inst, attacker, target)
    local x, y, z = inst.Transform:GetWorldPosition()

    for i = 1, 3 do
        local marble = SpawnPrefab("slipperymarblesproj")
        marble.Transform:SetPosition(x, 2, z)
        marble.type = math.random(4)
        local targetpos = inst:GetPosition()

        targetpos.x = targetpos.x + math.random(-4, 4)
        targetpos.z = targetpos.z + math.random(-4, 4)

        local dx = targetpos.x - x
        local dz = targetpos.z - z
        local rangesq = dx * dx + dz * dz

        local maxrange = TUNING.FIRE_DETECTOR_RANGE
        local speed = easing.linear(rangesq, maxrange, 5, maxrange * maxrange)
        marble.components.complexprojectile:SetHorizontalSpeed(15)
        marble.components.complexprojectile:SetGravity(-35)
        marble.components.complexprojectile:SetLaunchOffset(Vector3(0, .25, 0))
        marble.components.complexprojectile.usehigharc = true
        marble.components.complexprojectile:Launch(targetpos, inst, inst)
    end

    inst:Remove()
end

local function OnHit_Gold(inst, attacker, target)
    if target ~= nil and target:IsValid() and target.components and target.components.locomotor then
        local x, y, z = target.Transform:GetWorldPosition()
        local goldshatter = SpawnPrefab("slingshotammo_goldshatter")
        goldshatter.Transform:SetPosition(target.Transform:GetWorldPosition())
        goldshatter.AnimState:PlayAnimation("level" .. inst.powerlevel)

        local ents = TheSim:FindEntities(x, y, z, 1.5 + inst.powerlevel, { "_combat" }, AURA_EXCLUDE_TAGS)
        local damage = (inst.ammo_def.damage * (1 + (inst.powerlevel / 2))) * (attacker.components.combat ~= nil and attacker.components.combat.externaldamagemultipliers:Get() or 1)
		
        for i, v in ipairs(ents) do
            if v ~= target and v:IsValid() and not v:IsInLimbo() and (v:HasTag("bird_mutant") or not v:HasTag("bird")) then
                if not (v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")) then
                    if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
                        if no_aggro(attacker, v) then
                            v.components.combat:SetShouldAvoidAggro(attacker)
                        end
		
						local weapon = attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil

						v.components.combat:GetAttacked(weapon ~= nil and attacker or inst, inst.planar_ammo and 0 or damage, weapon, nil, {planar = inst.planar_ammo and damage or 0})

                        if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
                            v.components.sleeper:WakeUp()
                        end

                        if v.components.combat ~= nil then
                            v.components.combat:RemoveShouldAvoidAggro(attacker)
                        end
						
						if v.components.health ~= nil and v.components.health:IsDead() then
							attacker:PushEvent("killed", { victim = v, attacker = attacker })
						end
                    end
                end
            end
        end
    end
end

local DREADSTONE_TAGS = { "dreadstoneammo" }
local DREADSTONE_NOTAGS = { "INLIMBO" }

local function FindStackableDreadstoneAmmo(inst, radius)
	local x, y, z = inst.Transform:GetWorldPosition()
	local num = inst.components.stackable:StackSize()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, DREADSTONE_TAGS, DREADSTONE_NOTAGS)) do
		if v ~= inst and v.components.inventoryitem.is_landed and v.components.stackable:RoomLeft() >= num then
			return v
		end
	end
end

local function OnLanded2_Dreadstone(inst) --this is the inv item
	inst:RemoveEventCallback("on_landed", OnLanded2_Dreadstone)

	local other = FindStackableDreadstoneAmmo(inst, 0.25)
	if other then
		other.components.stackable:Put(inst)
	end
end

local function OnLanded_Dreadstone(inst) --this is the inv item
	inst:RemoveEventCallback("on_landed", OnLanded_Dreadstone)

	local other = FindStackableDreadstoneAmmo(inst, 0.5)
	if other then
		local vx, vy, vz = inst.Physics:GetVelocity()
		other.components.stackable:Put(inst)
		if vx ~= 0 or vz ~= 0 then
			local speed = math.sqrt(vx * vx + vz * vz)
			local dir = math.atan2(vz, -vx) * DEGREES
			Launch2(other, other, speed * 0.5, 0.1, 0, 0, 3, dir - 10 + math.random() * 20)
			other.components.inventoryitem:SetLanded(false, true)
			other:ListenForEvent("on_landed", OnLanded2_Dreadstone)
		end
	end
end

local function OnHit_Dreadstone(inst, attacker, target)
	if target and target:IsValid() then
		StartFlash(inst, target, 1, 0, 0)
		if math.random() < TUNING.SLINGSHOT_AMMO_DREADSTONE_RECOVER_CHANCE then
			local ammo = SpawnPrefab("slingshotammo_dreadstone")
			LaunchAt(ammo, target, attacker and attacker:IsValid() and attacker or nil, 1, 1, target:GetPhysicsRadius(0), 40)
			ammo.components.inventoryitem:SetLanded(false, true)
			ammo:ListenForEvent("on_landed", OnLanded_Dreadstone)
		end
		
		if target.components and target.components.locomotor and not target:HasTag("stageusher") and not target:HasTag("toadstool") then
			WixieShove(attacker, target, inst.powerlevel, false, nil, true, false)
		end
	end
end

local function SetVoidBonus_Dreadstone(inst)
	inst.components.weapon:SetDamage(inst.components.weapon.damage * TUNING.WEAPONS_VOIDCLOTH_SETBONUS_DAMAGE_MULT)
	inst.components.planardamage:AddBonus(inst, TUNING.WEAPONS_VOIDCLOTH_SETBONUS_PLANAR_DAMAGE, "setbonus")
end

local function OnHit_Gunpowder(inst, attacker, target)
	local x, y, z = target.Transform:GetWorldPosition()
	
	local fx = SpawnPrefab("slingshotammo_gunpowder_explode")

	if fx ~= nil then
		fx.Transform:SetPosition(x, y, z)
		fx.Transform:SetScale(inst.powerlevel, inst.powerlevel, inst.powerlevel)
	end

	for i, v in ipairs(AllPlayers) do
		local distSq = v:GetDistanceSqToInst(target)
		local k = math.max(0, math.min(1, distSq / 400))
		local intensity = k * 0.75 * (k - 2) + 0.75
		if intensity > 0 then
			v:ShakeCamera(CAMERASHAKE.FULL, 1.05, .03, intensity / 2)
		end
	end

	local ents = TheSim:FindEntities(x, y, z, TUNING.SLINGSHOT_AMMO_RANGE_GUNPOWDER_DUST_AOE + inst.powerlevel, { "_combat" }, AURA_EXCLUDE_TAGS)
	local damage = (inst.ammo_def.damage * (1 + (inst.powerlevel / 2))) * (attacker.components.combat ~= nil and attacker.components.combat.externaldamagemultipliers:Get() or 1)
		
	for i, v in ipairs(ents) do
		if v ~= target and v:IsValid() and not v:IsInLimbo() and (v:HasTag("bird_mutant") or not v:HasTag("bird")) then
			if not (v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")) then
				if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
					if no_aggro(attacker, v) then
						v.components.combat:SetShouldAvoidAggro(attacker)
					end
					
					local distsq = v ~= nil and x ~= nil and v:GetDistanceSqToPoint(x, y, z) or 1
					WixieShove(target, v, 2, false, distsq)
		
					local weapon = attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil

					v.components.combat:GetAttacked(weapon ~= nil and attacker or inst, inst.planar_ammo and 0 or damage, weapon, nil, {planar = inst.planar_ammo and damage or 0})

					if v.components.sleeper ~= nil and v.components.sleeper:IsAsleep() then
						v.components.sleeper:WakeUp()
					end

					if v.components.combat ~= nil then
						v.components.combat:RemoveShouldAvoidAggro(attacker)
					end
						
					if v.components.health ~= nil and v.components.health:IsDead() then
						attacker:PushEvent("killed", { victim = v, attacker = attacker })
					end
				end
			end
		end
	end
end

local function OnLaunch_Gunpowder(inst, owner, target, attacker)
    inst.SoundEmitter:PlaySound("meta5/walter/ammo_gunpowder_shoot")
end

local function DoHit_PureBrilliance(inst, attacker, target, skipaggro)
    if not (target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid()) then
        return
    end
	
	if target:HasDebuff("wixiecurse_debuff") then
		inst.powerlevel = inst.powerlevel + 1
		target:PushEvent("wixiebite")
	end
	
	target:AddDebuff("ammo_purebrilliance_mark", "slingshotammo_purebrilliance_debuff")
end

local function OnHit_PureBrilliance(inst, attacker, target)
	if target and target:IsValid() then
		StartFlash(inst, target, 1, 1, 1)

		if not (target.components.health and target.components.health:IsDead()) then
			DoHit_PureBrilliance(inst, attacker, target, true)
		end
	end
end

local function CommonPostInit_PureBrilliance(inst)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSymbolLightOverride("pb_energy_loop", .5)
    inst.AnimState:SetSymbolLightOverride("pb_ray", .5)
    inst.AnimState:SetSymbolLightOverride("SparkleBit", .5)
    inst.AnimState:SetLightOverride(.1)
end

--------------------------------------------------------------------------

local function NoHoles_LunarPlantHusk(pt)
	return TheWorld and not TheWorld.Map:IsPointNearHole(pt)
end

local function OnHit_LunarPlantHusk(inst, attacker, target)
    if not (target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid()) then
        return
    end
	
	if target:HasDebuff("wixiecurse_debuff") then
		inst.powerlevel = inst.powerlevel + 1
		target:PushEvent("wixiebite")
	end
	
	StartFlash(inst, target, 1, 1, 1)

	for i = 1, inst.powerlevel + inst.powerlevel - 1 do
		local pt = target:GetPosition()
		local offset = FindWalkableOffset(pt, TWOPI * math.random(), 2, 3, false, true, NoHoles_LunarPlantHusk, false, true)
		if offset then
			local tentacle = SpawnPrefab("lunarplanttentacle")
			tentacle.owner = attacker
			tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
			tentacle.components.combat:SetTarget(target)
			tentacle.sg:GoToState("quickattack")
		end
	end
end

local function NoHoles_GelBlobTentacle(pt)
	return TheWorld and not TheWorld.Map:IsPointNearHole(pt)
end

local function OnHit_GelBlob(inst, attacker, target)
    if not (target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid()) then
        return
    end
	
	if target:HasDebuff("wixiecurse_debuff") then
		inst.powerlevel = inst.powerlevel + 1
		target:PushEvent("wixiebite")
	end
	
	StartFlash(inst, target, 1, 1, 1)

	for i = 1, inst.powerlevel + inst.powerlevel - 1 do
		local pt = target:GetPosition()
		local offset = FindWalkableOffset(pt, TWOPI * math.random(), 2, 3, false, true, NoHoles_GelBlobTentacle, false, true)
		if offset then
			local tentacle = SpawnPrefab("shadowtentacle")
			if tentacle ~= nil then
				tentacle.owner = attacker
				tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
				tentacle.components.combat:SetTarget(target)
				tentacle.sg:GoToState("quickattack")

				tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_1")
				tentacle.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shadowTentacleAttack_2")
			end
		end
	end
end

local function InvMasterPostInit_Gelblob(inst)
    MakeCraftingMaterialRecycler(inst, { gelblob_bottle = "messagebottleempty" })
end

local NUM_HORROR_VARIATIONS = 6
local MAX_HORRORS = 4
local HORROR_PERIOD = 1
local INITIAL_RND_PERIOD = 0.35

local function RecycleHorrorDebuffFX(fx, pool)
	fx:RemoveFromScene()
	table.insert(pool, fx)
end

local function OnUpdate_HorrorFuel(target, attacker, data, endtime, first)
	if not (target.components.health and target.components.health:IsDead()) and
		target.components.combat and target.components.combat:CanBeAttacked()
	then
		local rnd = math.random(math.clamp(NUM_HORROR_VARIATIONS - #data.tasks, 2, NUM_HORROR_VARIATIONS / 2))
		local variation = data.variations[rnd]
		for i = rnd, NUM_HORROR_VARIATIONS - 1 do
			data.variations[i] = data.variations[i + 1]
		end
		data.variations[NUM_HORROR_VARIATIONS] = variation

		local fx
		if #data.pool > 0 then
			fx = table.remove(data.pool)
			fx:ReturnToScene()
		else
			fx = SpawnPrefab("slingshotammo_horrorfuel_debuff_fx")
			fx.pool = data.pool
			fx.onrecyclefn = RecycleHorrorDebuffFX
		end
		fx.entity:SetParent(target.entity)
		fx:Restart(attacker, target, variation, data.pool, first)
	end

	if GetTime() >= endtime then
		table.remove(data.tasks, 1):Cancel()
		if #data.tasks <= 0 then
			for i, v in ipairs(data.pool) do
				v:Remove()
			end
			target._slingshot_horror = nil
		end
	end
end

local function DoHit_HorrorFuel(inst, attacker, target, instant)
    if not (target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid()) then
        return
    end
	
	if target:HasDebuff("wixiecurse_debuff") then
		inst.powerlevel = inst.powerlevel + 1
		target:PushEvent("wixiebite")
	end
	
	StartFlash(inst, target, 1, 0, 0)
	local data = target._slingshot_horror
	if data == nil then
		data = { tasks = {}, variations = {}, pool = {} }
		for i = 1, NUM_HORROR_VARIATIONS do
			table.insert(data.variations, math.random(i), i)
		end
		target._slingshot_horror = data
	elseif #data.tasks >= MAX_HORRORS then
		table.remove(data.tasks, 1):Cancel()
	end

	local numticks = inst.voidbonusenabled and TUNING.SLINGSHOT_HORROR_SETBONUS_TICKS or TUNING.SLINGSHOT_HORROR_TICKS
	local endtime = GetTime() + HORROR_PERIOD * (numticks - 1) - 0.001
	if instant then
		table.insert(data.tasks, target:DoPeriodicTask(HORROR_PERIOD, OnUpdate_HorrorFuel, nil, attacker, data, endtime))
		OnUpdate_HorrorFuel(target, attacker, data, endtime, true)
	else
		local initialdelay = math.random() * INITIAL_RND_PERIOD
		endtime = endtime + initialdelay
		table.insert(data.tasks, target:DoPeriodicTask(HORROR_PERIOD, OnUpdate_HorrorFuel, initialdelay, attacker, data, endtime))
	end
end

local function OnHit_HorrorFuel(inst, attacker, target)
	if target and target:IsValid() then
		DoHit_HorrorFuel(inst, attacker, target, true)
	end
end

local function SetVoidBonus_HorrorFuel(inst)
	inst.voidbonusenabled = true
	inst.components.weapon:SetDamage(inst.components.weapon.damage * TUNING.WEAPONS_VOIDCLOTH_SETBONUS_DAMAGE_MULT)
	inst.components.planardamage:AddBonus(inst, TUNING.WEAPONS_VOIDCLOTH_SETBONUS_PLANAR_DAMAGE, "setbonus")
end

local _horror_player = nil
local _horror_AWAKELIST = {}

local function _horror_CalcTargetLightOverride(player)
	if player then
		local sanity = player.replica.sanity
		if sanity and sanity:IsInsanityMode() then
			local k = sanity:GetPercent()
			if k < 0.6 then
				k = 1 - k / 0.6
				return k * k
			end
		end
	end
	return 0
end

local function _horror_UpdateLightOverride(inst, instant)
	inst.targetlight = _horror_CalcTargetLightOverride(_horror_player)
	inst.currentlight = instant and inst.targetlight or inst.targetlight * 0.1 + inst.currentlight * 0.9
	inst.AnimState:SetLightOverride(inst.currentlight)
end

local function _horror_OnSanityDelta(player, data)
	if data and not data.overtime then
		for k in pairs(_horror_AWAKELIST) do
			_horror_UpdateLightOverride(k, true)
		end
	end
end

local function _horror_OnRemovePlayer(player)
	_horror_player = nil
end

local function _horror_StopWatchingPlayerSanity(world)
	if _horror_player then
		world:RemoveEventCallback("sanitydelta", _horror_OnSanityDelta, _horror_player)
		world:RemoveEventCallback("onremove", _horror_OnRemovePlayer, _horror_player)
		_horror_player = nil
	end
end

local function _horror_WatchPlayerSanity(world, player)
	world:ListenForEvent("sanitydelta", _horror_OnSanityDelta, player)
	world:ListenForEvent("onremove", _horror_OnRemovePlayer, player)
	_horror_player = player
end

local function _horror_OnPlayerActivated(world, player)
	if _horror_player ~= player then
		_horror_StopWatchingPlayerSanity(world)
		_horror_WatchPlayerSanity(world, player)
		for k in pairs(AWAKELIST) do
			_horror_UpdateLightOverride(k, true)
		end
	end
end

local function OnEntityWake_HorrorFuel(inst)
	if not _horror_AWAKELIST[inst] then
		if next(_horror_AWAKELIST) == nil then
			if _horror_player ~= ThePlayer then
				_horror_StopWatchingPlayerSanity(TheWorld)
				_horror_WatchPlayerSanity(TheWorld, ThePlayer)
			end
			TheWorld:ListenForEvent("playeractivated", _horror_OnPlayerActivated)
		end
		_horror_AWAKELIST[inst] = true
		inst._horror_task = inst:DoPeriodicTask(1, _horror_UpdateLightOverride, math.random())
		_horror_UpdateLightOverride(inst, true)
	end
end

local function OnEntitySleep_HorrorFuel(inst)
	if _horror_AWAKELIST[inst] then
		_horror_AWAKELIST[inst] = nil
		if next(_horror_AWAKELIST) == nil then
			_horror_StopWatchingPlayerSanity(TheWorld)
			TheWorld:RemoveEventCallback("playeractivated", _horror_OnPlayerActivated)
		end
		inst._horror_task:Cancel()
		inst._horror_task = nil
	end
end


local function OnHit_Scrapfeather(inst, attacker, target)
    if not (target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid()) then
        return
    end
	
	if target:HasDebuff("wixiecurse_debuff") then
		inst.powerlevel = inst.powerlevel + 1
		target:PushEvent("wixiebite")
	end

    if not (
        target:HasTag("electricdamageimmune") or
        (target.components.inventory ~= nil and target.components.inventory:IsInsulated())
    ) and
        target:GetIsWet()
    then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
    end

    if target ~= nil and target:IsValid() then
        target:AddDebuff("wixie_shockscrap_debuff", "wixie_shockscrap_debuff", { powerlevel = inst.powerlevel })
    end
end

local function CommonPostInit_Scrapfeather(inst)
	inst.AnimState:SetSymbolBloom("electricity")
    inst.AnimState:SetSymbolLightOverride("electricity", .3)
    inst.AnimState:SetSymbolMultColour("electricity", 255 / 255, 255 / 255, 175 / 255, 1)
end

local function ProjMasterPostInit_Scrapfeather(inst, attacker, target)
    inst.components.weapon:SetElectric(1, TUNING.SLINGSHOT_AMMO_SCRAPFEATHER_WET_DAMAGE_MULT)
end

local function OnHit_Stinger(inst, attacker, target)
    if target ~= nil then
        if target:HasDebuff("wixiecurse_debuff") then
            inst.powerlevel = inst.powerlevel + 1
            target:PushEvent("wixiebite")
        end
		
        if target.SoundEmitter ~= nil then
            target.SoundEmitter:PlaySound("dontstarve/bee/bee_attack")
        else
			inst.SoundEmitter:PlaySound(inst.sounds.attack)
            inst.SoundEmitter:PlaySound("dontstarve/bee/bee_attack")
        end
		
		target:AddDebuff("wixie_stinger_debuff", "wixie_stinger_debuff")
    end

    inst:Remove()
end

local function CreateFX_HorrorFuel()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	--inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("slingshotammo")
	inst.AnimState:SetBuild("slingshotammo")
	inst.AnimState:PlayAnimation("idle_horrorfuel", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
	inst.AnimState:SetFinalOffset(1)

	inst.currentlight = 0
	inst.targetlight = 0
	inst.OnEntityWake = OnEntityWake_HorrorFuel
	inst.OnEntitySleep = OnEntitySleep_HorrorFuel
	inst.OnRemoveEntity = OnEntitySleep_HorrorFuel

	return inst
end

local function CollisionCheck(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local attacker = inst.components.projectile.owner or nil

    for i, v in ipairs(TheSim:FindEntities(x, y, z, 3, { "_combat" }, AURA_EXCLUDE_TAGS)) do
        if v:GetPhysicsRadius(0) > 1.5 and v:IsValid() and v.components.combat ~= nil and v.components.health ~= nil and not (v.sg ~= nil and (v.sg:HasStateTag("swimming") or v.sg:HasStateTag("invisible"))) and (v:HasTag("bird_mutant") or not v:HasTag("bird")) then
            if not (v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")) then
                if not (v.components.health:IsDead() or v == attacker or v:HasTag("playerghost") or (v:HasTag("player") and not TheNet:GetPVPEnabled())) then
                    OnAttack(inst, attacker, v)
                    inst:Remove()
                    return
                end
            end
        end
    end

    for i, v in ipairs(TheSim:FindEntities(x, y, z, 2, { "_combat" }, AURA_EXCLUDE_TAGS)) do
        if v:IsValid() and v.components.combat ~= nil and v.components.health ~= nil and not (v.sg ~= nil and (v.sg:HasStateTag("swimming") or v.sg:HasStateTag("invisible"))) and (v:HasTag("bird_mutant") or not v:HasTag("bird")) then
            if not (v.components.follower ~= nil and v.components.follower:GetLeader() ~= nil and v.components.follower:GetLeader():HasTag("player")) then
                if not (v.components.health:IsDead() or v == attacker or v:HasTag("playerghost") or (v:HasTag("player") and not TheNet:GetPVPEnabled())) then
                    OnAttack(inst, attacker, v)
                    inst:Remove()
                    return
                end
            end
        end
    end
end

local function projectile_fn(ammo_def)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(10)
    inst.Physics:SetDamping(5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:SetCapsule(0.85, 0.85)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("slingshotammo")
    inst.AnimState:SetBuild("slingshotammo")
    inst.AnimState:PlayAnimation("spin_loop", true)
    if ammo_def.symbol ~= nil then
        inst.AnimState:OverrideSymbol("rock", "slingshotammo", ammo_def.symbol)
    end

    -- projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")
    inst:AddTag("scarytoprey")

    if ammo_def.tags then
        for _, tag in pairs(ammo_def.tags) do
            inst:AddTag(tag)
        end
    end

	--inst.REQUIRED_SKILL = ammo_def.skill

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.planar_ammo = ammo_def.isplanarammo or nil

    inst.ammo_def = ammo_def

    if inst.powerlevel == nil then
        inst.powerlevel = 1
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(ammo_def.damage)
    inst.components.weapon:SetOnAttack(nil --[[OnAttack]])

    inst.Physics:SetCollisionCallback(nil)

    inst:DoPeriodicTask(FRAMES, CollisionCheck)

    inst:AddComponent("locomotor")

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(20)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetOnPreHitFn(nil)
    inst.components.projectile:SetOnHitFn(nil)
    inst.components.projectile:SetOnMissFn(nil)
    inst.components.projectile:SetLaunchOffset(Vector3(1, 0.5, 0))

    inst:DoTaskInTime(2 - (inst.powerlevel * inst.powerlevel), inst.Remove)

    return inst
end

local ammo = {
    { name = "slingshotammo_rock",   damage = TUNING.SLINGSHOT_AMMO_DAMAGE_ROCKS, tags = { "wixieammo_basic" }, hit_sound = "dontstarve/characters/walter/slingshot/rock" },
    { name = "slingshotammo_gold",   symbol = "gold", onhit = OnHit_Gold, tags = { "wixieammo_basic" }, damage = TUNING.SLINGSHOT_AMMO_DAMAGE_GOLD,   hit_sound = "dontstarve/characters/walter/slingshot/gold" },
    { name = "slingshotammo_marble", symbol = "marble", onhit = OnHit_Marble, tags = { "wixieammo_basic" }, damage = TUNING.SLINGSHOT_AMMO_DAMAGE_MARBLE, hit_sound = "dontstarve/characters/walter/slingshot/marble" },
    {
        name = "slingshotammo_thulecite", -- chance to spawn a Shadow Tentacle
        symbol = "thulecite",
        onhit = OnHit_Thulecite,
		tags = { "wixieammo_special" },
        damage = TUNING.SLINGSHOT_AMMO_DAMAGE_THULECITE,
        hit_sound = "dontstarve/characters/walter/slingshot/gold"
    },
    { name = "slingshotammo_freeze", symbol = "freeze", onhit = OnHit_Ice,    tags = { "extinguisher", "wixieammo_special" }, onloadammo = onloadammo_ice, onunloadammo = onunloadammo_ice, damage = TUNING.SLINGSHOT_AMMO_DAMAGE_GOLD, hit_sound = "dontstarve/characters/walter/slingshot/frozen" },
    { name = "slingshotammo_slow",   symbol = "slow",   onhit = OnHit_Vortex, tags = { "wixieammo_special" }, damage = TUNING.SLINGSHOT_AMMO_DAMAGE_GOLD, hit_sound = "dontstarve/characters/walter/slingshot/slow" },
    {
        name = "slingshotammo_poop", -- distraction (drop target, note: hostile creatures will probably retarget you very shortly after)
        symbol = "poop",
        onhit = OnHit_Distraction,
		tags = { "wixieammo_basic" },
        damage = nil,
        hit_sound = "dontstarve/characters/walter/slingshot/poop",
        fuelvalue = TUNING.MED_FUEL / 10 -- 1/10th the value of using poop
    },
	-- NEW SKILLTREE SLINGSHOT AMMO

    {
        name = "slingshotammo_dreadstone",
		symbol = "dreadstone",
		inv_common_postinit = function(inst)
			inst:AddTag("dreadstoneammo")
		end,
		onhit = OnHit_Dreadstone,
		tags = { "wixieammo_special" },
		damage = TUNING.SLINGSHOT_AMMO_DAMAGE_DREADSTONE,
		planar = TUNING.SLINGSHOT_AMMO_PLANAR_DREADSTONE,
		damagetypebonus = { ["lunar_aligned"] = TUNING.SLINGSHOT_AMMO_VS_LUNAR_BONUS },
		setvoidbonus = SetVoidBonus_Dreadstone,
		--skill = "walter_slingshot_ammo_dreadstone",
		elemental = true,
    },
    {
        name = "slingshotammo_gunpowder",
		symbol = "gunpowder",
        onlaunch = OnLaunch_Gunpowder,
        onhit = OnHit_Gunpowder,
        damage = TUNING.SLINGSHOT_AMMO_DAMAGE_GUNPOWDER,
		--skill = "walter_slingshot_ammo_gunpowder",
		prefabs = { "slingshotammo_gunpowder_explode" },
    },
	{
        name = "slingshotammo_lunarplanthusk",
		symbol = "lunarplanthusk",
		onhit = OnHit_LunarPlantHusk,
		tags = { "wixieammo_special" },
		damage = TUNING.SLINGSHOT_AMMO_DAMAGE_LUNARPLANTHUSK,
		planar = TUNING.SLINGSHOT_AMMO_PLANAR_LUNARPLANTHUSK,
		damagetypebonus = { ["shadow_aligned"] = TUNING.SLINGSHOT_AMMO_VS_SHADOW_BONUS },
		isplanarammo = true,
		--skill = "walter_allegiance_lunar",
		prefabs = { "lunarplanttentacle" },
    },
    {
		name = "slingshotammo_purebrilliance",
		symbol = "purebrilliance",
		idleanim = "idle_purebrilliance",
		idlelooping = true,
		inv_common_postinit = CommonPostInit_PureBrilliance,
		proj_common_postinit = CommonPostInit_PureBrilliance,
		onhit = OnHit_PureBrilliance,
		tags = { "wixieammo_special" },
		damage = TUNING.SLINGSHOT_AMMO_DAMAGE_PUREBLILLIANCE,
		planar = TUNING.SLINGSHOT_AMMO_PLANAR_PUREBLILLIANCE,
		damagetypebonus = { ["shadow_aligned"] = TUNING.SLINGSHOT_AMMO_VS_SHADOW_BONUS },
		isplanarammo = true,
		--skill = "walter_allegiance_lunar",
		prefabs = { "slingshotammo_purebrilliance_debuff", "slingshot_aoe_fx" },
    },
    {
        name = "slingshotammo_horrorfuel",
		symbol = "horrorfuel",
		idleanim = "idle_horrorfuel_rock",
		spinloop = "spin_loop_horrorfuel",
		spinloopmounted = "spin_loop_mount_horrorfuel",
		spinsymbol = "horrofuel_stone",
		inv_common_postinit = function(inst)
			if not TheNet:IsDedicated() then
				inst.fx = CreateFX_HorrorFuel()
				inst.fx.entity:SetParent(inst.entity)
				inst.highlightchildren = { inst.fx }
			end
		end,
		proj_common_postinit = function(inst)
			inst.AnimState:SetSymbolLightOverride("horrorfuel", 1)
		end,
		onhit = OnHit_HorrorFuel,
		tags = { "wixieammo_special" },
		damage = TUNING.SLINGSHOT_AMMO_DAMAGE_HORRORFUEL,
		planar = TUNING.SLINGSHOT_AMMO_PLANAR_HORRORFUEL,
		damagetypebonus = { ["lunar_aligned"] = TUNING.SLINGSHOT_AMMO_VS_LUNAR_BONUS },
		isplanarammo = true,
		setvoidbonus = SetVoidBonus_HorrorFuel,
		--skill = "walter_allegiance_shadow",
		prefabs = { "slingshotammo_horrorfuel_debuff_fx", "slingshot_aoe_fx" },
    },
	{
		name = "slingshotammo_gelblob",
		symbol = "gelblob",
		onhit = OnHit_GelBlob,
		tags = { "wixieammo_special" },
		damage = TUNING.SLINGSHOT_AMMO_DAMAGE_LUNARPLANTHUSK,
		planar = TUNING.SLINGSHOT_AMMO_PLANAR_LUNARPLANTHUSK,
		damagetypebonus = { ["shadow_aligned"] = TUNING.SLINGSHOT_AMMO_VS_LUNAR_BONUS },
		isplanarammo = true,
        inv_master_postinit = InvMasterPostInit_Gelblob,
		setvoidbonus = SetVoidBonus_HorrorFuel,
		--skill = "walter_allegiance_shadow",
	},
    {
        name = "slingshotammo_scrapfeather",
		symbol = "scrapfeather",
		idleanim = "idle_scrapfeather",
		idlelooping = true,
		spinloop = "spin_loop_scrapfeather",
		spinloopmounted = "spin_loop_mount_scrapfeather",
		spinsymbol = "scrapfeather",
        onhit = OnHit_Scrapfeather,
		tags = { "wixieammo_special" },
		inv_common_postinit = CommonPostInit_Scrapfeather,
		proj_common_postinit = CommonPostInit_Scrapfeather,
        proj_master_postinit = ProjMasterPostInit_Scrapfeather,
        damage = TUNING.SLINGSHOT_AMMO_DAMAGE_SCRAPFEATHER,
		--skill = "walter_slingshot_ammo_scrapfeather",
    },
	{
        name = "slingshotammo_stinger",
		symbol = "stinger",
        onhit = OnHit_Stinger,
		tags = { "wixieammo_basic" },
        damage = TUNING.SLINGSHOT_AMMO_DAMAGE_ROCKS,
		--skill = "walter_slingshot_ammo_stinger",
    },
    { name = "trinket_1", no_inv_item = true, symbol = "trinket_1", onhit = OnHit_Melty, damage = TUNING.SLINGSHOT_AMMO_DAMAGE_TRINKET_1, hit_sound = "dontstarve/characters/walter/slingshot/trinket" }
}

local ammo_prefabs = {}
for _, v in ipairs(ammo) do
    v.impactfx = "slingshotammo_hitfx_" .. (v.symbol or "rock")

    local prefabs = { "shatter" }
    table.insert(prefabs, v.impactfx)
    table.insert(ammo_prefabs, Prefab(v.name .. "_proj_secondary", function() return projectile_fn(v) end, assets, prefabs))
end

return unpack(ammo_prefabs)
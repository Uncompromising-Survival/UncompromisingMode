local function beak_retreat(beak_inst)
    -- Try to spawn a boat leak at our location.
    local beak_pt = beak_inst:GetPosition()
    local boat = beak_inst:GetCurrentPlatform()
    if boat then
		boat:PushEvent("spawnnewboatleak", {pt = beak_pt, leak_size = "med_leak", playsoundfx = true})
    end

    beak_inst:Remove()
end

local function OnBeakHit(beak_inst)
    if not beak_inst.components.health:IsDead() and not beak_inst:HasTag("leaving") and not beak_inst:HasTag("attacking") then
        beak_inst.AnimState:PlayAnimation("hit")
    end
end

local function beakAttack_AnimOver(beak_inst)
    beak_retreat(beak_inst, false, "med_leak")
end

local function EndbeakAttack(beak_inst)
	beak_inst:AddTag("leaving") -- Prevent screeching from happening during the leaving sequence
    beak_inst.AnimState:PlayAnimation("leave", false)
    beak_inst:ListenForEvent("animqueueover", beakAttack_AnimOver)

    local boat = beak_inst:GetCurrentPlatform()
	if boat then
		beak_inst:DoTaskInTime(7*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
		beak_inst:DoTaskInTime(14*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.damage) end)
		beak_inst:DoTaskInTime(16*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
		beak_inst:DoTaskInTime(19*FRAMES, function(i) i.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/jump_small") end)
		beak_inst:DoTaskInTime(25*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
	end
    beak_inst._beak_attack_ending = true
    beak_inst:RemoveEventCallback("attacked", OnBeakHit)
end

local function beakBroken_AnimOver(beak_inst)
    beak_retreat(beak_inst, true, "small_leak")
end

local function beakBrokenWide_AnimOver(beak_inst)
    beak_retreat(beak_inst, true, "med_leak")
end

local function OnAttackBeakKilled(beak_inst)
	beak_inst.AnimState:PlayAnimation("killed")
	if beak_inst.ocupus then
		beak_inst.ocupus.beakkilled = true
	end
	beak_inst:ListenForEvent("animover",function(beak_inst)
		local boat = beak_inst:GetCurrentPlatform()
		if boat then
			boat:PushEvent("spawnnewboatleak", {pt = beak_inst:GetPosition(), leak_size = "med_leak", playsoundfx = true})
		end	
		beak_inst:Remove() 
	end)
end



local function isnotocupus(ent)
	if ent ~= nil and not ent:HasTag("ocupus") then -- fix to friendly AOE: refer for later AOE mobs -Axe
		return true
	end
end


local function AfterScreech(inst)
	inst:RemoveTag("attacking")
	inst:DoTaskInTime(inst.screechmod*math.random(5,8),function(inst)
		inst.Screeeeeeech(inst) 
	end)
end

local function DoTheScreechening(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x,y,z,4,{"_health","player"},{"playerghost"})
	for i,v in ipairs(players) do
		if v and v.components.inventory and not (v.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) and v.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab and v.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD).prefab == "earmuffshat") then
			v.sg:GoToState("soundstun")
		end
	end
end

local function YellRing(inst)
	local ring = SpawnPrefab("groundpoundring_fx")
	local x1,y1,z1 = inst.Transform:GetWorldPosition()

	ring.Transform:SetPosition(x1, y1, z1)
	ring.Transform:SetScale(0.55, 0.55, 0.55)
end

local function Screeeeeeech(inst) --Visually do the screech as well as show the ring
	if not inst:HasTag("leaving") then
		inst:AddTag("attacking")
		inst.AnimState:PlayAnimation("screech_pre",false)
		inst.AnimState:PushAnimation("screech",false)
		inst.AnimState:PushAnimation("idle",true)
		inst:DoTaskInTime(1.4,YellRing)
		inst:DoTaskInTime(1.3,YellRing)
		inst:DoTaskInTime(1.5,YellRing)
		inst:DoTaskInTime(1.4,DoTheScreechening)
		inst:DoTaskInTime(4,AfterScreech)
	end
end

local function Leave(inst)
	if inst.surface then
		Dive(inst)
	else
		inst.AnimState:PlayAnimation("dissappear")
		inst:ListenForEvent("animover",function(inst) --Maybe update the core, not sure
			inst.core.beak = nil
			inst:Remove() 
		end)
	end
end


local function AppearanceStuff(beak_inst) -- Do this stuff once the beak appears!
	local boat = beak_inst:GetCurrentPlatform()
	if boat then
		beak_inst.AnimState:PlayAnimation("appear", false)
		beak_inst.AnimState:PushAnimation("idle", true)
		beak_inst:DoTaskInTime(7*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
		beak_inst:DoTaskInTime(14*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.damage) end)
		beak_inst:DoTaskInTime(16*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
		beak_inst:DoTaskInTime(19*FRAMES, function(i) i.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/jump_small") end)
		beak_inst:DoTaskInTime(25*FRAMES, function(i) i.SoundEmitter:PlaySound(boat.sounds.thunk) end)
		beak_inst:DoTaskInTime(beak_inst.screechmod * math.random(5,10),Screeeeeeech)
	else
		beak_inst:Remove()
	end
end

local function teleport_override_fn(beak_inst)
	beak_inst:Remove() --Teleporting will remove the beak for a second
end

local function WatchBoatState(beak_inst)
	local boat = beak_inst:GetCurrentPlatform()
	if boat then
		local x,y,z = boat.Transform:GetWorldPosition()
		local players = FindPlayersInRangeSq(x, y, z, 4^2, true)
		if players and #players > 0 then
			if boat.components.health:IsDead() then
				beak_inst.retract(beak_inst)
			end
		else
			if not beak_inst.components.health:IsDead() and not beak_inst:HasTag("leaving") and not beak_inst:HasTag("attacking") then
				beak_inst.AnimState:PlayAnimation("bang")
				beak_inst.AnimState:PushAnimation("idle",true)
				beak_inst:DoTaskInTime(0.5,function(beak_inst)
					local boat = beak_inst:GetCurrentPlatform()
					if boat and boat.components.health and not boat.components.health:IsDead() then
						YellRing(beak_inst)
						boat.components.health:DoDelta(-60)
						if boat.components.health:IsDead() then
							beak_inst.retract(beak_inst)
						end
					end
				end)
			end
		end
	else
		beak_inst.retract(beak_inst)
	end
end

local function fn()
    local beak_inst = CreateEntity()

    beak_inst.entity:AddTransform()
    beak_inst.entity:AddAnimState()
    beak_inst.entity:AddSoundEmitter()
    beak_inst.entity:AddNetwork()

    beak_inst.AnimState:SetBank("um_ocupus_beak")
    beak_inst.AnimState:SetBuild("ocupus")

    beak_inst:AddTag("ocupus")
    beak_inst:AddTag("hostile")
    beak_inst:AddTag("soulless")

    beak_inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return beak_inst
    end

    beak_inst:AddComponent("combat")
    beak_inst:AddComponent("health")
    beak_inst.components.health:SetMaxHealth(2000)
    beak_inst.components.health.nofadeout = true

    beak_inst:ListenForEvent("death", OnAttackBeakKilled)
    beak_inst:ListenForEvent("attacked", OnBeakHit)

    beak_inst:AddComponent("inspectable")


    beak_inst:AddComponent("hauntable")
    beak_inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
	beak_inst.screechmod = 1 -- The ocupus can screech faster if needed...
	beak_inst.Transform:SetScale(1.2,1.2,1.2) --Scale er up a bit... beak looks a bit small
	beak_inst:DoTaskInTime(0,AppearanceStuff)
    beak_inst._beak_attack_ending = false
	beak_inst.Screeeeeeech = Screeeeeeech
	beak_inst.retract = EndbeakAttack
	beak_inst:DoPeriodicTask(3,WatchBoatState)
    return beak_inst
end

return Prefab("um_ocupus_beak",fn)


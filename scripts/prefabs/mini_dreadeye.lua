local assets =
{
	Asset("ANIM", "anim/shadow_eye.zip")
}


local AURA_EXCLUDE_TAGS = { "noauradamage", "INLIMBO", "notarget", "noattack" }

local NOTAGS = { "playerghost", "INLIMBO" }

local function TryFear(inst, v)
	local x, y, z = inst.Transform:GetWorldPosition()
	local vx, vy, vz = v.Transform:GetWorldPosition()
	
	if v.components.sanity ~= nil then
		if v.components.sanity:IsInsane() and v.components.health ~= nil then	
			--v.components.health:DoDelta(-1)
		elseif v.components.sanity:IsSane() then
			--v.components.sanity:DoDelta(-2)
		end
		
		local proj = SpawnPrefab("mini_dreadeye_fuel")
		proj.Transform:SetPosition(vx, vy, vz)
		proj.components.projectile:Throw(v, inst, v)
		
		local debuffkey = inst.prefab
		
		if v ~= nil and v:IsValid() and v.components.locomotor ~= nil then
			if v._slingshot_speedmulttask ~= nil then
				v._slingshot_speedmulttask:Cancel()
			end
			v._slingshot_speedmulttask = v:DoTaskInTime(2.1, function(i) i.components.locomotor:RemoveExternalSpeedMultiplier(i, debuffkey) i._slingshot_speedmulttask = nil end)

			v.components.locomotor:SetExternalSpeedMultiplier(v, debuffkey, TUNING.SLINGSHOT_AMMO_MOVESPEED_MULT)
		end
	end
end

local function DoAreaFear(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, { "player" }, { "playerghost"})
	
	if not inst.AnimState:IsCurrentAnimation("spawn") then
		if ents ~= nil and #ents >= 1 then
			if not inst.despawning then
				if not inst.AnimState:IsCurrentAnimation("unburrow") and not inst.AnimState:IsCurrentAnimation("idle_out") then
					inst.AnimState:PlayAnimation("unburrow")
					inst.AnimState:PushAnimation("idle_out", true)
				end
			
				--SpawnPrefab("mini_dreadeye_fx").Transform:SetPosition(x, y + 1, z)
				
				for i, v in ipairs(ents) do
					TryFear(inst, v)
				end
			end
		else
			if not inst.despawning and inst.AnimState:IsCurrentAnimation("burrow") and not inst.AnimState:IsCurrentAnimation("idle") then
				inst.AnimState:PlayAnimation("burrow")
				inst.AnimState:PushAnimation("idle", true)
			end
		end
	end
end

local function changeidle(inst)
	if inst.AnimState:IsCurrentAnimation("despawn") then
		inst:Remove()
	end
end

local function CancelCreepingSound(inst)
	inst.SoundEmitter:KillSound("creeping")
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
    local s  = 1.65
    inst.Transform:SetScale(s, s, s)
			
	inst.AnimState:SetBuild("shadow_eye")
	inst.AnimState:SetBank("shadow_eye")
	inst.AnimState:PlayAnimation("spawn")
	inst.AnimState:PushAnimation("idle")
	
	inst.AnimState:SetMultColour(0, 0, 0, 0.5)
	
	inst:AddTag("shadow_eye")
    inst:AddTag("shadowcreature")
	inst:AddTag("gestaltnoloot")
    inst:AddTag("monster")
    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")

    --inst:AddComponent("transparentonsanity_dreadeye")
    if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity:ForceUpdate()
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	
	inst.despawning = false
	
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_creep", "creeping")
	inst:DoTaskInTime(1.5, CancelCreepingSound)
	
	
	inst:AddComponent("aura")
    inst.components.aura.radius = 10
    inst.components.aura.tickperiod = TUNING.TOADSTOOL_SPORECLOUD_TICK * 2
    inst.components.aura.auraexcludetags = AURA_EXCLUDE_TAGS
    inst.components.aura:Enable(true)
    inst._coldtask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaFear, inst.components.aura.tickperiod)

	inst:AddComponent("combat")
	
    inst:AddComponent("health")
    inst.components.health.nofadeout = true
    inst.components.health:SetMaxHealth(TUNING.DSTU.MINI_DREADEYE_HEALTH)
	
	inst:ListenForEvent("death", function(inst)
		inst.despawning = true
		
		if inst.AnimState:IsCurrentAnimation("idle_out") then
			inst.AnimState:PlayAnimation("burrow")
		end
			
		inst.AnimState:PushAnimation("despawn", false)
			
		inst:DoTaskInTime(1.5, inst.Remove)
	end)

	inst:DoTaskInTime(10, function(inst)
		if not inst.despawning then
			inst.despawning = true
		
			if inst.AnimState:IsCurrentAnimation("idle_out") then
				inst.AnimState:PlayAnimation("burrow")
			end
			
			inst.AnimState:PushAnimation("despawn", false)
			
			inst:DoTaskInTime(1.5, inst.Remove)
		end
	end)
	
    inst.persists = false
	
	return inst
end

local function fxfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
			
	inst.AnimState:SetBuild("statue_ruins_fx")
	inst.AnimState:SetBank("statue_ruins_fx")
	inst.AnimState:PlayAnimation("transform_nightmare")
	
	inst.AnimState:SetMultColour(0, 0, 0, 0.6)
	
	inst:AddTag("fx")

    if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity:ForceUpdate()
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
        return inst
    end
	
    inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
	
    inst.persists = false
	
	inst:ListenForEvent("animover", inst.Remove)
	
	return inst
end

return Prefab("mini_dreadeye", fn, assets, prefabs),
		Prefab("mini_dreadeye_fx", fxfn, assets, prefabs)
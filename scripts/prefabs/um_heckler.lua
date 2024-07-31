local assets =
{
    Asset("ANIM", "anim/bishop.zip"),
}

local prefabs =
{
    "gears",
    "bishop_charge",
    "purplegem",
}

--local brain = require"brains/um_hecklerbrain"
local brain = require"brains/shadow_wixie"

local sounds =
{
    attack = "UCSounds/um_heckler/hawk",
    attack_grunt = "UCSounds/um_heckler/spit",
    death = "UCSounds/um_heckler/death",
    idle = "dontstarve/sanity/creature1/idle",
    taunt = "UCSounds/um_heckler/taunt",
    appear = "UCSounds/um_heckler/appear",
    disappear = "UCSounds/um_heckler/attacked",
}

local function Retarget(inst)
	local target = 
	FindEntity(
				inst,
                30,
                function(guy)
                    return inst.components.combat:CanTarget(guy)
                end,
                { "player" },
                { "playerghost" }
            )
        or FindEntity(
				inst,
                45,
                function(guy)
                    return inst.components.combat:CanTarget(guy) and not guy:IsInLight()
                end,
                { "player" },
                { "playerghost" }
            )
        or nil
	
	return target
end

local easing = require("easing")

local function LaunchProjectile(inst)
    local target = inst.components.combat.target
	if target ~= nil then
		local targetfocus = target
		local ix, iy, iz = inst.Transform:GetWorldPosition()
		for i = 1, 4 do 
			local delay = (i - 1) / 20
		
			--local px, py, pz = targetfocus.Transform:GetWorldPosition()
			local targetpos = targetfocus:GetPosition()
			inst:DoTaskInTime(delay, function()
				if targetfocus ~= nil then
					--local px, py, pz = targetfocus.Transform:GetWorldPosition()
					local rad = math.rad(inst:GetAngleToPoint(targetpos.x, 0, targetpos.z))
					local velx = math.cos(rad) * 4.5
					local velz = -math.sin(rad) * 4.5
				
					--local dx, dy, dz = ix + (i * velx), 0, iz + (i * velz)
					targetpos.x = ix + (i * velx)
					targetpos.z = iz + (i * velz)
					
					
					local dx = targetpos.x - ix
					local dz = targetpos.z - iz
					local rangesq = dx * dx + dz * dz
					local maxrange = TUNING.FIRE_DETECTOR_RANGE + 5
					local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
					
					
					local projectile = SpawnPrefab("heckler_goo")
					projectile.Transform:SetPosition(ix, iy, iz)
					
					projectile.components.complexprojectile:SetLaunchOffset(Vector3(4, 3, 0))
					projectile.components.complexprojectile:SetHorizontalSpeed(speed)
					projectile.components.complexprojectile:SetGravity(-35)
					projectile.components.complexprojectile:Launch(targetpos, inst, inst)
					
					--[[
					local maxrange = 40
					local bigNum = 30
					local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange * 2)
					
					
					local projectile = SpawnPrefab("guardian_goo")
					projectile.Transform:SetPosition(ix, iy, iz)
					
					projectile.components.complexprojectile:SetLaunchOffset(Vector3(5, 4, 0))
					projectile.components.complexprojectile:SetHorizontalSpeed(speed)
					projectile.components.complexprojectile:SetGravity(-65)
					projectile.components.complexprojectile:Launch(targetpos, inst, inst)]]
				end
			end)
		
		--[[
			local x, y, z = inst.Transform:GetWorldPosition()
			local projectile = SpawnPrefab("guardian_goo")
			projectile.Transform:SetPosition(x, y, z)
			local a, b, c = target.Transform:GetWorldPosition()
			local targetpos = target:GetPosition()
			targetpos.x = targetpos.x + math.random(-3, 3)
			targetpos.z = targetpos.z + math.random(-3, 3)
			local dx = a - x
			local dz = c - z
			local rangesq = dx * dx + dz * dz
			local maxrange = 20
			local bigNum = 15
			local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange * 2)
			projectile:AddTag("canthit")


			projectile.components.complexprojectile:SetLaunchOffset(Vector3(5, 4, 0))
			--projectile.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS/2
			projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
			projectile.components.complexprojectile:SetGravity(-65)
			projectile.components.complexprojectile:Launch(targetpos, inst, inst)
			projectile:Show()]]
		end
	end
	
	--[[
	--for i = 1, 4 do 
		if target ~= nil then
	
			local x, y, z = inst.Transform:GetWorldPosition()
			local a, b, c = target.Transform:GetWorldPosition()
			local projectile = SpawnPrefab("heckler_goo")
			projectile.Transform:SetPosition(x, y, z)
			local targetpos = target:GetPosition()
			
			local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(targetpos.x, 0, targetpos.z)
	
			targetpos.x = tx
			targetpos.z = ty
			
			local dx = a - x
			local dz = c - z
			local rangesq = dx * dx + dz * dz
			local maxrange = 20
			local bigNum = 15
			local speed = easing.linear(rangesq, bigNum, 3, maxrange * maxrange * 2)
			projectile:AddTag("canthit")


			projectile.components.complexprojectile:SetLaunchOffset(Vector3(4, 3, 0))
			--projectile.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS/2
			projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
			projectile.components.complexprojectile:SetGravity(-65)
			projectile.components.complexprojectile:Launch(targetpos, inst, inst)
			projectile:Show()
		end
	--end]]
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 0.9)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	--inst.Physics:CollidesWith(COLLISION.WORLD)
	
    inst.Transform:SetTwoFaced()
	
    inst.AnimState:SetBank("um_heckler")
    inst.AnimState:SetBuild("um_heckler")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)
	inst.AnimState:UsePointFiltering(true)
	
	inst.Transform:SetScale(0.4, 0.4, 0.4)
	
	inst:AddTag("monster")
    inst:AddTag("hostile")   
    inst:AddTag("swilson") 
	inst:AddTag("nightmarecreature")
	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
	inst:AddTag("notraptrigger")
	inst:AddTag("um_shadow_leech")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst.sounds = sounds

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.BISHOP_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.BISHOP_WALK_SPEED + 2
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

    inst:SetStateGraph("SGum_heckler")
    inst:SetBrain(brain)

    inst:AddComponent("combat")
    inst.components.combat:SetAttackPeriod(TUNING.BISHOP_ATTACK_PERIOD * 1.5)
    inst.components.combat:SetRange(TUNING.BISHOP_ATTACK_DIST * 2)
    inst.components.combat:SetRetargetFunction(3, Retarget)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)

    --inst:AddComponent("um_shadowcloaked")

    inst:AddComponent("inspectable")
	
    inst.LaunchProjectile = LaunchProjectile
	
    return inst
end

return Prefab("um_heckler", fn, assets, prefabs)
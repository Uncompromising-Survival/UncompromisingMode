local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function RechargeSpitfireAttack(inst)
	inst.spitfireready = true
	inst.components.combat:SetRange(6,3)
		
	-- Original Range variables from combat
	-- attackrange = 3
    -- hitrange = 3
end

local ARC = 90 * DEGREES --degrees to each side
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "notarget", "noattack"}
local function PoofNearby(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation() * DEGREES
    local x0, z0
	local radius = 4
    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, nil, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and v:IsValid() and not v:IsInLimbo()
            and not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z
            local distsq = dx * dx + dz * dz
            if distsq > 0 and distsq < range * range and DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC then
				if v.components.burnable then
					v.components.burnable:Ignite()
				end
				if v.components.health then
					v.components.health:DoFireDamage(10,nil,true)
				end
			end
        end
    end
end

local function SetUpFire(inst,degrand,speed,scale,damage)
	local x,y,z = inst.Transform:GetWorldPosition()
	local projectile = SpawnPrefab("um_fire_projectile")
	local rot = inst.Transform:GetRotation() 
	local dx = 1*math.sin((rot+ 90+degrand) * DEGREES)
	local dz = 1*math.cos((rot+ 90+degrand) * DEGREES)
	rot = rot + math.random(-20,20)
	projectile.Transform:SetPosition(x + dx,1,z+dz)
	projectile.Transform:SetRotation(rot)
	projectile.speed = speed
	projectile.scale = scale -- scale up sometimes.
	projectile.damage = damage
end

local function ShootFireMagmaHound(inst,total_flame) --AXE obviously called by magmahound to perform its continuous fire breath attack
	for i = 1,total_flame do
		inst:DoTaskInTime(0+math.random(1,15)*FRAMES,function(inst)
			SetUpFire(inst,5,20,1 + math.random(0,10)/100,2)
			PoofNearby(inst)
		end)
	end
end

local function ShootFire(inst) --AXE this one is called by fire hound for its short-range spitfire attack
	SetUpFire(inst,0,16,1 + math.random(0,10)/100,2)
end

local function FirePoof(inst) --AXE Visual support for when the fire hound is briefly charging the spitfire attack
	local x,y,z = inst.Transform:GetWorldPosition()
	local x1 = x + 0.05*math.random(-10, 10)
	local z1 = z + 0.05*math.random(-10, 10)
	local y1 = 0 + .25 * math.random()
	SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(x1, y1, z1)
	SpawnPrefab("magmafire").Transform:SetPosition(x1, 0, z1)
end


local function OnHitOtherBurn(inst, data)
    local other = data.target
    local burntarget = other.components.rideable and other.components.rideable:GetRider() or other
    if burntarget and not (burntarget.components.health and burntarget.components.health:IsDead()) and burntarget.components.burnable then
        burntarget.components.burnable:Ignite(true, inst, inst)
		FirePoof(burntarget)
    end
end

env.AddPrefabPostInit("firehound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if TUNING.DSTU.FIREBITEHOUNDS then
        if inst.components.combat then
            inst:ListenForEvent("onhitother", OnHitOtherBurn)
        end
    end
	inst:AddComponent("timer")
	inst:ListenForEvent("timerdone",RechargeSpitfireAttack)
	
	if not inst.spitfireready then -- If spawned, just give a small gap till it's time to spit again.
		inst:DoTaskInTime(math.random(4,8),RechargeSpitfireAttack)
	end
	inst.ShootFire = ShootFire
	inst.components.health.fire_damage_scale = 0 --AXE Fire hounds are Immune to the damage from fire as well as not burnable
	inst.FirePoof = FirePoof
	SetSharedLootTable('hound_fire',
	{
		{'monstermeat', 1.0},
		{'houndstooth', 1.0},
		{'redgem',      0.3},
	})


end)

env.AddPrefabPostInit("magmahound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.combat then
        inst:ListenForEvent("onhitother", OnHitOtherBurn)
    end
	inst.ShootFire = ShootFireMagmaHound
end)

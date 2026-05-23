local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function RechargeIceSpikeAttack(inst)
	inst.icespikeready = true
	inst.components.combat:SetRange(6,3)
		
	-- Original Range variables from combat
	-- attackrange = 3
    -- hitrange = 3
end

local function IceSpike(inst,target) --AXE Code from atoba's glacial hound, but tuned.
    local x, y, z = inst.Transform:GetWorldPosition()
    local numspikes = inst:HasTag("ice_shielded") and 12 or 6 --AXE Leaving this part of the code in, for when they do obtain an ice shield as well.
    if not target then -- Last-chance regrab the target.
	    target = inst.components.combat and inst.components.combat.target and inst.components.combat.target
    end
	if target then --AXE if no target, then just fakeout the attack.
        local target_pos = target:GetPosition()
		local angle = inst:GetAngleToPoint(target_pos)
		local rad = math.rad(angle)
		local speed = inst:HasTag("ice_shielded") and 15 or 25 --AXE Same.

		for i = 0, numspikes, 2 do
			inst:DoTaskInTime(i / speed, function(inst)
				if target == nil then
					return
				end

				local x1 = x + i * math.cos(rad) + math.random(-1, 1) / 5
				local z1 = z + i * -math.sin(rad) + math.random(-1, 1) / 5

				if #TheSim:FindEntities(x1, y, z1, 1, nil, nil, { "groundspike", "hound" }) >= 1 or not TheWorld.Map:IsVisualGroundAtPoint(x1, y, z1) then
					return
				end

				local spike = SpawnPrefab("glacialhound_icespike")

				spike.owner = inst
				spike.Transform:SetRotation(rad)
				spike.Transform:SetPosition(x1, y, z1)

				local size = Lerp(1.0, 0.75, i / numspikes)
				spike.Transform:SetScale(size, size, size)
			end)
		end
	end
end

local function SnowFX(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local x1 = x + math.random(-1, 1)
    local z1 = z + math.random(-1, 1)
    local y1 = 0 + 0.1 * math.random()

    local flakes = SpawnPrefab("deer_ice_flakes")
    flakes.AnimState:PlayAnimation("idle")
    flakes.Transform:SetPosition(x1, y1, z1)
    flakes:DoTaskInTime(1, flakes.Remove)
end

local function OnHitOtherFreeze(inst, data)
    local other = data.target
    if other and not (other.components.health and other.components.health:IsDead()) then
        if other.components.freezable and not other.components.freezable:IsFrozen() then
            other.components.freezable:AddColdness(2)
            other.components.freezable:SpawnShatterFX()
        end
        if other.components.temperature then
            local mintemp = math.max(other.components.temperature.mintemp, 0)
            local curtemp = other.components.temperature:GetCurrent()
            if mintemp < curtemp then
                other.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
            end                    
        end
    end
end

local function IsAlly(inst, guy)
    return UMCommonFns.IsAlly(inst, guy, {"hound", "houndfriend"})
end

env.AddPrefabPostInit("icehound", function(inst)
    if not TheWorld.ismastersim then return end
    if TUNING.DSTU.FROSTBITEHOUNDS then
        inst:ListenForEvent("onhitother", OnHitOtherFreeze)
    end

    inst.UMIsAlly = IsAlly

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone",RechargeIceSpikeAttack)
    
    if not inst.icespikeready then --AXE If spawned, just give a small gap till it's time to spike again.
        inst:DoTaskInTime(math.random(4,8),RechargeIceSpikeAttack)
    end
    inst.IceSpike = IceSpike
    inst.SnowFX = SnowFX
    SetSharedLootTable('hound_cold',
    {
        {'monstermeat', 1.0},
        {'houndstooth', 1.0},
        {'bluegem',      0.3},
    })
end)
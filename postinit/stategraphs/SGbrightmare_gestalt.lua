local env = env
GLOBAL.setfenv(1, GLOBAL)

local function FindBestAttackTarget(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local closestPlayer = nil
	local rangesq = TUNING.GESTALT_ATTACK_HIT_RANGE_SQ
    for i, v in ipairs(AllPlayers) do
        if not IsEntityDeadOrGhost(v) and
			not (v.sg:HasStateTag("knockout") or v.sg:HasStateTag("sleeping") or v.sg:HasStateTag("bedroll") or v.sg:HasStateTag("tent") or v.sg:HasStateTag("waking")) and
            v.entity:IsVisible() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestPlayer = v
            end
        end
    end
    return closestPlayer
end


local function GestaltHungrySleep(target)
	if target.components.grogginess and target.components.grogginess:IsKnockedOut() and target.components.hunger then
		target.components.hunger:DoDelta(-12.5)
		local fx = SpawnPrefab("abigail_gestalt_hit_fx")
		fx.Transform:SetPosition(target.Transform:GetWorldPosition())
		fx.Transform:SetScale(0.4,0.4,0.4)
	else
		target.gestalt_hungry_sleep:Cancel()
		target.gestalt_hungry_sleep = nil
	end
end

local function HasSkill(inst,name)
	return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function DoSpecialAttack(inst, target)
	if target.components.sanity then
		target.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY)
	end
	if target.components.hunger then -- additional hunger lost per hit
		target.components.hunger:DoDelta(-12.5)
	end
	if HasSkill(target,"wathom_allegiance_shadow") and target.components.health then
		target.components.health:DeltaPenalty(1/6)
	end
	
	local grogginess = target.components.grogginess
	if grogginess ~= nil then
		grogginess:AddGrogginess(TUNING.GESTALT_ATTACK_DAMAGE_GROGGINESS, TUNING.GESTALT_ATTACK_DAMAGE_KO_TIME)
		if grogginess.knockoutduration == 0 then
			target:PushEvent("attacked", {attacker = inst, damage = 0})
		else
			-- TODO: turn on special hud overlay while asleep in enlightened dream land
		end
	else
		target:PushEvent("attacked", {attacker = inst, damage = 0})
	end
	target:DoTaskInTime(2,function(target)
		if target.components.grogginess and target.components.grogginess:IsKnockedOut() and not target.gestalt_hungry_sleep then
			target.gestalt_hungry_sleep = target:DoPeriodicTask(2,GestaltHungrySleep)
		end
	end)
end


env.AddStategraphPostInit("gestalt", function(inst)

	inst.states["attack"].onupdate = function(inst)
			if inst.sg.statemem.enable_attack then
				local target = FindBestAttackTarget(inst)
				if target ~= nil then
					DoSpecialAttack(inst, target)
					inst.sg.statemem.attack_landed = true
					inst.components.combat:DropTarget()
					inst.sg:GoToState("mutate_pre")
				end
			end
        end

end)


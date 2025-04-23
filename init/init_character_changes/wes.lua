local wes_must_live = {
	shadowcreature = true,
	player = true,
	companion = true,
	structure = true,
	wall = true,
}

AddPrefabPostInitAny(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end

	for tag in pairs(wes_must_live) do
		if inst:HasTag(tag) then
			return
		end
	end

	if inst.components and inst.components.combat then
		local damage = inst.components.combat.defaultdamage and inst.components.combat.defaultdamage > 0
		local target = inst.components.combat.targetfn or inst.components.combat.keeptargetfn
		local state = inst.sg ~= nil and inst.sg:HasState("attack")

		if damage or target or state then
			inst:AddTag("wesmustdie")
		end
	end
end)

local they_must_die = {
	player = true,
	companion = true,
	structure = true,
	wall = true,
}

local function IgnoreMe(entity, taglist)
	for tag in pairs(taglist) do
		if entity:HasTag(tag) then
			return true
		end
	end
	return false
end

local they_love_me = {
	buzzard = true,
	tentacle = true,
	eyeplant = true,
	mosquito = true,
	gestalt = true,
	um_pawn = true,
	shadowtentacle = true,
}

local hate = 16
local love = 4

local function HatefulBountyOnYourHead(inst)
	if inst == nil or inst.Transform == nil or not inst:HasTag("vetcurse") then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local targets = TheSim:FindEntities(x, y, z, hate, {"wesmustdie"}, {"player", "INLIMBO"})

	for i, target in ipairs(targets) do
		if target ~= nil and
			target.components ~= nil and
			target.components.combat ~= nil and
			target.components.combat:CanTarget(inst) then

			local target_is_a_follower = false
			local leader = nil

			if target.components.follower ~= nil then
				leader = target.components.follower.leader
			end

			if leader ~= nil and (leader:HasTag("player") or leader:HasTag("bell")) then
				target_is_a_follower = true
			end

			local what_my_target_is_targeting = target.components.combat.target
			local they_die_not_me = what_my_target_is_targeting ~= nil and IgnoreMe(what_my_target_is_targeting, they_must_die)

			local my_target_is_targeting_followers = false
			if what_my_target_is_targeting ~= nil and
				what_my_target_is_targeting.components ~= nil and
				what_my_target_is_targeting.components.follower ~= nil then
				local him = what_my_target_is_targeting.components.follower.leader
				if him ~= nil and
					(him:HasTag("player") or him:HasTag("bell")) then
					my_target_is_targeting_followers = true
				end
			end

			if not they_die_not_me and
				not my_target_is_targeting_followers and
				not target_is_a_follower then

				if target.prefab ~= nil and not they_love_me[target.prefab] then
					target.components.combat:SetTarget(inst)
				end
			end
		end
	end
end

local function LovableBountyOnYourHead(inst)
	if inst == nil or inst.Transform == nil or not inst:HasTag("vetcurse") then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local targets = TheSim:FindEntities(x, y, z, love, {"wesmustdie"}, {"player", "INLIMBO"})

	for i, target in ipairs(targets) do
		if target ~= nil and
			target.components ~= nil and
			target.components.combat ~= nil and
			target.components.combat:CanTarget(inst) then

			local target_is_a_follower = false
			local leader = nil

			if target.components.follower ~= nil then
				leader = target.components.follower.leader
			end

			if leader ~= nil and (leader:HasTag("player") or leader:HasTag("bell")) then
				target_is_a_follower = true
			end

			local what_my_target_is_targeting = target.components.combat.target
			local they_die_not_me = what_my_target_is_targeting ~= nil and IgnoreMe(what_my_target_is_targeting, they_must_die)

			local my_target_is_targeting_followers = false
			if what_my_target_is_targeting ~= nil and
				what_my_target_is_targeting.components ~= nil and
				what_my_target_is_targeting.components.follower ~= nil then
				local him = what_my_target_is_targeting.components.follower.leader
				if him ~= nil and
					(him:HasTag("player") or him:HasTag("bell")) then
					my_target_is_targeting_followers = true
				end
			end

			if not they_die_not_me and
				not my_target_is_targeting_followers and
				not target_is_a_follower then

				if target.prefab ~= nil and they_love_me[target.prefab] then
					target.components.combat:SetTarget(inst)
				end
			end
		end
	end
end

AddPrefabPostInit("wes", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	inst:AddTag("the_mime")
	inst:DoPeriodicTask(0, HatefulBountyOnYourHead)
	inst:DoPeriodicTask(0, LovableBountyOnYourHead)
end)

AddPrefabPostInit("bat", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
	local _keeptargetfn = inst.components.combat.keeptargetfn

	local function KeepTarget(inst, target)
		if target:HasTag("the_mime") then
			return true
		else
			return _keeptargetfn(inst, target)
		end
	end

	inst.components.combat:SetKeepTargetFunction(KeepTarget)

	local _targetfn = inst.components.combat.targetfn

	local function Retarget(inst)
		if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("the_mime") then
			-- Don't retarget...
		else
			return _targetfn(inst)
		end
	end
	inst.components.combat:SetRetargetFunction(3, Retarget)
end)

AddPrefabPostInit("vampirebat", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
	local _keeptargetfn = inst.components.combat.keeptargetfn

	local function KeepTarget(inst, target)
		if target:HasTag("the_mime") then
			return true
		else
			return _keeptargetfn(inst, target)
		end
	end

	inst.components.combat:SetKeepTargetFunction(KeepTarget)

	local _targetfn = inst.components.combat.targetfn

	local function Retarget(inst)
		if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("the_mime") then
			-- Don't retarget...
		else
			return _targetfn(inst)
		end
	end
	inst.components.combat:SetRetargetFunction(3, Retarget)
end)

AddPrefabPostInit("mosquito", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end

	local function KeepTarget(inst, target)
		if target:HasTag("the_mime") and inst.components.combat.min_attack_period ~= 2 then
			inst.components.combat:SetAttackPeriod(2)
			return true
		elseif inst.components.combat.min_attack_period ~= TUNING.MOSQUITO_ATTACK_PERIOD then
			inst.components.combat:SetAttackPeriod(TUNING.MOSQUITO_ATTACK_PERIOD)
			return true
		else
			return true
		end
	end
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
end)

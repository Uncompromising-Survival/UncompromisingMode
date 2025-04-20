AddPrefabPostInitAny(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
    if inst.components and inst.components.combat then
        inst:AddTag("wesmustdie")
    end
end)

local LEAVE_HIM_BE = {
	player = true,
	playerghost = true,
	shadowcreature = true,
	structure = true,
	wall = true,
	bird = true,
	butterfly = true,
}

local NOT_ME = {
	player = true,
}

local function CanLeaveHimBe(entity, taglist)
    for tag in pairs(taglist) do
        if entity:HasTag(tag) then
            return true
        end
    end
    return false
end

local function LookAtHim(entity, taglist)
    for tag in pairs(taglist) do
        if entity:HasTag(tag) then
            return true
        end
    end
    return false
end

local SPECIAL_FELLOWS = {
	buzzard = true,
	tentacle = true,
	eyeplant = true,
	mosquito = true,
}

local CHAOS_RADIUS = 16
local SPECIAL_RADIUS = 4

local function BountyOnYourHead(inst)
    if inst == nil or not inst:HasTag("vetcurse") then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, CHAOS_RADIUS, {"wesmustdie"}, {"player", "INLIMBO"})
    for i, target in ipairs(targets) do
		if target ~= nil and target.components ~= nil and target.components.combat ~= nil and target.components.combat:CanTarget(inst) and not CanLeaveHimBe(target, LEAVE_HIM_BE) then
			local TARGET_IS_A_FOLLOWER = false
			if target.components.follower ~= nil then
				local THE_LEADER = target.components.follower.leader
				if THE_LEADER ~= nil and (THE_LEADER:HasTag("player") or THE_LEADER:HasTag("bell")) then
					TARGET_IS_A_FOLLOWER = true
				end
			end
			local WHAT_MY_TARGET_IS_TARGETING = target.components.combat.target
			local LOOK_AT_HIM_NOT_ME = WHAT_MY_TARGET_IS_TARGETING ~= nil and LookAtHim(WHAT_MY_TARGET_IS_TARGETING, NOT_ME)
			local TARGET_TARGETING_PLAYER_FOLLOWERS = false
			if WHAT_MY_TARGET_IS_TARGETING ~= nil and WHAT_MY_TARGET_IS_TARGETING.components ~= nil and WHAT_MY_TARGET_IS_TARGETING.components.follower ~= nil then
				local THE_MAN_OR_THE_WOMAN = WHAT_MY_TARGET_IS_TARGETING.components.follower.leader
				if THE_MAN_OR_THE_WOMAN ~= nil and (THE_MAN_OR_THE_WOMAN:HasTag("player") or THE_MAN_OR_THE_WOMAN:HasTag("bell")) then
					TARGET_TARGETING_PLAYER_FOLLOWERS = true
				end
			end
			if not LOOK_AT_HIM_NOT_ME and not TARGET_TARGETING_PLAYER_FOLLOWERS and not TARGET_IS_A_FOLLOWER then
				if not SPECIAL_FELLOWS[target.prefab] then
					target.components.combat:SetTarget(inst)
				end
			end
		end
    end
end

local function SpecialBountyOnYourHead(inst)
    if inst == nil or not inst:HasTag("vetcurse") then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, SPECIAL_RADIUS, {"wesmustdie"}, {"player", "INLIMBO"})
    for i, target in ipairs(targets) do
		if target ~= nil and target.components ~= nil and target.components.combat ~= nil and target.components.combat:CanTarget(inst) and not CanLeaveHimBe(target, LEAVE_HIM_BE) then
			local TARGET_IS_A_FOLLOWER = false
			if target.components.follower ~= nil then
				local THE_LEADER = target.components.follower.leader
				if THE_LEADER ~= nil and (THE_LEADER:HasTag("player") or THE_LEADER:HasTag("bell")) then
					TARGET_IS_A_FOLLOWER = true
				end
			end
			local WHAT_MY_TARGET_IS_TARGETING = target.components.combat.target
			local LOOK_AT_HIM_NOT_ME = WHAT_MY_TARGET_IS_TARGETING ~= nil and LookAtHim(WHAT_MY_TARGET_IS_TARGETING, NOT_ME)
			local TARGET_TARGETING_PLAYER_FOLLOWERS = false
			if WHAT_MY_TARGET_IS_TARGETING ~= nil and WHAT_MY_TARGET_IS_TARGETING.components ~= nil and WHAT_MY_TARGET_IS_TARGETING.components.follower ~= nil then
				local THE_MAN_OR_THE_WOMAN = WHAT_MY_TARGET_IS_TARGETING.components.follower.leader
				if THE_MAN_OR_THE_WOMAN ~= nil and (THE_MAN_OR_THE_WOMAN:HasTag("player") or THE_MAN_OR_THE_WOMAN:HasTag("bell")) then
					TARGET_TARGETING_PLAYER_FOLLOWERS = true
				end
			end
			if not LOOK_AT_HIM_NOT_ME and not TARGET_TARGETING_PLAYER_FOLLOWERS and not TARGET_IS_A_FOLLOWER then
				if SPECIAL_FELLOWS[target.prefab] then
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
	inst:DoPeriodicTask(0, BountyOnYourHead)	
	inst:DoPeriodicTask(0, SpecialBountyOnYourHead)
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
			return _keeptargetfn(inst,target)
		end
	end	
	
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	
	local _targetfn = inst.components.combat.targetfn
	
	local function Retarget(inst)
		if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("the_mime") then
			-- Dont retarget...
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
			return _keeptargetfn(inst,target)
		end
	end	
	
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	
	local _targetfn = inst.components.combat.targetfn
	
	local function Retarget(inst)
		if inst.components.combat and inst.components.combat.target and inst.components.combat.target:HasTag("the_mime") then
			-- Dont retarget...
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
			inst.components.combat:SetAttackPeriod(2) -- their problem is they just have a long attack CD... making them reset it to a diff value 
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

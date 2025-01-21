local FeatsOfStrength = Class(function(self, inst)
    self.inst = inst
end)

function FeatsOfStrength:CanAfford(cost)
	if self.inst == nil or cost == nil then
		return
	end
	local mightiness = self.inst.components.mightiness and self.inst.components.mightiness:GetCurrent()
	local hunger = self.inst.components.hunger:GetPercent() * TUNING.WOLFGANG_HUNGER
	local hunger_cost = (cost - mightiness)*TUNING.LUNAR_MIGHTY_HUNGER_TO_MIGHTINESS_RATIO
	local mighty_hunger = self.inst:HasTag("mighty_hunger") and self.inst:HasTag("mightiness_mighty")
	local hasCost = (mightiness >= cost) or (mighty_hunger and hunger >= hunger_cost)
	return hasCost, hunger_cost
end

function FeatsOfStrength:HandleCost(mightycost, hungercost, delay)
	if self.inst == nil or mightycost == nil or self.inst.components.mightiness == nil then
		return
	end
	self.inst.components.mightiness:DoDelta(-mightycost)
	if hungercost ~= nil and hungercost > 0 then
		if delay then
			self.inst:DoTaskInTime(delay, function(inst) inst.components.hunger:DoDelta(-hungercost) end)
		else
			self.inst.components.hunger:DoDelta(-hungercost)
		end
	end
end

function FeatsOfStrength:MightySwing(target)
	if target == nil or self.inst.components.mightiness == nil then
		return
	end

	local cost = 
		(self.inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_strikes_5") and TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_5_COST) or
		(self.inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_strikes_4") and TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_4_COST) or
		(self.inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_strikes_3") and TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_3_COST) or
		(self.inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_strikes_2") and TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_2_COST) or
		(self.inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_strikes_1") and TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_1_COST) or
		TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_BASE_COST

	local weapon = self.inst.components.combat:GetWeapon()
	local afford, hungerCost = self:CanAfford(cost)
	
	if afford then 
		local doubledplanar = false
		if weapon ~= nil and weapon.components.planardamage ~= nil then
			weapon.components.planardamage:AddMultiplier(self.inst, 4, "mighty_strikes")
			doubledplanar = true
		end
		if target.components.health ~= nil then
			self.inst.components.combat.externaldamagemultipliers:SetModifier("mighty_swing", 2) --removed as part of onhitother listener
			self.inst.components.combat:DoAttack(target)
			if self.inst:HasTag("shadow_strikes") then
				self.inst:IncreaseCombo(1, target)
			end
			if self.inst:HasTag("mighty_hunger") and target.components.freezable ~= nil then
				target.components.freezable:AddColdness(2)
			end
			if doubledplanar then
				weapon.components.planardamage:RemoveMultiplier(self.inst, "mighty_strikes")
			end
			if self.inst.player_classified ~= nil then
				self.inst.player_classified.playworkcritsound:push()
			end
			self:HandleCost(cost, hungerCost)
			
			self.inst:AddTag("mighty_strike_cooldown")
			self.inst:DoTaskInTime(TUNING.FEAT_OF_STRENGTH_MIGHTY_STRIKE_COOLDOWN, function(inst) inst:RemoveTag("mighty_strike_cooldown") end)
		end
	else
		self.inst.components.talker:Say(GetString(self.inst, "NEED_MORE_MIGHTINESS"))
		self.inst.components.combat:DoAttack(target)
	end
end

function FeatsOfStrength:MightyWork(target, tool, numworks)
	local basecost = 
	(self.inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_expert") and TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST_EXPERT) or
	(self.inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_4") and TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST_4) or
	(self.inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_3") and TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST_3) or
	(self.inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_2") and TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST_2) or
	(self.inst.components.skilltreeupdater:IsActivated("wolfgang_critwork_1") and TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST_1)	or
	TUNING.SKILLS.WOLFGANG_MIGHTY_WORK_COST
	
	local workleft = target.components.hackable and target.components.hackable:GetHacksLeft() or target.components.workable:GetWorkLeft()
	local work_action = target.components.hackable and ACTIONS.HACK or target.components.workable:GetWorkAction()
	local work_type_mult = TUNING.WOLFGANG_MIGHTY_WORK_COST_MULT[work_action.id]
	local cost = (basecost * workleft * work_type_mult) / numworks
	local golden = string.match(tool.prefab, "golden*")
	local uses = workleft/numworks
	local tough = target.components.workable ~= nil and target.components.workable.tough
	local tooltough = tool.components.tool ~= nil and tool.components.tool:CanDoToughWork()

	if golden then
		uses = uses / TUNING.GOLDENTOOLFACTOR
	end

	if tough and not tooltough then
		uses = uses * TUNING.HARD_MATERIAL_MULT
		cost = cost * 2
	end

	if workleft <= numworks then
		return
	end

	local canAfford, hungerCost = self:CanAfford(cost)

	if canAfford then
		if self.inst.player_classified ~= nil then
			self.inst.player_classified.playworkcritsound:push()
		end
		self:HandleCost(cost, hungerCost)
		if tool.components.finiteuses ~= nil then
			tool.components.finiteuses:Use(uses)
		end
		if self.inst:HasTag("shadow_strikes") then
			self.inst:IncreaseCombo(1, target)
		end
		return 99999
	end
end

function FeatsOfStrength:MightyLeap(act)
	local leapexpert = act.doer.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs_expert")
	local cost = 
		(leapexpert and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_EXPERT_COST) or
		(act.doer.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs_4") and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_4_COST) or
		(act.doer.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs_3") and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_3_COST) or
		(act.doer.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs_2") and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_2_COST) or
		(act.doer.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs") and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_1_COST) or
		TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_COST
	
	local afford, hungerCost = self:CanAfford(cost)

	if afford then
		act.doer:AddTag("mighty_leap_cooldown")
		act.doer:DoTaskInTime((leapexpert and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_EXPERT_COOLDOWN) or TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_COOLDOWN, function(inst) inst:RemoveTag("mighty_leap_cooldown") end)
		self:HandleCost(cost, hungerCost, 1.25)
		return true
	else
		act.doer.sg:GoToState("idle")
		return false
	end
end


local function HasFriendlyLeader(inst, target)
	local target_leader = (target.components.follower ~= nil) and target.components.follower.leader or nil
	
	if target_leader ~= nil then

		if target_leader.components.inventoryitem then
			target_leader = target_leader.components.inventoryitem:GetGrandOwner()
		end

		local PVP_enabled = TheNet:GetPVPEnabled()
		return (target_leader ~= nil 
				and (target_leader:HasTag("player") 
				and not PVP_enabled)) or
				(target.components.domesticatable and target.components.domesticatable:IsDomesticated() 
				and not PVP_enabled) or
				(target.components.saltlicker and target.components.saltlicker.salted
				and not PVP_enabled)
	end

	return false
end

local function CanDamage(inst, target)
	if target.components.minigame_participator ~= nil or target.components.combat == nil then
		return false
	end

	if target:HasTag("player") and not TheNet:GetPVPEnabled() then
		return false
	end

	if target:HasTag("playerghost") and not target:HasTag("INLIMBO") then
		return false
	end

	if target:HasTag("monster") and not TheNet:GetPVPEnabled() and 
	   ((target.components.follower and target.components.follower.leader ~= nil and 
		 target.components.follower.leader:HasTag("player")) or target.bedazzled) then
		return false
	end

	if HasFriendlyLeader(inst, target) then
		return false
	end

	return true
end

function FeatsOfStrength:MightyLeapLanding()
	local inst = self.inst

	local x,y,z = inst.Transform:GetWorldPosition()
	local AOE_ATTACK_MUST_TAGS = {"_combat", "_health"}
	local AOE_ATTACK_NO_TAGS = {"FX", "NOCLICK", "DECOR", "INLIMBO"}
	local isHeavyLifting = inst.components.inventory and inst.components.inventory:IsHeavyLifting()
	local range = (isHeavyLifting and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_AOE_RANGE_HEAVY) or TUNING.DEFAULT_ATTACK_RANGE
	local damage = (isHeavyLifting and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_DAMAGE_HEAVY) or
		(inst:HasTag("mightiness_mighty") and TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_DAMAGE_MIGHTY) or
		TUNING.FEAT_OF_STRENGTH_MIGHTY_LEAP_DAMAGE
	local ents = TheSim:FindEntities(x, y, z, range, AOE_ATTACK_MUST_TAGS, AOE_ATTACK_NO_TAGS)
	if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) then
		if isHeavyLifting then
			SpawnPrefab("groundpound_fx").Transform:SetPosition(x,y,z)
			local groundpound = SpawnPrefab("groundpoundring_fx")
			groundpound.Transform:SetScale(0.6, 0.6, 0.6)
			groundpound.Transform:SetPosition(x,y,z)
			inst:ShakeCamera(CAMERASHAKE.VERTICAL, 0.1, 0.03, 1)
		else
			SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(x,y-1,z)
			inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
			inst:ShakeCamera(CAMERASHAKE.VERTICAL, 0.1, 0.03, 1)
		end
		if inst.components.skilltreeupdater:IsActivated("wolfgang_mighty_legs") then
			for i, ent in ipairs(ents) do
				local canfreeze = inst:HasTag("mighty_hunger")
				if CanDamage(inst, ent) then
					ent.components.combat:GetAttacked(inst, damage)
					if canfreeze then
						if ent.components.freezable ~= nil then
							ent.components.freezable:AddColdness(1)
						end
					end
				end
			end
		end
	elseif inst:HasTag("mighty_hunger") and inst.components.drownable and inst.components.drownable:IsOverWater(x,y,z) then
		local iceboat = SpawnPrefab("boat_ice")
		iceboat.Transform:SetPosition(x,y-1,z)
		iceboat:DoTaskInTime(28, function(inst)
			SpawnPrefab("degrade_fx_ice").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst:Remove() 
		end)
		SpawnPrefab("degrade_fx_ice").Transform:SetPosition(x,y-1,z)
		inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_hit")
	end
	if inst:HasTag("shadow_strikes") then
		inst:IncreaseCombo(1)
	end
end

return FeatsOfStrength
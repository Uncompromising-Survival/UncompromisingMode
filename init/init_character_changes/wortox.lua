local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

if TUNING.DSTU.WORTOXCHANGES then
	AddPrefabPostInitAny(function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return inst
		end
		--if inst.components.health ~= nil and inst:HasTag("insect") and inst.components.health ~= nil and not inst.components.health:IsDead() and inst.components.health.maxhealth <= 100 then
		if inst:HasTag("butterfly") --[[or (not GetModConfigData("wortox_beesouls") and inst:HasTag("bee"))]] then
			inst:AddTag("soulless")
		end
	end)
	
	local function UncompromisingSoulHeal(inst)
		local healtargets = {}
		local healtargetscount = 0
		local sanitytargets = {}
		local sanitytargetscount = 0
		local x, y, z = inst.Transform:GetWorldPosition()
		local rangesq = TUNING.WORTOX_SOULHEAL_RANGE + (inst.soul_heal_range_modifier or 0)
		rangesq = rangesq * rangesq
		for i, v in ipairs(GLOBAL.AllPlayers) do
			if not (v.components.health:IsDead() or v:HasTag("playerghost")) and
				v.entity:IsVisible() and
				v:GetDistanceSqToPoint(x, y, z) < rangesq then
				-- NOTES(JBK): If the target is hurt put them on the list to do heals.
				if v.components.health:IsHurt() and not v:HasTag("health_as_oldage") or (inst.soul_heal_player_efficient and v.components.health.penalty and v.components.health.penalty > 0) then -- Wanda tag.
					table.insert(healtargets, v)
					healtargetscount = healtargetscount + 1
				end
				-- NOTES(JBK): If the target is another "soulstealer" give some sanity even when they did not drop the soul but not in overload state.
				if not inst.soul_bursting and v._souloverloadtask == nil and v.components.sanity and v:HasTag("soulstealer") then
					table.insert(sanitytargets, v)
					sanitytargetscount = sanitytargetscount + 1
				end
			end
		end
		if healtargetscount > 0 then
			-- Healing adjustments are absolute from the releaser but can be debuffed by the receiver.
			local loss_per_player = TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER
			if inst.soul_heal_player_efficient then
				loss_per_player = loss_per_player * TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_4_LOSS_PER_PLAYER_MULT
			end
			local amt = math.max(TUNING.WORTOX_SOULHEAL_MINIMUM_HEAL, (TUNING.HEALING_MED * (inst.soul_heal_premult or 1) - loss_per_player * (healtargetscount - 1)) * (inst.soul_heal_mult or 1))
			local amt_naughty = amt * TUNING.SKILLS.WORTOX.NAUGHTY_SOULHEAL_RECEIVED_MULT

			local souls = 0
			local wortox = inst.owner or nil
			if wortox then
				wortox.components.inventory:ForEachItemSlot(function(item)
					if item.prefab == "wortox_soul" then
						souls = souls + (item.components.stackable and item.components.stackable:StackSize() or 1)
					elseif item.prefab == "wortox_souljar" then
						souls = souls + item.soulcount
					end
				end)
				local activeitem = wortox.components.inventory:GetActiveItem()
				if activeitem then
					if activeitem.prefab == "wortox_soul" then
						souls = souls + (activeitem.components.stackable and activeitem.components.stackable:StackSize() or 1)
					elseif activeitem.prefab == "wortox_souljar" then
						souls = souls + activeitem.soulcount
					end
				end
			end
			for i = 1, healtargetscount do
				local v = healtargets[i]
				local adjusted_amt = v.wortox_inclination == "naughty" and amt_naughty or amt
				
				if souls > 20 then -- linearly reduce effectiveness of souls if wortox is holding more than 20
					adjusted_amt = adjusted_amt + 20 - souls
				end
				if adjusted_amt < 0 then
					adjusted_amt = 0
				end
				
				if inst.soul_doburst then -- Soul bastion 1 allows you to bypass SHOT
					v.components.health:DoDelta(adjusted_amt, nil, inst.prefab)
				else
					v.components.debuffable:AddDebuff("healthregenbuff_vetcurse_soul", "healthregenbuff_vetcurse",
							{ duration = (adjusted_amt * 0.1) })
				end		
				if inst.soul_heal_player_efficient then -- Soul bastion 2 Recovers some maximum health
					v.components.health:DeltaPenalty(-0.02)
				end
				
				if v.components.combat then -- Always show fx now that the heals do special targeting to show the player that it stops working when everyone is full.
					local fx = GLOBAL.SpawnPrefab("wortox_soul_heal_fx")
					fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
					fx:Setup(v)
				end
			end
		end
		if sanitytargetscount > 0 then
			-- Sanity adjustments are relative to who sees it.
			local amt = TUNING.SANITY_TINY * 0.5
			local amt_nice = amt * TUNING.SKILLS.WORTOX.NICE_SANITY_MULT
			local amt_naughty = amt * TUNING.SKILLS.WORTOX.NAUGHTY_SANITY_MULT
			for i = 1, sanitytargetscount do
				local v = sanitytargets[i]
				local adjusted_amt = v.wortox_inclination == "nice" and amt_nice or v.wortox_inclination == "naughty" and amt_naughty or amt
				v.components.sanity:DoDelta(adjusted_amt)
			end
		end
	end


	--beta uses
	local wortox_soul_common = require("prefabs/wortox_soul_common")
	wortox_soul_common.DoHeal = UncompromisingSoulHeal
		

	AddPrefabPostInit("wortox_reviver", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		inst:RemoveTag("reviver")
	end)
	AddPrefabPostInit("wortox_soul", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		local _ModifyStats = inst.ModifyStats
		
		local function ModifyStats(inst,owner)
			inst.owner = owner -- need to pass the owner so each soul can count how many souls the owner has
			_ModifyStats(inst,owner)
		end
		inst.ModifyStats = ModifyStats
	end)	
	
	local STRINGS = GLOBAL.STRINGS
	-- Skilltree Text Changes
	STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_1_DESC = "Learn how to channel Souls into a Twintailed Heart. This creation, when held, will save the bearer's life." 
	STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_2_DESC = "Reduces max penalties from using Twintailed Heart."
	
	STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_3_DESC = "Dropped Souls will instantly heal players and do a second healing wave for a lower amount after a delay."
	STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_4_DESC = "Dropped Souls will move faster towards hurt players, the second healing wave will happen quicker, and Souls are more efficient at healing multiple players. Souls will also recover health penalties."
	
	local SkillTreeDefs = GLOBAL.require("prefabs/skilltree_defs")
	if SkillTreeDefs.SKILLTREE_DEFS["wortox"] ~= nil then
		SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_lifebringer_1.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_1_DESC
		SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_lifebringer_2.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_2_DESC
		
		SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_soulprotector_3.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_3_DESC
		SkillTreeDefs.SKILLTREE_DEFS["wortox"].wortox_soulprotector_4.desc = STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_4_DESC
	end

end

AddPrefabPostInit("wortox", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	if inst.components.foodaffinity ~= nil then
		inst.components.foodaffinity:AddPrefabAffinity("devilsfruitcake", 1.24)
	end
	
end)


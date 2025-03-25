local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

if TUNING.DSTU.WORTOXCHANGES then




	--- Soul Changes, will eventually remove them after these lower-effort enemies have more nuance to killing a lot of them
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
				if adjusted_amt < 5 then
					adjusted_amt = 5
				end
				
				if inst.soul_doburst then -- Soul bastion 1 allows you to bypass SHOT
					v.components.health:DoDelta(adjusted_amt, nil, inst.prefab)
				else
					v.components.debuffable:AddDebuff("healthregenbuff_vetcurse_soul", "healthregenbuff_vetcurse",
							{ duration = (adjusted_amt * 0.1) })
				end		
				if inst.soul_heal_player_efficient then -- Soul bastion 2 Recovers some maximum health
					v.components.health:DeltaPenalty(-0.01)
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


	--Override the healing function with a new one
	local wortox_soul_common = require("prefabs/wortox_soul_common")
	wortox_soul_common.DoHeal = UncompromisingSoulHeal
		

	AddPrefabPostInit("wortox_reviver", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		inst:RemoveTag("reviver")
	end)
	
	
	local SOULPROTECTOR_TICK_TIME = 0.1
	AddPrefabPostInit("wortox_soul", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		local function ModifyStats(inst,owner) 
			local skilltreeupdater = owner.components.skilltreeupdater
			if skilltreeupdater then
				if skilltreeupdater:IsActivated("wortox_soulprotector_1") then
					inst.soul_heal_range_modifier = (inst.soul_heal_range_modifier or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_RANGE
					inst.soul_follow_speed = (inst.soul_follow_speed or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_SPEED
					inst.soulprotector_task = inst:DoPeriodicTask(SOULPROTECTOR_TICK_TIME, inst.SoulProtectorTick, 0.3)
				end
				if skilltreeupdater:IsActivated("wortox_soulprotector_3") then
					inst.soul_doburst = true
				end
				if skilltreeupdater:IsActivated("wortox_soulprotector_4") then
					inst.soul_follow_speed = (inst.soul_follow_speed or 0) + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_4_SPEED
					inst.soul_doburst_faster = true
					inst.soul_heal_player_efficient = true
				end
			end
			inst.owner = owner -- need to pass the owner so each soul can count how many souls the owner has
		end
		
		inst:AddComponent("tradable")

		inst:AddComponent("upgrader")
		inst.components.upgrader.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
		inst.components.upgrader.upgradevalue = 2

		inst.ModifyStats = ModifyStats
	end)
	
	AddPrefabPostInit("wortox_soul_spawn", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		local _OnThrownFn = inst.components.projectile.onthrown
		
		local function OnThrownTimeout(inst)
			inst._timeouttask = nil
			inst.components.projectile:Miss(inst.components.projectile.target)
		end
		
		local function OnThrown(inst, owner, target, attacker)
			_OnThrownFn(inst, owner, target, attacker) -- we don't want to have to replace the whole function, just recheck the timeout
	
			
			local duration = TUNING.WORTOX_SOUL_PROJECTILE_LIFETIME
			if target and target.components.skilltreeupdater then --redo the timer w/ thief 1 instead of relying on thief 2
				if target.components.skilltreeupdater:IsActivated("wortox_thief_1") then
					if inst._timeouttask ~= nil then
						inst._timeouttask:Cancel()
						inst._timeouttask = nil
					end
					duration = duration + TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_LIFETIME_BONUS
					inst._timeouttask = inst:DoTaskInTime(duration, OnThrownTimeout)
				end
			end
		end	
		inst.components.projectile:SetOnThrownFn(OnThrown)
		
	end)		
	

	local function SpawnWovenShadow(inst, upgrade_performer, obj)
		if inst.components.stackable then
			inst.components.stackable:Get(1):Remove()
			inst:RemoveComponent("upgradeable") -- reset the component, it sometimes loses the ability to be used when you take from stack
			inst:AddComponent("upgradeable")
			inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
			inst.components.upgradeable.onupgradefn = SpawnWovenShadow		
		else
			inst:Remove()
		end
		
		local rnd = math.random()
		
		
		local crechure = "stalker_minion"
		if skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") then -- 2x likelyhood for second shadow skill
			if rnd < 0.02 then
				crechure = "ruinsnightmare"
			elseif rnd < 0.12 then
				crechure = "nightmarebeak"
			elseif rnd < 0.4 then
				crechure = "crawlingnightmare"
			end
		else
			if rnd < 0.01 then
				crechure = "ruinsnightmare"
			elseif rnd < 0.06 then
				crechure = "nightmarebeak"
			elseif rnd < 0.2 then
				crechure = "crawlingnightmare"
			end
		end
		local shadow = GLOBAL.SpawnPrefab(crechure) 
		shadow.wortox_minion = true -- These Guys are minions of Wortox
		
		local x,y,z = upgrade_performer.Transform:GetWorldPosition()
		local offset = GLOBAL.FindWalkableOffset(upgrade_performer:GetPosition(),math.random() * 2 * GLOBAL.PI, 4, 5)
		if offset then -- So it doesn't crash if the player is godmode on the ocean and tries to weave a shadow
			x = x + offset.x
			z = z + offset.z
		end
		shadow.Transform:SetPosition(x,y,z)
		    
		local despawn = GLOBAL.SpawnPrefab("shadow_despawn")
		despawn.Transform:SetPosition(x, y, z)
	
		
		shadow:AddComponent("follower")
		upgrade_performer.components.leader:AddFollower(shadow)

		if crechure == "stalker_minion" then
			shadow.die_off = shadow:DoTaskInTime(60,function(shadow) 
				if shadow.components.health and not shadow.components.health:IsDead() then 
					shadow.components.health:Kill() 
				end 
			end)
		else
			shadow.die_off = shadow:DoPeriodicTask(1,function(shadow) 
				if shadow.components.health and not shadow.components.health:IsDead() then 
					shadow.components.health:DoDelta(-5)
				end 
			end)		
		end
		
		--shadow.persists = false
        local fx = GLOBAL.SpawnPrefab("wortox_soulecho_buff_fx")
        shadow.bufffx = fx
        fx.entity:SetParent(shadow.entity)
		fx.Transform:SetScale(2,2,2)
		shadow:ListenForEvent("ondeath",function(shadow)
			if inst.bufffx and inst.bufffx:IsValid() then
				inst.bufffx:Remove()
			end
			inst.bufffx = nil
			inst:Remove()	
		end)
		if shadow.components.lootdropper then
			shadow.components.lootdropper:SetLoot(nil)
			shadow.components.lootdropper:SetChanceLootTable(nil)
		end
		if crechure == "stalker_minion" then
			shadow.sg:GoToState("emerge_noburst")
			shadow:OnSpawnedBy(upgrade_performer)
		end
	end
	
	AddPrefabPostInit("nightmarefuel", function(inst)
		inst:AddTag("SOUL_SHADOW_upgradeable")
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		
		inst:AddComponent("upgradeable")
		inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
		inst.components.upgradeable.onupgradefn = SpawnWovenShadow		
	end)
	
	AddPrefabPostInit("voidcloth_scythe", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		
		local _OnAttack = inst.components.weapon.onattack
	
		local function OnAttack(inst, attacker, target) 
			local skilltreeupdater = attacker.components.skilltreeupdater
			local max_health = target.components.health ~= nil and target.components.health.maxhealth
			if target.components.health ~= nil and target.components.health:IsDead() and not target:HasTag("structure") and skilltreeupdater and skilltreeupdater:IsActivated("wortox_allegiance_shadow") and max_health then
				local x,y,z = attacker.Transform:GetWorldPosition()
				local shadows = TheSim:FindEntities(x,y,z,20,{"shadow"})
				local k = 0
				for i,shadow in ipairs(shadows) do -- find the division of health
					if shadow.wortox_minion then
						k = k + 1
					end
				end
				for i,shadow in ipairs(shadows) do
					if shadow.wortox_minion then
						GLOBAL.SpawnPrefab("shadow_despawn").Transform:SetPosition(shadow.Transform:GetWorldPosition())
						shadow.components.health:DoDelta(max_health/k)
					end
				end
			end
			_OnAttack(inst,attacker,target)
		end
				
		inst.components.weapon:SetOnAttack(OnAttack)
	end)
	
	local MIN_FOLLOW_LEADER = 2
	local MAX_FOLLOW_LEADER = 6
	local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2
	-- make woven shadow creatures follow wortox
	local function GetLeader(inst)
		return inst.components.follower ~= nil and inst.components.follower.leader or nil
	end
	
	local function ShadowCreatureFollow(self)
		table.insert(self.bt.root.children, 1, GLOBAL.WhileNode(function() return GetLeader(self.inst) end, "HasLeader",
            GLOBAL.Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER)))
	end

	AddBrainPostInit("nightmarecreaturebrain", ShadowCreatureFollow)
	
	modimport("init/init_character_changes/skilltree_wortox") -- Import New Wortox Tree

    AllRecipes["wortox_reviver"].ingredients = {
        Ingredient("wortox_soul", 20),
    }	
end

AddPrefabPostInit("wortox", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	if inst.components.foodaffinity ~= nil then
		inst.components.foodaffinity:AddPrefabAffinity("devilsfruitcake", 1.24)
	end
	
end)


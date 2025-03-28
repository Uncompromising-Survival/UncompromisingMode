require "behaviours/chaseandattack"

local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")

if TUNING.DSTU.WORTOXCHANGES then


	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Soul Changes, will eventually remove them after these lower-effort enemies have more nuance to killing a lot of them ] ----
	--------------------------------------------------------------------------------------------------------------------------------

	AddPrefabPostInitAny(function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return inst
		end
		--if inst.components.health ~= nil and inst:HasTag("insect") and inst.components.health ~= nil and not inst.components.health:IsDead() and inst.components.health.maxhealth <= 100 then
		if inst:HasTag("butterfly") --[[or (not GetModConfigData("wortox_beesouls") and inst:HasTag("bee"))]] then
			inst:AddTag("soulless")
		end
	end)
		
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Soul Healing Changes ] ----------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------	
	
	local SOULPROTECTOR_TICK_TIME = 0.1
		
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


			for i = 1, healtargetscount do
				local v = healtargets[i]
				local adjusted_amt = v.wortox_inclination == "naughty" and amt_naughty or amt
				
				adjusted_amt = adjusted_amt/2
				
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
	
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Twin Tailed Heart ] -------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------		

	AddPrefabPostInit("wortox_reviver", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		inst:RemoveTag("reviver")
		
		local function OnConsume(inst, owner)
			if inst.components.perishable and inst.components.perishable:GetPercent() > 0.5 then
				inst.components.perishable:SetPercent(inst.components.perishable:GetPercent()-0.5) -- take 1/2 freshhness
			else	
				inst:Remove()
			end
		end		
			
		inst.OnConsume = OnConsume
	end)
    AllRecipes["wortox_reviver"].ingredients = {
        Ingredient("wortox_soul", 20),
    }		
	
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Soul Pierce Changes ] -----------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------		

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

	local function OnHit(inst, attacker, target)
		if target ~= nil then
			local x, y, z = inst.Transform:GetWorldPosition()
			local fx = GLOBAL.SpawnPrefab("wortox_soul_in_fx")
			fx.Transform:SetPosition(x, y, z)
			fx:Setup(target)
			--ignore .isvisible, as long as it's .isopen
			if target.components.inventory ~= nil and target.components.inventory.isopen then
				target.components.inventory:GiveItem(GLOBAL.SpawnPrefab("wortox_soul"), nil, target:GetPosition())
			else
				--reuse fx variable
				fx = GLOBAL.SpawnPrefab("wortox_soul")
				fx.Transform:SetPosition(x, y, z)
				fx.components.inventoryitem:OnDropped(true)
			end
		end
		inst:Remove()
	end
	
	local function RethrowProjectile(inst, speed, soulthiefreceiver)
		if soulthiefreceiver:IsValid() then
			inst.components.projectile:SetSpeed(speed)
			inst.components.projectile:SetHoming(true)

			local x, y, z = inst.Transform:GetWorldPosition()
			inst.components.projectile:SetBounced(true)
			inst.components.projectile.overridestartpos = GLOBAL.Vector3(x, 0, z)
			inst.components.projectile:SetOnHitFn(OnHit)
			inst.components.projectile:Throw(inst, soulthiefreceiver, soulthiefreceiver)
		end
	end
	
	local function ReleaseSoul(inst,target,inv_soul) -- manually throw the soul
		if inv_soul.components.stackable ~= nil and inv_soul.components.stackable:IsStack() then
			inv_soul.components.stackable:Get():Remove()
		else
			inv_soul:Remove()
		end
		local x1,y1,z1 = inst.Transform:GetWorldPosition()
		local x2,y2,z2 = target.Transform:GetWorldPosition()
		local x = (x1+x2)/2
		local z = (z1+z2)/2
		local soul = GLOBAL.SpawnPrefab("wortox_soul_spawn")
		soul.Transform:SetPosition(x,0,z)
		
		soul.soul_spear_task = soul:DoPeriodicTask(0.1, soul.SoulSpearTick, 0, inst)
		
		local speed = TUNING.WORTOX_SOUL_PROJECTILE_SPEED
		soul.components.projectile:SetSpeed(-speed)
		soul.components.projectile:SetHoming(false)
		soul:DoTaskInTime(TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_REPEL_DURATION, RethrowProjectile, speed, inst)
		soul.components.projectile:SetOnHitFn(OnHit)
        soul.components.projectile:Throw(soul, inst, inst)
		soul.components.projectile:SetOnHitFn(function(soul) end)
	end
	
	local function GenerateSouls(inst,data)
		if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wortox_thief_4") then
			local souls = 0
			local ref_item = nil
			inst.components.inventory:ForEachItemSlot(function(item)
				if item.prefab == "wortox_soul" then
					souls = souls + (item.components.stackable and item.components.stackable:StackSize() or 1)
					ref_item = item
				end
			end)
			if souls >= 10 then
				if not inst.wortox_damage_recent then
					inst.wortox_damage_recent = 0
				end
				inst.wortox_damage_recent = inst.wortox_damage_recent + data.damage		
				if inst.wortox_damage_recent >= 176 then
					inst.wortox_damage_recent = 0
					ReleaseSoul(inst,data.target,ref_item)
				end				
			end
		end
	end
	
	AddPrefabPostInit("wortox", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		
		inst:ListenForEvent("onhitother", GenerateSouls)
		
	end)	
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Shadow Weaving ] ----------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------	
	
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
		local skilltreeupdater = upgrade_performer.components.skilltreeupdater
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
		
		shadow:RemoveComponent("sanityaura")
	end

	--------------------------------------------
	--[ Make Nightmarefuel "Upgradeable" ] -----
	--------------------------------------------
	
	AddPrefabPostInit("nightmarefuel", function(inst)
		inst:AddTag("SOUL_SHADOW_upgradeable")
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		
		inst:AddComponent("upgradeable")
		inst.components.upgradeable.upgradetype = GLOBAL.UPGRADETYPES.SOUL_SHADOW
		inst.components.upgradeable.onupgradefn = SpawnWovenShadow		
	end)
	
	--------------------------------------------
	--[ Scythe Extending Lifetime of Shadows] --
	--------------------------------------------
	
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
	
	-----------------------------
	--[ Shadow Brain Changes ] --
	-----------------------------
		
	--- Wortox Shadow brain changes
	local MIN_FOLLOW_LEADER = 2
	local MAX_FOLLOW_LEADER = 6
	local TARGET_FOLLOW_LEADER = (MAX_FOLLOW_LEADER + MIN_FOLLOW_LEADER) / 2
	-- make woven shadow creatures follow wortox
	local function GetLeader(inst)
		return inst.components.follower ~= nil and inst.components.follower.leader or nil
	end

	local function ShadowCreatureFollow(self)

		table.insert(self.bt.root.children, 2, GLOBAL.WhileNode(function() return GetLeader(self.inst) end, "HasLeader",
            GLOBAL.Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER)))
	end

	AddBrainPostInit("nightmarecreaturebrain", ShadowCreatureFollow)
	
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Nabbag Damage Calculation Tweak ] -----------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------	
	
	AddPrefabPostInit("wortox_nabbag", function(inst)
		if not GLOBAL.TheWorld.ismastersim then
			return
		end
		
		local BUCKET_NAMES = {
			"_empty",
			"_medium",
			"_full",
		}
		local BUCKET_SIZE = #BUCKET_NAMES

		local function UpdateStats(inst, percent, souls)
			-- Make the sizes into buckets.
			local bucket = math.clamp(math.ceil(percent * BUCKET_SIZE), 1, BUCKET_SIZE)
			local old_size = inst.nabbag_size
			inst.nabbag_size = BUCKET_NAMES[bucket]
			-- Scale percent to be percent of bucket.
			percent = (bucket - 1) / (BUCKET_SIZE - 1)

			local vfx_level = 0
			local owner = inst.components.inventoryitem.owner
			if inst.components.weapon then
				local maxdamage = 51
				local mindamage = TUNING.SKILLS.WORTOX.NABBAG_DAMAGE_MIN
				local damage = (maxdamage - mindamage) * percent + mindamage
				if owner and owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wortox_souljar_3") then
					local souls_max = TUNING.SKILLS.WORTOX.SOUL_DAMAGE_MAX_SOULS
					local souls_clamped = math.min(souls, souls_max)
					if souls_clamped == souls_max then -- NOTES(JBK): This is done like this to keep floating point precision out of the equation.
						vfx_level = 3
					elseif souls_clamped >= souls_max * 0.50 then
						vfx_level = 2
					elseif souls_clamped >= souls_max * 0.25 then
						vfx_level = 1
					end
					local damage_percent = souls_clamped / souls_max
					damage = damage * ((1 + (TUNING.SKILLS.WORTOX.SOUL_DAMAGE_NABBAG_BONUS_MULT - 1)/3 * damage_percent))
				end
				inst.components.weapon:SetDamage(damage)
				inst.components.weapon.attackwearmultipliers:SetModifier(inst, percent)
			end

			if inst.wortox_nabbag_body ~= nil then
				inst.wortox_nabbag_body.bodysize_netvar:set(bucket - 1)
				inst.wortox_nabbag_body.bodyvfx_souls:set(vfx_level)
				inst.wortox_nabbag_body:UpdateBodySize()
				if inst.wortox_nabbag_body.hiding then
					if owner then
						owner.AnimState:OverrideSymbol("swap_object", "swap_wortox_nabbag", "swap_wortox_nabbag" .. inst.nabbag_size)
					end
				end
			end
			if inst.nabbag_size == "_empty" then
				inst.components.inventoryitem:ChangeImageName(nil) -- Default image name is the prefab name itself as a network optimization.
			else
				inst.components.inventoryitem:ChangeImageName("wortox_nabbag" .. inst.nabbag_size)
			end
		end

		inst.UpdateStats = UpdateStats
			
	end)
	

	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Final Built Skilltree ] ---------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------
	
	modimport("init/init_character_changes/skilltree_wortox") -- Import New Wortox Tree


end


AddPrefabPostInit("wortox", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	--------------------------------------------------------------------------------------------------------------------------------
	-- [ Give Wortox devil food cake affinity ] ------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------
	
	if inst.components.foodaffinity ~= nil then
		inst.components.foodaffinity:AddPrefabAffinity("devilsfruitcake", 1.24)
	end
	
end)


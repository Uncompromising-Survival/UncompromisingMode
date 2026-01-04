local env = env
GLOBAL.setfenv(1, GLOBAL)

if TUNING.DSTU.WATHGRITHR_REWORK ~= 0 then
	env.AddPrefabPostInit("wathgrithr", function(inst)

		if not TheWorld.ismastersim then
			return
		end

		if inst.components.battleborn ~= nil then
			inst.components.battleborn:SetClampMin(0.33 * TUNING.DSTU.WATHGRITHR_BASE_BATTLEBORN_CLAMP_MULT)
			inst.components.battleborn:SetClampMax(2 * TUNING.DSTU.WATHGRITHR_BASE_BATTLEBORN_CLAMP_MULT)
			inst.components.battleborn:SetBattlebornBonus(0.25 * TUNING.DSTU.WATHGRITHR_BASE_BATTLEBORN_BONUS_MULT)
		end

		if TUNING.DSTU.WATHGRITHR_REWORK == 1 then inst:AddComponent("efficientuser") end
	end)
end

env.AddPrefabPostInit("battlesong_container", function(inst)

	if not TheWorld.ismastersim then
		return
	end

	inst:RemoveComponent("burnable")
	inst:RemoveComponent("propagator")
end)

----------------------------------------------------------------------------------------------------------------------------------------------------
--
-- TUNING
--
----------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------
-- BASE STATS
--------------------------------------------------------------------------

TUNING.DSTU.WATHGRITHR_BASE_BATTLEBORN_CLAMP_MULT = 0.33 -- This has an effect on small creatures only
TUNING.DSTU.WATHGRITHR_BASE_BATTLEBORN_BONUS_MULT = 0.66 -- This affects mainly big creatures

if TUNING.DSTU.WATHGRITHR_REWORK == 1 then -- Enabled only
TUNING.WATHGRITHR_BASE_INSPIRATION_GAIN_MULT = 1 

--------------------------------------------------------------------------
-- SHADOW HUNTRESS
--------------------------------------------------------------------------

TUNING.DSTU.WATHGRITHR_SHADOW_INSPIRATION_GAIN_MULT = 0 -- How fast it goes up per hit
TUNING.DSTU.WATHGRITHR_SHADOW_INSPIRATION_BUFFER_MULT = 1 -- How much time out of combatbefore it starts going down
TUNING.DSTU.WATHGRITHR_SHADOW_INSPIRATION_DRAIN_MULT = 1 -- How fast it ticks down

TUNING.DSTU.WATHGRITHR_SHADOW_BATTLEBORN_CLAMP_MULT = 1.15 -- This has an effect on small creatures only
TUNING.DSTU.WATHGRITHR_SHADOW_BATTLEBORN_BONUS_MULT = 1.15 -- This affects mainly big creatures
--TUNING.DSTU.WATHGRITHR_SHADOW_HUNGER_MULT = 1.2
--TUNING.DSTU.WATHGRITHR_MAXHEALTH_MULT = 1.25 -- 200 * value
TUNING.DSTU.WATHGRITHR_SHADOW_ABSORPTION = 0.35 -- Vanilla 0.25
TUNING.DSTU.WATHGRITHR_SHADOW_DAPPERNESS_MULT = 0.5 --How much sanity shadow items drain. 0-1
TUNING.DSTU.DREADSTONE_PREFABS = {"armordreadstone", "dreadstonehat"}

--------------------------------------------------------------------------
-- LUNAR MELODIST
--------------------------------------------------------------------------

--TUNING.DSTU.WATHGRITHR_LUNAR_INSPIRATION_GAIN_MULT = 1.5
--TUNING.DSTU.WATHGRITHR_LUNAR_INSPIRATION_BUFFER_MULT = 5
--TUNING.DSTU.WATHGRITHR_LUNAR_INSPIRATION_DRAIN_MULT = 0.2

--TUNING.DSTU.WATHGRITHR_LUNAR_BATTLEBORN_MULT = 0 -- Currently not in use

-- Songs
--TUNING.BATTLESONG_LUNAR_DURABILITY_ARMOR_MULT_SINGER = 0.15
--TUNING.DSTU.BATTLESONG_LUNAR_DURABILITY_MULT_SINGER = 0.9  -- We are multiplying 0.75 by this number
--TUNING.DSTU.BATTLESONG_LUNAR_HEALTHGAIN_MULT_SINGER = 2.5  -- We are multiplying 0.5 by this number 
--TUNING.DSTU.BATTLESONG_LUNAR_SANITYGAIN_MULT_SINGER = 1.25 -- We are multiplying 1 by this number
TUNING.DSTU.BATTLESONG_LUNAR_SANITYAURA_MULT_SINGER = 0.8  -- We are multiplying 0.5 by this number

TUNING.DSTU.BATTLESONG_LUNAR_REGEN_PERIOD = 5 -- Every X Seconds
TUNING.DSTU.BATTLESONG_LUNAR_REGEN_AMOUNT_HEALTH = 1
TUNING.DSTU.BATTLESONG_LUNAR_REGEN_AMOUNT_SANITY = 1
TUNING.DSTU.BATTLESONG_LUNAR_DURABILITY_MOD_ARMOR = 0.85 -- 1 does nothing, 0 armor takes no damage

TUNING.DSTU.BATTLESONG_LUNAR_LUNARALIGNED_LUNAR_RESIST = 0.85 -- Vanilla 0.9
TUNING.DSTU.BATTLESONG_LUNAR_LUNARALIGNED_VS_SHADOW_BONUS = 1.1 -- Vanilla 1.05
TUNING.DSTU.BATTLESONG_LUNAR_SHADOWALIGNED_SHADOW_RESIST0 = 0.85 -- Vanilla 0.9
TUNING.DSTU.BATTLESONG_LUNAR_SHADOWALIGNED_VS_LUNAR_BONUS = 1.1 -- Vanilla 1.05
end


--------------------------------------------------------------------------
-- EQUIPMENT PERKS
--------------------------------------------------------------------------

if TUNING.DSTU.WATHGRITHR_REWORK == 1 then -- Only with rework enabled
	-- Spear
	TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_LUNGE_USES = 2 -- Base cost of lunge
	--TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_LUNGE_ONHIT_USES = 0.5 -- Durability lost per mob hit
	--TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_LUNGE_MAX_HITS = 8 -- After this number of hits it will no longer drain durability

	TUNING.SPEAR_WATHGRITHR_LIGHTNING_USES = 200 ---150 base
	TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_USES = 200 -- 200 base
	TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LIGHTNINGREPAIR = 25 -- Uses

	-- Shield
	TUNING.WATHGRITHR_SHIELD_COOLDOWN = 5 --10
	--TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP = 2
	TUNING.WATHGRITHR_SHIELD_PARRY_DURATION = 1 * 2.5 --1 Apply it to the base shield
	TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_DURATION_MULT = 1 --2.5 This skill is no longer about parry duration, so remove the multiplier
	TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION = 0.4 --0.7 Advances to 70% cooldown, so the new cooldown is 30% of WATHGRITHR_SHIELD_COOLDOWN.

	--TUNUNG.WATHGRITHR_SHIELD_DAMAGE = wilson_attack * 1.5

	TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE = {min=15, max=100} --{ min=15, max=30 }
	TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_SCALE = 0.8 --0.5

	TUNING.DSTU.WATHGRITHR_SHIELD_DURABILITY_MULT = 1.3

	--TUNING.DSTU.WATHGRITHR_SHIELD_BASE_PARRY_EFFICIENCY = 0.6 --Parry durability loss = Hit damage * ( BASE_PARRY_EFFICIENCY - (UPGRADE_PARRY_EFFICIENCY * skil level))
	--TUNING.DSTU.WATHGRITHR_SHIELD_UPGRADE_PARRY_EFFICIENCY = 0.2 -- additive per upgrade with WATHGRITHR_SHIELD_BASE_PARRY_EFFICIENCY
	TUNING.DSTU.WATHGRITHR_SHIELD_PARRY_DURABILITY_LOSS = 0.1 -- Percentage of the hit damage that deducts durability. 0.2 = (100 damage hit will reduce shield durability by 20)

	-- Commander Helm
	TUNING.BATTLEBORN_REPAIR_EQUIPMENT_MULT = 3.5 * 0.4

	TUNING.SADDLE_WATHGRITHR_BONUS_DAMAGE = 12 -- 5
end


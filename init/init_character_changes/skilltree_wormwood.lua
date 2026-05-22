local SkillTreeDefs = require("prefabs/skilltree_defs")
local SkillTreeFns = SkillTreeDefs.FN
local TheWorld = GLOBAL.TheWorld

local UI_LEFT, UI_RIGHT = -214, 228
local UI_VERTICAL_MIDDLE = (UI_LEFT + UI_RIGHT) * 0.5
local UI_TOP, UI_BOTTOM = 176, 20
local TILE_SIZE, TILE_HALFSIZE = 34, 16
local WORMSKILLS = STRINGS.SKILLTREE.WORMWOOD

--------------------------------------------------------------------------------------------------

local ORDERS =
{
    { "crafting",    { UI_LEFT, UI_TOP } },
    { "gathering",   { UI_LEFT, UI_TOP } },
    { "allegiance1", { UI_LEFT, UI_TOP } },
    { "allegiance2", { UI_LEFT, UI_TOP } },
}


local function OnSeasonChange(inst, season)
	if (season == "summer" or season == "spring") and not inst:HasTag("playerghost") and inst.components.skilltreeupdater ~= nil and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis") then
		inst.components.bloomness:Fertilize()
	end
end

local STRINGS = GLOBAL.STRINGS
local WORMSKILLS = STRINGS.SKILLTREE.WORMWOOD

local function BSlapSomeone(inst, data)
	
	-- Brambleshade also snares enemies
	if inst == nil or data == nil then
		return
	end
	
	local attacker = data.attacker
	if not attacker or not attacker.components.locomotor
			or (attacker.components.health and attacker.components.health:IsDead()) or data.attacker:HasAnyTag("shadowcreature","brightmare_gestalt","ghost","flying") then
		return
	end

	local inst_skilltreeupdater = inst.components.skilltreeupdater
	if inst_skilltreeupdater and inst_skilltreeupdater:IsActivated("wormwood_allegiance_lunar_plant_gear_1") and math.random() > 0.66 then
		attacker:AddDebuff("wormwood_vined_debuff", "wormwood_vined_debuff")
	end
end

		
		
		
local skills =
{
	wormwood_identify_plants2 = { 
		title = WORMSKILLS.IDENTIFY_PLANTS_TITLE, --"Seed Sleuth"
		desc = WORMSKILLS.IDENTIFY_PLANTS_DESC,
		icon = "wormwood_identify_plants",
		pos = {(UI_LEFT + UI_RIGHT) * 0.5, UI_BOTTOM},

		group = "gathering",
		tags = {},
		root = true,
		onactivate = function(owner, from_load)
			owner:AddTag("farmplantidentifier")
		end,
		ondeactivate = function(owner, from_load)
			owner:RemoveTag("farmplantidentifier")
		end,
		connects = {
			"wormwood_blooming_farmrange1",
			"wormwood_quick_selffertilizer",
			"wormwood_blooming_speed1",
			"wormwood_prick_adept",
		},
		defaultfocus = true,
	},
	wormwood_blooming_farmrange1 = { -- This is "Farmhand"
		title = WORMSKILLS.BLOOMING_FARMRANGE1_TITLE,
		desc = WORMSKILLS.BLOOMING_FARMRANGE1_DESC,
		icon = "wormwood_blooming_farmrange1",
		pos = {UI_VERTICAL_MIDDLE - 105, UI_BOTTOM + 10},

		group = "gathering",
		tags = {"crafting"},
		onactivate = function(owner)
			owner:AddTag("farmplantfastpicker")
		end,
		ondeactivate = function(owner)
			owner:RemoveTag("farmplantfastpicker")
		end,
		connects = {
			"wormwood_bugs",
		},
	},

	wormwood_bugs = {
		title = WORMSKILLS.BUGS_TITLE,
		desc = WORMSKILLS.BUGS_DESC,
		icon = "wormwood_bugs",
		
		pos = {UI_VERTICAL_MIDDLE - 105 - 50, UI_BOTTOM + 10},
		group = "gathering",
		tags = {"crafting"},
		connects = {
			"wormwood_sympathetic_blooming",
			"wormwood_originator",
		},
	},


	wormwood_originator = { -- WHOOPS Wormiest meant "Progenitor", it'll be fixed in the string, I'm not fixing the var name.
		title = WORMSKILLS.ORIGINATOR_TITLE,  --"Juicy Berry Crafting" -> Originator - Combine all plant crafting skills.
		desc = WORMSKILLS.ORIGINATOR_DESC,
		icon = "wormwood_originator",
		pos = {UI_VERTICAL_MIDDLE - 115 - 60, UI_BOTTOM + 58},

		group = "crafting",
		tags = {"crafting"},
	},

	wormwood_sympathetic_blooming = {
		title = WORMSKILLS.SYMBLOOMER_TITLE,  --"Reed crafting" -> Sympathetic Blooming: Being bloomed near Cacti will cause them to flower, being bloomed near a mushtree will have them bloom as well. (Latter idea by Axe).
		desc = WORMSKILLS.SYMBLOOMER_DESC,
		icon = "wormwood_sympathetic_blooming",
		pos = {UI_VERTICAL_MIDDLE - 105 - 100, UI_BOTTOM + 10},

		group = "crafting",
		tags = {"crafting"},
		connects = {
			"wormwood_flytrap",
		},
	},

	wormwood_flytrap = {
		title = "Flytrap",
		desc = "Grab insects and spores without a net.",
		icon = "wormwood_flytrap",
		pos = {UI_VERTICAL_MIDDLE - 115 - 120, UI_BOTTOM + 58},
		onactivate = function(inst, fromload)
			inst:AddTag("wormwood_grabby")
		end,
		ondeactivate = function(inst, fromload)
			inst:RemoveTag("wormwood_grabby")
		end,
		group = "crafting",
		tags = {"crafting"},
	},

	wormwood_quick_selffertilizer = {
		title = WORMSKILLS.QUICK_SELFFERTILIZER_TITLE,
		desc = WORMSKILLS.QUICK_SELFFERTILIZER_DESC,
		icon = "wormwood_quick_selffertilizer",
		pos = {UI_VERTICAL_MIDDLE - 35, UI_BOTTOM + 65},

		group = "gathering",
		tags = {"crafting"},
		connects = {
			"wormwood_resilient_crops1",
		},
	},

	wormwood_resilient_crops1 = {
		title = WORMSKILLS.RCROPS_1_TITLE, --"Mushroom Mastery II" -> Resilient Crops I - Crops planted by wormwood will not get stressed from weeds or debris.
		desc = WORMSKILLS.RCROPS_1_DESC,
		icon = "wormwood_resilient_crops1",
		pos = {UI_VERTICAL_MIDDLE - 90, UI_BOTTOM + 95},

		group = "crafting",
		tags = {"crafting"},
		connects = {
			"wormwood_resilient_crops2",
			"wormwood_syrupcrafting",
		},
	},
	wormwood_resilient_crops2 = {
		title = WORMSKILLS.RCROPS_2_TITLE, --"Mushroom multiplier" -> Resilient Crops II - Wild crops automatically tend themselves.
		desc = WORMSKILLS.RCROPS_2_DESC,
		icon = "wormwood_resilient_crops2",
		pos = {UI_VERTICAL_MIDDLE - 90, UI_BOTTOM + 145},

		group = "crafting",
		tags = {"crafting"},
		connects = {
			"wormwood_resilient_crops3",
		},
	},
	wormwood_resilient_crops3 = {
		title = WORMSKILLS.RCROPS_3_TITLE, --"Mooncap eating" -> "Impeccable crops" Wild crops automatically tend themselves.
		desc = WORMSKILLS.RCROPS_3_DESC,
		icon = "wormwood_resilient_crops3",
		pos = {UI_VERTICAL_MIDDLE - 70, UI_BOTTOM + 190},

		group = "crafting",
		tags = {"crafting"},
	},
	wormwood_syrupcrafting = {
		title = WORMSKILLS.SYRUPCRAFTING_TITLE,
		desc = WORMSKILLS.SYRUPCRAFTING_DESC,
		icon = "wormwood_syrupcrafting",
		pos = {UI_VERTICAL_MIDDLE - 30, UI_BOTTOM + 125},

		group = "crafting",
		tags = {"crafting"},
	},

	wormwood_allegiance_lock_lunar_2 = SkillTreeFns.MakeCelestialChampionLock({
		pos = {UI_RIGHT - 3.5, UI_TOP - 45},
		group = "allegiance2",
	}),

	wormwood_allegiance_count_lock_2 = {
		desc = WORMSKILLS.COUNT_LOCK_2_DESC,
		pos = {UI_RIGHT - 3.5, UI_TOP - 12},
		group = "allegiance2",
		tags = {"allegiance", "lock"},
		locks = {"wormwood_allegiance_lock_lunar_2"},
		lock_open = function(prefabname, activatedskills, readonly)
			return SkillTreeFns.CountTags(prefabname, "blooming", activatedskills) >= 5
		end,
	},

	wormwood_allegiance_lunar_plant_gear_1 = {
		title = WORMSKILLS.LUNAR_GEAR_1_TITLE, --"Lunar Guardian I": Armors worn by Wormwood will have reduced durability loss while bloomed, number up to interpretation. (By Thaumoking)
		desc = WORMSKILLS.LUNAR_GEAR_1_DESC,
		icon = "wormwood_allegiance_lunar_plant_gear_1",
		pos = {UI_RIGHT - 3.5, UI_TOP + 25},
		locks = {"wormwood_allegiance_lock_lunar_2", "wormwood_allegiance_count_lock_2"},

		onactivate = function(owner, from_load)
			if not owner.components.skilltreeupdater:IsActivated("wormwood_allegiance_lunar_eqex") then
				owner:AddTag("player_lunar_aligned")
				if owner.components.damagetyperesist then
					owner.components.damagetyperesist:AddResist("lunar_aligned", owner, TUNING.SKILLS.WILSON_ALLEGIANCE_LUNAR_RESIST, "wormwood_allegiance_lunar")
				end
				if owner.components.damagetypebonus then
					owner.components.damagetypebonus:AddBonus("shadow_aligned", owner, TUNING.SKILLS.WILSON_ALLEGIANCE_VS_SHADOW_BONUS, "wormwood_allegiance_lunar")
				end
				owner:ListenForEvent("attacked",BSlapSomeone)
			end
		end,
		ondeactivate = function(owner, from_load)
			if not owner.components.skilltreeupdater:IsActivated("wormwood_allegiance_lunar_eqex") then
				owner:RemoveTag("player_lunar_aligned")
				if owner.components.damagetyperesist then
					owner.components.damagetyperesist:RemoveResist("lunar_aligned", owner, "wormwood_allegiance_lunar")
				end
				if owner.components.damagetypebonus then
					owner.components.damagetypebonus:RemoveBonus("shadow_aligned", owner, "wormwood_allegiance_lunar")
				end
				owner:RemoveEventCallback("attacked",BSlapSomeone)
			end
		end,

		group = "allegiance2",
		tags = {"allegiance", "lunar", "lunar_favor"},
		connects = {
			"wormwood_allegiance_lunar_plant_gear_2",
		},
	},
	wormwood_allegiance_lunar_plant_gear_2 = { --"Lunar Guardian II"
		title = WORMSKILLS.LUNAR_GEAR_2_TITLE,
		desc = WORMSKILLS.LUNAR_GEAR_2_DESC,
		icon = "wormwood_allegiance_lunar_plant_gear_2",
		pos = {UI_RIGHT - 3.5, UI_TOP + 65},

		group = "allegiance2",
		tags = {"allegiance", "lunar", "lunar_favor"},
	},

	wormwood_blooming_speed1 = {
		title = WORMSKILLS.BLOOMING_SPEED1_TITLE,
		desc = WORMSKILLS.BLOOMING_SPEED1_DESC,
		icon = "wormwood_blooming_speed1",
		pos = {UI_VERTICAL_MIDDLE + 105, UI_BOTTOM + 10},

		group = "gathering",
		tags = {"blooming"},
		onactivate = function(inst, from_load)
            local bloomness = inst.components.bloomness
            if bloomness then
                local skilltreeupdater = inst.components.skilltreeupdater
                if not skilltreeupdater:IsActivated("wormwood_blooming_speed2") and inst._movetreebonus ~= true and bloomness:GetLevel() >= 3 and inst.components.health:GetPercent() >= 0.9 then
                    inst._movetreebonus = true
                    inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.3
                end
            end
		end,
		connects = {
			"wormwood_blooming_speed2",
		},
	},
	wormwood_blooming_speed2 = {
		title = WORMSKILLS.BLOOMING_SPEED2_TITLE,
		desc = WORMSKILLS.BLOOMING_SPEED2_DESC,
		icon = "wormwood_blooming_speed2",
		pos = {UI_VERTICAL_MIDDLE + 105 + 50, UI_BOTTOM + 10},

		group = "gathering",
		tags = {"blooming"},
		onactivate = function(inst, from_load)
            local bloomness = inst.components.bloomness
            if bloomness then
                local skilltreeupdater = inst.components.skilltreeupdater
                if inst._movetreebonus ~= true and bloomness:GetLevel() >= 3 and inst.components.health:GetPercent() >= 0.8 then
                    inst._movetreebonus = true
                    inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.3
                end
            end
		end,
		connects = {
			"wormwood_blooming_max_upgrade",
			"wormwood_blooming_overheatprotection",
		},
	},
	wormwood_blooming_overheatprotection = {
		title = WORMSKILLS.BLOOMING_OVERHEATPROTECTION_TITLE,
		desc = WORMSKILLS.BLOOMING_OVERHEATPROTECTION_DESC,
		icon = "wormwood_blooming_overheatprotection",
		pos = {UI_VERTICAL_MIDDLE + 165, UI_BOTTOM + 60},

		group = "gathering",
		tags = {"blooming"},

		onactivate = function(inst)
			if inst.fullbloom then
				inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED_LARGE
				inst.components.moisture.waterproofnessmodifiers:SetModifier(inst, TUNING.WATERPROOFNESS_SMALL)
			end
		end,
		ondeactivate = function(inst)
			inst.components.moisture.waterproofnessmodifiers:SetModifier(inst, 0)
			if inst.fullbloom then
				inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_SMALL
			else
				inst.components.temperature.inherentsummerinsulation = 0
			end
		end,
	},
	wormwood_blooming_max_upgrade = {
		title = WORMSKILLS.BLOOMING_MAX_UPGRADE_TITLE, --"Flower Power":  "+30% nutrients gained" applies to all nutrients. (Should be done)
		desc = WORMSKILLS.BLOOMING_MAX_UPGRADE_DESC,
		icon = "wormwood_blooming_speed3",
		pos = {UI_VERTICAL_MIDDLE + 105 + 100, UI_BOTTOM + 10},

		group = "gathering",
		tags = {"blooming"},
		connects = {
			"wormwood_blooming_photosynthesis",
		},
		onactivate = function(inst)
			inst.components.bloomness:SetDurations(240, inst.components.bloomness.full_bloom_duration) -- half a day instead of 2/3 of vanilla
		end,
	},

	wormwood_blooming_photosynthesis = {
		title = WORMSKILLS.BLOOMING_PHOTOSYNTHESIS_TITLE,
		desc = WORMSKILLS.BLOOMING_PHOTOSYNTHESIS_DESC,
		icon = "wormwood_blooming_photosynthesis",
		pos = {UI_VERTICAL_MIDDLE + 165 + 55, UI_BOTTOM + 60},

		group = "gathering",
		tags = {"blooming"},

		onactivate = function(inst)
			inst:WatchWorldState("season", OnSeasonChange)
		end,
		ondeactivate = function(inst)
			inst:StopWatchingWorldState("season", OnSeasonChange)
		end,
	},

	wormwood_prick_adept = {
		title = WORMSKILLS.PRICK_ADEPT_TITLE,
		desc = WORMSKILLS.PRICK_ADEPT_DESC,
		icon = "wormwood_prick_adept",
		pos = {UI_VERTICAL_MIDDLE + 55, UI_BOTTOM + 45 + TILE_SIZE},

		group = "gathering",
		tags = {"blooming"},
		connects = {
			"wormwood_blooming_trapbramble",
		},
	},

	wormwood_blooming_trapbramble = {
		title = WORMSKILLS.BLOOMING_TRAPBRAMBLE_TITLE,
		desc = WORMSKILLS.BLOOMING_TRAPBRAMBLE_DESC,
		icon = "wormwood_blooming_trapbramble",
		pos = {UI_VERTICAL_MIDDLE + 95, UI_BOTTOM + 115},

		group = "gathering",
		tags = {"blooming"},
		connects = {
			"wormwood_armor_bramble",
			"wormwood_mushroommadness",
		},
	},

	wormwood_armor_bramble = {
		title = WORMSKILLS.ARMOR_BRAMBLE_TITLE,
		desc = WORMSKILLS.ARMOR_BRAMBLE_DESC,
		icon = "wormwood_armor_bramble",
		pos = {UI_VERTICAL_MIDDLE + 137, UI_BOTTOM + 145},


		group = "gathering",
		tags = {"blooming"},
		connects = {
			"wormwood_armor_bramble2",
		},
	},

	wormwood_armor_bramble2 = {
		title = WORMSKILLS.ARMOR_BRAMBLEBURST_TITLE,
		desc = WORMSKILLS.ARMOR_BRAMBLEBURST_DESC,
		icon = "wormwood_armor_bramble2",
		pos = {UI_VERTICAL_MIDDLE + 120, UI_BOTTOM + 187},


		group = "gathering",
		tags = {"blooming"},
	},

	wormwood_mushroommadness = {
		title = WORMSKILLS.MUSHMAD_TITLE, --"Berry Bush crafting" -> Mushroom Madness: Combines the Mushroom Planters skills into 1.
		desc = WORMSKILLS.MUSHMAD_DESC,
		icon = "wormwood_mushroomplanter_ratebonus2",

		pos = {UI_VERTICAL_MIDDLE + 43, UI_BOTTOM + 150},

		group = "crafting",
		tags = {"blooming"},

	},



	wormwood_allegiance_lock_lunar_1 = SkillTreeFns.MakeCelestialChampionLock({
		pos = {UI_LEFT + 13, UI_BOTTOM + 110},
		group = "allegiance1",
	}),
	wormwood_allegiance_count_lock_1 = {
		desc = WORMSKILLS.COUNT_LOCK_1_DESC,
		pos = {UI_LEFT + 13, UI_BOTTOM + 140},
		group = "allegiance1",
		tags = {"allegiance", "lock"},
		locks = {"wormwood_allegiance_lock_lunar_1"},
		lock_open = function(prefabname, activatedskills, readonly)
			return SkillTreeFns.CountTags(prefabname, "crafting", activatedskills) >= 5
		end,
	},
	wormwood_allegiance_lunar_eqex = {
		title = WORMSKILLS.EQEX_TITLE,
		desc = WORMSKILLS.EQEX_DESC,
		icon = "wormwood_eqex",
		pos = {UI_LEFT + 13, UI_BOTTOM + 175},
		locks = {"wormwood_allegiance_lock_lunar_1", "wormwood_allegiance_count_lock_1"},

		onactivate = function(owner, from_load)
			if not owner.components.skilltreeupdater:IsActivated("wormwood_allegiance_lunar_plant_gear_1") then
				owner:AddTag("player_lunar_aligned")
				if owner.components.damagetyperesist then
					owner.components.damagetyperesist:AddResist("lunar_aligned", owner, TUNING.SKILLS.WILSON_ALLEGIANCE_LUNAR_RESIST, "wormwood_allegiance_lunar")
				end
				if owner.components.damagetypebonus then
					owner.components.damagetypebonus:AddBonus("shadow_aligned", owner, TUNING.SKILLS.WILSON_ALLEGIANCE_VS_SHADOW_BONUS, "wormwood_allegiance_lunar")
				end
			end
		end,
		ondeactivate = function(owner, from_load)
			if not owner.components.skilltreeupdater:IsActivated("wormwood_allegiance_lunar_plant_gear_1") then
				owner:RemoveTag("player_lunar_aligned")
				if owner.components.damagetyperesist then
					owner.components.damagetyperesist:RemoveResist("lunar_aligned", owner, "wormwood_allegiance_lunar")
				end
				if owner.components.damagetypebonus then
					owner.components.damagetypebonus:RemoveBonus("shadow_aligned", owner, "wormwood_allegiance_lunar")
				end
			end
		end,
		group = "allegiance1",
		tags = {"allegiance", "lunar", "lunar_favor"},
		connects = {
			"wormwood_moon_cap_eating",
			"wormwood_lunar_mutations",
		},
	},
	wormwood_moon_cap_eating = {
		title = WORMSKILLS.MOONCAP_SAVANT_TITLE, --"Mooncap eating" -> "Impeccable crops" Wild crops automatically tend themselves.
		desc = WORMSKILLS.MOONCAP_SAVANT_DESC,
		icon = "wormwood_moon_cap_eating",
		pos = {UI_LEFT - 14, UI_TOP + 60},

		group = "allegiance1",
		tags = {"allegiance", "lunar", "lunar_favor"},
	},
	wormwood_lunar_mutations = {
		title = WORMSKILLS.MUTATOR_NOVICE_TITLE,
		desc = WORMSKILLS.MUTATOR_NOVICE_DESC,
		icon = "wormwood_mutations",
		pos = {UI_LEFT + 40, UI_TOP + 60},
		group = "allegiance1",
		tags = {"allegiance", "lunar", "lunar_favor"},
	},
}

if SkillTreeDefs.SKILLTREE_DEFS["wormwood"] ~= nil then --in case another mod turns it nil beforehand (disabling skill tree)
    SkillTreeDefs.SKILLTREE_DEFS["wormwood"] = {}
    SkillTreeDefs.CreateSkillTreeFor("wormwood", skills)
    SkillTreeDefs.SKILLTREE_ORDERS["wormwood"] = ORDERS
end

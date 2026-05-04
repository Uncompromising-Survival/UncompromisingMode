local require = GLOBAL.require

--	[ 	Import Prefabs, Assets, Widgets and Util	]	--
modimport("init/init_util")
modimport("init/init_assets")
modimport("init/init_widgets")
modimport("init/minimap_icons")
modimport("init/init_compat")

--  [   Import customized shard RPC module ]    --

modimport('init/init_dynlayout')
--  [   Mock Dragonfly Spit Bait ]    --
modimport("init/init_weather/init_dragonfly_bait")

--  [  	Over Eating Nerf	     ]    --
--modimport("init/init_food/init_stuffed")
--Currently shelved due to hunger upvalue return error

-- Needs to go up here, other files will try to reference it
modimport("init/init_tuning")

--	[ 	Import Names and Descriptions	]	--
modimport("init/init_strings/init_strings")
modimport("init/init_strings/init_names")
modimport("init/init_strings/init_tooltips")--load before postinit please!
modimport("init/init_bonusdescriptors") -- doesn't contain strings

-- Character descriptions
modimport("init/init_strings/init_descriptions/generic")
modimport("init/init_strings/init_descriptions/willow")
modimport("init/init_strings/init_descriptions/wolfgang")
modimport("init/init_strings/init_descriptions/wendy")
modimport("init/init_strings/init_descriptions/wx78")
modimport("init/init_strings/init_descriptions/wickerbottom")
modimport("init/init_strings/init_descriptions/woodie")
modimport("init/init_strings/init_descriptions/wes")
modimport("init/init_strings/init_descriptions/waxwell")
modimport("init/init_strings/init_descriptions/wathgrithr")
modimport("init/init_strings/init_descriptions/webber")
modimport("init/init_strings/init_descriptions/winona")
modimport("init/init_strings/init_descriptions/wortox")
modimport("init/init_strings/init_descriptions/wormwood")
modimport("init/init_strings/init_descriptions/warly")
modimport("init/init_strings/init_descriptions/wurt")
modimport("init/init_strings/init_descriptions/walter")
modimport("init/init_strings/init_descriptions/wanda")
modimport("init/init_strings/init_descriptions/winky")
modimport("init/init_strings/init_descriptions/wathom")



--	[ 		Number Tuning and PostInits		]	--
modimport("init/init_postinit")
modimport("init/init_actions")
modimport("init/init_containers")
modimport("init/init_batterypower")
modimport("init/init_rpctrackers")
modimport("init/init_creatures/init_ediblebugs")
modimport("init/init_creatures/init_bear_trap_immune")
modimport("init/init_generatorcharging")
modimport("init/init_generatorcharging2")
modimport("init/init_inkubator_ingredients")
--	[ 	Console Commands for tests !	]	--

require("uncompromisingcommands")
modimport("scripts/uncompromisingcommands_autocomplete")

--	[ 			 User   Interface	    ]	--

if TUNING.DSTU.UI_SHOWMULTIPRODUCTS then
    modimport("init/init_showmultiproducts")
end

--	[ 				Gamemodes			]	--

local GAMEMODE_UNCOMPROMISING = 0;
local GAMEMODE_CUSTOM_SETTINGS = 2;

--if GLOBAL.GetGameModeProperty("hardcore") then
--modimport("init/init_gamemodes/init_hardcore") --TODO: Fix hardcore game mode. For now, it is a mod config below.
--end

--	[ 				Features			]	--

--if GetModConfigData("harder_monsters") then4
if GetModConfigData("horriblefood") then
    modimport("init/init_horriblefood")
end


modimport("init/init_gemology/common")
modimport("init/init_gemology/special")
modimport("init/init_gemology/misc") -- AXE Monkeys angering when you mine slimestone with geodes, lab and AG loot
modimport("init/init_gemology/trades")

--if GetModConfigData("harder_monsters") then
modimport("init/init_creatures/init_treebuffs")
modimport("init/init_creatures/init_harder_monsters")
--end

if GetModConfigData("livingtree_legacy") then
    modimport("init/init_creatures/init_treebuffs")
end

modimport("init/init_food/init_food_changes")
modimport("init/init_food/init_bird_changes")
modimport("init/init_food/init_rare_foods")
modimport("init/init_vetcurse")
modimport("init/init_bosshealth")
modimport("init/init_freezeimmunity")
modimport("init/init_electricimmunity")

--if  GetModConfigData("harder_recipes") then <-- This isn't even a config change, yet.
--modimport("init/init_recipes") -- Deprecated, keeping the file just to prevent any merge conflicts.
modimport("init/init_recipes/init_recipes")

modimport("init/init_food/init_crockpot")
modimport("init/init_food/monsterfoods")
--end

if GetModConfigData("rat_raids") then
    modimport("init/init_ratraid")
    modimport("init/init_noratcheck")
end

modimport("init/init_creatures/init_knockback")

if GetModConfigData("harder_shadows") then
    modimport("init/init_creatures/init_harder_shadows")
    modimport("postinit/prefabs/shadowcreature")
    modimport("postinit/stategraphs/SGshadowcreature")
end

--if  GetModConfigData("harder_weather") then <-- This isn't even a config change, yet.
--modimport("init/init_weather/init_acidmushroom_networking")
--modimport("init/init_weather/init_acid_rain_effects")
--modimport("init/init_weather/init_acid_rain_disease")
modimport("init/init_weather/init_harder_weather")
--modimport("init/init_weather/init_snowstorm")
modimport("init/init_weather/init_snowstorm_structures")
if GetModConfigData("smog") then
    modimport("init/init_weather/init_smog")
end
--end

if GetModConfigData("acidrain") then
    --modimport("init/init_uncompromisingshardrpc")
    modimport("init/init_weather/init_acidmushroom_networking")
    modimport("postinit/prefabs/toadstool_cap")
end

if GetModConfigData("snowstorms") then
    modimport("init/init_weather/init_snowstorm")
end

if GetModConfigData("hayfever_disable") then
	modimport("init/init_weather/init_hayfever")
	modimport("init/init_creatures/init_sneeze_hitters")

end

modimport("init/init_durability")

modimport("init/init_character_changes/willow")

modimport("init/init_character_changes/willow_bernie")

--[[if GetModConfigData("gamemode") == GAMEMODE_UNCOMPROMISING and GetModConfigData("waxwell") or
	(GetModConfigData("gamemode") == GAMEMODE_CUSTOM_SETTINGS and GetModConfigData("waxwell")) then
		modimport("init/init_character_changes/waxwell")
	end]]

--if GetModConfigData("warly") then
--modimport("init/init_character_changes/warly")
--end

if GetModConfigData("wolfgang") then
    modimport("init/init_character_changes/wolfgang")
    modimport("postinit/components/coach")
    modimport("postinit/components/mightiness")
    modimport("postinit/prefabs/skilltree_wolfgang")
    modimport("postinit/prefabs/wolfgang_whistle")
end
--modimport("init/init_character_changes/wolfgang2")
modimport("init/init_character_changes/wormwood")
--end

-- All of these are wathgrightr changes
if TUNING.DSTU.WATHGRITHR_REWORK.ENABLED then
	modimport("postinit/prefabs/skilltree_wathgrithr")
	modimport("postinit/prefabs/beefalo") -- Yes, even this one
	modimport("postinit/prefabs/battlesongs")
	modimport("postinit/components/singinginspiration")
	modimport("postinit/components/battleborn")
	modimport("postinit/widgets/inspirationbadge")
	modimport("postinit/prefabs/wathgrithr_shield")
    modimport("postinit/prefabs/spear_wathgrithr")
end

modimport("init/init_skilltreeimports")

if GetModConfigData("lifeamulet") then
    modimport("init/init_lifeamulet")
end

--if GetModConfigData("caved") == false and GetModConfigData("acidrain") then
--modimport("init/init_weather/init_overworld_toadstool")
--end

if GetModConfigData("foodregen") then
    modimport("init/init_food/init_foodregen")
end

--TODO: Add settings for each individual character after we add many changes
--if GetModConfigData("character_changes") then <-- This isn't even a config option.
modimport("init/init_character_changes/generic")
modimport("init/init_character_changes/wendy")
--if not TUNING.DSTU.UPDATE_CHECK then
modimport("init/init_character_changes/wx78")
--end
modimport("init/init_character_changes/wickerbottom")
modimport("init/init_character_changes/woodie")
modimport("init/init_character_changes/wes")
modimport("init/init_character_changes/wathgrithr")
modimport("init/init_character_changes/webber")
modimport("init/init_character_changes/winona")
modimport("init/init_character_changes/wanda")
modimport("init/init_character_changes/wortox")
modimport("init/init_character_changes/warly")
if TUNING.DSTU.WAXWELL then
    modimport("init/init_character_changes/waxwell")
end
modimport("init/init_character_changes/walter")
modimport("init/init_character_changes/wurt")
modimport("init/lagcomp_warning")

if GetModConfigData("hardcore") then
    modimport("init/init_gamemodes/init_hardcore")
end

--modimport("init/init_loadingtips")

--food stats!
if GetModConfigData("food_stats") then
    modimport("init/init_food/init_food_stats")
end

if GetModConfigData("armorrework") then
    modimport("postinit/armor_rework")
end

modimport("init/init_weather/init_ripples")
modimport("init/init_weather/init_thicket")
modimport("init/init_insightcompat")

--need too load this AFTER strings, because scripts/gemology_defs needs to and (same with above)
GLOBAL.TheMineralLogbook = require("mineral_logbook")()
GLOBAL.TheMineralLogbook:Load()
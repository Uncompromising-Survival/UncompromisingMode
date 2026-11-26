STRINGS = GLOBAL.STRINGS

local SkillTreeDefs = GLOBAL.require("prefabs/skilltree_defs")
if SkillTreeDefs.SKILLTREE_DEFS["wilson"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["wilson"].wilson_alchemy_4.desc = STRINGS.SKILLTREE.WILSON.WILSON_ALCHEMY_4_DESC .. "\nTransform 3 Monster Morsels into a Monster Meat.\nTransform a Monster Meat into 2 Monster Morsels."
end

--[[if SkillTreeDefs.SKILLTREE_DEFS["willow"] ~= nil then --Desn't work rn :( -CB
    SkillTreeDefs.SKILLTREE_DEFS["willow"].willow_attuned_lighter.desc = STRINGS.SKILLTREE.WILLOW.WILLOW_ATTUNED_LIGHTER_DESC .. " 󰀕ACan also absorb Smog."
end]]

if SkillTreeDefs.SKILLTREE_DEFS["wurt"] ~= nil then --need to do a config check for grotto later probably yeah -CB
    SkillTreeDefs.SKILLTREE_DEFS["wurt"].wurt_pathfinder.desc = STRINGS.SKILLTREE.WURT.WURT_PATHFINDER_DESC .. "\n󰀕Same applies to flooded regions."
end

if SkillTreeDefs.SKILLTREE_DEFS["woose"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["woose"].woose_ocean_2.desc = STRINGS.SKILLTREE.WOOSE.WOOSE_OCEAN_2_DESC .. "\n󰀕Also works with flooded surfaces."
end


----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------
---
-- SKILL TREES

----------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------
-- WATHOM
--------------------------------------------------------------------------
STRINGS.SKILLTREE.PANELS.ENTROPIC_ANATOMY = "Entropic Anatomy"
STRINGS.SKILLTREE.PANELS.FORGOTTEN_KNOWLEDGE = "Forgotten Knowledge"
STRINGS.SKILLTREE.PANELS.AMP_UP = "Amp Up"

STRINGS.SKILLTREE.WATHOM = {

    WATHOM_CAPSTONE_LOCK_DESC = "Only one capstone may be unlocked at a time.",
    WATHOM_THEMIND_LOCK_DESC = "Unlock 6 left-sided skills, improving Wathom's knowledge, strategy and technique.",
    WATHOM_THEBODY_LOCK_DESC = "Unlock 6 right-sided skills, improving Wathom's ruthlessness, biology, and vitality.",

    ARTIFICER_1_TITLE = "Magic Affinity",
    ARTIFICER_1_DESC = "Wathom gains greater resistance to negative sanity effects of shadow and magic equipment.",
    ARTIFICER_2_TITLE = "Self-commital Artifice",
    ARTIFICER_2_DESC = "Building some magic items while Wathom's adrenaline is above 75 puts it into his work, increasing its durability.",
    ARTIFICER_3_TITLE = "Forbidden Commitment",
    ARTIFICER_3_DESC = "Building some ancient and shadow planar items while Wathom's adrenaline is above 75 puts it into his work, increasing its durability.",
    ARTIFICER_4_TITLE = "Unstoppable",
    ARTIFICER_4_DESC = "Wathom's sanity, temperature, moisture, and movement speed may not be negatively modified while he is amped up.",

    STALKER_1_TITLE = "Second Wind",
    STALKER_1_DESC = "Standing still for a few seconds sets Wathom's adrenaline back to zero. His sanity is slightly increased based upon prior adrenaline.",
    STALKER_2_TITLE = "Ambush",
    STALKER_2_DESC = "If Wathom's adrenaline is below 50 and he is not amped up, targets that have never been attacked by Wathom or targetted Wathom take more damage.",
    STALKER_3_TITLE = "Prowl",
    STALKER_3_DESC = "If Wathom's adrenaline is below 50 and he is not amped up, most enemies cannot gain him as a target unless he is close to them.",
    STALKER_4_TITLE = "Entropy Zero",
    STALKER_4_DESC = "Amping up makes Wathom briefly incorporeal and not able to be targetted. Enemies he's previously ambushed may be ambushed again. Amp-up ends extremely quickly.",

    HYPER_1_TITLE = "Digitigrade",
    HYPER_1_DESC = "Enter a four-legged sprint at 50 Adrenaline instead of 75.",
    HYPER_2_TITLE = "Cardio",
    HYPER_2_DESC = "Running with speed items causes Wathom to gain adrenaline, up to 50. Wathom's normal adrenaline drain is halted while doing this.",
    HYPER_3_TITLE = "Hunter Leap",
    HYPER_3_DESC = "While using a speed item, barking instead causes Wathom to quickly leap. Leaping costs much less adrenaline, may be performed in quick succession, and at lower adrenaline.",
    HYPER_4_TITLE = "Entropic Meltdown",
    HYPER_4_DESC = "Many of Wathom's actions are faster while amped up.",

    RAMPAGE_1_TITLE = "Kill-to-thrill",
    RAMPAGE_1_DESC = "Creatures slain by Wathom increase his adrenaline.",
    RAMPAGE_2_TITLE = "Rampage",
    RAMPAGE_2_DESC = "Creatures Wathom crashes into at the end of his leaping strikes will be knocked back a little.",
    RAMPAGE_3_TITLE = "Bodyslam",
    RAMPAGE_3_DESC = "Damage enemies Wathom crashes into. Scales with his Adrenaline.",
    RAMPAGE_4_TITLE = "Bloodlust",
    RAMPAGE_4_DESC = "After slaying a creature while amped up, Wathom's base damage is multiplied for a single hit. If that next attack slays a creature, the multiplied base damage will be preserved and increased.",
        
    GLUTTON_1_TITLE = "Prey",
    GLUTTON_1_DESC = "Fresh meat provides Wathom adrenaline.",
    GLUTTON_2_TITLE = "Umbral Cannibalism",
    GLUTTON_2_DESC = "Wathom may consume nightmare fuel and pure horror for adrenaline, empowering his next attacks. At lower adrenaline, he gains more attacks. He may bark to expel his remaining attacks in a devastating blast.",
    GLUTTON_3_TITLE = "Regurgitation",
    GLUTTON_3_DESC = "Wathom's bark is augmented with a charged vomit attack. Consume hunger and adrenaline to empower it. Trying to vomit with little charge performs a normal bark.",
    GLUTTON_4_TITLE = "Shadow Maw",
    GLUTTON_4_DESC = "While hunger is above 100, Wathom does additional planar damage, increases weapon planar damage, and his hunger drains significantly faster.",
    
    DEVOUR_1_TITLE = "Abyssal Metabolism",
    DEVOUR_1_DESC = "Unlock the ability to eat Lichen and Monster Meat.",
    DEVOUR_2_TITLE = "Bite",
    DEVOUR_2_DESC = "Quickly bite with unarmed strikes. Finish creatures off this way to slow Wathom's hunger and recover health.",
    DEVOUR_3_TITLE = "Overpower",
    DEVOUR_3_DESC = "Biting a creature with less than 10% health remaining will finish them off.",
    DEVOUR_4_TITLE = "Undying Parody",
    DEVOUR_4_DESC = "Regenerate while amped up. If current health is full, regenerate max health. Get a little hungrier while doing so.",

    ESCALATION_AFFINITY_TITLE = "Escalate",
    ESCALATION_AFFINITY_DESC = "The darkness within you allows you to grow upon the defeat of any unique boss for the first time - gaining max health and hunger.",
    
    EXPEDITION_AFFINITY_TITLE = "Hone",
    EXPEDITION_AFFINITY_DESC = "Honing your skills with ancient and shadow planar weapons unlocks new effects imbuing Wathom's adrenaline into their forms. These are the thulecite club, pick/axe, shadow reaper, and shadow maul.",

    WATHOM_BARKMODS_ATTACKS_TITLE = "Exploit Vulnerabilities",
    WATHOM_BARKMODS_ATTACKS_DESC = "Barking causes creatures nearby to become pierced by the dark - damage that doesn't come from Wathom is increased.",

    WATHOM_BARKMODS_EFFECTS_TITLE = "Bolster Strengths",
    WATHOM_BARKMODS_EFFECTS_DESC = "Barking improves the unique stat meters of player characters near you.",

}

--------------------------------------------------------------------------
-- WIXIE
--------------------------------------------------------------------------
STRINGS.SKILLTREE.WIXIE = {
    WIXIE_TAUNT_1_TITLE = "Taunt Level I",
    WIXIE_TAUNT_1_DESC = "Taunt enemies to raise damage taken by 10%, but increase their speed 15%!",
    WIXIE_TAUNT_2_TITLE = "Taunt Bonus I",
    WIXIE_TAUNT_2_DESC = "Reduce speed increase by 5%.",
    WIXIE_TAUNT_3_TITLE = "Taunt Bonus II",
    WIXIE_TAUNT_3_DESC = "Reduce speed increase by 10%.",
    WIXIE_TAUNT_4_TITLE = "Taunt Bonus III",
    WIXIE_TAUNT_4_DESC = "Reduce speed increase by 15%.",
    WIXIE_TAUNT_5_TITLE = "Taunt Level II",
    WIXIE_TAUNT_5_DESC = "Taunt enemies longer to raise damage taken by 15%, but increase their speed 20%!",
    WIXIE_TAUNT_6_TITLE = "Taunt Level III",
    WIXIE_TAUNT_6_DESC = "Taunt enemies even longer to raise damage taken by 20%, but increase their speed 25%!",

    WIXIE_AMMOCRAFT_1_TITLE = "Ammo Crafter I",
    WIXIE_AMMOCRAFT_1_DESC = "Increase ammo crafting speed.",
    WIXIE_AMMOCRAFT_2_TITLE = "Ammo Crafter II",
    WIXIE_AMMOCRAFT_2_DESC = "Increase basic ammo crafting amount by 5.",
    WIXIE_AMMOCRAFT_3_TITLE = "Ammo Crafter III",
    WIXIE_AMMOCRAFT_3_DESC = "Increase special ammo crafting amount by 5.",

    WIXIE_SLINGSHOT_AMMO_STINGER_TITLE = "Stinger Zingers",
    WIXIE_SLINGSHOT_AMMO_STINGER_DESC = "Learn to craft Stinger Zingers: an ammo made of Stingers that sticks into enemies and deals increasing damage for each subsequent hit.",

    WIXIE_SLINGSHOT_AMMO_DREADSTONE_TITLE = "Dreadstone Pebbles",
    WIXIE_SLINGSHOT_AMMO_DREADSTONE_DESC = "Learn to craft Dread Pebbles: an ammo made of Dreadstone that knocks enemies back and has a chance of not being destroyed on impact.",

    WIXIE_SLINGSHOT_AMMO_SCRAPFEATHER_TITLE = "Shockscrap Shots",
    WIXIE_SLINGSHOT_AMMO_SCRAPFEATHER_DESC = "Learn to craft Shockscrap Shots: an ammo made of Scrap and a Saffron Feather that periodically shocks the target and nearby enemies.",

    WIXIE_SLINGSHOT_AMMO_GUNPOWDER_TITLE = "Kablooies",
    WIXIE_SLINGSHOT_AMMO_GUNPOWDER_DESC = "Learn to craft Kablooies: an ammo mostly made of Gunpowder that explodes on impact, damaging and knocking back enemies.",

    WIXIE_SHOVE_1_TITLE = "Shover I",
    WIXIE_SHOVE_1_DESC = "Increase shove distance by 10%.",
    WIXIE_SHOVE_2_TITLE = "Shover II",
    WIXIE_SHOVE_2_DESC = "Increase shove distance by 20%.",
    WIXIE_SHOVE_3_TITLE = "Shover III",
    WIXIE_SHOVE_3_DESC = "Increase shove distance by 30%.",

    WIXIE_AMMO_BAG_TITLE = "Ammo Hoarder",
    WIXIE_AMMO_BAG_DESC = "Learn how to craft an Ammo Pouch for carrying your excess ammo.",

    WIXIE_ALLEGIANCE_LOCK_1_DESC = "Learn 12 skills to unlock.",

    WIXIE_ALLEGIANCE_SHADOW_TITLE = "Nightmare Maker",
    WIXIE_ALLEGIANCE_SHADOW_DESC = "Unlock the ability to craft 'Jessie', Ickies, and Pure Horror Rounds.\nART FOR JESSIE IS UNFINISHED!!",

    WIXIE_ALLEGIANCE_LUNAR_TITLE = "Dream Invader",
    WIXIE_ALLEGIANCE_LUNAR_DESC = "Unlock the ability to craft 'Claire', Brightshade Husk Rounds, and Pure Brilliance Rounds.\nART FOR CLAIRE IS UNFINISHED!!",
}


--------------------------------------------------------------------------
-- WIGFRID
--------------------------------------------------------------------------
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_SONGS_REVIVEWARRIOR_LOCK_DESC = "Have no Shadow Allegiance."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_SONGS_CONTAINER_LOCK_DESC = "Have no Shadow Allegiance."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_SONGS_INSTANTSONG_CD_LOCK_DESC = "Have no Shadow Allegiance."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_LOCK_DESC = "Have no Shadow Allegiance."

STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_1_TITLE = "Sturdy Spear I"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_1_DESC = "Combat Spears are 10% more durable when used by Wigfrid."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_2_TITLE = "Sturdy Spear II"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_2_DESC = "Combat Spears are 20% more durable when used by Wigfrid."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_3_DESC = "Learn to craft the Elding Spear: an electrical weapon that does more damage to wet targets.\nIt can be recharged like other UM Electrical Weapons."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_4_DESC = "The Elding Spear can perform a special attack."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SPEAR_5_DESC = "Upgrade the Elding Spear using Restrained Static to deal +20 Planar Damage."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_HELMET_1_DESC = "Battle Helms are 10% more durable when worn by Wigfrid."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_HELMET_2_DESC = "Battle Helms are 20% more durable when worn by Wigfrid."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_HELMET_5_DESC = "Fighting will repair the Commander's Helm no matter your health.\nThis effect ignores your lifeasteal multipliers."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_1_DESC = "Learn to craft the Battle Rönd.\nBlocking attacks will consume durability by 10% of the damage taken."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_2_TITLE = "Dread Rönd"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_2_DESC = "Learn to craft the Dread Rönd: a planar weapon that restores durability over time at the cost of your sanity."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ARSENAL_SHIELD_3_DESC = "Blocking adds the absorbed damage to the next attack, up to 100."

STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_1_DESC = "Beefalos will be domesticated 15% faster and ridden 30% longer."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_2_TITLE = "Noble Mount III"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_2_DESC = "Riding a beefalo will make your inspiration slowly rise until it reaches the halfway mark."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_3_TITLE = "Noble Mount II"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_3_DESC = "Wigfrid's damage multiplier applies to beefalos."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_BEEFALO_SADDLE_DESC = "Learn to craft a new Beefalo Saddle that protects your Beefalo. \nHas higher damage."

STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_LOCK_1_DESC = "Have no skills learned to unlock.\nAffinity can only be chosen as the first pick."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_SHADOW_TITLE = "Shadow Huntress"
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_SHADOW_DESC = "Combat sustain and damage resistance are greatly increased.\n Shadow item sanity drain is halved.\n Battle Calls are no longer available."
STRINGS.SKILLTREE.WATHGRITHR.WATHGRITHR_ALLEGIANCE_LUNAR_DESC = "Battle Calls have additional effects.\n Combat sustain is removed."
--------------------------------------------------------------------------
-- WOLFGANG
--------------------------------------------------------------------------
STRINGS.CHARACTERS.WOLFGANG.NEED_MORE_MIGHTINESS = "Mighty muscles must rest!"
STRINGS.CHARACTERS.WOLFGANG.NEED_MORE_SANITY = "Is too scary!"

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_1_TITLE = "Mighty Work I"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_2_TITLE = "Mighty Work II"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_3_TITLE = "Mighty Work III"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_4_TITLE = "Mighty Work IV"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_EXPERT_TITLE = "Mighty Work Expert"

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_1_DESC = "Cost to one-shot while working decreased 17%."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_2_DESC = "Cost to one-shot while working decreased 33%."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_3_DESC = "Cost to one-shot while working decreased 50%."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_4_DESC = "Cost to one-shot while working decreased 67%."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_CRITWORK_EXPERT_DESC = "Cost to one-shot while working decreased 75%.\nYou can break harder materials by forcing tools beyond their limit while mighty."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_COACH_DESC = "Learn to craft a Coaching Whistle.\nWhile coaching, Normal or Mighty Wolfgang will boost followers' damage."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_TITLE = "Leg Day"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_2_TITLE = "Leg Day II"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_3_TITLE = "Leg Day III"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_4_TITLE = "Leg Day IV"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_EXPERT_TITLE = "Leg Day Expert"

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_DESC = "Cost to leap is reduced by 10%, and landing on an enemy will cause damage."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_2_DESC = "Cost to leap is reduced by 20%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_3_DESC = "Cost to leap is reduced by 30%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_4_DESC = "Cost to leap is reduced by 40%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_LEGS_EXPERT_DESC = "Cost to leap is reduced by 50%, the cooldown is halved, and you can leap carrying heavy objects for more damage and a larger area."


STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_1_DESC             = "You can now gain mightiness up to 110."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_2_DESC             = "You can now gain mightiness up to 120."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_3_DESC             = "You can now gain mightiness up to 130."
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_4_DESC             = "You can now gain mightiness up to 140."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_5_TITLE            = "Push the Limits Expert"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_GYM_OVERBUFF_5_DESC             = "You can now gain mightiness up to 150, and you gain twice as much mightiness from using the gym."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_1_TITLE          = "Mighty Strikes I"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_2_TITLE          = "Mighty Strikes II"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_3_TITLE          = "Mighty Strikes III"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_4_TITLE          = "Mighty Strikes IV"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_5_TITLE          = "Mighty Strikes V"

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_1_DESC           = "Cost of Mighty Strikes decreases by 10%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_2_DESC           = "Cost of Mighty Strikes decreases by 20%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_3_DESC           = "Cost of Mighty Strikes decreases by 30%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_4_DESC           = "Cost of Mighty Strikes decreases by 40%"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_MIGHTY_STRIKES_5_DESC           = "Cost of Mighty Strikes decreases by 50%"

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_SHADOW_TITLE         = "Faustian Bargain"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_SHADOW_DESC          = "The Queen will reward your loyalty with devastating strength.\nYou will now always be mighty and with only 1.5x hunger rate, but your body becomes more fragile."

STRINGS.SKILLTREE.ALLEGIANCE_LOCK_SHADOW_DESC                       = "Master your shadow-fueled strength, but locks other masteries if chosen."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_SHADOW_MASTERY_TITLE = "Shadow Mastery"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_SHADOW_MASTERY_DESC  = "Your base damage is lower, but increases as you land hits, leap, and do mighty work without being hit yourself."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_LUNAR_TITLE          = "Monstrous Growth"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_LUNAR_DESC           = "The Cryptic Founder will reward your curiosity with lunar energy causing monstrous growth.\nYou gain an alternative mighty form with a dusting of fish scales and improved sailing and fishing capabilities."

STRINGS.SKILLTREE.ALLEGIANCE_LOCK_LUNAR_DESC                        = "Master your overgrown hunger, but locks other masteries if chosen."

STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_LUNAR_MASTERY_TITLE  = "Lunar Mastery"
STRINGS.SKILLTREE.WOLFGANG.WOLFGANG_ALLEGIANCE_LUNAR_MASTERY_DESC   = "Having insufficient mightiness will drain hunger instead.\nLeaping will create ice platforms on water.\nYou are immune to accursed trinkets."

STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_MONSTERTONORMAL                = "Wolfgang feel tiny now."
STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_NORMALTOMONSTER                = "The sea calls to Wolfgang!"
STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_IGNOREDTRINKETCURSE            = "Puny bracelet no match for mighty scales!"

STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_WASHED_ASHORE                  = "Wolfgang glad to be back on land."
STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_FELLINTOVOID                   = "Wolfgang barely managed to grab ledge!"
STRINGS.CHARACTERS.WOLFGANG.ANNOUNCE_BOAT_SINK                      = "Water is cold!"

--------------------------------------------------------------------------
-- WORTOX
--------------------------------------------------------------------------
STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_1_DESC                  = "Learn how to channel Souls into a Twintailed Heart. This creation, when held, will save the bearer's life."
STRINGS.SKILLTREE.WORTOX.WORTOX_LIFEBRINGER_2_DESC                  = "Twintailed Heart releases its Souls when it saves the bearer's life."

STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_3_DESC                = "Dropped Souls will instantly heal players and do a second healing wave for a lower amount after a delay."
STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_4_DESC                = "Dropped Souls will move faster towards hurt players, the second healing wave will happen quicker, and Souls are more efficient at healing multiple players. Souls will also apply the effects from Lifted Spirits I to healed targets."

STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_1_TITLE               = "Reaching Souls"
STRINGS.SKILLTREE.WORTOX.WORTOX_SOULPROTECTOR_1_DESC                = "Dropped Souls will move towards hurt players, and heal at an increased range."

STRINGS.SKILLTREE.WORTOX.WORTOX_THIEF_1_TITLE                       = "Soul Thief"
STRINGS.SKILLTREE.WORTOX.WORTOX_THIEF_1_DESC                        = "Souls are created and attracted to you from further away and will last longer."

STRINGS.SKILLTREE.WORTOX.WORTOX_NICE_LOCK_DESC                      = "Requires the skill below and 4 total Nice and/or Neutral skills to unlock."
STRINGS.SKILLTREE.WORTOX.WORTOX_NAUGHTY_LOCK_DESC                   = "Requires the skill below and 4 total Naughty and/or Neutral skills to unlock."

STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_SHADOW_2_TITLE           = "Shadow Harvester"
STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_SHADOW_2_DESC            = "The Queen has shared the secrets of weaving shadows with you, yielding better results. Souls waiting to be freed in a Soul Echo are consumed by the Shadow Reaper to unleash a powerful attack. Kills accomplished by the reaper nourish your shadows' lifeforce."

STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_SHADOW_1_TITLE           = "Shadow Weaver"
STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_SHADOW_1_DESC            = "Observing the Fuelweaver closely inspired you to weave your own creations to life. You can infuse Nightmare Fuel with Souls to try your hand at weaving shadows, but the results are inconsistent and unstable."

STRINGS.SKILLTREE.WORTOX.WORTOX_THIEF_4_DESC                        = "Souls attracted to you will repel away initially before coming towards you. Attacking while holding at least 10 Souls will periodically release a Soul from your inventory to pierce."
STRINGS.SKILLTREE.WORTOX.WORTOX_SOULJAR_3_DESC                      = "Held Souls and Souls inside of Soul Jars increases the damage of the Knabsack, up to 100 total Souls collected."

STRINGS.SKILLTREE.WORTOX.WORTOX_INCLINATION_NAUGHTY_DESC            = "Your greed stops you from overloading of Soul power, for a moment.\nEating or releasing Souls will no longer change sanity. Souls heal you for less. Increases the damage of Soul Pierce and Soul Decoy."

STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_LUNAR_1_TITLE            = "Lunar Summoner"
STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_LUNAR_1_DESC             = "Use Lune Tree Blossoms and Souls to summon allied gestalts from Alter. They are eager to carry any burden."

STRINGS.SKILLTREE.WORTOX.WORTOX_ALLEGIANCE_LUNAR_DESC               = "Your time spent tricking Alter's minions to do your bidding has increased your cunning. Lunar weaponry can be improved with a Soul Echo to do additional damage. In addition, this empowered attack will steal items off of enemies."

--------------------------------------------------------------------------
-- WALTER
--------------------------------------------------------------------------
-- For now go to init_descriptions/walter_strings

--------------------------------------------------------------------------
-- WORMWOOD
--------------------------------------------------------------------------
WORMSKILLS = STRINGS.SKILLTREE.WORMWOOD
WORMSKILLS.ORIGINATOR_TITLE                 = "Progenitor"
WORMSKILLS.ORIGINATOR_DESC                  = "Wormwood learns to craft many bushes and plants from his body."
WORMSKILLS.SYMBLOOMER_TITLE                 = "Sympathetic Bloomer"
WORMSKILLS.SYMBLOOMER_DESC                  = "While in full bloom, being near Cacti and Mushtrees will spur them to also bloom with you."
WORMSKILLS.FLYTRAP_TITLE                    = "Flytrap"
WORMSKILLS.FLYTRAP_DESC                     = "Grab insects and spores without the need of a Bug Net."
WORMSKILLS.RCROPS_1_TITLE                   = "Resilient Crops I"
WORMSKILLS.RCROPS_1_DESC                    = "Crops planted by Wormwood will not get stressed from nearby weeds or detritus."
WORMSKILLS.RCROPS_2_TITLE                   = "Resilient Crops II"
WORMSKILLS.RCROPS_2_DESC                    = "Wild crops you plant do not need to be tended."
WORMSKILLS.RCROPS_3_TITLE                   = "Impeccable Crops"
WORMSKILLS.RCROPS_3_DESC                    = "Your wild crops will never rot. However, plants left grown will eventually lose their seeds."
WORMSKILLS.LUNAR_GEAR_1_DESC                = "Fuse Bramble Husk and Brightshade Armor into Brambleshade Armor. When attacked, sometimes sieze foes in place. This is always triggered when wearing Brightshade or Brambleshade armors."
WORMSKILLS.LUNAR_GEAR_2_DESC                = "Vines appear when using brightshade or glass weaponry."
WORMSKILLS.BLOOMING_OVERHEATPROTECTION_DESC = "Gain increased wetness and overheating protection while in full bloom."
WORMSKILLS.BLOOMING_PHOTOSYNTHESIS_TITLE    = "Improved Photosynthesis"
WORMSKILLS.BLOOMING_PHOTOSYNTHESIS_DESC     = "Continue naturally blooming into Summer."
WORMSKILLS.BLOOMING_SPEED1_DESC             = "During full bloom move 5% faster while above 90% health."
WORMSKILLS.BLOOMING_SPEED2_DESC             = "During full bloom move 5% faster while above 80% health."
WORMSKILLS.BLOOMING_MAX_UPGRADE_DESC        = "Fertilization of Wormwood is boosted by 30%.\nReach full bloom much quicker."
WORMSKILLS.PRICK_ADEPT_TITLE                = "Prick Adept"
WORMSKILLS.PRICK_ADEPT_DESC                 = "Even without a Bramble Husk, Wormwood can safely pick and traverse most prickly plants."
WORMSKILLS.BLOOMING_TRAPBRAMBLE_DESC        = "Bramble Traps spread thorns over a larger area. Reset nearby Bramble Traps while in full bloom."
WORMSKILLS.ARMOR_BRAMBLEBURST_TITLE         = "Bramble Burst"
WORMSKILLS.ARMOR_BRAMBLEBURST_DESC          = "Bramble Husk triggers a second time after a short delay if the user is attacked."
WORMSKILLS.MUSHMAD_TITLE                    = "Mushroom Madness"
WORMSKILLS.MUSHMAD_DESC                     = "Mushrooms planted in a Mushroom Planter grow much faster and produce a higher yield. Learn how to plant Mushtrees for easier access to their spores."
WORMSKILLS.EQEX_TITLE                       = "Equivalent Exchange"
WORMSKILLS.EQEX_DESC                        = "Transmute seeds into their equivalent counterparts."
WORMSKILLS.MOONCAP_SAVANT_TITLE             = "Moon Shroom Savant"
WORMSKILLS.MOONCAP_SAVANT_DESC              = "Learn how to plant Moon Shrooms in Mushroom Planters and Lunar Mushtrees. Eat them for sleep-inducing spores. Dusk Caps react strangely when ingested."
WORMSKILLS.MUTATOR_NOVICE_TITLE             = "Mutator Novice"
WORMSKILLS.MUTATOR_NOVICE_DESC              = "Tap into your lunar roots to transform Carrots, Dragon Fruit, and Light Bulbs into sentient allies."

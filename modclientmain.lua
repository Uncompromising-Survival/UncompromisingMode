PrefabFiles = {
	"winky_none"
}

Assets = {
	Asset("ANIM", "anim/winky.zip"),
	Asset("ANIM", "anim/ghost_winky_build.zip"),
	
	Asset( "IMAGE", "bigportraits/winky.tex" ),
    Asset( "ATLAS", "bigportraits/winky.xml" ),

    Asset( "IMAGE", "bigportraits/winky_none_oval.tex" ),
    Asset( "ATLAS", "bigportraits/winky_none.xml" ),

    Asset( "IMAGE", "images/saveslot_portraits/winky.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/winky.xml" ),

    Asset( "IMAGE", "images/names_gold_winky.tex" ),
    Asset( "ATLAS", "images/names_gold_winky.xml" ),
}

local STRINGS = GLOBAL.STRINGS

STRINGS.NAMES.WINKY = "Winky"
STRINGS.SKIN_NAMES.winky_none = "Winky"
STRINGS.SKIN_DESCRIPTIONS.winky_none = "Despite the rumors, Winky bathes frequently."

STRINGS.CHARACTER_TITLES.winky = "The Vile Vermin"
STRINGS.CHARACTER_NAMES.winky = "Winky"
STRINGS.CHARACTER_DESCRIPTIONS.winky = "*Is a Rat\n*Can dig interconnected burrows\n*'Is weak, but fast'\n*Can eat horrible foods\n*Hates to lose hold of things"
STRINGS.CHARACTER_QUOTES.winky = "\"Squeak!\""
STRINGS.CHARACTER_ABOUTME.winky = "She's a rat."
STRINGS.CHARACTER_BIOS.winky = {
 { title = "Birthday", desc = "April 1" },
 { title = "Favorite Food", desc = "Powdercake" },
 { title = "Her Past...", desc = "Is yet to be revealed."},
}

STRINGS.CHARACTER_SURVIVABILITY.winky= "Stinky"

TUNING.WINKY_HEALTH = 175
TUNING.WINKY_HUNGER = 150
TUNING.WINKY_SANITY = 125

AddModCharacter("winky", "FEMALE")
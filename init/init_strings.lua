STRINGS = GLOBAL.STRINGS

-- [              DSTU Related Overrides                  ]

STRINGS.DSTU = {
    ACID_PREFIX =
    {
        NONE = "",
        GENERIC = "Corroding",
        RABBITHOLE = "",
        CLOTHING = "Eroding",
        FUEL = "Caustic",
        TOOL = "Rusting",
        FOOD = "Sour",
        POUCH = "Deteriorating",
        WETGOOP = "Toxic",
    },

}
STRINGS.SPELLS.SHADOW_MIMIC = "Shadow Mimic"

STRINGS.NAMES.WINKY = "Winky"
STRINGS.CHARACTER_TITLES.winky = "The Vile Vermin"
STRINGS.CHARACTER_NAMES.winky = "Winky"
STRINGS.CHARACTER_DESCRIPTIONS.winky = "*Is a Rat\n*Can dig interconnected burrows\n*'Is weak, but fast'\n*Can eat horrible foods\n*Hates to lose hold of things"
STRINGS.CHARACTER_QUOTES.winky = "\"Squeak!\""

STRINGS.SKIN_NAMES.winky_none = "Winky"

STRINGS.SKIN_QUOTES.winky_none = "\"Squeak!\""
STRINGS.SKIN_DESCRIPTIONS.winky_none = "She's a fan of shiny things."

STRINGS.ACTIONS.CREATE_BURROW = "Make Burrow"
STRINGS.ACTIONS.ACTIVATE.RECRUITRAT = "Recruit A Rat"

STRINGS.ACTIONS.UM_ACTIVATABLE_ITEM = {
            GENERIC = "Use",
            PONDER = "Ponder",
            MORPH = "Morph",
        }

STRINGS.ACTIONS.TURNOFF.HARPOON = "Break Reel"
STRINGS.ACTIONS.ACTIVATE.HARPOON = "Reel"
STRINGS.ACTIONS.CASTSPELL.HARPOON = "Throw Magnerang"
STRINGS.ACTIONS.CHARGE_POWERCELL = "Charge Equipment"
STRINGS.ACTIONS.DEPLOY.POWERCELL = "Charge Equipment"
STRINGS.ACTIONS.UPGRADE.SLUDGE_CORK = "Plug"
STRINGS.ACTIONS.UPGRADE.SOUL_LUNAR = "Offer"
STRINGS.ACTIONS.UPGRADE.SOUL = "Weave"
STRINGS.ACTIONS.USESPELLBOOK.TELESTAFF = "Select Focus"
STRINGS.ACTIONS.WX_CHARGEFROMPOWERCELL = "Charge"
STRINGS.ACTIONS.CASTSPELL.CHARLES_CHARGE = "Charge!"
STRINGS.ACTIONS.CASTSPELL.SLINGSHOT = "Shoot"
STRINGS.ACTIONS.CASTSPELL.WIXIE_SLING = "Sling"
STRINGS.ACTIONS.ACTIVATE.UM_TORNADOTRACKER = "Locate Tornadoes -"
STRINGS.ACTIONS.CASTAOE.WATHGRITHR_SHIELD_DREADSTONE = STRINGS.ACTIONS.CASTAOE.WATHGRITHR_SHIELD
STRINGS.UI.HUD.UM_VETSKULL_GENERIC = "Veteran's Curse:\n - Receive more damage when attacked.\n - Hunger drains faster.\n - Health and Sanity from foods is applied *slowly* over time."
STRINGS.UI.HUD.UM_VETSKULL = {
    DEFAULT = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WILLOW = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WilloWIP
    WOLFGANG = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WENDY = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WX78 = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WICKERBOTTOM = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WOODIE = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WES = "Veteran's Curse:\n - Wes Must Die.",
    WAXWELL = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WATHGRITHR = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WEBBER = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WINONA = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WARLY = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WORTOX = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
    WORMWOOD = "Veteran's Curse:\n - Health from healing items is applied *slowly* over time.\n - Taking damage interrupts the healing.",
	WURT = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --Wurt to Womp transition, real. Soon.
	WALTER = "Veteran's Curse:\n - Damage taken also applies a maximum Sanity penalty.\n - The penalty heals itself after a while without getting hurt.",
	WANDA = "Veteran's Curse:\n - Age faster when damaged.\n - Hunger drains faster.\n - Sanity from foods is applied *slowly* over time.",
	WINKY = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
	WATHOM = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
	WIXIE = STRINGS.UI.HUD.UM_VETSKULL_GENERIC, --WIP
}
STRINGS.UI.HUD.UM_VETSKULL_VETSITEMS = "\n - Be able to wield cursed items, dropped by certain bosses."
STRINGS.VETS_WIDGET_WES = "Veteran's Curse:\n - Wes Must Die."
STRINGS.VETS_WIDGET_WANDA = "Veteran's Curse:\n - Age faster when damaged.\n - Hunger drains faster.\n - Sanity from foods is applied *slowly* over time.\n - Gain the ability to wield cursed items, dropped by certain bosses."
STRINGS.VETS_WIDGET = "You've been afflicted by the Veteran's Curse.\nPress \"I\" or the icon next to your equipment slots\nto see the effects in your \"Inspect Self\" menu.\nClick this to hide this icon."
STRINGS.VETS_CONFIRMED_TITLE = "You Made Your Choice."
STRINGS.VETS_CONFIRMED = "Now you must live with the consequences..."
STRINGS.VETS_TITLE = "The Veterans Curse."
STRINGS.VETS = "You're about to be afflicted with a crippling curse.\nThe Constant will treat you more harshly,\nhowever fortune favors the bold (or foolish)! \n \nTouch the skull again to seal your fate."
STRINGS.VETS_OK = "Ok"

STRINGS.UI.CRAFTING.NEEDSVETERANSHRINE_ONE = "Requires something... darker."
STRINGS.UI.CRAFTING.RECIPEACTION.UM_WAXWELL_SUMMON = "Summon"

STRINGS.VETSKULL_TITLE = "The Veterans Skull"
STRINGS.VETSKULL = {
    --DEFAULT = "Return this skull to the Veterans Shrine\nYou will gain access to new items, but will be cursed.\nCurse Effects:\n-\n",
    DEFAULT = "Return this skull to the Veterans Shrine\nCurse Effects:",
    WILSON = "Deaths increase stat loss by 10%, up to 50%.",
    WALTER = "Damage taken in combat increased by 50%\nThis damage applies over time, and can be cured with healing items.",
    WORTOX = "Slain enemies will drop explosive souls.\nThese souls will deal damage based on the slain enemies max health.",
    MAXWELL = "Chasing stalking never stopping always hunting.",
    WILLOW = "...?",
    WARLY = "Hunger gained past your maximum will make you drowsy.",
    WINKY = "Dropping or breaking items will cause you pain.\nWait that sucks.",
    WICKERBOTTOM = "Going without sleep for long periods of time will\neventually cause you to pass out.",
    WIXIE = "Hostile Krampii may spawn when killing innocent creatures.",
    WOODIE = "...?",
    WOLFGANG = "Hunger is regained over time.\nFalling below 50% hunger will start to incur damage penalties.\nFalling below 30% will start to incur speed penalties.",
    WANDA = "Nightmare creatures have a chance to spawn from slain enemies.\nChance is based on missing sanity.",
    WATHGRITHR = "Your enemies have a chance to be buffed up, increasing their\nsize, speed, attack range, and attack speed.",
    WES = "Your stats and clock are hidden from you.\nLow health will be indicated by a heartbeat.\nDusk announcements are restored.",
    WENDY = "Health can never go higher than your current sanity percentage.",
}

STRINGS.PACTSWORN_TITLE = "The Shadow Pact"
STRINGS.PACTSWORN_TEXT = "A new path lies before you, if you give up the Codex Umbra. You will lose your spells and take 25% more damage, but you will gain a summonable sword, armor, and true classic shadows.\nThis cannot be undone."

STRINGS.PIG_REMEMBER_THREAT = { "REMEMBER YOU!", "YOU HURT US!", "YOU MEAN!" }
STRINGS.PIG_GUARD_PIGKING_TALK_LOOKATWILSON = { "NO SMASH HOUSES", "US WATCHING YOU", "BE GOOD HERE", "WATCHING YOU" }
STRINGS.PIG_GUARD_PIGKING_TALK_LOOKATWILSON_NIGHT = { "KING SLEEPING, YOU GO NOW", "YOU LEAVE NOW",
    "STAY AND WE GET MEAN", "KING NEED SLEEP, GO AWAY" }
STRINGS.PIG_GUARD_PIGKING_TALK_LOOKATWILSON_EVENING = { "KING BED TIME SOON, YOU GO NOW", "NO DISTURB KING SLEEP",
    "KING NEEDS BEAUTY SLEEP, GO", "NIGHT SOON, YOU LEAVE NOW" }
STRINGS.PIG_GUARD_PIGKING_TALK_LOOKATWILSON_FRIEND = { "KING SAY PROTECT", "PROTECT YOU", "WHERE MONSTERS?", "PROTECT!",
    "PROTECT KING!", "PROTECT FRIEND!" }

-- Hey look! I actually did something! -Canis
STRINGS.CHARACTER_DESCRIPTIONS.willow = STRINGS.CHARACTER_DESCRIPTIONS.willow .. "\n󰀕Can ignite things in the cold"
if GetModConfigData("bernie_buffs") then
    STRINGS.CHARACTER_DESCRIPTIONS.willow = STRINGS.CHARACTER_DESCRIPTIONS.willow .. "\n󰀕Hugging Bernie keeps the shadows at bay"
end
if GetModConfigData("wxless") then
    STRINGS.CHARACTER_DESCRIPTIONS.wx78 = STRINGS.CHARACTER_DESCRIPTIONS.wx78 .. "\n󰀕Circuits drain charge and degrade overtime\n󰀕Powers all components until last charge\n󰀕Resting and eating refills internal batteries"
end
if GetModConfigData("wx78") then
    STRINGS.CHARACTER_DESCRIPTIONS.wx78 = STRINGS.CHARACTER_DESCRIPTIONS.wx78 .. "\n󰀕Systems are not repaired via lightning"
end
if GetModConfigData("wickerbottom") then
    STRINGS.CHARACTER_DESCRIPTIONS.wickerbottom = STRINGS.CHARACTER_DESCRIPTIONS.wickerbottom ..
        "\n󰀕Reading requires brainpower"
end
STRINGS.CHARACTER_DESCRIPTIONS.wes = STRINGS.CHARACTER_DESCRIPTIONS.wes .. "\n󰀕Expanded inner dialogue" --"\n󰀕Pengulls are fond of mimes"
if TUNING.DSTU.WAXWELL then
    STRINGS.CHARACTER_DESCRIPTIONS.waxwell = STRINGS.CHARACTER_DESCRIPTIONS.waxwell .. "\n󰀕Can learn to summon shadowy gear" --"\n󰀕Can make a pact to regain his old tricks"
end
if GetModConfigData("wolfgang") then
    STRINGS.CHARACTER_DESCRIPTIONS.wolfgang = "󰀕Stronger on a full belly\n󰀕Grows mightier when fed and calm\n󰀕Is quite the showboat\n*Is afraid of monsters and the dark"
end
if GetModConfigData("warly_food_taste_") then
    STRINGS.CHARACTER_DESCRIPTIONS.warly = STRINGS.CHARACTER_DESCRIPTIONS.warly ..
        "\n󰀕Absorbs nutrients better...\n󰀕But prefers more variety"
end
if GetModConfigData("warly_butcher_") then
    STRINGS.CHARACTER_DESCRIPTIONS.warly = STRINGS.CHARACTER_DESCRIPTIONS.warly ..
        "\n󰀕Is a certified butcher"
end
if GetModConfigData("winonaworker") then
    STRINGS.CHARACTER_DESCRIPTIONS.winona = STRINGS.CHARACTER_DESCRIPTIONS.winona .. "\n󰀕Works hard until lunch"
end
if GetModConfigData("wortox") then
    STRINGS.CHARACTER_DESCRIPTIONS.wortox = STRINGS.CHARACTER_DESCRIPTIONS.wortox .. "\n󰀕Souls take time to heal\n󰀕Some weak creatures have no soul"
end
if GetModConfigData("wigfrid") then
    STRINGS.CHARACTER_DESCRIPTIONS.wathgrithr = STRINGS.CHARACTER_DESCRIPTIONS.wathgrithr .. "\n󰀕Combat is less sustaining"
end
if TUNING.DSTU.WORMWOOD_CONFIG_FIRE then
    STRINGS.CHARACTER_DESCRIPTIONS.wormwood = STRINGS.CHARACTER_DESCRIPTIONS.wormwood .. "\n󰀕Is dangerously flammable"
end

--I also did something! I love mod compatibility :) -CarlosBraw
if GLOBAL.KnownModIndex:IsModEnabled("workshop-2010472942") then
    STRINGS.CHARACTER_DESCRIPTIONS.wragonfly = STRINGS.CHARACTER_DESCRIPTIONS.wragonfly .. "\n󰀕Can breath in summer's smog"
    STRINGS.CHARACTER_DESCRIPTIONS.weerclops = STRINGS.CHARACTER_DESCRIPTIONS.weerclops .. "\n󰀕Not slowed down by winter's strong winds\n󰀕Is well accustomed to snow"
end
if GLOBAL.KnownModIndex:IsModEnabled("workshop-1847716441") then
    STRINGS.CHARACTER_DESCRIPTIONS.plaguedoctor = STRINGS.CHARACTER_DESCRIPTIONS.plaguedoctor .. "\n󰀕Mask protects against smog"
end


STRINGS.STANTON_GREET = { "Care to drink with the dead?", "How's about a drink?", "C'mon and drink with me." }
STRINGS.STANTON_GIVE = { "There ya go.", "The finest." }
STRINGS.STANTON_RULES = { "I only drink with one at a time." }
STRINGS.STANTON_GLOAT = { "Ha! I knew you were soft.", "Ha! You lose!" }

STRINGS.STANTON_POET1 = { "When it's six to midnight and the boney hand of death is nigh." }
STRINGS.STANTON_POET2 = { "You better drink your drink and shut your mouth." }
STRINGS.STANTON_POET3 = { "If you draw against his hand, you can never win." }
STRINGS.STANTON_POET4 = { "Go ahead… drink with the living dead." }
STRINGS.STANTON_POET5 = { "Drink with the living dead." }


STRINGS.UI.COOKBOOK.UM_BEEFALOWINGS = "Prevents Knockback"
STRINGS.UI.COOKBOOK.UM_CALIFORNIAKING = "Immunity to Hayfever"
STRINGS.UI.COOKBOOK.UM_LICELOAF = "Moderate Hayfever Relief"
STRINGS.UI.COOKBOOK.UM_SEAFOODPAELLA = "Huge Hayfever Relief"
STRINGS.UI.COOKBOOK.UM_SNOTROAST = "Reduces Hunger Drain"
STRINGS.UI.COOKBOOK.UM_STUFFED_PEEPER_POPPERS = "Spawns Friendly Al-'eyes'"
STRINGS.UI.COOKBOOK.UM_THEATERCORN = "Sanity For Spectacle"
STRINGS.UI.COOKBOOK.UM_VIPERJAM = "Spawns Friendly Vipers"
STRINGS.UI.COOKBOOK.UM_ZASPBERRYPARFAIT = "Shocks Your Attackers"
STRINGS.UI.COOKBOOK.UM_RIMEWEED_SPAGETT = "Immediately Freezes Your Surroundings"
STRINGS.UI.COOKBOOK.UM_RIMEWEED_TEQUILA = "Increases Resistance to Freezing"

--TIDDLER FRIENDLY MAN STRINGS BELOW--

STRINGS.CHARACTERS.GENERIC.DESCRIBE.SPEAKER_SPECTER = "This is making me feel under the weather..."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SPEAKER_RUSTED = "This is making me feel under the weather..."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.SPEAKER_BRINE = "This is making me feel under the weather..."

for _, sound in pairs({ "talk_LP", "talk_end" }) do
    RemapSoundEvent("dontstarve/characters/tiddle_stranger/" .. sound, "tiddle_stranger/characters/tiddle_stranger/" ..
        sound)
end

STRINGS.TIDDLESTRANGER_RNE_IGNORED = { "...Guess you ain't interested.", "Nevermind, then.", "..." }
STRINGS.NAMES.TIDDLESTRANGER_RNE = "Kind Stranger"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TIDDLESTRANGER_RNE = "He says a lot of nothing."
STRINGS.CHARACTERS.WX78.DESCRIBE.TIDDLESTRANGER_RNE = "ERROR: UNKNOWN ENTITY"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.TIDDLESTRANGER_RNE = "I wonder what lies beneath that mysterious garb."
STRINGS.CHARACTERS.WAXWELL.DESCRIBE.TIDDLESTRANGER_RNE = "I don't remember that one."
STRINGS.CHARACTERS.WENDY.DESCRIBE.TIDDLESTRANGER_RNE = "A guardian angel?"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.TIDDLESTRANGER_RNE = "Who the heck are you?"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.TIDDLESTRANGER_RNE = "Is creepy strange man."
STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.TIDDLESTRANGER_RNE = "An eerie prophet!"
STRINGS.CHARACTERS.WORMWOOD.DESCRIBE.TIDDLESTRANGER_RNE = "Helpy friend"
STRINGS.CHARACTERS.WURT.DESCRIBE.TIDDLESTRANGER_RNE = "Flort. Stranger danger."
STRINGS.CHARACTERS.WARLY.DESCRIBE.TIDDLESTRANGER_RNE = "Greetings, uh... I didn't get your name?"
STRINGS.CHARACTERS.WORTOX.DESCRIBE.TIDDLESTRANGER_RNE = "Hyuyuyu! A trickster after my own heart!"
STRINGS.CHARACTERS.WINONA.DESCRIBE.TIDDLESTRANGER_RNE = "Those shoulders don't seem practical."
STRINGS.CHARACTERS.WOODIE.DESCRIBE.TIDDLESTRANGER_RNE = "I like your funny words, magic man."

STRINGS.TIDDLESTRANGER_RNE_GREETING = { "Hey there, friend!", "Oh, hello there!", "Hey, friend!" }
STRINGS.TIDDLESTRANGER_RNE_FAREWELL = {
    {
        "I spent a lot of time making these.",
        "Finding all the materials wasn't easy.",
        "...",
        "So don't go losing it.",
    },
    {
        "I'd suggest you keep a high flame going.",
        "There's some dangerous stuff lurking in the dark.",
        "...",
        "Not sure where it all came from, to be honest.",
    },
    {
        "Nights ain't as comfy as they used to be.",
        "Strange occurences, creatures in the dark...",
        "I'd keep my eyes and ears open, and a light by my side if I were you.",
    },
}
STRINGS.TIDDLESTRANGER_RNE_ENDSPEECH = { "Try it on, and find out.",
    "I think it would look nice on you, so just try it on!", "No strings attached, just wear it!" }

STRINGS.TIDDLESTRANGER_RNE_SCENARIO = {
    METEOR = {
        "Stars sure are nice tonight.", "How 'bout a closer look?"
    },
    SPIDERS = {
        "How 'bout a little game?", "I got a nice little prize in it for ya.", "The rules are simple:",
        "You beat my pet, you get the prize!"
    },
    LIGHT = {
        "Allow me to shed some light on the situation!"
    },
}

STRINGS.TIDDLESTRANGER_RNE_SCENARIO_END = {
    METEOR = {
        "Woops! Too close.", "Sorry 'bout that."
    },
    SPIDERS = {
        "Oh. Ya did it.", "Well! Fair's fair.", "Hope ya enjoy it!", "Now I need to find a new pet..."
    },
    LIGHT = {
        "That's the best I got.", "Hope that helped, now."
    },
}

STRINGS.TIDDLESTRANGER_RNE_SPIDERWON = { "Guess ya didn't have it in ya after all.", "Oops. I didn't think ya'd DIE.",
    "Now ain't that a darn shame." }

STRINGS.TIDDLESTRANGER_RNE_DEFAULT = {
    {
        "I've been practicing arts and crafts lately.",
        "I thought I'd make ya something...Nice.",
        "What do they do?",
        "...",
    },
    {
        "You look like you could use a new face!",
        "Lucky for you, I have several!",
        "...Masks, that is.",
        "What's their purpose?",
        "...",
    },
    {
        "Ever wanted to start a collection?",
        "Well I have just the thing!",
        "Hand crafted masks! No curses, I promise.",
        "...",
    },
}

STRINGS.TIDDLESTRANGER_RNE_BANTER = {
    {
        "I should be on that throne right now... oh, the things I'd make."
    },
    {
        "Don't ya have... things you need to do, friend?",
    },
    {
        "I appreciate the company and all, but this is gettin' a bit awkward.",
    },
    {
        "You just gonna stand there all day, friend?",
    },
    {
        "You just gonna stand there all day, friend?",
    },
    {
        "You're still here. Why are you still here?",
    },
    {
        "Wanna hear a joke?",
        "...",
        "Ah...I forgot what it was.",
    },
    {
        "Me? I'm quite old, ya'know.",
        "Not, like, ancient or anything. But... old.",
    },
    {
        "So... ya like jazz?",
        "Been too long since I seen a gig.",
    },
    {
        "I know many things, ya'know. Learned so much.",
        "Understand how this world works...",
        "...but I can't understand why you're still here.",
    },
    {
        "Pst... can I interest you in some forbidden knowledge?",
        "I'm just kiddin' ya. That's MY knowledge.",
    },
}

STRINGS.TIDDLESTRANGER_RNE_ADVICE = {
    BUSY = {
        "Oh. I see you're busy.",
        "I'll just come back later.",
    },
    HARBINGERS = {
        "You're doin' great!",
        "But this sickness ain't about to give up so easily.",
        "Keep an ear out, ya hear me?",
        "Somethin's comin' your way...",
    },
    KILLED = {
        "You did it! You put them pests right in their place!",
        "But they'll be back...",
        "I'm sure you can handle 'em, though.",
        "Anyways, I just came around to congratulate you."
    },
    MEDICINE = {
        "You feeling alright? You don't look so good...",
        "You'd better get that treated!",
        "I heard somethin' about some misty swamp.",
        "Fellas lookin' for a cure I think.",
        "Maybe he could help...",
    },
    REVIVER = {
        "Look at you!",
        "A real asset to the team!",
        "They'd all be dead without you, ya'know.",
        "Keep up the good work!",
        "And don't let no one tell you what's what.",
        "You're better than those slackers."
    },
    MURDERER = {
        "You're rackin' up quite the headcount!",
        "I ain't judgin' none. Honest.",
        "Strong feasting on the weak;",
        "Dog eat dog world;",
        "Survival of the fittest;",
        "All that good stuff."
    },
    CUREFOUND = {
        "I hear ya found the cure!",
        "Ain't that just dandy.",
        "Shame it's in such limited supply, huh?",
        "I hear there's another source...",
    },
}

STRINGS.STALKER_ATRIUM_WATHOM_BATTLECRY = {
    "Don't repeat our history, fool.",
    "You will doom yourself as we did.",
    "Retreat while you're still whole, mimic.",
    "Our mistakes shouldn't be repeated.",
    "Let the dead stay buried.",
    "I pity you, mimic.",
}

STRINGS.UM_VETERANSHRINE = {
    VETERANCURSETAUNT = {
        "COME... CLOSER...",
        "THE... CHALLENGE...",
        "CURSE... WAY OUT..."
    },
    VETERANCURSED = {
        "NO... GOING... BACK...",
        "PACT... MADE...",
        "BRING... SKULLS..."
    },
    NOT_VETERANCURSED = {
        "NOT... AFFLICTED..."
    },
    NOT_VETERANSKULL = {
        "NOT... DESIRED..."
    },
    VETSKULL_COMMENT = {
        WILSON = "A CURIOUS MIND... DESTINED FOR DANGER",
        WALTER = "A KIND SOUL... BUT TOO CURIOUS... LIKE 'THEY' WERE",
        WORTOX = "TOO BREAK FREE... OF ONES NATURE... A RARE THING",
        MAXWELL = "THINKS HIMSELF A KING... HE WAS ONLY EVER A PAWN",
        WILLOW = "CAREFREE... CARELESS... MAY SHE FIND PEACE",
        WARLY = "ALWAYS HUNGRY FOR MORE... NEVER SATED",
        WINKY = "THE RESULT... OF THEIR MEDDLING...",
        WICKERBOTTOM = "TOO EAGER... TO TAMPER... WITH DARK FORCES",
        WIXIE = "DARKNESS INSIDE HER... THEIR FAVORITE FUEL SOURCE",
        WOODIE = "TAMPERED ONCE... WITH OUR INFLUENCES",
        WOLFGANG = "SEEKS STRENGTH... WHERE WEAKNESS IS FED UPON",
        WANDA = "ALWAYS RUNNING... HER TIME RUNS SHORT",
        WATHGRITHR = "THEY FUEL HER DELUSIONS... SHE FUELS THEIR DESITRES",
        WES = "SEEKS STRENGTH... WHERE WEAKNESS IS FED UPON",
        WENDY = "TO BRING BACK THE DEAD... A DANGEROUS PROSPECT",

        WORMWOOD = "TO BRING BACK THE DEAD... A DANGEROUS PROSPECT",
        WX78 = "A NEW SHELL... WITH NO SOUL TRANSFERRED",
    },
}

STRINGS.UM_VOXOLOPHONE = {
    SHADOW_WARNING = {
        HECKLER = {
            "AN AUDIENCE... DISAPPROVING... VENEMOUS TONGUE... (Heckler has appeared)",
            "THEY SIT... IN DARKNESS... VILE SPIT. (Heckler has appeared)",
            "SLINKING... SLURPING... SPITTING. (Heckler has appeared)",
        },
        MINDWEAVER = {
            "LURKING... WAITING TO STRIKE... WATCH YOUR HEAD. (Mindweaver has appeared)",
            "HIDING... ABOVE... WATCH YOUR SHADOW. (Mindweaver has appeared)",
            "UNSEEN... WAITING... LISTEN FOR ITS WARNING. (Mindweaver has appeared)",
        },
        HIVE = { --unused probably leech hive
            "VOLATILE... MOTHER... KEEP YOUR DISTANCE.",
            "INCUBATING... WANDERING... WAITING TO HATCH.",
            "DEFENSLESS... CORNERED... WILL BE YOUR END.",
        },
        BREAKER = { --unused probably charger
            "THE FIRST LINE... HEADSTRONG... BREAKING.",
            "WORKING... CRACKING... DESTRUCTION.",
            "THEY REMEMBER... SEEKING... MINING.",
        },
        GRABBY = {
            "GRASPING... CHASING... DRAGGED INTO DARKNESS. (Grabby hand has appeared)",
            "A HUNDRED HANDS... SEEKING LIFE. (Grabby hand has appeared)",
            "FINGERS... BONES... OUTSTRETCHED, WANTING. (Grabby hand has appeared)",
        },
        VORTEX = {
            "CONSUMING... FORCE... KEEP AWAY. (Vortex has appeared)",
            "SHADOWY INFLUENCE... A PORTAL... INTO DARKNESS. (Vortex has appeared)",
            "BEWARE... THEIR FORCE... GROWING, CONSUMING. (Vortex has appeared)",
        },
        HAUNT = {
            "LISTEN... CLOSELY... INVISIBLE THREAT. (Haunt has appeared)",
            "HIDING... WAITING... SEEK IT OUT. (Haunt has appeared)",
            "HAUNTING... LINGERING... CHASE IT OUT. (Haunt has appeared)",
        },
        FUELSEEKER = {
            "THEY ARE HUNGRY... THEY FEAST ON LIGHT. (Fuelseeker has appeared)",
            "CHASING AWAY... WHAT LIGHT REMAINS... (Fuelseeker has appeared)",
            "THEY... CONSUME... DO NOT LET THEM. (Fuelseeker has appeared)",
        },
        NIGHTCRAWLER = {
            "GNAWING THINGS... PROTECT THE MACHINE. (Nightcrwaler has appeared)",
            "THEY SEEK SILENCE... MY VOICE, CUT OFF. (Nightcrwaler has appeared)",
            "GUARD THE MACHINE... PESTS ARE CLOSE. (Nightcrwaler has appeared)",
        },
        UM_LEECHES = {
            "THE LIGHT... THEY FEAR... KEEP IT LIT. (Leech has appeared)",
            "THEY FEAST... IN DARKNESS... KEEP THE LIGHT CLOSE. (Leech has appeared)",
            "AFRAID... THEY SWARM... LIGHT REPULSES THEM. (Leech has appeared)",
        },
        HANDS = {
            "THEY SEEK... THEY TAKE... CHASE THEM BACK. (Night hand has appeared)",
            "BITE THE HAND... THAT FEEDS. (Night hand has appeared)",
            "STRETCHING OUT... SEEKING FLAME... STOMP THEM OUT. (Night hand has appeared)",
        },
        NIGHTMARECREATURE = {
            "A LOWLY CREATURE... CORRUPTED... FIGHT THEM OFF. (Generic shadow has appeared)",
            "A LOYAL SOLDIER... ONE OF MANY... FAMILIAR. (Generic shadow has appeared)",
            "ANOTHER SERVANT... A WARPED VISAGE... DISPATCH. (Generic shadow has appeared)",
        },
        SHADOWCHARACTER = {
            "THEY TAKE YOUR IMAGE... LEARN YOUR TRICKS. (Shadow character has appeared)",
            "THEY STUDY YOU WELL... AND MOCK YOUR VISAGE. (Shadow character has appeared)",
            "THEY MAKE YOU DANCE... LIKE A PUPPET ON A STRING. (Shadow character has appeared)",
        },
    },
    SPAWN_TALK = {
        "F##LOW... MY... V##CE...",
        "F#ND... #HE... MA#HINE...",
        "CANN#T... SPE#K... LO#G",
    },
    NEWMOON_WARNING = {
        "THE... LIGHT... FIND... LIGHT",
        "LITTLE... TIME... REMAINING...",
        "BEWARE... THE... DARK",
        "KEEP... THE... MACHINE... CLOSE",
    },
}

STRINGS.ACTIONS.SET_CUSTOM_NAME = "Set Custom Name"

local SkillTreeDefs = GLOBAL.require("prefabs/skilltree_defs")
if SkillTreeDefs.SKILLTREE_DEFS["wilson"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["wilson"].wilson_alchemy_4.desc = "Transform 3 Morsels into a Meat. Transform a Meat into 2 Morsels.\nTransform 3 Monster Morsels into a Monster Meat.\nTransform a Monster Meat into 2 Monster Morsels."
end

if SkillTreeDefs.SKILLTREE_DEFS["willow"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["willow"].willow_attuned_lighter.desc = STRINGS.SKILLTREE.WILLOW.WILLOW_ATTUNED_LIGHTER_DESC .. " Can also absorb Smog."
end
STRINGS.UM_HOUSETAUNTS = {
    PIGMAN = {
        "GET OFF LAWN",
        "LEAVE HOUSE ALONE",
        "NO SMASH HOUSE",
        "DO NOT HIT",
        "NO KILL HOUSE",
        --"BAD MONKEY MAN",
        "NO BREAK THINGS",
        "YOU STOP THAT",
        "STOP RIGHT THERE"
    },
    BUNNYMAN = {
        "INVADER!",
        "CRIMINAL!",
        "SCUM!",
        "AGGRESSOR!",
        "NO!",
        "MINE!",
        "HOUSE!",
        "BEGONE!",
    }
}

STRINGS.UM_LOADINGTIPS = {
    AMALGAMS = "\"Whoever designed these clockwork thingamawatzits should have installed a surge protector!\" -W",
    RNES = "\"I feel like there's something watching us at night...\" - W",
    MOONMAW = "Like a moth to a flame, a Dragonfly once flew too close to the moon. But unlike Icarus, her story doesn't end there...",
    MUTATIONS = "Each Deerclops you find may be different than the last.",
    RUINS = "The Shadows are stirring, and long buried clockworks have resurfaced. Keep your wits about you.",
    CONFIGS = "Not a fan of some changes? Need a change of pace? Check out Uncompromising Mode's configuration options! Almost everything is configurable!",
    WIKI = "Lost? Confused? Hungering for knowledge? Visit Uncompromising Mode's Wiki! It's... *mostly* accurate! (Make sure to use Wiki.gg and watch out for Outdated warnings!)",
    RATS_FOODSCORE = "\"Our rations appear to be attracting unwanted attention. I should get rid of our stale food...\" - W",
    RATS_ITEMSCORE = "\"The vermin have noticed the mess around camp, I really should do a bit of Spring cleaning...\" - W",
    RATS_BURROWBONUS = "\"I've spotted a rat den where there wasn't one before, I think they are multiplying, and fast!\" - W",
    SNOWPILES = "\"The snow is accumulating here rather fast. We should dig it soon before it covers everything, or worse...\" - W",
    UNHAPPYTOMATO = "\"My tomato harvest seems to have shortened this fall, I guess they're feeling under the weather.\" - W",
    AURACLOPS = "The ice walls certain Deerclops make can be mined, and some are more brittle than others.",
    RATMASK = "\"To think like a rat, and smell like a rat, I must become a rat. Or at least, blend in really nicely with this Rat Mask.\" - W",
    WIXIE = "\"Winifred? Never heard of her! Now stop asking!\" - W",
    POCKETS = "\"I taught the others to sew some pockets into their clothing. How did these dummies ever get by without me?\" - W",
    CRAFTINGTOOLTIP = "Items with a small \"UM\" icon next to them in the crafting menu have been changed. You can mouse over the icon to get more information about the change.",
    NOCOLLISION = "Most exploitable collisions have been removed. This includes signs, statues, giant crops, shell clusters, and more.",
    MAXHPLOSS = "Freezing, overheating, starving and more can reduce max health.",
    WEATHER = "Keep an eye out during each season. Every season has something new to encounter.",
    MAXHEALTHHEALING = "Warly's Salt Spice can restore lost max health.",
    SLEEPING = "Sleeping has been considerably improved. Stats are gained faster and lost max health can be recovered from a certain threshold.",
    ALPHAGOAT = "\"Today I saw some mean lookin' goat with the herd. The kids wanted to chase them down as play, but guess the big guy took it as a threat. Better not approach them again.\" - W",
    SNOWSTORMS = "\"Board up the windows, there is definitely a storm coming!\" - W",
    OCEAN_STEERING = "Boat rudders help with steering boats, increasing turn speed and allowing the boat to make sharper turns. The Captain's Hat also further increases steering speed.",
    --HEAVYFISH = "\"That's a big one! We'll have seafood the entire season with that!\" - W",
    WILTFLY = "Hungry and weak during summer, the Dragonfly takes flight, searching for food. Ash and unprepared survivors are her favorite!",
    SURVIVORCOCOONS = "The Hooded Widow seems to have acquired a taste for survivors, even bundling them up together in bigger cocoons to finish devouring them later.",
    MONSTERMEAT_DILUTION = "\"It's been very hard to use monster meat in my recipes, but today I discovered the solution! Just using the appropriate amount of healthy meat seems to completely dilute the poison.\" - W",
    MONSTERMEAT_DRYING = "\"I have been told that drying monster meat makes them ever so slightly less poisonous when cooking. That little boy scout sure knows a lot for his age.\" - W",
    MONSTERMEAT_WEREPIGS = "\"This amount of Monster Morsels in our Ice Box is just outrageous! It's risky, but we ought to send one of us to feed them to the Pigmen. Maybe Wigfrid. Wolfgang would definitely be too scared to do it.\" - W",
    MONSTERMEAT_KABOBS = "\"Sounds like nonsense, but surprisingly, eating this monster flesh cooked on a stick is not that bad. Props to the good ol' Kabobs for letting us avoid wasting healthy meat on a dish.\" - W",

    --tooltips
    --i'd preffer if we got character quotes for some of these.
    ARMOR_RUINS = "Thulecite Suits provides knockback immunity and reduce sanity lost from auras by 40%",
    SWEATERVEST = "The Dapper Vest reduces sanity lost from auras by 70%",
    COOKIECUTTERCAP = "The Cookie Cutter Cap now reflects 70% of the damage taken back at the attacker.",
    WARDROBE = "The Wardrobe now has 25 slots to store equipments. Keep your tools, weapons, armor, and more there!",
    TELESTAFF = "The Telelocator Staff and Focus have received major changes. You can now select one of multiple foci, rename them, teleport items, other players and heavy objects.",
    TOWNPORTAL = "The Lazy Deserter now picks items and harvests anything near it when used. This includes Grass Tufts, Drying Racks, Bee Boxes, and more.",
    PUMPKIN_LANTERN = "Pumpkin Lanterns have a positive sanity aura.",
    NIGHTLIGHT = "Night Lights drain sanity from nearby players to automatically fuel themselves as needed.",
    --MOONDIAL = "Moon Dials now work as a water source for Watering Cans. They can also be upgraded with a Moon Tear to allow mutating things during full moons.",
    ARMOR_DRAGONFLY = "The Scalemail now summons Dimvaes when worn to help you in combat.",
    GLASSCUTTER = "The Glass Cutter now deals extra damage against shadow-aligned enemies, as well as having increased durability against them",
    FEATHERHAT = "The Feather Hat provides safety against territorial Pengulls.",
    PURPLEAMULET = "The Nightmare Amulet provides additional Nightmare Fuel from slain Shadow Creatures when worn.",
    PIGGYPACK = "The Piggyback's reduced movement speed is now based on the number of stored items inside it.",
    PREMIUMWATERINGCAN = "The Waterfowl Can can store and preserve fish in it.",
    TURF_DRAGONFLY = "Scaled Flooring prevents Snow Pile buildup.",
    BLOWDART_YELLOW = "Electric Blowdarts can stun mechanical enemies.",
    DRAGONFLY_CHEST = "The Scaled Chest now has 25 slots total, and may kill the first Rat trying to steal from it.",
    BANDAGE = "Honey Poultice restores an additional 15 health overtime when used.",
    MULTITOOL = "The Pick/Axe creates shockwaves when used, harvesting nearby rocks/trees.",
    FEATHERPENCIL = "The Feather Pencil can rename Telelocator Foci and Wanda's Backtreck Watches.",
    DREADSTONE_WALL = "Dreadstone Walls have Planar Resistance and slowly repair themselves over time.",
    WALLS = "Walls prevent the buildup and spread of Snow Piles in a small radius.",
    FIREDART = "The Fire Darts are EXTRA fiery.",
    BEEMINE = "The Bee Mine has 5 uses and releases faster, more fragile bees.",
    FIRESUPRESSOR = "The Ice Flingomatic's \"Emergency Mode\" reacts faster to nearby fires, and ignores Campfires and Fire Pits.",
    CANNONS = "Cannons now have increased firepower and can fire Seedshells.",
    PIRATELEAKS = "Creating any leaks on Moon Quay pirate Boats causes them to retreat. This includes Seedshells!",
    TRIDENT = "The Striding Trident has a more powerful spell, and may multi-hit a target when attacking.",
    FAVORITE_FOOD = "A survivor's favorite food is a great thing to keep in mind when one wishes for some peace of mind.",
    LAZY_DESERTER = "The Lazy Deserter is now also a lazy collector! Just make sure to mind your sanity.",
    MONSTERMEAT_CROCKPOT = "\"Monster Meat is SO horrendous to cook with. But a true chef knows to mix it up with some healthy meat if the situation calls for it.\" - W",
    THERMAL_STONE = "Thermal Stones now become much better with proper clothing, and much worse without.",
    LIFE_AMULET = "Ghosts can no longer haunt Life Amulets to revive. Unless those amulets are of the rare and ancient variety.",
    PEARL_SHOP = "Pearl has expanded her shop, having a few more bits and baubles to sell.",
    FEATHER_FROCK = "The Feather Frock from Moose/Goose uses feathers for special effects, damaging enemies, speeding you up, and blocking a flat amount of incoming damage! The Veteran's Curse awaits you...",
    MOONFLY_LANTERN = "The Moonfly Lantern from Moonmaw Dragonfly speeds you up, while also leaving a glowing trail behind you that also speeds up fellow survivors! The Veteran's Curse awaits you...",
    SILKEN_SACK = "The Silken Sack from Hooded Widow is a Backpack that generates Silk every day, and can also bundle up items in exchange of Silk! The Veteran's Curse awaits you...",

    --character specific
    WARLY_BUTCHER = "\"Warly is a great friend to have. I have been capturing these creatures alive lately. He has a way with a knife that I cannot match.\" - W",
    WINONA_ELECTRICAL = "Winona expanded her electrical arsenal quite a bit! You should see her pack up her gizmos on the go.",
    WINONA_OVERCHARGE = "\"If you ask Winona nicely, she may upgrade your Lanterns or Miner Hats to the electrical era. She can even set their batteries to over 100%!\" - W",
    WIXIE_PUZZLE = "\"A mysterious wardrobe appeared, and I can't seem to get it open. Perhaps some outside assistance is required?\" - W",
    WENDY_SISTURN = "\"I have left Petals inside of the Sisturn out of respect. Something happened to them. They look ethereal now. I am afraid to ask Wendy about it.\" - W",
    WALTER_WOBY = "\"I taught Woby some new tricks! Look! She can grab what I command her and bark!\" - W",
    --WALTER_MEDIC = "\"After everyone got scratched and bruised so many times, Walter really learned a thing or two about first aid!\" - W",
    MAXWELL_TOPHAT = "\"Maxwell always goes around with that Top Hat on his head, and I think I discovered why! The confidence it gives me when messing with shadow magic...\" - W",
    --WICKER_BOOKREPAIR = "\"Wickerbottom has grown quite attached to her books. She keeps them on herself and takes propper care of them.\" - W",
    WILLOW_CUDDLE = "\"The shadows seem to not want to touch Willow when she is cuddling Bernie. Not even the forces of darkness would dare disturb something THAT adorable.\" - W",
    --WANDA_SHADOWS = "\"Wanda's time spent messing with time has really made her body more vulnerable to those nightmare monstrosities.\" - W",
    NOWINTERGROWTH_WURT = "\"Wurt, dear. Winter's been incredibly harsh to the crops as of late... I suggest you trade with your king for some kelp or venture down to the caves for more food.\" - W",
}

STRINGS.ACTIONS.USESPELLBOOK.UM_DETONATE = "Detonate"
--SCRAPBOOK
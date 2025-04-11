local stealtable = {}

stealtable= { 
    bee = {
		name = "bee",
		weight = {
			stinger = 5,
			honey = 1,
		},
	},
    pigguard = {
		name = "pigguard",
		weight = {
			kabobs = 1,
			goldnugget = 1,
			boards = 1,
			pig_coin = 1,
		},
		count = {
			goldnugget = 4,
			kabobs = 2,
			pig_coin = 4,
		},
	},
	abigail = {
		name = "abigail",
		weight = {
			petals_evil = 1,
		},
	},
    minotaur = {
		name = "minotaur",
		weight = {
			greengem = 1,
			nightmarefuel = 1,
			support_pillar_scaffold_blueprint = 1,
			orangegem = 1,
			yellowgem = 1,
			thulecite = 2,
		},
		count = {
			nightmarefuel = 5,
			greengem = 2,
			orangegem = 2,
			yellowgem = 2,
			thulecite = 5,
		},
	},    beefalo = {
		name = "beefalo",
		weight = {
			beefalowool = 1,
			horn = 1,
		},
	},    bunnyman = {
		name = "bunnyman",
		weight = {
			carrot = 2,
			powcake = 1,
			wormlight = 1,
			pitchfork = 1,
			yotr_food1 = 1,
			manrabbit_tail = 3,
		},
		count = {
			carrot = 2,
		},
		instakill = {
			manrabbit_tail = true
		},
	},    bishop = {
		name = "bishop",
		weight = {
			purplegem = 5,
			nightmarefuel = 1,
			thulecite_pieces = 1,
			thulecite = 1,
		},
		instakill = {
			purplegem = true
		},
		bonus = {
			purplegem = {"gears","gears"},
		},
	},    bishop_nightmare = {
		name = "bishop_nightmare",
		weight = {
			purplegem = 5,
			greengem = 2,
			yellowgem = 1,
			orangegem = 1,
			thulecite = 1,
		},
		instakill = {
			purplegem = true
		},
		bonus = {
			purplegem = {"nightmarefuel","thulecite_pieces"},
		},
	},    frog = {
		name = "frog",
		weight = {
			berries = 1,
			butterfly = 1,
			bee = 1,
			spider = 0.1,
			carrot = 1,
		},
	},    worm = {
		name = "worm",
		weight = {
			smallmeat = 0.5,
			wormlight_lesser = 1,
			slurtlehat = 0.5,
			ancientfruit_nightvision = 2,
			wormlight = 3,
		},
		bonus = {
			smallmeat = {"cavebanana"},
		},
		instakill = {
			wormlight = true
		},
		bonus = {
			wormlight = {"monstermeat","monstermeat","monstermeat","monstermeat"},
		},
	},    deerclops = {
		name = "deerclops",
		weight = {
			ice = 1,
		},
		count = {
			ice = 7,
		},
	},    perd = {
		name = "perd",
		weight = {
			berries = 1,
			berries_juicy = 1,
		},
	},    koalefant_summer = {
		name = "koalefant_summer",
		weight = {
			cutgrass = 2,
			twigs = 2,
			trunk_summer = 1,
		},
		count = {
			cutgrass = 5,
			twigs = 5,
		},
		instakill = {
			trunk_summer = true
		},
		bonus = {
			trunk_summer = {"meat","meat","meat","meat","meat","meat","meat","meat"},
		},
	},    koalefant_winter = {
		name = "koalefant_winter",
		weight = {
			cutgrass = 2,
			twigs = 2,
			trunk_winter = 1,
		},
		count = {
			cutgrass = 7,
			twigs = 6,
		},
		instakill = {
			trunk_winter = true
		},
		bonus = {
			trunk_winter = {"meat","meat","meat","meat","meat","meat","meat","meat"},
		},
	},    krampus = {
		name = "krampus",
		weight = {
			charcoal = 25,
			amulet = 25,
			krampus_sack = 5,
		    goldnugget = 25,
			dug_trap_starfish = 10,
			panflute = 10,
		},
		instakill = {
			krampus_sack = true
		},
		bonus = {
			krampus_sack = {"monstermeat","charcoal","charcoal"},
		},
		count = {
			charcoal = 4,
			goldnugget = 7,
		},
	},    walrus = {
		name = "walrus",
		weight = {
			walrushat = 5,
			heatrock = 1,
			tallbirdegg = 1,
			meat_dried = 1,
			blowdart_pipe = 1,
		},
		count = {
			blowdart_pipe = 5,
			meat_dried = 3,
		},
	},    little_walrus = {
		name = "little_walrus",
		weight = {
			meat_dried = 0.5,
			baconeggs = 2,
			smallmeat_dried = 0.5,
			houndwhistle = 7,
		},
		count = {
			smallmeat_dried = 3,
			meat_dried = 2,
		},
	},    merm = {
		name = "merm",
		weight = {
			pondfish = 5,
			fishingrod = 2,
			tentaclespike = 1,
		},
	},    penguin = {
		name = "penguin",
		weight = {
			bird_egg = 1,
			seeds = 1,
		},
	},    pigman = {
		name = "pigman",
		weight = {
			berries = 3,
			butterflymuffin = 1,
			hammer = 1,
			pig_coin = 3,
			yotpfood3 = 1,
			pumpkincookie = 0.5,
			kabobs = 1,
			taffy = 1,
			shovel = 1,
			pitchfork = 1,
		},
		count = {
			berries = 2,
			pig_coin = 2,
		},
	},    beehive = {
		name = "beehive",
		weight = {
			honey = 90,
			honeycomb = 9,
			royal_jelly = 1,
		},
	},    slurtle = {
		name = "slurtle",
		weight = {
			slurtle_shellpieces = 6,
			redgem = 1,
			bluegem = 1,
			thulecite = 1,
			slurtleslime = 1,
		},
	},    snurtle = {
		name = "snurtle",
		weight = {
			slurtle_shellpieces = 4,
			redgem = 1,
			bluegem = 1,
			thulecite = 1,
			slurtleslime = 1,
		},
	},    tentacle = {
		name = "tentacle",
		weight = {
			tentaclespots = 1,
			tentaclespike = 1,
		},
	},    tentacle_pillar = {
		name = "tentacle_pillar",
		weight = {
			tentaclespots = 1,
			tentaclespike = 1,
			turf_marsh = 0.1,
		},
	},    leif = {
		name = "leif",
		weight = {
			pinecone = 1,
			livinglog = 1,
		},
		count = {
			livinglog = 2,
			pinecone = 3,
		},
	},    leif_sparse = {
		name = "leif_sparse",
		weight = {
			pinecone = 1,
			livinglog = 1,
		},
		count = {
			livinglog = 2,
			pinecone = 3,
		},
	},    bearger = {
		name = "bearger",
		weight = {
			honey = 3,
			bearger_fur = 1,
		},
	},    catcoon = {
		name = "catcoon",
		weight = {
			mole = 2,
			rabbit = 1,
			canary_poisoned = 0.5,
			trinket_6 = 1,
			trinket_4 = 1,
			trinket_3 = 1,
		},
	},	
	    antlion = {
		name = "antlion",
		weight = {
			heatrock = 1,
			refined_dust = 1,
			thulecite = 1,
			orangegem = 8,
			bird_egg = 1,
		},
	},    beequeen = {
		name = "beequeen",
		weight = {
			honeycomb = 6,
			royal_jelly = 4,
		},
	},    klaus = {
		name = "klaus", 
		weight = {
			winterhat = 1,
			catcoonhat = 1,
			earmuffshat = 1,
			beefalohat = 1,
		},
		bonus_count = 2,
		bonus_pool = {
			"giftwrap",
			"sewing_kit",
			"purplegem",
			"greengem",
			"yellowgem",
			"orangegem",
			"thulecite",
			"winter_food8",
			"amulet",
		},
	},    crabking = {
		name = "crabking",
		weight = {
			messagebottle = 1,
		},
	},    deer_red = {
		name = "deer_red",
		weight = {
			charcoal = 1,
		},
	},    deer_blue = {
		name = "deer_blue",
		weight = {
			ice = 1,
		},
	},    malbatross = {
		name = "malbatross",
		weight = {
			bluegem = 4,
			yellowgem = 1,
		},
	},    toadstool = {
		name = "toadstool",
		weight = {
			mushroom_light2_blueprint = 1,
			green_cap = 2,
		},
	},    toadstool_dark = {
		name = "toadstool_dark",
		weight = {
			sleepbomb = 1,
			green_cap_cooked = 1,
		},
	},    fruitdragon = {
		name = "fruitdragon",
		weight = {
			dragonfruit_seeds = 3,
			dragonfruit = 1,
		},
	},    spiderqueen = {
		name = "spiderqueen",
		weight = {
			spidereggsack = 1,
			silk = 1,
		},
		count = {
			silk = 6,
		},
	},    sharkboi = {
		name = "sharkboi",
		weight = {
			bootleg = 1,
		},
		bonus_count = 2,
		bonus_pool = {
			"oceanfish_medium_8",
			"oceanfish_medium_2",
			"oceanfish_small_8",
			"oceanfish_small_6",
			"oceanfish_small_7",
			"oceanfish_small_9",
			"oceanfish_medium_1",
			"oceanfish_medium_3",
			"oceanfish_medium_4",
		},
	},     ghost = {
		name = "ghost",
		weight = {
			um_ghost_pepper_item = 1,
		},
	},     hoodedwidow = {
		name = "hoodedwidow",
		weight = {
			silk = 2,
			goose_feather = 1,
			
		},
		bonus_count = 2,
		bonus_pool = {
			"lightninggoathorn",
			"goose_feather",
			"tentaclespots",
			"livinglog",
			"walrus_tusk",
			"horn",
		},
		count = {
			silk = 3,
		},
	},     moonmaw_dragonfly = {
		name = "moonmaw_dragonfly",
		weight = {
			glass_scales = 1,
			alterguardianhatshard = 1,
			purebrilliance = 1,
		},
		count = {
			purebrilliance = 7,
		},
	},      viperworm = {
		name = "viperworm",
		weight = {
			viperfruit = 1,
			ancientfruit_nightvision = 1,
			viperfruit_lesser = 1,
		},
		instakill = {
			viperfruit = true
		},
		bonus = {
			viperfruit = {"monstermeat","monstermeat","monstermeat","monstermeat"},
		},
	},      shockworm = {
		name = "shockworm",
		weight = {
			zaspberry = 1,
			ancientfruit_nightvision = 1,
			zaspberry_lesser = 1,
		},
		instakill = {
			zaspberry = true
		},
		bonus = {
			zaspberry = {"monstermeat","monstermeat","monstermeat","monstermeat"},
		},
	},      alpha_lightninggoat = {
		name = "alpha_lightninggoat",
		weight = {
			lightninggoathorn = 1,
			goatmilk = 3,
			nitre = 1,
		},
		instakill = {
			lightninggoathorn = true
		},
		bonus = {
			lightninggoathorn = {"meat","meat"},
		},
	},      lightninggoat = {
		name = "lightninggoat",
		weight = {
			lightninggoathorn = 1,
			goatmilk = 3,
			nitre = 1,
		},
		instakill = {
			lightninggoathorn = true
		},
		bonus = {
			lightninggoathorn = {"meat","meat"},
		},
	},      stalker = {
		name = "stalker",
		weight = {
			shadowheart = 1,
		},
		instakill = {
			shadowheart = true
		},
		bonus = {
			shadowheart = {"fossil_piece","fossil_piece","fossil_piece","fossil_piece","fossil_piece","fossil_piece","fossil_piece","fossil_piece","nightmarefuel","nightmarefuel","nightmarefuel"},
		},
	},      stalker_atrium = {
		name = "stalker_atrium",
		weight = {
			shadow_crown = 1,
			skullflask = 1,
		},
	},
	      dragonfly = {
		name = "dragonfly",
		weight = {
			dragon_scales = 1,
			lavae_egg = 1,
		},
		bonus_count = 3,
		bonus_pool = {
			"redgem",
			"orangegem",
			"bluegem",
			"greengem",
			"purplegem",
			"yellowgem",
		},
	},
	lordfruitfly = {
		name = "lordfruitfly",
		weight = {
			seeds = 1,
		},
		count = {
			seeds = 7,
		},
	},
	mermguard = {
		name = "mermguard",
		weight = {
			pondfish = 1,
			spear = 1,
		},
	},
}

return stealtable
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
			berries = 1,
			goldnugget = 1,
			boards = 1,
			pig_coin = 1,
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
		},
		count = {
			nightmarefuel = 5,
		},
	},    beefalo = {
		name = "beefalo",
		weight = {
			beefalowool = 1,
			
		},
	},    bunnyman = {
		name = "bunnyman",
		weight = {
			carrot = 2,
			powcake = 1,
			wormlight = 1,
			pitchfork = 1,
			yotr_food1 = 1,
		},
	},    bishop = {
		name = "bishop",
		weight = {
			purplegem = 7,
			nightmarefuel = 1,
			thulecite_pieces = 1,
			thulecite = 1,
		},
	},    bishop_nightmare = {
		name = "bishop_nightmare",
		weight = {
			purplegem = 7,
			greengem = 1.5,
			yellowgem = 0.5,
			orangegem = 0.5,
			thulecite = 0.5,
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
			smallmeat = 1,
			wormlight_lesser = 4,
			slurtle_shellpieces = 1,
			slurper_pelt = 1,
			slurtlehat = 0.5,
		},
		bonus = {
			smallmeat = {"cavebanana"},
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
			cutgrass = 1,
			twigs = 1,
		},
	},    koalefant_winter = {
		name = "koalefant_winter",
		weight = {
			cutgrass = 1,
			twigs = 1,
		},
	},    krampus = {
		name = "krampus",
		weight = {
			charcoal = 30,
			amulet = 20,
			krampus_sack = 5,
		    goldnugget = 25,
			dug_trap_starfish = 10,
			panflute = 10,
		},
		instakill = {
			krampus_sack = true
		},
	},    walrus = {
		name = "walrus",
		weight = {
			walrushat = 1,
			blowdart_pipe = 1,
			heatrock = 1,
			tallbirdegg = 1,
			meat_dried = 1,
		},
	},    little_walrus = {
		name = "little_walrus",
		weight = {
			meat_dried = 1,
			baconeggs = 1,
			smallmeat_dried = 1,
			houndwhistle = 3,
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
			berries = 1,
			carrot = 1,
			hammer = 1,
			pig_coin = 1,
			yotpfood3 = 1,
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
			slurtle_shellpieces = 7,
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
	},    leif_sparse = {
		name = "leif_sparse",
		weight = {
			pinecone = 1,
			livinglog = 1,
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
			robin = 2,
			robin_winter = 1,
			crow = 1,
			canary_poisoned = 0.5,
			canary = 1,
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
			honeycomb = 9,
			royal_jelly = 1,
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
			green_cap = 1,
		},
	},    toadstool_dark = {
		name = "toadstool_dark",
		weight = {
			green_cap_cooked = 1,
		},
	},    fruitdragon = {
		name = "fruitdragon",
		weight = {
			dragonfruit_seeds = 1,
			
		},
	},    mermguard = {
		name = "mermguard",
		weight = {
			pondfish = 1,
			spear = 1,
		},
	},
}

return stealtable
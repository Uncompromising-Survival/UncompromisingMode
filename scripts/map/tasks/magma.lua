require ("map/rooms/caves/moltenregions")

AddTask("MagmaCaves", {
		locks={LOCKS.MAGMA_CAVES_ENTRANCE},
		keys_given={KEYS.MAGMA_CAVES},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers"},
		room_choices={
			["GrassMagma"] = 2,
			["GloomyMagma"] = 1,
			["FossilMagma"] = 2,		
			["ShroomyMagma"] = 2,
		},
		background_room="BGMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})
AddTask("MagmaCavesEntrance", {
		locks={LOCKS.MAGMA_CAVES},
		keys_given={},
		level_set_piece_blocker = true,
		room_tags = {"RoadPoison", "nohunt", "nohasslers"},
		room_choices={
			["MagmaStairs"] = 1,
			["ShroomyMagma"] = 1,			
		},
		background_room="BGMagma",
		room_bg=WORLD_TILES.UM_MAGMA,
		colour={r=.1,g=.1,b=.1,a=1},
})

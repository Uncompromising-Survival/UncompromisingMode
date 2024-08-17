-- Infest Triple Mac with Ghosts
if GetModConfigData("ghostwalrus") ~= "disabled" then
	AddRoomPreInit("WalrusHut_Plains", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
	AddRoomPreInit("WalrusHut_Grassy", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
	AddRoomPreInit("WalrusHut_Rocky", function(room) room.contents.countprefabs = { um_bear_trap_old = function() return math.random(6, 8) end, ghost_walrus = function() return math.random(2, 4) end, walrus_camp = 1 } end)
end

-- Trapdoor Spiders
if GetModConfigData("trapdoorspiders") then
	AddRoomPreInit("BGSavanna", function(room) -- Primarily affects beefalo plains and triple mac, lumping it into this modimport bc of its prevalence
		room.contents.countprefabs = { trapdoorspawner = function() return math.random(4, 5) end }
	end)
	AddRoomPreInit("Plain", function(room)                                                       -- This effects areas in the Major Beefalo Plains and the Grasslands next to the portal
		room.contents.countprefabs = { trapdoorspawner = function() return math.random(2, 4) end } -- returned number for whole area should be multiplied between 2-4 due to multiple rooms
	end)
end

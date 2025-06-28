AddRoomPreInit("MoonIsland_Beach", function(room) 
	room.contents.countprefabs = { um_beehive_moon = function() return math.random(1, 2) end} 
end)
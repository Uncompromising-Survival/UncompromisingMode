AddRoomPreInit("MoonIsland_Mine", function(room) 
	room.contents.countprefabs = { um_beehive_moon = function() return math.random(0, 2) end} 
end)
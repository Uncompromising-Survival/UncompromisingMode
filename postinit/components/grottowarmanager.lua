local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

-- Change this function
local function OnPlayerAreaChanced(player, data)
	if data ~= nil and data.tags ~= nil and table.contains(data.tags, "lunacyarea") then
		_players[player] = true
		TryStart()
	else
		_players[player] = nil
		if next(_players) == nil then
			Stop()
		end
	end
end


env.AddComponentPostInit("grottowarmanager", function(self)

end)
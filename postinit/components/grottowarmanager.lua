local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("grottowarmanager", function(self)
    local source = "scripts/components/grottowarmanager.lua"
	local inst = self.inst

    local _OnPlayerJoined
    for i, func in ipairs(inst.event_listeners["ms_playerjoined"][inst]) do
        -- We can find the correct func by the function's source since the
        -- event listeners likely won't have two different events of the same source
        if debug.getinfo(func, "S").source == source then
            _OnPlayerJoined = inst.event_listeners["ms_playerjoined"][inst][i]
            break
        end
    end
	local _TryStart = UpvalueHacker.GetUpvalue(_OnPlayerJoined, "OnPlayerAreaChanced","TryStart")
	local _Stop = UpvalueHacker.GetUpvalue(_OnPlayerJoined, "OnPlayerAreaChanced","Stop")
	local _players = UpvalueHacker.GetUpvalue(self.GetDebugString,"_players")


	local function OnPlayerAreaChanced(player, data)
		if data ~= nil and data.tags ~= nil and table.contains(data.tags, "um_grottowar") then
			_players[player] = true
			_TryStart()
		else
			_players[player] = nil
			if next(_players) == nil then
				_Stop()
			end
		end
	end
		
	UpvalueHacker.SetUpvalue(_OnPlayerJoined, OnPlayerAreaChanced, "OnPlayerAreaChanced")
end)
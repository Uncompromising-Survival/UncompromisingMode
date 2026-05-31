local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local BEARGER_TIMERNAME = "bearger_timetospawn"
local UpvalueHacker = require("tools/upvaluehacker")

env.AddComponentPostInit("beargerspawner", function(self)
	local um_overridespawn = false

	local _CanSpawnBearger = UpvalueHacker.GetUpvalue(self.OnUpdate,"CanSpawnBearger")
	local function CanSpawnBearger()
		return _CanSpawnBearger() or um_overridespawn == true
	end
	UpvalueHacker.SetUpvalue(self.OnUpdate,CanSpawnBearger,"CanSpawnBearger")

	local _SpawnBearger = UpvalueHacker.GetUpvalue(self.OnUpdate,"SpawnBearger")

	local function SpawnBearger()
		um_overridespawn = false
		if _CanSpawnBearger() then
			_SpawnBearger()
		end
	end
	UpvalueHacker.SetUpvalue(self.OnUpdate, SpawnBearger, "SpawnBearger")

	local _OnSave = self.OnSave
	local _OnLoad = self.OnLoad

	function self:OnSave()
		local data, ents = _OnSave(self)
		data.um_overridespawn = um_overridespawn
		return data, ents
	end

	function self:OnLoad(data)
		_OnLoad(self,data)
		um_overridespawn = data.um_overridespawn
	end

	local GetActiveHasslerCount = UpvalueHacker.GetUpvalue(self.GetDebugString, "GetActiveHasslerCount")

	local function OnMegaFlare(src, data)
		if data.sourcept and TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) and TheWorld.state.isautumn then
			local _worldsettingstimer = TheWorld.components.worldsettingstimer

			if GetActiveHasslerCount() > 0 then
				TheWorld:PushEvent("megaflare_guardmet", {sourcept = data.sourcept})
			else
				local numSpawned = UpvalueHacker.GetUpvalue(self.OnPostInit,"OnBeargerTimerDone","ReleaseHassler","_numSpawned") or 0
				UpvalueHacker.SetUpvalue(self.OnPostInit, numSpawned + 1,"OnBeargerTimerDone", "ReleaseHassler","_numToSpawn")
				local currentTime = _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME)
				if currentTime ~= nil and currentTime <= 480 then
					TheWorld:PushEvent("megaflare_guardmet", {sourcept = data.sourcept})
				elseif currentTime ~= nil and currentTime > 480 then -- Cannot advance any more if it's within one day
					local time = UMCommonFns.MegaFlareTimerReduction(currentTime)
					_worldsettingstimer:SetTimeLeft(BEARGER_TIMERNAME, time)
					--TheNet:Announce("Bearger timer: " .. tostring(time))
					--TheNet:Announce("Bearger timer: " .. tostring(time/480) .. " days")
				elseif not _worldsettingstimer:ActiveTimerExists(BEARGER_TIMERNAME) then
					local time = 480*math.random(10,12)
					_worldsettingstimer:StartTimer(BEARGER_TIMERNAME, time)
					--TheNet:Announce("Bearger timer started: " .. tostring(time))
					--TheNet:Announce("Bearger timer started: " .. tostring(time/480) .. " days")
					um_overridespawn = true
				end
			end
		end
	end


	self.inst:ListenForEvent("megaflare_detonated", OnMegaFlare, TheWorld)
end)

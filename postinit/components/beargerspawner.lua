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
		_SpawnBearger()
		um_overridespawn = false
	end	
	
	local _OnSave = self.OnSave
	local _OnLoad = self.OnLoad
	
	function self:OnSave()
		local data, ents = _OnSave(self)
		table.insert(data,um_overridespawn)
		return data, ents
	end

	function self:OnLoad(data)
		_OnLoad(self,data)
		um_overridespawn = data.um_overridespawn
	end
	
	local function OnMegaFlare(src, data)
		if data.sourcept and TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) and TheWorld.state.isautumn then
			local _worldsettingstimer = TheWorld.components.worldsettingstimer
			local _activehassler = UpvalueHacker.GetUpvalue(self.GetDebugString,"GetActiveHasslerCount", "_activehassler")

			
			if not _activehassler then
			
				UpvalueHacker.SetUpvalue(self.OnPostInit,1,"OnBeargerTimerDone", "ReleaseHassler","_numToSpawn")
				if _worldsettingstimer:ActiveTimerExists(BEARGER_TIMERNAME) and _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME) > 480*1.8 then -- Cannot advance any more if it's within two days
					local time = _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME)
					if time > 480*8 then
						time = time - 480*math.random(2,3)
					elseif time > 480*4 then
						time = time - 480*math.random(1,2)
					else
						time = time - 480*math.random(1,1.5)
					end
					_worldsettingstimer:SetTimeLeft(BEARGER_TIMERNAME, time)
					--TheNet:Announce(_worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME))
				elseif not _worldsettingstimer:ActiveTimerExists(BEARGER_TIMERNAME) then
					_worldsettingstimer:StartTimer(BEARGER_TIMERNAME, 480*math.random(6,8))
					um_overridespawn = true
				else
					--
				end
			else
				--TheNet:Announce("Active Hassler... somehow")
			end
		end
	end

	
	self.inst:ListenForEvent("megaflare_detonated", OnMegaFlare, TheWorld)
end)
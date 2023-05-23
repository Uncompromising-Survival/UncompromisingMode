--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")

--------------------------------------------------------------------------
--[[ Gmoosespawner class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)
	assert(TheWorld.ismastersim, "Gmoosespawner should not exist on client")

	local _locationtags = {
		"siren_bird_spawner",
		"siren_speaker_spawner",
		"siren_fish_spawner",
	}

	local _worldsettingstimer = TheWorld.components.worldsettingstimer
	local UM_STORM_TIMERNAME = "um_storm_timer"

	--------------------------------------------------------------------------
	--[[ Private constants ]]
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	--[[ Public Member Variables ]]
	--------------------------------------------------------------------------

	self.inst = inst

	--------------------------------------------------------------------------
	--[[ Private Member Variables ]]
	--------------------------------------------------------------------------

	local _tornadotime = (TheWorld.state.springlength / 4) * 240

	--------------------------------------------------------------------------
	--[[ Private member functions ]]
	--------------------------------------------------------------------------

	local function PickAttackTarget()
		if #_locationtags == 0 then
			_locationtags = {
				"siren_bird_spawner",
				"siren_speaker_spawner",
				"siren_fish_spawner",
			}
		else
			local target_portal = TheSim:FindFirstEntityWithTag("multiplayer_portal")
			local location_id = math.random(#_locationtags)
			local spawn_location = TheSim:FindFirstEntityWithTag(_locationtags[location_id])

			if spawn_location ~= nil then
				table.remove(_locationtags, location_id)

				local x, y, z = spawn_location.Transform:GetWorldPosition()
				local x_dest, y_dest, z_dest = spawn_location.Transform:GetWorldPosition()

				if x > 0 then
					x_dest = -x * 2
				else
					x_dest = math.abs(x) * 2
				end

				if z > 0 then
					z_dest = -z * 2
				else
					z_dest = math.abs(z) * 2
				end

				SpawnPrefab("um_tornado_destination").Transform:SetPosition(x_dest + math.random(-50, 50), 0,
					z_dest + math.random(-50, 50))
				SpawnPrefab("um_tornado").Transform:SetPosition(x, y, z)

				SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "CaveTornado"), nil, x, z)
			end
		end

		_worldsettingstimer:StartTimer(UM_STORM_TIMERNAME, _tornadotime + math.random(180))
	end

	local function SpawnCaveTornado(inst, data)
		print("SpawnCaveTornado")
		if data ~= nil and data.xdata ~= nil then
			--print("xdata"..data.xdata)
			local x = data.xdata
			local z = data.zdata

			local x_dest = x
			local z_dest = z

			if x > 0 then
				x_dest = -x * 2
			else
				x_dest = math.abs(x) * 2
			end

			if z > 0 then
				z_dest = -z * 2
			else
				z_dest = math.abs(z) * 2
			end

			SpawnPrefab("um_tornado_destination").Transform:SetPosition(x_dest + math.random(-50, 50), 0,
				z_dest + math.random(-50, 50))
			SpawnPrefab("um_cavetornado").Transform:SetPosition(x, 0, z)
		end
	end

	local function StartStorms()
		if _worldsettingstimer:GetTimeLeft(UM_STORM_TIMERNAME) == nil then
			_worldsettingstimer:StartTimer(UM_STORM_TIMERNAME, _tornadotime + math.random(180))
		end

		_worldsettingstimer:ResumeTimer(UM_STORM_TIMERNAME)
	end

	local function StopStorms()
		_worldsettingstimer:StopTimer(UM_STORM_TIMERNAME)
	end

	--------------------------------------------------------------------------
	--[[ Private event handlers ]]
	--------------------------------------------------------------------------

	local function OnSeasonChange(self)
		if TheWorld.state.season == "spring" then
			StartStorms()
		else
			_locationtags = {
				"siren_bird_spawner",
				"siren_speaker_spawner",
				"siren_fish_spawner",
			}

			StopStorms()
		end
	end


	function self:OnSave()
		local data =
		{
			locationtags = _locationtags,
		}

		return data
	end

	function self:OnLoad(data)
		_locationtags = data.locationtags
	end

	function self:OnPostInit()
		if TheWorld.ismastershard then
			_worldsettingstimer:AddTimer(UM_STORM_TIMERNAME, _tornadotime + math.random(180), true, PickAttackTarget)

			OnSeasonChange()
		end
	end

	if TheWorld.ismastershard then
		self:WatchWorldState("season", OnSeasonChange)
		self.inst:ListenForEvent("forcetornado", PickAttackTarget)
	else
		self.inst:ListenForEvent("spawncavetornado", SpawnCaveTornado)
	end
end)

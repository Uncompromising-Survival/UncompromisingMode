--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------
local easing = require("easing")

--------------------------------------------------------------------------
--[[ Deerclopsspawner class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

    assert(TheWorld.ismastersim, "nullspawner should not exist on client")

    --------------------------------------------------------------------------
    --[[ Private constants ]]
    --------------------------------------------------------------------------

    local STRUCTURE_DIST = 20
    local HASSLER_SPAWN_DIST = 40
    local HASSLER_KILLED_DELAY_MULT = 6
    local STRUCTURES_PER_SPAWN = 4
    local DEERCLOPS_TIMERNAME = "deerclops_timetoattack"

    --------------------------------------------------------------------------
    --[[ Public Member Variables ]]
    --------------------------------------------------------------------------

    self.inst = inst

    --------------------------------------------------------------------------
    --[[ Private Member Variables ]]
    --------------------------------------------------------------------------

    local _activeplayers = {}
	
	self.nightterrors = nil
	self.shadowcharacters = nil
	self.storedterrors = {}
	self.storedcharacters = {}
	self.totalrandomnightterrorsweight = nil
	self.totalrandomshadowcharactersweight = nil
	
    self._hasspawnedvoxolophone = false
    self._retry_spawning_voxolophone = false
	
    self.prep_for_nightterrors = false

    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------

    local function AllowedToAttack(data)
        return #_activeplayers > 0 and
            ((data and data.skipcycles) or TheWorld.state.cycles > TUNING.NO_BOSS_TIME) and
            (_attackoffseason or
                TheWorld.state.season == "winter")
    end

    local function IsEligible(player)
        local area = player.components.areaaware
        return TheWorld.Map:IsVisualGroundAtPoint(player.Transform:GetWorldPosition())
            and area:GetCurrentArea() ~= nil
            and not area:CurrentlyInTag("nohasslers")
    end

    local function DespawnOnDay(ent)
        ent:WatchWorldState("cycles", function() 
			local x, y, z = ent.Transform:GetWorldPosition()
			SpawnPrefab("statue_transition").Transform:SetPosition(x, y, z)
			SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
							
			ent:Remove()
		end)
    end

    local ATTACK_MUST_TAGS = { "structure" }
    local function PickAttackTarget()
        _targetplayer = nil
        if #_activeplayers == 0 then
            return
        end

        local playerlist = {}
        for _, v in ipairs(_activeplayers) do
            if IsEligible(v) then
                table.insert(playerlist, v)
            end
        end
        shuffleArray(playerlist)
        if #playerlist == 0 then
            return
        end

        local numStructures = 0
        local loopCount = 0
        local player = nil
        while (numStructures < STRUCTURES_PER_SPAWN) and (loopCount < (#playerlist + 3)) do
            player = playerlist[1 + (loopCount % #playerlist)]

            local x, y, z = player.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, STRUCTURE_DIST, ATTACK_MUST_TAGS)

            numStructures = #ents
            loopCount = loopCount + 1
        end
		
        _targetplayer = player
    end

    local function GetSpawnPoint(pt)
        if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
            pt = FindNearbyLand(pt, 1) or pt
        end
        local offset = FindWalkableOffset(pt, math.random() * 2 * PI, HASSLER_SPAWN_DIST, 12, true)
        if offset ~= nil then
            offset.x = offset.x + pt.x
            offset.z = offset.z + pt.z
            return offset
        end
    end

    local STRUCTURE_TAGS = { "structure" }
    local function ReleaseHassler(targetPlayer)
        assert(targetPlayer)

        local hassler = TheSim:FindFirstEntityWithTag("deerclops")
        if hassler ~= nil then
            return hassler -- There's already a hassler in the world, we're done here.
        end

        local spawn_pt = GetSpawnPoint(targetPlayer:GetPosition())
        if spawn_pt ~= nil then
            if _storedhassler ~= nil then
                hassler = SpawnSaveRecord(_storedhassler, {})
                _storedhassler = nil
            else
                hassler = nil --SpawnPrefab("deerclops") No...
            end

            if hassler ~= nil then
                hassler.Physics:Teleport(spawn_pt:Get())
                local target = GetClosestInstWithTag(STRUCTURE_TAGS, targetPlayer, 40)
                if target ~= nil then
                    hassler.components.knownlocations:RememberLocation("targetbase", target:GetPosition())
                end
                -- Liz: home location is now chosen right before going there, to make sure that deerclops can walk there.
                return hassler
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------

    local function OnPlayerJoined(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then
                return
            end
        end
        table.insert(_activeplayers, player)
    end

    local function OnPlayerLeft(src, player)
        for i, v in ipairs(_activeplayers) do
            if v == player then
                table.remove(_activeplayers, i)
				
                return
            end
        end
    end

    --------------------------------------------------------------------------
    --[[ NIGHT TERRORS ]]
    --------------------------------------------------------------------------
	
	local function PlayerScaling(player)
		local x, y, z = player.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 50, {"player"}, {"playerghost"})

		if #ents >= 0 and #ents < 3 then
			return 1
		elseif #ents >= 3 and #ents < 5 then
			return 2
		elseif #ents >= 5 and #ents < 7 then
			return 3
		elseif #ents > 6 then
			return 4
		end

		return 1
	end
	
	local function DayScaling()
		local scale = TheWorld.state.cycles / 20 --This uhhhh should be equal to the full moon date, right?
		print("um_nightterrors DayScaling : "..scale)
		return scale
	end
	
	local NEARFIRE_MUST_TAGS = { "fire" }
	local NEARFIRE_CANT_TAGS = { "_equippable" }
	local _fueltags = {}
	local _map = TheWorld.Map

	local function SpawnHand(player)
        -- this is for land and fire.
        local fire = FindEntity(player, 60, nil, NEARFIRE_MUST_TAGS, NEARFIRE_CANT_TAGS, _fueltags)
		
	    if fire == nil then
	        return
	    end
		
	    local radius = fire.components.burnable:GetLargestLightRadius() or 8
	    local x, y, z = fire.Transform:GetWorldPosition()
		
	    for i = 1, math.random(2) do
	        local angle = math.random() * 2 * PI
	        local result_offset = FindValidPositionByFan(angle, radius, 12, function(offset)
	            local x1 = x + offset.x
	            local z1 = z + offset.z
	            return TheSim:GetLightAtPoint(x1, 0, z1) <= TUNING.DARK_SPAWNCUTOFF
	                and _map:IsPassableAtPoint(x1, 0, z1)
	                and not _map:IsPointNearHole(Vector3(x1, 0, z1))
	        end)
	        if result_offset ~= nil then
	            local ent = SpawnPrefab("shadowhand")
	            ent.Transform:SetPosition(x + result_offset.x, 0, z + result_offset.z)
	            ent:SetTargetFire(fire)
	        end
	    end
		
		TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.HANDS })
	end

	local function SpawnShadowGrabby(player)
		if TheWorld.state.isnight then
			local radius = 15 + math.random() * 15
			local theta = math.random() * 2 * PI
			local x, y, z = player.Transform:GetWorldPosition()
			local x1 = x + radius * math.cos(theta)
			local z1 = z - radius * math.sin(theta)
			local light = TheSim:GetLightAtPoint(x1, 0, z1)
			
			for i = 1, 2 + math.random(2) do
				for i = 1, 8 do
					if (light <= 0.2 or i == 8) then
						local ent = SpawnPrefab("rne_grabbyshadows")
						ent.Transform:SetPosition(x1, 0, z1)
						DespawnOnDay(ent)

						TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.GRABBY })
						
						break
					end
				end
			end
		end
	end

	local function SpawnShadowVortex(player)
		if TheWorld.state.isnight then
			for i = 1, 8 do
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)
				if (light <= 0.3 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
					local ent = SpawnPrefab("shadowvortex")
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)

					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.VORTEX }) 
			
					break
				end
			end
		end
	end

	local function SpawnMindWeavers(player)
		if TheWorld.state.isnight then
			TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.MINDWEAVER }) 
			
			for i = 1, PlayerScaling(player) do
				local x, y, z = player.Transform:GetWorldPosition()
				local ent = SpawnPrefab("mindweaver")
				ent.Transform:SetPosition(x + math.random(-5, 5), y, z + math.random(-5, 5))
			end
		end
	end
	
	local function SpawnNightCrawlers(player)
		if TheWorld.state.isnight then
			for i = 1, 3 do
				for i = 1, 8 do
					local radius = 15 + math.random() * 15
					local theta = math.random() * 2 * PI
					local x, y, z = player.Transform:GetWorldPosition()
					local x1 = x + radius * math.cos(theta)
					local z1 = z - radius * math.sin(theta)
					local light = TheSim:GetLightAtPoint(x1, 0, z1)

					if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
						local ent = SpawnPrefab("um_nightcrawler")
						ent.Transform:SetPosition(x1, 0, z1)
						DespawnOnDay(ent)

						TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.NIGHTCRAWLER })
						
						break
					end
				end
			end
		end
	end
	
	local function SpawnLeeches(player)
		if TheWorld.state.isnight then
			for i = 1, 5 do
				for i = 1, 8 do
					local radius = 15 + math.random() * 15
					local theta = math.random() * 2 * PI
					local x, y, z = player.Transform:GetWorldPosition()
					local x1 = x + radius * math.cos(theta)
					local z1 = z - radius * math.sin(theta)
					local light = TheSim:GetLightAtPoint(x1, 0, z1)

					if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
						local ent = SpawnPrefab("um_shadow_leech")
						ent.Transform:SetPosition(x1, 0, z1)
						DespawnOnDay(ent)

						TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.UM_LEECH })
						
						break
					end
				end
			end
		end
	end
	
	local function SpawnFuelSeekers(player)
		if TheWorld.state.isnight then
			local has_spawned_threat = false
			local dayscale = DayScaling() / 2
			local playerscale = PlayerScaling(player)
			
			if dayscale > 3 then
				dayscale = 3
			end
			
			local totalscale = dayscale + playerscale
			
			if totalscale < 1 then
				totalscale = 1
			end
		
			if self:LightStealTarget(player) then
				for i = 1, totalscale do
					for i = 1, 8 do
						local radius = 15 + math.random() * 15
						local theta = math.random() * 2 * PI
						local x, y, z = player.Transform:GetWorldPosition()
						local x1 = x + radius * math.cos(theta)
						local z1 = z - radius * math.sin(theta)
						local light = TheSim:GetLightAtPoint(x1, 0, z1)

						if (light <= 0.2 or i == 8) then
							has_spawned_threat = true
							local ent = SpawnPrefab("fuelseeker")
							ent.Transform:SetPosition(x1, 0, z1)
							DespawnOnDay(ent)

							TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.FUELSEEKER }) 
					
							break
						end
					end
				end
			end
			
			if not has_spawned_threat then
				self:PickTerror(player)
			end
		end
	end

	local function SpawnHaunt(player)
		if TheWorld.state.isnight then
			local x, y, z = player.Transform:GetWorldPosition()
			local structures = TheSim:FindEntities(x, y, z, 30, { "structure" })
			
			if structures ~= nil and #structures > 0 then
				for i, v in ipairs(structures) do
					for i = 1, 3 do
						if v ~= nil then
							local players = TheSim:FindEntities(x, y, z, 8, { "player" })
										
							if players == nil or #players == 0 then
								local ent = SpawnPrefab("um_haunt")
								ent.haunt_target = v
								ent.Transform:SetPosition(x1, 0, z1)
								DespawnOnDay(ent)
					
								TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.HAUNT }) 

								return
							end
						end
					end
				end
			end
			
			self:PickTerror(player)
			return
		end
	end

	local function SpawnHeckler(player)
		if TheWorld.state.isnight then
			for i = 1, 8 do
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)

				if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
					local ent = SpawnPrefab("um_heckler")
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)
					
					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.HECKLER })
					
					break
				end
			end
		end
	end

	local function SpawnNightmareCreature(player)
		if TheWorld.state.isnight then
			for i = 1, 8 do
				local count = 1 
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)

				if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
					local ent = math.random() > 0.66 and SpawnPrefab("nightmarebeak") or SpawnPrefab("crawlingnightmare")
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)
					
					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.NIGHTMARECREATURE })
					count = count + 1
					
					if count >= 2 then
						break
					end
				end
			end
		end
	end

	local function SpawnShadowCharacter(player, character)
		if TheWorld.state.isnight and character ~= nil then
			for i = 1, 8 do
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)

				if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
					local ent = SpawnPrefab(character)
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)

					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.HECKLER })
					
					break
				end
			end
		end
	end
	
    --------------------------------------------------------------------------
    --[[ Public member functions ]]
    --------------------------------------------------------------------------

    function self:OnUpdate(dt)
    end

    function self:LongUpdate(dt)
        --self:OnUpdate(dt)
    end

    --------------------------------------------------------------------------
    --[[ Save/Load ]]
    --------------------------------------------------------------------------

	function self:OnSave(data)
		local data = {}
		
		data._hasspawnedvoxolophone = self._hasspawnedvoxolophone
		data.prep_for_nightterrors = self.prep_for_nightterrors
		data._retry_spawning_voxolophone = self._retry_spawning_voxolophone
			
		return data
	end

	function self:OnLoad(data)
		if data ~= nil then
			if data._hasspawnedvoxolophone then
				self._hasspawnedvoxolophone = data._hasspawnedvoxolophone
			end
			
			if data.prep_for_nightterrors then
				self.prep_for_nightterrors = data.prep_for_nightterrors
			end
			
			if data._retry_spawning_voxolophone then
				self._retry_spawning_voxolophone = data._retry_spawning_voxolophone
			end
		end
	end

	local function AddTerror(name, weight)
		if not self.nightterrors then
			self.nightterrors = {}
			self.totalrandomnightterrorsweight = 0
		end
		
		if not table.contains(self.nightterrors, name) then
			table.insert(self.nightterrors, { name = name, weight = weight })
			self.totalrandomnightterrorsweight = self.totalrandomnightterrorsweight + weight
		end
	end

	local function AddCharacters(weight, character, level)
		if not self.shadowcharacters then
			self.shadowcharacters = {}
			self.totalrandomshadowcharactersweight = 0
		end
		
		if not table.contains(self.shadowcharacters, character) then
			table.insert(self.shadowcharacters, { weight = weight, character = character, level = level })
			self.totalrandomshadowcharactersweight = self.totalrandomshadowcharactersweight + weight
		end
	end
	
	local HARASSMENT =
	{
		SpawnHand = { name = SpawnHand, weight = .3, },
		SpawnShadowGrabby = { name = SpawnShadowGrabby, weight = .5, },
		SpawnShadowVortex = { name = SpawnShadowVortex, weight = .4, },
		SpawnNightCrawlers = { name = SpawnNightCrawlers, weight = .5, },
		SpawnHaunt = { name = SpawnHaunt, weight = .5, },
		SpawnLeeches = { name = SpawnHaunt, weight = .5, },
	}
	
	local TERRORS =
	{
		SpawnMindWeavers = { name = SpawnMindWeavers, weight = .5, },
		--SpawnBreakers = { name = SpawnNervousTicks, weight = .5, },
		--SpawnNervousNest = { name = SpawnNervousTicks, weight = .5, },
		SpawnFuelSeekers = { name = SpawnFuelSeekers, weight = .5, },
		SpawnHeckler = { name = SpawnHeckler, weight = .5, },
	}
	
	local SHADOWS =
	{
		SpawnNightmareCreature = { name = SpawnNightmareCreature, weight = .3, },
	}
	
	local CHARACTERS =
	{
		SpawnShadowWilson = { weight = .5, character = "swilson", level = 2 },
		SpawnShadowWalter = { weight = .5, character = "um_shadow_walter", level = 1 },
		SpawnShadowWortox = { weight = .5, character = "um_shadow_wortox", level = 2 },
		--SpawnShadowMaxwell = { weight = .5, character = "um_shadow_maxwell", level = 3 },
		--SpawnShadowWillow = { weight = .5, character = "um_shadow_willow", level = 0 },
		SpawnShadowWarly = { weight = .5, character = "um_shadow_warly", level = 1 },
		--SpawnShadowWinky = { weight = .5, character = "um_shadow_winky", level = 1 },
		SpawnShadowWickerbottom = { weight = .5, character = "um_shadow_wickerbottom", level = 2 },
		--SpawnShadowWoodie = { weight = .5, character = "um_shadow_woodie", level = 2 },
		SpawnShadowWolfgang = { weight = .5, character = "um_shadow_wolfgang", level = 1 },
		SpawnShadowWanda = { weight = .5, character = "um_shadow_wanda", level = 1 },
		SpawnShadowWathgrithr = { weight = .5, character = "swathgrithr", level = 2 },
		SpawnShadowWes = { weight = .5, character = "um_shadow_wes", level = 1 },
		SpawnShadowWendy = { weight = .5, character = "um_shadow_wendy", level = 1 },
	}

	for k, v in pairs(HARASSMENT) do
		AddTerror(v.name, v.weight)
	end

	for k, v in pairs(TERRORS) do
		AddTerror(v.name, v.weight)
	end

	for k, v in pairs(SHADOWS) do
		AddTerror(v.name, v.weight)
	end

	for k, v in pairs(CHARACTERS) do
		AddCharacters(v.weight, v.character, v.level)
	end

    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------
	
	function self:PickTerror(player)
		if TheWorld.state.isnight then
			if self.totalrandomnightterrorsweight and self.totalrandomnightterrorsweight > 0 and self.nightterrors then
				local rnd = math.random()*self.totalrandomnightterrorsweight
				for k,v in pairs(self.nightterrors) do
					rnd = rnd - v.weight
					if rnd <= 0 and not table.contains(self.storedterrors, v.name) then
						if #self.storedterrors > (#self.nightterrors / 2) then
							table.remove(self.storedterrors, 1)
						end

						table.insert(self.storedterrors, v.name)
						v.name(player)
						
						return
					end
				end
			end
		end
	end
	
	local function PickCharacter(player)
		if TheWorld.state.isnight then
			if self.totalrandomshadowcharactersweight and self.totalrandomshadowcharactersweight > 0 and self.shadowcharacters then
				local rnd = math.random()*self.totalrandomshadowcharactersweight
				for k,v in pairs(self.shadowcharacters) do
					rnd = rnd - v.weight
					if rnd <= 0 and not table.contains(self.storedcharacters, v.character) then
						if #self.storedcharacters > (#CHARACTERS - 1) then
							table.remove(self.storedcharacters, 1)
						end

						table.insert(self.storedcharacters, v.character)
						
						if DayScaling() >= v.level then
							SpawnShadowCharacter(player, v.character)
						else
							self.inst:DoTaskInTime(0, PickCharacter, player)
						end
						
						return
					end
				end
			end
		end
	end
	
	local function onmoonphasechagned(inst, phase)
		if TheWorld.state.moonphase == "new" then
			TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 8, night = 8})
		end
	end
	
	local function SpawnVoxolophoneFunction(player)
	end

	local function CheckPlayersVoxolophone()
		if TheWorld.state.isnight and not self._hasspawnedvoxolophone or self._retry_spawning_voxolophone then
			self._retry_spawning_voxolophone = true

			if #_activeplayers > 0 then
				local player = _activeplayers[math.random(#_activeplayers)]

				if player ~= nil then
					local radius = 15 + math.random() * 15
					local theta = math.random() * 2 * PI
					local x, y, z = player.Transform:GetWorldPosition()
					local x1 = x + radius * math.cos(theta)
					local z1 = z - radius * math.sin(theta)
					local playercheck = TheSim:FindEntities(x1, y, z1, 30, {"player"})
					
					if TheWorld.Map:IsPassableAtPoint(x1, 0, z1) and (playercheck == nil or #playercheck == 0) then
						self._hasspawnedvoxolophone = true
						self._retry_spawning_voxolophone = false
							
						local voxolophone = SpawnPrefab("um_voxolophone")
						voxolophone.Transform:SetPosition(x1, y, z1)
						voxolophone:StartMusic()
					else
						self.inst:DoTaskInTime(1, CheckPlayersVoxolophone)
					end
				end
			end
		end
	end

					
	function self:LightStealTarget(inst)
		local lighttargets = {}
		local x, y, z = inst.Transform:GetWorldPosition()
			
		if x ~= nil then
			local ents = TheSim:FindEntities(x, y, z, 40)
			
			for i, v in ipairs(ents) do
				if v.components.burnable ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
					table.insert(lighttargets, { targetsource = v, light_type = "fire" })
					--return v, "fire"
				elseif v._light ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
					table.insert(lighttargets, { targetsource = v, light_type = "light" })
					--return v, "light"
				elseif v._lastpulsesync ~= nil and v.components.timer and v.components.timer:GetTimeLeft("extinguish") then
					table.insert(lighttargets, { targetsource = v, light_type = "star" })
					--return v, "star"
				end
			end
		end
		
		return lighttargets
		--return nil, nil
	end

	local function StartNightTerrors()
		if TheWorld.state.cycles > 1 and TheWorld.state.isnight then
			local voxo_check = TheSim:FindFirstEntityWithTag("um_voxolophone")
			
			if voxo_check == nil then
				if #_activeplayers > 0 then
					local spawn_vox_for = _activeplayers[math.random(#_activeplayers)]
					
					if spawn_vox_for ~= nil then
						SpawnPrefab("um_voxolophone").Transform:SetPosition(spawn_vox_for.Transform:GetWorldPosition())
					end
				end
			end
		
			local cycles = (TheWorld.state.cycles / 20)
			self.terror_count = 0
			
			self.terror_task = self.inst:DoPeriodicTask(15 - (cycles <= 5 and cycles or 5), function()
				if #_activeplayers > 0 then
					local player = _activeplayers[math.random(#_activeplayers)]

					if player ~= nil then
						if self.terror_count == 8 then
							print("Night Terrors Pick Character")
							PickCharacter(player)
						else
							print("Night Terrors Pick Terror")
							self:PickTerror(player)
						end
						
						self.terror_count = self.terror_count + 1
					end
				end
			end)
			
			self.snuffout_task = self.inst:DoPeriodicTask(0.25, function()
				if #_activeplayers > 0 then
					local player = _activeplayers[math.random(#_activeplayers)]
					if player ~= nil then
						local x, y, z = player.Transform:GetWorldPosition()
						
						--local lightsteal_target, lighttype = LightStealTarget(player, x, y, z)
						
						local fx = SpawnPrefab("um_shadow_attune_fx")
						
						if math.random() > 0.33 then
							local lightsteal_targettable = self:LightStealTarget(player)
							
							if lightsteal_targettable ~= nil then
								for i, v in ipairs(lightsteal_targettable) do
									if v.targetsource ~= nil and v.light_type ~= nil then
										local x1, y1, z1 = v.targetsource.Transform:GetWorldPosition()
										local voxolophone1 = TheSim:FindEntities(x1, y1, z1, 10, { "um_voxolophone" }, { "INLIMBO" })
										
										if voxolophone1 == nil or #voxolophone1 == 0 then
											local fx2 = SpawnPrefab("um_shadow_attune_fx")
						
											if v.light_type == "fire" then
												fx2.Transform:SetPosition(x1, y1, z1)
												v.targetsource.components.fueled:DoDelta(-24)
											elseif v.light_type == "light" then
												fx2.Transform:SetPosition(x1, y1, z1)
												v.targetsource.components.fueled:DoDelta(-24)
											elseif v.light_type == "star" then
												fx2.Transform:SetPosition(x1, y1, z1)
												v.targetsource.components.timer:SetTimeLeft("extinguish", v.targetsource.components.timer:GetTimeLeft("extinguish") - 100)
											end
											
											if math.random() > 0.5 then
												fx2.AnimState:PlayAnimation("attune_out")
												fx2.SoundEmitter:PlaySound("dontstarve/common/fireOut")
											end
										end
									end
								end
							end
						end
						
						x = x + math.random(-30, 30)
						z = z + math.random(-30, 30)
							
						local voxolophone = TheSim:FindEntities(x, y, z, 10, { "um_voxolophone" }, { "INLIMBO" })
						if voxolophone ~= nil and #voxolophone > 0 then
							fx.AnimState:SetMultColour(1, 1, 1, .6)
						end

						fx.Transform:SetPosition(x, 0, z)
						
						if math.random() > 0.5 then
							fx.AnimState:PlayAnimation("attune_out")
						end
					end
				end
			end)
		end
	end

    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
	for k, v in pairs(FUELTYPE) do
		if v ~= FUELTYPE.USAGE then --Not a real fuel
			table.insert(_fueltags, v.."_fueled")
		end
	end

    for i, v in ipairs(AllPlayers) do
        table.insert(_activeplayers, v)
    end
	
	local function CheckPhase(inst, data)
		if self.terror_task ~= nil then
			self.terror_task:Cancel()
			self.terror_task = nil
		end
		
		if self.snuffout_task ~= nil then
			self.snuffout_task:Cancel()
			self.snuffout_task = nil
		end
		
		if TheWorld.state.cycles > 5 and data.moonphase == "new" then
			TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 8, night = 8})
		end
	end
	
	local function ForceTerrors(inst, data)
		TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 8, night = 8})
	end
	
    self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
    self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
    self:WatchWorldState("isfullmoon", CheckPlayersVoxolophone)
	self:WatchWorldState("isnewmoon", function() self.inst:DoTaskInTime(6, StartNightTerrors) end)
	--self:WatchWorldState("isnight", function() self.inst:DoTaskInTime(6, StartNightTerrors) end)
	--self.inst:ListenForEvent("cycles", ForceTerrors)
	self.inst:ListenForEvent("moonphasechanged2", CheckPhase)
end)

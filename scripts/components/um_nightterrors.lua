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
	self.stanton_spawned = false
    self._hasspawnedvoxolophone = false
    self._retry_spawning_voxolophone = false
	
	
	self.ongoing = false
    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
	
	local function ShadowPieceNearby(player)
		local x,y,z = player.Transform:GetWorldPosition()
		if TheWorld.state.cycles < 31 and #TheSim:FindEntities(x,y,z,40,{"shadowchesspiece"}) > 0 then -- This exception only applies to day 21, or another day if you mess with the moon cycle
			return true
		end
	end
	
	local function DelayHoundsAndGiantsIfNecessary()
		if self.inst.components.hounded then
			local houndtime = self.inst.components.hounded:GetTimeToAttack()/(60*8) --Convert seconds to DS days 
			if houndtime < 5*60*8 then
				self.inst.components.hounded:OnUpdate(-5*60*8) -- Tell it to back up
			end	
		end
	end
		
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
	
	local function CalcDayTime()
		local daytime = 6
		if TheWorld.state.iswinter then
			daytime = 4
		elseif TheWorld.state.isautumn or TheWorld.state.isspring then
			daytime = 5
		end
		return daytime
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
    --[[ Atmosphere ]]
    --------------------------------------------------------------------------	
	
	
	local function SpawnSkitts(player)
		local skitttime = 10 * math.random() * 2
		if TheWorld.state.isnight then
			player:DoTaskInTime(skitttime, function()
				local x, y, z = player.Transform:GetWorldPosition()
				local num_skitts = 150
				for i = 1, num_skitts do
					player:DoTaskInTime(0.2 * i + math.random() * 0.3, function()
						local skitts = SpawnPrefab("rneshadowskittish")
						skitts.Transform:SetPosition(x + math.random(-12,12), y, z + math.random(-12,12))
					end)
				end
			end)
		end
	end
	
	--THUNDER----------------------------

	local function SpawnLightning(player)
		player:DoTaskInTime(10 * math.random() * 2, function()
				local x, y, z = player.Transform:GetWorldPosition()
				local lightnings = 1
				for i = 1, lightnings do
					player:DoTaskInTime(0.2 * i + math.random(4) * 0.3, function()
						if math.random() > 0.33 then
							local pos = Vector3(x + math.random(-10,10), y, z + math.random(-10,10))
							TheWorld:PushEvent("ms_sendlightningstrike", pos)
						else
							local lightningstrike = SpawnPrefab("hound_lightning")
							lightningstrike.Transform:SetPosition(x + math.random(-10,10), y, z + math.random(-10,10))
						end
					end)
				end
		end)
	end

	local function SpawnThunderClose(player)
		player:DoTaskInTime(10 * math.random() * 2, function()
				local x, y, z = player.Transform:GetWorldPosition()
				local thunders = 1
				for i = 1, thunders do
					player:DoTaskInTime(0.2 * i + math.random(4) * 0.3, function()
						--local thunder = SpawnPrefab("thunder_close")
						--thunder.Transform:SetPosition(x + math.random(-10,10), y, z + math.random(-10,10))
						SpawnPrefab("thunder_close")
						player:DoTaskInTime(10 * math.random(), SpawnLightning)
					end)
				end
		end)
	end

	local function SpawnThunderFar(player)
		if not TheWorld.state.israining then
			TheWorld:PushEvent("ms_forceprecipitation")
		end

		player:DoTaskInTime(10 * math.random() * 2, function()
				local x, y, z = player.Transform:GetWorldPosition()
				local thunders = math.random(15,20)
				for i = 1, thunders do
					player:DoTaskInTime(0.6 * i + math.random(6) * 0.3, function()
						--local thunder = SpawnPrefab("thunder_far")
						--thunder.Transform:SetPosition(x + math.random(-10,10), y, z + math.random(-10,10))
						SpawnPrefab("thunder_far")
						player:DoTaskInTime(10 * math.random(), SpawnThunderClose)
					end)
				end
		end)
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
		local scale = TheWorld.state.cycles / 20 
		return scale
	end
	
	local NEARFIRE_MUST_TAGS = { "fire" }
	local NEARFIRE_CANT_TAGS = { "_equippable" }
	local _fueltags = {}
	local _map = TheWorld.Map

	local function SpawnHand(player) -- Standard fire hands, not grabby hands... should make them able to reach for dwarf star lights
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
	end
	
	local function StalkerFadeOut(stalker)
		stalker.opacity = stalker.opacity - 0.01
		local opacity = stalker.opacity
		inst.AnimState:SetMultColour(1,1,1,opacity)
		if stalker.opacity < 0 then
			stalker:Remove()
		end	
	end
	
	local function StalkerFadeIn(stalker)
		stalker.opacity = stalker.opacity + 0.005
		local opacity = stalker.opacity
		stalker.AnimState:SetMultColour(1,1,1,opacity)
		if stalker.opacity > 1 then
			StalkerFadeOut(stalker)
		else
			StalkerFadeIn(stalker)
		end
	end
	
	local function SpawnLightFlowersNFerns(player)
		local x,y,z = player.Transform:GetWorldPosition()
        local offset = FindWalkableOffset(player:GetPosition(), math.random() * 2 * PI, 30, 36, true)
        if offset ~= nil then
            x = offset.x + x
            z = offset.z + z
        end
		local stalker = SpawnPrefab("stalker_forest") -- Instead temporarily make a ghost of the stalker, he'll immediately go away. Sidenote, why is he called a "Stalker", he does no stalking whatsoever.
		stalker.Transform:SetPosition(x,y,z)
		stalker.Physics:ClearCollisionMask()
		stalker:DoTaskInTime(FRAMES,StalkerFadeIn)
		stalker.opacity = 0
	end
		
	local chesspiece = {"shadow_bishop","shadow_rook","shadow_knight"}
	local function SpawnChessPiece(player) -- only spawn 1 chess piece
		local choice_chess = math.random(1,#chesspiece)
		local x,y,z = player.Transform:GetWorldPosition()
        local offset = FindWalkableOffset(player:GetPosition(), math.random() * 2 * PI, 16, 24, true)
        if offset ~= nil then
            x = offset.x + x
            z = offset.z + z
        end
		SpawnPrefab(chesspiece[choice_chess]).Transform:SetPosition(x,y,z)
	end
		
	local function SpawnFissuresFunction(player)
		local x, y, z = player.Transform:GetWorldPosition()

        local offset = FindWalkableOffset(player:GetPosition(), math.random() * 2 * PI, 10, 12, true)
        if offset ~= nil then
            x = offset.x + x
            z = offset.z + z
        end
		
		if TheWorld.state.isnight then --AXE incase the function gets close to day when it's called.
			SpawnPrefab("rnefissure").Transform:SetPosition(x, 0, z)
		end
	end

	local function SpawnFissures(player)
		local fissures = 2+math.floor(math.random()*3, 3)
		local chances = 1
		for i = chances, fissures do
			player:DoTaskInTime(0.2 * i + math.random(4) * 0.3, function()
				SpawnFissuresFunction(player)
			end)
		end

	end
	
	local function SpawnStanton(player)
		local x,y,z = player.Transform:GetWorldPosition()
        local offset = FindWalkableOffset(player:GetPosition(), math.random() * 2 * PI, 4, 6, true)
        if offset ~= nil then
            x = offset.x + x
            z = offset.z + z
        end
		SpawnPrefab("stanton").Transform:SetPosition(x,y,z)
		self.stanton_spawned = true --AXE limit the number of Stantons per night terror to just 1.
	end

	local function SpawnShadowGrabby(player) -- Grabby hands, these teleport the player into the darkness
		if TheWorld.state.isnight then
			for i = 1, 2 + math.random(2) do
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local targetplayer = FindEntity(player,20^2,nil,{"player"})
				local x,y,z
				if targetplayer then
					x,y,z = targetplayer.Transform:GetWorldPosition()
				else
					x,y,z = player.Transform:GetWorldPosition()
				end
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)
			
				for i = 1, 8 do
					if (light <= 0.2 or i == 8) then
						local ent = SpawnPrefab("rne_grabbyshadows")
						ent.Transform:SetPosition(x1, 0, z1)
						DespawnOnDay(ent)
						ent:AddTag("nightterror")
						break
					end
				end
			end
		end
	end

	local function SpawnShadowVortex(player) -- Shadow Vortoex, kills the player...
		if TheWorld.state.isnight then
			for i = 1, 100 do
				local radius = 25 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)
				if (light <= 0.1 or i == 100) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then -- Push the vortex further in the night
					local ent = SpawnPrefab("shadowvortex")
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)
					ent:AddTag("nightterror")
					break
				end
			end
		end
	end

	local function SpawnMindWeavers(player) -- Mind Weavers, try to kill the player
		if TheWorld.state.isnight then
			TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.MINDWEAVER }) 
			
			for i = 1, PlayerScaling(player) do
				local x, y, z = player.Transform:GetWorldPosition()
				local ent = SpawnPrefab("mindweaver")
				ent.Transform:SetPosition(x + math.random(-5, 5), y, z + math.random(-5, 5))
				ent:AddTag("nightterror")
			end
		end
	end
	
	local function SpawnNightCrawlers(player) -- Night Crawlers, try to kill the player
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
						ent:AddTag("nightterror")
						break
					end
				end
			end
		end
	end
	
	local function SpawnLeeches(player) -- Leeches, Try to kill the player, slowly
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
						ent:AddTag("nightterror")
						TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.UM_LEECH })
						
						break
					end
				end
			end
		end
	end
	
	local function SpawnFuelSeekers(player) -- Fuel seekers, try to remove the bases's fire
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
							ent:AddTag("nightterror")
							TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.FUELSEEKER }) 
					
							break
						end
					end
				end
			end
		end
	end

	local function SpawnHaunt(player) -- Haunt, move the player's stuff around
		if TheWorld.state.isnight then
			local x, y, z = player.Transform:GetWorldPosition()
			local structures = TheSim:FindEntities(x, y, z, 30, { "structure" })
			
			if structures ~= nil and #structures > 0 then
				for i, v in ipairs(structures) do
					for i = 1, 3 do
						if v ~= nil then
							local players = TheSim:FindEntities(x, y, z, 8, { "player" })
							local x1,y1,z1 = players
							if players == nil or #players == 0 then
								local ent = SpawnPrefab("um_haunt")
								if ent then
									ent.haunt_target = v
									ent.Transform:SetPosition(x1, 0, z1)
									DespawnOnDay(ent)
									return
								end
							end
						end
					end
				end
			end
		end
	end

	local function SpawnHeckler(player) -- Spitter, try to spread goo
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
					ent:AddTag("nightterror")
					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.HECKLER })
					
					break
				end
			end
		end
	end

	local function SpawnNightmareCreature(player) -- generic-ass nightmares
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
					ent:AddTag("nightterror")
					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.NIGHTMARECREATURE })
					count = count + 1
					if count >= 2 then
						break
					end
					
					
					
				end
			end
		end
	end

	local function SpawnShadowCharacter(player, character) -- shadow characters
		if TheWorld.state.isnight and character ~= nil then
			for i = 1, 8 do
				local radius = 15 + math.random() * 15
				local theta = math.random() * 2 * PI
				local x, y, z = player.Transform:GetWorldPosition()
				local x1 = x + radius * math.cos(theta)
				local z1 = z - radius * math.sin(theta)
				local light = TheSim:GetLightAtPoint(x1, 0, z1)

				if (light <= 0.2 or i == 8) and TheWorld.Map:IsPassableAtPoint(x1, 0, z1) then
					--TheNet:Announce(character)
					local ent = SpawnPrefab(character)
					ent.Transform:SetPosition(x1, 0, z1)
					DespawnOnDay(ent)
					ent:AddTag("nightterror")
					TheWorld:PushEvent("um_voxolophone_warning", { threat = STRINGS.UM_VOXOLOPHONE.SHADOW_WARNING.SHADOWCHARACTER })
					
					break
				end
			end
		end
	end
	local function Nothing(player)
		-- While there are few/no versions of high sanity effects, we need to have "nothing" occur so Skitts isn't everywhere.
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
		data._retry_spawning_voxolophone = self._retry_spawning_voxolophone
			
		return data
	end

	function self:OnLoad(data)
		if data ~= nil then
			if data._hasspawnedvoxolophone then
				self._hasspawnedvoxolophone = data._hasspawnedvoxolophone
			end
			
			
			if data._retry_spawning_voxolophone then
				self._retry_spawning_voxolophone = data._retry_spawning_voxolophone
			end
		end
	end

	local ENVIRONMENTAL = 
	{
		ThunderStorm = { name = SpawnThunderFar, weight = .3, },
	}
	
	local HIGHSANITY =
	{
		SpawnSkitts = { name = SpawnSkitts, weight = .3, },
		Nothing = {name = Nothing, weight = 3},
		SpawnStanton = { name = SpawnStanton, weight = .1, tag = "skeleton"},
		--SpawnGhostOfStalker = { name = SpawnLightFlowersNFerns, weight = .05},
	}
	local HIGHMEDSANITY = 
	{	
		SpawnHand = { name = SpawnHand, weight = .3, },
		SpawnHaunt = { name = SpawnHaunt, weight = .5, },
		SpawnStanton = { name = SpawnStanton, weight = .2, tag = "skeleton"},
		--SpawnGhostOfStalker = { name = SpawnLightFlowersNFerns, weight = .1},
	}
	local MEDSANITY = 
	{	
		SpawnHand = { name = SpawnHand, weight = .3, },
		SpawnHaunt = { name = SpawnHaunt, weight = .5, },
		SpawnShadowGrabby = { name = SpawnShadowGrabby, weight = .5, },
		SpawnNightCrawlers = { name = SpawnNightCrawlers, weight = .5, },
		SpawnFuelSeekers = { name = SpawnFuelSeekers, weight = .5, },
		
	}
	local LOWMEDSANITY = 
	{
		SpawnNightmareCreature = { name = SpawnNightmareCreature, weight = .3, },
		SpawnMindWeavers = { name = SpawnMindWeavers, weight = .5, },
		SpawnHeckler = { name = SpawnHeckler, weight = .5, },
		SpawnShadowWilson = { name = SpawnShadowCharacter, weight = .5, character = "swilson"},
	
	}
	local LOWSANITY = 
	{
		SpawnShadowVortex = { name = SpawnShadowVortex, weight = .9, },	
		SpawnFissuresFunction = { name = SpawnFissuresFunction, weight = .3, },
		SpawnNightmareCreature = { name = SpawnNightmareCreature, weight = .3, },
	}
	
	local function weighted_random_choice(items)
		local total_weight = 0
		for i, v in ipairs(items) do
			total_weight = total_weight + v.weight
		end

		local random_value = math.random() * total_weight
		local cumulative_weight = 0
		for i, v in pairs(items) do
			cumulative_weight = cumulative_weight + v.weight
			if random_value <= cumulative_weight then
				return i 
			end
		end
		return 1
	end

	function self:DoTerror(player,level,bank)
		if self.stanton_spawned then
			local to_remove = {}
			for i,v in ipairs(bank) do
				if v.tag == "skeleton" then
					table.insert(to_remove,i)
				end
			end
			if #to_remove > 0 then
				for i,v in ipairs_reverse(self.screenstack) do
					table.remove(bank,v)
				end
			end
		end
		local choice = bank[weighted_random_choice(bank)].name
		--TheNet:Announce(level)
		choice(player)
	end
	
	function self:PickTerror(player)
		if TheWorld.state.isnight then
			local sanity = player.components.sanity
			if sanity then
				local pct = sanity:GetPercent()
				
				if pct >= 0.8 then -- Sanity is high, do something mundane.
					local level = "High Sanity Trigger"
					self:DoTerror(player,level,HIGHSANITY)
				end
				if pct < 0.8 and pct >= 0.6 then -- Sanity is still high, do something a bit creeper, but don't do multiple things.
					local level = "High-med Sanity Trigger"
					self:DoTerror(player,level,HIGHMEDSANITY)
				end
				if pct < 0.6 then -- You're on the way to insanity, begin hostilities.
					local level = "Med Sanity Trigger"
					self:DoTerror(player,level,MEDSANITY)
				end
				if pct < 0.4 then -- You're almost insane, do hostile stuff, and the stuff in the tier above it should get a roll too! 
					local level = "Med-low Sanity Trigger"
					self:DoTerror(player,level,LOWMEDSANITY)
				end
				if pct < 0.2 then -- You're insane, do very hostile stuff, and do the stuff above all the way to the medium sanity level.
					local level = "Low Sanity Trigger"
					self:DoTerror(player,level,LOWSANITY)
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
			DelayHoundsAndGiantsIfNecessary()
			self.ongoing = true
			self.stanton_spawned = false
			local cycles = (TheWorld.state.cycles / 20)
			if #_activeplayers > 0 then
				for i,v in ipairs(_activeplayers) do
					v.components.terrorized.nightterror = 0
				end
			end
			
			self.terror_task = self.inst:DoPeriodicTask(40 - (cycles <= 5 and cycles or 5), function()
				if #_activeplayers > 0 then
					local player = _activeplayers[math.random(#_activeplayers)]
					
					if player then
						if TheWorld.state.isnight then
							print("Night Terrors Pick Terror")
							self:PickTerror(player)
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
		
		if TheWorld.state.cycles > 5 and data.moonphase == "new" then
			local daytime = CalcDayTime()
			TheWorld:PushEvent("ms_setclocksegs", {day = daytime, dusk = 8-daytime, night = 8})
		end
		
		if self.ongoing then
			self.ongoing = false
			if #_activeplayers > 0 then
				for i,v in ipairs(_activeplayers) do
					v.components.terrorized.nightterror = 1
				end
			end
		end
	end
	
	local function ForceTerrors(inst, data)
		local daytime = CalcDayTime()
		TheWorld:PushEvent("ms_setclocksegs", {day = daytime, dusk = 8-daytime, night = 8})
	end
	
    self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
    self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
	self:WatchWorldState("isnewmoon", function() self.inst:DoTaskInTime(6, StartNightTerrors) end)
	self.inst:ListenForEvent("moonphasechanged2", CheckPhase)
end)

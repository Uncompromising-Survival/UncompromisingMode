return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_tentacle_repopulator should not exist on client")
    --AXE This is essentially a big ol bat in the cave, pooping everywhere...

    local function CheckForOtherTentacles(pos)
        local tentacles = TheSim:FindEntities(pos.x, 0, pos.z, 4, { "tentacle" })
        if not (tentacles and #tentacles > 0) then
            return true
        end
        return false
    end

    local function NotBase(pos)
        local structures = TheSim:FindEntities(pos.x, 0, pos.z, 32, { "structure" })
        if not (structures and #structures > 19) then
            return true
        end
        return false
    end
	
    local function NotTooClose(pos)
        local ents = TheSim:FindEntities(pos.x, 0, pos.z, 2)
        if not (ents and #ents > 0) then
            return true
        end
        return false
    end
	
    local function IterateThroughTiles(tiles)
        shuffleArray(tiles)
        local target_location = {}
        target_location.x = tiles[1].x
        target_location.z = tiles[1].z
        --print("target_location = ", target_location.x, target_location.z)
        if target_location and CheckForOtherTentacles(target_location) and NotBase(target_location) and NotTooClose(target_location) then -- and NotBase(target_location) then
            return target_location,tiles
        elseif tiles and #tiles > 0 then
            table.remove(tiles, 1)
            return IterateThroughTiles(tiles)
        end
    end


    local function SpawnTentacle(ent,tiles)
        local location,tiles = IterateThroughTiles(tiles)
        if location then --If you maxwelled the whole ocean I swear
            SpawnPrefab(ent).Transform:SetPosition(location.x, 0, location.z)
        end
        return tiles
    end

	function self:PopulateTentacles()
		local marshtiles = TheWorld.components.um_tilelogger:AnalyzeWorld(WORLD_TILES["MARSH"])
		local moontiles
		if TheWorld:HasTag("cave") then
			moontiles = TheWorld.components.um_tilelogger:AnalyzeWorld(WORLD_TILES["UM_FLOODWATER_GROTTO"])
		end
		for i = 1,math.random(80,120),1 do -- Generously 100..
            marshtiles = SpawnTentacle("tentacle",marshtiles)
		end
        if TheWorld:HasTag("cave") then
            for i = 1,math.random(20,30),1 do -- Generously 25..
                moontiles = SpawnTentacle("um_tentacle_moon",moontiles)
            end
        end
	end

    inst:WatchWorldState("onspring", function(inst, data)
		self:PopulateTentacles()
    end)
end)

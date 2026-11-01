return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_tentacle_repopulator should not exist on client")

    local function CheckForOtherTentacles(pos)
        local tentacles = TheSim:FindEntities(pos.x, 0, pos.z, 4, {"tentacle"})
        if not next(tentacles) then
            return true
        end
        return false
    end

    local function NotBase(pos)
        local structures = TheSim:FindEntities(pos.x, 0, pos.z, 32, {"structure"})
        if #structures < 19 then
            return true
        end
        return false
    end
    
    local function NotTooClose(pos)
        local ents = TheSim:FindEntities(pos.x, 0, pos.z, 2)
        if not next(ents) then
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
            return target_location, tiles
        elseif next(tiles) then
            table.remove(tiles, 1)
            return IterateThroughTiles(tiles)
        end
    end

    local function SpawnTentacle(ent, tiles)
        local location, tiles = IterateThroughTiles(tiles)
        if location then
            SpawnPrefab(ent).Transform:SetPosition(location.x, 0, location.z)
        end
        return tiles
    end

    function self:PopulateTentacles()
        local um_tilelogger = TheWorld.components.um_tilelogger
        local marshtiles = um_tilelogger:AnalyzeWorld(WORLD_TILES["MARSH"])
        for i = 1, math.random(80, 120), 1 do -- Generously 100..
            marshtiles = SpawnTentacle("tentacle", marshtiles)
        end
        if TheWorld:HasTag("cave") then
            local moontiles = um_tilelogger:AnalyzeWorld(WORLD_TILES["UM_FLOODWATER_GROTTO"])
            for i = 1, math.random(20, 30), 1 do -- Generously 25..
                moontiles = SpawnTentacle("um_tentacle_moon", moontiles)
            end
        end
    end

    inst:WatchWorldState("isspring", function(inst, isspring)
        if isspring then
            self:PopulateTentacles()
        end
    end)
end)
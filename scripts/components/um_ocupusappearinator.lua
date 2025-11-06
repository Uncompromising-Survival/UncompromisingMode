return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_ocupusappearinator should not exist on client")

    local function FindOcupi()
        local tag = "um_ocupus_core"
        local entities = {}
        for k, v in pairs(Ents) do
            if v:HasTag(tag) then
                table.insert(entities, v)
            end
        end
        return #entities
    end

    local function CheckForOtherOcupi(pos)
        print(pos.x, pos.z)
        print(#TheSim:FindEntities(pos.x, 0, pos.z, 40, { "um_ocupus_core" }))
        if #TheSim:FindEntities(pos.x, 0, pos.z, 40, { "um_ocupus_core" }) == 0 then
            return true
        end
        return false
    end


    local function IterateThroughTiles(tiles)
        --print("iterating through tiles...")
        for k, v in ipairs(tiles) do
            --print("k,v", k,v)
            local offset = math.random() * 4
            local target_location = {}
            target_location.x = v.x
            target_location.z = v.z
            --print("target_location = ", target_location.x, target_location.z)
            if CheckForOtherOcupi(target_location) then
                --print("found valid location")
                target_location.x = v.x + offset
                target_location.z = v.z + offset

                return target_location
            else
                table.remove(tiles, k)
                IterateThroughTiles(tiles)
            end
        end
    end

    local function FindLocation()
        if TheWorld.components.um_tilelogger and TheWorld.components.um_tilelogger.Hazardous then
            return IterateThroughTiles(TheWorld.components.um_tilelogger.Hazardous)
        end
    end

    local function SpawnOcupi()
        local locationfornewoct = FindLocation()
        if locationfornewoct then --If you maxwelled the whole ocean I swear
            SpawnPrefab("um_ocupus").Transform:SetPosition(locationfornewoct.x, 0, locationfornewoct.z)
        end
    end

    local function OnSeasonTick(src, data)
        local Ocupus = FindOcupi()
        if Ocupus and Ocupus < 1 then
            SpawnOcupi()
            SpawnOcupi()
        elseif Ocupus < 3 then
            SpawnOcupi()
        elseif Ocupus < 4 and math.random() > 0.5 then
            SpawnOcupi()
        elseif Ocupus < 6 and math.random() > 0.75 then
            SpawnOcupi()
        elseif math.random() > 0.9 then
            SpawnOcupi()
        end
    end

    function self:FirstRun()
        SpawnOcupi()
        SpawnOcupi()
        SpawnOcupi()
    end

    function self:OnSave()
        local data = {}
        data.firstrun = self.firstrun
    end

    function self:OnLoad(data)
        if data then
            if data.firstrun then
                self.firstrun = data.firstrun
            end
        end
    end

    function self:OnPostInit()
        self.firstrun = true
        self.inst:DoTaskInTime(0, function(inst)
            if not self.firstrun then
                inst.components.um_ocupusappearinator:FirstRun()
            end
        end)
    end

    self.inst:ListenForEvent("seasontick", OnSeasonTick, TheWorld)
end)

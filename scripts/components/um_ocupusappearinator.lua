return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_ocupusappearinator should not exist on client")

    self.ocupi = {}

    function self:CountOcupi()
        --can't use #self.ocupi because it's a map, doesn't have a numerical idx
        local count = 0
        for k, v in pairs(self.ocupi) do
            count = count + 1
        end

        return count
    end

    local function CheckForOtherOcupi(pos)
        if self:CountOcupi() > 0 then
            for guid, ent in pairs(self.ocupi) do
                if ent ~= nil and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z) <= 250 * 250 then
                    return false
                end
            end
            return true
        else
            return true
        end
    end

    local function IterateThroughTiles(tiles)
        for k, v in ipairs(tiles) do
            local offset = math.random() * 4
            local target_location = {}
            target_location.x = v.x
            target_location.z = v.z

            if CheckForOtherOcupi(target_location) then
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
            return IterateThroughTiles(deepcopy(TheWorld.components.um_tilelogger.Hazardous))
        end
    end

    function self:SpawnOcupi()
        local pos = FindLocation()
        if pos then --If you maxwelled the whole ocean I swear
            SpawnPrefab("um_ocupus").Transform:SetPosition(pos.x, 0, pos.z)
        end
    end

    local function OnSeasonTick(src, data)
        local Ocupus = self:CountOcupi()
        if Ocupus and Ocupus < 1 then
            self:SpawnOcupi()
            self:SpawnOcupi()
        elseif Ocupus < 3 then
            self:SpawnOcupi()
        elseif Ocupus < 4 and math.random() > 0.5 then
            self:SpawnOcupi()
        elseif Ocupus < 6 and math.random() > 0.75 then
            self:SpawnOcupi()
        end
    end

    function self:FirstRun()
        self:SpawnOcupi()
        self:SpawnOcupi()
        self:SpawnOcupi()
    end

    function self:RegisterOcupus(ent)
        if ent ~= nil and ent:IsValid() and self.ocupi[ent.GUID] == nil then
            self.ocupi[ent.GUID] = ent
        end
    end

    function self:UnregisterOcupus(ent)
        self.ocupi[ent.GUID] = nil
        local new_ocupi = {}

        for guid, ent in pairs(self.ocupi) do
            if ent ~= nil then
                new_ocupi[guid] = ent
            end
        end

        self.ocupi = new_ocupi
    end

    function self:OnSave()
        local data = {}

        data.firstrun = self.firstrun

        return data
    end

    function self:OnLoad(data)

        if data then
            if data.firstrun then
                self.firstrun = data.firstrun
            end
        end
    end

    function self:OnPostInit()
        --need to wait for um_tilelogger to register tiles.
        self.inst:DoTaskInTime(1, function(inst)
            if not self.firstrun then
                inst.components.um_ocupusappearinator:FirstRun()
                self.firstrun = true
            end
        end)
    end

    self.inst:ListenForEvent("seasontick", OnSeasonTick, TheWorld)
end)

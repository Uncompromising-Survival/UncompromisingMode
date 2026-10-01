return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_ocupusappearinator should not exist on client")

    self.ocupi = {}

    local function CheckForOtherOcupi(pos)
        for guid, ent in pairs(self.ocupi) do
            if ent and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z) <= 250 * 250 then
                return false
            end
        end
        return true
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
        local um_tilelogger = TheWorld.components.um_tilelogger
        local Hazardous = um_tilelogger and um_tilelogger.Hazardous
        if Hazardous then return IterateThroughTiles(deepcopy(Hazardous)) end
    end

    function self:SpawnOcupi()
        local pos = FindLocation()
        if pos then --If you maxwelled the whole ocean I swear
            SpawnPrefab("um_ocupus").Transform:SetPosition(pos.x, 0, pos.z)
        end
    end

    local function OnSeasonTick(src, data)
        local ocupus = GetTableSize(self.ocupi)
        local rand = math.random()
        if ocupus < 1 then
            for i = 1, 2 do
                self:SpawnOcupi()
            end
        elseif ocupus < 3 then
            self:SpawnOcupi()
        elseif ocupus < 4 then
            if rand > .5 then self:SpawnOcupi() end
        elseif ocupus < 6 then
            if rand > .75 then self:SpawnOcupi() end
        end
    end

    function self:FirstRun()
        for i = 1, 3 do 
            self:SpawnOcupi()
        end
    end

    function self:RegisterOcupus(ent)
        if ent and ent:IsValid() and not self.ocupi[ent.GUID] then
            self.ocupi[ent.GUID] = ent
        end
    end

    function self:UnregisterOcupus(ent)
        self.ocupi[ent.GUID] = nil
        local new_ocupi = {}

        for guid, ent in pairs(self.ocupi) do
            if ent then new_ocupi[guid] = ent end
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
                self:FirstRun()
                self.firstrun = true
            end
        end)
    end

    self.inst:ListenForEvent("seasontick", OnSeasonTick, TheWorld)
end)
return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_ocupusappearinator should not exist on client")

    self.ocupi = {}

    local function CountOcupi()
        --can't use #self.ocupi because it's a map, doesn't have a numerical idx
        local count = 0
        for k, v in pairs(self.ocupi) do
            count = count + 1
        end

        return count
    end

    local function CheckForOtherOcupi(pos)
        print("checking for other ocupi")
        print("min dist", 40 * 40)
        print("ocupi count", CountOcupi())

        if CountOcupi() > 0 then
            for guid, ent in pairs(self.ocupi) do
                print("curr dist for ", ent, ent ~= nil and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z))
                if ent ~= nil and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z) <= 40 * 40 then
                    print("returning false because there's other ocupi that's too close")
                    return false
                end
            end
            print("returning true because there's no nearby ocupi")
            return true
        else
            print("returning true because there's no ocupi")
            return true
        end
    end


    local function IterateThroughTiles(tiles)
        print("iterating through tiles")
        --print("iterating through tiles...")
        for k, v in ipairs(tiles) do
            --print("k,v", k,v)
            local offset = math.random() * 4
            local target_location = {}
            target_location.x = v.x
            target_location.z = v.z
            --print("target_location = ", target_location.x, target_location.z)
            print("checking for other ocupi at", target_location, CheckForOtherOcupi(target_location))
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
        print("finding location")
        print("tilelogger", TheWorld.components.um_tilelogger)
        print("haz", TheWorld.components.um_tilelogger.Hazardous)
        if TheWorld.components.um_tilelogger and TheWorld.components.um_tilelogger.Hazardous then
            return IterateThroughTiles(deepcopy(TheWorld.components.um_tilelogger.Hazardous))
        end
    end



    local function SpawnOcupi()
        print("spawn ocupi")
        local pos = FindLocation()
        print("pos", pos)
        if pos then --If you maxwelled the whole ocean I swear
            SpawnPrefab("um_ocupus").Transform:SetPosition(pos.x, 0, pos.z)
        end
    end

    local function OnSeasonTick(src, data)
        print("season tick")
        local Ocupus = CountOcupi()
        if Ocupus and Ocupus < 1 then
            SpawnOcupi()
            SpawnOcupi()
        elseif Ocupus < 3 then
            SpawnOcupi()
        elseif Ocupus < 4 and math.random() > 0.5 then
            SpawnOcupi()
        elseif Ocupus < 6 and math.random() > 0.75 then
            SpawnOcupi()
        end
    end

    function self:FirstRun()
        print("doing first run")
        SpawnOcupi()
        SpawnOcupi()
        SpawnOcupi()
    end

    function self:RegisterOcupus(ent)
        print("registering ocupus", ent)
        if ent ~= nil and ent:IsValid() then
            self.ocupi[ent.GUID] = ent
        end
    end

    function self:UnregisterOcupus(ent)
        print("unregistering an ocupus")
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
        data.ocupi = {}

        data.retrofit = self.retrofit

        local references = {}

        for k, v in pairs(self.ocupi) do
            table.insert(data.ocupi, v.GUID)
            table.insert(references, v.GUID)
        end

        return data, references
    end

    function self:OnLoad(data)
        if data then
            if data.firstrun then
                self.firstrun = data.firstrun
            end
            if data.retrofit then
                self.retrofit = data.retrofit
            end
        end
    end

    function self:OnPostInit()
        print(c_countprefabs("um_ocupus"))
        --need to wait for um_tilelogger to register tiles.
        print("doing first run in 1s")
        self.inst:DoTaskInTime(1, function(inst)
            print("first run task")
            if not self.firstrun then
                print("first run being done")
                inst.components.um_ocupusappearinator:FirstRun()
                self.firstrun = true
            end
        end)
    end

    function self:LoadPostPass(newents, savedata)

        print("load post pass")
        if savedata.ocupi then
            for k, guid in pairs(savedata.ocupi) do
                if newents[guid] then
                    self.ocupi[guid] = newents[guid]
                end
            end
        end

        if not self.retrofit then
            print("doing retro")
            print("CountOcupi", CountOcupi())
            --in case old worlds have too many.
            if CountOcupi() > 6 then
                print("has too many ocupi")
                while CountOcupi() > 6 do
                    print("while loop")
                    for k, v in pairs(self.ocupi) do
                        print("for loop")
                        v:Remove()
                        break
                    end
                end
            end
            print("retrofit done")
            self.retrofit = true
        end
    end

    self.inst:ListenForEvent("seasontick", OnSeasonTick, TheWorld)
end)

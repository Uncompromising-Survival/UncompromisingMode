return Class(function(self, inst)
    self.inst = inst
    assert(TheWorld.ismastersim, "um_snowstormmanager should not exist on client")

    self.snowpiles = {}
    self.rimeweeds = {}
    function self:CountSnowpiles()
        --can't use #self.snowpiles because it's a map, doesn't have a numerical idx
        local count = 0
        for k, v in pairs(self.snowpiles) do
            count = count + 1
        end

        return count
    end

    function self:CheckForOtherSnowpiles(pos, dist_sq)
        local found = 0

        for guid, ent in pairs(self.snowpiles) do
            if ent ~= nil and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z) <= dist_sq then
                found = found + 1
            end
        end

        return found
    end

    function self:RegisterSnowpile(ent)
        if ent ~= nil and ent:IsValid() and self.snowpiles[ent.GUID] == nil then
            self.snowpiles[ent.GUID] = ent
        end
    end

    function self:UnregisterSnowpile(ent)
        self.snowpiles[ent.GUID] = nil
        local new_piles = {}

        for guid, ent in pairs(self.snowpiles) do
            if ent ~= nil then
                new_piles[guid] = ent
            end
        end

        self.snowpiles = new_piles
    end

    --rimeweeds
    function self:CountRimeweeds()
        --can't use #self.snowpiles because it's a map, doesn't have a numerical idx
        local count = 0
        for k, v in pairs(self.rimeweeds) do
            count = count + 1
        end

        return count
    end

    function self:CheckForOtherRimeweeds(pos, dist_sq)
        local found = 0

        for guid, ent in pairs(self.rimeweeds) do
            if ent ~= nil and ent:IsValid() and ent:GetDistanceSqToPoint(pos.x, 0, pos.z) <= dist_sq then
                found = found + 1
            end
        end

        return found
    end

    function self:RegisterRimeweed(ent)
        if ent ~= nil and ent:IsValid() and self.rimeweeds[ent.GUID] == nil then
            self.rimeweeds[ent.GUID] = ent
        end
    end

    function self:UnregisterRimeweed(ent)
        if self.rimeweeds[ent.GUID] ~= nil then
            self.rimeweeds[ent.GUID] = nil
            local new_piles = {}

            for guid, ent in pairs(self.rimeweeds) do
                if ent ~= nil then
                    new_piles[guid] = ent
                end
            end

            self.rimeweeds = new_piles
        end
    end
end)

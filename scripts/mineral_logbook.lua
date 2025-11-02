--[[
TODO:
-- automatically fix broken saved data, prevent broken data from being loaded.
-- try to prevent brokens save data from being saved to begin with
]]

local MineralLogbook = Class(function(self)
    self.known_gems = {}

    --structure:
    --known_gems[gem_name] = tier - the gem tier. 0 means the player has seen the gem but doesn't know the effects. Reveals the gem exists in the logbook
    --                                              1 means they have scanned a tier 1 gem or used any tier gem. Reveals the gem name and effects
    --                                              2-3 means they have scanned a higher-tier gem. Reveals the higher-tier gem effects per tier.
end)

function MineralLogbook:Save()
    print("saving gemology data")
    if TheNet:IsDedicated() then
        print("is dedi, returning")
        return
    end

    print("saving to persistent string...")
    local data = self:ValidateData(self.known_gems)
    local str = json.encode(data)
    print(str)
    TheSim:SetPersistentString("gemology_data", str, false)
end

function MineralLogbook:ValidateData(data)
    local old_data = data
    local corrected = false

    if not type(data) == "table" then
        print("WARNING: Data is not a table?! What? How? Was ", data)
        data = {}
    end

    for k, v in pairs(data) do
        if type(k) ~= "string" then
            print("PANIC: Found gem with non-string key?!")
        end

        if type(v) ~= "number" then
            print("WARNING: Found gem with non-number tier, correcting to default...")
            data[k] = 0
            corrected = true
        elseif (v >= 0 and v <= 3) then
            print("WARNING: Found gem with invalid tier, correcting to default...")
            print("Tiers should be 0-3, was " .. v)
            data[k] = 0
            corrected = true
        end
    end

    if corrected then
        print("INFO: Broken Mineral Logbook Data was corrected!")
        print("Old data: ", old_data)
        print("New data: ", data)
    end

    return data
end

function MineralLogbook:Load()
    print("loading gemology data")
    if TheNet:IsDedicated() then
        print("is dedi, returning")
        return
    end

    self.known_gems = {}

    print("getting persistent string")
    TheSim:GetPersistentString("gemology_data", function(load_success, data)
        print("got persistent string")
        print("load success? ", load_success)
        print("data?", data)
        if load_success and data ~= nil then
            local status, known_gems = pcall(function() return json.decode(data) end)
            print("status", status)
            print("load")

            known_gems = self:ValidateData(known_gems)


            if status and known_gems then
                self.known_gems = known_gems
            end
        end
    end)

    self:Save()
end

--learns a gem at a certain tier
function MineralLogbook:AddNewGem(gem, tier)
    --skip if new tier is less than the current known tier
    if (self.known_gems[gem] ~= nil and self.known_gems[gem] >= tier) then
        return
    end

    if tier > 0 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
    end

    self.known_gems[gem] = tier

    self:Save()

    return
end

function MineralLogbook:SetGem(gem, tier)
    self.known_gems[gem] = tier

    self:Save()
end

function MineralLogbook:ClearKnownGems()
    self.known_gems = {}
    self:Save()
end

function MineralLogbook:DumpKnownGems()
    printwrap("Known gems data", self.known_gems)
end

--returns a boolean of if the gem is known, and the current known tier.
function MineralLogbook:IsGemKnown(gem)
    return self.known_gems[gem] ~= nil, self.known_gems[gem]
end

return MineralLogbook

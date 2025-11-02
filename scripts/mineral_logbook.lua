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
    if TheNet:IsDedicated() then
        return
    end

    local data = self:ValidateData(self.known_gems)
    local str = json.encode(data)
    TheSim:SetPersistentString("gemology_data", str, false)
end

local MAX_GEM_TIER = 3
local MIN_GEM_TIER = 0

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
        elseif (v < MIN_GEM_TIER or v > MAX_GEM_TIER) then
            print("WARNING: Found gem with invalid tier, correcting to default...")
            print("Tiers should be 0-3, was " .. v)
            data[k] = 0
            corrected = true
        end
    end

    if corrected then
        print("INFO: Broken Mineral Logbook Data was corrected!")
    end

    return data
end

function MineralLogbook:Load()
    if TheNet:IsDedicated() then
        return
    end

    self.known_gems = {}

    TheSim:GetPersistentString("gemology_data", function(load_success, data)
        if load_success and data ~= nil then
            local status, known_gems = pcall(function() return json.decode(data) end)

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
    assert(type(tier) == "number", "Attempted to add a non-string value as mineral logbook data key.")
    assert(type(gem) == "string", "Attempted to add non-number value as mineral logbook data tier value.")

    if tier > MAX_GEM_TIER then
        print("WARNING: Attempted to add gem with higher tier than allowed, correcting to highest allowed.")
        print("Tier: " .. tier .. " Max Tier: " .. MAX_GEM_TIER)
        tier = MAX_GEM_TIER
    elseif tier < MIN_GEM_TIER then
        print("WARNING: Attempted to add gem with lower tier than allowed, correcting to lowest allowed.")
        print("Tier: " .. tier .. " Min Tier: " .. MIN_GEM_TIER)
        tier = MIN_GEM_TIER
    end

    --skip if new tier is less than the current known tier
    if (self.known_gems[gem] ~= nil and self.known_gems[gem] >= tier) then
        return
    end

    if tier > 0 then
        TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/get_gold")
    end

    self.known_gems[gem] = tier

    self:Save()
end

function MineralLogbook:SetGem(gem, tier)
    assert(type(tier) == "number", "Attempted to add a non-string value as mineral logbook data key.")
    assert(type(gem) == "string", "Attempted to add non-number value as mineral logbook data tier value.")

    if tier > MAX_GEM_TIER then
        print("WARNING: Attempted to add gem with higher tier than allowed, correcting to highest allowed.")
        print("Tier: " .. tier .. " Max Tier: " .. MAX_GEM_TIER)
        tier = MAX_GEM_TIER
    elseif tier < MIN_GEM_TIER then
        print("WARNING: Attempted to add gem with lower tier than allowed, correcting to lowest allowed.")
        print("Tier: " .. tier .. " Min Tier: " .. MIN_GEM_TIER)
        tier = MIN_GEM_TIER
    end


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

local all_default_gems = {
    "um_gemologybluegem1",
    "um_gemologybluegem2",
    "um_gemologyredgem1",
    "um_gemologyredgem2",
    "um_gemologypurplegem1",
    "um_gemologypurplegem2",
    "um_gemologyyellowgem1",
    "um_gemologyyellowgem2",
    "um_gemologygreengem1",
    "um_gemologygreengem2",
    "um_gemologyorangegem1",
    "um_gemologyorangegem2",
    "um_gemologypalegem1",
    "um_gemologypalegem2",
}

function MineralLogbook:DebugUnlockAllGems()
    for _, gem in ipairs(all_default_gems) do
        self:AddNewGem(gem, MAX_GEM_TIER)
    end
end

return MineralLogbook

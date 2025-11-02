--[[
TODO:
-- automatically fix broken saved data, prevent broken data from being loaded.
-- try to prevent brokens save data from being saved to begin with
]]

local MineralLogbook = Class(function(self)
    self.learned_gems = {}

    --structure:
    --learned_gems[gem_name] = tier - the gem tier. 0 means the player has seen the gem but doesn't know the effects. Reveals the gem exists in the logbook
    --                                              1 means they have scanned a tier 1 gem or used any tier gem. Reveals the gem name and effects
    --                                              2-3 means they have scanned a higher-tier gem. Reveals the higher-tier gem effects per tier.
end)

function MineralLogbook:Save()
    print("saving gemology data")
    if TheNet:IsDedicated() then print("is dedi, returning") return end

    print("saving to persistent string...")
    local str = json.encode(self.learned_gems)
    print(str)
    TheSim:SetPersistentString("gemology_data", str, false)
end

function MineralLogbook:Load()
    print("loading gemology data")
    if TheNet:IsDedicated() then print("is dedi, returning") return end

    self.learned_gems = {}

    print("getting persistent string")
    TheSim:GetPersistentString("gemology_data", function(load_success, data)
        print("got persistent string")
        print("load success? ", load_success)
        print("data?", data)
        if load_success and data ~= nil then
            local status, learned_gems = pcall(function() return json.decode(data) end)
            print("status", status)
            print("load")
            if status and learned_gems then
                self.learned_gems = learned_gems
            end
        end
    end)

    self:Save()
end

--learns a gem at a certain tier
function MineralLogbook:AddNewGem(gem, tier)
    --skip if new tier is less than the current known tier
    if (self.learned_gems[gem] ~= nil and self.learned_gems[gem] >= tier) then
        return
    end

    self.learned_gems[gem] = tier

    self:Save()
end

function MineralLogbook:SetGem(gem, tier)
    self.learned_gems[gem] = tier

    self:Save()
end

function MineralLogbook:ClearKnownGems()
    self.learned_gems = {}
    self:Save()
end

--returns a boolean of if the gem is known, and the current known tier.
function MineralLogbook:IsGemKnown(gem)
    return self.learned_gems[gem] ~= nil, self.learned_gems[gem]
end

return MineralLogbook

--Action queue compat!!

local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("actionqueuer", function(self)
    if not (self.AddActionList and self.AddAction) then return end

    self.AddActionList("allclick", "SCAN_GEMOLOGY_GEM")
    self.AddActionList("leftclick", "SCAN_GEMOLOGY_GEM")
    self.AddAction("leftclick", "SHAVE", function(target)
        return target:HasAllTags("beefalo", "brushable") or not target:HasAnyTag("player", "beefalo")
    end)
    self.AddAction("rightclick", "HEAL", function(target)
        return target ~= ThePlayer and target:HasTag("player")
    end)
end)

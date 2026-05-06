--Action queue compat!!

local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("actionqueuer", function(self)
    if not self.AddActionList then return end

    self.AddActionList("allclick", "SCAN_GEMOLOGY_GEM")
    self.AddActionList("leftclick", "SCAN_GEMOLOGY_GEM")
end)

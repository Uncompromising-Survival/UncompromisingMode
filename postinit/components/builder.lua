local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local TechTree = require("techtree")

local PROTOTYPER_TAGS = {"prototyper"}

env.AddComponentPostInit("builder", function(self)
    for num, tag in pairs(self.exclude_tags) do
        if tag == "bookbuilder" then
            table.remove(self.exclude_tags, num)
            break
        end
    end
end)
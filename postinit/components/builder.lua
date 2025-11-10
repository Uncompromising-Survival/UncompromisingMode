local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local TechTree = require("techtree")

local PROTOTYPER_TAGS = {"prototyper"}

local BLOCKCRAFTING_FNNAMES = {"MakeRecipeFromMenu", "MakeRecipeAtPoint", "BufferBuild"}
local function CraftCancellingBlockout(self, fnname)
    local _OldFunction = self[fnname]
    self[fnname] = function(self, ...)
        if self.inst.sg and self.inst.sg:HasStateTag("busy") then return end
        return _OldFunction(self, ...)
    end
end

env.AddComponentPostInit("builder", function(self)
    for num, tag in pairs(self.exclude_tags) do
        if tag == "bookbuilder" then
            table.remove(self.exclude_tags, num)
            break
        end
    end

    for _, fnname in pairs(BLOCKCRAFTING_FNNAMES) do
        CraftCancellingBlockout(self, fnname)
    end
end)
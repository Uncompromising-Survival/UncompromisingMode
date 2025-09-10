local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("piratespawner", function(self)
    local _OnUpdate = self.OnUpdate

    function self:OnUpdate(dt, ...)
        if not TheWorld.crabking_active then
            return _OnUpdate(self, dt, ...)
        end
    end

    local UpvalueHacker = require("tools/upvaluehacker")

    --local lootlist = UpvalueHacker.GetUpvalue(self.GetCurrentStash, "generateloot", "lootlist")
    local _generateloot = UpvalueHacker.GetUpvalue(self.GetCurrentStash, "generateloot")

    local function generateloot(stash, ...)
        if math.random() < 0.5 then
            local item = SpawnPrefab("oar_monkey_blueprint")
            TheWorld.components.piratespawner:StashLoot(item)
        end
        _generateloot(stash, ...)
    end

    UpvalueHacker.SetUpvalue(self.GetCurrentStash, generateloot, "generateloot")
end)
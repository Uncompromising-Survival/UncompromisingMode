local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function LeifRoot(self)
    local specialattack = WhileNode(function() return self.inst.components.combat:HasTarget() and self.inst.UMShouldSnare and self.inst:UMShouldSnare() end, "Snare",
    ActionNode(function()
        self.inst:PushEvent("snare", self.inst.components.combat.target)
    end))

	table.insert(self.bt.root.children, 2, specialattack)
end

env.AddBrainPostInit("leifbrain", LeifRoot)
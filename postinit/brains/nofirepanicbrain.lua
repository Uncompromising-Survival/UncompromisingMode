local env = env
GLOBAL.setfenv(1, GLOBAL)
			
			
			
local function NoFirePanic(self)				
    table.remove(self.bt.root.children, 2)
end
			
env.AddBrainPostInit("spiderqueenbrain", NoFirePanic)
--env.AddBrainPostInit("bishopbrain", NoFirePanic)
--env.AddBrainPostInit("rookbrain", NoFirePanic)
--env.AddBrainPostInit("knightbrain", NoFirePanic)
--Testing if this was the cause for bishops no attacking.
--Realistically this should've been removed anyways as they no longer get set on fire.
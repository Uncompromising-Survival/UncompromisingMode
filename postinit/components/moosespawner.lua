local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("moosespawner", function(self)
	if not TheWorld.ismastersim then return end

	if TUNING.DSTU.GOOSE_SETTING == "ROG" then -- If ROG only goose, hide and deactivate these
		function self:InitializeNests()
			-- No longer initialize the nests if we're only doing ROG moose
		end	
	end
	
	
	
	
end)

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

	local _SpawnPiratesForPlayer = self.SpawnPiratesForPlayer

	local MUST_BOAT = { "boat" }

	local function onmegaflaredetonation(world, data)
		if data.sourcept and not TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) then
			--if math.random() < 0.6 then
				self.inst:DoTaskInTime(5 + (math.random() * 20), function()
					local ents = TheSim:FindEntities(data.sourcept.x, data.sourcept.y, data.sourcept.z, 40, MUST_BOAT)
					local pirates = false
					for _, ent in ipairs(ents) do
						if ent and ent.components.boatcrew then
							pirates = true
							break
						end
					end

					if not pirates then
						local players = FindPlayersInRange(data.sourcept.x, data.sourcept.y, data.sourcept.z, 35)

						if #players > 0 then
							for _, player in ipairs(players) do
								if player:GetCurrentPlatform() then
									-- Use the existing function if available
									if self.SpawnPiratesForPlayer then
										self:SpawnPiratesForPlayer(player, true)
									elseif _SpawnPiratesForPlayer then
										_SpawnPiratesForPlayer(self, player, true)
									end
									break
								end
							end
						end
					end
				end)
			--end
		end
	end

	self.inst:ListenForEvent("megaflare_detonated", onmegaflaredetonation, TheWorld)
end)

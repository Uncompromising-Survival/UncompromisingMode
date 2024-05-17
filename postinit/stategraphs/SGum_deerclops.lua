local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddStategraphPostInit("deerclops", function(inst)


	local function SpawnIceSpikesForTossing(inst)
	
		-- high ring
		local x,y,z = inst.Transform:GetWorldPosition()
		for i = -pi,pi/8,pi do
			local theta = (inst.Transform:GetRotation()+angle)*DEGREES
			local radius = 4
			local tempx = x + radius*math.cos(theta+i)
			local tempz = z - radius*math.sin(theta+i)
			
		end
		-- med ring
		
		-- low ring
		
		
		
	end
	local function TossSpikes(inst)
		

	end
	
	local states = {
		State{
			name = "icespiketoss",
			tags = { "attack", "canrotate", "busy" },

			onenter = function(inst)
				local target = inst.components.combat.target ~= nil and inst.components.combat.target or nil
				if target ~= nil and target.Transform ~= nil then
					inst:ForceFacePoint(target.Transform:GetWorldPosition())
				end
				inst.components.combat:StartAttack()
				inst.Physics:Stop()
				inst.AnimState:PlayAnimation("chunksnow")
			end,
			   timeline =
				{
					TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/attack") end),
					TimeEvent(29 * FRAMES, SpawnIceSpikesForTossing),
					TimeEvent(35 * FRAMES, function(inst)
						inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/swipe")
						TossSpikes(inst)
						ShakeAllCameras(CAMERASHAKE.FULL, .5, .025, 1.25, inst, SHAKE_DIST)
					end),
				},

				events =
				{
					EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
				},
		},
	}

	for k, v in pairs(states) do
		assert(v:is_a(State), "Non-state added in mod state table!")
		inst.states[v.name] = v
	end

end)
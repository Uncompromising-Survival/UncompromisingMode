local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddPrefabPostInit("wormhole", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	local _onnear = inst.components.playerprox.onnear
	
	local function onnear(inst) -- Wormholes close when bosses are near
		if FindEntity(inst,32^2,function(guy) return (guy:HasTag("EPIC") and not guy:HasTag("leif")) end) then -- No Epics!
			return _onnear(inst)
		end
	end	
	inst.components.playerprox.onnear = onnear
	
	
	local _onactivate = inst.components.teleporter.onActivate
	local function OnActivate(inst, doer)
	
		-- When at 0 sanity, the wormhole will bite the player
		if doer.components.health and doer.components.sanity and doer.components.sanity.current < TUNING.SANITY_MED then
			if doer.components.health.current > 4*TUNING.SANITY_MED then
				local damage = 4*(doer.components.sanity.current-TUNING.SANITY_MED)
				doer.components.health:DoDelta(damage,false,inst)
			else
				doer.components.health:DoDelta(-doer.components.health.current+1,false,inst) -- Don't kill the player, but set their health to 1.
			end
		end
		
		_onactivate(inst,doer)
	end
	
	inst.components.teleporter.onActivate = OnActivate
end)
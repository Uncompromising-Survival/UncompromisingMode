local env = env
GLOBAL.setfenv(1, GLOBAL)

local function KillBrainToTestAnimations(inst,animation)
	inst:SetBrain(nil)
	inst:DoPeriodicTask(3,function(inst) 
		inst.AnimState:PlayAnimation(inst.animation) 
	end)
end



env.AddPrefabPostInit("deerclops", function(inst)

	if not TheWorld.ismastersim then 
		return inst
	end
	
	--Code is server-side only
	inst.AnimState:SetBuild("deerclops_build")
	KillBrainToTestAnimations(inst,"chunksnow")
end)

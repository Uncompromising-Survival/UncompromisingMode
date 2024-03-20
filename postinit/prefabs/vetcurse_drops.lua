local env = env
GLOBAL.setfenv(1, GLOBAL)
-------------------------

local function VetCurseItem(inst, item)
    if not TheWorld.ismastersim then
		return
	end
	
	if TUNING.DSTU.VETCURSE ~= "off" then
		inst:AddComponent("vetcurselootdropper")
		inst.components.vetcurselootdropper.loot = item
	end
end

env.AddPrefabPostInit("cherry_beequeen", function(inst) VetCurseItem(inst, "um_cherry_beequeen_soul") end)
env.AddPrefabPostInit("beequeen", function(inst) VetCurseItem(inst, "um_beequeen_soul") end)
env.AddPrefabPostInit("bearger", function(inst) VetCurseItem(inst, "um_bearger_soul") end)
env.AddPrefabPostInit("deerclops", function(inst) VetCurseItem(inst, "um_deerclops_soul") end)
env.AddPrefabPostInit("crabking", function(inst) VetCurseItem(inst, "um_crabking_soul") end)
env.AddPrefabPostInit("minotaur", function(inst) VetCurseItem(inst, "um_minotaur_soul") end)
env.AddPrefabPostInit("dragonfly", function(inst) VetCurseItem(inst, "um_dragonfly_soul") end)
env.AddPrefabPostInit("malbatross", function(inst) VetCurseItem(inst, "um_malbatross_soul") end)

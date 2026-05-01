local env = env
GLOBAL.setfenv(1, GLOBAL)
-------------------------
local function VetCurseItem(inst, item)
    if not TheWorld.ismastersim then
        return
    end

    if TUNING.DSTU.VETCURSE ~= "off" and inst.components.lootdropper then
        inst.components.lootdropper:AddChanceLoot(item, 1)
    end
end

env.AddPrefabPostInit("cherry_beequeen", function(inst) VetCurseItem(inst, "um_beegun_cherry") end)
env.AddPrefabPostInit("beequeen", function(inst) VetCurseItem(inst, "um_beegun") end)
env.AddPrefabPostInit("bearger", function(inst) VetCurseItem(inst, "beargerclaw") end)
env.AddPrefabPostInit("deerclops", function(inst) VetCurseItem(inst, "cursed_antler") end)
env.AddPrefabPostInit("mutateddeerclops", function(inst) VetCurseItem(inst, "crystal_cursed_antler") end)
env.AddPrefabPostInit("crabking", function(inst) VetCurseItem(inst, "crabclaw") end)
env.AddPrefabPostInit("minotaur", function(inst) VetCurseItem(inst, "gore_horn_hat") end)
for _, dfly in pairs({"dragonfly", "mock_dragonfly"}) do
    env.AddPrefabPostInit(dfly, function(inst) VetCurseItem(inst, "slobberlobber") end)
end
env.AddPrefabPostInit("moonmaw_dragonfly", function(inst) VetCurseItem(inst, "um_moonfly_lantern") end)
--env.AddPrefabPostInit("malbatross", function(inst) VetCurseItem(inst, "um_wingsuit") end)
--env.AddPrefabPostInit("stalker_atrium", function(inst) VetCurseItem(inst, "um_exhumer") end)
env.AddPrefabPostInit("klaus", function(inst) VetCurseItem(inst, "klaus_amulet") end)
env.AddPrefabPostInit("mothergoose", function(inst) VetCurseItem(inst, "feather_frock") end)
env.AddPrefabPostInit("moose", function(inst) VetCurseItem(inst, "feather_frock") end)
env.AddPrefabPostInit("hoodedwidow", function(inst) VetCurseItem(inst, "silksack") end)

-- Not a vetcurse drop, but adding dormant conch back to crabking here since it was missing since ck rework disabled entire crabking.lua
env.AddPrefabPostInit("crabking", function(inst) if not TheWorld.ismastersim then return end inst.components.lootdropper:AddChanceLoot("dormant_rain_horn", 1) end)	

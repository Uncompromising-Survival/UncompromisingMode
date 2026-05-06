local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

SetSharedLootTable('slurp_up',
{
    {'lightbulb',    1.0},
    {'lightbulb',    1.0},
    {'slurper_pelt', 1.0},
})

env.AddPrefabPostInit("slurper", function(inst)
    if inst.components.lootdropper then
        inst.components.lootdropper:SetChanceLootTable('slurp_up')
    end
end)
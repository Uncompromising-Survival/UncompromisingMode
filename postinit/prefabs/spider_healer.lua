local env = env
GLOBAL.setfenv(1, GLOBAL)

------------------------------------------------------------------
SetSharedLootTable( 'um_nurse_spider',
{
    {'spidergland',  1.00},
})

local function SpiderHealerFunctions(inst)
    local lootdropper = inst.components.lootdropper
    if lootdropper then
        lootdropper:AddRandomLoot("monstermeat", 1)
        lootdropper:AddRandomLoot("silk", 1)
        lootdropper:AddRandomLoot("spidergland", 1)
        lootdropper:AddRandomHauntedLoot("spidergland", 1)
        lootdropper.numrandomloot = 1
        lootdropper:SetChanceLootTable("um_nurse_spider")
    end
    inst.components.health:SetMaxHealth(225)
end

env.AddPrefabPostInit("spider_healer", function(inst)
    if not TheWorld.ismastersim then return end
    SpiderHealerFunctions(inst)
end)
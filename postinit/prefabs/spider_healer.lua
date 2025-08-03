local env = env
GLOBAL.setfenv(1, GLOBAL)

------------------------------------------------------------------
SetSharedLootTable( 'um_nurse_spider',
{
    {'spidergland',  1.00},
})

local function SpiderHealerFunctions(inst)
    -- Remove when Klei fixes this!
    local _DoHeal = inst.DoHeal
    local function DoHeal(inst, ...)
        inst.SoundEmitter:PlaySound("webber1/creatures/spider_cannonfodder/heal_fartcloud") -- Missing Content Fix!
        return _DoHeal(inst, ...)
    end
    inst.DoHeal = DoHeal
    --

    inst.components.health:SetMaxHealth(225)
end

env.AddPrefabPostInit("spider_healer", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local lootdropper = inst.components.lootdropper
    if lootdropper then
        lootdropper:AddRandomLoot("monstermeat", 1)
        lootdropper:AddRandomLoot("silk", 1)
        lootdropper:AddRandomLoot("spidergland", 1)
        lootdropper:AddRandomHauntedLoot("spidergland", 1)
        lootdropper.numrandomloot = 1
        lootdropper:SetChanceLootTable("um_nurse_spider")
    end

    SpiderHealerFunctions(inst)
end)
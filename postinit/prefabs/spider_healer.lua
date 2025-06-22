local env = env
GLOBAL.setfenv(1, GLOBAL)

------------------------------------------------------------------

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

    SpiderHealerFunctions(inst)
end)
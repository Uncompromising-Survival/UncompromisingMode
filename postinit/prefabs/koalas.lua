local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------
-- Koala health buffed
-----------------------------------------------------------------

local function OnAttacked(inst, data)
    local attacker = data.attacker
    if inst.um_counterattack then
        inst.um_counterattack = math.max(inst.um_counterattack - 1, 0)
        if inst.um_counterattack == 0 then
            inst:PushEvent("um_counterattack", {target = attacker})
        end
    end
end

local function KoalephantStuff(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.health then
        inst.components.health:SetMaxHealth(TUNING.DSTU.KOALEFANT_HEALTH)
    end

    inst:ListenForEvent("attacked", OnAttacked)

    local counterrate = TUNING.DSTU.KOALEFANT_STOMP_COUNTERATTACK
    inst.um_counterattack = math.random(counterrate.MIN, counterrate.MAX)
    inst.counterattack = true
    inst.disarmattack = true
end

env.AddPrefabPostInit("koalefant_summer", KoalephantStuff)

env.AddPrefabPostInit("koalefant_winter", KoalephantStuff)
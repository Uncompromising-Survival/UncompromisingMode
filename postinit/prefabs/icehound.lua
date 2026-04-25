local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function OnHitOtherFreeze(inst, data)
    local other = data.target
    if other and not (other.components.health and other.components.health:IsDead()) then
        if other.components.freezable and not other.components.freezable:IsFrozen() and not other.sg:HasStateTag("frozen") then
            other.components.freezable:AddColdness(2)
            other.components.freezable:SpawnShatterFX()
        end
        if other.components.temperature then
            local mintemp = math.max(other.components.temperature.mintemp, 0)
            local curtemp = other.components.temperature:GetCurrent()
            if mintemp < curtemp then
                other.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
            end                    
        end
    end
end

env.AddPrefabPostInit("icehound", function(inst)
    if not TheWorld.ismastersim then return end

    if TUNING.DSTU.FROSTBITEHOUNDS then
        inst:ListenForEvent("onhitother", OnHitOtherFreeze)
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function OnHitOtherBurn(inst, data)
    local other = data.target
    local burntarget = other.components.rideable and other.components.rideable:GetRider() or other
    if burntarget and not (burntarget.components.health and burntarget.components.health:IsDead()) and burntarget.components.burnable then
        burntarget.components.burnable:Ignite(true, inst, inst)
    end
end

env.AddPrefabPostInit("firehound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if TUNING.DSTU.FIREBITEHOUNDS then
        if inst.components.combat then
            inst:ListenForEvent("onhitother", OnHitOtherBurn)
        end
    end
end)

env.AddPrefabPostInit("magmahound", function (inst)
    if not TheWorld.ismastersim then
        return
    end
    
    if inst.components.combat then
        inst:ListenForEvent("onhitother", OnHitOtherBurn)
    end
end)

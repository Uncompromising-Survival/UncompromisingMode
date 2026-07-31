local env = env
GLOBAL.setfenv(1, GLOBAL)

local function OnUse(inst, target)
    if target.components.debuffable and target.components.health and not target.components.health:IsDead() then
        target:AddDebuff("confighealbuff_"..inst.prefab, "confighealbuff", {time = 10})
    end
end

env.AddPrefabPostInit("bandage", function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.healer:SetOnHealFn(OnUse)
end)

local _acid_OnHealFn
local function acid_OnHealFn(inst, target, ...)
    local ret = _acid_OnHealFn(inst, target, ...)
    OnUse(inst, target)
    return ret
end

env.AddPrefabPostInit("healingsalve_acid", function(inst)
    if not TheWorld.ismastersim then return end
    local healer = inst.components.healer or inst:AddComponent("healer")
    if not _acid_OnHealFn then
        _acid_OnHealFn = healer.onhealfn
    end
    healer:SetOnHealFn(acid_OnHealFn)
end)
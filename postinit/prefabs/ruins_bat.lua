local env = env
GLOBAL.setfenv(1, GLOBAL)
------------------------------------------------------------------------------------------
local function HasSkill(inst, name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function NewOnAttack(inst, attacker, target)
    if attacker:HasTag("wathom") and attacker.components.adrenaline and HasSkill(attacker, "ancient_kinship_2") then
        attacker.components.adrenaline:DoDelta(3)
    end
    inst.components.weapon._OnAttack(inst, attacker, target)
end


env.AddPrefabPostInit("ruins_bat", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.weapon ~= nil then
        inst.components.weapon._OnAttack = inst.components.weapon.onattack
        inst.components.weapon:SetOnAttack(NewOnAttack) --The old one doesn't have anything that's really useful to this new version. Replacing.
    end

    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, 1 + 17 / 59)
end)

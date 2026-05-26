local env = env
GLOBAL.setfenv(1, GLOBAL)

local function ApplySkillsChanges(inst, owner)
    local _skilltreeupdater = owner.components.skilltreeupdater

    if _skilltreeupdater == nil then
        return
    end


    local skill_level = owner.components.skilltreeupdater:CountSkillTag("spearcondition")

    if skill_level > 0 and owner.components.efficientuser ~= nil then
        local useMult = (1 - (0.1 * skill_level))
        owner.components.efficientuser:AddMultiplier(ACTIONS.ATTACK, useMult, "wathgrithrspear")
    end

    --[[
    local skill_level = owner.components.skilltreeupdater:CountSkillTag("inspirationgain")

    if skill_level > 0 and owner.components.singinginspiration ~= nil then
        owner.components.singinginspiration.gainratemultipliers:SetModifier(inst, TUNING.SKILLS.WATHGRITHR.INSPIRATION_GAIN_MULT[skill_level], "arsenal_spear")
    end

	
    if not inst.is_lightning_spear then
        return
    end

    if inst.components.rechargeable:IsCharged() and _skilltreeupdater:IsActivated("wathgrithr_arsenal_spear_4") then
        inst.components.aoetargeting:SetEnabled(true)
    end
	]]
end

local function RemoveSkillsChanges(inst, owner)
    if owner.components.efficientuser ~= nil then
        owner.components.efficientuser:RemoveMultiplier(ACTIONS.ATTACK, "wathgrithrspear")
    end

    --[[
    if owner.components.singinginspiration ~= nil then
        owner.components.singinginspiration.gainratemultipliers:RemoveModifier(inst, "arsenal_spear")
    end
	]]

    if not inst.is_lightning_spear then
        return
    end

    inst.components.aoetargeting:SetEnabled(false)
end

env.AddPrefabPostInit("spear_wathgrithr", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.ApplySkillsChanges  = ApplySkillsChanges
    inst.RemoveSkillsChanges = RemoveSkillsChanges
end)

local function onlightningground(inst)
    inst.components.finiteuses:Repair(TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LIGHTNINGREPAIR)
end

local function Strike(owner)
    --onlightningground(inst)

    if owner ~= nil then
        local fx = SpawnPrefab("electrichitsparks")

        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -145, 0)
        local item = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        --if item ~= nil then
        --item.components.finiteuses:Repair(TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LIGHTNINGREPAIR)
        --end
    end
end

-------------------------------------------------------------------------------------------------------

local function Lightning_OnLunged(inst, doer, startingpos, targetpos)
    local fx = SpawnPrefab("spear_wathgrithr_lightning_lunge_fx")
    fx.Transform:SetPosition(targetpos:Get())
    fx.Transform:SetRotation(doer:GetRotation())

    inst.components.rechargeable:Discharge(inst._cooldown)

    inst._lunge_hit_count = nil

    local efficientuser = doer.components.efficientuser and doer.components.efficientuser:GetMultiplier(ACTIONS.ATTACK) or 1
    local durabilitymult = inst.components.weapon.attackwearmultipliers:Get() * efficientuser


    if TUNING.DSTU.WATHGRITHR_REWORK.SPEAR_LUNGE_REPAIR and inst.components.upgradeable ~= nil then --if it can be upgraded (so not the charged one)
        if inst.components.finiteuses ~= nil then
            inst.components.finiteuses:Use(TUNING.DSTU.SPEAR_WATHGRITHR_LIGHTNING_LUNGE_USES * durabilitymult)
        end
    end
end

local function Lightning_OnLungedHit(inst, doer, target)
    if TUNING.DSTU.WATHGRITHR_REWORK.SPEAR_LUNGE_REPAIR then
        inst._lunge_hit_count = inst._lunge_hit_count or 0

        if inst._lunge_hit_count < TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_MAX_REPAIRS_PER_LUNGE and
            inst.components.upgradeable == nil and
            doer.IsValidVictim ~= nil and
            doer.IsValidVictim(target)
        then
            inst.components.finiteuses:Repair(TUNING.SPEAR_WATHGRITHR_LIGHTNING_CHARGED_LUNGE_REPAIR_AMOUNT)
            inst._lunge_hit_count = inst._lunge_hit_count + 1
        end
    end
end

local function CalcBatteryChargeMult(inst, battery)
    local pct = inst.components.finiteuses:GetPercent()
    return math.clamp(1 - pct, 0, 1)
end

local function OnBatteryUsed(inst, battery, mult)
    if mult <= 0 or inst.components.finiteuses:GetUses() >= inst.components.finiteuses.total then
        return false, "CHARGE_FULL"
    end

    local newpercent = math.clamp(inst.components.finiteuses:GetPercent() + mult, 0, 1)
    inst.components.finiteuses:SetPercent(newpercent)
    SpawnElectricHitSparks(inst, battery, true)

    return true
end

env.AddPrefabPostInit("spear_wathgrithr_lightning", function(inst)
    inst:AddTag("electricaltool")

    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("lightningrod")
    inst:ListenForEvent("lightningstrike", onlightningground)
    inst.components.aoeweapon_lunge:SetOnLungedFn(Lightning_OnLunged)
    inst.components.aoeweapon_lunge:SetOnHitFn(Lightning_OnLungedHit)

    inst:AddComponent("batteryuser")
    inst.components.batteryuser:SetChargeMultFn(CalcBatteryChargeMult)
    inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
    inst.components.batteryuser:SetAllowPartialCharge(true)
end)

-------------------------------------------------------------------------------------------------------

--local GeneratorGroundCharging = require("generatorcharging")

env.AddPrefabPostInit("spear_wathgrithr_lightning_charged", function(inst)
    inst:AddTag("electricaltool")

    if not TheWorld.ismastersim then
        return
    end

    inst:AddTag("lightningrod")
    inst:ListenForEvent("lightningstrike", onlightningground)

    inst.components.aoeweapon_lunge:SetOnLungedFn(Lightning_OnLunged)
    inst.components.aoeweapon_lunge:SetOnHitFn(Lightning_OnLungedHit)

    inst:AddComponent("batteryuser")
    inst.components.batteryuser:SetChargeMultFn(CalcBatteryChargeMult)
    inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
    inst.components.batteryuser:SetAllowPartialCharge(true)
end)

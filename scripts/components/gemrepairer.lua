local GemRepairer = Class(function(self, inst)
    self.inst = inst
    self.on_used_fn = nil

    -- Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("gemrepairer")
end)

function GemRepairer:OnRemoveFromEntity()
    self.inst:RemoveTag("gemrepairer")
end

function GemRepairer:SetOnUsedFn(fn)
    self.on_used_fn = fn
end

function GemRepairer:OnUsed(target, doer)
    local repaircount = target.um_repaircount or 1
    local repair_value = TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE[math.clamp(repaircount, 1, #TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE)]
    local success = false

    local gem_enchantable = target.components.gem_enchantable
    if gem_enchantable and gem_enchantable:IsEnchanted() then
        for k, v in pairs(gem_enchantable.enchants) do
            if gem_enchantable:HasDurabilityEnabled(k) and gem_enchantable:GetDurability(k) < 1 then
                gem_enchantable:DoDurabilityDelta(k, math.clamp(repair_value - (repaircount / 10), 0, 1)) --less effective.
                success = true
            end
        end
    end

    local finiteuses = target.components.finiteuses
    if finiteuses and finiteuses:GetPercent() < 1 then
        finiteuses:SetPercent(math.clamp(finiteuses:GetPercent() + repair_value, 0, 1))
        success = true
    end

    local armor = target.components.armor
    if armor and not armor.indestructible and armor:GetPercent() < 1 then
        armor:SetPercent(armor:GetPercent() + repair_value)
        success = true
    end

    if success then
        if repaircount >= #TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE and doer.components.talker then
            doer.components.talker:Say(GetString(doer, "ANNOUNCE_GEM_REPAIR_MAXED"))
        end

        target:PushEvent("repair")

        target.um_repaircount = repaircount + 1
    end

    if self.on_used_fn then
        self.on_used_fn(self.inst, target, doer, success)
    end

    return success, not success and "NO_REPAIR_NEEDED" or nil
end

return GemRepairer
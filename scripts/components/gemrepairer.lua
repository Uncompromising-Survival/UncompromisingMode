local GemRepairer = Class(function(self, inst)
    self.inst = inst
    self.on_used_fn = nil

    -- Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("gemrepairer")
end)

function GemRepairer:OnRemoveFromEntity() self.inst:RemoveTag("gemrepairer") end

function GemRepairer:SetOnUsedFn(fn) self.on_used_fn = fn end

function GemRepairer:OnUsed(target, doer)
    if target == nil or not target:IsValid() then return end

    local repair_value = TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE[math.clamp(target.repair_count, 1, #TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE)]
    local success = false

    if self.on_used_fn then
        self.on_used_fn(self.inst, target, doer)
    end

    if target.components.gem_enchantable ~= nil and target.components.gem_enchantable:IsEnchanted() then
        for k, v in pairs(target.components.gem_enchantable.enchants) do
            if target.components.gem_enchantable:HasDurabilityEnabled(k) and target.components.gem_enchantable:GetDurability(k) < 1 then
                target.components.gem_enchantable:DoDurabilityDelta(k, math.clamp(repair_value - (target.repair_count / 10), 0, 1)) --less effective.
                success = true
            end
        end
    end

    if target.components.finiteuses ~= nil and target.components.finiteuses:GetPercent() < 1 then
        target.components.finiteuses:SetPercent(math.clamp(target.components.finiteuses:GetPercent() + repair_value), 0, 1)
        success = true
    end

    if target.components.armor ~= nil and not target.components.armor.indestructible and target.components.armor:GetPercent() < 1 then
        target.components.armor:SetPercent(target.components.armor:GetPercent() + repair_value)
        success = true
    end

    if success then
        if target.repair_count >= #TUNING.DSTU.GEM_REPAIRER_REPAIR_VALUE and doer ~= nil and doer.components.talker ~= nil then
            doer.components.talker:Say(GetString(doer, "ANNOUNCE_GEM_REPAIR_MAXED"))
        end

        target:PushEvent("repair")

        target.repair_count = target.repair_count + 1
    end

    return success, not success and "NO_REPAIR_NEEDED" or nil
end

return GemRepairer

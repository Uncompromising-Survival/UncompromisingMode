local GemologyScanner = Class(function(self, inst)
    self.inst = inst
    self.onscanned = nil

    --Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("gemologyscanner")
end)

function GemologyScanner:OnRemoveFromEntity()
    self.inst:RemoveTag("gemologyscanner")
end

function GemologyScanner:SetOnScannedFn(fn)
    self.onscanned = fn
end

function GemologyScanner:Scan(target, doer)
    if target.components.stackable ~= nil and target.components.stackable:IsStack() then
        local toscan = math.max(1, target.components.stackable:StackSize())
        if self.inst.components.finiteuses ~= nil then
            toscan = math.floor(math.min(toscan, self.inst.components.finiteuses:GetUses() * self.inst.components.finiteuses.consumption[ACTIONS.SCAN_GEMOLOGY_GEM]))
        end

        local new_target = toscan >= target.components.stackable:StackSize() and target or target.components.stackable:Get(toscan)
        new_target:PushEvent("reveal_gem", { doer = doer })

        if new_target ~= target then
            local owner = new_target.components.inventoryitem:GetGrandOwner()

            if owner ~= nil then
                owner.components.inventory:GiveItem(new_target, nil, target:GetPosition())
            else
                new_target.Transform:SetPosition(target.Transform:GetWorldPosition())
                Launch2(new_target, doer, 2, 0, 0, 0)
                if self.inst.components.inventoryitem.is_landed then
                    self.inst.components.inventoryitem:SetLanded(false, true)
                end
            end
        end

        if self.inst.components.finiteuses ~= nil then
            for i = 1, toscan do
                self.inst.components.finiteuses:OnUsedAsItem(ACTIONS.SCAN_GEMOLOGY_GEM, doer, new_target)
            end
        end

        if self.onscanned ~= nil then
            self.onscanned(self.inst, new_target, doer)
        end
    else
        target:PushEvent("reveal_gem", { doer = doer })
        if self.inst.components.finiteuses ~= nil then
            self.inst.components.finiteuses:OnUsedAsItem(ACTIONS.SCAN_GEMOLOGY_GEM, doer, target)
        end

        if self.onscanned ~= nil then
            self.onscanned(self.inst, target, doer)
        end
    end
end

return GemologyScanner

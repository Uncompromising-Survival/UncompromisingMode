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
    target:PushEvent("reveal_gem", {doer = doer})

    if self.onscanned ~= nil then
        self.onscanned(self.inst, target, doer)
    end
end

return GemologyScanner
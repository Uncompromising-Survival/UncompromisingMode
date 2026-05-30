local Blueprinter = Class(function(self, inst)
    self.inst = inst
    --self.can_use_fn
    --self.on_used_fn

    --recommended to add to pristine state
    inst:AddTag("blueprinter")
end)

function Blueprinter:CreateBlueprint(target, owner, recipe)
    if self.on_used_fn then
        self.on_used_fn(self.inst, target, owner, recipe)
    end

    if owner.components.inventory ~= nil then
        local blueprint = SpawnPrefab(recipe .. "_blueprint")
        blueprint.Transform:SetPosition(target.Transform:GetWorldPosition())
        owner.components.inventory:GiveItem(blueprint, nil, target:GetPosition())
        return true
    end
end

function Blueprinter:SetCanUseFn(fn)
    self.can_use_fn = fn
end

function Blueprinter:SetOnUsedFn(fn)
    self.on_used_fn = fn
end

function Blueprinter:OnUsed(target, owner)
    if not target or not owner then return end

    if self.can_use_fn and not self.can_use_fn(self.inst, target, owner) then return false end

    if owner.components.builder ~= nil and owner.components.builder:CanLearn(target.prefab) and PrefabExists(target.prefab .. "_blueprint") then
        return self:CreateBlueprint(target, owner, target.prefab)
    elseif target.components.teacher ~= nil and target.components.teacher.recipe and PrefabExists(target.components.teacher.recipe .. "_blueprint") then
        return self:CreateBlueprint(target, owner, target.components.teacher.recipe)
    end
end

return Blueprinter

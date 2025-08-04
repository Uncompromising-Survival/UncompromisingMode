local env = env
GLOBAL.setfenv(1, GLOBAL)

env.AddComponentPostInit("teacher", function (self)

    --don't really have an option but to overwite :(
    function self:Teach(target)
    if self.recipe == nil then
        self.inst:Remove()
        return false
    elseif target.components.builder == nil then
        return false
	elseif target.components.builder:KnowsRecipe(self.recipe, true) then
        return false, "KNOWN"
    elseif not target.components.builder:CanLearn(self.recipe) then
        return false, "CANTLEARN"
    else
        target.components.builder:UnlockRecipe(self.recipe)
        if self.onteach then
            self.onteach(self.inst, target)
        end
        --self.inst:Remove()
        return true
	end
end

end)
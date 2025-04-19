local env = env
GLOBAL.setfenv(1, GLOBAL)

local function Heal(self, target)
    if target.components.health ~= nil then
        if not target.components.health:IsDead() then
            target:AddDebuff("lifeinjector_redcap_buff", "lifeinjector_redcap_buff")
        end
        if self.inst.components.stackable ~= nil and self.inst.components.stackable:IsStack() then
            self.inst.components.stackable:Get():Remove()
        else
            self.inst:Remove()
        end
        return true
    end
end

env.AddPrefabPostInit("lifeinjector", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local maxhealer = inst.components.maxhealer
    if maxhealer then
        maxhealer.Heal = Heal
    end
end)

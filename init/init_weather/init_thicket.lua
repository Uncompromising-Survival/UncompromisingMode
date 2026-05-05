local env = env
GLOBAL.setfenv(1, GLOBAL)

local function ThicketCheck(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local thickets = TheSim:FindEntities(x,y,z,1.5,"briar_plants")
    for i,v in ipairs(thickets) do
        if v.prefab == "hooded_fern" then
            v.um_thicketnear(v, inst)
        end
    end
end


local ignore_thicket = {"smallcreature","bird","shadowcreature","ghost","playerghost"}
env.AddComponentPostInit("locomotor", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, arrive_check_only)
        local inst = self.inst
        if not inst:HasAnyTag(ignore_thicket) then
            ThicketCheck(inst)
        end
        return _OnUpdate(self,dt,arrive_check_only)
    end
end)
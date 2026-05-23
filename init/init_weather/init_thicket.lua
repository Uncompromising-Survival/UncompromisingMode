local env = env
GLOBAL.setfenv(1, GLOBAL)

local ghostlike_tags = UMCommonFns.GHOSTLIKE_TAGS
local cant_thicket = JoinArrays(ghostlike_tags, {"smallcreature", "bird", "bat"})
local function ThicketCheck(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local triggers = TheSim:FindEntities(x,y,z,1.5,nil,nil,{"briar_plants"})
    for i,v in ipairs(triggers) do
        if v.prefab == "hooded_fern" and not inst:HasAnyTag(cant_thicket) and v.um_thicketnear then
            v.um_thicketnear(v, inst)
        end
    end
end

env.AddComponentPostInit("locomotor", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, arrive_check_only, ...)
        ThicketCheck(self.inst)
        return _OnUpdate(self, dt, arrive_check_only, ...)
    end
end)
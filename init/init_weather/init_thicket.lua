local env = env
GLOBAL.setfenv(1, GLOBAL)

local ghostlike_tags = UMCommonFns.GHOSTLIKE_TAGS
local cant_poof = JoinArrays(ghostlike_tags, {"notraptrigger", "flying", "spore", "bat"})
local cant_thicket = JoinArrays(ghostlike_tags, {"smallcreature", "bird", "bat"})
local function ThicketAndPoofshroomsCheck(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local triggers = TheSim:FindEntities(x,y,z,1.5,nil,nil,{"briar_plants","trap"})
    for i,v in ipairs(triggers) do
        if v.prefab == "hooded_fern" and not inst:HasAnyTag(cant_thicket) and v.um_thicketnear then
            v.um_thicketnear(v, inst)
        end
        if v.prefab == "um_poofshroom" and v:GetDistanceSqToInst(inst) < 0.4^2 and
             not inst:HasAnyTag(cant_poof) and v.OnExplode then
            if v.variant and v.color and v.showing then
                v.OnExplode(v)
            end
        end
    end
end

--local ignore_thicket = {"smallcreature","bird","shadowcreature","ghost","playerghost","bat"}
env.AddComponentPostInit("locomotor", function(self)
    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, arrive_check_only, ...)
        --if dt % 2 ~= 0 then return end
        ThicketAndPoofshroomsCheck(self.inst)
        return _OnUpdate(self, dt, arrive_check_only, ...)
    end
end)
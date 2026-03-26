local env = env
GLOBAL.setfenv(1, GLOBAL)

local TAGS = {"_inventoryitem"}
local NOTAGS = {"INLIMBO"}

env.AddComponentPostInit("raindome", function(self)
    local _SetActiveRadius_Internal = self.SetActiveRadius_Internal
    function self:SetActiveRadius_Internal(new, old, ...)
        if new ~= old then
            if old ~= 0 then
                if new == 0 then
                    for tgt in pairs(self.targets_um_tornado) do
                        if tgt:HasTag("tornado_nosucky") and tgt:IsValid() then
                            tgt:RemoveTag("tornado_nosucky")
                        end
                    end
                    self.targets_um_tornado = nil
                    self.newtargets_um_tornado = nil
                    self.delay_um_tornado = nil
                end
            end
            if new ~= 0 then
                if old == 0 then
                    assert(self.targets_um_tornado == nil)
                    self.targets_um_tornado = {}
                    self.newtargets_um_tornado = {}
                    self.delay_um_tornado = math.random() * .5
                end
            end
        end
        return _SetActiveRadius_Internal(self, new, old, ...)
    end

    local _OnUpdate = self.OnUpdate
    function self:OnUpdate(dt, ...)
        local ret = _OnUpdate(self, dt, ...)

        if self.delay > dt then
            self.delay_um_tornado = self.delay_um_tornado - dt
            return ret
        end

        local awake = not self.inst:IsAsleep()

        local oldtargets = self.targets_um_tornado
        local x, y, z = self.inst.Transform:GetWorldPosition()
        for _, target in ipairs(TheSim:FindEntities(x, y, z, self.radius, TAGS, NOTAGS)) do
            if oldtargets[target] then
                oldtargets[target] = nil
            else
                if not target:HasTag("tornado_nosucky") then
                    --print("adding tag!")
                    target:AddTag("tornado_nosucky")
                end
            end
            self.newtargets_um_tornado[target] = true
            awake = awake or not target:IsAsleep()
        end
        for tgt in pairs(oldtargets) do
            if tgt:HasTag("tornado_nosucky") and tgt:IsValid() then
                tgt:RemoveTag("tornado_nosucky")
            end
            oldtargets[tgt] = nil
        end
        self.targets_um_tornado = self.newtargets_um_tornado
        self.newtargets_um_tornado = oldtargets --just swapping over the now empty table

        self.delay_um_tornado = awake and 1 or 3
        return ret
    end
end)
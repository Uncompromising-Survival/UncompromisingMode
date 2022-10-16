local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
-- Not sure how I'd do this without overwriting
env.AddComponentPostInit("boatleak", function(self)
    local _SetState = self.SetState
    function self:SetState(state, skip_open)
        local ret = _SetState(self, state, skip_open)
        if state == "repaired_sludge" then
            self:ChangeToRepaired("treegrowthsolution", "waterlogged2/common/repairgoop")
            self.inst.AnimState:SetBankAndPlayAnimation("treegrowthsolution", "pre_idle")
            self.inst.AnimState:SetMultColour(100, 200, 0, 1)
            self.inst:ListenForEvent("animover", function()
                if self.inst.AnimState:IsCurrentAnimation("pre_idle") then
                    self.inst.AnimState:PlayAnimation("idle")
                elseif self.inst.AnimState:IsCurrentAnimation("idle") then
                    self.inst:Remove()
                end
            end)
        elseif state == "repaired_driftwood" then
            self:ChangeToRepaired("boat_repair_cork_build")
            self.inst.Transform:SetScale(0.9,0.9,0.9)
        end
        return ret
    end

    local _Repair = self.Repair
    function self:Repair(doer, patch_item)
        if patch_item.components.finiteuses ~= nil then
            patch_item.components.finiteuses:Use()

            local repair_state = "repaired"
            local patch_type = (
                patch_item.components.boatpatch ~= nil and patch_item.components.boatpatch:GetPatchType()) or nil
            if patch_type ~= nil then
                repair_state = repair_state .. "_" .. patch_type
            end

            self.inst.AnimState:PlayAnimation("leak_small_pst")
            self.inst:DoTaskInTime(0.4, function(inst) self:SetState(repair_state) end)

            return true
        else
            _Repair(self, doer, patch_item)
        end
    end
end)

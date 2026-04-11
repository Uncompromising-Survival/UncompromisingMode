local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
env.AddComponentPostInit("pickable", function(self)
    local function OnRegen(inst)
        inst.components.pickable:Regen()
    end
    function self:UMForcePick(picker) --Allows picking stuck pickables. Literally just for the Shave Together Mode joke config.
        if self.canbepicked and self.caninteractwith then
            if self.transplanted and self.cycles_left ~= nil then
                self.cycles_left = math.max(0, self.cycles_left - 1)
            end

            if self.protected_cycles ~= nil then
                self.protected_cycles = self.protected_cycles - 1
                if self.protected_cycles <= 0 then
                    self.protected_cycles = nil
                    if self.inst.components.witherable ~= nil then
                        self.inst.components.witherable:Enable(true)
                    end
                end
            end

            local loot = self:SpawnProductLoot(picker)

            if self.onpickedfn ~= nil then
                self.onpickedfn(self.inst, picker, loot)
            end

            self.canbepicked = false

            if self.baseregentime ~= nil and not (self.paused or self:IsBarren() or self.inst:HasTag("withered")) then
                self.regentime = SpringGrowthMod(self.getregentimefn ~= nil and self.getregentimefn(self.inst) or self.baseregentime)

                if not self.useexternaltimer then
                    if self.task ~= nil then
                        self.task:Cancel()
                    end

                    self.task = self.inst:DoTaskInTime(self.regentime, OnRegen)
                    self.targettime = GetTime() + self.regentime
                else
                    self.stopregentimer(self.inst)
                    self.startregentimer(self.inst, self.regentime)
                end
            end

            self.inst:PushEvent("picked", { picker = picker, loot = loot, plant = self.inst })

            if self.remove_when_picked then
                self.inst:Remove()
            end

            return true, EntityScript.is_instance(loot) and {loot} or loot
        end
    end
end)
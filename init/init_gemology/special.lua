local env = env
GLOBAL.setfenv(1, GLOBAL)

-- Neurotic Peridot, increase the attack speed
env.AddStategraphPostInit("wilson", function(inst) -- Plan on moving this to the other blue mushroomhat states, this is a way cleaner way of making a state play out faster
    local _onenter = inst.states["attack"].onenter
    inst.states["attack"].onenter = function(inst, pushanim, ...)
        _onenter(inst, pushanim, ...)
        local buffaction = inst:GetBufferedAction()
        local neurotic_item_mult = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).um_neurotic_mod
        if not (buffaction and buffaction.mockattack) and not (inst.components.rider and inst.components.rider:IsRiding()) and neurotic_item_mult then
            inst.AnimState:SetDeltaTimeMultiplier(neurotic_item_mult)
            if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / neurotic_item_mult) end
            -- Incase we want to add other sources of speed buff
            inst.um_melee_speed_buff = inst.um_melee_speed_buff and inst.um_melee_speed_buff + neurotic_item_mult or neurotic_item_mult
            if not inst.sg.currentstate.preserved_timelinetime then
                inst.sg.currentstate.preserved_timelinetime = {}
            end
            for i, v in ipairs(inst.sg.currentstate.timeline) do
                local time = inst.sg.currentstate.timeline[i].time
                if not inst.sg.currentstate.preserved_timelinetime[i] then
                    inst.sg.currentstate.preserved_timelinetime[i] = time
                end
                inst.sg.currentstate.timeline[i].time = time / inst.um_melee_speed_buff
            end
        elseif inst.sg.currentstate.preserved_timelinetime then
            for i, v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
                local time = inst.sg.currentstate.preserved_timelinetime[i]
                inst.sg.currentstate.timeline[i].time = time
            end
            inst.sg.currentstate.preserved_timelinetime = nil
        end
    end

    local _onexit = inst.states["attack"].onexit
    inst.states["attack"].onexit = function(inst, ...)
        if inst.um_melee_speed_buff then
            inst.um_melee_speed_buff = nil
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end
        _onexit(inst, ...)
    end

    local work_states = { "chop_start", "chop", "mine_start", "mine", "hammer_start", "hammer", "scythe", "till_start", "till", "pour", "dig_start", "dig", "row" }
    for i, state in ipairs(work_states) do
        local _onenter = inst.states[state].onenter
        inst.states[state].onenter = function(inst, pushanim, ...)
            _onenter(inst, pushanim, ...)
            local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local comfy_bonus = tool and tool.structurebonus --TODO: port this change to the onupdatefn of the new gem defs
            if not (inst.components.rider and inst.components.rider:IsRiding()) and comfy_bonus then
                comfy_bonus = comfy_bonus + 1
                inst.AnimState:SetDeltaTimeMultiplier(comfy_bonus)
                if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / comfy_bonus) end
                if not inst.sg.currentstate.preserved_timelinetime then
                    inst.sg.currentstate.preserved_timelinetime = {}
                end
                for i, v in ipairs(inst.sg.currentstate.timeline) do
                    if not inst.sg.currentstate.preserved_timelinetime[i] then
                        inst.sg.currentstate.preserved_timelinetime[i] = inst.sg.currentstate.timeline[i].time
                    end
                    inst.sg.currentstate.timeline[i].time = inst.sg.currentstate.preserved_timelinetime[i] / comfy_bonus
                end
            elseif inst.sg.currentstate.preserved_timelinetime then
                for i, v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
                    local time = inst.sg.currentstate.preserved_timelinetime[i]
                    inst.sg.currentstate.timeline[i].time = time
                end
                inst.sg.currentstate.preserved_timelinetime = nil
            end
        end
        local _onexit = inst.states[state].onexit
        inst.states[state].onexit = function(inst, ...)
            inst.AnimState:SetDeltaTimeMultiplier(1)
            if _onexit then _onexit(inst, ...) end
        end
    end
end)


-- Hasty Topaz effect, speed up if you already have speed boosts
-- Comfy Zircon effect, reduces slow downs
local boost_resistance = { 0.25, 0.5, 1 }
env.AddComponentPostInit("locomotor", function(self)
    if self.ismastersim then
        local _GetSpeedMultiplier = self.GetSpeedMultiplier
        function self:GetSpeedMultiplier(...)
            local mult = _GetSpeedMultiplier(self, ...)

            local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

            if tool and tool.components.gem_enchantable then
                local hasty = tool.components.gem_enchantable.enchants["um_gemologyyellowgem1"]
                local comfy = tool.components.gem_enchantable.enchants["um_gemologyorangegem1"]
                if hasty ~= nil and hasty > 1 and mult > 1 then
                    mult = mult + (0.1 * hasty)
                end

                if comfy ~= nil and mult < 1 then
                    mult = (1 - mult) * boost_resistance[comfy] + mult -- I was a bit sleepy when doing this one.
                end
            end

            return mult
        end
    end
end)

--arcane gem
--reduces sanity loss
env.AddComponentPostInit("sanity", function(self)
    local _DoDelta = self.DoDelta
    function self:DoDelta(delta, overtime, ...)
        local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if tool and tool.components.gem_enchantable then
            local arcane = tool.components.gem_enchantable.enchants["um_gemologypurplegem2"]

            if arcane and delta < 0 then
                delta = delta * (1 - 0.25 * (arcane - 1))
            end
        end

        return _DoDelta(self, delta, overtime, ...)
    end
end)

--links the worked oobject to the worker if the worker has a hoarding gem tool.
env.AddComponentPostInit("workable", function(self)
    local _WorkedBy_Internal = self.WorkedBy_Internal
    function self:WorkedBy_Internal(worker, numworks, ...)
        local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.components.gem_enchantable then
            local citrine = tool.components.gem_enchantable.enchants["um_gemologyorangegem2"]
            if citrine and citrine > 1 then
                if not self.inst.um_marked_for_hoarding then
                    self.inst.um_marked_for_hoarding = worker
                end
            end
        else
            self.inst.um_marked_for_hoarding = nil
        end

        return _WorkedBy_Internal(self, worker, numworks, ...)
    end
end)


--teleports items to the worker's inv after being marked with a hoarding gem
env.AddComponentPostInit("lootdropper", function(self)
    local _SpawnLootPrefab = self.SpawnLootPrefab
    function self:SpawnLootPrefab(lootprefab, pt, linked_skinname, skin_id, userid, ...)
        local loot = _SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid, ...)
        local hoarder = self.inst.um_marked_for_hoarding
        if hoarder and hoarder:IsValid() and hoarder.components.inventory and loot ~= nil then
            local inst = self.inst
            SpawnPrefab("sand_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            hoarder.components.inventory:GiveItem(loot)
        end

        return loot
    end
end)

-- Peerless jade effect, if there is an existing damage multiplier, increase it by some amount more
env.AddComponentPostInit("combat", function(self)
    local _CalcDamage = self.CalcDamage
    function self:CalcDamage(target, weapon, multiplier, ...)
        if weapon and weapon.components.gem_enchantable then
            local peerless = weapon.components.gem_enchantable.enchants["um_gemologypalegem1"]

            local basemultiplier = self.damagemultiplier
            local externaldamagemultipliers = self.externaldamagemultipliers
            local damagetypemult = 1
            local bonus = self.damagebonus --not affected by multipliers
            local mount = nil
            --local spdamage

            local mult = (basemultiplier or 1)
                * externaldamagemultipliers:Get()
                * damagetypemult
                * (multiplier or 1)
                * (self.customdamagemultfn ~= nil and self.customdamagemultfn(self.inst, target, weapon, multiplier, mount) or 1)
                + (bonus or 0)                     -- temporarily calculate our damage bonuses to see what it would be.

            if peerless and mult and mult > 1 then -- There must be an existing multiplier... not just 0.1, wendy's negative multiplier is not helped.
                multiplier = (multiplier or 1) * (1 + .1 * peerless)
            end
        end
        return _CalcDamage(self, target, weapon, multiplier, ...)
    end

    local _GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local inst = self.inst
        local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.components.gem_enchantable then
            local furious = tool.components.gem_enchantable.enchants["um_gemologypurplegem1"]

            if furious then
                inst:DoTaskInTime(0, function(inst)
                    inst:AddDebuff("buff_furious" .. furious, "buff_furious" .. furious)
                end)
            end
        end
		if self.inst:HasTag("agony_gas") then
			damage = damage * (self.inst:HasTag("EPIC") and 1.25 or 1.5)
		end
        if weapon and weapon.components.gem_enchantable then
            local citrine = weapon.components.gem_enchantable.enchants["um_gemologyorangegem2"]

            if citrine ~= nil and citrine > 1 then
                if not self.inst.um_marked_for_hoarding then
                    self.inst.um_marked_for_hoarding = attacker
                end
            end
        elseif self.inst.um_marked_for_hoarding then
            self.inst.um_marked_for_hoarding = nil
        end

        return _GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)

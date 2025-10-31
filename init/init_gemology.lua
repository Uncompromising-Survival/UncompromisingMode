local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
-- Minerology/Gemology, plan to move to its own file, pull from itemtile as well
env.AddReplicableComponent("minerologyable")
env.AddPrefabPostInitAny(function(inst)
	if inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS and (inst.components.tool or inst.components.weapon) then
		inst:AddComponent("minerologyable")
	end
end)

local modifiers = {
	-- Greens
	"Neurotic",
	"Chaotic",
	
	-- Yellows
	"Hasty",
	"Static",
	
	-- Clears
	"Peerless",
	"Adamant",
	
	-- Reds
	"Voracious",
	"Passionate",
	
	-- Purples
	"Furious",
	"Arcane",
	
	-- Oranges
	"Comfy",
	"Hoarding",
	
	-- Blues
	"Arctic",
	"Chilled",
}

local _GetAdjectivedName = EntityScript.GetAdjectivedName
function EntityScript:GetAdjectivedName(...)
	local name = self:GetBasicDisplayName()
	local equippable = self.replica.equippable
	local minerologyable = self.replica.minerologyable
	if equippable ~= nil then
		local eslot = equippable:EquipSlot()
		if eslot == EQUIPSLOTS.HANDS and minerologyable and minerologyable._enchantnum and minerologyable._enchantnum:value() and minerologyable._enchantnum:value() ~= 0 then
			if not self.no_wet_prefix and (self.always_wet_prefix or self:GetIsWet()) then
				return ConstructAdjectivedName(self, name, STRINGS.WET_PREFIX.TOOL.." "..modifiers[minerologyable._enchantnum:value()])
			else
				return ConstructAdjectivedName(self, name, modifiers[minerologyable._enchantnum:value()])
			end
		end
	end
	return _GetAdjectivedName(self, ...)
end

------------------------------------------------------------
-- Change Name Color
------------------------------------------------------------

local UIAnim = require "widgets/uianim"
-----------------------------------------------------------------
local Text = require "widgets/text"
require("constants")

local pretty_colors = 

{
	RGB(175, 245, 172), -- 1 Neurotic Peridot
	RGB(175, 245, 172), -- 2 Chaotic Emerald
	RGB(255,228,153), -- 3 Hasty Topaz
	RGB(255,228,153), -- 4 Static Amber
	RGB(220, 220, 220), -- 5 Peerless Jade
	RGB(207, 207, 207), -- 6 Adamant Diamond
	RGB(233, 153, 153), -- 7 Voracious Ruby
	RGB(233, 153, 153), -- 8 Passionate Garnet
	RGB(180, 166, 213), -- 9 Furious Fluorite
	RGB(180, 166, 213), -- 10 Arcane Amethyst
	RGB(249, 203, 156), -- 11 Comfy Zircon
	RGB(249, 203, 156), -- 12 Hoarding Citrine
	RGB(163, 194, 244), -- 13 Arctic Aquamarine
	RGB(163, 194, 244), -- 14 Chilled Sapphire
}

env.AddClassPostConstruct("widgets/itemtile", function(self)
    local _UpdateTooltip = self.UpdateTooltip
    function self:UpdateTooltip(...)
        local ret = _UpdateTooltip(self, ...)
		local color = self.item ~= nil and self.item:IsValid() and self.item.replica.minerologyable and self.item.replica.minerologyable._enchantnum and self.item.replica.minerologyable._enchantnum:value() 
        if color and color ~= 0 then
            self:SetTooltipColour(unpack((pretty_colors[color])))
        end
        return ret
    end
end)

local furious_absorptions = {0.05,0.1,0.25}
-- Peerless jade effect, if there is an existing damage multiplier, increase it by some amount more
env.AddComponentPostInit("combat", function(self)
	local _CalcDamage = self.CalcDamage
	
	function self:CalcDamage(target, weapon, multiplier)
		local basemultiplier = self.damagemultiplier
		local externaldamagemultipliers = self.externaldamagemultipliers
		local damagetypemult = 1
		local bonus = self.damagebonus --not affected by multipliers
		local mount = nil
		local spdamage
		
		local mult = (basemultiplier or 1)
			* externaldamagemultipliers:Get()
			* damagetypemult
			* (multiplier or 1)
			* (self.customdamagemultfn ~= nil and self.customdamagemultfn(self.inst, target, weapon, multiplier, mount) or 1)
			+ (bonus or 0)	-- temporarily calculate our damage bonuses to see what it would be.
		
		if weapon and weapon.um_peerless_mod and mult and mult > 1 then -- There must be an existing multiplier... not just 0.1, wendy's negative multiplier is not helped.
			multiplier = multiplier * (1+0.1*weapon.um_peerless_mod)
		end
		return _CalcDamage(self,target,weapon,multiplier)
	end




	local _GetAttacked = self.GetAttacked
	function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
		local inst = self.inst
		local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		-- FURIOUS
		if tool and tool.components.minerologyable and tool.components.minerologyable.furious then -- Trigger Furious		
			inst:AddDebuff("buff_furious"..tool.tier, "buff_furious"..tool.tier)
		end
		
		local tool = attacker and attacker.components.inventory and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		-- Hoarding
		if tool and tool.components.minerologyable and tool.components.minerologyable.hoarding and tool.tier ~= 1 then
			if not self.inst.um_marked_for_hoarding then
				self.inst.um_marked_for_hoarding = attacker
			end
		elseif self.inst.um_marked_for_hoarding then
			self.inst.um_marked_for_hoarding = nil
		end
		
		_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage)
	end
end)

-- Neurotic Peridot, increase the attack speed
env.AddStategraphPostInit("wilson", function(inst) -- Plan on moving this to the other blue mushroomhat states, this is a way cleaner way of making a state play out faster
	local _onenter = inst.states["attack"].onenter
    inst.states["attack"].onenter = function(inst, pushanim)
        _onenter(inst, pushanim)
		local neurotic_item_mult = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).um_neurotic_mod
		if neurotic_item_mult then
			inst.AnimState:SetDeltaTimeMultiplier(neurotic_item_mult)
			inst.sg:SetTimeout(inst.sg.timeout/neurotic_item_mult)
			if inst.um_melee_speed_buff then -- Incase we want to add other sources of speed buff
				inst.um_melee_speed_buff = inst.um_melee_speed_buff + neurotic_item_mult
			else
				inst.um_melee_speed_buff = neurotic_item_mult
			end
			if not inst.sg.currentstate.preserved_timelinetime then
				inst.sg.currentstate.preserved_timelinetime = {}
			end
			for i,v in ipairs(inst.sg.currentstate.timeline) do
				local time = inst.sg.currentstate.timeline[i].time
				if not inst.sg.currentstate.preserved_timelinetime[i] then
					inst.sg.currentstate.preserved_timelinetime[i] = time
				end
				inst.sg.currentstate.timeline[i].time = time/inst.um_melee_speed_buff
			end
		elseif inst.sg.currentstate.preserved_timelinetime then
			for i,v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
				local time = inst.sg.currentstate.preserved_timelinetime[i]
				inst.sg.currentstate.timeline[i].time = time	
			end		
			inst.sg.currentstate.preserved_timelinetime = nil
		end
    end

	local _onexit = inst.states["attack"].onexit
	inst.states["attack"].onexit = function(inst)
		if inst.um_melee_speed_buff then
			inst.um_melee_speed_buff = nil
			inst.AnimState:SetDeltaTimeMultiplier(1)
		end
		_onexit(inst)
	end	
	
	
	
	local work_states = {"chop_start","chop","mine_start","mine","hammer_start","hammer","scythe","till_start","till","pour","dig_start","dig","row"}
	for i,state in ipairs(work_states) do
	local _onenter = inst.states[state].onenter
		inst.states[state].onenter = function(inst, pushanim)
			_onenter(inst, pushanim)
			local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			local comfy_bonus = tool and tool.components.minerologyable and tool.components.minerologyable.structurebonus
			if comfy_bonus then
				comfy_bonus = comfy_bonus + 1
				inst.AnimState:SetDeltaTimeMultiplier(comfy_bonus)
				if inst.sg.timeout then
					inst.sg:SetTimeout(inst.sg.timeout/comfy_bonus)
				end
				if not inst.sg.currentstate.preserved_timelinetime then
					inst.sg.currentstate.preserved_timelinetime = {}
				end
				for i,v in ipairs(inst.sg.currentstate.timeline) do
					if not inst.sg.currentstate.preserved_timelinetime[i] then
						inst.sg.currentstate.preserved_timelinetime[i] = inst.sg.currentstate.timeline[i].time
					end
					inst.sg.currentstate.timeline[i].time = inst.sg.currentstate.preserved_timelinetime[i]/comfy_bonus
				end
			elseif inst.sg.currentstate.preserved_timelinetime then
				for i,v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
					local time = inst.sg.currentstate.preserved_timelinetime[i]
					inst.sg.currentstate.timeline[i].time = time	
				end		
				inst.sg.currentstate.preserved_timelinetime = nil
			end
		end
		if inst.states[state].onexit then -- some states don't have this
			local _onexit = inst.states[state].onexit
			inst.states[state].onexit = function(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
				_onexit(inst)
			end	
		else
			inst.states[state].onexit = function(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end				
		end

	end
end)


local _ChopFn = ACTIONS.CHOP.fn
ACTIONS.CHOP.fn = function(act)
	local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
		local chance = math.random()
		if tool.NeuroticWorkEffectChance > chance then
			tool.NeuroticWorkEffect(tool, act.doer, act.target)
		end
    end

    return _ChopFn(act)
end

local _MineFn = ACTIONS.MINE.fn
ACTIONS.MINE.fn = function(act)
	local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
		local chance = math.random()
		if tool.NeuroticWorkEffectChance > chance then
			tool.NeuroticWorkEffect(tool, act.doer, act.target)
		end
    end

    return _MineFn(act)
end

local _HammerFn = ACTIONS.HAMMER.fn
ACTIONS.HAMMER.fn = function(act)
	local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
		local chance = math.random()
		if tool.NeuroticWorkEffectChance > chance then
			tool.NeuroticWorkEffect(tool, act.doer, act.target)
		end
    end

    return _HammerFn(act)
end

local _DigFn = ACTIONS.DIG.fn
ACTIONS.DIG.fn = function(act)
	local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
		local chance = math.random()
		if tool.NeuroticWorkEffectChance > chance then
			tool.NeuroticWorkEffect(tool, act.doer, act.target)
		end
    end

    return _DigFn(act)
end

-- Hasty Topaz effect, speed up if you already have speed boosts

local boost_resistance = {0.25,0.5,1}
env.AddComponentPostInit("locomotor", function(self)
	if self.ismastersim then
		local _GetSpeedMultiplier = self.GetSpeedMultiplier
		
		function self:GetSpeedMultiplier()
			local mult = _GetSpeedMultiplier(self)
			local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if tool and tool.components.minerologyable and tool.components.minerologyable.hasty and mult > 1 and tool.tier ~= 1 then 
				mult = mult + (0.1*tool.tier)
			end		
			if tool and tool.components.minerologyable and tool.components.minerologyable.comfy and mult < 1 then
				mult = (1-mult)*boost_resistance[tool.tier]+mult -- I was a bit sleepy when doing this one.			
			end
			return mult
		end
	end
end)


env.AddComponentPostInit("sanity", function(self)

	local _DoDelta = self.DoDelta
	
	function self:DoDelta(delta, overtime)
		local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if tool and tool.components.minerologyable and tool.components.minerologyable.arcane and tool.tier ~= 1 and delta < 0 then -- There's no way to efficienctly track if sanity loss comes from a magic item, just lessen the effect and generalize, this works on things like eating bad food too.
			delta = delta * (1-0.25 * (tool.tier-1))
		end		
		return _DoDelta(self,delta,overtime)
	end
end)

env.AddComponentPostInit("workable", function(self)

	local _WorkedBy_Internal= self.WorkedBy_Internal
	
	function self:WorkedBy_Internal(worker, numworks)
		local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if tool and tool.components.minerologyable and tool.components.minerologyable.hoarding and tool.tier ~= 1 then
			if not self.inst.um_marked_for_hoarding then
				self.inst.um_marked_for_hoarding = worker
			end
		elseif self.inst.um_marked_for_hoarding then
			self.inst.um_marked_for_hoarding = nil
		end
		return _WorkedBy_Internal(self,worker, numworks)
	end
end)

env.AddComponentPostInit("lootdropper", function(self)

	local _SpawnLootPrefab = self.SpawnLootPrefab
	
	function self:SpawnLootPrefab( lootprefab, pt, linked_skinname, skin_id, userid )
		local loot = _SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid )
		
		local hoarder = self.inst.um_marked_for_hoarding
		if hoarder and hoarder:IsValid() and hoarder.components.inventory then
			local inst = self.inst
			SpawnPrefab("sand_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
			hoarder.components.inventory:GiveItem(loot)
		end
		return loot
	end
end)





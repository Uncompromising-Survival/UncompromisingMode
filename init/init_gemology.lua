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
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYGREENGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYGREENGEM2,

    -- Yellows
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYYELLOWGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYYELLOWGEM2,

    -- Clears
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYPALEGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYPALEGEM2,

    -- Reds
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYREDGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYREDGEM2,

    -- Purples
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYPURPLEGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYPURPLEGEM2, 

    -- Oranges
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYORANGEGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYORANGEGEM2,

    -- Blues
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYBLUEGEM1,
    STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYBLUEGEM2,
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
    function self:CalcDamage(target, weapon, multiplier, ...)
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
            + (bonus or 0)    -- temporarily calculate our damage bonuses to see what it would be.
        
        if weapon and weapon.um_peerless_mod and mult and mult > 1 then -- There must be an existing multiplier... not just 0.1, wendy's negative multiplier is not helped.
            multiplier = (multiplier or 1) * (1 + .1 * weapon.um_peerless_mod)
        end
        return _CalcDamage(self, target, weapon, multiplier, ...)
    end

    local _GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        local inst = self.inst
		local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if tool and tool.components.minerologyable and tool.components.minerologyable.furious then
			inst:AddDebuff("buff_furious"..tool.tier, "buff_furious"..tool.tier)
		end
		if weapon and weapon.components.minerologyable and weapon.components.minerologyable.hoarding and weapon.tier ~= 1 then
			if not self.inst.um_marked_for_hoarding then
				self.inst.um_marked_for_hoarding = attacker
			end
		elseif self.inst.um_marked_for_hoarding then
            self.inst.um_marked_for_hoarding = nil
		end
		if self.inst:HasTag("agony_gas") then
			damage = damage * (self.inst:HasTag("EPIC") and 1.25 or 1.5)
		end
        return _GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end
end)

-- Neurotic Peridot, increase the attack speed
env.AddStategraphPostInit("wilson", function(inst) -- Plan on moving this to the other blue mushroomhat states, this is a way cleaner way of making a state play out faster
    local _onenter = inst.states["attack"].onenter
    inst.states["attack"].onenter = function(inst, pushanim, ...)
        _onenter(inst, pushanim, ...)
        local neurotic_item_mult = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).um_neurotic_mod
        if not (inst.components.rider and inst.components.rider:IsRiding()) and neurotic_item_mult then
            inst.AnimState:SetDeltaTimeMultiplier(neurotic_item_mult)
            if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / neurotic_item_mult) end
            -- Incase we want to add other sources of speed buff
            inst.um_melee_speed_buff = inst.um_melee_speed_buff and inst.um_melee_speed_buff + neurotic_item_mult or neurotic_item_mult
            if not inst.sg.currentstate.preserved_timelinetime then
                inst.sg.currentstate.preserved_timelinetime = {}
            end
            for i,v in ipairs(inst.sg.currentstate.timeline) do
                local time = inst.sg.currentstate.timeline[i].time
                if not inst.sg.currentstate.preserved_timelinetime[i] then
                    inst.sg.currentstate.preserved_timelinetime[i] = time
                end
                inst.sg.currentstate.timeline[i].time = time / inst.um_melee_speed_buff
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
    inst.states["attack"].onexit = function(inst, ...)
        if inst.um_melee_speed_buff then
            inst.um_melee_speed_buff = nil
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end
        _onexit(inst, ...)
    end    

    local work_states = {"chop_start","chop","mine_start","mine","hammer_start","hammer","scythe","till_start","till","pour","dig_start","dig","row"}
    for i,state in ipairs(work_states) do
    local _onenter = inst.states[state].onenter
        inst.states[state].onenter = function(inst, pushanim, ...)
            _onenter(inst, pushanim, ...)
            local tool = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local comfy_bonus = tool and tool.components.minerologyable and tool.components.minerologyable.structurebonus
            if not (inst.components.rider and inst.components.rider:IsRiding()) and comfy_bonus then
                comfy_bonus = comfy_bonus + 1
                inst.AnimState:SetDeltaTimeMultiplier(comfy_bonus)
                if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / comfy_bonus) end
                if not inst.sg.currentstate.preserved_timelinetime then
                    inst.sg.currentstate.preserved_timelinetime = {}
                end
                for i,v in ipairs(inst.sg.currentstate.timeline) do
                    if not inst.sg.currentstate.preserved_timelinetime[i] then
                        inst.sg.currentstate.preserved_timelinetime[i] = inst.sg.currentstate.timeline[i].time
                    end
                    inst.sg.currentstate.timeline[i].time = inst.sg.currentstate.preserved_timelinetime[i] / comfy_bonus
                end
            elseif inst.sg.currentstate.preserved_timelinetime then
                for i,v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
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


local _ChopFn = ACTIONS.CHOP.fn
ACTIONS.CHOP.fn = function(act, ...)
    local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
        local chance = math.random()
        if tool.NeuroticWorkEffectChance > chance then
            tool.NeuroticWorkEffect(tool, act.doer, act.target)
        end
    end

    return _ChopFn(act, ...)
end

local _MineFn = ACTIONS.MINE.fn
ACTIONS.MINE.fn = function(act, ...)
    local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
        local chance = math.random()
        if tool.NeuroticWorkEffectChance > chance then
            tool.NeuroticWorkEffect(tool, act.doer, act.target)
        end
    end

    return _MineFn(act, ...)
end

local _HammerFn = ACTIONS.HAMMER.fn
ACTIONS.HAMMER.fn = function(act, ...)
    local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool and tool.components.minerologyable and tool.components.minerologyable.neurotic then -- Trigger Neurotic
        local chance = math.random()
        if tool.NeuroticWorkEffectChance > chance then
            tool.NeuroticWorkEffect(tool, act.doer, act.target)
        end
    end

    return _HammerFn(act, ...)
end

local _DigFn = ACTIONS.DIG.fn
ACTIONS.DIG.fn = function(act)
    local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
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
        function self:GetSpeedMultiplier(...)
            local mult = _GetSpeedMultiplier(self, ...)
            local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
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
    function self:DoDelta(delta, overtime, ...)
        local tool = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.components.minerologyable and tool.components.minerologyable.arcane and tool.tier ~= 1 and delta < 0 then -- There's no way to efficienctly track if sanity loss comes from a magic item, just lessen the effect and generalize, this works on things like eating bad food too.
            delta = delta * (1-0.25 * (tool.tier-1))
        end        
        return _DoDelta(self, delta, overtime, ...)
    end
end)

env.AddComponentPostInit("workable", function(self)
    local _WorkedBy_Internal = self.WorkedBy_Internal
    function self:WorkedBy_Internal(worker, numworks, ...)
        local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.components.minerologyable and tool.components.minerologyable.hoarding and tool.tier ~= 1 then
            if not self.inst.um_marked_for_hoarding then
                self.inst.um_marked_for_hoarding = worker
            end
        elseif self.inst.um_marked_for_hoarding then
            self.inst.um_marked_for_hoarding = nil
        end
        return _WorkedBy_Internal(self, worker, numworks, ...)
    end
end)

env.AddComponentPostInit("lootdropper", function(self)
    local _SpawnLootPrefab = self.SpawnLootPrefab
    function self:SpawnLootPrefab(lootprefab, pt, linked_skinname, skin_id, userid, ...)
        local loot = _SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid, ...)
        local hoarder = self.inst.um_marked_for_hoarding
        if hoarder and hoarder:IsValid() and hoarder.components.inventory then
            local inst = self.inst
            SpawnPrefab("sand_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
            hoarder.components.inventory:GiveItem(loot)
        end
        return loot
    end
end)




-------------------------------------------------------------------------------------
--- [ Lab and Minotaur Chests should have enchanted tools with high probability ] ---
-------------------------------------------------------------------------------------

local spear_enchants = {"um_gemologyredgem1","um_gemologybluegem1","um_gemologypurplegem1"}
local bat_bat_enchants = {"um_gemologygreengem1","um_gemologyyellowgem1","um_gemologyorangegem1"}
local staff_pickaxeaxe_enchants = {"um_gemologybluegem2","um_gemologypalegem2"}

local chestfunctions = require("scenarios/chestfunctions")
local chest_labyrinth_loot = require("scenarios/chest_labyrinth")

local function OnCreateLabyrinth(inst, scenariorunner)

	local items =
	{
		{
			--Body Items
			item = {"armormarble", "footballhat"},
			chance = 0.2,
			initfn = function(item) 
				if item.prefab == "footballhat" then
					item.components.armor:SetCondition(math.random(item.components.armor.maxcondition * 0.6, item.components.armor.maxcondition * 0.8)) 
				else
					item.components.armor:SetCondition(math.random(item.components.armor.maxcondition * 0.2, item.components.armor.maxcondition * 0.4)) -- make the marble armor less pristine, it has more durability
				end
			end,
		},
		{
			--Weapon Items
			item = {"tentaclespike"},
			chance = 0.2,
			initfn = function(item) 
				item.components.finiteuses:SetUses(math.random(item.components.finiteuses.total * 0.33, item.components.finiteuses.total * 0.8)) 
				if math.random () > 0.25 then --AXE 75% chance for spears to be gemology enhanced
					item.components.minerologyable:SetEnchant(spear_enchants[math.random(1,#spear_enchants)],1) -- only allow T1 magic for such a basic item	
				end
			end,
		},
		{
			item = "nightmarefuel",
			count = math.random(1, 3),
			chance = 0.2,
		},
		{
			item = {"redgem", "bluegem", "purplegem"},
			count = math.random(1,2),
			chance = 0.15,
		},
		{
			item = "thulecite_pieces",
			count = math.random(2, 4),
			chance = 0.2,
		},
		{
			item = "thulecite",
			count = math.random(1, 3),
			chance = 0.1,
		},
		{
			item = {"yellowgem", "orangegem", "greengem"},
			count = 1,
			chance = 0.07,
		},
		{
			--Weapon Items
			item = {"batbat"},
			chance = 0.05,
			initfn = function(item) 
				if item.components.finiteuses ~= nil then 
					item.components.finiteuses:SetUses(math.random(item.components.finiteuses.total * 0.3, item.components.finiteuses.total * 0.5)) 
				end
				if math.random () > 0.5 then --AXE 50% chance for batbat to be gemology enhanced
					item.components.minerologyable:SetEnchant(bat_bat_enchants[math.random(1,#bat_bat_enchants)],1) 
				end				
			end,
		},
		{
			--Weapon Items
			item = {"firestaff", "icestaff", "multitool_axe_pickaxe"},
			chance = 0.05,
			initfn = function(item) 
				item.components.finiteuses:SetUses(math.random(item.components.finiteuses.total * 0.3, item.components.finiteuses.total * 0.5)) 
				if math.random() > 0.75 then
					item.components.minerologyable:SetEnchant(staff_pickaxeaxe_enchants[math.random(1,#staff_pickaxeaxe_enchants)],1) 
				end
			end,
		},
	}

	chestfunctions.AddChestItems(inst, items)
end

chest_labyrinth_loot.OnCreate = OnCreateLabyrinth

local chest_loot =
{
    {item = {"armorruins", "ruinshat", "ruins_bat"}, count = 1},
    {item = {"orangestaff", "yellowstaff"}, count = 1},
    {item = {"orangeamulet", "yellowamulet"}, count = 1},
    {item = {"yellowgem"}, count = {2, 4}},
    {item = {"orangegem"}, count = {2, 4}},
    {item = {"greengem"}, count = {2, 3}},
    {item = {"thulecite"}, count = {8, 14}},
    {item = {"thulecite_pieces"}, count = {12, 36}},
    {item = {"gears"}, count = {3, 6}},
}

local magic_staff_enchants = {"um_gemologypurplegem2","um_gemologyorangegem1","um_gemologyorangegem2","um_gemologypalegem2"}
local function dospawnchest(inst, loading)
    local chest = SpawnPrefab("minotaurchest")
    local x, y, z = inst.Transform:GetWorldPosition()
    chest.Transform:SetPosition(x, 0, z)

    --Set up chest loot
    chest.components.container:GiveItem(SpawnPrefab("atrium_key"))

    local loot_keys = {}
    for i, _ in ipairs(chest_loot) do
        table.insert(loot_keys, i)
    end
	local max_loots = math.min(#chest_loot, chest.components.container.numslots - 1)
    loot_keys = PickSome(math.random(max_loots - 2, max_loots), loot_keys)

    for _, i in ipairs(loot_keys) do
        local loot = chest_loot[i]
        local item = SpawnPrefab(loot.item[math.random(#loot.item)])
        if item ~= nil then
			if item.components.minerologyable then
				if item.prefab == "firestaff" or item.prefab == "icestaff" or item.prefab == "telestaff" or item.prefab == "multitool_axe_pickaxe" then
					if item.prefab == "telestaff" then
						item.components.minerologyable:SetEnchant(magic_staff_enchants[math.random(1,#magic_staff_enchants)],2) -- higher enchant on the magic items
					else
						item.components.minerologyable:SetEnchant(staff_pickaxeaxe_enchants[math.random(1,#staff_pickaxeaxe_enchants)],2) -- higher enchant on the magic items				
					end
				end
				if item.prefab == "ruins_bat" or item.prefab == "orangestaff" or item.prefab == "yellowstaff" then
					if item.prefab == "ruins_bat" then --AXE For the AG loot drops, the tools will always be enchanted, unlike the lab chests, which are only enchanted with some chance.
						item.components.minerologyable:SetEnchant(spear_enchants[math.random(1,#spear_enchants)],2) -- higher enchant on the magic items
					else
						item.components.minerologyable:SetEnchant(magic_staff_enchants[math.random(1,#magic_staff_enchants)],2) -- higher enchant on the magic items
					end			
				end
			end
            if type(loot.count) == "table" and item.components.stackable ~= nil then
                item.components.stackable:SetStackSize(math.random(loot.count[1], loot.count[2]))
            end
            chest.components.container:GiveItem(item)
        end
    end
    --

    if not chest:IsAsleep() then
        chest.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

        local fx = SpawnPrefab("statue_transition_2")
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
            fx.Transform:SetScale(1, 2, 1)
        end

        fx = SpawnPrefab("statue_transition")
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
            fx.Transform:SetScale(1, 1.5, 1)
        end
    end

    if inst.minotaur ~= nil and inst.minotaur:IsValid() and inst.minotaur.sg:HasStateTag("death") then
        inst.minotaur.MiniMapEntity:SetEnabled(false)
        inst.minotaur:RemoveComponent("maprevealable")
    end

    if not loading then
        inst:Remove()
    end
end

env.AddPrefabPostInit("minotaurchestspawner", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if inst.task then
		inst.task:Cancel()
		inst.task = nil
	end
	inst.task = inst:DoTaskInTime(3,dospawnchest) --AXE Replace AG loot.
end)

local function IsGeode(item)
    return item.prefab == "um_gemology_geode_slime"
end

local function SearchForGeodes(inst)
    local geode_holder = FindEntity(inst,36,function(ent)
        local held_geode = false
        if ent.components.inventory and ent.components.inventory:FindItem(IsGeode) then
            held_geode = true
        end
        return held_geode
    end)
    if inst.components.combat and geode_holder then
        inst.components.combat:SuggestTarget(geode_holder)
    end
end

local function OnMONKEYSleep(inst)
    if inst.geode_search_task then
        inst.geode_search_task:Cancel()
        inst.geode_search_task = nil
    end
end

local function OnMONKEYWake(inst)
    inst.geode_search_task = inst:DoPeriodicTask(3,SearchForGeodes)
end

env.AddPrefabPostInit("monkey", function(inst)
    if not TheWorld.ismastersim then
        return
    end
	inst:ListenForEvent("entitywake",OnMONKEYWake)
	inst:ListenForEvent("entitysleep",OnMONKEYSleep)
end)





--- TRADERS




local env = env
GLOBAL.setfenv(1, GLOBAL)



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
					item.components.gem_enchantable:AddEnchantment(spear_enchants[math.random(1,#spear_enchants)],1) -- only allow T1 magic for such a basic item	
					item.components.gem_enchantable:SetDurability(spear_enchants[math.random(1,#spear_enchants)],1) -- only allow T1 magic for such a basic item	
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
					item.components.gem_enchantable:AddEnchantment(bat_bat_enchants[math.random(1,#bat_bat_enchants)],1)
					item.components.gem_enchantable:SetDurability(bat_bat_enchants[math.random(1,#bat_bat_enchants)],1) 
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
					item.components.gem_enchantable:AddEnchantment(staff_pickaxeaxe_enchants[math.random(1,#staff_pickaxeaxe_enchants)],1) 
					item.components.gem_enchantable:SetDurability(staff_pickaxeaxe_enchants[math.random(1,#staff_pickaxeaxe_enchants)],1) 
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
			if item.components.gem_enchantable then
				if item.prefab == "firestaff" or item.prefab == "icestaff" or item.prefab == "telestaff" or item.prefab == "multitool_axe_pickaxe" then
					if item.prefab == "telestaff" then
            			item.components.gem_enchantable:AddEnchantment(magic_staff_enchants[math.random(1,#magic_staff_enchants)], 2)
            			item.components.gem_enchantable:SetDurability(magic_staff_enchants[math.random(1,#magic_staff_enchants)], 1)
					else
						item.components.gem_enchantable:AddEnchantment(staff_pickaxeaxe_enchants[math.random(1,#staff_pickaxeaxe_enchants)],2) -- higher enchant on the magic items				
            			item.components.gem_enchantable:SetDurability(staff_pickaxeaxe_enchants[math.random(1,#magic_staff_enchants)], 1)
					end
				end
				if item.prefab == "ruins_bat" or item.prefab == "orangestaff" or item.prefab == "yellowstaff" then
					if item.prefab == "ruins_bat" then --AXE For the AG loot drops, the tools will always be enchanted, unlike the lab chests, which are only enchanted with some chance.
						item.components.gem_enchantable:AddEnchantment(spear_enchants[math.random(1,#spear_enchants)],2) -- higher enchant on the magic items
						item.components.gem_enchantable:SetDurability(spear_enchants[math.random(1,#spear_enchants)],1) 
					else
						item.components.gem_enchantable:AddEnchantment(magic_staff_enchants[math.random(1,#magic_staff_enchants)],2) -- higher enchant on the magic items
						item.components.gem_enchantable:SetDurability(spear_enchants[math.random(1,#spear_enchants)],1) 
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


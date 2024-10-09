local env = env
local cooking = require("cooking")
GLOBAL.setfenv(1, GLOBAL)

--[[
# TODO
- Give beefalo foods a stat bonus to compensate for their bad ingredients.
]]

env.AddComponentPostInit("stewer", function(self)
    local _OldStartCooking = self.StartCooking

    local function InvertVeggieStats(v, value)
        return v.components.edible.foodtype == FOODTYPE.ROUGHAGE and 0
            or not v:HasTag("mushroom") and v.components.edible.foodtype == FOODTYPE.VEGGIE and value < 0 and math.abs(value) or value
    end

    function self:StartCooking(doer)
        --awfully verbose, but keeps the code understandable. Could've just had the numbers here instead in an order.
        self.food_stats = {
            { hunger = nil, health = nil, sanity = nil },
            { hunger = nil, health = nil, sanity = nil },
            { hunger = nil, health = nil, sanity = nil },
            { hunger = nil, health = nil, sanity = nil },
        }

        if self.inst.components.container.slots ~= nil then
            for i, v in ipairs(self.inst.components.container.slots) do
                if v.components ~= nil and v.components.edible then
                    local product_pref = nil

                    if not v:HasTag("mushroom") and (v.components.edible.foodtype == FOODTYPE.MEAT or v.components.edible.foodtype == FOODTYPE.VEGGIE) and
                        v.components.cookable ~= nil
                        and v.components.cookable.product ~= nil then
                        product_pref = SpawnPrefab(v.components.cookable.product)
                        product_pref:Hide()

                        v = product_pref
                    end

                    self.food_stats[i].hunger = InvertVeggieStats(v, v.components.edible.hungervalue) + (v.potstats.hunger or 0)
                    self.food_stats[i].health = InvertVeggieStats(v, v.components.edible.healthvalue) + (v.potstats.health or 0)
                    self.food_stats[i].sanity = InvertVeggieStats(v, v.components.edible.sanityvalue) + (v.potstats.sanity or 0)


                    if product_pref ~= nil then
                        product_pref:Remove()
                    end
                end
            end
        end

        _OldStartCooking(self, doer)
    end

    local _OldHarvest = self.Harvest

    function self:Harvest(harvester)
        if self.done then
            if self.onharvest ~= nil then
                self.onharvest(self.inst)
            end

            if self.product ~= nil then
                local loot = SpawnPrefab(self.product)
                if loot ~= nil then
                    local recipe = cooking.GetRecipe(self.inst.prefab, self.product)

                    if harvester ~= nil and
                        self.chef_id == harvester.userid and
                        recipe ~= nil and
                        recipe.cookbook_category ~= nil and
                        cooking.cookbook_recipes[recipe.cookbook_category] ~= nil and
                        cooking.cookbook_recipes[recipe.cookbook_category][self.product] ~= nil then
                        harvester:PushEvent("learncookbookrecipe", { product = self.product, ingredients = self.ingredient_prefabs })
                    end

                    local stacksize = recipe and recipe.stacksize or 1
                    if loot.components.edible == nil and stacksize > 1 then
                        loot.components.stackable:SetStackSize(stacksize)
                    else
                        loot:RemoveComponent("stackable") -- lord forgive me
                    end

                    if loot.components.edible ~= nil then
                        local hunger_mult = loot.components.edible.hungervalue ~= nil and loot.components.edible.hungervalue / 200 or 0
                        local health_mult = loot.components.edible.healthvalue ~= nil and loot.components.edible.healthvalue / 80 or 0
                        local sanity_mult = loot.components.edible.sanityvalue ~= nil and loot.components.edible.sanityvalue / 33 or 0

                        local original_stats = { hunger = loot.components.edible.hungervalue, health = loot.components.edible.healthvalue, sanity = loot.components.edible.sanityvalue }


                        local meta = {
                            __call = function(self)
                                local sum = 0
                                for i = 1, 4 do sum = sum + self[i] end
                                return sum
                            end
                        }

                        local hunger_values = {}
                        local health_values = {}
                        local sanity_values = {}

                        --lets me just call the function to get the sum.
                        setmetatable(hunger_values, meta)
                        setmetatable(health_values, meta)
                        setmetatable(sanity_values, meta)

                        for i = 1, 4 do
                            table.insert(hunger_values, self.food_stats[i].hunger ~= nil and self.food_stats[i].hunger > 0 and self.food_stats[i].hunger * (1 + hunger_mult) or 0)
                            table.insert(health_values, self.food_stats[i].health ~= nil and self.food_stats[i].health > 0 and self.food_stats[i].health * (1 + health_mult) or 0)
                            table.insert(sanity_values, self.food_stats[i].sanity ~= nil and self.food_stats[i].sanity > 0 and self.food_stats[i].sanity * (1 + sanity_mult) or 0)
                        end

                        print(hunger_values())
                        print(health_values())
                        print(sanity_values())
                        printwrap("original stats", original_stats)

                        loot.components.edible.cookstat_hunger = hunger_values()
                        loot.components.edible.cookstat_health = health_values()
                        loot.components.edible.cookstat_sanity = sanity_values()

                        loot.components.edible.hungervalue = loot.components.edible.cookstat_hunger
                        loot.components.edible.healthvalue = loot.components.edible.cookstat_health
                        loot.components.edible.sanityvalue = loot.components.edible.cookstat_sanity

                        local mults = { hunger = hunger_values() / original_stats.hunger, health = health_values() / original_stats.health, sanity = sanity_values() / original_stats.sanity }
                        printwrap("mults", mults)
                        local high_mults = 0
                        for k, v in pairs(mults) do
                            if v > 3 then
                                high_mults = high_mults + 1
                            end
                        end
                        loot.food_prefix = high_mults >= 2 and "BALANCED" or
                            mults.hunger > 3 and "FILLING" or
                            mults.health > 3 and "HEALTHY" or
                            mults.sanity > 3 and "SOOTHING" or
                            (hunger_values() < original_stats.hunger - 25 and "MEAGER") or
                            (health_values() < original_stats.health - 25 and "UNHEALTHY") or
                            (sanity_values() < original_stats.sanity - 25 and "RANCID") or nil
                    end
                    if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                        local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                        loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                        loot.components.perishable:StartPerishing()
                    end
                    if harvester ~= nil and harvester.components.inventory ~= nil then
                        harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                    else
                        LaunchAt(loot, self.inst, nil, 1, 1)
                    end
                end
                self.product = nil
            end

            if self.task ~= nil then
                self.task:Cancel()
                self.task = nil
            end

            self.targettime = nil
            self.done = nil
            self.spoiltime = nil
            self.product_spoilage = nil

            if self.inst.components.container ~= nil then
                self.inst.components.container.canbeopened = true
            end

            return true
        end
    end

    local _OldOnLoad = self.OnLoad

    self.OnLoad = function(self, data)
        self.food_stats = data.food_stats
        return _OldOnLoad(self, data)
    end

    local _OnSave = self.OnSave
    self.OnSave = function(self)
        local _oldData = _OnSave(self)
        local newdata = {
            food_stats = self.food_stats
        }

        if _oldData ~= nil then
            for k, v in pairs(_oldData) do
                newdata[k] = v
            end
        end

        return newdata
    end
end)

env.AddComponentPostInit("edible", function(self)
    local _OldOnLoad = self.OnLoad

    self.OnLoad = function(self, data)
        if self.inst.components.stackable ~= nil then
            self.inst:RemoveComponent("stackable")
        end

        if data.cookstat_hunger ~= nil then
            self.cookstat_hunger = data.cookstat_hunger
            self.inst.components.edible.hungervalue = data.cookstat_hunger
        end

        if data.cookstat_health ~= nil then
            self.cookstat_health = data.cookstat_health
            self.inst.components.edible.healthvalue = data.cookstat_health
        end

        if data.cookstat_sanity ~= nil then
            self.cookstat_sanity = data.cookstat_sanity
            self.inst.components.edible.sanityvalue = data.cookstat_sanity
        end

        return _OldOnLoad(self, data)
    end

    local _OnSave = self.OnSave
    self.OnSave = function(self)
        local _oldData = _OnSave(self)
        local newdata = {
            cookstat_hunger = self.cookstat_hunger,
            cookstat_health = self.cookstat_health,
            cookstat_sanity = self.cookstat_sanity,
        }

        if _oldData ~= nil then
            for k, v in pairs(_oldData) do
                newdata[k] = v
            end
        end

        return newdata
    end
end)

--Seperate from the edible cmp stats. Lets inedible ingredients to have stats.
--Made global for mod compatibility.
INGREDIENT_STATS =
{
    ["watermelon_cooked"] =
    {
        hunger_mod = nil,
        health_mod = 3,
        sanity_mod = nil,
    },
    ["cave_banana"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["cave_banana_cooked"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["corn_cooked"] =
    {
        hunger_mod = 25,
        health_mod = nil,
        sanity_mod = nil,
    },
    ["honey"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 2,
    },
    ["nightmarefuel"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = -10,
    },
    ["tallbirdegg_cooked"] =
    {
        hunger_mod = nil,
        health_mod = 3,
        sanity_mod = nil,
    },
    ["boneshard"] = {
        hunger_mod = 10,
        health_mod = 10,
        sanity_mod = 10
    }
}

for k, v in pairs(INGREDIENT_STATS) do
    env.AddPrefabPostInit(k, function(inst)
        if not TheWorld.ismastersim then return end --do we let the client also get this too??

        inst.potstats = {
            hunger = v.hunger_mod,
            health = v.health_mod,
            sanity = v.sanity_mod,
        }
    end)
end

STRINGS.FOOD_PREFIX = {
    FILLING = "Filling",
    HEALTHY = "Healthy",
    SOOTHING = "Soothing",
    BALANCED = "Balanced",
    MEAGER = "Meager",
    UNHEALTHY = "Unhealthy",
    RANCID = "Rancid",
}

USE_PREFIX[STRINGS.FOOD_PREFIX.FILLING] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.HEALTHY] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.SOOTHING] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.BALANCED] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.MEAGER] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.UNHEALTHY] = true
USE_PREFIX[STRINGS.FOOD_PREFIX.RANCID] = true

local _GetAdjectivedName = EntityScript.GetAdjectivedName
EntityScript.GetAdjectivedName = function(self)
    local name = self:GetBasicDisplayName()

    if self.food_prefix ~= nil then
        return ConstructAdjectivedName(self, name, STRINGS.FOOD_PREFIX[self.food_prefix])
    else
        return _GetAdjectivedName(self)
    end
end

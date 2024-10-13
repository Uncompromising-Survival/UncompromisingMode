local env = env
local cooking = require("cooking")
GLOBAL.setfenv(1, GLOBAL)

--[[
# TODO
- Give beefalo foods a stat bonus to compensate for their bad ingredients.
]]


--initialize net var for clients to get the prefix string
env.AddPrefabPostInitAny(function(inst)
    if inst:HasTag("preparedfood") then
        inst.net_food_prefix = net_string(inst.GUID, "loot_prefix", "loot_prefix_dirty")
    end
end)


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

                    self.food_stats[i].hunger = InvertVeggieStats(v, v.components.edible.hungervalue) + (v.potstats ~= nil and v.potstats.hunger or 0)
                    self.food_stats[i].health = InvertVeggieStats(v, v.components.edible.healthvalue) + (v.potstats ~= nil and v.potstats.health or 0)
                    self.food_stats[i].sanity = InvertVeggieStats(v, v.components.edible.sanityvalue) + (v.potstats ~= nil and v.potstats.sanity or 0)


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

                    --[[local stacksize = recipe and recipe.stacksize or 1
                    if loot.components.edible == nil and stacksize > 1 then
                        loot.components.stackable:SetStackSize(stacksize)
                    else
                        loot:RemoveComponent("stackable") -- lord forgive me
                    end]]

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

                        if loot.components.edible ~= nil and loot.components.edible.foodtype ~= FOODTYPE.ROUGHAGE then
                            loot.components.edible.cookstat_hunger = hunger_values()
                            loot.components.edible.cookstat_health = health_values()
                            loot.components.edible.cookstat_sanity = sanity_values()

                            loot.components.edible.hungervalue = loot.components.edible.cookstat_hunger
                            loot.components.edible.healthvalue = loot.components.edible.cookstat_health
                            loot.components.edible.sanityvalue = loot.components.edible.cookstat_sanity

                            local mults = { hunger = hunger_values() / original_stats.hunger, health = health_values() / original_stats.health, sanity = sanity_values() / original_stats.sanity }

                            local high_mults = 0

                            for k, v in pairs(mults) do
                                if v > 2 then
                                    high_mults = high_mults + 1
                                end
                            end

                            loot.original_stats = original_stats
                            loot.food_prefix = high_mults >= 2 and "BALANCED" or
                                mults.hunger > 2 and "FILLING" or
                                mults.health > 2 and "HEALTHY" or
                                mults.sanity > 2 and "SOOTHING" or
                                (hunger_values() < original_stats.hunger - 25 and "MEAGER") or
                                (health_values() < original_stats.health - 25 and "UNHEALTHY") or
                                (sanity_values() < original_stats.sanity - 25 and "RANCID") or nil
                            if loot.food_prefix ~= nil then
                                loot.net_food_prefix:set(loot.food_prefix)
                            end
                        end
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
        self.inst.food_prefix = data.food_prefix
        if self.inst.food_prefix ~= nil then
            self.inst.net_food_prefix:set(self.inst.food_prefix)
        end
        self.inst.original_stats = data.original_stats
        return _OldOnLoad(self, data)
    end

    local _OnSave = self.OnSave
    self.OnSave = function(self)
        local _oldData = _OnSave(self)

        if _oldData ~= nil then
            _oldData.food_stats = self.food_stats
            _oldData.food_prefix = self.inst.food_prefix
            _oldData.original_stats = self.inst.original_stats
        end


        --[[local newdata = {
            food_stats = self.food_stats,
            food_prefix = self.inst.food_prefix,
            original_stats = self.inst.original_stats
        }

        if _oldData ~= nil then
            for k, v in pairs(_oldData) do
                newdata[k] = v
            end
        end

        printwrap("newdata", newdata)]]
        return _oldData --newdata
    end
end)

env.AddComponentPostInit("edible", function(self)
    local _OldOnLoad = self.OnLoad

    self.OnLoad = function(self, data)
        --[[if self.inst.components.stackable ~= nil then
            self.inst:RemoveComponent("stackable")
        end]]

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

        self.inst.food_prefix = data.food_prefix
        if self.inst.food_prefix ~= nil then
            self.inst.net_food_prefix:set(self.inst.food_prefix)
        end
        self.inst.original_stats = data.original_stats

        return _OldOnLoad(self, data)
    end

    local _OnSave = self.OnSave
    self.OnSave = function(self)
        local _oldData = _OnSave(self)
        local newdata = {
            cookstat_hunger = self.cookstat_hunger,
            cookstat_health = self.cookstat_health,
            cookstat_sanity = self.cookstat_sanity,
            original_stats = self.inst.original_stats,
            food_prefix = self.inst.food_prefix
        }

        if _oldData ~= nil then
            for k, v in pairs(_oldData) do
                newdata[k] = v
            end
        end

        return newdata
    end
    local _DiluteChill = self.DiluteChill

    function self:DiluteChill(item, count)
        _DiluteChill(self, item, count)

        local stacksize = self.inst.components.stackable.stacksize

        if item:HasTag("preparedfood") then
            self.hungervalue = (stacksize * self.hungervalue + count * item.components.edible.hungervalue) / (stacksize + count)
            self.healthvalue = (stacksize * self.healthvalue + count * item.components.edible.healthvalue) / (stacksize + count)
            self.sanityvalue = (stacksize * self.sanityvalue + count * item.components.edible.sanityvalue) / (stacksize + count)
        end

        if self.inst.original_stats ~= nil then
            local original_stats = self.inst.original_stats
            local mults = { hunger = self.hungervalue / original_stats.hunger, health = self.healthvalue / original_stats.health, sanity = self.sanityvalue / original_stats.sanity }

            local high_mults = 0

            for k, v in pairs(mults) do
                if v > 2 then
                    high_mults = high_mults + 1
                end
            end

            self.inst.food_prefix = high_mults >= 2 and "BALANCED" or
                mults.hunger > 2 and "FILLING" or
                mults.health > 2 and "HEALTHY" or
                mults.sanity > 2 and "SOOTHING" or
                (self.hungervalue < original_stats.hunger - 25 and "MEAGER") or
                (self.healthvalue < original_stats.health - 25 and "UNHEALTHY") or
                (self.sanityvalue < original_stats.sanity - 25 and "RANCID") or nil
        end
    end
end)

--Seperate from the edible cmp stats. Lets inedible ingredients to have stats.
--Made global for mod compatibility.
INGREDIENT_STATS =
{
    --farm crops
    --explicity doing popcorn here because if I applied to both normal and popcorn it'd make normal corn REALLY good.
    ["corn_cooked"] =
    {
        hunger_mod = 25,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["onion"] = {
        hunger_mod = nil,
        health_mod = 10,
        sanity_mod = 10,
    },
    ["garlic"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["pepper"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["tomato"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 7.5,
    },
    ["watermelon"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 10,
    },
    ["dragonfruit"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["pumpkin"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 7.5,
    },
    ["pomegranate"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["asparagus"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 7.5,
    },
    ["durian"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["eggplant"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 5,
    },
    ["potato"] = {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 10,
    },
    ["cave_banana"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = 10,
    },
    ["honey"] =
    {
        hunger_mod = 6,
        health_mod = nil,
        sanity_mod = 7.5,
    },
    ["nightmarefuel"] =
    {
        hunger_mod = nil,
        health_mod = nil,
        sanity_mod = -10,
    },
    ["tallbirdegg"] =
    {
        hunger_mod = nil,
        health_mod = 5,
        sanity_mod = nil,
    },
    ["boneshard"] = {
        hunger_mod = 5,
        health_mod = 5,
        sanity_mod = nil
    },
    ["goatmilk"] = {
        hunger_mod = 10,
        health_mod = 5,
        sanity_mod = 10
    },
    ["fishmeat"] = {
        hunger_mod = nil,
        health_mod = 5,
        sanity_mod = 5
    },
    ["fishmeat_small"] = {
        hunger_mod = nil,
        health_mod = 2.5,
        sanity_mod = 2.5
    },
    ["acorn"] = {
        hunger_mod = nil,
        health_mod = 2.5,
        sanity_mod = nil
    },
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

    --prefab postinit doesn't error when trying to postinit a non-existing prefab, so no need for a check here. Although maybe it affects performance slightly.
    env.AddPrefabPostInit(k .. "_cooked", function(inst)
        if not TheWorld.ismastersim then return end

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

--I'm not even sure this is needed???
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
    --what the fuck am I doing at this point
    if self.food_prefix ~= nil or self.net_food_prefix ~= nil and self.net_food_prefix:value() ~= nil and self.net_food_prefix:value():len() > 0 then
        return ConstructAdjectivedName(self, name, STRINGS.FOOD_PREFIX[self.net_food_prefix ~= nil and self.net_food_prefix:value() or self.food_prefix])
    else
        return _GetAdjectivedName(self)
    end
end


--to handle unstacking foods
env.AddComponentPostInit("stackable", function(self)
    local _Get = self.Get
    function self:Get(num)
        local instance = _Get(self, num)
        if instance ~= nil and instance.components.edible ~= nil then
            instance.components.edible.health = self.inst.components.edible.health
            instance.components.edible.hungervalue = self.inst.components.edible.hungervalue
            instance.components.edible.sanityvalue = self.inst.components.edible.sanityvalue
        end

        return instance
    end
end)

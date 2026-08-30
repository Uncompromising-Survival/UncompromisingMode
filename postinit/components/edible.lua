--[[
Documentation: KoreanWaffles

Characters can have three types of food affinity: Prefab Affinity, Tag Affinity, and Foodtype Affinity
Prefab Affinity is specifying a prefab to give bonus hunger (e.g. Bacon and Eggs for Wilson)
Tag Affinity is specifying all foods with a certain tag to give bonus hunger (not used in base game)
Foodtype Affinity is specifying all foods of a certain type to give bonus hunger (e.g. veggies for Wurt)

It is assumed that any prefab affinity is considered a character's favorite food, and thus will be
converted into bonus sanity, but not tag affinity or foodtype affinity (if foodtype affinity was included,
Wurt would gain sanity from eating any vegetable!). If you want to specify a character to have all
foods of a certain tag or foodtype to be their favorite foods, please use the favorite_food_fn function
in the foodaffinity component.

Please refer to postinit/components/foodaffinity for related changes and further documentation
regarding characters' favorite foods.

DoFoodEffects in postinit/components/eater was modified to check for favorite foods.
]]

AddComponentPostInit("edible", function(self)
    --- NEW FUNCTION
    --- Determines if this food is a character's favorite food.
    --- @eater: The character eating this food.
    function self:IsFavoriteFood(eater)
        local foodaffinity = eater and eater.components.foodaffinity
        if foodaffinity then
            local prefab = foodaffinity:GetFoodBasePrefab(self.inst)
            local prefab_affinity = foodaffinity:HasPrefabAffinity(self.inst)
            local favorite_foods = foodaffinity.favorite_foods
            local favorite_food_fn = foodaffinity.favorite_food_fn
            return favorite_foods and favorite_foods[prefab] and true or prefab_affinity or favorite_food_fn and favorite_food_fn(self.inst)
        end
        return false
    end

    -- Prevent favorite foods from reducing health.
    local _GetHealth = self.GetHealth
    function self:GetHealth(eater, ...)
        local healthvalue = _GetHealth(self, eater, ...) or 0
        if self:IsFavoriteFood(eater) then
            -- favorite foods will not incur health penalties
            healthvalue = math.max(0, healthvalue)
        end
        return healthvalue
    end

    -- Reverse the bonus hunger granted by favorite foods.
    local _GetHunger = self.GetHunger
    function self:GetHunger(eater, ...)
        local hungervalue = _GetHunger(self, eater, ...)
        local multiplier = 1

        --temp fix we should probably seee *why* eater is being nil.
        local foodaffinity = eater and eater.components.foodaffinity
        if foodaffinity then
            local found_affinities = {}

            if foodaffinity.prefab_affinities[self.inst.prefab] ~= nil then
                table.insert(found_affinities, foodaffinity.prefab_affinities[self.inst.prefab])
            end

            local basefood = foodaffinity:GetFoodBasePrefab(self.inst)
            local prefabaffinity = foodaffinity.prefab_affinities[basefood]
            if prefabaffinity ~= nil then
                table.insert(found_affinities, prefabaffinity)
            end

            if #found_affinities > 0 then
                if #found_affinities > 1 then
                    -- Sort the found_affinities so we return the biggest bonus
                    table.sort(found_affinities, function(a, b) return a > b end)
                end
                multiplier = multiplier / found_affinities[1]
            end
        end

        return hungervalue * multiplier
    end

    -- Calculations for favorite food sanity.
    local _GetSanity = self.GetSanity
    function self:GetSanity(eater, ...)
        local ignoresspoilage_temp
        local eatercomp = eater and eater:HasTag("ratwhisperer") and eater.components.eater -- Winky doesn't care about spoilage regarding sanity.
        if eatercomp then
            ignoresspoilage_temp = eatercomp.ignoresspoilage
            eatercomp.ignoresspoilage = true
        end
        local sanityvalue = _GetSanity(self, eater, ...) or 0
        if ignoresspoilage_temp ~= nil then eatercomp.ignoresspoilage = ignoresspoilage_temp end
        local addend = 0
        if self:IsFavoriteFood(eater) then
            -- favorite foods will not incur sanity penalties
            sanityvalue = math.max(0, sanityvalue)
            local prefab = eater.components.foodaffinity:GetFoodBasePrefab(self.inst)
            local favorite_foods = eater.components.foodaffinity.favorite_foods
            local healthvalue = self:GetHealth(eater) or 0
            local hungervalue = self:GetHunger(eater) or 0
            addend = favorite_foods and favorite_foods[prefab] or math.max(5, healthvalue / 4, hungervalue / 5, sanityvalue / 3)
        end
        return sanityvalue + addend
    end
end)

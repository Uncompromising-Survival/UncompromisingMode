local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local DONT_FIRELOOT_LOOT_TAGS = {"structure", "tree", "boulder", "hive", "prey"}

env.AddComponentPostInit("lootdropper", function(self)
    local _DropLoot = self.DropLoot
    --[[local _GenerateLoot = self.GenerateLoot
    if TUNING.DSTU.WARLY_BUTCHER then
        function self:GenerateLoot()
            if self.inst:HasTag("butchermark") then
                local loots = {}
                local previous_prefab = nil

                if self.lootsetupfn then
                    self.lootsetupfn(self)
                end

                local function butcherloot(prefab)
                    if self.inst:HasTag("butchermark") --and not
                        --(self.inst:HasTag("epic") or
                            --self.inst:HasTag("veggie") or
                            --self.inst:HasTag("structure") or
                            --self.inst:HasTag("wall") or
                            --self.inst:HasTag("balloon") or
                            --self.inst:HasTag("soulless") or
                            --self.inst:HasTag("chess") or
                            --self.inst:HasTag("shadow") or
                            --self.inst:HasTag("shadowcreature") or
                            --self.inst:HasTag("shadowminion") or
                            --self.inst:HasTag("shadowchesspiece") or
                            --self.inst:HasTag("groundspike") or
                            --self.inst:HasTag("smashable"))
                        --and math.random() <= .25
                        and (previous_prefab == nil or previous_prefab ~= prefab) then
                        table.insert(loots, prefab)
                    end
                    previous_prefab = prefab
                end

                if self.numrandomloot and math.random() <= (self.chancerandomloot or 1) then
                    for k = 1, self.numrandomloot do
                        local loot = self:PickRandomLoot()
                        if loot then
                            table.insert(loots, loot)
                            butcherloot(loot)
                        end
                    end
                end

                if self.chanceloot then
                    for k, v in pairs(self.chanceloot) do
                        if v.chance >= 1.0 then
                            table.insert(loots, v.prefab)
                            butcherloot(v.prefab)
                        elseif math.random() < v.chance then
                            table.insert(loots, v.prefab)
                            butcherloot(v.prefab)
                            self.droppingchanceloot = true
                        end
                    end
                end

                if self.chanceloottable then
                    local loot_table = LootTables[self.chanceloottable]
                    if loot_table then
                        for i, entry in ipairs(loot_table) do
                            local prefab = entry[1]
                            local chance = entry[2]
                            if chance >= 1.0 then
                                table.insert(loots, prefab)
                                butcherloot(prefab)
                            elseif math.random() <= chance then
                                table.insert(loots, prefab)
                                butcherloot(prefab)
                                self.droppingchanceloot = true
                            end
                        end
                    end
                end

                if not self.droppingchanceloot and self.ifnotchanceloot then
                    self.inst:PushEvent("ifnotchanceloot")
                    for k, v in pairs(self.ifnotchanceloot) do
                        table.insert(loots, v.prefab)
                        butcherloot(v.prefab)
                    end
                end

                if self.loot then
                    for k, v in ipairs(self.loot) do
                        table.insert(loots, v)
                        butcherloot(v)
                    end
                end

                local recipe = AllRecipes[self.inst.prefab]
                if recipe then
                    local recipeloot = self:GetRecipeLoot(recipe)
                    for k, v in ipairs(recipeloot) do
                        table.insert(loots, v)
                    end
                end

                if self.inst:HasTag("burnt") and math.random() < .4 then
                    table.insert(loots, "charcoal") -- Add charcoal to loot for burnt structures
                end

                return loots
            else
                return _GenerateLoot(self)
            end
        end
    end]]

    if TUNING.DSTU.FIRELOOT > 1 then
        function self:DropLoot(pt, prefabs, ...)
            prefabs = prefabs or self:GenerateLoot()

            local burnable = self.inst.components.burnable
            if burnable and not burnable:IsControlledBurn() and burnable:IsBurning()
                and (not self.inst.components.fueled or burnable.ignorefuel) and not self.inst:HasAnyTag(DONT_FIRELOOT_LOOT_TAGS) then
                for k, v in pairs(prefabs) do
                    local item = TUNING.BURNED_LOOT_OVERRIDES[v]
                        or PrefabExists(v.."_cooked") and v.."_cooked"
                        or PrefabExists("cooked"..v) and "cooked"..v
                        or nil
                    if item then
                        prefabs[k] = item
                    else
                        self:SpawnLootPrefab("ash", pt)
                    end
                end

                for k, v in pairs(prefabs) do
                    self:SpawnLootPrefab(v, pt)
                    self:SpawnLootPrefab("fireloot", pt)
                end

                if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
                    local prefabname = string.upper(self.overridewinterlootprefabname or self.inst.prefab)
                    local num_decor_loot = self.GetWintersFeastOrnaments ~= nil and self.GetWintersFeastOrnaments(self.inst) or TUNING.WINTERS_FEAST_TREE_DECOR_LOOT[prefabname] or nil
                    if num_decor_loot ~= nil then
                        for i = 1, num_decor_loot.basic do
                            self:SpawnLootPrefab(GetRandomBasicWinterOrnament(), pt)
                        end
                        if num_decor_loot.special ~= nil then
                            self:SpawnLootPrefab(num_decor_loot.special, pt)
                        end
                    elseif not TUNING.WINTERS_FEAST_LOOT_EXCLUSION[prefabname] and self.inst:HasAnyTag("monster", "animal", "creaturecorpse") then
                        local loot = math.random()
                        if loot <= self:GetChance(TUNING.WINTERS_FEAST_BASIC_ORNAMENT_DROP_CHANCE) then
                            self:SpawnLootPrefab(GetRandomBasicWinterOrnament(), pt)
                        elseif loot <= self:GetChance(TUNING.WINTERS_FEAST_WINTER_FOOD_DROP_CHANCE) then
                            self:SpawnLootPrefab("winter_food"..math.random(NUM_WINTERFOOD), pt)
                        end
                    end
                end

                TheWorld:PushEvent("entity_droploot", {inst = self.inst})
            else
                return _DropLoot(self, pt, prefabs, ...)
            end
        end
    end
end)
--[[
Note(Atobá):
The key is the prefab name of the gem.

The values are:
{
    fns = {
        onattack = function(item, owner, target, tier) --function that runs when you hit an enemy
        onupdate = function(item, tier) --function that runs every second
        onapply = function(item, tier) -- function that runs when you apply the gem to an item - also runs on load!
        onremove = function(item, tier) -- function that runs when you remove the gem from an item
        onwork = function(item, owner, target, tier) -- function that runs when you chop/mine/dig/etc
        onequip= function(item, owner, tier) -- function that runs when you equip the item with the gem
        onunequip = function(item, owner, tier) -- function that runs when you unequip the item with the gem
    }
    color = RGB(r,g,b) --color for the text/durability border in the UI
    -- for mineral logbook
    desc = { --For scrapbook and insight.
        [1] = "Description for tier 1 gem"
        [2] = "Description for tier 2 gem"
        ...and so forth
    }
    createprefab = boolean --whether the item prefab is automatically created.
    build = "string" --build name - even if you don't generate the prefab, you need this for scrapbook/mineral logbook.
    bank = "string" --bank name
    anim = "string" --anim name   -- defaults to "idle"
    img = "string.tex" --texture name --for scrapbook only.
    atlas = "string.xml" --atlas name
    postfn = function(inst) -- function that runs when the prefab is created on the common side on post-init.
}

Additional note:

Every gemologyable item has two fields called volatile_gemology_data and persistent_gemology_data, with holds any relevant data for gems. For example:
item.persistent_gemology_data[gem_name].foo = true
item.volatile_gemology_data[gem_name].bar = {thing = 1}

persistent is actually saved and loaded, volatile is not.

This is so we can save some gem-specific data so it can probably revert when removed.
]]


local GEM_DEFS = {}
local GEM_LOOKUP = {}
function AddGemDef(name, def)
    GEM_LOOKUP[#GEM_LOOKUP + 1] = name
    GEM_DEFS[name] = def
end

local GEM_USES = TUNING.DSTU.GEM_USES

local function AddUMGemDef(name, def) --helper function to just skip some re-used things we do.
    def.build = "um_gemologygems"
    def.bank = "um_gemologygems"
    def.img = name .. ".tex"
    def.atlas = name .. ".xml"
    def.anim = name
    def.createprefab = true

    def.desc = STRINGS.UM_DESCRIPTOR.GEM_ENCHANTABLE[string.upper(string.gsub(name, "gem", ""))]

    AddGemDef("um_gemology" .. name, def)
end


function IsEnchantValid(gem)
    return GEM_DEFS[gem] ~= nil
end

function DamageGem(enchant, item, value)
    if item.components.gem_enchantable:HasEnchantment("um_gemology" .. enchant) and item.components.gem_enchantable:HasDurabilityEnabled("um_gemology" .. enchant) then
        item.components.gem_enchantable:DoDurabilityDelta("um_gemology" .. enchant, -value)
    end
end

------------------------------------------------------------------
--REDGEM2

AddUMGemDef("redgem2", {
    color = RGB(233, 153, 153),
    fns = {
        onattack = function(inst, attacker, target, tier)
            if target.components.health then
                target.components.health:DoFireDamage(TUNING.DSTU.REDGEM2_DAMAGE[tier], attacker, true)
                SpawnPrefab("deer_fire_burst").Transform:SetPosition(target.Transform:GetWorldPosition())
                if tier ~= 1 and target.components.burnable and target.components.burnable:IsBurning() then
                    target.components.health:DoFireDamage(inst.components.weapon:GetDamage(attacker, target) * TUNING.DSTU.REDGEM2_BURNING_MULT[tier], attacker, true)
                    target.components.burnable:ExtendBurning()
                end
                DamageGem("redgem2", inst, GEM_USES[tier])
            end
        end,
        canapply = function(item, tier)
            return item.components.weapon ~= nil
        end
    },
})

-------------------------------------------------------------------
--REDGEM1
local devour_tags = { "animal", "pig", "monster", "smallcreature" }
local devour_mults = { 1 / 10, 1 / 5 }

AddUMGemDef("redgem1", {
    color = RGB(233, 153, 153),
    fns = {
        onattack = function(inst, attacker, target, tier)
            if tier ~= 1 and target:HasOneOfTags(devour_tags) and math.random() > 0.75 then -- arbitrarily said "a chance", I have no idea how common this should be
                local mult = TUNING.DSTU.REDGEM1_DEVOUR_MULT[tier]
                attacker.components.combat:DoAttack(target, inst, nil, nil, mult, 0)        -- gotta use a bit more durability...
                mult = inst.components.weapon:GetDamage(attacker, target) * mult
                --owner.components.sanity:DoDelta(-mult)
                attacker.components.hunger:DoDelta(mult * TUNING.DSTU.REDGEM1_HUNGER_MULT)
            end

            if target.components.health ~= nil and target.components.health:IsDead() then -- Devour
                local recover = target.components.health.maxhealth * TUNING.DSTU.REDGEM1_HEALTH_MULT * tier
                attacker.components.health:DoDelta(recover)
                attacker.components.sanity:DoDelta(recover)
            end

            DamageGem("redgem1", inst, GEM_USES[tier])
        end,
        canapply = function(item, tier)
            return item.components.weapon ~= nil
        end
    },
})


------------------------------------------------------------------
---GREENGEM1
local action_list = { ACTIONS.CHOP, ACTIONS.MINE, ACTIONS.DIG, ACTIONS.HAMMER }
local melee_speeds = { 1.1, 1.2, 1.4 } -- Related to the tiering system

local function GetRandomTargetOfSameType(attacker, target)
    local x, y, z = target.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x, y, z, TUNING.DSTU.GREENGEM1_SHADOW_CLONE_FIND_MAX_DIST)
    local ent_same_prefab = {}
    for i, v in ipairs(ents) do
        if v.prefab == target.prefab and ((not v:HasTag("stump") and not v:HasTag("stump")) or (target:HasTag("stump") and v:HasTag("stump"))) and target ~= v then
            table.insert(ent_same_prefab, v)
        end
    end

    return #ent_same_prefab > 0 and ent_same_prefab[math.random(1, #ent_same_prefab)] or nil
end

local swilson_symbols_to_hide = {
    "arm_lower",
    "arm_lower_cuff",
    "arm_upper",
    "arm_upper_skin",
    "cheeks",
    "face",
    "foot",
    "hairpigtails",
    "hairfront",
    "hair_hat",
    "hand",
    "headbase",
    "headbase_hat",
    "leg",
    "skirt",
    "torso",
    "torso_pelvis",
    "hair",
    "swap_icon",
    "swap_face",
    "swap_face_eye_glow",
    "swap_face_eye_glow_glasses",
    "swap_body_tall",
    "swap_body",
    --"swap_object",
    "swap_hat",
    "beard",
    "tail",
}

local function SendShadowClone(item, owner, target, tier)
    DamageGem("greengem1", item, GEM_USES[tier]) --damage on any attack/work because it speeds it up.

    if target:IsValid() and (tier - 1) * TUNING.DSTU.GREENGEM1_SHADOW_CLONE_CHANCE_MULT > math.random() and tier > 1 then
        if owner:GetDistanceSqToInst(target) > TUNING.DSTU.GREENGEM1_SHADOW_CLONE_MAX_DIST and owner.components.sanity then --Long ways away, it's taking from your mind to send swilsons there
            if target.components.combat then
                owner.components.sanity:DoDelta(TUNING.DSTU.GREENGEM1_SHADOW_CLONE_SANITY_COST)                             --If using for combat, be significantly more expensive
            end
        end

        local swilson = SpawnPrefab("swilson_labotomized")
        for i, v in ipairs(swilson_symbols_to_hide) do
            swilson.AnimState:HideSymbol(v)
        end
        local newtarget = GetRandomTargetOfSameType(owner, target)
        local angle = math.random(0, 614) / 200
        if newtarget ~= nil then
            local x, y, z = newtarget.Transform:GetWorldPosition()
            swilson.Transform:SetPosition(x + 1.5 * math.cos(angle), y, z + 1.5 * math.sin(angle))
            --swilson.green = 1 -- Tried making him green, it just looks goofy
            swilson.dupe_toolweapon = SpawnPrefab(item.prefab)
            swilson.components.inventory:Equip(swilson.dupe_toolweapon)
            swilson.dupe_toolweapon.components.inventoryitem:SetOnDroppedFn(swilson.dupe_toolweapon.Remove)

            if target.components.workable and not (target.prefab == "punchingbag" or target.prefab == "punchingbag_lunar" or target.prefab == "punchingbag_shadow" or (target.components.workable and target.components.workable.action == ACTIONS.NET)) then
                swilson.work = 1
                swilson.LabWork(swilson, owner, newtarget)
            elseif target.components.health then
                swilson.attack = item.components.weapon:GetDamage(owner, target)
                swilson.LabAttack(swilson, owner, newtarget)
            end
        end
    end
end

AddUMGemDef("greengem1", {
    color = RGB(175, 245, 172),
    fns = {
        onapply = function(item, tier)
            item.um_neurotic_mod = TUNING.DSTU.GREENGEM1_MELEE_SPEED[tier] --melee_speeds[tier]

            local tool = item.components.tool

            if tool and tool.actions then
                item.volatile_gemology_data.um_gemologygreengem1.tool_actions = {}

                for k, v in pairs(tool.actions) do
                    item.volatile_gemology_data.um_gemologygreengem1.tool_actions[k] = v
                end

                for i, v in ipairs(action_list) do
                    if tool.actions[v] then
                        tool.actions[v] = tool.actions[v] * (1 + tier * TUNING.DSTU.GREENGEM1_TOOL_EFFICENCY_MOD)
                    end
                end
            end
        end,
        onwork = SendShadowClone,
        onattack = SendShadowClone,
        onremove = function(item, tier)
            item.um_neurotic_mod = nil

            local tool = item.components.tool
            if tool and tool.actions then
                tool.actions = item.volatile_gemology_data.um_gemologygreengem1.tool_actions
            end
        end,
        canapply = function(item, tier)
            return item.components.tool ~= nil or item.components.weapon ~= nil
        end
    }
})

-----------------------------------------------------------------------------------
---Green2

local valid_enchants = { "um_gemologygreengem1", "um_gemologyyellowgem1", "um_gemologyyellowgem2", "um_gemologypalegem1", "um_gemologyredgem1", "um_gemologyredgem2", "um_gemologypurplegem1", "um_gemologypurplegem2", "um_gemologyorangegem1", "um_gemologybluegem1" }

local function addRandomGemEffects(inst)
    local tier = inst.components.gem_enchantable:GetEnchantmentTier("um_gemologygreengem2")

    if inst.persistent_gemology_data.um_gemologygreengem2.gem_effects then
        for k, v in pairs(inst.persistent_gemology_data.um_gemologygreengem2.gem_effects) do
            if inst.components.gem_enchantable.enchants[k] then
                inst.components.gem_enchantable:RemoveEnchantment(k)
            end
        end
    end

    local tries = 10
    local enchant_nums = 0

    while enchant_nums < TUNING.DSTU.GREENGEM2_MAX_ENCHANTS and tries > 0 do
        local enchant = valid_enchants[math.random(#valid_enchants)]
        if IsEnchantValid(enchant) and not inst.components.gem_enchantable:HasEnchantment(enchant) and (GEM_DEFS[enchant].canapply ~= nil and GEM_DEFS[enchant].canapply(inst, tier) or GEM_DEFS[enchant].canapply == nil) then --don't add already existing other enchants.
            inst.components.gem_enchantable:AddEnchantment(enchant, tier, true)
            inst.persistent_gemology_data.um_gemologygreengem2.gem_effects[enchant] = tier
            enchant_nums = enchant_nums + 1
        end

        tries = tries - 1
    end

    for k, v in pairs(inst.persistent_gemology_data.um_gemologygreengem2.gem_effects) do
        table.insert(inst.components.gem_enchantable.hidden_enchants, k)
    end
end

AddUMGemDef("greengem2", {
    color = RGB(175, 245, 172),
    fns = {
        onapply = function(item, tier)
            if item.persistent_gemology_data.um_gemologygreengem2.gem_effects == nil then
                item.persistent_gemology_data.um_gemologygreengem2.gem_effects = {}

                addRandomGemEffects(item)
            else
                for k, v in pairs(item.persistent_gemology_data.um_gemologygreengem2.gem_effects) do
                    item.components.gem_enchantable:AddEnchantment(k, tier, true)
                    table.insert(item.components.gem_enchantable.hidden_enchants, k)
                end
            end

            item:WatchWorldState("startday", addRandomGemEffects)
        end,
        onremove = function(item, tier)
            if item.persistent_gemology_data.um_gemologygreengem2.gem_effects then
                for k, v in pairs(item.persistent_gemology_data.um_gemologygreengem2.gem_effects) do
                    if item.components.gem_enchantable.enchants[k] then
                        item.components.gem_enchantable:RemoveEnchantment(k)
                        item.components.gem_enchantable.slots = item.components.gem_enchantable.slots - 1
                    end
                end

                for k, v in pairs(item.components.gem_enchantable.hidden_enchants) do
                    if item.persistent_gemology_data.um_gemologygreengem2.gem_effects[v] then
                        table.remove(item.components.gem_enchantable.hidden_enchants, k)
                    end
                end
            end

            item:StopWatchingWorldState("startday", addRandomGemEffects)
        end,
        onattack = function(item, attacker, target, tier)
            DamageGem("greengem2", item, GEM_USES[tier])
        end,
        onwork = function(item, attacker, target, tier)
            DamageGem("greengem2", item, GEM_USES[tier])
        end

    }
})

-----------------------------------------------------------------------------------
---Yellow1

AddUMGemDef("yellowgem1", {
    color = RGB(255, 228, 153),
    fns = {
        onapply = function(item, tier)
            if item.components.equippable then
                item.volatile_gemology_data.um_gemologyyellowgem1.old_dapperness = item.components.equippable.dapperness

                if item.components.equippable.dapperness then
                    item.components.equippable.dapperness = item.components.equippable.dapperness + TUNING.DSTU.YELLOWGEM1_SANITY[tier]
                else
                    item.components.equippable.dapperness = TUNING.DSTU.YELLOWGEM1_SANITY[tier]
                end
            end
        end,
        onupdate = function(item, tier)
            if item ~= nil and item.components.equippable:IsEquipped() then
                DamageGem("yellowgem1", item, 1 / TUNING.DSTU.YELLOWGEM1_DURATION[tier])
            end
        end,
        onremove = function(item, tier)
            if item.components.equippable then
                item.components.equippable.dapperness = item.volatile_gemology_data.um_gemologyyellowgem1.old_dapperness
            end
        end
    }
})

-----------------------------------------------------------------------------------
---Yellow2

local arc_cantarget = { "_health", "_combat" }
local arc_canttarget = { "player", "playerghost", "arcgrounded", "wall", "INLIMBO", "companion", "abigail", "invisible", "hiding", "notarget", "noattack" }


local function WetCheck(target)
    return target ~= nil and target:IsValid() and target.GetWetMultiplier ~= nil and target:GetWetMultiplier() > 0
end

local function ForceElectrocute(target, attacker)
    if target ~= nil and target:IsValid() and target.components.health ~= nil and not target.components.health:IsDead() then
        target:PushEventImmediate("electrocute", { attacker = attacker, stimuli = "electric", numforks = 0, noresist = true, })
    end
end

local function YellowDamage(inst, attacker, target, tier)
    if target ~= nil and target:IsValid() and target.components.combat ~= nil then
        local damage = TUNING.DSTU.YELLOWGEM2_SHOCK_DAMAGE[tier]

        if WetCheck(target) then
            damage = damage * TUNING.DSTU.YELLOWGEM2_SHOCK_WET_MULT
        end

        target.components.combat:GetAttacked(attacker, damage, inst, "electric")
        ForceElectrocute(target, attacker)
    end
end

local function ShockChain(inst, attacker, target, ShockAgain, tier)
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.DSTU.YELLOWGEM2_SHOCK_RANGE, arc_cantarget, arc_canttarget)

    for i, v in ipairs(ents) do
        if v ~= target and v.components.health ~= nil and not v.components.health:IsDead() and attacker.components.combat ~= nil and not attacker.components.combat:IsAlly(v) and attacker.components.combat:CanTarget(v) then
            local dist = math.sqrt(target:GetDistanceSqToInst(v))

            v:DoTaskInTime(dist / TUNING.DSTU.YELLOWGEM2_ATTACK_TIME_FACTOR, function(v)
                if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() and not v:HasTag("arcgrounded") then
                    local mult = TUNING.DSTU.YELLOWGEM2_SHOCK_DIST_FACTOR - dist

                    mult = math.clamp(mult, TUNING.DSTU.YELLOWGEM2_SHOCK_MULT_RANGES[tier][1], TUNING.DSTU.YELLOWGEM2_SHOCK_MULT_RANGES[tier][2])

                    local damage = inst.components.weapon:GetDamage(attacker, v) * mult

                    v:AddTag("arcgrounded")
                    v.components.combat:GetAttacked(attacker, damage, inst)
                    ShockAgain(inst, attacker, v, tier)

                    SpawnPrefab("electricchargedfx").Transform:SetPosition(v.Transform:GetWorldPosition())

                    v:DoTaskInTime(TUNING.DSTU.YELLOWGEM2_SHOCK_COOLDOWN, function(v)
                        if v:IsValid() then
                            v:RemoveTag("arcgrounded")
                        end
                    end)
                end
            end)
        end
    end
end

local function ElectricAttack(inst, attacker, target, tier)
    if target == nil or not target:IsValid() then
        return
    end

    SpawnElectricHitSparks(attacker, target, true)

    if tier ~= 1 then
        ShockChain(inst, attacker, target, ElectricAttack, tier)

        target:AddTag("arcgrounded")
        target:DoTaskInTime(TUNING.DSTU.YELLOWGEM2_SHOCK_COOLDOWN, function(target)
            if target:IsValid() then
                target:RemoveTag("arcgrounded")
            end
        end)
    end

    YellowDamage(inst, attacker, target, tier)

    DamageGem("yellowgem2", inst, GEM_USES[tier])
end

AddUMGemDef("yellowgem2", {
    color = RGB(255, 228, 153),

    fns = {
        onapply = function(item, tier)
            if item.prefab == "hambat" then
                item.new_max_damage = TUNING.HAMBAT_DAMAGE + TUNING.DSTU.YELLOWGEM2_SHOCK_DAMAGE[tier]
            end

            item.volatile_gemology_data.um_gemologyyellowgem2.old_stimuli = item.components.weapon.stimuli
        end,

        onattack = ElectricAttack,

        onremove = function(item, tier)
            item.new_max_damage = nil

            if item.components.weapon ~= nil then
                item.components.weapon.stimuli =
                    item.volatile_gemology_data.um_gemologyyellowgem2.old_stimuli
            end
        end,

        canapply = function(item, tier)
            return item.components.weapon ~= nil
        end
    }
})

-----------------------------------------------------------------------------------
---Pale1

AddUMGemDef("palegem1", {
    color = RGB(220, 220, 220),
    fns = {
        onapply = function(item, tier)
            -- stuff is handled elsewhere
            -- see init/init_gemology/special.lua

            if tier ~= 1
                and AllRecipes ~= nil
                and (AllRecipes[item.prefab] == nil
                    or AllRecipes[item.prefab] ~= nil
                    and (AllRecipes[item.prefab].is_deconstruction_recipe))
                and item.components.weapon ~= nil then
                local damage = item.components.weapon.damage
                item.volatile_gemology_data.um_gemologypalegem1.weapon_damage = damage
                if type(damage) == "function" then
                    item.components.weapon:SetDamage(function(inst, attacker, target)
                        return damage(inst, attacker, target) + (TUNING.DSTU.PALEGEM1_EXTRA_DAMAGE_PER_TIER * (tier - 1))
                    end)
                else
                    item.components.weapon:SetDamage(damage + (TUNING.DSTU.PALEGEM1_EXTRA_DAMAGE_PER_TIER * (tier - 1)))
                end
            end
        end,
        onattack = function(item, attacker, target, tier)
            DamageGem("palegem1", item, GEM_USES[tier])
        end,
        onremove = function(item, tier)
            if item.volatile_gemology_data.um_gemologypalegem1 and item.volatile_gemology_data.um_gemologypalegem1.weapon_damage then
                item.components.weapon:SetDamage(item.volatile_gemology_data.um_gemologypalegem1.weapon_damage)
            end
        end
    }
})

-----------------------------------------------------------------------------------
---Pale2

AddUMGemDef("palegem2", {
    color = RGB(220, 220, 220),
    fns = {
        onapply = function(item, tier)
            if item.components.finiteuses then
                local pct = item.components.finiteuses:GetPercent()
                local total = item.components.finiteuses.total
                item.volatile_gemology_data.um_gemologypalegem2.old_finite = total
                item.components.finiteuses:SetMaxUses(total * (1 + tier))
                item.components.finiteuses:SetPercent(pct)
            end
            if item.components.fueled then -- Future, there are other items that fall into this category that cannot be learned or prototyped
                local pct = item.components.fueled:GetPercent()
                local total = item.components.fueled.maxfuel
                item.volatile_gemology_data.um_gemologypalegem2.old_fueled = total

                item.components.fueled:SetPercent(pct * total * (1 + tier))
            end
            if item.components.perishable then -- it *might* work on the hambat, doesn't seem certain though
                local pct = item.components.perishable:GetPercent()
                item.volatile_gemology_data.um_gemologypalegem2.old_perish = item.components.perishable.perishtime

                item.components.perishable.perishtime = item.components.perishable.perishtime * (1 + tier)

                item.components.perishable:SetPercent(pct)
            end

            --TODO: ARMOR

            if item.components.finiteuses
                and AllRecipes ~= nil
                and (AllRecipes[item.prefab] == nil
                    or AllRecipes[item.prefab] ~= nil
                    and (AllRecipes[item.prefab].nounlock
                        or AllRecipes[item.prefab].is_deconstruction_recipe)
                ) then
                if tier ~= 1 then
                    local _Use = item.components.finiteuses.Use
                    item.volatile_gemology_data.um_gemologypalegem2.old_use = _Use
                    item.components.finiteuses.Use = function(self, num) -- Modify only this item's version of finiteuses
                        local chance = math.random()
                        if chance > TUNING.DSTU.PALEGEM2_USE_CHANCE[tier] then
                            _Use(self, num)
                        end
                    end
                end
            end
        end,
        onattack = function(item, attacker, target, tier)
            DamageGem("palegem2", item, TUNING.DSTU.PALEGEM2_USES[tier])
        end,
        onwork = function(item, attacker, target, tier)
            DamageGem("palegem2", item, TUNING.DSTU.PALEGEM2_USES[tier])
        end,

        onremove = function(item, tier)
            local old_finite = item.volatile_gemology_data.um_gemologypalegem2.old_finite
            local old_fueled = item.volatile_gemology_data.um_gemologypalegem2.old_fueled
            local old_perish = item.volatile_gemology_data.um_gemologypalegem2.old_perish
            local old_use = item.volatile_gemology_data.um_gemologypalegem2.old_use

            --Re-setting the durability needs to be delayed 1 frame so it does so AFTER the enchament is properly removed
            --otherwise, it doesn't properly revert durability
            --the volatile data are stored as variables above because they also get wiped when the enchantment is removed, so we save them here.
            item:DoTaskInTime(0, function()
                if item.components.finiteuses then
                    local pct = item.components.finiteuses:GetPercent()

                    item.components.finiteuses:SetMaxUses(old_finite)
                    item.components.finiteuses:SetPercent(pct)

                    if old_use ~= nil then
                        item.components.finiteuses.Use = old_use
                    end
                end

                if item.components.fueled then
                    local pct = item.components.fueled:GetPercent()
                    item.components.fueled.maxfuel = old_fueled
                    item.components.fueled:SetPercent(pct)
                end

                if item.components.perishable then
                    local pct = item.components.perishable:GetPercent()
                    item.components.perishable.perishtime = old_perish
                    item.components.perishable:SetPercent(pct)
                end
            end)
        end,
        canapply = function(item, tier)
            return item.components.fueled ~= nil or item.components.finiteuses ~= nil or item.components.perishable ~= nil
        end
    }
})
-----------------------------------------------------------------------------------
---Purple1

local function HambatUpdateDamage(inst)
    if inst.components.perishable and inst.components.weapon then
        local dmg = TUNING.HAMBAT_DAMAGE * inst.components.perishable:GetPercent()
        dmg = Remap(dmg, 0, inst.new_max_damage and inst.new_max_damage or TUNING.HAMBAT_DAMAGE, TUNING.HAMBAT_MIN_DAMAGE_MODIFIER / 2 * TUNING.HAMBAT_DAMAGE,
            TUNING.HAMBAT_DAMAGE)
        if dmg < TUNING.DSTU.PURPLEGEM1_EXTRA_DAMAGE_THRESHOLD and inst.components.gem_enchantable ~= nil and inst.components.gem_enchantable:HasEnchantment("um_gemologypurplegem1") then
            dmg = dmg + dmg * inst.components.gem_enchantable:GetEnchantmentTier("um_gemologypurplegem1") * TUNING.DSTU.PURPLEGEM1_EXTRA_DAMAGE_MULT
        end
        inst.components.weapon:SetDamage(dmg)
    end
end


AddUMGemDef("purplegem1", {
    color = RGB(180, 166, 213),
    fns = {
        onapply = function(item, tier)
            if item.prefab == "hambat" and tier ~= 1 then -- hambat needs an exception
                item.volatile_gemology_data.um_gemologypurplegem1.old_update_damage = item.UpdateDamage
                item.UpdateDamage = HambatUpdateDamage
            end
        end,
        onattack = function(item, attacker, target, tier)
            if item.tier ~= 1 and item.components.weapon ~= nil then
                local damage = item.components.weapon:GetDamage(attacker, target)
                if damage < TUNING.DSTU.PURPLEGEM1_EXTRA_DAMAGE_THRESHOLD and item.prefab ~= "hambat" then
                    damage = damage * tier * TUNING.DSTU.PURPLEGEM1_EXTRA_DAMAGE_MULT
                    local stimuli = item.components.weapon.stimuli and item.components.weapon.stimuli or nil
                    target.components.combat:GetAttacked(attacker, damage, nil, stimuli)
                    DamageGem("purplegem1", item, GEM_USES[tier])
                end
            end
        end,
        onremove = function(item, tier)
            if item.volatile_gemology_data.um_gemologypurplegem1.old_update_damage then
                item.UpdateDamage = item.volatile_gemology_data.um_gemologypurplegem1.old_update_damage
            end
        end
    }
})

-----------------------------------------------------------------------------------
---Purple2
---
local function GrabNearItem(inst, owner)
    local item = FindEntity(owner, TUNING.DSTU.PURPLEGEM2_ITEM_GRAB_RANGE, function(ent) return ent.components.inventoryitem and ent ~= inst end)
    if item then
        local fx = SpawnPrefab("shadow_puff")
        fx.Transform:SetPosition(item.Transform:GetWorldPosition())
        owner.components.inventory:GiveItem(item)
    end
end

local function OnDropedIfDeadGiveBack(inst) -- This is the only one that has an "ondropped" effects
    local tier = inst.components.gem_enchantable:GetEnchantmentTier("um_gemologypurplegem2")
    local owner = FindEntity(inst, TUNING.DSTU.PURPLEGEM2_OWNER_RANGE, function(ent) return ent:HasTag("player") end)

    inst:DoTaskInTime(math.random(), function(inst)
        if owner and (owner.components.health:IsDead() or owner.sg ~= nil and owner.sg:HasStateTag("dead") or owner:HasTag("playerghost")) then -- If this happens, the owner has just died.
            if tier ~= 1 then
                for i = 1, tier do
                    GrabNearItem(inst, owner)
                end
            end

            owner.components.inventory:GiveItem(inst) -- Give the ghost back the item
            local fx = SpawnPrefab("shadow_puff")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

            DamageGem("purplegem2", inst, TUNING.DSTU.PURPLEGEM2_USES[tier])
        end
    end)

    if inst.volatile_gemology_data.um_gemologypurplegem2.old_ondropfn then
        inst.volatile_gemology_data.um_gemologypurplegem2.old_ondropfn(inst)
    end
end



AddUMGemDef("purplegem2", {
    color = RGB(180, 166, 213),
    fns = {
        onapply = function(item, tier)
            item.volatile_gemology_data.um_gemologypurplegem2.old_ondropfn = item.components.inventoryitem.ondropfn
            item.components.inventoryitem:SetOnDroppedFn(OnDropedIfDeadGiveBack)
        end,
        onremove = function(item, tier)
            item.components.inventoryitem:SetOnDroppedFn(item.volatile_gemology_data.um_gemologypurplegem2.old_ondropfn)
        end
    }
})

-----------------------------------------------------------------------------------
---Orange1

local function FindUniqueBaseStructures(inst, tier)
    if inst.entity:IsAwake() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, TUNING.DSTU.ORANGEGEM1_STRUCTURE_RANGE, { "structure" })
        local uniquestructures = {}
        for i, v in ipairs(ents) do
            if not table.contains(uniquestructures, v.prefab) then
                table.insert(uniquestructures, v.prefab)
            end
        end
        inst.structurebonus = math.clamp(#uniquestructures, 0, TUNING.DSTU.ORANGEGEM1_MAX_STRUCTURES) * tier / TUNING.DSTU.ORANGEGEM1_BONUS_FACTOR
    end
end

local function BaseSitterAttack(item, attacker, target, tier)
    DamageGem("orangegem1", item, GEM_USES[tier])

    if tier ~= 1 then
        local damage = item.components.weapon:GetDamage(attacker, target)
        local fx = SpawnPrefab("sand_puff")
        fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        fx.Transform:SetScale(0.05 + 2 * item.structurebonus, 0.05 + 2 * item.structurebonus, 0.05 + 2 * item.structurebonus)
        target.components.combat:GetAttacked(attacker, damage * item.structurebonus)
    end
end


AddUMGemDef("orangegem1", {
    color = RGB(249, 203, 156),
    fns = {
        onattack = BaseSitterAttack,
        onremove = function(item, tier)
            item.structure_bonus = nil
        end,
        onwork = function(item, attacker, target, tier)
            DamageGem("orangegem1", item, GEM_USES[tier])
        end,
        onupdate = FindUniqueBaseStructures
    }
})

-----------------------------------------------------------------------------------
---Orange2

local function UpdateSanityStat(inst, count, tier)
    if inst.volatile_gemology_data.um_gemologyorangegem2.old_dapperness then
        inst.components.equippable.dapperness = inst.volatile_gemology_data.um_gemologyorangegem2.old_dapperness + count * tier * TUNING.DSTU.ORANGEGEM2_OLD_DAPPERNESS_PER_TIER
    else
        inst.components.equippable.dapperness = count * tier * TUNING.DSTU.ORANGEGEM2_DAPPERNESS_PER_TIER 
    end
end

local function OnInventoryStateChanged(inst, owner, tier)
    local count = 0
    if owner.components.inventory then
        owner.components.inventory:ForEachItemSlot(function(item)
            count = count + 1
        end)
        UpdateSanityStat(inst, count, tier)
    end
end

local function HoardingHarvest(inst, ent, doer) -- they don't return the "loot" in this function, so we'll go with this solution instead of referencing the original (Scythe hoarding compatibility)
    if ent.components.pickable.picksound then
        doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
    end

    local success, loot = ent.components.pickable:Pick(TheWorld)
    if doer and doer:IsValid() and doer.components.inventory then
        if loot then
            for i, item in ipairs(loot) do
                doer.components.inventory:GiveItem(item)
            end
        end
        SpawnPrefab("sand_puff").Transform:SetPosition(ent.Transform:GetWorldPosition())
    else
        if loot then
            for i, item in ipairs(loot) do
                Launch(item, doer, 1.5)
            end
        end
    end
end


AddUMGemDef("orangegem2", {
    color = RGB(249, 203, 156),
    fns = {
        onapply = function(item, tier)
            item.volatile_gemology_data.um_gemologyorangegem2.old_dapperness = item.components.equippable.dapperness

            if item.HarvestPickable and tier ~= 1 then
                item.volatile_gemology_data.um_gemologyorangegem2.old_harvest_pickable_fn = item.HarvestPickable

                item.HarvestPickable = function(inst, ent, doer)
                    HoardingHarvest(inst, ent, doer)
                    if item.volatile_gemology_data.um_gemologyorangegem2.old_harvest_pickable_fn then
                        item.volatile_gemology_data.um_gemologyorangegem2.old_harvest_pickable_fn(inst, ent, doer)
                    end
                end
            end
        end,
        onattack = function(item, attacker, target, tier)
            DamageGem("orangegem2", item, GEM_USES[tier])
        end,
        onwork = function(item, attacker, target, tier)
            DamageGem("orangegem2", item, GEM_USES[tier])
        end,
        onremove = function(item, tier)
            if item.HarvestPickable then
                item.HarvestPickable = item.volatile_gemology_data.um_gemologyorangegem2.old_harvest_pickable_fn
            end
        end,
        onupdate = function(item, tier)
            local owner = item.components.inventoryitem:GetGrandOwner()

            if owner ~= nil then
                OnInventoryStateChanged(item, owner, tier)
            end
        end
    }
})

--Note (Atobá): Fixing up greengem2 and doing all the ones after that were done in 1 sitting over 6 and my sanity will never recover.

-----------------------------------------------------------------------------------
---Blue1

AddUMGemDef("bluegem1", {
    color = RGB(163, 194, 244),
    fns = {
        onapply = function(item, tier)
            if not item.components.insulator then
                item:AddComponent("insulator")
                item.volatile_gemology_data.um_gemologybluegem1.added_insulator = true
            else
                item.volatile_gemology_data.um_gemologybluegem1.old_type = item.components.insulator.type
                item.volatile_gemology_data.um_gemologybluegem1.old_insulation = item.components.insulator.insulation
            end
            item.components.insulator:SetSummer()
            item.components.insulator:SetInsulation(TUNING.DSTU.BLUEGEM1_INSULATION_PER_TIER * tier) -- A bit too easy...
        end,
        onremove = function(item, tier)
            if item.volatile_gemology_data.um_gemologybluegem1.added_insulator then
                item:RemoveComponent("insulator")
            else
                item.components.insulator.type = item.volatile_gemology_data.um_gemologybluegem1.old_type
                item.components.insulator.insulation = item.volatile_gemology_data.um_gemologybluegem1.old_insulation
            end
        end,
        onattack = function(item, attacker, target, tier)
            if target.components.freezable then
                target.components.freezable:AddColdness(TUNING.DSTU.BLUEGEM1_COLDNESS_PER_TIER * tier)
                target.components.freezable:SpawnShatterFX()
                if target.components.freezable:IsFrozen() and tier ~= 1 then
                    local ice_shield = SpawnPrefab("um_ice_shield")
                    ice_shield:Init(attacker, "swap_body", TUNING.DSTU.BLUEGEM1_ICE_SHIELD_TIER_BASE + (tier * TUNING.DSTU.BLUEGEM1_ICE_SHIELD_TIER_PER_TIER))
                end
                DamageGem("bluegem1", item, GEM_USES[tier])
            end
        end
    }
})

-----------------------------------------------------------------------------------
---Blue2

local SourceModifierList = require("util/sourcemodifierlist")
local DummyFueledClass = require("dummy_fueled")

local function PerishFill(inst, from_object)
    if from_object ~= nil
        and from_object.components.watersource ~= nil
        and from_object.components.watersource.override_fill_uses ~= nil then
        inst.components.perishable.perishremainingtime = (math.min(inst.components.perishable.perishtime, inst.components.perishable.perishremainingtime + from_object.components.watersource.override_fill_uses))
    else
        inst.components.perishable:SetPercent(1)
    end
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/emerge/small")
    return true
end

--special little gem.
AddUMGemDef("bluegem2", {
    color = RGB(163, 194, 244),
    fns = {
        onapply = function(item, tier)
            local pct = 1
            local maxval = 10
            local was_perishable

            local fillable = item.components.fillable

            if item.components.finiteuses then
                item.volatile_gemology_data.um_gemologybluegem2.old_finiteuses = item.components.finiteuses
                if not fillable then --just defualt to 100% for fillable. Don't perish instnatly when applying to a non-fillable item
                    pct = item.components.finiteuses:GetPercent()
                end
                maxval = item.components.finiteuses.total
                item:RemoveComponent("finiteuses")
            end
            if item.components.fueled then
                item.volatile_gemology_data.um_gemologybluegem2.old_fueled = item.components.fueled

                pct = item.components.fueled:GetPercent()
                maxval = item.components.fueled.maxfuel
                local old_fueltype = item.components.fueled.fueltype
                item:RemoveComponent("fueled")
                item.components.fueled = DummyFueledClass                        -- This should be repeated with finiteuses in the future.
                item.components.fueled.inst = item
                item.components.fueled.rate_modifiers = SourceModifierList(item) -- Still going to reference the original rate modifier list to prevent any crashes related to functions that may search through it from this class
                item.components.fueled.fueltype = old_fueltype
            end

            if item.components.perishable then
                was_perishable = true
                pct = item.components.perishable:GetPercent()
                item.volatile_gemology_data.um_gemologybluegem2.old_perishtime = item.components.perishable.perishtime
                maxval = item.components.perishable.perishremainingtime
                if tier ~= 1 then
                    maxval = maxval * ((1 + tier) * TUNING.DSTU.BLUEGEM2_PERISHABLE_EXTRA_TIME_MULT)
                end
            elseif not item.components.perishable then
                item:AddComponent("perishable")
            end

            item.components.perishable:SetPerishTime(maxval * tier * (was_perishable and TUNING.DSTU.BLUEGEM2_PERISHABLE_MULT or TUNING.DSTU.BLUEGEM2_NON_PERISHABLE_MULT))
            item.components.perishable:StartPerishing()
            item.components.perishable.onperishreplacement = "spoiled_food"
            item.components.perishable:SetPercent(pct)

            if item.persistent_gemology_data.um_gemologybluegem2.perish_time_left then
                item.components.perishable.perishremainingtime = item.persistent_gemology_data.um_gemologybluegem2.perish_time_left
            end


            -- inst.components.finiteuses = {}
            -- inst.components.finiteuses.Use = function() end
            item:AddTag("frozen")
            if fillable then -- Good ending for watering cans, I could have just made them remove the fillable component
                item.persistent_gemology_data.um_gemologybluegem2.old_onfill = item.components.fillable.overrideonfillfn
                item.components.fillable.overrideonfillfn = PerishFill
            end
        end,
        onremove = function(item, tier)
            local pct = item.components.perishable:GetPercent()
            local old_finite = item.volatile_gemology_data.um_gemologybluegem2.old_finiteuses
            local old_fueled = item.volatile_gemology_data.um_gemologybluegem2.old_fueled
            local old_perishtime = item.volatile_gemology_data.um_gemologybluegem2.old_perishtime
            local old_onfill = item.persistent_gemology_data.um_gemologybluegem2.old_onfill

            if old_finite then
                item.components.finiteuses = old_finite
                item.components.finiteuses:SetPercent(pct)
            end
            if old_fueled then
                item.components.fueled = old_fueled
                item.components.fueled:SetPercent(pct)
            end
            if old_perishtime then
                item.components.perishable.perishtime = old_perishtime
                item.components.perishable:SetPercent(pct)
            end
            if not old_perishtime then
                item:RemoveComponent("perishable")
            elseif item.components.perishable ~= nil then
                item.components.perishable.perishtime = old_perishtime
            end
            if old_onfill then
                item.components.fillable.overrideonfillfn = old_onfill
            end
        end,
        onupdate = function(item, tier)
            if not item.components.perishable then
                return
            end
            item.persistent_gemology_data.um_gemologybluegem2.perish_time_left = item.components.perishable.perishremainingtime
        end,
        canapply = function(item, tier)
            return item.components.fueled ~= nil or item.components.finiteuses ~= nil or item.components.perishable ~= nil
        end
    }
})

return { GEM_DEFS = GEM_DEFS, GEM_LOOKUP = GEM_LOOKUP }

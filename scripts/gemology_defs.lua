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
    sources = {
    prefab_name = {build = "string", bank = "string", anim = "string" }} --anim defaults to idle. Should these actually be the inv image instead, though?
    build = "string" --build name
    bank = "string" --bank name  --should these be the inv img instead??? probably.
    anim = "string" --anim name   -- defaults to "idle"
}

Additional note:

Every gemolyable item has a field called gemology_data, with holds any relevant data for gems. For example:
item.gemology_data[gem_name].foo = true

This is so we can save some gem-specific data so it can probably revert when removed.
]]


--[[
TEMP TEMP TEMP TEMP TEMP TEMP TEMP
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
TEMP TEMP TEMP TEMP TEMP TEMP TEMP
]]
local GEM_DEFS = {}

--for clients.
--gem enchants from gem_enchantable component are saved as a net_smallbytearray (8-bit unsigned ints, 31 max size)
--each gem gets assigned an int value here to be able to get a gem's name from the number on the client
local INVERTED_GEM_LOOKUP = {}
local GEM_LOOKUP = {}


setmetatable(GEM_DEFS, {
    __newindex = function(t, k, v)
        assert(#GEM_LOOKUP < 32, "Too many gems! Max is 31 gems")
        rawset(t, k, v)
    end
})


function AddGemDef(name, def)
    GEM_LOOKUP[#GEM_LOOKUP + 1] = name
    INVERTED_GEM_LOOKUP[name] = #GEM_LOOKUP

    GEM_DEFS[name] = def
end

local function AddUMGemDef(name, def) --helper function to just skip some re-used things we do.
    def.build = "um_gemologygems"
    def.bank = "um_gemologygems"
    def.anim = name

    AddGemDef("um_gemology" .. name, def)
end


function IsEnchantValid(gem)
    return GEM_DEFS[gem] ~= nil
end

------------------------------------------------------------------
--REDGEM1
local burn_damage = { 8, 16, 34 }
local burn_portion = { 0.05, 0.2 }

AddUMGemDef("redgem2", {
    color = RGB(233, 153, 153),
    fns = {
        onattack = function(inst, attacker, target, tier)
            if target.components.health then
                target.components.health:DoFireDamage(burn_damage[tier], attacker, true)
                SpawnPrefab("deer_fire_burst").Transform:SetPosition(target.Transform:GetWorldPosition())
                if tier ~= 1 and target.components.burnable and target.components.burnable:IsBurning() then
                    target.components.health:DoFireDamage(inst.components.weapon.damage * burn_portion[tier - 1], attacker, true)
                    target.components.burnable:ExtendBurning()
                end
            end
        end

    },
})

-------------------------------------------------------------------
--REDGEM2
local devour_tags = { "animal", "pig", "monster", "smallcreature" }
local devour_mults = { 1 / 10, 1 / 5 } -- it's what the document said.... I guess the damage isn't what we're really looking for, it's being able to eat part of the mob

AddUMGemDef("redgem1", {
    color = RGB(233, 153, 153),
    fns = {
        onattack = function(inst, attacker, target, tier)
            if tier ~= 1 and target:HasOneOfTags(devour_tags) and math.random() > 0.75 then -- arbitrarily said "a chance", I have no idea how common this should be
                local mult = devour_mults[tier - 1]
                attacker.components.combat:DoAttack(target, inst, nil, nil, mult, 0)        -- gotta use a bit more durability...
                mult = inst.components.weapon.damage * mult
                --owner.components.sanity:DoDelta(-mult)
                attacker.components.hunger:DoDelta(mult / 2)
            end

            if target.components.health ~= nil and target.components.health:IsDead() then -- Devour
                local recover = target.components.health.maxhealth * 0.01 * tier
                attacker.components.health:DoDelta(recover)
                attacker.components.sanity:DoDelta(recover)
            end
        end,
    },
})


------------------------------------------------------------------
---GREENGEM1
local action_list = { ACTIONS.CHOP, ACTIONS.MINE, ACTIONS.DIG, ACTIONS.HAMMER }
local melee_speeds = { 1.1, 1.2, 1.4 } -- Related to the tiering system

local function GetRandomTargetOfSameType(attacker, target)
    local x, y, z = target.Transform:GetWorldPosition()
    local tag_to_search = {}

    local ents = TheSim:FindEntities(x, y, z, 24)
    local ent_same_prefab = { target }
    for i, v in ipairs(ents) do
        if v.prefab == target.prefab and ((not v:HasTag("stump") and not v:HasTag("stump")) or (target:HasTag("stump") and v:HasTag("stump"))) then
            table.insert(ent_same_prefab, v)
        end
    end
    return ent_same_prefab[math.random(1, #ent_same_prefab)]
end

local function SendShadowClone(item, owner, target, tier)
    if target:IsValid() and (tier - 1) * 0.3 > math.random() and tier > 1 then
        if owner:GetDistanceSqToInst(target) > 50 ^ 2 and owner.components.sanity then --Long ways away, it's taking from your mind to send swilsons there
            if target.components.combat then
                owner.components.sanity:DoDelta(-5)                                    --If using for combat, be significantly more expensive
            end
        end

        local swilson = SpawnPrefab("swilson_labotomized")

        local newtarget = GetRandomTargetOfSameType(owner, target)
        local angle = math.random(0, 614) / 200
        local x, y, z = newtarget.Transform:GetWorldPosition()
        swilson.Transform:SetPosition(x + 1.5 * math.cos(angle), y, z + 1.5 * math.sin(angle))
        --swilson.green = 1 -- Tried making him green, it just looks goofy
        swilson.dupe_toolweapon = SpawnPrefab(item.prefab)
        swilson.components.inventory:Equip(swilson.dupe_toolweapon)
        swilson.dupe_toolweapon.components.inventoryitem:SetOnDroppedFn(swilson.dupe_toolweapon.Remove)

        if target.components.workable and not (target.prefab == "punchingbag" or target.prefab == "punchingbag_lunar" or target.prefab == "punchingbag_shadow") then
            swilson.work = 1
            swilson.LabWork(swilson, owner, newtarget)
        elseif target.components.health then
            swilson.attack = item.components.weapon.damage
            swilson.LabAttack(swilson, owner, newtarget)
        end
    end
end

AddUMGemDef("greengem1", {
    color = RGB(175, 245, 172),
    fns = {
        onapply = function(item, tier)
            item.um_neurotic_mod = melee_speeds[tier]

            local tool = item.components.tool

            if tool and tool.actions then
                item.gemology_data.um_gemologygreengem1.tool_actions = deepcopy(tool.actions)

                for i, v in ipairs(action_list) do
                    if tool.actions[v] then
                        tool.actions[v] = tool.actions[v] * (1 + tier / 4)
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
                tool.actions = item.gemology_data.um_gemologygreengem1.tool_actions
            end
        end
    }
})

-----------------------------------------------------------------------------------
---Green2

local valid_enchants = { "um_gemologygreengem1", --[["um_gemologyyellowgem1", "um_gemologyyellowgem2", "um_gemologypalegem1",]] "um_gemologyredgem1", "um_gemologyredgem2", --[["um_gemologypurplegem1", "um_gemologypurplegem2", "um_gemologyorangegem1", "um_gemologybluegem1"]] }

local function addRandomGemEffects(inst, item, tier)
    if inst.gemology_data.um_gemologygreengem2.gem_effects then
        for k, v in pairs(inst.gemology_data.um_gemologygreengem2.gem_effects) do
            if inst.components.gem_enchantable.enchants[k] then
                inst.components.gem_enchantable:RemoveEnchantment(k)
            end
        end
    end

    local tries = 10
    local enchant_nums = 0
    local max_enchants = 1

    while enchant_nums < max_enchants and tries > 0 do
        local enchant = valid_enchants[math.random(#valid_enchants)]
        if IsEnchantValid(enchant) then --don't add already existing other enchants.
            print("is valid")
            print("Has Enchant?", inst.components.gem_enchantable:HasEnchant(enchant), enchant)

            if not inst.components.gem_enchantable:HasEnchant(enchant) then
                print("adding echant "..enchant.." at tier "..tier)
                inst.components.gem_enchantable:AddEnchantment(enchant, tier)
                inst.gemology_data.um_gemologygreengem2.gem_effects[enchant] = tier
                enchant_nums = enchant_nums + 1
            end
        end

        tries = tries - 1
    end
end

AddUMGemDef("greengem2", {
    color = RGB(175, 245, 172),
    fns = {
        onapply = function(item, tier)
            if item.gemology_data.um_gemologygreengem2.gem_effects == nil then
                item.gemology_data.um_gemologygreengem2.gem_effects = {}

                addRandomGemEffects(item, item, tier)
            end
            item:WatchWorldState("startday", function(inst)
                addRandomGemEffects(inst, item, tier)
            end)
        end,
        onremove = function(item, tier)
            if item.gemology_data.um_gemologygreengem2.gem_effects then
                for k, v in pairs(item.gemology_data.um_gemologygreengem2.gem_effects) do
                    if item.components.gem_enchantable.enchants[k] then
                        item.components.gem_enchantable:RemoveEnchantment(k)
                    end
                end
            end
        end
    }
})

return { GEM_DEFS = GEM_DEFS, GEM_LOOKUP = GEM_LOOKUP, INVERTED_GEM_LOOKUP = INVERTED_GEM_LOOKUP }

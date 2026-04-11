local function set_enchant_client(self, enchantnum)
    self.inst.replica.minerologyable:SetEnchantClient(enchantnum)
end
local function set_chilling_client(self, chilling)
    self.inst.replica.minerologyable:SetChillingClient(chilling)
end

local Minerologyable = Class(function(self, inst)
        self.inst = inst

        self.enchant = nil
        self.enchantnum = 0 -- start it as 0.
    end,
    nil,
    {
        enchantnum = set_enchant_client,
        chilling = set_chilling_client,
    })

-- All Gemology, Geology, Minerology, Minecraft Enchantment effects are described below:
--[[

Neurotic Peridot -- 1
name = Green1
effect_apparent: +tier*10% tool efficiency, +tier*5% melee attack speed
effect_obscured: Creates copies of character to help with work and attack after N actions are performed, up to (tier-1)*2 copies
tier: Scales both apparent and obscured effects, no obscure effects on tier 1
target: tool, weapon

Chaotic Emerald -- 2
name = Green2
effect_apparent: Copies other Apparent and Obscured effects from gems, for now once, maybe in the future daily, 3 effects
effect_obscured: already hard to understand
tier: The copied effect references the chaotic emerald's tier
target: tool, weapon

Static Amber: -- 3
name = Yellow1
effect_apparent: 5+(5*tier) electrical damage, if electric weapon already, instead 15+(5*tier) electrical damage
effect_obscured: Enemy shares damage with neighbors, damage they receive is based on distance, up to 100+(tier-1)*25 damage
tier: Scales both apparnet and obscured effects, no obscure effects on tier 1
target: weapon

Hasty Topaz: -- 4
name = Yellow2
effect_apparent: 0.5+(0.5*tier) sanity/min, doubling under sun
effect_obscured: If player has speed boosts active, give an additional (tier*5) percent speed multiplier
tier: Scales both apparnet and obscured effects, no obscure effects on tier 1
target: weapon

Peerless Jade -- 5 -- [I think both effects are a bit less than apparent]
name = Clear1
effect_apparent: If under damage increasing buffs, increase them by 10,20,30% more
effect_obscured: If an item is not craftable, increase its damage by 16.7 and 34
tier: Scales both apparnet and obscured effects, no obscure effects on tier 1
target: weapon

Adamant Diamond -- 6 -- [Mundane, but should be a foundation, this one doesn't need to be interesting to attract attention because durability is generally useful, gotta have your standard unbreaking sort of deal]
name = Clear2
effect_apparent: durability buff tier(2x,3x,4x)
effect_obscured: noncraftable items have an additional 0%,30%,60% chance to ignore durability loss each time they are used, for fueled and perishable, this triggers every dt, for perishable
tier: Scales both apparnet and obscured effects, no obscure effects on tier 1
target: weapon/tool


]]

------------------
-- [[ Green 1
------------------
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

local function SendWilson(inst, attacker, target)
    if target:IsValid() then
        if attacker:GetDistanceSqToInst(target) > 50 ^ 2 and attacker.components.sanity then --Long ways away, it's taking from your mind to send swilsons there
            if target.components.combat then
                attacker.components.sanity:DoDelta(-5)                                       --If using for combat, be significantly more expensive
            end
        end
        local swilson = SpawnPrefab("swilson_labotomized")


        local newtarget = GetRandomTargetOfSameType(attacker, target)
        local angle = math.random(0, 614) / 200
        local x, y, z = newtarget.Transform:GetWorldPosition()
        swilson.Transform:SetPosition(x + 1.5 * math.cos(angle), y, z + 1.5 * math.sin(angle))
        --swilson.green = 1 -- Tried making him green, it just looks goofy
        swilson.dupe_toolweapon = SpawnPrefab(inst.prefab)
        swilson.components.inventory:Equip(swilson.dupe_toolweapon)
        swilson.dupe_toolweapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)

        if target.components.workable and not (target.prefab == "punchingbag" or target.prefab == "punchingbag_lunar" or target.prefab == "punchingbag_shadow") then
            swilson.work = 1
            swilson.LabWork(swilson, attacker, newtarget)
        elseif target.components.health then
            swilson.attack = inst.components.weapon.damage
            swilson.LabAttack(swilson, attacker, newtarget)
        end
    end
end

local function SendTheWilson(inst, attacker, target)
    if inst.tier ~= 1 then
        local chance = math.random()
        if inst.NeuroticWorkEffectChance > chance then
            SendWilson(inst, attacker, target)
        end
    end
end


local action_list = { ACTIONS.CHOP, ACTIONS.MINE, ACTIONS.DIG, ACTIONS.HAMMER }
local melee_speeds = { 1.1, 1.2, 1.4 } -- Related to the tiering system
local function MakeGreen1(self, tier) -- Run this on the tool to make them have the Green 2 Effects
    self.enchantnum = 1
    self.neurotic = true

    local inst = self.inst
    inst.tier = tier

    inst.um_neurotic_mod = melee_speeds[tier]
    local tool = inst.components.tool
    if tool and tool.actions then
        for i, v in ipairs(action_list) do
            if tool.actions[v] then
                tool.actions[v] = tool.actions[v] * (1 + tier / 4)
            end
        end
    end
    inst.NeuroticWorkEffectChance = (tier - 1) * 0.3
    inst.NeuroticWorkEffect = SendWilson
end
------------------
-- [[ Green 2
------------------

-- Chaotic Emerald has to be handled later in the file, since it has to reference everything



------------------
-- [[ Yellow 1
------------------

local sanities = { TUNING.DAPPERNESS_SMALL / 2, TUNING.DAPPERNESS_SMALL, TUNING.DAPPERNESS_SMALL * 2 }
local function MakeYellow1(self, tier)
    self.enchantnum = 3
    self.hasty = true

    local inst = self.inst
    inst.tier = tier
    if inst.components.equippable.dapperness then
        inst.components.equippable.dapperness = inst.components.equippable.dapperness + sanities[inst.tier]
    else
        inst.components.equippable.dapperness = sanities[inst.tier]
    end
end

------------------
-- [[ Yellow 2
------------------

local combat_health = { "_health", "_combat" }
local arc_player = { "player", "arcgrounded" }
local function FindEnemiesNearbyAndShockThem(inst, attacker, target, ShockAGAIN)
    local x, y, z = target.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4, combat_health, arc_player)
    for i, v in ipairs(ents) do
        if not v.components.health:IsDead() then
            local dist = math.sqrt(target:GetDistanceSqToInst(v))
            v:DoTaskInTime(dist / 5, function(v)
                if v.components.health and not v.components.health:IsDead() and not v:HasTag("arcgrounded") then -- we check these again because they could have already died or been shocked once
                    local mult = 2 - dist
                    if inst.tier == 2 then
                        mult = math.clamp(mult, 0.1, 1.25)
                    elseif inst.tier == 3 then
                        mult = math.clamp(mult, 0.25, 1.5)
                    end
                    local damage = inst.components.weapon.damage * mult
                    v.components.combat:GetAttacked(attacker, damage, nil, "electric")
                    v:AddTag("arcgrounded")
                    ShockAGAIN(inst, attacker, v)
                    SpawnPrefab("electricchargedfx").Transform:SetPosition(v.Transform:GetWorldPosition())
                    v:DoTaskInTime(3, function(v) v:RemoveTag("arcgrounded") end)
                end
            end)
        end
    end
end

local static_mods = { 10, 15, 20 }
local function ElectricAttack(inst, attacker, target)
    SpawnElectricHitSparks(attacker, target, true)
    if inst.tier ~= 1 then
        if target:IsValid() then
            FindEnemiesNearbyAndShockThem(inst, attacker, target, ElectricAttack)
        end
        -- Dont allow arcing back upon oneself
        target:AddTag("arcgrounded")
        target:DoTaskInTime(3, function(target) target:RemoveTag("arcgrounded") end)
    end

    if target.components.combat then
        target.components.combat:GetAttacked(attacker, static_mods[inst.tier], nil, "electric")
    end

    if inst.components.weapon.stimuli ~= "electric" then
        inst.components.weapon:SetElectric(1, 2.5)
    end
end

local function MakeYellow2(self, tier) -- um_static_mod is referenced in a postinit to the combat component in init_gemology, setting the value here will talk to the function there, and make it increase damage if the player has a modifier already
    self.enchantnum = 4
    self.static = true

    local inst = self.inst
    inst.tier = tier

    if inst.prefab == "hambat" then
        inst.new_max_damage = TUNING.HAMBAT_DAMAGE + static_mods[tier]
    end
end

------------------
-- [[ Clear 1
------------------

local cant_be_crafted = {
    "tentaclespike",
    "rabbitkingspear",
    "oar_monkey",
    "shieldofterror",
    "cutless",
    "bullkelp_root",
    "malbatross_beak",

    -- UM-specific items
    "rimeweed_whip",

    -- Island Adventures, add others later, atoba here's your chance.
    "peg_leg",
    --"trident", -- What does IA call the SW trident
    "harpoon",
}

local function UniqueBonusDamage(inst, attacker, target)
    if inst.tier ~= 1 then
        local stimuli = inst.components.weapon.stimuli and inst.components.weapon.stimuli or nil
        target.components.combat:GetAttacked(attacker, 34 / 2 * (inst.tier - 1), nil, stimuli)
    end
end

local function MakeClear1(self, tier) -- um_peerless_mod is referenced in a postinit to the combat component in init_gemology, setting the value here will talk to the function there, and make it increase damage if the player has a modifier already
    self.enchantnum = 5

    local inst = self.inst
    inst.tier = tier
    inst.um_peerless_mod = tier
    if tier ~= 1 and inst.components.weapon then
        for i, v in ipairs(cant_be_crafted) do -- the noncraftable item list is a bit short....
            if v == inst.prefab then
                self.peerless = true          -- only actually give it the peerless effect if it can't be crafted
            end
        end
    end
end

------------------
-- [[ Clear 2
------------------

-- I'm counting learned recipes as prototyped, so no thulecite bugnet in here.
local cant_be_proto = {
    "ruins_bat",
    "tentaclespike",
    "glasscutter",
    "rabbitkingspear",
    "oar_monkey",
    "shieldofterror",
    "cutless",
    "bullkelp_root",

    "moonglassaxe",
    "multitool_axe_pickaxe",
    "malbatross_beak",
    "yotd_oar",

    "voidcloth_scythe",
    "shadow_battleaxe",
    "sword_lunarplant",
    "staff_lunarplant",
    "voidcloth_boomerang",

    "pickaxe_lunarplant",
    "shovel_lunarplant",

    -- UM-specific items
    "rimeweed_whip",

    -- Island Adventures, add others later, atoba here's your chance.
    "spear_obsidian",
    "peg_leg",
    --"trident", -- What does IA call the SW trident
    "obsidianmachete",
    "obsidianaxe",
    "harpoon",
}

local function MakeClear2(self, tier) -- Scale up the durability, items that cannot be prototyped or learned have additional chances to not break
    local inst = self.inst
    if not self.adamant then
        if inst.components.finiteuses then
            local pct = inst.components.finiteuses:GetPercent()
            local total = inst.components.finiteuses.total
            inst.components.finiteuses:SetMaxUses(total * (1 + tier))
            inst.components.finiteuses:SetPercent(pct)
        end
        if inst.components.fueled then -- Future, there are other items that fall into this category that cannot be learned or prototyped
            local pct = inst.components.fueled:GetPercent()
            local total = inst.components.fueled.maxfuel
            inst.components.fueled:SetPercent(pct * total * (1 + tier))
        end
        if inst.components.perishable then -- it *might* work on the hambat, doesn't seem certain though
            local pct = inst.components.perishable:GetPercent()
            inst.components.perishable.perishtime = inst.components.perishable.perishtime * (1 + tier)
            inst.components.perishable:SetPercent(pct)
        end
    end

    self.adamant = true
    self.enchantnum = 6

    local inst = self.inst
    if inst.components.finiteuses then
        if tier ~= 1 then
            for i, v in ipairs(cant_be_proto) do
                if v == inst.prefab then
                    local _Use = inst.components.finiteuses.Use
                    inst.components.finiteuses.Use = function(self, num) -- Modify only this item's version of finiteuses
                        local chance = math.random()
                        if (chance > 0.7 and tier == 2) or (chance > 0.4 and tier == 3) then
                            _Use(self, num)
                        end
                    end
                end
            end
        end
    end
end -- Todo, make these scale back if we go for chaotic emerald swapping daily, the way you would do it is by grabbing the old maximum values and saving them, for when chaotic emerald to switch, it goes back to the old version, this would require saving/loading the variables as well

------------------
-- [[ Red 1
------------------

local devour_tags = { "animal", "pig", "monster", "smallcreature" }
local devour_mults = { 1 / 10, 1 / 5 }                                                   -- it's what the document said.... I guess the damage isn't what we're really looking for, it's being able to eat part of the mob
local function Devour(inst, owner, target)
    if inst.tier ~= 1 and target:HasOneOfTags(devour_tags) and math.random() > 0.75 then -- arbitrarily said "a chance", I have no idea how common this should be
        local mult = devour_mults[inst.tier - 1]
        owner.components.combat:DoAttack(target, inst, nil, nil, mult, 0)                -- gotta use a bit more durability...
        mult = inst.components.weapon.damage * mult
        --owner.components.sanity:DoDelta(-mult)
        owner.components.hunger:DoDelta(mult / 2)
    end

    if target.components.health ~= nil and target.components.health:IsDead() then -- Devour
        local recover = target.components.health.maxhealth * 0.01 * inst.tier
        owner.components.health:DoDelta(recover)
        owner.components.sanity:DoDelta(recover)
    end
end


local function MakeRed1(self, tier)
    self.enchantnum = 7
    self.voracious = true

    local inst = self.inst
    inst.tier = tier
end

------------------
-- [[ Red 2
------------------

local burn_damage = { 8, 16, 34 }
local burn_portion = { 0.05, 0.2 }
local function Burny(inst, attacker, target)
    if target.components.health then
        target.components.health:DoFireDamage(burn_damage[inst.tier], attacker, true)
    end
    SpawnPrefab("deer_fire_burst").Transform:SetPosition(target.Transform:GetWorldPosition())
    if inst.tier ~= 1 and target.components.burnable and target.components.burnable:IsBurning() then
        target.components.health:DoFireDamage(inst.components.weapon.damage * burn_portion[inst.tier - 1], attacker, true)
        target.components.burnable:ExtendBurning()
    end
end

local function MakeRed2(self, tier)
    self.enchantnum = 8
    self.passionate = true

    local inst = self.inst
    inst.tier = tier
    -- inst:AddComponent("insulator")
    -- inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL*tier) -- If we say it should have winter insulation, just uncomment
end

------------------
-- [[ Purple 1
------------------

local function HambatUpdateDamage(inst)
    if inst.components.perishable and inst.components.weapon then
        local dmg = TUNING.HAMBAT_DAMAGE * inst.components.perishable:GetPercent()
        dmg = Remap(dmg, 0, inst.new_max_damage and inst.new_max_damage or TUNING.HAMBAT_DAMAGE, TUNING.HAMBAT_MIN_DAMAGE_MODIFIER / 2 * TUNING.HAMBAT_DAMAGE,
            TUNING.HAMBAT_DAMAGE)
        if dmg < 50 then
            dmg = dmg + dmg * inst.tier * 0.25
        end
        inst.components.weapon:SetDamage(dmg)
    end
end

local function HaveFury(inst, attacker, target) -- Surprised "Furious" is not red, I guess passionate and voracious is sorta red too? I would have personally made this purple one voracious and the other red furious.
    if inst.tier ~= 1 then
        local damage = inst.components.weapon.damage
        if damage < 50 and inst.prefab ~= "hambat" then
            damage = damage * inst.tier * 0.25
            local stimuli = inst.components.weapon.stimuli and inst.components.weapon.stimuli or nil
            target.components.combat:GetAttacked(attacker, damage, nil, stimuli)
        end
    end
end

local function MakePurple1(self, tier)
    self.enchantnum = 9
    self.furious = true

    local inst = self.inst
    inst.tier = tier
    if inst.prefab == "hambat" and tier ~= 1 then -- hambat needs an exception
        inst.UpdateDamage = HambatUpdateDamage
    end
end

------------------
-- [[ Purple 2
------------------

local function GrabNearItem(inst, owner)
    local item = FindEntity(owner, 8, function(ent) return ent.components.inventoryitem and ent ~= inst end)
    if item then
        owner.components.inventory:GiveItem(item)
    end
end

local function OnDropedIfDeadGiveBack(inst) -- This is the only one that has an "ondropped" effect
    local x, y, z = inst.Transform:GetWorldPosition()
    local owner = FindEntity(inst, 10, function(ent) return ent:HasTag("player") and ent.components.health and ent.components.health:IsDead() end)
    if owner and owner.components.health:IsDead() then -- If this happens, the owner has just died.
        if inst.tier ~= 1 then
            for i = 1, inst.tier do
                GrabNearItem(inst, owner)
            end
        end
        owner.components.inventory:GiveItem(inst) -- Give the ghost back the item
    end

    local gemology = inst.components.minerologyable
    if gemology and gemology._nongemologyondropfn then
        gemology._nongemologyondropfn(inst)
    end
end

local function MakePurple2(self, tier)
    self.enchantnum = 10
    self.arcane = true

    local inst = self.inst
    inst.tier = tier
    if inst.components.inventoryitem.ondropfn and not inst.components.minerologyable._nongemologyondropfn then
        inst.components.minerologyable._nongemologyondropfn = inst.components.inventoryitem.ondropfn
    end
    inst.components.inventoryitem:SetOnDroppedFn(OnDropedIfDeadGiveBack) -- This is the only one that has a special drop condition
end

------------------
-- [[ Orange 1, Comfy Zircon
------------------

local function FindUniqueBaseStructures(inst)
    if inst.entity:IsAwake() then
        local self = inst.components.minerologyable
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 48, { "structure" })
        local uniquestructures = {}
        for i, v in ipairs(ents) do
            if not table.contains(uniquestructures, v.prefab) then
                table.insert(uniquestructures, v.prefab)
            end
        end
        self.structurebonus = math.clamp(#uniquestructures, 0, 30) * inst.tier / 150
    end
end

local function BaseSitterAttack(inst, attacker, target)
    if inst.tier ~= 1 then
        local damage = inst.components.weapon.damage
        local self = inst.components.minerologyable
        local fx = SpawnPrefab("sand_puff")
        fx.Transform:SetPosition(target.Transform:GetWorldPosition())
        fx.Transform:SetScale(0.05 + 2 * self.structurebonus, 0.05 + 2 * self.structurebonus, 0.05 + 2 * self.structurebonus)
        target.components.combat:GetAttacked(attacker, damage * self.structurebonus)
    end
end

local function MakeOrange1(self, tier)
    self.enchantnum = 11
    self.comfy = true

    local inst = self.inst
    inst.tier = tier
    self.structurebonus = 0
    inst:DoPeriodicTask(15, FindUniqueBaseStructures)
end

------------------
-- [[ Orange 2, Hoarding Citrine
------------------

local function UpdateSanityStat(inst, count)
    if inst.components.minerologyable._dapperness then
        inst.components.equippable.dapperness = inst.components.minerologyable._dapperness + count * inst.tier * TUNING.DAPPERNESS_SMALL / 5
    else
        inst.components.equippable.dapperness = count * inst.tier * TUNING.DAPPERNESS_SMALL / 10
    end
end

local function OnInventoryStateChanged_Internal(inst, owner)
    local count = 0
    owner.components.inventory:ForEachItemSlot(function(item)
        count = count + 1
    end)
    UpdateSanityStat(inst, count)
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

local function MakeOrange2(self, tier)
    self.enchantnum = 12
    self.hoarding = true

    local inst = self.inst
    inst.tier = tier

    inst.OnInventoryStateChangedGemology = function(owner)
        OnInventoryStateChanged_Internal(inst, owner)
    end

    if inst.components.equippable.dapperness and not inst.components.minerologyable._dapperness then
        inst.components.minerologyable._dapperness = inst.components.equippable.dapperness
    end

    if inst.tier ~= 1 and not inst.components.minerologyable.telling_inventory then
        local _onequip = inst.components.equippable.onequipfn
        local _onunequip = inst.components.equippable.onunequipfn

        inst.components.minerologyable.telling_inventory = true
        local function OnEquip(inst, owner)
            _onequip(inst, owner)
            inst:ListenForEvent("itemget", inst.OnInventoryStateChangedGemology, owner)
            inst:ListenForEvent("itemlose", inst.OnInventoryStateChangedGemology, owner)
            inst:ListenForEvent("stacksizechange", inst.OnInventoryStateChangedGemology, owner)

            inst.OnInventoryStateChangedGemology(owner)
        end
        local function OnUnequip(inst, owner)
            _onunequip(inst, owner)
            inst:RemoveEventCallback("itemget", inst.OnInventoryStateChangedGemology, owner)
            inst:RemoveEventCallback("itemlose", inst.OnInventoryStateChangedGemology, owner)
            inst:RemoveEventCallback("stacksizechange", inst.OnInventoryStateChangedGemology, owner)
        end
        inst.components.equippable:SetOnEquip(OnEquip) -- only time this is used in gemology, if this is used again, we'll need a function at the bottom to add it with compatibility between each gem
        inst.components.equippable:SetOnUnequip(OnUnequip)
    end
    if inst.HarvestPickable and inst.tier ~= 1 then
        inst._HarvestPickable = inst.HarvestPickable -- For chaotic reversion
        inst.HarvestPickable = HoardingHarvest
    end
end
------------------
-- [[ Blue 1, Arctic Aquamarine
------------------
local function Freezy(inst, attacker, target)
    if target.components.freezable then
        target.components.freezable:AddColdness(0.15 * inst.tier)
        target.components.freezable:SpawnShatterFX()
        if target.sg and target.sg:HasStateTag("frozen") and math.random() < (inst.tier - 1) * 0.25 and inst.tier ~= 1 then
            target:DoTaskInTime(0, function(inst) -- immediate refreeze
                target.components.freezable:AddColdness(999)
            end)
        end
    end
end

local function MakeBlue1(self, tier)
    self.enchantnum = 13
    self.arctic = true

    local inst = self.inst
    inst.tier = tier
    if not inst.components.insulator then
        inst:AddComponent("insulator")
    end
    inst.components.insulator:SetSummer()
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL * tier) -- A bit too easy...
end


------------------
-- [[ Blue 2, Chilled Sapphire
------------------

local SourceModifierList = require("util/sourcemodifierlist")
local DummyFn = function() end
-- May move these dummy functions outside of the component and somewherer else to improve readability, if anyone wants to do that they can, but it's not necessary.

-- Set up the dummy fueled class
local DummyFueledClass = {}
-- Keep a the variables in the class definition incase they are referenced by another script. They shouldn't do anything, but they're *also* not nil
DummyFueledClass.consuming = false

DummyFueledClass.maxfuel = 0
DummyFueledClass.currentfuel = 0
DummyFueledClass.rate = 1

DummyFueledClass.no_sewing = nil --V2C: HACK COLON RIGHT PARANTHESIS, I mean, what choice do I have if I don't want to break mods -_ -
DummyFueledClass.accepting = false
DummyFueledClass.secondaryfueltype = nil
DummyFueledClass.sections = 1
DummyFueledClass.sectionfn = nil
DummyFueledClass.period = 1
DummyFueledClass.bonusmult = 1
DummyFueledClass.depleted = nil

-- Dummy functions, most should just be fixed to not return nil. There may be a way to reference the original class and hookup all the original functions to nil, but I'm not sure how you could loop through all the variables/functions in a class.

DummyFueledClass.OnRemoveFromEntity = DummyFn
DummyFueledClass.MakeEmpty = DummyFn
DummyFueledClass.OnSave = DummyFn
DummyFueledClass.OnLoad = DummyFn
DummyFueledClass.SetSectionCallback = DummyFn
DummyFueledClass.SetDepletedFn = DummyFn
DummyFueledClass.IsEmpty = function() return false end -- hook this up to an actual return, some items need to know if it's empty, there's no empty state for a chilled item, so it's always full
DummyFueledClass.IsFull = function() return true end   -- same logic, hook up, always true
DummyFueledClass.SetSections = DummyFn
DummyFueledClass.SetMultiplierFn = DummyFn
DummyFueledClass.CanAcceptFuelItem = function() return false end -- No, any chilled item is no longer refuelable, with the exception of the watering can which is slightly different since it uses fillable class
DummyFueledClass.SetMultiplierFn = DummyFn
DummyFueledClass.GetCurrentSection = function() return 1 end     -- should always appear as if it's full
DummyFueledClass.ChangeSection = DummyFn
DummyFueledClass.SetCanTakeFuelItemFn = DummyFn
DummyFueledClass.SetTakeFuelItemFn = DummyFn
DummyFueledClass.SetTakeFuelFn = DummyFn
DummyFueledClass.TakeFuelItem = DummyFn
DummyFueledClass.SetUpdateFn = DummyFn
DummyFueledClass.GetDebugString = function() return "This entity's fueled component is now a dummy class to prevent nil crashes from referencing. It does not provide any function anymore. Trying to adjust durability of perishable through this class will not work." end
DummyFueledClass.AddThreshold = DummyFn
DummyFueledClass.GetSectionPercent = function() return 1 end
DummyFueledClass.GetPercent = DummyFn -- Do not return a percentage for the indicator
DummyFueledClass.SetPercent = DummyFn
DummyFueledClass.SetFirstPeriod = DummyFn
DummyFueledClass.StartConsuming = DummyFn
DummyFueledClass.OnWallUpdate = DummyFn
DummyFueledClass.InitializeFuelLevel = DummyFn
DummyFueledClass.DoDelta = DummyFn
DummyFueledClass.OnUpdate = DummyFn
DummyFueledClass.StopConsuming = DummyFn
DummyFueledClass.LongUpdate = DummyFn

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

local function ConvertToPerishable(inst)
    local pct = 1
    local maxval = 10

    local was_perishable
    if inst.components.finiteuses then
        pct = inst.components.finiteuses:GetPercent()
        maxval = inst.components.finiteuses.total
        inst:RemoveComponent("finiteuses")
    end
    if inst.components.fueled then
        pct = inst.components.fueled:GetPercent()
        maxval = inst.components.fueled.maxfuel
        local old_fueltype = inst.components.fueled.fueltype
        inst:RemoveComponent("fueled")
        inst.components.fueled = DummyFueledClass                        -- This should be repeated with finiteuses in the future.
        inst.components.fueled.inst = inst
        inst.components.fueled.rate_modifiers = SourceModifierList(inst) -- Still going to reference the original rate modifier list to prevent any crashes related to functions that may search through it from this class
        inst.components.fueled.fueltype = old_fueltype
    end
    if inst.components.perishable then
        was_perishable = true
        pct = inst.components.perishable:GetPercent()
        maxval = inst.components.perishable.perishremainingtime
        if inst.tier ~= 1 then
            maxval = maxval * ((1 + inst.tier) * 0.5)
        end
    elseif not inst.components.perishable then
        inst:AddComponent("perishable")
    end
    inst.components.perishable:SetPerishTime(maxval * inst.tier * (was_perishable and 1 or 3))

    

    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"
    inst.components.perishable:SetPercent(pct)

    -- inst.components.finiteuses = {}
    -- inst.components.finiteuses.Use = function() end
    inst:AddTag("frozen")
    if inst.components.fillable then -- Good ending for watering cans, I could have just made them remove the fillable component
        inst.components.fillable.overrideonfillfn = PerishFill
    end
end

local function MakeBlue2(self, tier)
    self.enchantnum = 14


    local inst = self.inst
    inst.tier = tier

    if not self.chilling then
        ConvertToPerishable(inst)
    end
    self.chilling = true
end

-- Perform the onhit definition in this way to have compatibility with others as well as ourself with chaotic emerald
local function GemologyCompatibleOnHit(inst, attacker, target)
    local self = inst.components.minerologyable
    if self._nongemology_onhit then
        self._nongemology_onhit(inst, attacker, target)
    end
    if self.neurotic then -- 1
        --TheNet:Announce("neurotic")
        SendTheWilson(inst, attacker, target)
    end
    -- 2 is chaotic, which does not have any onhit effects on its own, rather, it will adopt several of these modifiers in its definition
    -- 3 is hasty, which does not have "onhit" effects
    if self.static then -- 4
        --TheNet:Announce("static")
        ElectricAttack(inst, attacker, target)
    end
    if self.peerless then -- 5
        --TheNet:Announce("peerless")
        UniqueBonusDamage(inst, attacker, target)
    end
    -- 6 is adamant, which does not have "onhit" effects
    if self.voracious then -- 7
        --TheNet:Announce("voracious")
        Devour(inst, attacker, target)
    end
    if self.passionate then -- 8
        --TheNet:Announce("passionate")
        Burny(inst, attacker, target)
    end
    if self.furious then -- 9
        --TheNet:Announce("furious")
        HaveFury(inst, attacker, target)
    end
    -- 10 is arcane, which has no effect or combat-specific perk
    if self.comfy then -- 11
        --TheNet:Announce("comfy")
        BaseSitterAttack(inst, attacker, target)
    end
    if self.arctic then -- 13
        --TheNet:Announce("arctic")
        Freezy(inst, attacker, target)
    end
end

local function MakeNewOnHits(self, tier)
    local inst = self.inst

    if inst.components.weapon then
        if not self._nongemology_onhit and inst.components.weapon.onattack then -- Do Not Redefine
            self._nongemology_onhit = inst.components.weapon.onattack
        end

        inst.components.weapon:SetOnAttack(GemologyCompatibleOnHit)
    end
end

local function ResetChaos(inst)
    local self = inst.components.minerologyable
    local tier = inst.tier

    -- reset all flags
    -- green
    self.neurotic = nil
    -- yellow
    self.hasty = nil
    self.static = nil
    -- pale
    self.peerless = nil
    self.adamant = nil
    -- red
    self.voracious = nil
    self.passionate = nil
    -- purples
    self.furious = nil
    self.arcane = nil
    -- oranges
    self.comfy = nil
    self.hoarding = nil
    -- blues
    self.arctic = nil
    self.chilling = nil

    self.MakeChaos(self, tier)
end

local function MakeChaos(self, tier)
    self.making_chaos = true -- to prevent repeated definitions of the old onhit
    local inst = self.inst
    inst.tier = tier
    local enchants = { "um_gemologygreengem1", "um_gemologyyellowgem1", "um_gemologyyellowgem2", "um_gemologypalegem1", "um_gemologyredgem1", "um_gemologyredgem2", "um_gemologypurplegem1", "um_gemologypurplegem2", "um_gemologyorangegem1", "um_gemologybluegem1" }
    for i = 1, 3 do
        local indx = math.random(1, #enchants)
        self:SetEnchant(enchants[indx], tier)
        table.remove(enchants, indx)
    end
    self.chaotic = true
    self.MakeChaos = MakeChaos
    self.enchantnum = 2

    inst:WatchWorldState("startcaveday", ResetChaos)

    self._nongemology_onhit = nil
    MakeNewOnHits(self, tier)
end

function Minerologyable:SetEnchant(enchant, tier)
    self.enchant = enchant
    self.tier = tier

    if enchant == "um_gemologygreengem1" then -- We'll condense down the if-tower later into a for loop or something, whatever the better organized think is best.
        MakeGreen1(self, tier)
    end
    if enchant == "um_gemologygreengem2" then
        MakeChaos(self, tier)
    end
    if enchant == "um_gemologyyellowgem1" then
        MakeYellow1(self, tier)
    end
    if enchant == "um_gemologyyellowgem2" then
        MakeYellow2(self, tier)
    end
    if enchant == "um_gemologypalegem1" then
        MakeClear1(self, tier)
    end
    if enchant == "um_gemologypalegem2" then
        MakeClear2(self, tier)
    end
    if enchant == "um_gemologyredgem1" then
        MakeRed1(self, tier)
    end
    if enchant == "um_gemologyredgem2" then
        MakeRed2(self, tier)
    end
    if enchant == "um_gemologypurplegem1" then
        MakePurple1(self, tier)
    end
    if enchant == "um_gemologypurplegem2" then
        MakePurple2(self, tier)
    end
    if enchant == "um_gemologyorangegem1" then
        MakeOrange1(self, tier)
    end
    if enchant == "um_gemologyorangegem2" then
        MakeOrange2(self, tier)
    end
    if enchant == "um_gemologybluegem1" then
        MakeBlue1(self, tier)
    end
    if enchant == "um_gemologybluegem2" then
        MakeBlue2(self, tier)
    end
    if not self.making_chaos then
        MakeNewOnHits(self, tier)
    end
end

function Minerologyable:OnSave()
    local data = {}
    data.enchant = self.enchant
    data.tier = self.tier

    return data
end

function Minerologyable:OnLoad(data)
    self:SetEnchant(data.enchant, data.tier)
end

return Minerologyable

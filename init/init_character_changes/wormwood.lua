local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function propegation(inst)
    if inst.components.burnable and not inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
        MakeSmallPropagator(inst)
    else
        inst:DoTaskInTime(5, propegation)
    end
end

local function DefaultIgniteFn(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:StartWildfire()
    end

    --propegation(inst)
end

local WATCH_WORLD_PLANTS_DIST_SQ = 20 * 20
local SANITY_DRAIN_TIME = 5

local function DoKillPlantPenalty(inst, penalty, overtime)
    if overtime then
        table.insert(inst.plantpenalties, { amt = -penalty / SANITY_DRAIN_TIME, t = SANITY_DRAIN_TIME })
    else
        while #inst.plantbonuses > 0 do
            table.remove(inst.plantbonuses)
        end
        inst.components.sanity:DoDelta(-penalty)
        inst.components.talker:Say(GetString(inst, "ANNOUNCE_KILLEDPLANT"))
    end
end

local function WatchWorldPlants2(inst)
    if inst._onplantkilled2 == nil then
        inst._onplantkilled2 = function(src, data)
            if data == nil then
                --shouldn't happen
            elseif data.doer == inst then
                DoKillPlantPenalty(inst, data.workaction ~= nil and data.workaction == ACTIONS.DIG and TUNING.SANITY_TINY or 0)
            end
        end
        inst:ListenForEvent("plantkilled", inst._onplantkilled2, TheWorld)
    end
end

local function StopWatchingWorldPlants2(inst)
    if inst._onplantkilled2 ~= nil then
        inst:RemoveEventCallback("plantkilled", inst._onplantkilled2, TheWorld)
        inst._onplantkilled2 = nil
    end
end

local function OnRespawnedFromGhost2(inst)
    WatchWorldPlants2(inst)

    --MakeMediumBurnableCharacter(inst, "torso")
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.burnable:Extinguish()
            MakeSmallPropagator(inst)
        end
    end)
end

local function OnBecameGhost2(inst)
    StopWatchingWorldPlants2(inst)
end

local function OnBurnt(inst)
    --Overriding the OnBurnt function to prevent propegator from sometimes removing, hopefully.
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() then
            inst.components.burnable:Extinguish()
            MakeSmallPropagator(inst)
        end
    end)
end

local function OnMoistureDelta(inst)
    --Overriding the OnBurnt function to prevent propegator from sometimes removing, hopefully.
    inst:DoTaskInTime(0, function(inst)
        if inst.components.health and not inst.components.health:IsDead() and inst.components.moisture and
            inst.components.moisture:GetMoisturePercent() >= 0.4 then
            if inst.components.propegator ~= nil then
                inst.components.propagator.acceptsheat = false
            end
        elseif inst.components.health and not inst.components.health:IsDead() then
            if inst.components.propegator ~= nil then
                inst.components.propagator.acceptsheat = true
            end
        end
    end)
end

env.AddPrefabPostInit("wormwood", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onlevelchangedfn = inst.components.bloomness.onlevelchangedfn

    local function UpdateBloomStage(inst, stage)
        local ret = _onlevelchangedfn(inst, stage)
        inst:RemoveTag("beebeacon")
        inst.beebeacon = nil
        return ret
    end

    inst.UpdateBloomStage = UpdateBloomStage
    inst.components.bloomness.onlevelchangedfn = UpdateBloomStage
    inst:RemoveTag("beebeacon")
    inst.beebeacon = nil

    --[[inst:ListenForEvent("healthdelta", function(inst, data)
        if data.cause == "fire" then
            local maxhealth = inst.components.health.maxhealth
            inst.components.health:DeltaPenalty(math.abs(data.amount / maxhealth / 2))
        end
    end)]]


    inst:AddTag("hayfever_immune")
end)

if TUNING.DSTU.WORMWOOD_CONFIG_PLANTS then
    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        WatchWorldPlants2(inst)
        inst:ListenForEvent("ms_becameghost", OnBecameGhost2)
    end)
end

if TUNING.DSTU.WORMWOOD_CONFIG_FIRE then
    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end

        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnBurntFn(OnBurnt)
        inst:ListenForEvent("moisturedelta", OnMoistureDelta)
        inst:ListenForEvent("ms_respawnedfromghost", OnRespawnedFromGhost2)
    end)
end

local function TrapsAOE(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y, z, TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE, { "trap" })) do
        if v ~= nil and v.prefab == "trap_bramble" and v.components.mine ~= nil and v.components.mine.issprung then
            v.components.mine:Reset()
        end
    end
end

local function UpdateBloomStageUM(inst, stage) --Checks the bloom stage in a friendly way, no overriding
    --The setters will all check for dirty values, since refreshing bloom
    --stage can potentially get triggered quite often with state changes.
    inst:DoTaskInTime(0, function(inst) --Checking for blooming is hard, so we'll just check for pollentask instead XD
        if inst.pollentask --[[and inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wormwood_bugs")]] then
            inst.traptask = inst:DoPeriodicTask(.5, TrapsAOE)
        elseif inst.traptask then
            inst.traptask:Cancel()
            inst.traptask = nil
        end
    end)
end

if TUNING.DSTU.WORMWOOD_CONFIG_TRAPS then
    env.AddPrefabPostInit("bramblefx_trap", function(inst)
        inst.canhitplayers = false
    end)

    env.AddPrefabPostInit("bramblefx_armor", function(inst)
        inst.canhitplayers = false
    end)

    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then
            return
        end
        -- AXE this was commented when I got here.
        --[[local _UpdateBloomStage = inst.components.bloomness.onlevelchangedfn
        local function NewUpdateBloomStage(inst, stage)
            _UpdateBloomStage(inst, stage)
            UpdateBloomStageUM(inst, stage)
        end
        inst.components.bloomness.onlevelchangedfn = NewUpdateBloomStage]]
    end)
end


if env.GetModConfigData("wormwood_photosynthesis") then
    --------------------------------------------------------------------------------------------------------------------------------
    -- [ Final Built Skilltree ] ---------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------------------

    env.modimport("init/init_character_changes/skilltree_wormwood") -- Import New Wormwood Tree

    local function VetCurseCancelHealing(inst, data)
        local debuffable = inst.components.debuffable
        if inst:HasTag("vetcurse") and debuffable then
            local debuffs = debuffable.debuffs
            for i, v in pairs(debuffs) do
                if string.sub(i, 1, 24) == "healthregenbuff_vetcurse" or i == "confighealbuff" or i == "compostheal_buff" or i == "tillweedsalve_buff" then
                    debuffable:RemoveDebuff(i)
                end
            end
        end
    end

    local function ToggleUniqueVetCurse(inst, toggle)
        if toggle then
            inst:ListenForEvent("attacked", VetCurseCancelHealing)
            inst:ListenForEvent("firedamage", VetCurseCancelHealing)
        else
            inst:RemoveEventCallback("attacked", VetCurseCancelHealing)
            inst:RemoveEventCallback("firedamage", VetCurseCancelHealing)
        end
    end

    env.AddPrefabPostInit("wormwood", function(inst)
        if not TheWorld.ismastersim then return end

        inst.UpdatePhotosynthesisState = function(inst, isday)
            --nuhuh --AXE What?
        end

        local _CalcBloomRateFn = inst.components.bloomness.calcratefn

        inst.components.bloomness.calcratefn = function(inst, level, is_blooming, fertilizer)
            if inst.components.skilltreeupdater ~= nil and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_photosynthesis") then
                local season_mult = 1
                if TheWorld.state.season == "summer" or TheWorld.state.season == "spring" then
                    if is_blooming then
                        season_mult = TUNING.WORMWOOD_SPRING_BLOOM_MOD
                    else
                        return TUNING.WORMWOOD_SPRING_BLOOMDRAIN_RATE
                    end
                end
                local rate = (is_blooming and fertilizer > 0) and (season_mult * (1 + fertilizer * TUNING.WORMWOOD_FERTILIZER_RATE_MOD)) or 1
                return rate
            end

            return _CalcBloomRateFn(inst, level, is_blooming, fertilizer)
        end
        -----------------------------------
        local function skilltreemovespeed(inst)
            local stage = inst.components.bloomness:GetLevel()
            local skilltreeupdater = inst.components.skilltreeupdater

            if stage >= 3 and inst._movetreebonus ~= true and ((skilltreeupdater:IsActivated("wormwood_blooming_speed2") and inst.components.health:GetPercent() >= 0.8) or (skilltreeupdater:IsActivated("wormwood_blooming_speed1") and inst.components.health:GetPercent() >= 0.9)) then
                inst._movetreebonus = true
                inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.3
            elseif inst._movetreebonus == true then
                inst._movetreebonus = false
                inst.components.locomotor.runspeed = inst.components.locomotor.runspeed - 0.3
            end
        end

        local _UpdateBloomStage = inst.components.bloomness.onlevelchangedfn

        inst.components.bloomness.onlevelchangedfn = function(inst, stage) --in case you enter the 3rd stage with enough hp required or you go back to 2nd
            _UpdateBloomStage(inst, stage)
            --print("guh") --no guh -- AXE huh?
            skilltreemovespeed(inst)
        end

        inst.UpdateBloomStage = inst.components.bloomness.onlevelchangedfn --not sure if this is needed but Wormwood also uses UpdateBloomStage for this too so might as well update this

        inst:ListenForEvent("healthdelta", function(inst)
            skilltreemovespeed(inst)
        end)

        inst.UMToggleUniqueVetCurse = ToggleUniqueVetCurse

        local function OnFertilizedWithCompost(inst, value)
            if value > 0 and inst.components.health and not inst.components.health:IsDead() then
                local healing = TUNING.WORMWOOD_COMPOST_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_COMPOST_HEAL_VALUES[1]
                if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
                    healing = healing * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
                end

                inst:AddDebuff("compostheal_buff", "compostheal_buff", { duration = healing * (TUNING.WORMWOOD_COMPOST_HEALOVERTIME_TICK / TUNING.WORMWOOD_COMPOST_HEALOVERTIME_HEALTH) })
            end
        end
        inst.OnFertilizedWithCompost = OnFertilizedWithCompost

        local function OnFertilizedWithManure(inst, value, src)
            if value > 0 and inst.components.bloomness then
                local healing = TUNING.WORMWOOD_MANURE_HEAL_VALUES[math.ceil(value / 8)] or TUNING.WORMWOOD_MANURE_HEAL_VALUES[1]
                if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
                    healing = healing * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
                end
                inst.components.health:DoDelta(healing, false, src.prefab)
            end
        end
        inst.OnFertilizedWithManure = OnFertilizedWithManure
    end)
end

-- AXE This is required for compatibility with Wormwood's new skilltree

local creatures_to_grab = { "bee", "killerbee", "butterfly", "um_buttery_fly", "moonbutterfly", "lightflier", "um_bee_moon", "spore_medium", "spore_tall", "spore_small", "um_smolder_spore" }
for i, v in ipairs(creatures_to_grab) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst.components.inventoryitem.grabbableoverridetag = "wormwood_grabby"
    end)
end

-- Change Wormwood Crafts
local require = env.require
require("recipe")

local TECH = env.TECH
local Ingredient = env.Ingredient

local plant_craft_skills = { "sapling", "berrybush", "berrybush2", "juicyberrybush", "reeds", "lureplant" }
for i, v in ipairs(plant_craft_skills) do
    env.AllRecipes["wormwood_" .. v].builder_skill = "wormwood_originator"
end

local mutation_skills = { "carrat", "lightflier", "fruitdragon" }
for i, v in ipairs(mutation_skills) do
    env.AllRecipes["wormwood_" .. v].builder_skill = "wormwood_lunar_mutations"
end

-- Lunar Mushtree Skills
env.AddRecipe2("wormwood_mushtree_tall", { Ingredient("blue_cap", 1), Ingredient("spore_tall", 1), Ingredient("guano", 5) }, TECH.NONE, { placer = "wormwood_mushtree_tall_placer", builder_skill = "wormwood_mushroommadness", product = "mushtree_tall", nounlock = true, no_deconstruction = true, description = "wormwood_mushtree", image = "wormwood_mushtree_tall.tex" }, { "CHARACTER" })
env.AddRecipe2("wormwood_mushtree_medium", { Ingredient("red_cap", 1), Ingredient("spore_medium", 1), Ingredient("guano", 5) }, TECH.NONE, { placer = "wormwood_mushtree_medium_placer", builder_skill = "wormwood_mushroommadness", product = "mushtree_medium", nounlock = true, no_deconstruction = true, description = "wormwood_mushtree", image = "wormwood_mushtree_medium.tex" }, { "CHARACTER" })
env.AddRecipe2("wormwood_mushtree_small", { Ingredient("green_cap", 1), Ingredient("spore_small", 1), Ingredient("guano", 5) }, TECH.NONE, { placer = "wormwood_mushtree_small_placer", builder_skill = "wormwood_mushroommadness", product = "mushtree_small", nounlock = true, no_deconstruction = true, description = "wormwood_mushtree", image = "wormwood_mushtree_small.tex" }, { "CHARACTER" })

env.AllRecipes["wormwood_mushtree_tall"].builder_tag = "plantkin"
env.AllRecipes["wormwood_mushtree_medium"].builder_tag = "plantkin"
env.AllRecipes["wormwood_mushtree_small"].builder_tag = "plantkin"

env.AddRecipe2("wormwood_mushtree_lunar", { Ingredient("moon_cap", 2), Ingredient("guano", 5) }, TECH.NONE, { placer = "wormwood_mushtree_lunar_placer", builder_skill = "wormwood_moon_cap_eating", product = "mushtree_moon", nounlock = true, no_deconstruction = true, description = "wormwood_mushtree", image = "wormwood_mushtree_lunar.tex" }, { "CHARACTER" })
env.AllRecipes["wormwood_mushtree_lunar"].builder_tag = "plantkin"
--[[
local plant_types = {"tomato","eggplant","potato","dragonfruit","pepper","carrot","pumpkin","onion","pomegranate","asparagus",
"corn","durian","garlic","watermelon"}

for i,v in ipairs(plant_types) do
    env.AddRecipe2("wormwood_"..v.."_eqex", {Ingredient(v.."_seeds", 5),Ingredient(CHARACTER_INGREDIENT.HEALTH, 5   )}, TECH.NONE, {  numtogive = 5,  builder_skill = "wormwood_allegiance_lunar_eqex", product = v, nounlock = true,no_deconstruction=true, description="wormwood_eqex"}, {"CHARACTER"})
    env.AllRecipes["wormwood_"..v.."_eqex"].builder_tag = "plantkin"
end
-- AXE Exceptions... These don't correctly grab their images, probably because of Gorge.
env.AllRecipes["wormwood_tomato_eqex"].image = "wormwood_tomato.tex"
env.AllRecipes["wormwood_onion_eqex"].image = "wormwood_onion.tex"]]

local plants_1 = { "potato", "asparagus", "garlic", "pumpkin", "pomegranate", "dragonfruit", "watermelon" }
local plants_2 = { "eggplant", "corn", "durian", "carrot", "onion", "pepper", "tomato" }
for i, v in ipairs(plants_1) do
    env.AddRecipe2("wormwood_" .. v .. "_eqex", { Ingredient(plants_2[i] .. "_seeds", 5), Ingredient(CHARACTER_INGREDIENT.HEALTH, 5) }, TECH.NONE, { numtogive = 4, builder_skill = "wormwood_allegiance_lunar_eqex", product = v .. "_seeds", nounlock = true, no_deconstruction = true, description = "wormwood_eqex" }, { "CHARACTER" })
    env.AllRecipes["wormwood_" .. v .. "_eqex"].builder_tag = "plantkin"

    env.AddRecipe2("wormwood_" .. plants_2[i] .. "_eqex", { Ingredient(v .. "_seeds", 5), Ingredient(CHARACTER_INGREDIENT.HEALTH, 5) }, TECH.NONE, { numtogive = 4, builder_skill = "wormwood_allegiance_lunar_eqex", product = plants_2[i] .. "_seeds", nounlock = true, no_deconstruction = true, description = "wormwood_eqex" }, { "CHARACTER" })
    env.AllRecipes["wormwood_" .. plants_2[i] .. "_eqex"].builder_tag = "plantkin"
end



local levels =
{
    { amount = 6, grow = "mushroom_4", idle = "mushroom_4_idle", hit = "hit_mushroom_4" }, -- this can only be reached by starting with spores
    { amount = 4, grow = "mushroom_3", idle = "mushroom_3_idle", hit = "hit_mushroom_3" }, -- max for starting with mushrooms
    { amount = 2, grow = "mushroom_2", idle = "mushroom_2_idle", hit = "hit_mushroom_2" },
    { amount = 1, grow = "mushroom_1", idle = "mushroom_1_idle", hit = "hit_mushroom_1" },
    { amount = 0, idle = "idle",   hit = "hit_idle" },
}

local spore_to_cap = --AXE I'm referring to these, and the other local arrays... I think we have to keep these to reset StartGrowing.
{
    spore_tall = "blue_cap",
    spore_medium = "red_cap",
    spore_small = "green_cap",
}

local FULLY_REPAIRED_WORKLEFT = 3

local function DoMushroomOverrideSymbol(inst, product)
    inst.AnimState:OverrideSymbol("swap_mushroom", "mushroom_farm_" .. (string.split(product, "_")[1]) .. "_build", "swap_mushroom")
end

local function StartGrowing(inst, giver, product)
    if inst.components.harvestable ~= nil then
        local is_spore = product:HasTag("spore")

        local grower_skilltreeupdater = giver.components.skilltreeupdater
        local planter_is_improved = (grower_skilltreeupdater and grower_skilltreeupdater:IsActivated("wormwood_mushroommadness")) --AXE I'm needing to change these,

        local max_produce = ((is_spore or planter_is_improved) and levels[1].amount) or levels[2].amount
        local productname = (is_spore and spore_to_cap[product.prefab]) or product.prefab

        local grow_time_percent = 1.0

        if grower_skilltreeupdater ~= nil then
            if grower_skilltreeupdater:IsActivated("wormwood_mushroommadness") then --AXE I'm needing to change these, unfortunately I don't think there's a way to change these and *not* include the above defintions for the spores
                grow_time_percent = TUNING.WORMWOOD_MUSHROOMPLANTER_RATEBONUS_2
            end
        end

        local grow_time = grow_time_percent * TUNING.MUSHROOMFARM_FULL_GROW_TIME

        DoMushroomOverrideSymbol(inst, productname)

        inst.components.harvestable:SetProduct(productname, max_produce)
        inst.components.harvestable:SetGrowTime(grow_time / max_produce)
        inst.components.harvestable:Grow()

        TheWorld:PushEvent("itemplanted", { doer = giver, pos = inst:GetPosition() }) --this event is pushed in other places too
    end
end

local UpvalueHacker = require("tools/upvaluehacker")
env.AddPrefabPostInit("world", function(inst) -- AXE Assuming Max said this -> Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not _G.TheWorld.ismastersim then return end
    UpvalueHacker.SetUpvalue(_G.Prefabs.mushroom_farm.fn, StartGrowing, "onacceptitem", "StartGrowing")
end)

local TREESTATES =
{
    BLOOMING = "bloom",
    NORMAL = "normal",
}

local function IsWormwoodGone(inst)
    local wormwood = FindEntity(inst, TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE * TUNING.WORMWOOD_TENDRANGE_MULT, function(ent)
        return ent.prefab == "wormwood" and
            ent.components.skilltreeupdater and ent.components.skilltreeupdater:IsActivated("wormwood_sympathetic_blooming") and ent.fullbloom
    end)
    if wormwood then
        inst:DoTaskInTime(60 * 4, IsWormwoodGone)
    elseif not TheWorld.state.issummer and inst.components.pickable and inst.components.pickable.canbepicked and (inst.prefab == "cactus" or inst.prefab == "oasis_cactus") then
        inst.AnimState:PlayAnimation("idle", true)
        inst.has_flower = false
    elseif inst:HasTag("mushtree") and not ((inst.prefab == "mushtree_tall" and TheWorld.state.iswinter) or
            (inst.prefab == "mushtree_small" and TheWorld.state.isspring) or (inst.prefab == "mushtree_medium" and TheWorld.state.issummer)) then
        inst._Normal(inst, true)
    end
    if not wormwood then
        SpawnPrefab("wormwood_lunar_transformation_finish").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end


local function DoSympatheticBlooming(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    -- Cactus
    local cacti = TheSim:FindEntities(x, y, z, TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE * TUNING.WORMWOOD_TENDRANGE_MULT, { "plant", "thorny" })
    for i, v in ipairs(cacti) do
        if (v.prefab == "cactus" or v.prefab == "oasis_cactus") and not v.has_flower and v.components.pickable.canbepicked then
            v.AnimState:PlayAnimation("idle_flower", true)
            v.has_flower = true
            v:DoTaskInTime(60 * 4, IsWormwoodGone)
            SpawnPrefab("wormwood_lunar_transformation_finish").Transform:SetPosition(v.Transform:GetWorldPosition())
        end
    end

    -- Mushtrees
    local mushtrees = TheSim:FindEntities(x, y, z, TUNING.WORMWOOD_BLOOM_FARM_PLANT_INTERACT_RANGE * TUNING.WORMWOOD_TENDRANGE_MULT, { "mushtree" })
    for i, v in ipairs(mushtrees) do
        if (v.prefab == "mushtree_tall" or v.prefab == "mushtree_medium" or v.prefab == "mushtree_small") and v.treestate == "normal" then
            v._Bloom(v, true)
            v:DoTaskInTime(60 * 4, IsWormwoodGone)
            SpawnPrefab("wormwood_lunar_transformation_finish").Transform:SetPosition(v.Transform:GetWorldPosition())
        end
    end
end

local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS

env.AddPrefabPostInit("world", function(inst)
    if not _G.TheWorld.ismastersim then return end

    local _DoAOEeffect = UpvalueHacker.GetUpvalue(_G.Prefabs.wormwood.fn, "master_postinit", "UpdateBloomStage", "EnableFullBloom", "DoAOEeffect")
    local function DoAOEeffect(inst, enable)
        _DoAOEeffect(inst, enable)
        local skilltreeupdater = inst.components.skilltreeupdater
        if skilltreeupdater and skilltreeupdater:IsActivated("wormwood_sympathetic_blooming") then
            DoSympatheticBlooming(inst)
        end
    end
    UpvalueHacker.SetUpvalue(_G.Prefabs.wormwood.fn, DoAOEeffect, "master_postinit", "UpdateBloomStage", "EnableFullBloom", "DoAOEeffect")

    local _EnableFullBloom = UpvalueHacker.GetUpvalue(_G.Prefabs.wormwood.fn, "master_postinit", "UpdateBloomStage", "EnableFullBloom")
    local function EnableFullBloom(inst, enable)
        if enable then
            if not inst.fullbloom then
                if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_overheatprotection") then
                    inst.components.moisture.waterproofnessmodifiers:SetModifier(inst, TUNING.WATERPROOFNESS_SMALL)
                end
            end
        elseif inst.fullbloom then
            if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("wormwood_blooming_overheatprotection") then
                inst.components.moisture.waterproofnessmodifiers:SetModifier(inst, 0)
            end
        end
        _EnableFullBloom(inst, enable)
    end
    UpvalueHacker.SetUpvalue(_G.Prefabs.wormwood.fn, EnableFullBloom, "master_postinit", "UpdateBloomStage", "EnableFullBloom")

    for k, v in pairs(PLANT_DEFS) do
        env.AddPrefabPostInit(v.prefab, function(inst)
            inst:ListenForEvent("on_planted", on_planted)
        end)
    end

    local _OnBlocked = UpvalueHacker.GetUpvalue(_G.Prefabs.armor_bramble.fn, "OnBlocked")
    local function OnBlocked(owner, data, inst)
        _OnBlocked(owner, data, inst)
        if data ~= nil and not data.redirected then
            if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wormwood_armor_bramble2") then
                owner:DoTaskInTime(0.6, function(owner) --AXE The capstone ability triggers the bramble effect a second time.
                    if owner then
                        SpawnPrefab("bramblefx_armor"):SetFXOwner(owner)
                        if owner.SoundEmitter ~= nil then
                            owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
                        end
                    end
                end)
            end
        end
    end
    UpvalueHacker.SetUpvalue(_G.Prefabs.armor_bramble.fn, OnBlocked, "OnBlocked")

    local _OnHuskBlocked = UpvalueHacker.GetUpvalue(_G.Prefabs.armor_lunarplant_husk.fn, "husk_master_postinit", "OnHuskBlocked")
    local function OnHuskBlocked(owner, data, inst)
        _OnHuskBlocked(owner, data, inst)

        if data ~= nil and not data.redirected then
            if owner.components.skilltreeupdater and owner.components.skilltreeupdater:IsActivated("wormwood_armor_bramble2") then
                owner:DoTaskInTime(0.6, function(owner) --AXE The capstone ability triggers the bramble effect a second time.
                    if owner then
                        SpawnPrefab("bramblefx_armor_upgrade"):SetFXOwner(owner)
                        if owner.SoundEmitter ~= nil then
                            owner.SoundEmitter:PlaySound("dontstarve/common/together/armor/cactus")
                        end
                    end
                end)
            end
        end

        -- Brambleshade also snares enemies
        if owner == nil or data == nil then
            return
        end

        local attacker = data.attacker
        if not attacker or not attacker.components.locomotor
            or (attacker.components.health and attacker.components.health:IsDead()) then
            return
        end

        local owner_skilltreeupdater = owner.components.skilltreeupdater
        if owner_skilltreeupdater and owner_skilltreeupdater:IsActivated("wormwood_allegiance_lunar_plant_gear_1") then
            attacker:AddDebuff("wormwood_vined_debuff", "wormwood_vined_debuff")
        end
    end

    UpvalueHacker.SetUpvalue(_G.Prefabs.armor_lunarplant_husk.fn, OnHuskBlocked, "husk_master_postinit", "OnHuskBlocked")

    local function DoThornsTrap(inst, pos)
        local thorns = SpawnPrefab("bramblefx_trap")
        thorns.Transform:SetPosition(pos:Get())
        thorns.canhitplayers = TheNet:GetPVPEnabled()
        if inst.bonusrange then
            thorns.range = thorns.range + 2
            thorns.Transform:SetScale(2, 2, 2)
        end
    end

    UpvalueHacker.SetUpvalue(_G.Prefabs.trap_bramble.fn, DoThornsTrap, "OnExplode", "DoThorns")
end)

local function on_planted(inst, data)
    if data and data.doer then
        local skilltreeupdater = data.doer.components.skilltreeupdater
        if skilltreeupdater and skilltreeupdater:IsActivated("wormwood_resilient_crops1") then
            --TheNet:Announce("Wormwood made me resilient")
            inst.components.farmplantstress.wormwood_res1 = true
        end
        if skilltreeupdater and skilltreeupdater:IsActivated("wormwood_resilient_crops2") then
            --TheNet:Announce("Wormwood made me tend myself")
            inst.components.farmplantstress.wormwood_res2 = true
            if not TheWorld.Map:IsFarmableSoilAtPoint(inst.Transform:GetWorldPosition()) then
                inst.components.farmplanttendable:TendTo(data.doer)
            end
        end
        if skilltreeupdater and skilltreeupdater:IsActivated("wormwood_resilient_crops3") then
            --TheNet:Announce("Wormwood made me extremely resilient")
            inst.components.farmplantstress.wormwood_res3 = true
        end
    end
end


for k, v in pairs(PLANT_DEFS) do
    env.AddPrefabPostInit(v.prefab, function(inst)
        inst:ListenForEvent("on_planted", on_planted)

        -- AXE This is our backdoor to make edits to all plants during the fn call
        local _UpdateResearchStage = inst.UpdateResearchStage
        inst.UpdateResearchStage = function(inst, stage)
            -- AXE Resilient Crops II triggers here after the crops grow; if they're wild, then they tend themselves.
            if inst.components.farmplanttendable and inst.components.farmplantstress and inst.components.farmplantstress.wormwood_res2 and not TheWorld.Map:IsFarmableSoilAtPoint(inst.Transform:GetWorldPosition()) then
                inst.components.farmplanttendable:TendTo(TheWorld)
            end

            -- AXE Impeccable Crops III makes crops unrot themselves
            --TheNet:Announce(stage)
            if inst.components.growable and inst.components.farmplantstress and inst.components.farmplantstress.wormwood_res3 and not TheWorld.Map:IsFarmableSoilAtPoint(inst.Transform:GetWorldPosition()) and inst.components.growable.stage == 6 then
                inst.components.growable:SetStage(4)
                inst.components.growable:DoGrowth()
                stage = stage - 1
                inst.components.farmplantstress.depressed_forever = true
                inst:DoTaskInTime(0, function(inst) inst.AnimState:PlayAnimation("crop_full", true) end)
            else
                --AXE in this instance, we don't need to update the research stage, it's going to get called again....
                _UpdateResearchStage(inst, stage)
            end
        end
    end)
end

--- AXE For a lot of wormwood's resilient crops path, there needs to be edits to the stress tests
env.AddComponentPostInit("farmplantstress", function(self)
    self.wormwood_res1 = false
    self.wormwood_res2 = false
    self.wormwood_res3 = false
    self.depressed_forever = false

    local _SetStressed = self.SetStressed
    self.SetStressed = function(self, name, stressed, doer)
        --TheNet:Announce("running")
        local should_stress = true
        if (name == "killjoys" and self.wormwood_res1) then -- If it's a killjoy and wormwood with a skill planted us, ignore the losses.
            stressed = false
        end
        _SetStressed(self, name, stressed, doer)
    end


    local _GetFinalStressState = self.GetFinalStressState
    self.GetFinalStressState = function(self)
        if self.depressed_forever then
            self.final_stress_state = 4 -- High
        end
        return self.final_stress_state
    end

    -- AXE I haven't figured out how to correctly Postinit this. If you fix it, *test your fix first*, I've tried a decent chunk of things and they
    -- tend to screw things up (like trying to insert the variables into the "data" structure getting passed).
    -- There's probably a correct way to do it, though.
    local _OnSave = self.OnSave
    function self:OnSave(...)
        local ret = _OnSave(self, ...)
        if ret then
            ret.wormwood_res1 = self.wormwood_res1
            ret.wormwood_res2 = self.wormwood_res2
            ret.wormwood_res3 = self.wormwood_res3
            ret.depressed_forever = self.depressed_forever
        end
        return ret
    end

    local _OnLoad = self.OnLoad
    function self:OnLoad(data, ...)
        local ret = _OnLoad(self, data, ...)
        if data then
            self.wormwood_res1 = data.wormwood_res1
            self.wormwood_res2 = data.wormwood_res2
            self.wormwood_res3 = data.wormwood_res3
            self.depressed_forever = data.depressed_forever

            if self.wormwood_res2 and not TheWorld.Map:IsFarmableSoilAtPoint(self.inst.Transform:GetWorldPosition()) then -- Make auto tending.
                self.inst.components.farmplanttendable:TendTo(TheWorld)
            end
        end
        return ret
    end
end)

local cactii = { "cactus", "oasis_cactus" }
for i, v in ipairs(cactii) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        local _onpickedfn = inst.components.pickable.onpickedfn

        local function onpickedfn(inst, picker)
            if picker.components.skilltreeupdater and picker.components.skilltreeupdater:IsActivated("wormwood_prick_adept") then
                inst.Physics:SetActive(false)
                inst.AnimState:PlayAnimation(inst.has_flower and "picked_flower" or "picked")
                inst.AnimState:PushAnimation("empty", true)

                if picker ~= nil then
                    if inst.has_flower then
                        -- You get a cactus flower, yay.
                        local loot = SpawnPrefab("cactus_flower")
                        loot.components.inventoryitem:InheritWorldWetnessAtTarget(inst)
                        if picker.components.inventory ~= nil then
                            picker.components.inventory:GiveItem(loot, nil, inst:GetPosition())
                        else
                            local x, y, z = inst.Transform:GetWorldPosition()
                            loot.components.inventoryitem:DoDropPhysics(x, y, z, true)
                        end
                    end
                end

                inst.has_flower = false
            else
                _onpickedfn(inst, picker)
            end
        end
        inst.components.pickable.onpickedfn = onpickedfn
    end)
end

env.AddPrefabPostInit("marsh_bush", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    local _onpickedfn = inst.components.pickable.onpickedfn

    local function onpickedfn(inst, picker)
        if picker.components.skilltreeupdater and picker.components.skilltreeupdater:IsActivated("wormwood_prick_adept") then
            inst.AnimState:PlayAnimation("picking")
            inst.AnimState:PushAnimation("picked", false)
        else
            _onpickedfn(inst, picker)
        end
    end
    inst.components.pickable.onpickedfn = onpickedfn
end)

local function NoHoles(pt)
    return (TheWorld ~= nil) and not TheWorld.Map:IsPointNearHole(pt)
end

env.AddPrefabPostInit("glasscutter", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local weapon = inst.components.weapon
    if weapon then
        local _OnAttack = weapon.onattack
        weapon:SetOnAttack(function(inst, attacker, target, ...)
            if attacker.components.skilltreeupdater and attacker.components.skilltreeupdater:IsActivated("wormwood_allegiance_lunar_plant_gear_2")
                and target and target:IsValid() and math.random() < 0.2 then
                local pt = target:GetPosition()

                local offset = FindWalkableOffset(pt, TWOPI * math.random(), 2, 3, false, true, NoHoles, false, true)
                if offset then
                    local tentacle = SpawnPrefab("lunarplanttentacle")
                    if tentacle then
                        tentacle.owner = attacker
                        tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                        tentacle.components.combat:SetTarget(target)
                    end
                end
            end
            if _OnAttack then _OnAttack(inst, attacker, target, ...) end
        end)
    end
end)


env.AddPrefabPostInit("trap_bramble", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    local _ondeploy = inst.components.deployable.ondeploy
    local function ondeploy(inst, pt, deployer)
        if deployer.components.skilltreeupdater and deployer.components.skilltreeupdater:IsActivated("wormwood_blooming_trapbramble") then
            inst.bonusrange = true
        end
        _ondeploy(inst, pt, deployer)
    end
    inst.components.deployable.ondeploy = ondeploy

    local _OnSave = inst.OnSave
    inst.OnSave = function(inst, data, ...)
        if inst.bonusrange then
            data.bonusrange = true
        end
        return _OnSave and _OnSave(inst, data, ...)
    end

    local _OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data, ...)
        if data and data.bonusrange then
            inst.bonusrange = true
        end
        return _OnLoad and _OnLoad(inst, data, ...)
    end
end)

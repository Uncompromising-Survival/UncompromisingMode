require "prefabutil" -- for the MakePlacer function

local mushredassets = { Asset("ANIM", "anim/um_geode_red.zip") }
local mushgreenassets = { Asset("ANIM", "anim/um_geode_green.zip") }
local mushblueassets = { Asset("ANIM", "anim/um_geode_blue.zip") }
local guanoassets = { Asset("ANIM", "anim/um_geode_guano.zip") }
local lobsterassets = { Asset("ANIM", "anim/um_geode_lobster.zip") }
local glassassets = { Asset("ANIM", "anim/um_geode_glass.zip") }
local slimeassets = { Asset("ANIM", "anim/um_geode_slime.zip") }
local ruinsassets = { Asset("ANIM", "anim/um_geode_ruins.zip") }
local sinksassets = { Asset("ANIM", "anim/um_geode_sink.zip") }

local loot_table = {

    ["um_gemology_geode_red"] =
    {
        notgemloot = {
            red_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_medium = 0.5,
        },
        gemloot = {
            um_gemologyredgem1 = 1,
            um_gemologyredgem2 = 1,
            um_gemologyorangegem1 = 0.5,
            redgem = 0.5,
        },
    },

    ["um_gemology_geode_green"] =
    {
        notgemloot = {
            green_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_short = 0.5,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologygreengem2 = 1,
            um_gemologypalegem1 = 0.5,
            greengem = 0.05,
        },
    },

    ["um_gemology_geode_blue"] =
    {
        notgemloot = {
            blue_cap = 1,
            rocks = 1,
            log = 0.5,
            spore_tall = 0.5,
        },
        gemloot = {
            um_gemologybluegem1 = 1,
            um_gemologybluegem2 = 1,
            um_gemologypurplegem2 = 0.5,
            bluegem = 0.5,
        },
    },
    ["um_gemology_geode_guano"] =
    {
        notgemloot = {
            guano = 1,
            rocks = 1,
            nitre = 0.5,
            flint = 0.5,
        },
        gemloot = {
            um_gemologyyellowgem2 = 1,
            um_gemologyredgem2 = 1,
            um_gemologypurplegem2 = 0.5,
            yellowgem = 0.1,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_lobster"] =
    {
        notgemloot = {
            smallmeat = 1,
            rocks = 1,
            nitre = 0.5,
            flint = 0.5,
        },
        gemloot = {
            um_gemologyyellowgem1 = 1,
            um_gemologypalegem2 = 1,
            um_gemologyorangegem2 = 1,
            um_gemologybluegem1 = 1,
            yellowgem = 0.1,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_glass"] =
    {
        notgemloot = {
            moonglass = 1,
            moonglass = 1,
            moonglass = 0.5,
        },
        gemloot = {
            um_gemologyyellowgem2 = 1,
            um_gemologypalegem1 = 1,
            um_gemologybluegem1 = 1,
            um_gemologygreengem1 = 1,
            yellowgem = 0.1,
            bluegem = 0.5,
        },
    },
    ["um_gemology_geode_slime"] =
    {
        notgemloot = {
            poop = 1,
            rocks = 1,
            poop = 0.5,
            rocks = 0.5,
            cave_banana = 0.5,
        },
        gemloot = {
            um_gemologybluegem2 = 1,
            um_gemologyredgem1 = 1,
            um_gemologypalegem1 = 1,
            um_gemologypalegem2 = 1,
            bluegem = 0.5,
            redgem = 0.5,
        },
    },
    ["um_gemology_geode_ruins"] =
    {
        notgemloot = {
            gears = 1,
            trinket_6 = 1,
            trinket_1 = 1,
            thulecite = 0.25,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologyyellowgem1 = 1,
            um_gemologypurplegem2 = 1,
            um_gemologypurplegem1 = 1,
            bluegem = 0.5,
            redgem = 0.5,
            purplegem = 0.5,
            orangegem = 0.25,
            yellowgem = 0.25,
            greengem = 0.25,
        },
    },
    ["um_gemology_geode_sink"] =
    {
        notgemloot = {
            rocks = 1,
            cutgrass = 1,
            twigs = 1,
            foliage = 1,
        },
        gemloot = {
            um_gemologygreengem1 = 1,
            um_gemologyyellowgem2 = 1,
            um_gemologyorangegem2 = 1,
            um_gemologyorangegem1 = 1,
            orangegem = 0.1,
            greengem = 0.05,
            yellowgemgem = 0.05,
        },
    },

}


local function GenerateLoot(inst, miner)
    for i = 1, 3 do -- nongem loot
        local loot = weighted_random_choice(loot_table[inst.prefab].notgemloot)
        local prefab = SpawnPrefab(loot)
        LaunchAt(prefab, inst, miner, -1.8, 1.5, nil, math.random(0, 360))
    end
    local max_i = 1
    if math.random() < 0.05 then -- Need to make it uncommon to get more than 1
        max_i = 2
    end
    for i = 1, max_i do -- gem loot
        local loot = weighted_random_choice(loot_table[inst.prefab].gemloot)
        local prefab = SpawnPrefab(loot)
        LaunchAt(prefab, inst, miner, -1.8, 1.5, nil, math.random(0, 360))
        if prefab:HasTag("gemology_gem") then
            local rand = math.random()
            if not (rand >= 0.35) then
                prefab:SetTier(2)
                if rand < 0.1 then
                    prefab:SetTier(3)
                end
            end
        end
    end
end


local function on_mine(inst, miner, workleft, workdone)
    local num_rocks_worked = math.clamp(math.ceil(workdone / TUNING.ROCK_FRUIT_MINES), 1, inst.components.stackable:StackSize())
    GenerateLoot(inst, miner)
    -- Finally, remove the actual stack items we just consumed
    local top_stack_item = inst.components.stackable:Get(num_rocks_worked)
    top_stack_item:Remove()
end

local function OnExplosion(inst, data)
    local miner = data and data.explosive or nil
    if miner then
        LaunchAt(inst, inst, miner, -1.8, 1.5, nil, 65)
    end
end

local function stack_size_changed(inst, data)
    if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(data.stacksize * TUNING.ROCK_FRUIT_MINES)
    end
end

local function geodemain(bankbuild)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(bankbuild)
    inst.AnimState:SetBuild(bankbuild)
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "rock"

    inst:AddTag("molebait")
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.68)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("tradable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCK_FRUIT_MINES * inst.components.stackable.stacksize)
    --inst.components.workable:SetOnFinishCallback(on_mine)
    inst.components.workable:SetOnWorkCallback(on_mine)

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
    inst.components.edible.hungervalue = 2
    inst:AddComponent("bait")

    -- The amount of work needs to be updated whenever the size of the stack changes
    inst:ListenForEvent("stacksizechange", stack_size_changed)
    -- Explosions knock around these fruits in specific.
    inst:ListenForEvent("explosion", OnExplosion)

    MakeHauntableLaunch(inst)

    return inst
end

local function mushred()
    return geodemain("um_geode_red")
end

local function mushgreen()
    return geodemain("um_geode_green")
end

local function mushblue()
    return geodemain("um_geode_blue")
end

local function guano()
    return geodemain("um_geode_guano")
end

local function lobster()
    return geodemain("um_geode_lobster")
end

local function glass()
    return geodemain("um_geode_glass")
end

local function slime()
    return geodemain("um_geode_slime")
end

local function ruins()
    return geodemain("um_geode_ruins")
end

local function sink()
    return geodemain("um_geode_sink")
end

return Prefab("um_gemology_geode_red", mushred, mushredassets),
    Prefab("um_gemology_geode_green", mushgreen, mushgreenassets),
    Prefab("um_gemology_geode_blue", mushblue, mushblueassets),
    Prefab("um_gemology_geode_guano", guano, guanoassets),
    Prefab("um_gemology_geode_lobster", lobster, lobsterassets),
    Prefab("um_gemology_geode_glass", glass, glassassets),
    Prefab("um_gemology_geode_slime", slime, slimeassets),
    Prefab("um_gemology_geode_ruins", ruins, ruinsassets),
    Prefab("um_gemology_geode_sink", sink, sinksassets)

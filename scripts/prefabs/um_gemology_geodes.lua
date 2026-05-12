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
local ventassets = { Asset("ANIM", "anim/um_geode_vent.zip") }

local loot_table = require("um_gemology_geode_defs")

local function GenerateLoot(inst, miner, num_rocks_worked)
    for i = 1, num_rocks_worked do
        for i = 1, 3 do -- nongem loot
            local loot = weighted_random_choice(loot_table[inst.prefab].notgemloot)
            local prefab = SpawnPrefab(loot)
            LaunchAt(prefab, inst, miner, -1.8, 1.5, nil, math.random(0, 360))
        end
        for j = 1, math.random() < .05 and 2 or 1 do -- Need to make it uncommon to get more than 1
            local loot = weighted_random_choice(loot_table[inst.prefab].gemloot)
            local prefab = SpawnPrefab(loot)
            LaunchAt(prefab, inst, miner, -1.8, 1.5, nil, math.random(0, 360))
            if prefab:HasTag("gemology_gem") then
                local rand = math.random()
                if not (rand >= 0.05) then
                    prefab:SetTier(2)
                    if rand < 0.01 then
                        prefab:SetTier(3)
                    end
                end
            end
        end
    end
end

local function on_mine(inst, miner, workleft, workdone)
    local num_rocks_worked = math.clamp(math.ceil(workdone / TUNING.ROCK_FRUIT_MINES), 1, inst.components.stackable:StackSize())
    GenerateLoot(inst, miner, num_rocks_worked)
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
    inst:AddTag("gemology_geode")
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
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
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
    local inst = geodemain("um_geode_glass")
    inst:AddTag("quakedebris")
    return inst
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

local function vent()
    return geodemain("um_geode_vent")
end

return Prefab("um_gemology_geode_red", mushred, mushredassets),
    Prefab("um_gemology_geode_green", mushgreen, mushgreenassets),
    Prefab("um_gemology_geode_blue", mushblue, mushblueassets),
    Prefab("um_gemology_geode_guano", guano, guanoassets),
    Prefab("um_gemology_geode_lobster", lobster, lobsterassets),
    Prefab("um_gemology_geode_glass", glass, glassassets),
    Prefab("um_gemology_geode_slime", slime, slimeassets),
    Prefab("um_gemology_geode_ruins", ruins, ruinsassets),
    Prefab("um_gemology_geode_sink", sink, sinksassets),
    Prefab("um_gemology_geode_vent", vent, ventassets)
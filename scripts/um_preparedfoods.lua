local RECIPE_ICE_LIMIT = TUNING.DSTU.CROCKPOT_RECIPE_ICE_LIMIT
local RECIPE_TWIG_LIMIT = TUNING.DSTU.CROCKPOT_RECIPE_TWIG_LIMIT
local RECIPE_ICE_PLUS_TWIG_LIMIT = TUNING.DSTU.CROCKPOT_RECIPE_ICE_PLUS_TWIG_LIMIT
local easing = require("easing")

local function LimitIceTestFn(tags, ice_limit)
    if tags ~= nil and tags.frozen ~= nil and TUNING.DSTU.GENERALCROCKBLOCKER then
        return (not tags.frozen or (tags.frozen + (tags.foliage ~= nil and tags.foliage or 0) <= ice_limit))
    end
    return true
end

local function LimitTwigTestFn(tags, twig_limit)
    if tags ~= nil and tags.inedible ~= nil then
        return not tags.inedible or (tags.inedible + (tags.foliage ~= nil and tags.foliage or 0) <= twig_limit)
    end
    return true
end

local function LimitIcePlusTwigTestFn(tags, ice_plus_twig_limit)
    if tags ~= nil and tags.frozen ~= nil and tags.inedible ~= nil then
        return (tags.frozen + tags.inedible + (tags.foliage ~= nil and tags.foliage or 0)) <= ice_plus_twig_limit
    end
    return true
end

local function UncompromisingFillerCustomTestFn(tags, ice_limit, twig_limit, ice_plus_twig_limit)
    return LimitIceTestFn(tags, ice_limit) and LimitTwigTestFn(tags, twig_limit) and
        LimitIcePlusTwigTestFn(tags, ice_plus_twig_limit)
end

local function UncompromisingFillers(tags)
    return (
        UncompromisingFillerCustomTestFn(tags, RECIPE_ICE_LIMIT, RECIPE_TWIG_LIMIT, RECIPE_ICE_PLUS_TWIG_LIMIT) and
        TUNING.DSTU.GENERALCROCKBLOCKER) or TUNING.DSTU.GENERALCROCKBLOCKER == false
end

local function UnGhost(eater)
    if not (eater:HasTag("psuedo_ghost") or eater:HasTag("playerghost")) then
        if eater.flashingtask then
            eater.flashingtask:Cancel()
            eater.flashghost = nil
            eater.flashingtask = nil
        end
        eater.Physics:CollidesWith(COLLISION.OBSTACLES)
        eater.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        eater.Physics:CollidesWith(COLLISION.CHARACTERS)
        eater.Physics:CollidesWith(COLLISION.FLYERS)
        eater.AnimState:SetHaunted(false)
    end
end

local function Ghost(eater)
    if eater.flashingtask then
        eater.flashingtask:Cancel()
        eater.flashghost = nil
        eater.flashingtask = nil
    end

    eater.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
    eater.Physics:ClearCollidesWith(COLLISION.SMALLOBSTACLES)
    eater.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
    eater.Physics:ClearCollidesWith(COLLISION.FLYERS)
    eater.AnimState:SetHaunted(true)

    if eater.unghosttask then eater.unghosttask:Cancel() end
    eater.unghosttask = eater:DoTaskInTime(60 * 4, UnGhost)
end

local function BoomPieStopKnockback(inst, data)
    if data and data.statename ~= "knockback" and inst.um_boomberrypietask then
        inst.um_boomberrypietask:Cancel()
        inst.um_boomberrypietask = nil
    end
    inst:RemoveEventCallback("newstate", BoomPieStopKnockback)
end

local pie_shouldnt_hit = {"FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost", "player"}
local function BoomPieGo(inst, eater)
    if eater.components.health and not eater.components.health:IsDead() then
        local x, y, z = eater.Transform:GetWorldPosition()
        eater.Physics:SetCollisionMask(COLLISION.GROUND, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS) -- Can Launch yourself over gaps
        eater.Physics:Teleport(x, y, z)
        eater:PushEvent("knockback", {knocker = eater, radius = 6, strengthmult = 6})
        eater:ListenForEvent("newstate", BoomPieStopKnockback)
		eater:PushEvent("attacked", {damage = 3})
        eater.components.health:SetInvincible(true)

        if eater.um_boomberrypietask then eater.um_boomberrypietask:Cancel() end
        eater.um_boomberrypietask = eater:DoTaskInTime(10 * FRAMES, function(eater)
            eater.Physics:SetCollisionMask(COLLISION.WORLD, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS)        
            eater.components.health:SetInvincible(false)
            if eater.sg then
                eater.sg.statemem.speed = -10
                eater:DoTaskInTime(0, function()
                    if eater.sg:HasState("sink_fast") and eater.components.drownable and eater.components.drownable:IsOverWater() then
                        eater.sg:GoToState("sink_fast")
                        eater.AnimState:SetFrame(70)
                        SpawnPrefab("um_ocean_splash").Transform:SetPosition(eater.Transform:GetWorldPosition())
                    end
                end)
            end
            eater.um_boomberrypietask = nil
            eater:RemoveEventCallback("newstate", BoomPieStopKnockback)
        end)

        SpawnPrefab("explode_small").Transform:SetPosition(x, y, z)
        SpawnPrefab("blueberryexplosion").Transform:SetPosition(x, y, z)
        local puddle = SpawnPrefab("blueberrypuddle")
        puddle.Transform:SetPosition(x, y, z)        
        puddle.playermade = true
        puddle.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap")

        local casualties = TheSim:FindEntities(x, y, z, 2, nil, pie_shouldnt_hit)
        if #casualties > 0 then
            for i, v in pairs(casualties) do
                if v.components.combat and eater.components.combat:CanTarget(v) then
                    v.components.combat:GetAttacked(eater, 68)
                end
            end
        end
    end
end

local um_preparedfoods =
{
    beefalowings =
    {
        test = function(cooker, names, tags)
            return tags.veggie and names.horn and
                (
                    (names.batwing and names.batwing > 1) or (names.batwing_cooked and names.batwing_cooked > 1) or
                    (names.batwing and names.batwing_cooked))
        end,
        hunger = 62.5,
        health = 30,
        sanity = 30,
        foodtype = FOODTYPE.MEAT,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        priority = 20,
        weight = 30,
        cooktime = 2.4,
        floater = { "med", nil, 0.6 },
        tags = { "honeyed" },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_BEEFALOWINGS,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                eater.components.debuffable:AddDebuff("buff_knockbackimmune", "buff_knockbackimmune")
            end
        end,
        card_def = { ingredients = { { "horn", 1 }, { "batwing", 2 }, { "carrot", 1 } } },
    },

    blueberrypancakes =
    {
        test = function(cooker, names, tags)
            return names.giant_blueberry and names.giant_blueberry >= 2 and tags.egg and tags.egg >= 2
        end,
        hunger = 75,
        health = 5,
        sanity = 20,
        priority = 20,
        weight = 30,
        cooktime = 1.8,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = TUNING.PERISH_SLOW,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "giant_blueberry", 2 }, { "bird_egg", 2 } } },
    },

    californiaking =
    {
        test = function(cooker, names, tags)
            return (names.barnacle or names.barnacle_cooked) and
                (names.wobster_sheller_land) and (names.pepper or names.pepper_cooked) and tags.frozen
        end,
        hunger = 62.5,
        health = 3,
        sanity = -15,
        priority = 30,
        weight = 30,
        cooktime = 2,
        foodtype = FOODTYPE.MEAT,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", nil, 0.8 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_CALIFORNIAKING,
        oneatenfn = function(inst, eater)
            if eater.components.hayfever and eater.components.hayfever.enabled then
                eater.components.hayfever:SetNextSneezeTime(1920) --Should be four days            
            end

            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                eater.components.debuffable:AddDebuff("buff_californiaking", "buff_californiaking")
            end
        end,
        card_def = { ingredients = { { "barnacle", 1 }, { "wobster_sheller_land", 1 }, { "pepper", 1 }, { "ice", 1 } } },
    },

    --[[carapacecooler =
    {
        test = function(cooker, names, tags)
            return not tags.monster and not tags.inedible and UncompromisingFillers(tags)
                and names.iceboomerang and tags.sweetener
        end,
        hunger = 37.5,
        health = 40,
        sanity = 15,
        priority = 30,
        weight = 1,
        cooktime = 0.5,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 2*TUNING.PERISH_TWO_DAY,
        floater = {"small", nil, 0.6},
        card_def = {ingredients = {{"iceboomerang", 1}, {"honey", 1}}},
    },]]

    devilsfruitcake =
    {
        test = function(cooker, names, tags)
            return (names.pomegranate or names.pomegranate_cooked) and not tags.meat and tags.egg and tags.egg >= 2 and UncompromisingFillers(tags)
        end,
        hunger = 62.5,
        health = 60,
        sanity = -0.6,
        temperature = TUNING.HOT_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_AVERAGE,
        priority = 1,
        weight = 1,
        cooktime = 2,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = TUNING.PERISH_SLOW,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "pomegranate", 1 }, { "bird_egg", 2 } } },
    },

    liceloaf =
    {
        test = function(cooker, names, tags)
            return (tags.rice and tags.rice >= 2) and UncompromisingFillers(tags) and
                not (tags.insectoid and tags.insectoid >= 1) and not tags.inedible
        end,
        hunger = 62.5,
        health = 0,
        sanity = 0,
        priority = 30,
        weight = 1,
        cooktime = 1.2,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 15 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_LICELOAF,
        oneatenfn = function(inst, eater)
            if eater.components.hayfever and eater.components.hayfever.enabled then
                eater.components.hayfever:SetNextSneezeTime(1440)
            end
        end,
    },

    seafoodpaella =
    {
        test = function(cooker, names, tags)
            return UncompromisingFillers(tags) and tags.rice and tags.veggie and
                tags.veggie >= 2 and (names.wobster_sheller_land or tags.fish and tags.fish >= 2)
        end,
        hunger = 75,
        health = 20,
        sanity = 60,
        priority = 30,
        weight = 1,
        cooktime = 1,
        foodtype = FOODTYPE.MEAT,
        perishtime = TUNING.PERISH_FAST,
        floater = { "med", 0.05, 0.65 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_SEAFOODPAELLA,
        oneatenfn = function(inst, eater)
            if eater.components.hayfever and eater.components.hayfever.enabled then
                eater.components.hayfever:SetNextSneezeTime(1440)
            end
        end,
        card_def = { ingredients = { { "wobster_sheller_land", 1 }, { "rice1", 1 }, { "carrot", 1 } } },
    },

    simpsalad =
    {
        test = function(cooker, names, tags)
            return tags.foliage and tags.foliage > 1 and
                not (tags.frozen and tags.frozen >= 1 and tags.sweetener and tags.sweetener >= 1)
        end,
        hunger = 4.9,
        health = 1,
        sanity = 1,
        priority = 53,
        weight = 20,
        cooktime = 0.4,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 2 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
    },

    snotroast =
    {
        test = function(cooker, names, tags)
            return (names.trunk_summer or names.trunk_winter or names.trunk_cooked) and
                (names.carrot or names.carrot_cooked) and (names.potato or names.potato_cooked) and
                (names.onion or names.onion_cooked)
        end,
        hunger = 150,
        health = 3,
        sanity = 5,
        priority = 30,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.MEAT,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", nil, 0.65 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_SNOTROAST,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                eater.components.debuffable:AddDebuff("buff_largehungerslow", "buff_largehungerslow")
            end
        end,
        idlename = "idle_ground",
        card_def = { ingredients = { { "onion", 1 }, { "potato", 1 }, { "carrot", 1 }, { "trunk_summer", 1 } } },
    },

    um_ghost_fajita =
    {
        test = function(cooker, names, tags)
            return tags.meat and names.um_ghost_pepper_item and tags.veggie >= 2
        end,
        hunger = 37.5,
        health = 40,
        sanity = -10,
        priority = 10,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.MEAT,
        perishtime = 4 * TUNING.PERISH_TWO_DAY,
        oneatenfn = function(inst, eater)
            if not (eater.components.health ~= nil and eater.components.health:IsDead()) and not eater:HasTag("playerghost") then
                Ghost(eater)
                if eater.components.temperature then
                    eater.components.temperature:DoDelta(-40)
                end
            end
        end,
        floater = { "med", nil, 0.65 },
        card_def = { ingredients = { { "meat", 1 }, { "carrot", 1 }, { "um_ghost_pepper_item", 1 } } },
    },

    um_boom_tart =
    {
        test = function(cooker, names, tags)
            return names.giant_blueberry and names.giant_blueberry >= 2 and tags.sweetener and tags.sweetener >= 2
        end,
        hunger = 37.5,
        health = 3,
        sanity = 33,
        priority = 10,
        weight = 1,
        cooktime = 0.9,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 4 * TUNING.PERISH_TWO_DAY,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                eater.components.debuffable:AddDebuff("buff_boomberryattacks", "buff_boomberryattacks")
            end
        end,
        floater = { "med", nil, 0.65 },
        card_def = { ingredients = { { "giant_blueberry", 1 }, { "giant_blueberry", 1 }, { "honey", 1 } } },
    },

    um_sponge_cake =
    {
        test = function(cooker, names, tags)
            return names.um_spongeplant_item and names.um_spongeplant_item >= 2 and tags.sweetener and tags.fruit and tags.fruit >= 1
        end,
        hunger = 37.5,
        health = -3,
        sanity = 33,
        priority = 10,
        weight = 1,
        cooktime = 0.9,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 4 * TUNING.PERISH_TWO_DAY,
        oneatenfn = function(inst, eater)
            if eater.components.moisture then
                eater.components.moisture:DoDelta(-33)
            end
        end,
        floater = { "med", nil, 0.65 },
        card_def = { ingredients = { { "giant_blueberry", 1 }, { "giant_blueberry", 1 }, { "honey", 1 } } },
    },

    snowcone =
    {
        test = function(cooker, names, tags) return TUNING.DSTU.ICECROCKBLOCKER == true and ((tags.frozen and tags.frozen > 1) or (tags.frozen and names.twigs)) end,
        hunger = 9.375,
        health = 3,
        sanity = 5,
        priority = 0.5,
        weight = 0.5,
        cooktime = 0.5,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 2 * TUNING.PERISH_TWO_DAY,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_BRIEF,
        floater = { nil, 0.1, 0.6 },
    },

    stuffed_peeper_poppers =
    {
        test = function(cooker, names, tags)
            return (names.milkywhites) and (tags.monster and tags.monster >= 2) and tags.meat and
                (names.durian or names.durian_cooked) and not tags.inedible
        end,
        hunger = 37.5,
        health = -3,
        sanity = -15,
        priority = 54,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.MEAT,
        secondaryfoodtype = FOODTYPE.MONSTER,
        perishtime = 4 * TUNING.PERISH_TWO_DAY,
        floater = { "med", nil, 0.65 },
        tags = { "monstermeat" },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_STUFFED_PEEPER_POPPERS,
        oneatenfn = function(inst, eater)
            local function SpawnEyes(inst, eater)
                local x, y, z = inst.Transform:GetWorldPosition()
                local pt = inst:GetPosition()
                local speed = easing.linear(3, 7, 3, 10)
                pt.x = pt.x + math.random(-3, 3)
                pt.z = pt.z + math.random(-3, 3)

                local projectile = SpawnPrefab("eyeofterror_mini_projectile_ally")
                projectile.Transform:SetPosition(x, y, z)
                projectile:AddTag("canthit")
                projectile:AddTag("friendly")
                projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))

                if TheWorld.Map:IsAboveGroundAtPoint(pt.x, 0, pt.z) or TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z) ~= nil then
                    inst.count = 0
                    projectile.player = eater
                    projectile.components.complexprojectile:Launch(pt, inst, inst)
                else
                    if inst.count < 10 then
                        inst.count = inst.count + 1
                        inst:DoTaskInTime(0, SpawnEyes(inst, eater))
                    end

                    projectile:Remove()
                end
            end

            inst.count = 0

            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and not (eater.components.health ~= nil and eater.components.health:IsDead()) and not eater:HasTag("playerghost") then
                for k = 1, 2 do
                    inst:DoTaskInTime(0, SpawnEyes(inst, eater))
                end
            end
        end,
        card_def = { ingredients = { { "milkywhites", 1 }, { "durian", 2 } } },
    },

    theatercorn =
    {
        test = function(cooker, names, tags)
            return (
                (names.corn_cooked and names.corn_cooked >= 2) or (names.corn and names.corn >= 2) or
                (names.corn and names.corn_cooked)) and (names.butter)
        end,
        stacksize = 3,
        hunger = 37.5,
        health = 20,
        priority = 30,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 10 * TUNING.PERISH_TWO_DAY,
        floater = { "med", nil, 0.65 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_THEATERCORN,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                local x, y, z = eater.Transform:GetWorldPosition()
                local combatents = TheSim:FindEntities(x, y, z, 20, { "_combat" })
                local count = 0
                for i, v in ipairs(combatents) do
                    if v.components.combat ~= nil and v.components.combat.target ~= nil then
                        count = count + 1
                        if v:HasTag("epic") then
                            count = count + 5
                        end
                    end
                end

                if count > 0 and count <= 5 then
                    eater.tempamusetier = 1
                end

                if count > 5 and count <= 10 then
                    eater.tempamusetier = 2
                end

                if count > 10 and count <= 15 then
                    eater.tempamusetier = 3
                end

                if count > 15 then
                    eater.tempamusetier = 4
                end

                eater.components.debuffable:AddDebuff("buff_amusementcorn", "buff_amusementcorn")
                eater:DoTaskInTime(1, function(eater)
                    if eater.tempamusetier ~= nil then
                        eater.tempamusetier = nil
                    end
                end)
            end
        end,
        idlename = "ground",
        card_def = { ingredients = { { "corn", 2 }, { "butter", 1 } } },
    },

    um_deviled_eggs =
    {
        --test = function(cooker, names, tags) return tags.monster and tags.monster >= 2 and tags.egg and not tags.meat end,
        test = function(cooker, names, tags) return tags.monster and tags.egg and not (tags.meat and tags.monster > tags.egg) end,

        hunger = 18.75,
        health = -15,
        sanity = -20,
        priority = 52,
        weight = 1,
        cooktime = .5,
        foodtype = FOODTYPE.MEAT,
        secondaryfoodtype = FOODTYPE.MONSTER,
        perishtime = TUNING.PERISH_FAST,
        floater = { nil, 0.1, 0.6 },
        tags = { "monstermeat" },
    },

    viperjam =
    {
        test = function(cooker, names, tags)
            return not tags.monster and not tags.inedible and UncompromisingFillers(tags)
                and (names.viperfruit or (names.viperfruit_lesser and names.viperfruit_lesser == 3)) and names.giant_blueberry
        end,
        hunger = 37.5,
        health = 40,
        sanity = 15,
        priority = 30,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 10 * TUNING.PERISH_TWO_DAY,
        floater = { nil, 0.1, 0.6 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_VIPERJAM,
        oneatenfn = function(inst, eater)
            local function GetWorms(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local worms = TheSim:FindEntities(x, y, z, 40, { "viperlingfriend" })
                local worm_friends = {}
                for i, v in ipairs(worms) do
                    if inst.components.leader and inst.components.leader:IsFollower(v) then
                        table.insert(worm_friends, v)
                    end
                end
                for i, v in ipairs(worm_friends) do -- need specifically *that players* worms
                    SpawnPrefab("shadow_despawn").Transform:SetPosition(v.Transform:GetWorldPosition())
                    local more_time = v.components.timer:GetTimeLeft("despawn") or 0
                    v.components.timer:SetTimeLeft("despawn", 60 + more_time)
                end
                local nworms = #worm_friends
                if #worm_friends > 6 then
                    nworms = 6
                end
                return 6 - nworms
            end


            local function SpawnVipers(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local projectile = SpawnPrefab("viperprojectile")
                projectile.Transform:SetPosition(x, y, z)
                local pt = inst:GetPosition()
                pt.x = pt.x + math.random(-3, 3)
                pt.z = pt.z + math.random(-3, 3)
                local speed = easing.linear(3, 7, 3, 10)
                projectile:AddTag("canthit")
                projectile:AddTag("friendly")
                --projectile.components.wateryprotection.addwetness = TUNING.WATERBALLOON_ADD_WETNESS/2
                projectile.components.complexprojectile:SetHorizontalSpeed(speed + math.random(4, 9))
                projectile.eater = inst
                projectile.max_worms = 6
                if TheWorld.Map:IsAboveGroundAtPoint(pt.x, 0, pt.z) or TheWorld.Map:GetPlatformAtPoint(pt.x, pt.z) ~= nil then
                    inst.count = 0
                    projectile.components.complexprojectile:Launch(pt, inst, inst)
                else
                    if inst.count < 10 then
                        inst.count = inst.count + 1
                        inst:DoTaskInTime(0, SpawnVipers(inst))
                    end
                    projectile:Remove()
                end
            end

            inst.count = 0
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                local i = GetWorms(eater)
                for k = 1, i do
                    eater:DoTaskInTime(0, SpawnVipers(eater))
                end
            end
        end,
        card_def = { ingredients = { { "viperfruit", 1 }, { "giant_blueberry", 1 } } },
    },

    zaspberryparfait =
    {
        test = function(cooker, names, tags)
            return not tags.monster and not tags.inedible and UncompromisingFillers(tags)
                and (names.zaspberry or (names.zaspberry_lesser and names.zaspberry_lesser == 2)) and tags.sweetener and tags.dairy
        end,
        hunger = 37.5,
        health = 40,
        sanity = 15,
        priority = 30,
        weight = 1,
        cooktime = 1.8,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 2 * TUNING.PERISH_TWO_DAY,
        floater = { nil, 0.1, 0.6 },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_ZASPBERRYPARFAIT,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                eater.components.debuffable:AddDebuff("buff_electricretaliation", "buff_electricretaliation")
            end
        end,
        card_def = { ingredients = { { "zaspberry", 1 }, { "honey", 1 }, { "goatmilk", 1 } } },
    },




    -- [Rimeweed] -----
    um_rimeweed_spagett =
    {
        test = function(cooker, names, tags) return names.um_rimeweed_itemflower and names.um_rimeweed_itemvine and names.um_rimeweed_itemvine > 2 end,
        hunger = 62.5,
        health = 3,
        sanity = 5,
        priority = 200,
        weight = 1,
        cooktime = 1.8,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_LONG,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 3 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "um_rimeweed_itemvine", 3 }, { "um_rimeweed_itemflower", 1 } } },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_RIMEWEED_SPAGETT,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                local x, y, z = eater.Transform:GetWorldPosition()
                local iceShield = SpawnPrefab("um_ice_shield")
                iceShield:Init(eater, "swap_body", .125)

                local fx = SpawnPrefab("deer_ice_burst")
                fx.Transform:SetPosition(x, y, z)
                fx.Transform:SetScale(3, 3, 3)
                local ents = TheSim:FindEntities(x, y, z, 6, { "_health" })
                for i, ent in ipairs(ents) do
                    if ent ~= eater and ent.components.freezable then
                        ent.components.freezable:AddColdness(5)
                    end
                end
            end
        end,
    },

    um_rimeweed_tequila =
    {
        test = function(cooker, names, tags) return names.um_rimeweed_itemflower and names.ice end,
        hunger = 12.5,
        health = 3,
        sanity = 33,
        priority = 200,
        weight = 1,
        cooktime = 2,
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_LONG,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "um_rimeweed_itemflower", 1 }, { "ice", 1 } } },
        oneat_desc = STRINGS.UI.COOKBOOK.UM_RIMEWEED_TEQUILA,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) and
                not eater:HasTag("playerghost") then
                local iceShield = SpawnPrefab("um_ice_shield")
                iceShield:Init(eater, "swap_body", .125)

                eater.components.debuffable:AddDebuff("um_rimeweed_tequila_buff", "um_rimeweed_tequila_buff")
            end
        end,
    },
    um_durian_cream_marshcake =
    {
        test = function(cooker, names, tags) return (names.durian or names.durian_cooked) and tags.dairy and tags.egg and not tags.inedible end,
        hunger = 75,
        health = 12,
        sanity = 15,
        priority = 53,
        weight = 1,
        cooktime = 2,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "durian", 1 }, { "goatmilk", 1 }, { "bird_egg", 1 } } },
        oneatenfn = function(inst, eater)
            if eater and eater.components.health and eater.components.sanity then
                if TheWorld then
                    if TheWorld.state.isssummer then
                        eater.components.health:DoDelta(6, true)
                        eater.components.sanity:DoDelta(20, true)
                    elseif TheWorld.state.isautumn then
                        eater.components.health:DoDelta(12, true)
                        eater.components.sanity:DoDelta(40, true)
                    elseif TheWorld.state.iswinter then
                        eater.components.health:DoDelta(18, true)
                        eater.components.sanity:DoDelta(60, true)
                    end
                end
            end
        end,
    },
    um_chiles_en_nogada =
    {
        test = function(cooker, names, tags) return (names.pepper or names.pepper_cooked) and (names.acorn or names.acorn_cooked) and (names.pomegranate or names.pomegranate_cooked) and tags.meat and tags.meat > 0.5 end,
        hunger = 37.5,
        health = 20,
        sanity = 50,
        priority = 51,
        weight = 1,
        cooktime = 3,
        temperature = TUNING.HOT_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_LONG,
        foodtype = FOODTYPE.MEAT,
        perishtime = 10 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "pomegranate", 1 }, { "pepper", 1 }, { "acorn", 1 }, { "meat", 1 } } },
    },
    um_rice_pudding =
    {
        test = function(cooker, names, tags) return (tags.rice and tags.rice >= 2) and tags.sweetener and not tags.meat and not tags.inedible end,
        hunger = 37.5,
        health = 20,
        sanity = 15,
        priority = 66,
        weight = 1,
        cooktime = 1,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 6 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "rice1", 2 }, { "honey", 1 } } },
    },
    um_boomberrypie =
    {
        test = function(cooker, names, tags) return (names.giant_blueberry and names.giant_blueberry > 2) end, -- At least 3 giant blueberries
        hunger = 37.5,
		health = -3,
        priority = 30,
        weight = 1,
        cooktime = 2,
        foodtype = FOODTYPE.VEGGIE,
        perishtime = 5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "giant_blueberry", 1 }, { "giant_blueberry", 1 }, { "giant_blueberry", 1 } } },
        oneatenfn = BoomPieGo,
    },
}


if TUNING.DSTU.BONESTEW == "bone_appetit" then
    um_preparedfoods["um_kebab"] =
    {
        test = function(cooker, names, tags) return (tags.meat and tags.meat > 2.5) and not (tags.monster and tags.monster > 2.5) and not names.boneshard end,
        hunger = 87.5,
        health = 8,
        sanity = 20,
        priority = 29,
        weight = 1,
        cooktime = 1,
        foodtype = FOODTYPE.MEAT,
        perishtime = 7.5 * TUNING.PERISH_TWO_DAY,
        floater = { "med", 0.05, 0.65 },
        card_def = { ingredients = { { "meat", 3 } } },
    }
end


for k, v in pairs(um_preparedfoods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0
    v.build = k
    v.bank = k
    v.atlasname = "images/inventoryimages/" .. k .. ".xml"
    v.cooktime = k.cooktime
    v.overridebuild = k
    v.cookbook_atlas = "images/cookbook_" .. k .. ".xml"
    v.cookbook_tex = "cookbook_" .. k .. ".tex"
    --v.cookbook_category = "cookpot"
end


return um_preparedfoods
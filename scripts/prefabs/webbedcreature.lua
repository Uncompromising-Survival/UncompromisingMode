local function SetStage(inst, stage)
    if stage <= 3 then
        inst.AnimState:PlayAnimation(inst.anims.init)
        inst.AnimState:PushAnimation(inst.anims.idle, true)
        inst:DoTaskInTime(3, function(inst) inst.AnimState:SetTime(math.random() * 2) end)
    end
end

local function SetSmall(inst)
    if inst:HasTag("mediumcocoon") then
        inst:RemoveTag("mediumcocoon")
    end
    if inst:HasTag("largecocoon") then
        inst:RemoveTag("largecocoon")
    end
    inst:AddTag("smallcocoon")
    inst.MiniMapEntity:SetIcon("webbedcreature_small_minimap.tex")
    inst.AnimState:SetBank("wackycocoonsmall")
    inst.AnimState:SetBuild("wackycocoonsmall")
    inst.DynamicShadow:SetSize(3.5, 2.5)
    for i = 1, 2 do
        inst.components.lootdropper:AddChanceLoot("silk", 1)
    end
    inst.anims = {
        hit = "hit_small",
        idle = "idle_small",
        kill = "break_small",
        init = "appear_small",
    }
    SetStage(inst, 1)
end

local function SetMedium(inst)
    if inst:HasTag("smallcocoon") then
        inst:RemoveTag("smallcocoon")
    end
    if inst:HasTag("largecocoon") then
        inst:RemoveTag("largecocoon")
    end
    inst:AddTag("mediumcocoon")
    inst.MiniMapEntity:SetIcon("webbedcreature_medium_minimap.tex")
    inst.DynamicShadow:SetSize(4, 3.5)
    for i = 1, 4 do
        inst.components.lootdropper:AddChanceLoot("silk", 1)
    end
    inst.anims = {
        hit = "hit_medium",
        idle = "idle_medium",
        kill = "break_medium",
        init = "appear_medium",
    }
    SetStage(inst, 2)
end

local function SetLarge(inst)
    if inst:HasTag("smallcocoon") then
        inst:RemoveTag("smallcocoon")
    end
    if inst:HasTag("mediumcocoon") then
        inst:RemoveTag("mediumcocoon")
    end
    inst:AddTag("largecocoon")
    inst.MiniMapEntity:SetIcon("webbedcreature_large_minimap.tex")
    inst.DynamicShadow:SetSize(5, 4)
    for i = 1, 6 do
        inst.components.lootdropper:AddChanceLoot("silk", 1)
    end
    inst.anims = {
        hit = "hit_large",
        idle = "idle_large",
        kill = "break_large",
        init = "appear_large",
    }
    SetStage(inst, 3)
end

local function AddChanceLoot(inst, prefab, chance, amount)
    for i = 1, (amount or 1) do
        inst.components.lootdropper:AddChanceLoot(prefab, chance or 1)
    end
end

local cocoontable = {
    [1] = {
        creature = "beeguard",
        lootfn = function(inst)
            AddChanceLoot(inst, "honeycomb", nil, 2)
            AddChanceLoot(inst, "honey", nil, 5)
            AddChanceLoot(inst, "honey", .5)
            AddChanceLoot(inst, "stinger", .1)
            AddChanceLoot(inst, "royal_jelly")
        end,
        cocoonsize = SetSmall,
        cocoonname = "Buggy",
    },
    [2] = {
        creature = "pied_rat",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat", nil, 2)
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "rat_tail", nil, 2)
        end,
        cocoonsize = SetSmall,
        cocoonname = "Grotesque",
    },
    [3] = {
        creature = "eyeofterror_mini",
        lootfn = function(inst)
            AddChanceLoot(inst, "milkywhites", nil, 2)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "monstermeat", .5)
        end,
        cocoonsize = SetSmall,
        cocoonname = "Grotesque",
    },
    [4] = {
        creature = "catcoon",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "coontail", nil, 4)
        end,
        cocoonsize = SetSmall,
        cocoonname = "Hairy",
    },
    [5] = {
        creature = "lightninggoat",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .25)
            AddChanceLoot(inst, "lightninggoathorn", nil, 2)
        end,
        cocoonsize = SetSmall,
        cocoonname = "Hairy",
    },
    [6] = {
        creature = "bishop",
        lootfn = function(inst)
            AddChanceLoot(inst, "trinket_6", nil, 2)
        end,
        cocoonsize = SetSmall,
        cocoonname = "Hardened",
    },
    [7] = {
        creature = "merm",
        lootfn = function(inst)
            AddChanceLoot(inst, "froglegs", .5)
            AddChanceLoot(inst, "tentaclespots", nil, 2)
        end,
        cocoonsize = SetMedium,
        cocoonname = "Leathery",
    },
    [8] = {
        creature = "pigman",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "pigskin")
            AddChanceLoot(inst, "tophat")
            AddChanceLoot(inst, "pig_token", .1)
        end,
        cocoonsize = SetMedium,
        cocoonname = "Leathery",
    },
    [9] = {
        creature = "mossling",
        cocoonsize = SetMedium,
        cocoonname = "Feathery",
    },
    [10] = {
        creature = "tallbird",
        lootfn = function(inst)
            AddChanceLoot(inst, "tallbirdegg")
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "feather_crow", nil, 2)
            AddChanceLoot(inst, "feather_crow", .25)
            AddChanceLoot(inst, "feather_robin", nil, 2)
            AddChanceLoot(inst, "feather_robin", .25)
            AddChanceLoot(inst, "feather_robin_winter", nil, 2)
            AddChanceLoot(inst, "feather_robin_winter", .25)
            AddChanceLoot(inst, "feather_canary", nil, 2)
            AddChanceLoot(inst, "feather_canary", .25)
        end,
        cocoonsize = SetMedium,
        cocoonname = "Feathery",
    },
    [11] = {
        creature = "deer",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "deer_antler")
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = SetMedium,
        cocoonname = "Hairy",
    },
    [12] = {
        creature = "krampus",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "charcoal", nil, 2)
            AddChanceLoot(inst, "boneshard")
            AddChanceLoot(inst, "krampus_sack", .05)
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = SetMedium,
        cocoonname = "Grotesque",
    },
    [13] = {
        creature = "snapdragon",
        lootfn = function(inst)
            AddChanceLoot(inst, "plantmeat", .5)
            AddChanceLoot(inst, "livinglog", nil, 3)
            AddChanceLoot(inst, "whisperpod")
            AddChanceLoot(inst, "cactus_flower", nil, 3)
            AddChanceLoot(inst, "cactus_flower", .5)
        end,
        cocoonsize = SetMedium,
        cocoonname = "Leafy",
    },
    [14] = {
        creature = "walrus",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "walrus_tusk")
            AddChanceLoot(inst, "um_bear_trap_equippable_tooth", .5)
        end,
        cocoonsize = SetMedium,
        cocoonname = "Leathery",
    },
    [15] = {
        creature = "lordfruitfly",
        lootfn = function(inst)
            AddChanceLoot(inst, "plantmeat", .5)
            AddChanceLoot(inst, "seeds", nil, 4)
            AddChanceLoot(inst, "seeds", .25, 4)
        end,
        cocoonsize = SetLarge,
        cocoonname = "Buggy",
    },
    [16] = {
        creature = "spiderqueen",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "monstermeat", .5)
            AddChanceLoot(inst, "silk")
            AddChanceLoot(inst, "silk", .5)
        end,
        cocoonsize = SetLarge,
        cocoonname = "Grotesque",
    },
    [17] = {
        creature = "beefalo",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "beefalowool")
            AddChanceLoot(inst, "beefalowool", .5)
            AddChanceLoot(inst, "horn")
            AddChanceLoot(inst, "poop", .5)
        end,
        cocoonsize = SetLarge,
        cocoonname = "Hairy",
    },
    [18] = {
        creature = "warg",
        lootfn = function(inst)
            AddChanceLoot(inst, "monstermeat")
            AddChanceLoot(inst, "houndstooth", nil, 2)
            AddChanceLoot(inst, "houndstooth", .5)
            AddChanceLoot(inst, "boneshard")
            AddChanceLoot(inst, "boneshard", .5)
            AddChanceLoot(inst, "bluegem")
            AddChanceLoot(inst, "redgem")
        end,
        cocoonsize = SetLarge,
        cocoonname = "Hairy",
    },
    [19] = {
        creature = "spat",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat")
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "steelwool", nil, 2)
            AddChanceLoot(inst, "steelwool", .5)
            AddChanceLoot(inst, "phlegm", nil, 2)
        end,
        cocoonsize = SetLarge,
        cocoonname = "Hardened",
    },
    [20] = {
        creature = "koalefant_summer",
        lootfn = function(inst)
            AddChanceLoot(inst, "meat", nil, 3)
            AddChanceLoot(inst, "meat", .5)
            AddChanceLoot(inst, "poop", .5)
        end,
        cocoonsize = SetLarge,
        cocoonname = "Leathery",
    },
}
local function OnKilled(inst)
    inst.AnimState:PlayAnimation(inst.anims.kill)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")
    local creature
    if inst.size then
        for num, mob in pairs(cocoontable) do
            if inst.size == num then
                creature = mob.creature
                if mob.lootfn then
                    mob.lootfn(inst)
                end
            end
        end
        inst.components.lootdropper:DropLoot()
        --[[if creature and not creature == "spiderqueen" then
            inst.components.lootdropper:SetChanceLootTable('webbedcreature_'..creature)
        end]]
        local deadcreature = SpawnPrefab(creature)
        deadcreature.Transform:SetPosition(x, y, z)
        if creature == "spiderqueen" then
            deadcreature:AddTag("nodecomposepls")
        end
        deadcreature:DoTaskInTime(0, function()
            if deadcreature.brain then
                deadcreature.brain:Stop()
            end
            deadcreature.components.health:Kill()
        end)
    else
        local deadcreature = SpawnPrefab("pigman")
        deadcreature.Transform:SetPosition(x, y, z)
        deadcreature.components.health:Kill()
    end
    local spawner = SpawnPrefab("webbedcreaturespawner")
    spawner.Transform:SetPosition(x, y, z)
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spidernest_LP", "loop")
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function onsave(inst, data)
    if inst.size then
        data.size = inst.size
    else
        data.size = math.random(1, 20)
    end
end

local function onload(inst, data)
    if data and data.size then
        inst.size = data.size
    else
        inst.size = math.random(1, 20)
    end
end

local function SetSize(inst)
    for num, mob in pairs(cocoontable) do
        if inst.size == num then
            if mob.cocoonsize then
                mob.cocoonsize(inst)
            end
            inst.components.named:SetName(mob.cocoonname.." Cocoon")
        end
    end
end

local function PlayHitAnimations(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
    inst.AnimState:PlayAnimation(inst.anims.hit)
    inst.AnimState:PushAnimation(inst.anims.idle)
end

local function NoEpics(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheSim:FindEntities(x, y, z, 50, {"epic"}, {"hoodedwidow", "smallepic"})
end

local function Regen(inst, data)
    ---TheNet:Announce("attacked")
    local attacker = data.attacker
    if attacker then
        if not attacker:HasTag("player") then
            if attacker.components.combat and attacker.components.combat.target then
                attacker.components.combat:DropTarget()
            end
        end
        if not inst.components.health:IsDead() and not attacker:HasTag("hoodedwidow") then
            --TheNet:Announce("advancing")
            local widowweb = FindEntity(inst, 50, function(guy) return guy:HasTag("widowweb") end)
            if widowweb and attacker:HasTag("player") and #NoEpics(inst) == 0 then
                --TheNet:Announce("tellingwidow")
                widowweb:SpawnInvestigators(attacker)
            end
            PlayHitAnimations(inst)
            if attacker:HasTag("widowsgrasp") and not (attacker.components.rider and attacker.components.rider:IsRiding()) then
                --inst.components.health:Kill()
            elseif attacker:HasTag("player") and not attacker:HasTag("mime") and not attacker:HasTag("widowsgrasp") then
                attacker.components.talker:Say(GetString(attacker.prefab, "WEBBEDCREATURE"))
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    --inst.MiniMapEntity:SetIcon("hoodedwidow_map.tex")

    inst.AnimState:SetBank("wackycocoons")
    inst.AnimState:SetBuild("wackycocoons")
    inst.AnimState:PlayAnimation("idle_small", true)

    inst:AddTag("noepicmusic")
    inst:AddTag("webbedcreature")
    --inst:AddTag("structure")
    --inst:AddTag("noauradamage")
    --inst:AddTag("notarget")
    inst:AddTag("houndfriend")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("queensstuff")
    inst:AddTag("companion")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1000000)
    inst.components.health.absorb = 1
    --inst.components.health.invincible = true
    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", Regen)
    inst:ListenForEvent("death", OnKilled)

    inst:AddComponent("lootdropper")
    inst:AddComponent("named")

    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")
    inst:DoTaskInTime(0, SetSize)
    MakeSnowCovered(inst)
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.size = math.random(1, 20)
    
    inst.PlayHitAnimations = PlayHitAnimations
    return inst
end

local function on_anim_over(inst)
    if inst.components.mine.issprung then
        return
    end

    if inst.froze then
        if inst.Harvestable then
            inst.AnimState:PushAnimation("idle_frozen", true)
        else
            inst.AnimState:PushAnimation("trap_idle", true)
        end
    else
        local random_value = math.random()
        if random_value < 0.4 then
            inst.AnimState:PushAnimation("idle_2")
            -- inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/idle")
            inst.AnimState:PushAnimation("idle", true)
        elseif random_value < 0.8 then
            inst.AnimState:PushAnimation("idle_3")
            -- inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/idle")
            inst.AnimState:PushAnimation("idle", true)
        end
    end
end

local function on_anim_over(inst)
    inst.AnimState:PlayAnimation(inst.category..(math.random() > 0.95 and "_twitch" or ""))
end

local function decorsave(inst, data)
    if data then
        data.category = inst.category
    end
end

local function decorload(inst, data)
    if data and data.category then
        inst.category = data.category
        inst.AnimState:PlayAnimation(inst.category)
    end
end

local function fndecor()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cocoondecor")
    inst.AnimState:SetBuild("cocoondecor")

    inst:AddTag("webdecor")
    inst:AddTag("antlion_sinkhole_blocker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", on_anim_over)
    inst.OnSave = decorsave
    inst.OnLoad = decorload
    return inst
end

return Prefab("webbedcreature", fn),
    Prefab("widowdecor", fndecor)
require "webbedcreatureloot"

local function AddChanceLoot(inst, loot, chance, amount)
    for i = 1, amount do
        inst.components.lootdropper:AddChanceLoot(type(loot) == "function" and loot() or loot, chance)
    end
end

function SpawnDurabilityLoot(inst, loot, amount, chance)
    for i = 1, amount do
        if chance >= 1 or math.random() < chance then
            local item = inst.components.lootdropper:SpawnLootPrefab(type(loot) == "function" and loot() or loot, inst:GetPosition())
            if item == nil then
                print("Item "..(type(loot) == "function" and loot() or loot).." is NOT a valid prefab!")
                return
            end

            local itemcomponent = item.components.finiteuses or item.components.fueled or item.components.perishable or item.components.armor

            if itemcomponent then
                itemcomponent:SetPercent(math.random(25, 100) / 100)
            else
                print(type(loot) == "function" and loot() or loot, " has no durability-esque component in webbedcreature.lua!")
            end
        end
    end
end

function LootFn(inst, loot, fn)
    if fn then
        fn(inst.components.lootdropper:SpawnLootPrefab(type(loot) == "function" and loot() or loot, inst:GetPosition()), inst)
    end
end

local function SetStage(inst, stage)
    if stage <= 3 then
        inst.AnimState:PlayAnimation(inst.anims.init)
        inst.AnimState:PushAnimation(inst.anims.idle, true)
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationNumFrames() * FRAMES, function(inst) inst.AnimState:SetTime(math.random() * 2) end)
    end
end

local function GetCocoonFeatures(size)
    local shadowx, shadowy, silk, stage = 5, 4, 6, 3
    if size == 0 then
        shadowx, shadowy, silk, stage = 3.5, 2.5, 2, 1
    elseif size == 1 then
        shadowx, shadowy, silk, stage = 4, 3.5, 4, 2
    end
    return shadowx, shadowy, silk, stage
end

local function GetSizeName(size)
    return size == 0 and "small" or size == 1 and "medium" or "large"
end

local function SetCocoonSize(inst, size)
    if size ~= 0 and inst:HasTag("smallcocoon") then
        inst:RemoveTag("smallcocoon")
    end
    if size ~= 1 and inst:HasTag("mediumcocoon") then
        inst:RemoveTag("mediumcocoon")
    end
    if size ~= 2 and inst:HasTag("largecocoon") then
        inst:RemoveTag("largecocoon")
    end
    local shadowx, shadowy, silk, stage = GetCocoonFeatures(size)
    inst:AddTag(GetSizeName(size).."cocoon")

    inst.MiniMapEntity:SetIcon("webbedcreature_"..GetSizeName(size).."_minimap.tex")
    inst.DynamicShadow:SetSize(shadowx, shadowy)
    for i = 1, silk do
        inst.components.lootdropper:AddChanceLoot("silk", 1)
    end
    inst.anims = {
        hit = "hit_"..GetSizeName(size),
        idle = "idle_"..GetSizeName(size),
        kill = "break_"..GetSizeName(size),
        init = "appear_"..GetSizeName(size),
    }
    SetStage(inst, stage)
end


---sets the data of the cocoonn.
---@param inst any The instance of the cocooon
local function SetUpCocoon(inst)
    if not inst.cocoon_creature then
        local is_character = math.random() > .95 --roughly same chance as before.
        if is_character then
            inst.cocoon_creature = COCOON_CHARACTERS[math.random(#COCOON_CHARACTERS)]
            inst.cocoon_data = COCOON_DEFS.CHARACTER[inst.cocoon_creature]
            inst.cocoon_data.size = 1
            inst.cocoon_data.name = "Shrouded"
        elseif IsIslandWorld() then
            inst.cocoon_creature = COCOON_CREATURES_SHIPWRECKED[math.random(#COCOON_CREATURES_SHIPWRECKED)]
            inst.cocoon_data = COCOON_DEFS.SHIPWRECKED[inst.cocoon_creature]
        else
            inst.cocoon_creature = COCOON_CREATURES_DEFAULT[math.random(#COCOON_CREATURES_DEFAULT)]
            inst.cocoon_data = COCOON_DEFS.DEFAULT[inst.cocoon_creature]
        end
    end

    inst.components.named:SetName(inst.cocoon_data.name.." Cocoon")
    SetCocoonSize(inst, inst.cocoon_data.size)
end

local function OnKilled(inst)
    inst.AnimState:PlayAnimation(inst.anims.kill)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.SoundEmitter:KillSound("loop")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_destroy")

    --creature
    if not table.contains(COCOON_CHARACTERS, inst.cocoon_creature) then
        local deadcreature = SpawnPrefab(inst.cocoon_creature)
        deadcreature.Transform:SetPosition(x, y, z)
        deadcreature:DoTaskInTime(0, function()
            if deadcreature.brain then deadcreature.brain:Stop() end
            deadcreature.components.health:Kill()
        end)
    else
        SpawnPrefab("skeleton").Transform:SetPosition(x, y, z)
    end

    --spawn loot
    if inst.cocoon_data.loot then
        for k, loot in ipairs(inst.cocoon_data.loot) do
            if not loot.use_durability or not loot.lootfn then
                AddChanceLoot(inst, loot.prefab, loot.chance, loot.amount)
            end
            if loot.use_durability then
                SpawnDurabilityLoot(inst, loot.prefab, loot.amount, loot.chance)
            end
            if loot.lootfn then
                LootFn(inst, loot.prefab, loot.lootfn)
            end
        end
    end

    inst.components.lootdropper:DropLoot()

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
    data.cocoon_creature = inst.cocoon_creature
end

local function onload(inst, data)
    if data then
        inst.cocoon_creature = data.cocoon_creature
        inst.cocoon_data = COCOON_DEFS.DEFAULT[inst.cocoon_creature] or COCOON_DEFS.SHIPWRECKED[inst.cocoon_creature]
            or COCOON_DEFS.CHARACTER[inst.cocoon_creature]
    end
end

local function PlayHitAnimations(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spiderLair_hit")
    inst.AnimState:PlayAnimation(inst.anims.hit)
    inst.AnimState:PushAnimation(inst.anims.idle)
end

local function NoEpics(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheSim:FindEntities(x, y, z, 50, { "epic" }, { "hoodedwidow", "smallepic" })
end

local function Regen(inst, data)
    local attacker = data.attacker
    if attacker then
        if not attacker:HasTag("player") and attacker.components.combat and attacker.components.combat.target then
            attacker.components.combat:DropTarget()
        end
        if not inst.components.health:IsDead() and not attacker:HasTag("hoodedwidow") then
            local widowweb = FindEntity(inst, 50, function(guy) return guy:HasTag("widowweb") end)
            if widowweb and attacker:HasTag("player") and #NoEpics(inst) == 0 then
                widowweb:SpawnInvestigators(attacker)
            end
            inst:PlayHitAnimations()
            if attacker:HasTag("player") and not attacker:HasTag("mime") and (not attacker:HasTag("widowsgrasp")
                    or (attacker.components.rider and attacker.components.rider:IsRiding())) then
                attacker.components.talker:Say(GetString(attacker.prefab, "WEBBEDCREATURE"))
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local network = inst.entity:AddNetwork()
    local shadow = inst.entity:AddDynamicShadow()
    local sound = inst.entity:AddSoundEmitter()
    local minimap = inst.entity:AddMiniMapEntity()

    --minimap:SetIcon("hoodedwidow_map.tex")

    anim:SetBank("wackycocoons")
    anim:SetBuild("wackycocoons")
    --anim:PlayAnimation("idle_small", true)

    inst:AddTag("noepicmusic")
    inst:AddTag("webbedcreature")
    --inst:AddTag("structure")
    --inst:AddTag("noauradamage")
    --inst:AddTag("notarget")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("queensstuff")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("ignorewalkableplatformdrowning")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    local health = inst:AddComponent("health")
    health:SetMaxHealth(300)
    health:SetMinHealth(1)
    health:SetAbsorptionAmount(1)
    health:StartRegen(300, .1)
    --health.invincible = true

    inst:AddComponent("combat")
    inst:ListenForEvent("attacked", Regen)
    inst:ListenForEvent("death", OnKilled)

    inst:AddComponent("lootdropper")
    inst:AddComponent("named")

    MakeLargePropagator(inst)

    inst:AddComponent("inspectable")

    MakeSnowCovered(inst)
    inst:DoTaskInTime(0, SetUpCocoon)
    inst.PlayHitAnimations = PlayHitAnimations
    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    return inst
end

local function on_anim_over(inst)
    inst.AnimState:PlayAnimation(inst.category..(math.random() > .95 and "_twitch" or ""))
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
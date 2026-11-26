local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("ANIM", "anim/wathom.zip"),
    Asset("ANIM", "anim/wathom_shadow.zip"),
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUNDPACKAGE", "sound/wathomcustomvoice.fev"),
    Asset("SOUND", "sound/wathomcustomvoice.fsb")
}

-- Character stats.
TUNING.WATHOM_HEALTH = 225
TUNING.WATHOM_HUNGER = 120
TUNING.WATHOM_SANITY = 120

local function VetCurseCheck(inst)
    local sanity = inst.components.sanity
    if not sanity then return end
    if inst:HasTag("vetcurse") then
        sanity:EnableLunacy(sanity:GetPercent() > .5 or false, "vetcurse")
    elseif sanity._lunacy_sources._modifiers[inst] and sanity._lunacy_sources._modifiers[inst].modifiers["vetcurse"] then
        sanity:EnableLunacy(false, "vetcurse")
    end
end

local function ToggleUniqueVetCurse(inst, toggle)
    if toggle then
        if not inst.um_wathom_vetcurse then
            inst.um_wathom_vetcurse = inst:DoPeriodicTask(0, VetCurseCheck)
        end
    else
        if inst.um_wathom_vetcurse then
            inst.um_wathom_vetcurse:Cancel()
            inst.um_wathom_vetcurse = nil
        end
        local sanity = inst.components.sanity
        sanity:EnableLunacy(false, "vetcurse")
    end
end

local function HasSkill(inst,name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WATHOM
end

local prefabs = FlattenTree(start_inv, true)

local function TurnOffShadowForm(inst)
    inst.AnimState:SetBuild("wathom")
    inst:RemoveEventCallback("animqueueover", TurnOffShadowForm)
end

local function UpdateCarnage(inst,killed)
    if inst:HasTag("amped") and killed then
        if inst.carnage_multiplier == 0 then
            inst.carnage_multiplier = 1 -- Start it off stronger
        else
            inst.carnage_multiplier = math.clamp(inst.carnage_multiplier + 0.5,1.5,3)
        end
    else
        inst.carnage_multiplier = 0
    end

    if inst.carnage_multiplier > 0 and not inst.carnage_fx then
        inst.carnage_fx = SpawnPrefab("tophat_shadow_fx")
		inst.carnage_fx.entity:SetParent(inst.entity)
		inst.carnage_fx.Follower:FollowSymbol(inst.GUID, "torso", 0, 100, 0)
    elseif inst.carnage_multiplier == 0 and inst.carnage_fx then
        inst.carnage_fx:Remove()
        inst.carnage_fx = nil
    end

    if inst.carnage_multiplier > 0 and inst.carnage_fx then
        local scale = 0.5 + (inst.carnage_multiplier-1)/2
        inst.carnage_fx.Transform:SetScale(scale,scale,scale)
    end
end

local function ToggleUndeathState(inst, toggle,fake)
    if toggle then
        if not inst:HasTag("playerghost") then
            inst.AnimState:SetBuild("wathom_shadow")
        end
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("shadow_shield1").Transform:SetPosition(x, y, z)
        --inst.components.talker:Say("DEATH, REFUSED!", nil, true)
        inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/shadowbark")

        if not (inst.components.health and inst.components.health:IsDead()) then
            inst.sg:GoToState("wathombark_shadow")
            inst.components.health.invincible = true

            inst:DoTaskInTime(1, function() inst.components.health.invincible = false end)
        end
        inst.components.adrenaline:SetPercent(1)
        inst.helpimleaking = inst:DoPeriodicTask(0.125, function(inst)
            if inst:HasTag("amped") then
                local x, y, z = inst.Transform:GetWorldPosition()
                local xoffset = math.random(-10, 10) / 10
                local zoffset = math.random(-10, 10) / 10
                --SpawnPrefab("minotaur_blood"..math.random(3)).Transform:SetPosition(x + xoffset, y, z + zoffset)
                SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + xoffset, y, z + zoffset)
            end
        end)
    else
        if inst.helpimleaking ~= nil then
            inst.helpimleaking:Cancel()
            inst.helpimleaking = nil
        end

        --if not inst:HasTag("playerghost") then
        inst:ListenForEvent("animqueueover", TurnOffShadowForm)
        --end
    end
end

local function HealingGlutton(inst)
    local health = inst.components.health
    if health then
        local current = health.currenthealth
        if current < health.maxhealth then
            local hunger_mod = 8
            if current == health:GetMaxWithPenalty() then
                health:DeltaPenalty(-1/TUNING.WATHOM_HEALTH) 
                hunger_mod = 2 + hunger_mod        
            end
            health:DoDelta(1)
            if not inst.wathom_is_hungy_active then
                inst.wathom_is_hungy_active = true
                inst.components.hunger.burnratemodifiers:RemoveModifier(inst)
                inst.components.hunger.burnratemodifiers:SetModifier(inst, hunger_mod)
            end
        else -- Full health, return to normal AMPED regeneration rate
            if inst.wathom_is_hungy_active then
                inst.wathom_is_hungy_active = nil
                inst.components.hunger.burnratemodifiers:RemoveModifier(inst)
                inst.components.hunger.burnratemodifiers:SetModifier(inst, 6)
            end       
        end
    end
end

-- Stalker 4 visuals and collisions
local function Shadow(inst)
    inst.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
    inst.Physics:ClearCollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
    inst.Physics:ClearCollidesWith(COLLISION.FLYERS)
    inst.AnimState:SetMultColour(0,0,0,1)
    --local fx = SpawnPrefab("oldager_become_older_fx") -- FX Opportunity
    --fx.entity:SetParent(inst.entity)
end

local function UnShadow(inst)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.FLYERS)
    inst.AnimState:SetMultColour(1,1,1,1)
    --local fx = SpawnPrefab("oldager_become_younger_front_fx")
    --fx.entity:SetParent(inst.entity)
end

local function NewAmpHungy(inst)
    local current = inst.components.hunger.current
    if current < 100 and inst.wathom_is_hungy_active then
        inst.wathom_is_hungy_active = nil
        inst.components.hunger.burnratemodifiers:RemoveModifier(inst)
        inst.components.hunger.burnratemodifiers:SetModifier(inst, 6)
    elseif not inst.wathom_is_hungy_active then
        inst.wathom_is_hungy_active = true
        inst.components.hunger.burnratemodifiers:RemoveModifier(inst)
        inst.components.hunger.burnratemodifiers:SetModifier(inst, 12)
    end
end

local function UnAmp(inst)
    if HasSkill(inst,"stalker_4") then
        UnShadow(inst)
    end

    if HasSkill(inst,"glutton_4") then
        inst:RemoveEventCallback("hungerdelta",NewAmpHungy)
    end
    inst.components.hunger.burnratemodifiers:RemoveModifier(inst)
    
    inst:RemoveTag("amped") -- Party's over.
    inst.components.combat.attackrange = 2
    inst.AmpDamageTakenModifier = TUNING.DSTU.WATHOM_AMPED_VULNERABILITY

    inst.components.adrenaline:SetAmped(false)
    if inst.helpimleaking ~= nil then
        inst.helpimleaking:Cancel()
        inst.helpimleaking = nil
    end
    if inst:HasTag("deathamp") then
        inst:RemoveTag("deathamp")

        local bed = inst.components.sleepingbaguser and inst.components.sleepingbaguser.bed
        if bed and bed.components.sleepingbag then
            bed.components.sleepingbag:DoWakeUp()
        end

        if not (inst.components.health and inst.components.health:IsDead()) then
            if HasSkill(inst,"ancient_terror_3") then
                inst.components.health.currenthealth = 10
            else
                inst.components.health:DoDelta(-225, nil, "deathamp")
            end
        end
    end

    -- AMP is over, lose your carnage multiplier.
    if HasSkill(inst,"rampage_4") then
        UpdateCarnage(inst,false)
    end 
    
    -- Cancel Regeneration from devour_4
    if inst.devour_regen then
        inst.devour_regen:Cancel()
        inst.devour_regen = nil
    end

    if inst.afterImages then
        inst.afterImages:Cancel()
        inst.afterImages = nil
    end
end

local function TellDropAllTargetsAndResetAmbushes(inst)
    local x,y,z = inst.Transform:GetWorldPosition()

    -- Drop me as a target
    local ents = TheSim:FindEntities(x,y,z,64,{"_combat"})
    for i,v in ipairs(ents) do
        if v.components.combat.target and v.components.combat.target == inst then
            v.components.combat:DropTarget()
        end
        if v.wathom_shouldnt_ambush == true then
            v.wathom_shouldnt_ambush = nil
        end
    end

    inst.components.hunger.burnratemodifiers:SetModifier(inst, 18) -- Absurd drain for effective immunity

    Shadow(inst)
end


local function Amp(inst)
    if not inst:HasTag("amped") then
        inst.components.hunger.burnratemodifiers:SetModifier(inst, 6)

        inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/ampedbark")
        inst.components.combat.attackrange = 7 -- These values are for when Wathom's at 100 Adrenaline, so he should be Amping Up right now.
        
        inst:AddTag("amped")
        inst.components.adrenaline:SetAmped(true)
        


        -- Periodic FX
        inst.helpimleaking = inst:DoPeriodicTask(0.33, function(inst)
            if inst:HasTag("amped") then
                local x, y, z = inst.Transform:GetWorldPosition()
                local xoffset = math.random(-10, 10) / 10
                local zoffset = math.random(-10, 10) / 10
                --SpawnPrefab("minotaur_blood"..math.random(3)).Transform:SetPosition(x + xoffset, y, z + zoffset)
                SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + xoffset, y, z + zoffset)
            end
        end)


        if HasSkill(inst,"devour_4") then
            inst.devour_regen = inst:DoPeriodicTask(1,HealingGlutton)
        end

        if HasSkill(inst,"glutton_4") then
            inst:ListenForEvent("hungerdelta",NewAmpHungy)
        end

        if HasSkill(inst,"stalker_4") then
            TellDropAllTargetsAndResetAmbushes(inst)
        end


        -- Leaving this here, I don't kno what it would have done prior.
        --[[
        if not (inst.components.health and inst.components.health:IsDead()) then
            --inst.sg:GoToState("wathombark")
            inst.components.health.invincible = true
            inst:DoTaskInTime(1, function() inst.components.health.invincible = false end)
        end
        ]]
        
        --AfterImage FX for hyper amp
        if HasSkill(inst,"hyper_4") then
            inst.afterImages = inst:DoPeriodicTask(0.5,function(inst)
                local animPercent = inst.AnimState:GetCurrentAnimationTime() / inst.AnimState:GetCurrentAnimationLength()
                local fx = SpawnPrefab("um_wathom_trace")
                fx.Start(fx,inst, 0.6, inst.sg.statemem.animName, animPercent, 0.175)
            end)
        end

    end
end

-- When the character is revived from human
local function onbecamehuman(inst)
    -- Set speed when not a ghost (optional)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wathom_speed_mod", 1)
    UnAmp(inst)
    --inst.AnimState:SetBuild("wathom")
    inst.components.adrenaline:SetPercent(0)
end

local function onbecameghost(inst)
    -- Remove speed modifier when becoming a ghost
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wathom_speed_mod")
    UnAmp(inst)
    inst.components.adrenaline:SetPercent(0)
end

-------------------------------------------

local magic_hands = {"nightsword","batbat","firestaff","icestaff","telestaff"}
local magic_armor = {"armor_sanity","armorslurper","amulet","blueamulet","purpleamulet"}
--local magic_helmets = {} -- No T1-2 Magic helmets are in the game....

local artifact_hands = {"ruins_bat","multitool_axe_pickaxe","orangestaff","yellowstaff"}
local artifact_armor = {"armorruins","orangeamulet","yellowamulet"}
local artifact_helmets = {"ruinshat"} 

local function SapTask(inst)
    local hands = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local chest = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local hat = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if HasSkill(inst,"wathom_magics") and inst:HasTag("amped") then
        for i,v in ipairs(magic_armor) do
            if chest and v == chest.prefab then
                if chest.components.fueled and chest.components.fueled:GetPercent() < 1 then
                    local maxfuel = chest.components.fueled.maxfuel
                    chest.components.fueled:DoDelta(0.005*maxfuel)
                end
                if chest.components.finiteuses and chest.components.finiteuses:GetPercent() < 1  then
                    local maxuses = chest.components.finiteuses.total
                    chest.components.finiteuses:Use(-0.005*maxuses)
                end
                if chest.components.armor and chest.components.armor:GetPercent() < 1 then
                    local maxfuel = chest.components.armor.maxcondition
                    chest.components.armor:Repair(0.005*maxfuel)
                end    
            end
        end
        for i,v in ipairs(magic_hands) do
            if hands and v == hands.prefab then
                if hands.components.fueled and hands.components.fueled:GetPercent() < 1 then
                    local maxfuel = hands.components.fueled.maxfuel
                    hands.components.fueled:DoDelta(0.005*maxfuel)
                end
                if hands.components.finiteuses and hands.components.finiteuses:GetPercent() < 1  then
                    local maxuses = hands.components.finiteuses.total
                    hands.components.finiteuses:Use(-0.005*maxuses)
                end
            end
        end        
        -- for i,v in ipairs(magic_helmets) do
            -- if v == hat then
                -- if hat.components.fueled and hat.components.fueled:GetPercent() < 1 then
                    -- local maxfuel = hat.components.fueled.maxfuel
                    -- hat.components.fueled:DoDelta(0.005*maxfuel)
                -- end
                -- if hat.components.finiteuses and hat.components.finiteuses:GetPercent() < 1  then
                    -- local maxuses = hat.components.finiteuses.total
                    -- hat.components.finiteuses:Use(-0.005*maxuses)
                -- end
                -- if hat.components.armor and hat.components.armor:GetPercent() < 1 then
                    -- local maxfuel = hat.components.armor.maxcondition
                    -- hat.components.armor:Repair(0.005*maxfuel)
                -- end    
            -- end
        -- end            
    end    
    if HasSkill(inst,"wathom_artifacts") and inst:HasTag("amped") then
        for i,v in ipairs(artifact_armor) do
            if chest and v == chest.prefab then
                if chest.components.fueled and chest.components.fueled:GetPercent() < 1 then
                    local maxfuel = chest.components.fueled.maxfuel
                    chest.components.fueled:DoDelta(0.005*maxfuel)
                end
                if chest.components.finiteuses and chest.components.finiteuses:GetPercent() < 1  then
                    local maxuses = chest.components.finiteuses.total
                    chest.components.finiteuses:Use(-0.005*maxuses)
                end
                if chest.components.armor and chest.components.armor:GetPercent() < 1 then
                    local maxfuel = chest.components.armor.maxcondition
                    chest.components.armor:Repair(0.005*maxfuel)
                end    
            end
        end
        for i,v in ipairs(artifact_hands) do
            if hands and v == hands.prefab then
                if hands.components.fueled and hands.components.fueled:GetPercent() < 1 then
                    local maxfuel = hands.components.fueled.maxfuel
                    hands.components.fueled:DoDelta(0.005*maxfuel)
                end
                if hands.components.finiteuses and hands.components.finiteuses:GetPercent() < 1  then
                    local maxuses = hands.components.finiteuses.total
                    hands.components.finiteuses:Use(-0.005*maxuses)
                end
            end
        end        
        for i,v in ipairs(artifact_helmets) do
            if hat and v == hat.prefab then
                if hat.components.fueled and hat.components.fueled:GetPercent() < 1 then
                    local maxfuel = hat.components.fueled.maxfuel
                    hat.components.fueled:DoDelta(0.005*maxfuel)
                end
                if hat.components.finiteuses and hat.components.finiteuses:GetPercent() < 1  then
                    local maxuses = hat.components.finiteuses.total
                    hat.components.finiteuses:Use(-0.005*maxuses)
                end
                if hat.components.armor and hat.components.armor:GetPercent() < 1 then
                    local maxfuel = hat.components.armor.maxcondition
                    hat.components.armor:Repair(0.005*maxfuel)
                end    
            end
        end            
    end    
    
end

local function FindSpeed(inst)
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local equiphands = item and item.components.equippable

    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local equipbody = item and item.components.equippable
 
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local equiphat = item and item.components.equippable

    return (equiphands and equiphands.walkspeedmult and equiphands.walkspeedmult > 1) or
        (equipbody and equipbody.walkspeedmult and equipbody.walkspeedmult > 1) or 
    (equiphat and equiphat.walkspeedmult and equiphat.walkspeedmult > 1)
end

local function AmpTimer(inst)
    -- Passive Adrenaline Loss Mechanics
    if (inst:HasTag("amped") or inst:HasTag("deathamp")) then
        if HasSkill(inst,"stalker_4") then
            inst.components.adrenaline:DoDelta(-10)
        end
        if HasSkill(inst,"hyper_2") and FindSpeed(inst) and inst.sg:HasStateTag("running") then
            -- Nothing
        else
            inst.components.adrenaline:DoDelta(inst.adrenalpause and -1 or -4)
        end
    elseif inst.components.adrenaline:GetPercent() >= 0 then
        if HasSkill(inst,"hyper_2") and FindSpeed(inst) and inst.sg:HasStateTag("running") and not inst:HasTag("amped") then
            if inst.components.adrenaline:GetPercent() < 0.5 then
                inst.components.adrenaline:DoDelta(1)
            else
                -- Nothing
            end
        elseif not inst.adrenalpause and not inst.horror_regen and not inst.nightmare_regen then
            inst.components.adrenaline:DoDelta(-1)
        end
    end


    local AmpLevel = inst.components.adrenaline:GetPercent()
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    --range updates

    if inst.components.rider and inst.components.rider:IsRiding() then
        inst.components.combat.attackrange = 2
    elseif (inst:HasTag("amped") or inst:HasTag("deathamp")) then
        inst.components.combat.attackrange = (item or HasSkill(inst,"devour_2")) and 7 or 2
    else
        inst.components.combat.attackrange = (item or HasSkill(inst,"devour_2")) and (4 + AmpLevel*3) or 2
    end
end

local function OnKilledFunction(inst,target) -- Target has passed a nil check
    
    -- Rampage 1 Will allow you to gain adrenaline based upon the kill health
    if HasSkill(inst,"rampage_1") then
        local maxhealth = target.components.health.maxhealth
        if inst.components.adrenaline and not inst:HasTag("amped") then
            inst.components.adrenaline:DoDelta(math.sqrt(maxhealth))
            local puff = SpawnPrefab("shadow_puff")
            local scale = math.clamp(math.sqrt(maxhealth/100),1,4) -- 1x for 100 health mobs, all the way to 4x for bosses
            puff.Transform:SetPosition(target.Transform:GetWorldPosition())
            puff.Transform:SetScale(scale,scale,scale)
        end
    end

    -- Rampge 4 Will allow you to scale your damage multiplier up to 5x
    if HasSkill(inst,"rampage_4") then
        UpdateCarnage(inst,true)
    end
end

-- Empowered attacks
local function SetEmpoweredFx(inst)
    if inst.num_nightmare_hits > 0 and not inst.nightmare_hit_fx then
        inst.nightmare_hit_fx = SpawnPrefab("shadow_pillar_base_fx")
		inst.nightmare_hit_fx.entity:SetParent(inst.entity)
        inst.nightmare_hit_fx.entity:AddFollower()
    elseif inst.nightmare_hit_fx and inst.num_nightmare_hits <= 0 then
        inst.nightmare_hit_fx:Remove()
        inst.nightmare_hit_fx = nil
        if inst.nightmare_regen_FN then
            inst.nightmare_regen_FN:Cancel()
            inst.nightmare_regen_FN = nil
        end
    end

    if inst.num_planar_hits > 0 and not inst.planar_hit_fx then
        inst.planar_hit_fx = SpawnPrefab("wurt_shadow_merm_planar_fx")
		inst.planar_hit_fx.entity:SetParent(inst.entity)
    elseif inst.planar_hit_fx and inst.num_planar_hits <= 0 then
        inst.planar_hit_fx:Remove()
        inst.planar_hit_fx = nil
        if inst.horror_regen_FN then
            inst.horror_regen_FN:Cancel()
            inst.horror_regen_FN = nil
        end
    end
end

local planar_attack = {} -- Klei structures planar damage calculation in this way
planar_attack["planar"] = 68

local MUST_TAGS = {"_combat"}
local CANT_TAGS = {"player", "companion", "abigail", "shadowminion", "playerghost", "INLIMBO", "wixieshoved", "invisible",
    "hiding", "notarget", "noattack", "flight"} -- shadowcreatures should probably get hit by this... allies though, maybe not.

local function EmpoweredDamage(inst,target)
     
    local regular = false
    local planar = false
    local x, y, z = target.Transform:GetWorldPosition()
    
    if inst.num_nightmare_hits > 0 then 
        local fx1 = SpawnPrefab("wanda_attack_pocketwatch_old_fx")
        fx1.Transform:SetPosition(x,y,z)   
        inst.num_nightmare_hits = inst.num_nightmare_hits - 1
        regular = true
    end
    if inst.num_planar_hits > 0 then 
        local fx2 = SpawnPrefab("shadowthrall_projectile_fx")
        fx2.Transform:SetPosition(x,y,z)   
        fx2.Transform:SetScale(1.5,1.5,1.5) 
        inst.num_planar_hits = inst.num_planar_hits - 1
        fx2.AnimState:PlayAnimation("projectile_impact")
        fx2.DynamicShadow:Enable(false)
        fx2.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
        planar = true
    end

    SetEmpoweredFx(inst)
    
    local ents = TheSim:FindEntities(x, y, z, 2, MUST_TAGS, CANT_TAGS)
    for i, v in ipairs(ents) do
        if inst.components.combat:CanTarget(v) and not inst.components.combat:IsAlly(v) then
            if not (v.components.health and v.components.health:IsDead()) then
                v.components.combat:GetAttacked(inst,regular and 68 or 0,nil,"wathom_aoe",planar and planar_attack or nil)
            end
        end
    end
end 

local function FindHoneID(inst,prefab)
    for i,v in ipairs(inst.hone_items) do
        if v == prefab then
            return i
        end
    end
end

local function AddHoneFx(inst,scale)
    inst.hone_fx = SpawnPrefab("smoke_plant")
    inst.hone_fx.entity:SetParent(inst.entity)
    inst.hone_fx.entity:AddFollower()
    inst.hone_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 50, -100, 0)
    inst.hone_fx.AnimState:SetMultColour(0,0,0,1)
    inst.hone_fx.Transform:SetScale(scale,scale,scale)
    inst.hone_fx.Light:Enable(false)
    inst.hone_fx.SoundEmitter:SetVolume("smolder",0.5)
end

local function CheckHone(inst)
    local should_fx = false
    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon then
        local ID = FindHoneID(inst,weapon.prefab)
        local hone_track
        if ID then
            hone_track = inst.hone_amounts[ID]
        end
        if hone_track and hone_track >= inst.hone_tiers[1] then
            local scale = 0
            if hone_track >= inst.hone_tiers[2] then
                should_fx = true
                scale = 1
            elseif hone_track >= inst.hone_tiers[1] then
                should_fx = true
                scale = 0.5
            end
            if not inst.hone_fx then
                AddHoneFx(inst,scale)
            else
                inst.hone_fx.Transform:SetScale(scale,scale,scale)
            end
        end
    end

    if not should_fx and inst.hone_fx then
        inst.hone_fx:Remove()
        inst.hone_fx = nil
    end
end

local function ShouldThreshBurst(inst,amount,prev_amount)
    local burst  = false
    local scale = 0
    if prev_amount < inst.hone_tiers[1] and (prev_amount + amount) >= inst.hone_tiers[1] then
        burst = true
        scale = 0.5
    elseif prev_amount < inst.hone_tiers[2] and (prev_amount + amount) >= inst.hone_tiers[2] then
        burst = true
        scale = 1
    end
    if burst then
        local burst_fx = SpawnPrefab("statue_transition")
        burst_fx.entity:SetParent(inst.entity)
        burst_fx.entity:AddFollower()
        burst_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 50, -100, 0)
        burst_fx.Transform:SetScale(scale,scale,scale)
        --burst_fx:ListenForEvent("animover")
        --burst_fx:Remove()
        
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item then
            if item.prefab == "shadow_battleaxe" then
                item:DoTaskInTime(0,function(item) item.SetLevel(item,item.level) end)
            end
        end
    end
end

local no_hone = {"nolifedrainable","companion","character"}

local function TryHone(inst,data)
    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local target = data.target
    local health = data.target.components.health and data.target.components.health.maxhealth

    if weapon and target and health and not target:HasAnyTag(no_hone) then
        local amount = 0        
        local ID = inst.FindHoneID(inst,weapon.prefab)

        -- Should we bother estimating hone
        if ID then
            -- Figure out how much...
            if health <= 100 and target:HasTag("hostile") then
                amount = amount + 1
            elseif health > 100 and health < 600 then
                amount = amount + 1
            elseif health > 900 and not target:HasTag("EPIC") then
                amount = amount + 1.25
            elseif health < 4000 then
                amount = amount + 1.5
            elseif health < 10000 then
                amount = amount + 1.75
            elseif health >= 10000 then
                amount = amount + 2
            end 
            if inst.hone_amounts[ID] <= inst.hone_tiers[2] then
                ShouldThreshBurst(inst,amount,inst.hone_amounts[ID])
                inst.hone_amounts[ID] = inst.hone_amounts[ID] + amount
                CheckHone(inst)
            end
        end
    end
end

local function OnAttackOther(inst, data)
    if data and data.target and not data.projectile
        and ((data.target.components.combat and data.target.components.health and data.target.components.health.maxhealth >= 50)) then
        -- AXE I removed the checks for specific things here we're just relying on a health threshhold now, the value I set captures bats at lowest

        inst.adrenalpause = true
        if inst.adrenalresume then
            inst.adrenalresume:Cancel()
            inst.adrenalresume = nil
        end
        inst.adrenalresume = inst:DoTaskInTime(10, function(inst) inst.adrenalpause = false end)
        if not (inst:HasTag("amped") or inst:HasTag("deathamp")) then
            inst.components.adrenaline:DoDelta(5 - 2 * inst.components.adrenaline:GetPercent())
        end

        if HasSkill(inst,"expedition") then
            TryHone(inst,data)
        end

        if HasSkill(inst,"rampage_4") and inst.carnage_multiplier > 0 then 
            local x,y,z = data.target.Transform:GetWorldPosition()

            local fx1 = SpawnPrefab("shadow_merm_spawn_poof_fx")
            local fx2 = SpawnPrefab("shadow_merm_smacked_poof_fx")
            local scale = 0.75 + (inst.carnage_multiplier-1)*0.25/2
            fx1.Transform:SetScale(scale,scale,scale)
            fx2.Transform:SetScale(scale,scale,scale)

            fx1.Transform:SetPosition(x,y,z)
            fx2.Transform:SetPosition(x,y,z)          
        end

        if inst.num_nightmare_hits > 0 or inst.num_planar_hits > 0 then
            EmpoweredDamage(inst,data.target)
        end

        inst:DoTaskInTime(0,function(inst)
            if data and data.target and data.target.components.health and data.target.components.health:IsDead() then
                OnKilledFunction(inst,data.target)
            elseif HasSkill(inst,"rampage_4") then
                UpdateCarnage(inst,false) -- Failed to Kill.
            end        
        end)
    end
end

---------------------------------------------

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and not useitem then
        local rider = inst.replica.rider
        if rider and not rider:IsRiding() or not rider then
            return {ACTIONS.WATHOMBARK}
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker then
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

local NIGHTVISION_CCS = {
    blue = {
        day = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
        night = resolvefilepath("images/colour_cubes/bat_vision_on_cc.tex"),
        full_moon = "images/colour_cubes/fungus_cc.tex",
    },
    red  = {
        day = "images/colour_cubes/mole_vision_on_cc.tex",
        dusk = "images/colour_cubes/mole_vision_on_cc.tex",
        night = "images/colour_cubes/mole_vision_on_cc.tex",
        full_moon = "images/colour_cubes/fungus_cc.tex",
    },
    bnw  = {
        day = "images/colour_cubes/ruins_dim_cc.tex",
        dusk = "images/colour_cubes/ruins_dim_cc.tex",
        night = "images/colour_cubes/ruins_dim_cc.tex",
        full_moon = "images/colour_cubes/ruins_dim_cc.tex",
    }
}

local function GetMusicValues(inst)
    return inst:HasTag("amped") and "wathom_amped" or nil --this should turn off the music.
end

--[[local function WathomEnterLight(inst)
end

local function WathomEnterDark(inst)
end]]

local function CheckLight(inst)
    if inst:IsInLight() then
        if not inst.updatewathomvisiontask then
            inst.updatewathomvisiontask = inst:DoTaskInTime(2, function()
                inst.components.playervision:SetCustomCCTable(nil)
                inst.components.playervision:ForceNightVision(false)
                inst:RemoveTag("WathomInDark")

                if inst.updatewathomvisiontask ~= nil then
                    inst.updatewathomvisiontask:Cancel()
                end
            end)
        end
    else
        if inst.updatewathomvisiontask then
            inst.updatewathomvisiontask:Cancel()
        end

        inst.updatewathomvisiontask = nil
        --print(NIGHTVISION_CCS, TUNING.DSTU.WATHOM_NIGHTVISON_CC, NIGHTVISION_CCS[TUNING.DSTU.WATHOM_NIGHTVISON_CC])
        inst.components.playervision:SetCustomCCTable(NIGHTVISION_CCS[TUNING.DSTU.WATHOM_NIGHTVISON_CC])
        inst.components.playervision:ForceNightVision(true)
        inst:AddTag("WathomInDark")
    end
end


-- Boss Saving/Loading Mechanics
local function SaveHealthAndHunger(inst,data)
    data.hunger_current = inst.components.hunger.current
    data.hunger_max = inst.components.hunger.max

    data.health_current = inst.components.health.currenthealth
    data.health_max = inst.components.health.maxhealth
    return data
end

local function LoadHealthAndHunger(inst,data)
    if data.hunger_current then
        inst.components.hunger.current = data.hunger_current
        inst.components.hunger.max = data.hunger_max

        inst.components.health.currenthealth = data.health_current
        inst.components.health.maxhealth = data.health_max
    end

end



-- When loading or spawning the character
local function onload(inst, data)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end

    if data then
        -- Hone
        if data.hone_amounts then
            inst.hone_amounts = data.hone_amounts
        end

        if data.amped then
            inst:AddTag("amped")
            SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomMusicToggle"), inst.userid, GetMusicValues(inst))
        end

        if data.deathamped then
            inst:AddTag("deathamp")
            SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomMusicToggle"), inst.userid, GetMusicValues(inst))
        end
        if data.found_station then
            inst.found_station = true
            inst:AddComponent("prototyper")
            inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.ANCIENTALTAR_HIGH
        end
        if data.um_bosses_killed then
            inst.um_bosses_killed = data.um_bosses_killed
            if #data.um_bosses_killed > 0 then
                LoadHealthAndHunger(inst,data)
            end
        end
    end
end



local function CheckForCaneRun(inst)
    local AmpLevel = inst.components.adrenaline:GetPercent()
    if inst:HasTag("amped") or AmpLevel >= (HasSkill(inst,"hyper_1") and 0.48 or 0.75) and
        (inst.components.rider and not inst.components.rider:IsRiding() or not inst.components.rider) then --Handle Wathom Running
        inst:AddTag("wathomrun")
    elseif inst:HasTag("wathomrun") and not (inst:HasTag("amped") or AmpLevel >= (HasSkill(inst,"hyper_1") and 0.48 or 0.75)) or inst.components.rider and inst.components.rider:IsRiding() then
        inst:RemoveTag("wathomrun")
    end
end

local function EquipChecks(inst)
    CheckForCaneRun(inst)
    CheckHone(inst)
end

local function UpdateAdrenaline(inst, data)
    SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomMusicToggle"), inst.userid, GetMusicValues(inst))
    local AmpLevel = inst.components.adrenaline:GetPercent()
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    --seperate 'if's so all sounds can play at once, in theory. (And I don't have to worry about elseif order...)
    if data.oldpercent < 0.75 and data.newpercent >= 0.75 then
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomAdrenalineStinger"), inst.userid, "wathom_ampstage_04")
    end
    if data.oldpercent < 0.5 and data.newpercent >= 0.5 then
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomAdrenalineStinger"), inst.userid, "wathom_ampstage_02")
    end

    if data.oldpercent >= 0.5 and data.newpercent < 0.5 then
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomAdrenalineStinger"), inst.userid, "wathom_breathe")
    end
    if data.oldpercent >= 0.25 and data.newpercent < 0.25 and not inst:HasTag("amped") then
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomAdrenalineStinger"), inst.userid, "wathom_breathe")
    end
    if data.oldpercent >= 0 and data.newpercent == 0 and inst:HasTag("amped") then
        SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomAdrenalineStinger"), inst.userid, "wathom_breathe")
    end

    CheckForCaneRun(inst)

    if inst.components.rider and inst.components.rider:IsRiding() then
        inst.components.combat.attackrange = 2
    elseif (inst:HasTag("amped") or inst:HasTag("deathamp")) then
        inst.components.combat.attackrange = item and 7 or 2
    else
        inst.components.combat.attackrange = item and (4 + AmpLevel*3) or 2
    end
    
    if AmpLevel <= 0 and inst:HasTag("amped") then
        UnAmp(inst)
    elseif AmpLevel >= 1 then
        Amp(inst)
    end
end

local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
    return mount and 1 or ((inst:HasTag("amped") and 4 or 2) + inst.carnage_multiplier)
end


local function Exclamationfy(string)
    if not ThePlayer or not ThePlayer:HasAnyTag("amped", "groggy") then
        return string
    end

    local ret = ""
    for i = 1, #string do
        local c = string:sub(i,i)
        if ThePlayer:HasTag("amped") then
            ret = ret..((c == "." or c == "!") and ((c == "." and "!") or (c == "!" and "!!")) or c)
        elseif ThePlayer:HasTag("groggy") then
            ret = ret..((c == "." or c == "!") and ((c == "." and "...") or (c == "!" and "...")) or c)
        else
            return string
        end
    end
    return ret
end

local function UpdateMusic(inst)
    SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "WathomMusicToggle"), inst.userid, GetMusicValues(inst))
end

-- This initializes for both the server and client. Tags can be added here.
local function common_postinit(inst)
    -- Minimap icon
    inst.MiniMapEntity:SetIcon("wathom.tex")

    inst:AddTag("wathom") -- Tells the game to switch the character's attacks to leaping, as well as switch some insanity sources around to give sanity instead.
    inst:AddTag("monster")
    inst:AddTag("playermonster")
    inst:AddTag("nightvision")

    inst.components.talker.mod_str_fn = Exclamationfy

    inst.OnLoad = onload
    inst.OnNewSpawn = onload

    inst:DoPeriodicTask(.3, CheckLight)
    --[[inst:ListenForEvent("enterdark", WathomEnterDark)
    inst:ListenForEvent("enterlight", WathomEnterLight)]]

    --t'was revealed to me in a dream, and I'm not even kidding.
    inst:ListenForEvent("wathommusic_start", UpdateMusic)
    inst:ListenForEvent("wathommusic_end", UpdateMusic)
    inst:ListenForEvent("ms_playerreroll", UpdateMusic)
    inst:ListenForEvent("player_despawn", UpdateMusic)
    inst:ListenForEvent("setowner", OnSetOwner)
    inst:ListenForEvent("ondeath", function(inst)
        if inst:HasTag("amped") then
            inst:RemoveTag("amped")
        end

        UpdateMusic(inst)
    end)
end

local function KnockOutTest(inst)
    if inst:HasTag("amped") then
        return false
    end
    return DefaultKnockoutTest(inst)
end

local function SetupKnockOutTest(inst)
    inst.components.grogginess:SetKnockOutTest(KnockOutTest)
end

local function RemoveCorpse(inst)
    inst:DoTaskInTime(0,function(inst)
        if inst.wathom_corpse and inst.wathom_corpse:IsValid() then
            inst.wathom_corpse.ReplaceWithSkeleton(inst.wathom_corpse)
        end
        inst:RemoveEventCallback("ms_respawnedfromghost",RemoveCorpse)
    end)
end

local function WathomWarnsEarly(inst, threattype)
    inst.owner.components.talker:Say("Others can't hear, "..threattype.." is coming.")
end


local function AttachEmpoweredHits(inst,pct,planar)
    if planar then
        inst.num_planar_hits = math.clamp(20-20*pct,inst.num_planar_hits,20)
    else
        inst.num_nightmare_hits = math.clamp(20-20*pct,inst.num_nightmare_hits,20)
    end
    SetEmpoweredFx(inst)
end

local function NMRegen(inst)
    inst.nightmare_regen = inst.nightmare_regen - 1
    inst.components.adrenaline:DoDelta(1)
    if inst.nightmare_regen <= 0 then
        inst.nightmare_regen_FN:Cancel()
        inst.nightmare_regen_FN = nil
    end
end

local function HRRegen(inst)
    inst.horror_regen = inst.horror_regen - 1
    inst.components.adrenaline:DoDelta(2)
    if inst.horror_regen <= 0 then
        inst.horror_regen_FN:Cancel()
        inst.horror_regen_FN = nil
    end
end

local function AttachRegenAdrenaline(inst,type)
    if type == "nightmarefuel" then
        AttachEmpoweredHits(inst,inst.components.adrenaline:GetPercent(),false)
        if not inst.nightmare_regen_FN then
            inst.nightmare_regen_FN = inst:DoPeriodicTask(1,NMRegen)
        end
        inst.nightmare_regen = 60
    elseif type == "horrorfuel" then
        AttachEmpoweredHits(inst,inst.components.adrenaline:GetPercent(),true)
        if not inst.horror_regen_FN then
            inst.horror_regen_FN = inst:DoPeriodicTask(1,HRRegen)
        end
        inst.horror_regen = 120
    end

end

local function OnDeath(inst)
    if inst.num_planar_hits or inst.num_nightmare_hits then
        inst.num_nightmare_hits = 0
        inst.num_planar_hits = 0
        SetEmpoweredFx(inst)
    end
end

local ancients = {"ruinshat","yellowamulet","greenamulet","orangeamulet","yellowstaff","greenstaff","orangestaff","um_magnifier",
"multitool_axe_pickaxe","armorruins","ruins_bat","ancient_amulet_red",
"voidcloth_umbrella","saddle_shadow","voidcloth_scythe","beeswax_spray","shadow_battleaxe","voidcloth_boomerang","armor_voidcloth","voidclothhat"}
-- both ancient AND shadow planar
local function IsAncientItem(item)
    for i,v in ipairs(ancients) do
        if item.prefab == v then
            return true
        end
    end
    return false
end


local magics = {"nightsword","armor_sanity","icestaff","firestaff","telestaff","armordreadstone","dreadstonehat","um_magnifier_purplegem",
"batbat","um_ice_sicle","um_hat_pepperdragon","antlionhat","amulet","blueamulet","purpleamulet","onemanband","um_feather_totem","panflute"}


local function IsMagicItem(item)
    for i,v in ipairs(magics) do
        if item.prefab == v then
            return true
        end
    end
    return false
end

local function Artifice(inst,data)
    if data and data.item and
        ((HasSkill(inst,"artificer_2") and IsMagicItem(data.item)) or 
        (HasSkill(inst,"artificer_3") and IsAncientItem(data.item))) and
        inst.components.adrenaline and 
        (inst.components.adrenaline.current > 75 or inst:HasTag("amped")) then
        local augmented = false
        if data.item.components.finiteuses then
            augmented = true
            local oldmax = data.item.components.finiteuses.total
            data.item.components.finiteuses:SetMaxUses(2*oldmax)
            data.item.components.finiteuses:SetUses(2*oldmax)
        end
        if data.item.components.fueled then
            augmented = true
            local oldmaxfuel = data.item.components.fueled.maxfuel
            data.item.components.fueled:InitializeFuelLevel(2*oldmaxfuel)
        end
        if data.item.components.armor then
            augmented = true
            local oldcondition = data.item.components.armor.condition
            data.item.components.armor.maxcondition = 2 * oldcondition
            data.item.components.armor.condition = 2 * oldcondition
        end
        if augmented == true then
            inst.components.adrenaline:SetPercent(0)
        end



    end
end

-- wathom_barkmod_effects call
local function SurvivorBarkEffect(player)
    if player.components.wereness then
        player.components.wereness:DoDelta(25)
    end
    if player.components.mightiness then
        player.components.mightiness:DoDelta(25)
    end
    if player.components.singinginspiration then
        player.components.singinginspiration:DoDelta(25)
    end
end

-- This initializes for the server only. Components are added here.
local function master_postinit(inst)

    inst.adrenalinecheck = 0 -- I have no idea what this does. It's left over from SCP-049.

    -- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    -- choose which sounds this character will play
    inst.soundsname = "wathomvoiceevent"
    inst.talker_path_override = "wathomcustomvoice/"

    -- Carnivore
    if inst.components.eater then
        inst.components.eater:SetDiet({FOODGROUP.OMNI}, {FOODTYPE.MEAT, FOODTYPE.GOODIES})
        inst.components.eater:SetCanEatRawMeat(true) -- Comment out when we want to invert insanity.
    end
    if TUNING.DSTU.BONESTEW == "bone_appetit" then
        inst.components.foodaffinity:AddPrefabAffinity("um_kebab", 20)
    else
        inst.components.foodaffinity:AddPrefabAffinity("bonestew", 20)
    end
    -- Stats
    inst.components.health:SetMaxHealth(TUNING.WATHOM_HEALTH)
    inst.components.hunger:SetMax(TUNING.WATHOM_HUNGER)
    inst.components.sanity:SetMax(TUNING.WATHOM_SANITY)

    --    inst.components.sanity.neg_aura_absorb = TUNING.ARMOR_HIVEHAT_SANITY_ABSORPTION -- Reverses insanity auras and reduces by 50%

    -- Damage multiplier (In reality, Wathom won't deal double damage. The time it takes for him to attack is about twice as long as other characters.
    --inst.components.combat.damagemultiplier = 2
    inst.components.combat.customdamagemultfn = CustomCombatDamage

    -- Hunger rate (optional)
    inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE

    -- Idle animation
    inst.customidleanim = "spooked"

    -- Grogginess stuff
    inst:ListenForEvent("ms_respawnedfromghost", SetupKnockOutTest)
    SetupKnockOutTest(inst)

    inst:DoPeriodicTask(.3, CheckLight)
    --[[inst:ListenForEvent("enterdark", WathomEnterDark)
    inst:ListenForEvent("enterlight", WathomEnterLight)]]

    -- stuff relating to Wathom's adrenaline timer. This can most likely be optimized.
    inst:DoPeriodicTask(1.5, function() AmpTimer(inst) end)
    inst:DoPeriodicTask(1, function() SapTask(inst) end)
    
    inst:ListenForEvent("onattackother", OnAttackOther)
    if TheWorld.ismastersim then
        inst:ListenForEvent("adrenalinedelta", UpdateAdrenaline)
    end
    inst:ListenForEvent("wathommusic_start", UpdateMusic)
    inst:ListenForEvent("wathommusic_end", UpdateMusic)
    inst:ListenForEvent("ms_playerreroll", UpdateMusic)
    inst:ListenForEvent("player_despawn", UpdateMusic)
    inst:ListenForEvent("ondeath", function(inst)
        if inst:HasTag("amped") then
            inst:RemoveTag("amped")
        end
        UpdateMusic(inst)
    end)

    inst.components.sanity.custom_rate_fn = function(inst)
        if inst:HasTag("amped") then
            if HasSkill(inst,"hyper_4") then
                return -TUNING.SANITYAURA_SMALL
            elseif HasSkill(inst,"stalker_4") then
                return -TUNING.SANITYAURA_HUGE/2
            else
                return -TUNING.SANITYAURA_SMALL_TINY
            end
        end
        if TheWorld.state.isday and not inst.components.sanity:IsLunacyMode() then
            return -TUNING.SANITYAURA_SMALL_TINY
        end

        return 0
    end

    inst.components.sanity.night_drain_mult = 0


    local _onsave = inst.OnSave
    local function onsave(inst, data)
        if inst:HasTag("amped") then
            data.amped = true
        end
        if inst:HasTag("deathamp") then
            data.deathamped = true
        end

        if inst.hone_amounts then -- Save the list of things wathom has honed
            data.hone_amounts = inst.hone_amounts
        end

        data.um_bosses_killed = inst.um_bosses_killed
        if #data.um_bosses_killed > 0 then
            data = SaveHealthAndHunger(inst,data)
        end
    
        if _onsave ~= nil then
            return _onsave(inst, data)
        end
    end

    inst.OnLoad = onload
    inst.OnSave = onsave

    inst.OnNewSpawn = onload
    inst.ToggleUndeathState = ToggleUndeathState

    inst.SetEmpoweredFx = SetEmpoweredFx
    inst.EmpoweredDamage = EmpoweredDamage
    inst.HealingGlutton = HealingGlutton
    inst.SurvivorBarkEffect = SurvivorBarkEffect
    inst.carnage_multiplier = 0
    inst.num_nightmare_hits = 0
    inst.num_planar_hits = 0


    -- Hone Tuning Variables - we can move to TUNING.DSTU at some - after merge probably
    inst.hone_tiers = {500,5000}
    inst.hone_items = {"ruins_bat","multitool_axe_pickaxe","voidcloth_scythe","voidcloth_boomerang","shadow_battleaxe"}
    if not inst.hone_amounts then
        inst.hone_amounts = {0,0,0,0,0} -- Starts at 0, loading may give different values
    end
    inst.FindHoneID = FindHoneID

    inst:ListenForEvent("equip",EquipChecks)
    inst:ListenForEvent("unequip",EquipChecks)


    inst.UMToggleUniqueVetCurse = ToggleUniqueVetCurse

    local _oneatfn = inst.components.eater.oneatfn or nil
    local function OnEatFn(inst,food,feeder)
        if HasSkill(inst,"glutton_1") then
            if food:HasTag("meat") and food:HasTag("cookable") and food.components.perishable then
                local deltaadrenaline = food.components.edible.hungervalue * food.components.perishable:GetPercent()
                inst.components.adrenaline:DoDelta(deltaadrenaline)
            end
        end
        if HasSkill(inst,"glutton_2") then
            -- Attach special effects as well.
            if food.prefab == "nightmarefuel" then
                AttachRegenAdrenaline(inst,food.prefab)                
            end
            if food.prefab == "horrorfuel" then
                AttachRegenAdrenaline(inst,food.prefab)
            end
        end
        if _oneatfn then
            _oneatfn(inst,food,feeder)
        end
    end


    inst:ListenForEvent("death",OnDeath)
    inst.components.eater.oneatfn = OnEatFn

    inst.FindSpeed = FindSpeed
    inst.um_bosses_killed = {}
    -- Artificer
    inst:ListenForEvent("builditem",Artifice)
end

return MakePlayerCharacter("wathom", prefabs, assets, common_postinit, master_postinit)
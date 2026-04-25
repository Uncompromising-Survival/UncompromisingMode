local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("ANIM", "anim/wathom.zip"),
    Asset("ANIM", "anim/wathom_shadow.zip"),
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("SOUNDPACKAGE", "sound/wathomcustomvoice.fev"),
    Asset("SOUND", "sound/wathomcustomvoice.fsb")
}

-- Your character's stats
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

local function ToggleUndeathState(inst, toggle,fake)
    if inst.components.timer and inst.components.timer:TimerExists("shadowwathomcooldown") then
        return
    end

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

local function UnAmp(inst)
    inst:RemoveTag("amped") -- Party's over.
    inst.components.combat.attackrange = 2
    inst.AmpDamageTakenModifier = TUNING.DSTU.WATHOM_AMPED_VULNERABILITY
    if inst.adrenalinehpregen ~= nil then
        inst.adrenalinehpregen:Cancel()
        inst.adrenalinehpregen = nil
    end

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
end

local function RegurgitateFuel(inst)
    local fuel = SpawnPrefab("nightmarefuel")
    fuel.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fuel:DoTaskInTime(0,function(fuel)
        Launch(fuel, inst, 3) -- need to set it to our location first, the 2nd entry does not do that, I tested it in a world, if you fail to do this it'll toss it at 0,0,0
    end)
end

local function ShouldRegurgitate(inst)
    if inst:HasTag("amped") then
        RegurgitateFuel(inst)
    else
        inst.um_wathom_regurgitatetask:Cancel()
        inst.um_wathom_regurgitatetask = nil
    end
end

local function Amp(inst)
    inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/ampedbark")
    inst.components.combat.attackrange = 7 -- These values are for when Wathom's at 100 Adrenaline, so he should be Amping Up right now.
    inst.AmpDamageTakenModifier = TUNING.DSTU.WATHOM_AMPED_VULNERABILITY
    inst:AddTag("amped")
    inst.components.adrenaline:SetAmped(true)
    --inst.components.talker:Say("AMPED UP!", nil, true)

    inst.helpimleaking = inst:DoPeriodicTask(0.33, function(inst)
        if inst:HasTag("amped") then
            local x, y, z = inst.Transform:GetWorldPosition()
            local xoffset = math.random(-10, 10) / 10
            local zoffset = math.random(-10, 10) / 10
            --SpawnPrefab("minotaur_blood"..math.random(3)).Transform:SetPosition(x + xoffset, y, z + zoffset)
            SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + xoffset, y, z + zoffset)
        end
    end)

    --[[inst.adrenalinehpregen = inst:DoPeriodicTask(1, function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst.components.health:DoDelta(1.5)
        end
    end)]]
    if not (inst.components.health and inst.components.health:IsDead()) then
        --inst.sg:GoToState("wathombark")
        inst.components.health.invincible = true
        inst:DoTaskInTime(1, function() inst.components.health.invincible = false end)
    end
    
    if HasSkill(inst,"wathom_allegiance_shadow") then
        RegurgitateFuel(inst)
        RegurgitateFuel(inst)
        RegurgitateFuel(inst)
        inst.um_wathom_regurgitatetask = inst:DoPeriodicTask(30,ShouldRegurgitate)
    end
end

-- When the character is revived from human
local function onbecamehuman(inst)
    -- Set speed when not a ghost (optional)
    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wathom_speed_mod", 1)
    UnAmp(inst)
    --inst.AnimState:SetBuild("wathom")
    inst.components.adrenaline:SetPercent(0.25)
end

local function onbecameghost(inst)
    -- Remove speed modifier when becoming a ghost
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wathom_speed_mod")
    UnAmp(inst)
    inst.components.adrenaline:SetPercent(0.25)
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

local function AmpTimer(inst)
    if inst.components.grogginess ~= nil and
        (inst.components.adrenaline:GetPercent() < 0.25 and not inst:HasTag("amped") and not inst:HasTag("deathamp")) then
        inst.components.grogginess.grog_amount = 0.5
    end

    -- Draining adrenaline when not in combat.
    if (inst:HasTag("amped") or inst:HasTag("deathamp")) then
        inst.components.adrenaline:DoDelta(inst.adrenalpause and -1 or -4)
    elseif inst.components.adrenaline:GetPercent() >= 0.25 then
        if not inst.adrenalpause then
            inst.components.adrenaline:DoDelta(-1)
        end
    end

    if inst.components.adrenaline:GetPercent() < 0.25 and not (inst:HasTag("amped") or inst:HasTag("deathamped")) then
        inst.components.adrenaline:DoDelta(1) -- Slowly regaining to normal levels.
    end

    local AmpLevel = inst.components.adrenaline:GetPercent()
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    --range updates

    if inst.components.rider and inst.components.rider:IsRiding() then
        inst.components.combat.attackrange = 2
        return
    end

    if (inst:HasTag("amped") or inst:HasTag("deathamp")) then
        inst.components.combat.attackrange = item and 7 or 2
    elseif AmpLevel < 0.25 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = 2
    elseif AmpLevel < 0.5 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_1") and 4) or 2
    elseif AmpLevel < 0.75 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_1") and 5) or 2
    elseif AmpLevel < 1 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_2") and 6 or HasSkill(inst,"amp_1") and 5) or 2
    end
end

local function OnAttackOther(inst, data)
    if data and data.target and not data.projectile and inst.components.adrenaline:GetPercent() >= 0.25
        and ((data.target.components.combat and data.target.components.combat.defaultdamage > 0)
        or (data.target.prefab == "dummytarget" or data.target.prefab == "antlion" or data.target.prefab == "stalker_atrium"
        or data.target.prefab == "stalker")) then
        inst.adrenalpause = true
        if inst.adrenalresume then
            inst.adrenalresume:Cancel()
            inst.adrenalresume = nil
        end
        inst.adrenalresume = inst:DoTaskInTime(10, function(inst) inst.adrenalpause = false end)
        if not (inst:HasTag("amped") or inst:HasTag("deathamp")) then
            inst.components.adrenaline:DoDelta(inst.components.adrenaline:GetPercent() >= 0.25 and inst.components.adrenaline:GetPercent() < 0.5 and 5
                or inst.components.adrenaline:GetPercent() >= 0.50 and inst.components.adrenaline:GetPercent() < 0.75 and 4 or 3)
        end
    end
end

local function OnHealthDelta(inst, data)
    if data.amount < 0 and not inst:HasTag("amped") and inst.components.adrenaline:GetPercent() >= 0.25 and
        data.cause ~= "deathamp" and not (inst.components.health and inst.components.health:IsDead()) then
        inst.components.adrenaline:DoDelta(math.floor(data.amount * -0.25)) -- This gives Wathom adrenaline when attacked!
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
    end
end

local function HoldingCane(inst)
    return inst:HasTag("wathom") and inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and 
    (inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "cane" or inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "orangestaff" or
    inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab == "walking_stick") and true
end

local function CheckForCaneRun(inst)
    local AmpLevel = inst.components.adrenaline:GetPercent()
    if (AmpLevel >= 0.75 or inst:HasTag("amped") or HoldingCane(inst) or (HasSkill(inst,"digitigrade_1") and inst.components.adrenaline and inst.components.adrenaline:GetPercent() > 0.48)) and
        (inst.components.rider and not inst.components.rider:IsRiding() or not inst.components.rider) then --Handle VVathom Running
        inst:AddTag("wathomrun")
        -- if inst.sg:HasStateTag("running") then
            -- inst.sg:GoToState("idle")
        -- end
    elseif inst:HasTag("wathomrun") and not (AmpLevel >= 0.75 or inst:HasTag("amped") or HoldingCane(inst)) or inst.components.rider and inst.components.rider:IsRiding() then
        inst:RemoveTag("wathomrun")
        -- if inst.sg:HasStateTag("running") then
            -- inst.sg:GoToState("idle")
        -- end
    end
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

    if AmpLevel == 0 and inst:HasTag("amped") then
        UnAmp(inst)
    elseif AmpLevel < 0.25 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = 2
        inst.AmpDamageTakenModifier = 3
    elseif AmpLevel < 0.5 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and 4 or 2
        inst.AmpDamageTakenModifier = 1
    elseif AmpLevel >= 1 and not inst:HasTag("amped") and HasSkill(inst,"amp_3") then
        Amp(inst)
        inst.AmpDamageTakenModifier = TUNING.DSTU.WATHOM_AMPED_VULNERABILITY
    elseif AmpLevel >= 1 and not inst:HasTag("amped") and HasSkill(inst,"amp_3") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_2") and 6 or HasSkill(inst,"amp_1") and 5) or 2
        --inst.components.health:SetAbsorptionAmount(HasSkill(inst,"amp_2") and -0.5 or HasSkill(inst,"amp_2") and -0.25 or 0)
        inst.AmpDamageTakenModifier = HasSkill(inst,"amp_2") and 2 or HasSkill(inst,"amp_1") and 1.5 or 1    
    elseif AmpLevel >= 0.75 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_2") and 6 or HasSkill(inst,"amp_1") and 5) or 2
        --inst.components.health:SetAbsorptionAmount(HasSkill(inst,"amp_2") and -0.5 or HasSkill(inst,"amp_2") and -0.25 or 0)
        inst.AmpDamageTakenModifier = HasSkill(inst,"amp_2") and 2 or HasSkill(inst,"amp_1") and 1.5 or 1
    elseif AmpLevel >= 0.5 and not inst:HasTag("amped") then
        inst.components.combat.attackrange = item and (HasSkill(inst,"amp_1") and 5) or 2
        inst.AmpDamageTakenModifier = HasSkill(inst,"amp_1") and 1.5 or 1
    end

    if inst.components.rider and inst.components.rider:IsRiding() then
        inst.components.combat.attackrange = 2
    end
end

local function CustomCombatDamage(inst, target, weapon, multiplier, mount)
    --sometimes I hate short-circuit evals...
    if not mount then
        return (target.components.hauntable and target.components.hauntable.panic and inst:HasTag("amped")) and (1.5 * 4)
            or (target.components.hauntable and target.components.hauntable.panic) and (1.5 * 2)
            or inst:HasTag("amped") and 4 or 2 or 1
    end
end

local function OnAttacked(inst, data)
    inst.adrenalpause = true
    if inst.adrenalresume then
        inst.adrenalresume:Cancel()
        inst.adrenalresume = nil
    end
    inst.adrenalresume = inst:DoTaskInTime(10, function(inst) inst.adrenalpause = false end)
    if not TUNING.DSTU.WATHOM_ARMOR_DAMAGE then
        local dmgmod = inst.AmpDamageTakenModifier
    
        
        if data.damageresolved then
            inst.components.health:DoDelta(-((data.damageresolved * dmgmod) - data.damageresolved), nil, data.attacker)
        end
    end
    --    if data.attacker:HasTag("brightmare") then
    --        inst.components.adrenaline:DoDelta(-10)
    --        inst.components.health:DoDelta(-10, nil, data.attacker)
    --    end
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

local function SeeIfShouldBecomeShadow(inst)
    if HasSkill(inst,"shadow_wathom_2") then
        inst.AnimState:SetBuild("wathom")
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetMultColour(0,0,0,0.6)
        inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED + TUNING.WONKEY_SPEED_BONUS
        if inst.components.health:GetPenaltyPercent() <= 0.25 then
            inst.wathom_corpse = SpawnPrefab("wathom_corpse")
            inst.wathom_corpse.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst:ListenForEvent("ms_respawnedfromghost", RemoveCorpse)
        else
            SpawnPrefab("skeleton").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
end

local function StopBeingShadow(inst)
    if HasSkill(inst,"shadow_wathom_2") then
        inst.AnimState:SetMultColour(1,1,1,1)
        inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
    end
end

local function WathomWarnsEarly(inst, threattype)
    inst.owner.components.talker:Say("Others can't hear, "..threattype.." is coming.")
end

-- This initializes for the server only. Components are added here.
local function master_postinit(inst)
    --    inst.components.sanity:EnableLunacy(true, "wathomlunacy")

    -- --     If at high lunacy, become a target for Gestalts and Greater Gestalts.
    --    if inst.components.sanity:GetPercent() > 0.84 then
    --        inst:AddTag("gestalt_possessable")
    --    else
    --        inst:RemoveTag("gestalt_possessable")
    --end

    inst.adrenalinecheck = 0 -- I have no idea what this does. It's left over from SCP-049.

    -- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

    -- choose which sounds this character will play
    inst.soundsname = "wathomvoiceevent"
    inst.talker_path_override = "wathomcustomvoice/"
    -- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"

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
    
    inst:ListenForEvent("healthdelta", OnHealthDelta)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("attacked", OnAttacked)
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

    --    inst:WatchWorldState("isday", function()
    --        inst:DoTaskInTime(TheWorld.state.isday and 0 or 1, function(inst)
    --            if not TheWorld:HasTag("cave") then
    --                if TheWorld.state.isnight or TheWorld.state.isdusk then
    --                    inst.components.sanity.dapperness = 0
    --                elseif TheWorld.state.isday then
    --                    inst.components.sanity.dapperness = 10 / 60
    --                end
    --            end
    --        end)
    --    end)
    
    inst.components.sanity.custom_rate_fn = function(inst)
        if inst.components.sanity:IsLunacyMode() then
            return 0
        end

        if TheWorld.state.isday then
            return TUNING.SANITY_NIGHT_LIGHT
        end

        return 0
    end

    inst.components.sanity.night_drain_mult = 0

    -- Night Vision enabler
    --    inst.components.playervision:ForceNightVision(true) -- Should only force this if it's night or in caves.

    -- Doubles Wathom's attack range so he can jump at things from further away.
    -- inst.components.combat.attackrange = 4

    local _onsave = inst.OnSave
    local function onsave(inst, data)
        if inst:HasTag("amped") then
            data.amped = true
        end
        if inst:HasTag("deathamp") then
            data.deathamped = true
        end
        if inst.found_station then
            data.found_station = true
        end
        
        if _onsave ~= nil then
            return _onsave(inst, data)
        end
    end

    inst.OnLoad = onload
    inst.OnSave = onsave

    inst.OnNewSpawn = onload
    inst.ToggleUndeathState = ToggleUndeathState

    inst:ListenForEvent("equip",CheckForCaneRun)
    inst:ListenForEvent("unequip",CheckForCaneRun)

    inst:ListenForEvent("makeplayerghost",function(inst) inst:DoTaskInTime(0,SeeIfShouldBecomeShadow) end)
    inst:ListenForEvent("ms_respawnedfromghost", StopBeingShadow)

    inst:DoPeriodicTask(0, VetCurseCheck)
end

return MakePlayerCharacter("wathom", prefabs, assets, common_postinit, master_postinit)
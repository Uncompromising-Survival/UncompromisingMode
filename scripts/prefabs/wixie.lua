local MakePlayerCharacter = require("prefabs/player_common")
local SourceModifierList = require("util/sourcemodifierlist")

local assets = {
        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wixie.fsb" ),
        Asset( "ANIM", "anim/beard.zip" ),

        -- Don't forget to include your character's custom assets!
        Asset( "ANIM", "anim/wixie.zip" ),
        Asset( "ANIM", "anim/ghost_wixie_build.zip" ),
}

local prefabs = {
    "slingshot",
}

local function customidleanimfn(inst)
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and item.prefab == "the_real_charles_t_horse" and "idle_woodie" or "idle_wixie"
end

local function OnKilledOther(inst, data)
    if data and data.victim and data.victim.prefab then
        local naughtiness = NAUGHTY_VALUE[data.victim.prefab]
        if naughtiness then
            local naughty_val = FunctionOrValue(naughtiness, inst, data)
            local naughtyresolve = naughty_val * (data.stackmult or 1)
            inst.components.sanity:DoDelta(naughtyresolve)
        end
    end
end

local function GetClaustrophobia(inst)
    return inst.claustrophobia or 0
end

local function CanGainClaustrophobia(inst)
    local isghost = (inst.player_classified and inst.player_classified.isghostmode:value()) or (not inst.player_classified and inst:HasTag("playerghost"))
    return not (isghost or inst.components.health and inst.components.health:IsDead() or inst.replica and inst.replica.health and inst.replica.health:IsDead())
end

local function OnCooldown(inst)
    inst._claustrophobiacdtask = nil
end

local NOT_CLAUSTROPHOBIC_TAGS = {"noclaustrophobia", "balloon", "structure", "wall", "fx", "NOCLICK", "INLIMBO", "invisible", "player", "playerghost", "ghost", "shadow", "shadowcreature",
    "shadowminion", "stalkerminion", "shadowchesspiece", "boatbumper", "spore", "pigelite", "oceanfishable", "trap", "companion", "isdead", "deckcontainer"}
local function updateclaustrophobia(inst)
    inst.claustrophobiarate = inst.claustrophobiahidden and .005 or 0
    local objectmodifier = 0

    if not inst._claustrophobiacdtask and inst:CanGainClaustrophobia() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 6, {"_health", "_combat"}, NOT_CLAUSTROPHOBIC_TAGS)
        local treesandwallsandcompanions = TheSim:FindEntities(x, y, z, 5, nil, {"stump", "critter", "INLIMBO", "isdead"}, {"tree", "wall", "companion"})

        if treesandwallsandcompanions then
            for i, v in ipairs(treesandwallsandcompanions) do
                objectmodifier = objectmodifier < .5 and objectmodifier + (v:HasTag("companion") and .5 or .05) or .5
            end
        end

        if not inst.wixiepanic and ents and #ents >= 1 or inst.claustrophobiarate > 0 or inst.replica.rider and inst.replica.rider:IsRiding() then
            if ents and #ents >= 1 then
                for i, v in ipairs(ents) do
                    local distsq = v:IsValid() and inst:GetDistanceSqToInst(v) or 1
                    local distance_rate = 1.5 - (distsq / 33)
                    --print("distsq"..distsq)
                    --print("distance_rate"..distance_rate)
                    if inst:GetClaustrophobia() < 1 then
                        local adjustrate = v:HasTag("smallcreature") and v:HasAnyTag("insect", "rabbit", "bird", "companion") and .0005
                            or v:HasTag("smallcreature") and .0008 or v:HasTag("epic") and (v.prefab == "klaus" and .008 or .006) or .0025
                        inst.claustrophobiarate = math.clamp(inst.claustrophobiarate + (adjustrate * distance_rate), 0, .008)
                    end
                end
            end

            if inst.replica.rider and inst.replica.rider:IsRiding() then
                inst.claustrophobiarate = math.clamp(inst.claustrophobiarate + .0005, 0, .008)
            end

            inst.claustrophobia = math.clamp(inst.claustrophobia + inst.claustrophobiarate, 0, 1)

            if inst:GetClaustrophobia() >= 1 then
                if not inst.wixiepanic then
                    inst.wixiepanic = true
                    SendModRPCToServer(GetModRPC("WixieTheDelinquent", "ClaustrophobiaPanic"), inst)
                end
            end
        else
            if inst.wixiepanic then
                inst.claustrophobia = math.max(inst.claustrophobia - .0075, 0)
            end

            local minimum_claustrophobia = inst.claustrophobiamodifier + objectmodifier
            inst.claustrophobia = not inst.wixiepanic and inst:GetClaustrophobia() <= minimum_claustrophobia
                and math.clamp(inst.claustrophobia + .002, 0, minimum_claustrophobia) or math.max(inst.claustrophobia - .001, 0)

            if inst:GetClaustrophobia() <= 0 then
                if inst.wixiepanic then
                    inst.wixiepanic = false
                    inst._claustrophobiacdtask = inst:DoTaskInTime(10, OnCooldown)
                end
            end
        end
    end
end

local NOT_CLAUSTROPHOBIC_ARMOR_TAGS = {"grass", "shadow_item"}
local function EquipUnequipCount(inst, data)
    local headequipped = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local bodyequipped = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)

    inst.headmodifier = headequipped and headequipped.components.armor and not headequipped:HasAnyTag(NOT_CLAUSTROPHOBIC_ARMOR_TAGS) and 0.2 or 0
    inst.bodymodifier = bodyequipped and bodyequipped.components.armor and not bodyequipped:HasAnyTag(NOT_CLAUSTROPHOBIC_ARMOR_TAGS) and 0.2 or 0

    inst.claustrophobiamodifier = inst.headmodifier + inst.bodymodifier

    SendModRPCToClient(GetClientModRPC("WixieTheDelinquent", "ClaustrophobiaEquipMult"), inst.userid, tostring(inst.claustrophobiamodifier))
end

local function EquipedCount(inst, data)
    if data and data.item and data.item.components.equippable and (data.item.components.equippable.equipslot == EQUIPSLOTS.BODY
        or data.item.components.equippable.equipslot == EQUIPSLOTS.HEAD) and data.item.components.armor and not data.item:HasAnyTag(NOT_CLAUSTROPHOBIC_ARMOR_TAGS) then
        inst.components.talker:Say(GetString(inst, data.item.components.equippable.equipslot == EQUIPSLOTS.BODY and "UNCOMFORTABLE_ARMOR" or "UNCOMFORTABLE_HAT"))
    end

    EquipUnequipCount(inst, data)
end

local function OnNewState(inst, data)
    if inst.sg:HasStateTag("hiding") or inst.claustrophobiahidden then
        inst.claustrophobiahidden = inst.sg:HasStateTag("hiding") or nil
        SendModRPCToClient(GetClientModRPC("WixieTheDelinquent", "ClaustrophobiaHidden"), inst.userid, inst.claustrophobiahidden)
    end
end

local function OnInit(inst)
    if not inst.wixietask then
        inst.wixietask = inst:DoPeriodicTask(FRAMES, updateclaustrophobia)
    end
end

local MAPREVEAL_SCALE = 450
local MAPREVEAL_STEPS = 10

local function OnNewSpawn(inst)
    inst:DoTaskInTime(0, function()
        local spawn = TheSim:FindFirstEntityWithTag("wixie_wardrobe")
        if spawn then
            local x, y, z = spawn.Transform:GetWorldPosition()
            inst.Transform:SetPosition(x + 1, y, z + 1)
            spawn:PushEvent("wixie_wardrobe_shutter")
            
            if inst.DynamicShadow ~= nil then
                inst.DynamicShadow:Enable(false)
            end

            for i = 1, 4 do
                inst:DoTaskInTime(i, function()
                    spawn:PushEvent("wixie_wardrobe_shutter")
                end)
            end

            inst:DoTaskInTime(5, function()
                spawn:PushEvent("wixie_wardrobe_shake")

                inst:DoTaskInTime(20 * FRAMES, function()
                    inst.sg:GoToState("idle")
                    inst:Show()

                    if inst.DynamicShadow then
                        inst.DynamicShadow:Enable(true)
                    end

                    inst:PushEvent("knockback", {knocker = spawn, radius = 15, strengthmult = 1})

                    inst:DoTaskInTime(2, function()
                        inst.components.talker:Say(GetString(inst, "WIXIE_SPAWN"))
                    end)
                end)
            end)
        end
    end)

    TheWorld:PushEvent("ms_newplayerspawned", inst)
end

local NO_RIGHTCLICK_TAGS = {"woby", "customwobytag", "shadow", "shadowcreature", "shadowminion", "heavy", "heavyobject", "player"}
local function RightClickPicker(inst, target, pos)
    local notexamine
    if target then
        local actions = inst.components.playeractionpicker:GetSceneActions(target, true)
        for i, v in pairs(actions) do
            if target:IsActionValid(v.action, true) or v.action.rmb or v.action ~= ACTIONS.WALKTO and v.action ~= ACTIONS.LOOKAT and v.action ~= ACTIONS.PICKUP and v.action ~= ACTIONS.DIG and v.action ~= ACTIONS.HARVEST and v.action ~= ACTIONS.PICK and v.action ~= ACTIONS.FEED then
                notexamine = true
            end
        end
    end

    local validtargetaction
    local useitem = inst.replica.inventory:GetActiveItem()
    local equipitem = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipitem and equipitem:IsValid() then
        if target then
            local equipactions = inst.components.playeractionpicker:GetEquippedItemActions(target, equipitem, true)
            for i, v in pairs(equipactions) do
                validtargetaction = v
            end
        end
    end

    return inst:HasTag("wixie_tauntlevel_1") and target and target ~= inst and target:HasTag("_combat")
        and not target:HasAnyTag(NO_RIGHTCLICK_TAGS) and not validtargetaction and not notexamine and not useitem
        and inst.components.playeractionpicker:SortActionList({ACTIONS.WIXIE_TAUNT}, target, nil) or nil, true
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker then
        inst.components.playeractionpicker.rightclickoverride = RightClickPicker
    end
end

local function OnBuildAmmo(inst, data)
    if data.recipe.product and data.item and (inst:HasTag("wixie_ammocraft_3") and data.item:HasTag("wixieammo_special")
        or inst:HasTag("wixie_ammocraft_2") and data.item:HasTag("wixieammo_basic")) then
        for i = 1, 5 do
            --print("give me the special ammo")
            local addt_prod = SpawnPrefab(data.recipe.product)
            inst.components.inventory:GiveItem(addt_prod, nil, inst:GetPosition())
        end
    end
end

local function OnAttackOther(inst, data)
    local target, weapon = data and data.target, data and data.weapon
    local isriding = inst.components.rider and inst.components.rider:IsRiding()
    local shouldshove = target and (not weapon or weapon:HasTag("wixie_weapon"))
    if inst.sg then
        local shouldextinguish = weapon and not (weapon:HasTag("extinguisher") and target and target.components.burnable and target.components.burnable:IsBurning())
        local shovefrozen = not isriding and shouldshove and target and target.components.freezable and target.components.freezable:IsFrozen()
        if shouldshove and shouldextinguish or inst.sg.mem.dontuseweaponinstate then
            inst.sg.mem.dontuseweaponinstate = shouldshove and shouldextinguish or nil
        end
        if shovefrozen or inst.sg.mem.wixiefrozentargetshove then
            inst.sg.mem.wixiefrozentargetshove = shovefrozen or nil
        end
    end
    if not isriding and shouldshove then
        WixieShove(inst, target, inst.powerlevel, true, nil, nil, true)
    end
end

local function common_postinit(inst)
    inst:ListenForEvent("setowner", OnSetOwner)

    inst.avatar_tex = "avatar_wixie.tex"
    inst.avatar_atlas = "images/avatars/avatar_wixie.xml"

    inst.avatar_ghost_tex = "avatar_ghost_wixie.tex"
    inst.avatar_ghost_atlas = "images/avatars/avatar_ghost_wixie.xml"

    inst:AddTag("pebblemaker")
    inst:AddTag("slingshot_sharpshooter")
    inst:AddTag("troublemaker")

    inst.claustrophobia = 0
    inst.claustrophobiamodifier = 0
    inst.wixiepanic = false

    inst.GetClaustrophobia = GetClaustrophobia
    inst.CanGainClaustrophobia = CanGainClaustrophobia

    if not TheWorld.ismastersim or not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, OnInit)
    end

    if TheWorld.ismastersim then
        inst:ListenForEvent("equip", EquipedCount)
        inst:ListenForEvent("unequip", EquipUnequipCount)
        inst:ListenForEvent("newstate", OnNewState)
    end
end

local function master_postinit(inst)
    inst.starting_inventory = {"slingshot", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock", "slingshotammo_rock"}

    inst.MiniMapEntity:SetIcon("wixie.tex")
    --inst:AddComponent("claustrophobia")
	
    inst.customidleanim = customidleanimfn

    inst.components.health:SetMaxHealth(TUNING.WALTER_HEALTH)
    inst.components.hunger:SetMax(TUNING.WILSON_HUNGER)
    inst.components.sanity:SetMax(TUNING.WALTER_SANITY)

    inst.components.foodaffinity:AddPrefabAffinity("blueberrypancakes", 1.2)

    inst:ListenForEvent("onattackother", OnAttackOther)
    --inst:ListenForEvent("killed", OnKilledOther)

    inst.soundsname = "wixie"

    --inst:ListenForEvent("builditem", OnBuildAmmo)

    inst.OnNewSpawn = OnNewSpawn
end

STRINGS.CHARACTERS.WIXIE = require"speech_wixie"

return MakePlayerCharacter("wixie", prefabs, assets, common_postinit, master_postinit)
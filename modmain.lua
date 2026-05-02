local require = GLOBAL.require

require "um_pocketdimensioncontainers"

GLOBAL.UMCommonFns = require("tools/um_commonfns")
GLOBAL.MAX_GEM_TIER = 3
GLOBAL.MIN_GEM_TIER = 0

PrefabFiles = require("uncompromising_prefabs")
PreloadAssets = {
    Asset("IMAGE", "images/UM_tip_icon.tex"),
    Asset("ATLAS", "images/UM_tip_icon.xml"),
    --Asset("IMAGE", "images/giant_tree.tex"),
}
ReloadPreloadAssets()
-- Start the game mode
SignFiles = require("uncompromising_writeables")

local vanilla = require "screens/redux/scrapbookdata"
local uncomp = require "screens/redux/scrapbookdata_changes"

local valid_data = {
    "health",
    "damage",
    "burnable",
    "craftingprefab",
    "deps",
    "stacksize",
    "hungervalue",
    "healthvalue",
    "sanityvalue",
    "foodtype",
    "perishable",
    "specialinfo",
    "notes",
    "dapperness",
    "fueltype",
    "fuelvalue",
    "sanityaura",
    "finiteuses",
    "waterproofer",
    "damage",
    "armor",
    "absorb_percent",
    "forgerepairable",
    "armor_planardefense",
    "fueledmax",
    "fueledrate",
    "fueledtype1",
    "fueledtype2",
    "fueleduses",
    "weapondamage",
    "picakble",
    "insulator",
    "insulator_type"
}

AddPrefabPostInit("world", function(inst)
    inst:DoTaskInTime(0, function()
        for entry, data in pairs(vanilla) do
            for k, datatype in ipairs(valid_data) do
                if uncomp[entry] ~= nil and uncomp[entry][datatype] ~= nil and uncomp[entry][datatype] ~= vanilla[entry][datatype] then
                    vanilla[entry][datatype] = uncomp[entry][datatype]
                end
            end
        end
    end)
	GLOBAL.TheWorld:AddTag("um_beta") -- Added so it's easy to tell if the um beta is active
    if not inst.ismastersim then
        return
    end
end)

modimport("init/init_gamemodes/init_uncompromising_mode")
modimport("init/init_wathom")

local skilltree_defs = require("prefabs/skilltree_defs")
local BuildSkillsData = require("prefabs/skilltree_wixie")

if BuildSkillsData then
    RegisterSkilltreeBGForCharacter(GLOBAL.resolvefilepath("images/wixie_skilltree.xml"), "wixie")
    local data = BuildSkillsData(skilltree_defs.FN)
    for k, v in pairs(data.SKILLS) do
        if v.icon then
            RegisterSkilltreeIconsAtlas("images/wixie_skilltree.xml", v.icon .. ".tex")
        end
    end
end

if GetModConfigData("funny rat") then
    AddModCharacter("winky", "FEMALE")

    GLOBAL.TUNING.WINKY_HEALTH = 175
    GLOBAL.TUNING.WINKY_HUNGER = 175
    GLOBAL.TUNING.WINKY_SANITY = 125
end

GLOBAL.FUELTYPE.BATTERYPOWER = "BATTERYPOWER"
GLOBAL.FUELTYPE.SALT = "SALT"
GLOBAL.FUELTYPE.WOOL = "WOOL"
GLOBAL.FUELTYPE.EYE = "EYE"
GLOBAL.FUELTYPE.SLUDGE = "SLUDGE"
GLOBAL.UPGRADETYPES.ELECTRICAL = "ELECTRICAL"
GLOBAL.UPGRADETYPES.SLUDGE_CORK = "SLUDGE_CORK"
GLOBAL.UPGRADETYPES.SOUL_SHADOW = "SOUL_SHADOW"
GLOBAL.UPGRADETYPES.SOUL_LUNAR = "SOUL_LUNAR"
GLOBAL.MATERIALS.SLUDGE = "sludge"
GLOBAL.MATERIALS.COPPER = "copper"

if GetModConfigData("um_music", true) then
    AddPrefabPostInit("eyeofterror", function(inst)
	    RemoveRemapSoundEvent("terraria1/common/music_epicfight_eot")
    end)
    AddPrefabPostInit("twinofterror1", function(inst)
	    RemapSoundEvent("terraria1/common/music_epicfight_eot", "UMMusic2/music/um_epicfight_tot")
    end)
    AddPrefabPostInit("twinofterror2", function(inst)
	    RemapSoundEvent("terraria1/common/music_epicfight_eot", "UMMusic2/music/um_epicfight_tot")
    end)
    local track = math.random() > .01 and "UMMusic2/music/uncomp_char_select2" or "UMMusic/music/uncomp_char_select" -- Change chances to 50/50 later.
    RemapSoundEvent("dontstarve/together_FE/DST_theme_portaled", track)
    RemapSoundEvent("dontstarve/music/music_FE", "UMMusic/music/uncomp_main_menu")
end
AddShardModRPCHandler("UncompromisingSurvival", "Hayfever_Stop", function() GLOBAL.TheWorld:PushEvent("beequeenkilled") end)

AddShardModRPCHandler("UncompromisingSurvival", "Hayfever_Start", function(...) GLOBAL.TheWorld:PushEvent("beequeenrespawned") end)

local function WathomMusicToggle(level)
    if level ~= nil and GetModConfigData("um_music", true) then
        GLOBAL.TheWorld:PushEvent("enabledynamicmusic", false)
        GLOBAL.TheWorld.wathom_enabledynamicmusic = false
        if not GLOBAL.TheFocalPoint.SoundEmitter:PlayingSound("wathommusic") then
            GLOBAL.TheFocalPoint.SoundEmitter:PlaySound("UMMusic/music/" .. level, "wathommusic")
        end
    else
        if not GLOBAL.TheWorld.wathom_enabledynamicmusic then -- just so other things that killed the music don't get messed up.
            GLOBAL.TheWorld:PushEvent("enabledynamicmusic", true)
            GLOBAL.TheWorld.wathom_enabledynamicmusic = true
        end
        GLOBAL.TheFocalPoint.SoundEmitter:KillSound("wathommusic")
    end
end

-- wathomcustomvoice/wathomvoiceevent
local function DoAdrenalineUpStinger(sound)
    if type(sound) == "string" then
        GLOBAL.TheFrontEnd:GetSound():PlaySound("wathomcustomvoice/wathomvoiceevent/" .. sound)
    else
        GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve_DLC001/characters/wathgrithr/inspiration_down")
    end
end

local function GetTargetFocus(player, telebase, telestaff) telestaff.target_focus = telebase end

AddModRPCHandler("UncompromisingSurvival", "GetTargetFocus", GetTargetFocus)

local function GetAllActiveTelebases()
    local valid_telebases = {}
    for k, telebase in pairs(Ents) do
        if telebase.prefab == "telebase" then
            if telebase.canteleto(telebase) then
                table.insert(valid_telebases, telebase)
            end
        end
    end
    return valid_telebases
end

local function UpdateAllFocuses(player)
    for k, v in ipairs(GetAllActiveTelebases()) do
        v.update_location(v)
    end
end

AddClientModRPCHandler("UncompromisingSurvival", "UpdateAllFocuses", UpdateAllFocuses)

local function PianoPuzzleComplete1()
    local piano = TheSim:FindFirstEntityWithTag("wixie_piano")
    piano:PushEvent("pianopuzzlecomplete_1")
end

local function PianoPuzzleComplete2()
    local piano = TheSim:FindFirstEntityWithTag("wixie_piano")
    piano:PushEvent("pianopuzzlecomplete_2")
end

local function PianoPuzzleComplete3()
    local piano = TheSim:FindFirstEntityWithTag("wixie_piano")
    piano:PushEvent("pianopuzzlecomplete_3")
end

AddModRPCHandler("UncompromisingSurvival", "PianoPuzzleComplete1", PianoPuzzleComplete1)
AddModRPCHandler("UncompromisingSurvival", "PianoPuzzleComplete2", PianoPuzzleComplete2)
AddModRPCHandler("UncompromisingSurvival", "PianoPuzzleComplete3", PianoPuzzleComplete3)

AddClientModRPCHandler("UncompromisingSurvival", "WathomMusicToggle", WathomMusicToggle)
AddClientModRPCHandler("UncompromisingSurvival", "WathomAdrenalineStinger", DoAdrenalineUpStinger)

local function ToggleLagCompOn(self)
    if --[[not GLOBAL.IsDefaultScreen() or]] GLOBAL.ThePlayer == nil or GLOBAL.ThePlayer.hadcompenabled ~= nil then
        return
    end

    if GLOBAL.Profile:GetMovementPredictionEnabled() then
        GLOBAL.ThePlayer:EnableMovementPrediction(false)
        GLOBAL.Profile:SetMovementPredictionEnabled(false)

        -- GLOBAL.ThePlayer.HUD.controls.networkchatqueue:DisplaySystemMessage("The shadows have turned lag compensation off, it will be restored on nights end.")
        -- GLOBAL.TheNet:Announce("The shadows have turned lag compensation off, it will be restored on nights end.")

        if GLOBAL.ThePlayer.components.playercontroller:CanLocomote() then
            GLOBAL.ThePlayer.components.playercontroller.locomotor:Stop()
        else
            GLOBAL.ThePlayer.components.playercontroller:RemoteStopWalking()
        end

        GLOBAL.ThePlayer.hadcompenabled = true
    end
end

AddClientModRPCHandler("UncompromisingSurvival", "ToggleLagCompOn", ToggleLagCompOn)

local function ToggleLagCompOff(self)
    if --[[not GLOBAL.IsDefaultScreen() or]] GLOBAL.ThePlayer == nil or GLOBAL.ThePlayer.hadcompenabled == nil then
        return
    end

    if GLOBAL.ThePlayer.hadcompenabled then
        if not GLOBAL.Profile:GetMovementPredictionEnabled() then
            GLOBAL.ThePlayer:EnableMovementPrediction(true)
            GLOBAL.Profile:SetMovementPredictionEnabled(true)

            -- GLOBAL.ThePlayer.HUD.controls.networkchatqueue:DisplaySystemMessage("The shadows are gone, and lag compensation returns.")
            -- GLOBAL.TheNet:Announce("The shadows are gone, and lag compensation returns.")

            if GLOBAL.ThePlayer.components.playercontroller:CanLocomote() then
                GLOBAL.ThePlayer.components.playercontroller.locomotor:Stop()
            else
                GLOBAL.ThePlayer.components.playercontroller:RemoteStopWalking()
            end

            GLOBAL.ThePlayer.hadcompenabled = nil
        end
    end
end

AddClientModRPCHandler("UncompromisingSurvival", "ToggleLagCompOff", ToggleLagCompOff)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsDeath", function(...)
    if GLOBAL.TheWorld ~= nil and not GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("hasslerkilled")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsRemoved", function(...)
    if GLOBAL.TheWorld ~= nil and not GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("hasslerremoved")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsStored", function(...)
    if GLOBAL.TheWorld ~= nil and not GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("storehassler")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsDeath_caves", function(...)
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("hasslerkilled_secondary")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsRemoved_caves", function(...)
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("hasslerremoved")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "DeerclopsStored_caves", function(...)
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastershard then
        GLOBAL.TheWorld:PushEvent("storehassler")
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "CaveTornado", function(def, x, z, wise, dest_can_move)
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld:HasTag("cave") then
        GLOBAL.TheWorld:PushEvent("spawncavetornado", { xdata = x, zdata = z, wisedata = wise, dest_can_movedata = dest_can_move })
    end
end)

AddShardModRPCHandler("UncompromisingSurvival", "ToggleCaveHeatWave", function(sender_list, toggle)
    if toggle and GLOBAL.TheWorld ~= nil then
        GLOBAL.TheWorld:AddTag("heatwavestart")
        GLOBAL.TheWorld.net:AddTag("heatwavestartnet")
        GLOBAL.TheWorld:PushEvent("heatwavestart")
    elseif GLOBAL.TheWorld ~= nil then
        GLOBAL.TheWorld:RemoveTag("heatwavestart")
        GLOBAL.TheWorld.net:RemoveTag("heatwavestartnet")
        GLOBAL.TheWorld:PushEvent("heatwaveend")
    end
end)

local function LearnGemologyGem(data)
    data = GLOBAL.json.decode(data)
    GLOBAL.TheMineralLogbook:AddNewGem(data.gem, data.tier)
end

AddClientModRPCHandler("UncompromisingSurvival", "LearnGemologyGem", LearnGemologyGem)



-- WIXIE RELATED RPC'S

local function HandlerFunction(player, mouseposx, mouseposy, mouseposz)
    if GLOBAL.TheWorld.ismastersim then
        if mouseposx ~= nil then
            player.wixiepointx = mouseposx
        end

        if mouseposy ~= nil then
            player.wixiepointy = mouseposy
        end

        if mouseposz ~= nil then
            player.wixiepointz = mouseposz
        end
    else
        local wixieposition = GLOBAL.TheInput:GetWorldPosition()

        player.wixiepointx = wixieposition.x
        player.wixiepointy = wixieposition.y
        player.wixiepointz = wixieposition.z
    end
end

AddModRPCHandler("WixieTheDelinquent", "GetTheInput", HandlerFunction)

local function TornadoHandlingFunction(player, mouseposx, mouseposy, mouseposz)
    if GLOBAL.TheWorld.ismastersim then
        if mouseposx ~= nil then
            player.tornadopointx = mouseposx
        end

        if mouseposy ~= nil then
            player.tornadopointy = mouseposy
        end

        if mouseposz ~= nil then
            player.tornadopointz = mouseposz
        end
    else
        local tornadopoint = GLOBAL.TheInput:GetWorldPosition()

        player.tornadopointz = tornadopoint.x
        player.tornadopointz = tornadopoint.y
        player.tornadopointz = tornadopoint.z
    end
end

AddModRPCHandler("AllMouseGags", "GetTheInput", TornadoHandlingFunction)

local function ClaustrophobiaPanic(player, inst)
    if not (inst.components.health and inst.components.health:IsDead()) and not inst.sg:HasStateTag("wixiepanic") then
        inst.sg:GoToState("claustrophobic")
    end
end

AddModRPCHandler("WixieTheDelinquent", "ClaustrophobiaPanic", ClaustrophobiaPanic)

local function ClaustrophobiaEquipMult(claustrophobiamodifier)
    if GLOBAL.ThePlayer then
        GLOBAL.ThePlayer.claustrophobiamodifier = type(claustrophobiamodifier) == "string" and GLOBAL.tonumber(claustrophobiamodifier) or claustrophobiamodifier
    end
end

AddClientModRPCHandler("WixieTheDelinquent", "ClaustrophobiaEquipMult", ClaustrophobiaEquipMult)

local function ClaustrophobiaHidden(claustrophobiahidden)
    if GLOBAL.ThePlayer then
        GLOBAL.ThePlayer.claustrophobiahidden = claustrophobiahidden
    end
end

AddClientModRPCHandler("WixieTheDelinquent", "ClaustrophobiaHidden", ClaustrophobiaHidden)

if GetModConfigData("wixie_walter") then
    AddModCharacter("wixie", "FEMALE")

    GLOBAL.TUNING.WIXIE_HEALTH = 130
    GLOBAL.TUNING.WIXIE_HUNGER = 150
    GLOBAL.TUNING.WIXIE_SANITY = 200

    for k, v in pairs(GLOBAL.CLOTHING) do
        if v and v.symbol_overrides_by_character and v.symbol_overrides_by_character.walter then
            GLOBAL.CLOTHING[k].symbol_overrides_by_character.wixie = v.symbol_overrides_by_character.walter
        end
    end

    local skilltree_defs = require("prefabs/skilltree_defs")
    local BuildSkillsData = require("prefabs/skilltree_wixie")
    if BuildSkillsData then
        local data = BuildSkillsData(skilltree_defs.FN)

        skilltree_defs.CreateSkillTreeFor("wixie", data.SKILLS)
        skilltree_defs.SKILLTREE_ORDERS["wixie"] = data.ORDERS

        RegisterSkilltreeBGForCharacter(GLOBAL.resolvefilepath("images/wixie_skilltree.xml"), "wixie")
        for k, v in pairs(data.SKILLS) do
            if v.icon then
                RegisterSkilltreeIconsAtlas("images/wixie_skilltree.xml", v.icon .. ".tex")
            end
        end
    end
end

-- local skilltree_defs = require("prefabs/skilltree_defs")
-- local BuildSkillsData = require("prefabs/skilltree_wathom")
-- if BuildSkillsData then
	-- local data = BuildSkillsData(skilltree_defs.FN)

	-- skilltree_defs.CreateSkillTreeFor("wathom", data.SKILLS)
	-- skilltree_defs.SKILLTREE_ORDERS["wathom"] = data.ORDERS

	-- RegisterSkilltreeBGForCharacter(GLOBAL.resolvefilepath("images/wixie_skilltree.xml"), "wixie")
	-- for k, v in pairs(data.SKILLS) do
		-- if v.icon then
			-- RegisterSkilltreeIconsAtlas("images/wixie_skilltree.xml", v.icon .. ".tex")
		-- end
	-- end
-- end


--[[
AddShardModRPCHandler("UncompromisingSurvival", "AcidMushroomsUpdate", function(shard_id, data)
    GLOBAL.TheWorld:PushEvent("acidmushroomsdirty", {shard_id = shard_id, uuid = data.uuid, targets = data.targets})
end)

AddShardModRPCHandler("UncompromisingSurvival", "AcidMushroomsTargetFinished", function(shard_id, data)
    GLOBAL.TheWorld:PushEvent("master_acidmushroomsfinished", data)
end)]]
-- since ChangeImageName just does that, we need to assign the new atlas as well. I don't want to pack 2 images in the same atlas (mostly because idk how)

--Checks for projectinator/receptionator, basically blocking both the lazy deserter and desert stones
local _OldStartChannelingFn = GLOBAL.ACTIONS.STARTCHANNELING.fn
GLOBAL.ACTIONS.STARTCHANNELING.fn = function(act)
    local target = act.target
    local doer = act.doer
    if target ~= nil and doer ~= nil and doer:HasTag("um_astral_projected") then
        if target:HasTag("um_astral_projector") then
            return false
        end
        if target:HasTag("um_astral_projector_target") and doer.um_astral_target ~= target then
            return false
        end
        if target:HasTag("townportal") then
            return false
        end
    end
    return _OldStartChannelingFn(act)
end

local _OldTeleportFn = GLOBAL.ACTIONS.TELEPORT.fn
GLOBAL.ACTIONS.TELEPORT.fn = function(act)
    if act.doer ~= nil and act.doer:HasTag("um_astral_projected") then
        return false
    end
    return _OldTeleportFn(act)
end

GLOBAL.plaguemask_init_fn = function(inst, build_name) GLOBAL.basic_init_fn(inst, build_name, "hat_plaguemask") end

GLOBAL.plaguemask_clear_fn = function(inst) GLOBAL.basic_clear_fn(inst, "hat_plaguemask") end

GLOBAL.feather_frock_init_fn = function(inst, build_name) GLOBAL.basic_init_fn(inst, build_name, "featherfrock_ground") end

GLOBAL.feather_frock_clear_fn = function(inst) GLOBAL.basic_clear_fn(inst, "featherfrock_ground") end

GLOBAL.cursed_antler_init_fn = function(inst, build_name) GLOBAL.basic_init_fn(inst, build_name, "cursed_antler") end

GLOBAL.crystal_cursed_antler_init_fn = function(inst, build_name) GLOBAL.basic_init_fn(inst, build_name, "crystal_cursed_antler") end

GLOBAL.cursed_antler_clear_fn = function(inst) GLOBAL.basic_clear_fn(inst, "cursed_antler") end

GLOBAL.crystal_cursed_antler_init_fn = function(inst) GLOBAL.basic_clear_fn(inst, "crystal_cursed_antler") end

GLOBAL.ancient_amulet_red_init_fn = function(inst, build_name) GLOBAL.basic_init_fn(inst, build_name, "amulet_red_ground") end

GLOBAL.ancient_amulet_red_clear_fn = function(inst) GLOBAL.basic_clear_fn(inst, "amulet_red_ground") end

GLOBAL.TUNING.DSTU.MODROOT = MODROOT

modimport("init/init_statusannouncements")

AddSimPostInit(function()
    if not GLOBAL.TheNet:IsDedicated() then
        GLOBAL.ShadeRenderer:SetShadeTexture(GLOBAL.ShadeTypes.HoodedForestCanopy, GLOBAL.resolvefilepath("images/giant_tree.tex"))
    end
end)

modimport("init/um_tree_rock_data")
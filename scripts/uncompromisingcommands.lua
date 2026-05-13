require "webbedcreatureloot"

-- toggle snowstorm
function c_um_snowstorm()
    if TheWorld.components.um_snow_stormspawner ~= nil and TheWorld.state.iswinter then
        if TheWorld.components.um_snow_stormspawner:ToggleSnowstorm() then
            print("starting snowstorm...")
        else
            print("stopping snowstorm...")
        end
    end
end

local DEERCLOPS_TIMERNAME = "deerclops_timetoattack"
local MOTHERGOOSE_TIMERNAME = "mothergoose_timetoattack"
local MOCKFLY_TIMERNAME = "mockfly_timetoattack"
local BEARGER_TIMERNAME = "bearger_timetospawn"

function c_um_bosstimers()
    if TheWorld.ismastersim then
        TheNet:Announce("Checking Spawners...")
        local _worldsettingstimer = TheWorld.components.worldsettingstimer
        if TheWorld.state.iswinter then
            if _worldsettingstimer:ActiveTimerExists(DEERCLOPS_TIMERNAME) then
                TheNet:Announce("Found Deerclops timer, it has ".._worldsettingstimer:GetTimeLeft(DEERCLOPS_TIMERNAME).." seconds left till attacking.")
            else
                TheNet:Announce("Deerclops spawning timer doesn't exist.")
            end
        elseif TheWorld.state.isspring then
            if _worldsettingstimer:ActiveTimerExists(MOTHERGOOSE_TIMERNAME) then
                TheNet:Announce("Found Mother Goose timer, it has ".._worldsettingstimer:GetTimeLeft(MOTHERGOOSE_TIMERNAME).." seconds left till attacking.")
            else
                TheNet:Announce("Mother Goose spawning timer doesn't exist.")
            end        
        elseif TheWorld.state.issummer then
            if _worldsettingstimer:ActiveTimerExists(MOCKFLY_TIMERNAME) then
                TheNet:Announce("Found Wilting Dragonfly timer, it has ".._worldsettingstimer:GetTimeLeft(MOCKFLY_TIMERNAME).." seconds left till attacking.")
            else
                TheNet:Announce("Wilting Dragonfly spawning timer doesn't exist.")
            end            
        else
            if _worldsettingstimer:ActiveTimerExists(BEARGER_TIMERNAME) then
                TheNet:Announce("Found Bearger timer, it has ".._worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME).." seconds left till attacking.")
            else
                TheNet:Announce("Bearger spawning timer doesn't exist.")
            end                
        end
    else
        print("c_um_debug_bosstimers only works as the host")
    end
end


-- toggles vetcurse
function c_um_vetcurse()
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.health ~= nil and not player:HasTag("playerghost") then
        if not player:HasTag("vetcurse") then
            --player.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
            if player.UMToggleVetCurse then player:UMToggleVetCurse(true) end
            player:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_VETCURSE", 1 })
            print("added vetcurse")
        elseif player:HasTag("vetcurse") then
            --player.components.debuffable:RemoveDebuff("buff_vetcurse")
            if player.UMToggleVetCurse then player:UMToggleVetCurse() end
            print("removed vetcurse")
        end
    end
end

-- gives all current vet curse items
function c_um_vetcurseitems()
    local items = {
        "cursed_antler",
        "beargerclaw",
        "slobberlobber",
        "feather_frock",
        "gore_horn_hat",
        "klaus_amulet",
        "crabclaw",
        "um_beegun",
        --"um_wingsuit",
        --"um_exhumer",
        "um_moonfly_lantern",
        "silksack",
        "crystal_cursed_antler",
    }
    for k, v in ipairs(items) do
        c_give(v)
    end
    if KnownModIndex:IsModEnabled("workshop-1289779251") then
        c_give("um_beegun_cherry")
    end
end

-- Klei doesnt have a console command that changes max health???

function c_setmaxhealth(n)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.health ~= nil and not player:HasTag("playerghost") then
        player.components.health:SetPenalty(math.clamp(n, 0, TUNING.MAXIMUM_HEALTH_PENALTY))
    end
end

-- Pauses Woby's hunger drain

function c_woby_hunger()
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.woby ~= nil and player.woby.components.hunger ~= nil then
        if player.woby.components.hunger:IsPaused() then
            player.woby.components.hunger:Resume()
        else
            player.woby.components.hunger:Pause()
        end
    end
end

-- gives all current vet curse skulls

local vetskulls = {
    "walter_vetskull",
    "wortox_vetskull",
    "maxwell_vetskull",
    "willow_vetskull",
    "warly_vetskull",
    "winky_vetskull",
    "wickerbottom_vetskull",
    "wixie_vetskull",
    "woodie_vetskull",
    "wolfgang_vetskull",
    "wanda_vetskull",
    "wathgrithr_vetskull",
    "wes_vetskull",
    "wendy_vetskull",
}

function c_um_givevetskulls()
    for i, v in ipairs(vetskulls) do
        c_give(v)
    end
end

-- gives all current uncomp records

local records = {
    "um_record_menu",
    "um_record_walter",
    "um_record_wixie",
    "um_record_shadow_wixie",
    "um_record_hooded_widow",
    "um_record_moonmaw",
    "um_record_tot",
    "um_record_wathom",
    "um_record_stranger",
    "um_record_winky",
}

function c_um_giverecords()
    for i, v in ipairs(records) do
        c_give(v)
    end
end

-- lists current rat score shenenigans.
function c_um_ratcheck()
    local inst = TheSim:FindFirstEntityWithTag("rat_sniffer")
    inst:PushEvent("rat_sniffer")
    TheNet:SystemMessage("-------------------------")
    --TheNet:SystemMessage("Itemscore = " .. inst.itemscore)
    TheNet:SystemMessage("Foodscore = " .. inst.foodscore)
    TheNet:SystemMessage("Burrowbonus = " .. inst.burrowbonus)
    TheNet:SystemMessage("Ratscore = " .. inst.ratscore)
    if inst.ratscore > 300 then
        inst.ratscore = 300
    end
    --TheNet:SystemMessage("True Ratscore = " .. inst.ratscore)
    TheNet:SystemMessage("Timer = " .. TheWorld.components.ratcheck:GetRatTimer() .. "s")
    TheNet:SystemMessage("-------------------------")
end

-- forces an RNE.
-- function c_um_rne()
-- local rne = TheWorld.components.randomnightevents
-- rne:ForceRNE(true)
-- end

-- spawns a sunken chest at mouse pos
-- @royal: whether to spawn royal chest
-- examples:
-- c_um_spawnsunkenchest() spawns a vanilla treasure
-- c_um_spawnsunkenchest(true) spawns a royal chest
-- c_um_spawnsunkenchest(false) spawns a um normal chest
function c_um_spawnsunkenchest(royal)
    local pos = ConsoleWorldPosition()

    if royal ~= true and royal ~= false then
        local messagebottletreasures = require("messagebottletreasures")
        print("spawning normal sunken chest at X:" .. pos.x .. " Z:" .. pos.z)
        local treasure = messagebottletreasures.GenerateTreasure(pos)
        treasure.Transform:SetPosition(pos.x, pos.y, pos.z)
    elseif royal then
        local messagebottletreasures_um = require("messagebottletreasures_um")
        print("spawning royal sunken chest at X:" .. pos.x .. " Z:" .. pos.z)
        local treasure = messagebottletreasures_um.GenerateTreasure(pos, "sunkenchest_royal_random")
        treasure.Transform:SetPosition(pos.x, pos.y, pos.z)
    elseif not royal then
        local messagebottletreasures_um = require("messagebottletreasures_um")
        print("spawning UM normal sunken chest at X:" .. pos.x .. " Z:" .. pos.z)
        local treasure = messagebottletreasures_um.GenerateTreasure(pos, "sunkenchest")
        treasure.Transform:SetPosition(pos.x, pos.y, pos.z)
    else
        print("failed to spawn sunken chest")
    end
end

-- sets a tile by ID
-- defaults to barren if unspecified.
function c_um_settile(tile)
    if tile == nil then
        tile = 4
    end
    local pos = ConsoleWorldPosition()
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(pos.x, 0, pos.z)

    if tile ~= WORLD_TILES.MONKEY_DOCK then
        TheWorld.Map:SetTile(tile_x, tile_z, tile)
    else
        TheWorld.components.dockmanager:CreateDockAtPoint(pos.x, 0, pos.z, WORLD_TILES.MONKEY_DOCK) -- so it properly creates the undertile.
    end

    print("setting tile " .. tile .. " at " .. tile_x .. ", " .. tile_z)
end

-- cheap little shortcut to respawn ocean biomes...
function c_um_regenerateoceanbiomes()
    local um_areahandler = TheWorld.components.um_areahandler
    if um_areahandler ~= nil then
        --[[if TheWorld.state.isspring then
            um_areahandler:FullGenerate()
        else
            um_areahandler:GenerateInactiveBiomes()
        end]]
        um_areahandler:FullGenerate()
        print("Regenerated UM ocean biomes.")
    else
        print("Failed to regenerate UM ocean biomes. - um_areahandler is nil!")
    end
end

-- quick umss spawn command shortcut
-- umss is string!
function c_um_umss(umss)
    if type(umss) ~= "string" then
        print("Failed to spawn! Defined value must be a string.")
        return
    end

    local pos = ConsoleWorldPosition()
    local setpiece = SpawnPrefab("umss_general")
    setpiece.DefineTable(setpiece, umss)
    setpiece.Transform:SetPosition(pos.x, 0, pos.z)
    setpiece:AddTag("NOCLICK")
    setpiece.AnimState:SetMultColour(0, 0, 0, 0)
    setpiece:DoTaskInTime(1, setpiece.Remove)

    print("Spawning umss setpiece " .. umss .. " at " .. tostring(pos.x) .. "," .. tostring(pos.z) .. ".")
end

function c_um_setadrenaline(p)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.components.adrenaline ~= nil then
        player.components.adrenaline:SetPercent(p)
    end
end

local function CountLocalPrefabs(prefab, pos, set_radius)
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, set_radius)
    local count = 0

    for k, v in pairs(ents) do
        if v ~= nil and v.prefab ~= nil and v.prefab == prefab then
            count = count + 1
        end
    end

    print("There are ", count, prefab .. "s in this vicinity.")
end

function c_um_findents(radius, awake)
    local pos = ConsoleWorldPosition()
    local set_radius = radius ~= nil and radius or 50
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, set_radius)
    local alreadycounted_ents = {}

    for i, v in ipairs(ents) do
        if awake == nil or awake and v.entity:IsAwake() then
            local count = 0

            if v ~= nil and v.prefab ~= nil and not table.contains(alreadycounted_ents, v.prefab) then
                table.insert(alreadycounted_ents, v.prefab)
                CountLocalPrefabs(v.prefab, pos, set_radius)
            end
        end
    end
end

function c_um_forcetornado() TheWorld:PushEvent("forcetornado") end

function c_um_heatwave()
    if TheWorld.components.um_heatwaves ~= nil and TheWorld.state.issummer then
        if TheWorld.components.um_heatwaves:ToggleHeatWave() then
            print("starting heatwave...")
        else
            print("stopping heatwave")
        end
    end
end

local uncompfoods = {
    "beefalowings",
    "blueberrypancakes",
    "californiaking",
    "devilsfruitcake",
    "liceloaf",
    "seafoodpaella",
    "snotroast",
    "snowcone",
    "stuffed_peeper_poppers",
    "theatercorn",
    "um_boomberrypie",
    "um_boom_tart",
    "um_chiles_en_nogada",
    "um_deviled_eggs",
    "um_durian_cream_marshcake",
    "um_ghost_fajita",
    "um_rice_pudding",
    "um_rimeweed_spagett",
    "um_rimeweed_tequila",
    "um_sponge_cake",
    "viperjam",
    "zaspberryparfait",
}

if TUNING.DSTU.BONESTEW == "bone_appetit" then
    table.insert(uncompfoods, "um_kebab")
end

function c_um_givefoods()
    if ThePlayer ~= nil then
        for i, v in pairs(uncompfoods) do
            if ThePlayer.components.inventory ~= nil then
                local food = SpawnPrefab(v)
                food.Transform:SetPosition(ThePlayer.Transform:GetWorldPosition())

                ThePlayer.components.inventory:GiveItem(food)
            end
        end
    end
end

local function UM_ConsoleCommandPlayer()
    return (c_sel() ~= nil and c_sel():HasTag("player") and c_sel()) or ThePlayer or AllPlayers[1]
end

local function ListingOrConsolePlayer(input)
    if type(input) == "string" or type(input) == "number" then
        return UserToPlayer(input)
    end
    return input or UM_ConsoleCommandPlayer()
end

function c_um_wobygodmode(player)
    if TheWorld ~= nil and not TheWorld.ismastersim then
        c_remote("c_um_wobygodmode()")
        return
    end

    player = ListingOrConsolePlayer(player)
    if player ~= nil and player.woby ~= nil then
        SuUsed("c_um_wobygodmode", true)
        if player.woby.components.health ~= nil then
            local godmode = player.woby.components.health.invincible
            player.woby.components.health:SetInvincible(not godmode)
            print("God mode: " .. tostring(not godmode))
        end
    end
end

function c_um_setwobyhunger(p)
    local player = ConsoleCommandPlayer()
    if player ~= nil and player.woby ~= nil then
        player.woby.components.hunger:SetPercent(p)
    end
end

function c_um_listumprefabs()
    print("HERE --- ALL UM PREFABS")
    for k, v in pairs(TUNING.DSTU.PREFABS) do
        print(k)
        TheNet:Announce(k)
    end
end

function c_um_spawncocoon(type)
    type = string.upper(type)

    if table.contains(COCOON_CREATURES_DEFAULT, type) or table.contains(COCOON_CREATURES_SHIPWRECKED, type) or table.contains(COCOON_CHARACTERS, type) then
        local pos = ConsoleWorldPosition()
        print("Spawning cocoon at position X:" .. pos.x .. " Z:" .. pos.z .. " with type " .. type)

        local cocoon = SpawnPrefab("webbedcreature")
        cocoon.Transform:SetPosition(pos.x, 0, pos.z)

        cocoon.cocoon_creature = type
        cocoon.cocoon_data = COCOON_DEFS.DEFAULT[cocoon.cocoon_creature] ~= nil and COCOON_DEFS.DEFAULT[cocoon.cocoon_creature]
            or COCOON_DEFS.SHIPWRECKED[cocoon.cocoon_creature] ~= nil and COCOON_DEFS.SHIPWRECKED[cocoon.cocoon_creature]
            or COCOON_DEFS.CHARACTER[cocoon.cocoon_creature]

        if COCOON_DEFS.CHARACTER[cocoon.cocoon_creature] ~= nil then
            cocoon.cocoon_data.size = 1
            cocoon.cocoon_data.name = "Shrouded"
        end
    else
        print("Unable to spawn cocoon with type " .. type)
    end
end

-- NOTE (HALF): Congrats asgerrr your comment is now in UM and DF, HAHAHAHAHAHAHAHHA

--asgerrr: this one has been sitting in a txt file on my desktop for a long ass time lol
function c_changetile(tile, radius) 
    local center_dist = radius - 1 
    local center_x, center_y = TheWorld.Map:GetTileCoordsAtPoint(ConsoleWorldPosition():Get()) 
    for x = center_x-center_dist, center_x+center_dist, 1 do 
        for y = center_y-center_dist, center_y+center_dist, 1 do
            if GROUND_INVISIBLETILES[tile] then
                TheWorld.components.undertile:SetTileUnderneath(x, y, TheWorld.Map:GetTile(x, y))
            end
            TheWorld.Map:SetTile(x,y,WORLD_TILES[tile])
        end 
    end 
end

function c_gettile()
    local center_x, center_y = TheWorld.Map:GetTileCoordsAtPoint(ConsoleWorldPosition():Get()) 
    return INVERTED_WORLD_TILES[TheWorld.Map:GetTile(center_x, center_y)]
end

--This is for all players. If you don't care for entities, consider using
-- TheWorld.minimap.MiniMap:EnableFogOfWar(false)
function c_revealmap()
    local size = 2 * TheWorld.Map:GetSize()
    for _, player in pairs(AllPlayers) do
        for x = -size, size, 32 do
            for z = -size, size, 32 do
                player.player_classified.MapExplorer:RevealArea(x, 0, z)
            end
        end
    end

    print(TheWorld.Map:GetSize())
end

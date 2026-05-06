local MakePlayerCharacter = require("prefabs/player_common")

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
    Asset( "SOUND", "sound/wilson.fsb" ),
    Asset( "ANIM", "anim/beard.zip" ),

    -- Don't forget to include your character's custom assets!
    Asset( "ANIM", "anim/winky.zip" ),
    Asset( "ANIM", "anim/ghost_winky_build.zip" ),
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.WINKY
end

local prefabs = FlattenTree(start_inv, true)

local function RightClickPicker(inst, target, pos)
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

    return target and target == inst --and target.components.follower and target.components.follower:GetLeader() == inst --target:HasTag("winky_rat")
        and not validtargetaction and not useitem
        and inst.components.playeractionpicker:SortActionList({ACTIONS.RAT_ORDER}, target, nil) or nil, true
end

local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and useitem == nil then
        local rider = inst.replica.rider
        if rider == nil or not rider:IsRiding() and TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) ~= WORLD_TILES.FARMING_SOIL then
            return { ACTIONS.CREATE_BURROW }
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker then
        inst.components.playeractionpicker.rightclickoverride = RightClickPicker
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end

local function common_postinit(inst)
    inst.readytogather = net_bool(inst.GUID, "winky.readytogather")

    inst.avatar_tex   = "avatar_winky.tex"
    inst.avatar_atlas = "images/avatars/avatar_winky.xml"

    inst.avatar_ghost_tex   = "avatar_ghost_winky.tex"
    inst.avatar_ghost_atlas = "images/avatars/avatar_ghost_winky.xml"
    
    inst:AddTag("playermonster")
    inst:AddTag("monster")
    
    inst:ListenForEvent("setowner", OnSetOwner)
end

local function checkfav(inst, food)
    if food ~= nil then
        if food.prefab == "powcake" then
            inst.components.hunger:DoDelta(15)
            inst.components.health:DoDelta(15)
            inst.components.sanity:DoDelta(15)
        elseif food.prefab == "winter_food4" then
            inst.components.health:DoDelta(4)
            inst.components.sanity:DoDelta(4)
        end
    end
end

local function CustomFoodStatsMod(inst, health_delta, hunger_delta, sanity_delta, food, feeder)
    local gross_food_list = {
        "wormlight",
        "zaspberry",
        "potato",
        "onion",
        "garlic",
        "kelp",
        "boatpatch_kelp",
        "humanmeat",
        "humanmeat_dried",
        "deerclops_eyeball",
        "minotaurhorn",
        "ancientfruit_nightvision",
        "barnacle",
        "um_spongeplant_item",
        "phlegm",
        "milkywhites",
        "frogfishbowl",
        "devilsfruitcake",
    }
    for _, prefab in pairs(gross_food_list) do
        if food and (food.prefab == prefab or food.prefab == prefab .. "_cooked" or food.prefab == prefab .. "_lesser") and sanity_delta and sanity_delta < 0 then
            sanity_delta = 0
        end
        --[[if food and (food.prefab == prefab or food.prefab == prefab .. "_cooked" or food.prefab == prefab .. "_lesser") and health_delta and health_delta < 0 then
            health_delta = 0
        end]]
    end
    return health_delta, hunger_delta, sanity_delta
end

local function OnPickSomething(inst, data)
end

local function OnDropItem(inst, data)
    local item = data.item
	inst:DoTaskInTime(0, function()
		if not inst.no_sanity_drop and not item:HasTag("heavy") then
			inst.components.sanity:DoDelta(-5)
		end
	end)
end

local function sanityfn(inst)
    local sanityvalue = -5

    for i = 1, inst.components.inventory.maxslots do
        if inst.components.inventory:GetItemInSlot(i) ~= nil then
            sanityvalue = sanityvalue + 0.1
        end
    end

    return sanityvalue
end

local function WinkyDespawn(inst)
    inst.no_sanity_drop = true
end

local CURSED_SLOTS = {11, 12, 13, 14, 15}

local function CursedSlots(inst, slot)
	if not inst:HasTag("vetcurse") then
		return false
	end

	for _, blockedslot in ipairs(CURSED_SLOTS) do
		if blockedslot == slot then
			return true
		end
	end

	return false
end

local function CursedInventory(inst)
	if inst.components.inventory == nil then
		return
	end

	if inst:HasTag("vetcurse") then
		for slot = 11, 15 do
			local item = inst.components.inventory:GetItemInSlot(slot)
			if item ~= nil then
				inst.components.inventory:DropItem(item, true, true)
			end
		end
	end
end

local function master_postinit(inst)
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

     -- Minimap icon
    inst.MiniMapEntity:SetIcon("winky.tex")
    inst:AddTag("winky")
    inst:AddTag("ratwhisperer")

    -- choose which sounds this character will play
    inst.soundsname = "winky"

    inst.components.foodaffinity:AddPrefabAffinity("powcake", 20)
    inst.components.foodaffinity:AddPrefabAffinity("winter_food4", 20)

    if inst.components.eater then
        inst.components.eater:SetCanEatVeggieHorrible() -- Can eat UM_HORRIBLE_VEGGIE
        inst.components.eater:SetCanEatHorrible()
        inst.components.eater:SetStrongStomach(true) -- can eat monster meat!
        inst.components.eater:SetCanEatRawMeat(true)
        inst.components.eater:SetOnEatFn(checkfav)
        inst.components.eater.custom_stats_mod_fn = CustomFoodStatsMod
    end
    
    inst.components.sanity.night_drain_mult = TUNING.WENDY_SANITY_MULT
    inst.components.sanity.neg_aura_mult = TUNING.WENDY_SANITY_MULT

    inst.components.eater.spoiled_sanity = TUNING.WINKY_SPOILED_FOOD_SANITY --edible get sanity

	-- todo: Add an example special power here.
	inst.components.health:SetMaxHealth(175)
	inst.components.hunger:SetMax(175)
	inst.components.sanity:SetMax(125)
    --inst.components.sanity.custom_rate_fn = sanityfn

    inst.components.combat.damagemultiplier = TUNING.WENDY_DAMAGE_MULT
    if TheWorld.state.isnight then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "im_winky_mother_frikker", 1.25) 
    else
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "im_winky_mother_frikker", 1.15)
    end

    inst:WatchWorldState("isnight", function() 
        if TheWorld.state.isnight then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "im_winky_mother_frikker", 1.25) 
        else
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "im_winky_mother_frikker", 1.15)
        end
    end)
    
    --inst:ListenForEvent("picksomething", OnPickSomething)
    
    inst.no_sanity_drop = false
    inst:ListenForEvent("dropitem", OnDropItem)
    inst:ListenForEvent("um_combinestack", OnDropItem)
    inst:ListenForEvent("player_despawn", WinkyDespawn)
    --inst:ListenForEvent("itemlose", OnDropItem)
	inst:DoPeriodicTask(0, CursedInventory)

	if inst.components.inventory ~= nil then

		local old_giveitem = inst.components.inventory.GiveItem

		inst.components.inventory.GiveItem = function(self, item, slot, src_pos, ...)
			if slot ~= nil and CursedSlots(self.inst, slot) then
				self:DropItem(item, true, true)
				return false
			end

			return old_giveitem(self, item, slot, src_pos, ...)
		end
	end
end

return MakePlayerCharacter("winky", prefabs, assets, common_postinit, master_postinit)
local UpvalueHacker = require("tools/upvaluehacker")
-- Update for PAWN
AddAction("LAVASPIT", "LAVASPIT", function(act)
    if act.doer and act.target and act.doer.prefab == "dragonfly" then
        local spit = SpawnPrefab("lavaspit")
        local x, y, z = act.doer.Transform:GetWorldPosition()
        local downvec = TheCamera:GetDownVec()
        local offsetangle = math.atan2(downvec.z, downvec.x) * (180 / math.pi)
        if act.doer.AnimState:GetCurrentFacing() == 0 then -- Facing right
            offsetangle = offsetangle + 70
        else                                               -- Facing left
            offsetangle = offsetangle - 70
        end
        while offsetangle > 180 do offsetangle = offsetangle - 360 end
        while offsetangle < -180 do offsetangle = offsetangle + 360 end
        local offsetvec = Vector3(math.cos(offsetangle * DEGREES), -.3, math.sin(offsetangle * DEGREES)) * 1.7
        spit.Transform:SetPosition(x + offsetvec.x, y + offsetvec.y, z + offsetvec.z)
        spit.Transform:SetRotation(act.doer.Transform:GetRotation())
    end
end)

AddAction("INFEST", "INFEST", function(act)
    if not act.doer.infesting then act.doer.components.infester:Infest(act.target) end

    return true
end)

AddAction("UM_SILKWRAP", "UM_SILKWRAP", function(act)
    return act.target:WrapStuff(act.target)
end)

AddAction("UNCOMPROMISING_PAWN_HIDE", "UNCOMPROMISING_PAWN_HIDE", function(act)
    -- Dummy action for pawn.
end)

AddAction("UNCOMPROMISING_PAWN_SHAKE", "UNCOMPROMISING_PAWN_SHAKE", function(act)
    -- Dummy action for pawn.
end)

AddAction("RAT_STEAL_EQUIPPABLE", "RAT_STEAL_EQUIPPABLE", function(act)
    if act.target.components.container then
        act.target.components.container:DropOneItemWithTag("_equippable")
        return true
    end
end)
AddAction("RAT_STEAL_GEM", "RAT_STEAL_GEM", function(act)
    if act.target.components.container then
        act.target.components.container:DropOneItemWithTag("gem")
        return true
    end
end)

AddAction("CASTLIGHTER", "CASTLIGHTER", function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    local act_pos = act:GetActionPoint()
    if staff and staff:HasTag("lighter") and staff.components.spellcaster and staff.components.spellcaster:CanCast(act.doer, act.target, act_pos) then
        staff.components.spellcaster:CastSpell(act.target, act_pos)
        return true
    end
end)

local wingsuit = AddAction("WINGSUIT", "WINGSUIT", function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
    local act_pos = act:GetActionPoint()
    if staff and staff:HasTag("um_wingsuit") then
        act.doer:ForceFacePoint(act_pos.x, 0, act_pos.z)

        return true
    end
end)

wingsuit.priority = HIGH_ACTION_PRIORITY
wingsuit.rmb = true
wingsuit.distance = 20
wingsuit.mount_valid = false

local createburrow = AddAction("CREATE_BURROW", GLOBAL.STRINGS.ACTIONS.CREATE_BURROW, function(act)
    local act_pos = act:GetActionPoint()
    if act.doer.components.hunger.current > 15 and not GLOBAL.TheWorld.Map:GetPlatformAtPoint(act_pos.x, act_pos.z) then
        local burrows = GLOBAL.TheSim:FindEntities(act_pos.x, 0, act_pos.z, 10000, { "winkyburrow" })
        local home = false

        for i, v in pairs(burrows) do if v.myowner == act.doer.userid then home = true end end

        if home then
            local burrow = GLOBAL.SpawnPrefab("uncompromising_winkyburrow")
            burrow.Transform:SetPosition(act_pos.x, 0, act_pos.z)
            act.doer.components.hunger:DoDelta(-15)
        else
            local burrow = GLOBAL.SpawnPrefab("uncompromising_winkyhomeburrow")
            burrow.Transform:SetPosition(act_pos.x, 0, act_pos.z)
            burrow.myowner = act.doer.userid

            act.doer.components.hunger:DoDelta(-20)
        end

        return true
    end
end)

createburrow.priority = HIGH_ACTION_PRIORITY
createburrow.rmb = true
createburrow.distance = 2
createburrow.mount_valid = false

local charge_powercell = AddAction("CHARGE_POWERCELL", GLOBAL.STRINGS.ACTIONS.CHARGE_POWERCELL, function(act)
    local target = act.target or act.invobject

    if (target ~= nil and target:HasTag("powercell")) and (act.doer ~= nil and act.doer:HasTag("batteryuser")) then
        act.doer.components.batteryuser:ChargeFrom(target)
        return true
    else
        return false
    end
end)

charge_powercell.instant = true
charge_powercell.rmb = true
charge_powercell.priority = HIGH_ACTION_PRIORITY

-- Rummaging is opening containers.
-- Any character can open Warly's Portable Crock Pot.
local _RummageFn = GLOBAL.ACTIONS.RUMMAGE.fn
GLOBAL.ACTIONS.RUMMAGE.fn = function(act)
    local target = act.target or act.invobject
    if target == nil then
        return
    end
    if target.prefab == "portablecookpot" and target ~= nil and target.components.container ~= nil
        and target.components.container.canbeopened and GLOBAL.CanEntitySeeTarget(act.doer, target) then
        if target.components.container:IsOpenedBy(act.doer) then
            target.components.container:Close(act.doer)
            act.doer:PushEvent("closecontainer", { container = target })
            return true
        end
        act.doer:PushEvent("opencontainer", { container = target })
        target.components.container:Open(act.doer)
        return true
    end
    return _RummageFn(act)
end

local _ChopFn = GLOBAL.ACTIONS.CHOP.fn

GLOBAL.ACTIONS.CHOP.fn = function(act)
    if act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS) and act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS).prefab == "um_shadow_axe" then --Shadow Axe Support
        local axe = act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        axe.WorkEffect(axe, act.doer, act.target)
    end

    return _ChopFn(act)
end

local _spellbookstrfn = GLOBAL.ACTIONS.USESPELLBOOK.strfn
GLOBAL.ACTIONS.USESPELLBOOK.strfn = function(act)
    if act and act.invobject and act.invobject.prefab == "um_detonator" then
        return "UM_DETONATE"
    else
        return _spellbookstrfn(act)
    end
end

--[[local _lookatstrfn = GLOBAL.ACTIONS.LOOKAT.strfn
GLOBAL.ACTIONS.LOOKAT.strfn = function(act)
	if act.target and act.target:HasTag("ancient_text") then
		if act.doer and act.doer.components.skilltreeupdater and act.doer.components.skilltreeupdater:IsActivated("wathom_allegiance_neutral") then
			return "READ"
		end
	else
		return _lookatstrfn(act)
	end
end]]

--if TUNING.DSTU.WICKERNERF then
--local _ReadFn = GLOBAL.ACTIONS.READ.fn

--GLOBAL.ACTIONS.READ.fn = function(act)
--local targ = act.target or act.invobject
--if targ ~= nil and act.doer ~= nil and not act.doer:HasTag("aspiring_bookworm") then if targ.components.book ~= nil and act.doer.components.reader ~= nil and act.doer.components.sanity ~= nil and act.doer.components.sanity:IsInsane() then return false end end

--return _ReadFn(act)
--end
--end

-- Storing is drag-clicking an item into a container.
-- Any character can store items into Warly's Portable Crock Pot.
local _StoreFn = GLOBAL.ACTIONS.STORE.fn
GLOBAL.ACTIONS.STORE.fn = function(act)
    local target = act.target

    if target:HasTag("pocketbackpack") and not target.components.equippable.isequipped and act.target.components.inventoryitem.owner ~= nil then
        return false
    elseif target.prefab == "portablecookpot" and target.components.container ~= nil and act.invobject.components.inventoryitem ~= nil
        and act.doer.components.inventory ~= nil and target.components.container:CanTakeItemInSlot(act.invobject) then
        local item = act.invobject.components.inventoryitem:RemoveFromOwner(target.components.container.acceptsstacks)
        if item ~= nil then
            if not target.components.container:GiveItem(item, targetslot, nil, false) then
                if act.doer.components.playercontroller ~= nil and
                    act.doer.components.playercontroller.isclientcontrollerattached then
                    act.doer.components.inventory:GiveItem(item)
                else
                    act.doer.components.inventory:GiveActiveItem(item)
                end
                return false
            end
            return true
        end
    end
    return _StoreFn(act)
end

local _UpgradeStrFn = GLOBAL.ACTIONS.UPGRADE.strfn

GLOBAL.ACTIONS.UPGRADE.strfn = function(act)
    if act.target ~= nil and act.target:HasTag(GLOBAL.UPGRADETYPES.SLUDGE_CORK .. "_upgradeable") then return "SLUDGE_CORK" end
    if act.target ~= nil and act.target.prefab == "nightmarefuel" then return "SOUL" end
    if act.target ~= nil and act.target.prefab == "horrorfuel" then return "SOUL" end
    if act.target ~= nil and act.target.prefab == "moon_tree_blossom" then return "SOUL_LUNAR" end
    if act.target ~= nil and act.target.prefab == "purebrilliance" then return "SOUL_LUNAR" end
    return _UpgradeStrFn(act)
end

local _AddFuelFn = GLOBAL.ACTIONS.ADDFUEL.fn
local _AddWetFuelFn = GLOBAL.ACTIONS.ADDWETFUEL.fn

GLOBAL.ACTIONS.ADDFUEL.fn = function(act)
    if act.doer.components.inventory and act.invobject.components.finiteuses ~= nil and act.invobject:HasTag("sludge_oil") then
        local fuel = act.invobject
        if fuel then
            if act.target.components.fueled and act.target.components.fueled:TakeFuelItem(fuel, act.doer) then
                return true
            else
                act.doer.components.inventory:GiveItem(fuel)
            end
        end
    else
        return _AddFuelFn(act)
    end
end

GLOBAL.ACTIONS.ADDWETFUEL.fn = function(act) -- I'M GOING TO ***BOMB KLEI*** WHY THE *FUCK* IS WETFUEL IT'S OWN ACTION.
    if act.doer.components.inventory and act.invobject.components.finiteuses ~= nil and act.invobject:HasTag("sludge_oil") then
        local fuel = act.invobject
        if fuel then
            if act.target.components.fueled and act.target.components.fueled:TakeFuelItem(fuel, act.doer) then
                return true
            else
                act.doer.components.inventory:GiveItem(fuel)
            end
        end
    else
        return _AddWetFuelFn(act)
    end
end

local _UseSpellBookStrFn = GLOBAL.ACTIONS.USESPELLBOOK.strfn

GLOBAL.ACTIONS.USESPELLBOOK.strfn = function(act)
    local target = act.invobject or act.target
    return target:HasTag("telestaff") and "TELESTAFF" or _UseSpellBookStrFn ~= nil and _UseSpellBookStrFn(act) or "BOOK"
end

local SET_CUSTOM_NAME = GLOBAL.Action({ distance = 2, mount_valid = true })
SET_CUSTOM_NAME.id = "SET_CUSTOM_NAME"
SET_CUSTOM_NAME.str = STRINGS.ACTIONS.SET_CUSTOM_NAME
AddAction(SET_CUSTOM_NAME)

SET_CUSTOM_NAME.fn = function(act)
    local focus = nil
    if act.target and act.target:HasTag("telebase") or act.target.prefab == "pocketwatch_portal" or act.target.prefab == "pocketwatch_recall" --[[or act.target:HasTag("_equippable")]] then focus = act.target end

    if focus and focus.components.writeable then
        if focus.components.writeable:IsBeingWritten() then return false, "INUSE" end

        act.doer.tool_prefab = act.invobject.prefab
        if act.invobject.components.stackable then
            act.invobject.components.stackable:Get():Remove()
        else
            act.invobject:Remove()
        end

        focus.components.writeable:BeginWriting(act.doer)

        return true
    end
end

GLOBAL.ACTIONS.CHANGEIN.rmb = true
GLOBAL.ACTIONS.CHANGEIN.priority = 10
GLOBAL.ACTIONS.REPAIR.distance = 2.5

local STORE_BOAT = GLOBAL.Action({ distance = 10, mount_valid = false })
STORE_BOAT.id = "STORE_BOAT"
STORE_BOAT.str = "Store Boat"

STORE_BOAT.fn = function(act)
    local shore_pt
    local boat, bottle = act.target, act.invobject

    if boat ~= nil and boat:HasTag("walkableplatform") and boat.components.walkableplatform ~= nil then
        for k in pairs(boat.components.walkableplatform:GetEntitiesOnPlatform()) do
            if k:HasTag("player") then
                return false, "PLAYER_ON_PLATFORM"
            end

            if k.components.container ~= nil then
                k.components.container:DropEverything()
            end

            if k.components.inventory ~= nil then
                k.components.inventory:DropEverything()
            end
        end

        bottle.components.boatbottle:DoFullRecord(act.target)
        local collected_entities = {}

        for k in pairs(boat.components.walkableplatform:GetEntitiesOnPlatform()) do
            if k.components.drownable ~= nil then
                if shore_pt == nil then
                    shore_pt = GLOBAL.Vector3(GLOBAL.FindRandomPointOnShoreFromOcean(k.Transform:GetWorldPosition()))
                end
                k:PushEvent("onsink", { boat = boat, shore_pt = shore_pt })
            end

            if not k:HasOneOfTags("ignorewalkableplatforms", "ignorewalkableplatformdrowning", "activeprojectile", "flying", "FX", "DECOR", "INLIMBO", "player") and not k.components.drownable ~= nil then
                table.insert(collected_entities, k)
            end
        end

        for k, v in ipairs(collected_entities) do
            if v.components.mast ~= nil then
                v:AddTag("no_mast_sinking")
            end
            v:Remove()
        end

        GLOBAL.SpawnPrefab("fx_boat_pop").Transform:SetPosition(boat.Transform:GetWorldPosition())
        boat:Remove()

        return true
    end
    return false
end

AddAction(STORE_BOAT)
--RELEVANT: playeractionpicker postinit


AddComponentAction("USEITEM", "drawingtool",
    function(inst, doer, target, actions, right)
        if target:HasTag("telebase") or
            target.prefab == "pocketwatch_recall" or
            target.prefab == "pocketwatch_portal" then
            table.insert(actions, GLOBAL.ACTIONS.SET_CUSTOM_NAME)
        end
    end)

AddComponentAction("USEITEM", "boatbottle",
    function(inst, doer, target, actions, right)
        if target:HasTag("walkableplatform") and not inst:HasTag("filled_boat_bottle") then
            table.insert(actions, GLOBAL.ACTIONS.STORE_BOAT)
        end
    end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.STORE_BOAT, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.STORE_BOAT, "dolongaction"))


if TUNING.DSTU.WARLY_CHANGES ~= 0 then
    local _murderfn = GLOBAL.ACTIONS.MURDER.fn
    GLOBAL.ACTIONS.MURDER.fn = function(act)
        local murdered = act.invobject or act.target
        if murdered ~= nil and (murdered.components.health ~= nil or murdered.components.murderable ~= nil) and act.doer ~= nil and act.doer:HasTag("masterchef") then
            local stacksize = murdered.components.stackable ~= nil and murdered.components.stackable:StackSize() or 1
            local x, y, z = act.doer.Transform:GetWorldPosition()

            if murdered.components.lootdropper ~= nil then
                murdered.causeofdeath = act.doer
                local pos = GLOBAL.Vector3(x, y, z)
                for i = 1, stacksize do
                    local loots = murdered.components.lootdropper:GenerateLoot()
                    local lootprefab = loots[#loots > 1 and math.random(#loots) or 1]

                    if lootprefab ~= nil then
                        local loot = GLOBAL.SpawnPrefab(lootprefab)
                        if loot ~= nil then
                            act.doer.components.inventory:GiveItem(loot, nil, pos)
                        end
                    end
                end
            end

            if murdered.components.inventory and murdered:HasTag("drop_inventory_onmurder") then
                murdered.components.inventory:TransferInventory(act.doer)
            end
        end
        return _murderfn(act)
    end
end

if TUNING.DSTU.WXLESS then
    local BREAK_DOWN_MODULE = GLOBAL.Action({ priority = 4, mount_valid = true })
    BREAK_DOWN_MODULE.id = "BREAK_DOWN_MODULE"
    BREAK_DOWN_MODULE.str = "Dismantle"
    AddAction(BREAK_DOWN_MODULE)
    BREAK_DOWN_MODULE.fn = function(act)
        if act.invobject and act.invobject.components.data_extractor and act.target.components.upgrademodule then
            return act.invobject.components.data_extractor:BreakDown(act.target, act.doer)
        end
    end
    AddComponentAction("USEITEM", "data_extractor", function(inst, doer, target, actions, right)
        if doer:HasTag('upgrademoduleowner') and target:HasTag('upgrademodule') then
            table.insert(actions, GLOBAL.ACTIONS.BREAK_DOWN_MODULE)
        end
    end)

    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BREAK_DOWN_MODULE, "dolongaction"))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BREAK_DOWN_MODULE, "dolongaction"))
end

GLOBAL.STRINGS.ACTIONS.START_CHANNELCAST.MOONFALL = "Start Casting"

local _Start_ChannelCastStrFn = GLOBAL.ACTIONS.START_CHANNELCAST.strfn
GLOBAL.ACTIONS.START_CHANNELCAST.strfn = function(act)
    return act.invobject and act.invobject:HasTag("moonfallstaff") and "MOONFALL" or _Start_ChannelCastStrFn(act)
end

AddComponentAction("USEITEM", "fuel", function(inst, doer, target, actions)
    if not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())
        or (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer)) then
        if inst.prefab ~= "spoiled_food" and
            inst:HasTag("quagmire_stewable") and
            target:HasTag("quagmire_stewer") and
            target.replica.container ~= nil and
            target.replica.container:IsOpenedBy(doer) then
            return
        end

        if inst:HasTag("SLUDGE_fuel") and (target:HasTag("BURNABLE_fueled") or target:HasTag("CHEMICAL_fueled") or target:HasTag("CAVE_fueled")) then
            table.insert(actions, inst:GetIsWet() and GLOBAL.ACTIONS.ADDWETFUEL or GLOBAL.ACTIONS.ADDFUEL)
        end
    end
end)

AddComponentAction("EQUIPPED", "wateryprotection", function(inst, doer, target, actions, right) -- Washable stuff.
    if right and target:HasTag("um_washable_goo") then
        table.insert(actions, GLOBAL.ACTIONS.POUR_WATER)
    end
end)

AddComponentAction("SCENE", "stewer_wagstaff", function(inst, doer, actions, right)
    if not inst:HasTag("burnt") and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then
        if inst:HasTag("donecooking") then
            table.insert(actions, GLOBAL.ACTIONS.HARVEST)
        elseif right and (
                (inst:HasTag("readytocook") and
                    --(not inst:HasTag("professionalcookware") or doer:HasTag("professionalchef")) and
                    (not inst:HasTag("mastercookware") or doer:HasTag("masterchef"))
                ) or
                (inst.replica.container ~= nil and
                    inst.replica.container:IsFull() and
                    inst.replica.container:IsOpenedBy(doer)
                )
            ) then
            table.insert(actions, GLOBAL.ACTIONS.COOK)
        end
    end
end)

-- AddComponentAction("SCENE", "pickable", function(inst, doer, actions)
-- if (inst:HasTag("pickable") and not (inst:HasTag("fire") or inst:HasTag("intense"))) or actions == GLOBAL.ACTIONS.SCYTHE then
-- table.insert(actions, GLOBAL.ACTIONS.PICK)
-- end
-- end)

-- AddComponentAction("VALID", "pickable", function(inst, action, right)
-- local valid = right and action == GLOBAL.ACTIONS.SCYTHE -- Can scythe the air

-- if valid then return true end
-- end)

-- Wagstaff crockpot actions...
local _OldCook = GLOBAL.ACTIONS.COOK.fn
GLOBAL.ACTIONS.COOK.fn = function(act)
    if act.target.prefab == "um_cookpot_wagstaff" then
        if act.target.components.stewer_wagstaff:IsCooking() then
            --Already cooking
            return true
        end
        local container = act.target.components.container
        if container ~= nil and container:IsOpenedByOthers(act.doer) then
            return false, "INUSE"
        elseif not act.target.components.stewer_wagstaff:CanCook() then
            return false
        end
        act.target.components.stewer_wagstaff:StartCooking(act.doer)
        return true
    else
        return _OldCook(act)
    end
end

GLOBAL.STRINGS.ACTIONS.UM_GUNSHOOTY = "Shoot"
local um_gunshooty = GLOBAL.Action({ priority = -1, rmb = true, distance = 40, mount_valid = true })
um_gunshooty.id = "UM_GUNSHOOTY"
um_gunshooty.str = GLOBAL.STRINGS.ACTIONS.UM_GUNSHOOTY
um_gunshooty.fn = function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local act_pos = act:GetActionPoint()
    if staff and staff.components.spellcaster then
        if staff.components.itemmimic and staff.components.itemmimic.fail_as_invobject then
            return false, "ITEMMIMIC"
        end

        local can_cast, cant_cast_reason = staff.components.spellcaster:CanCast(act.doer, act.target, act_pos)
        if can_cast then
            staff.components.spellcaster:CastSpell(act.target, act_pos, act.doer)
            return true
        end
        return can_cast, cant_cast_reason
    end
end

AddAction(um_gunshooty)

AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(GLOBAL.EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local POINT, EQUIPPED = COMPONENT_ACTIONS.POINT, COMPONENT_ACTIONS.EQUIPPED
        if POINT then
            local OldPOINT_fn = POINT["spellcaster"]
            if OldPOINT_fn then
                POINT["spellcaster"] = function(inst, doer, pos, actions, right, target, ...)
                    if inst:HasTag("um_gun") then
                        if not right then
                            return
                        end
                        local cast_on_water = inst:HasTag("castonpointwater")
                        if inst:HasTag("castonpoint") then
                            local px, py, pz = pos:Get()
                            if GLOBAL.TheWorld.Map:IsAboveGroundAtPoint(px, py, pz, cast_on_water) and not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, GLOBAL.ACTIONS.UM_GUNSHOOTY)
                            end
                        elseif cast_on_water then
                            local px, py, pz = pos:Get()
                            if GLOBAL.TheWorld.Map:IsOceanAtPoint(px, py, pz, false) and not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, GLOBAL.ACTIONS.UM_GUNSHOOTY)
                            end
                        end
                        return
                    end
                    return OldPOINT_fn(inst, doer, pos, actions, right, target, ...)
                end
            end
        end
        if EQUIPPED then
            local OldEQUIPPED_fn = EQUIPPED["spellcaster"]
            if OldEQUIPPED_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    if inst:HasTag("um_gun") then
                        if right and (inst:HasTag("castontargets") or (target:HasTag("locomotor") and (inst:HasTag("castonlocomotors")
                                    or (inst:HasTag("castonlocomotorspvp") and (target == doer or GLOBAL.TheNet:GetPVPEnabled() or not (target:HasTag("player") and doer:HasTag("player"))))))
                                or (inst:HasTag("castoncombat") and doer.replica.combat and doer.replica.combat:CanTarget(target))) then
                            table.insert(actions, GLOBAL.ACTIONS.UM_GUNSHOOTY)
                        end
                        return
                    end
                    return OldEQUIPPED_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)

local _OldHarvest = GLOBAL.ACTIONS.HARVEST.fn
GLOBAL.ACTIONS.HARVEST.fn = function(act)
    if act.target.prefab == "um_cookpot_wagstaff" then
        return act.target.components.stewer_wagstaff:Harvest(act.doer)
    else
        return _OldHarvest(act)
    end
end

local _PICKUP = _G.ACTIONS.PICKUP.fn
_G.ACTIONS.PICKUP.fn = function(act, ...)
    if act.doer:HasTag("player") and act.doer.components.inventory and act.target and act.target.components.inventoryitem and act.target.um_no_pickup then return false end
    return _PICKUP(act, ...)
end

-- Scythes can reach into the thicket without needing to be on top of them
GLOBAL.ACTIONS.SCYTHE.distance = 2.5

-- Card actions are instant for now.
GLOBAL.ACTIONS.DRAW_FROM_DECK.instant = true
GLOBAL.ACTIONS.FLIP_DECK.instant = true
GLOBAL.ACTIONS.ADD_CARD_TO_DECK.instant = true

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local UM_ACTIVATABLE_ITEM = Action({ mount_valid = true, priority = 1, rmb = true })
UM_ACTIVATABLE_ITEM.id = "UM_ACTIVATABLE_ITEM"
UM_ACTIVATABLE_ITEM.str = STRINGS.ACTIONS.UM_ACTIVATABLE_ITEM
ENV.AddAction(UM_ACTIVATABLE_ITEM)

UM_ACTIVATABLE_ITEM.strfn = function(act)
    return act.invobject ~= nil and act.invobject.actiontype ~= nil and act.invobject.actiontype or STRINGS.ACTIONS.UM_ACTIVATABLE_ITEM.GENERIC
end

UM_ACTIVATABLE_ITEM.fn = function(act)
    local item = act.invobject
    if item ~= nil and item.components.um_activatable_item ~= nil then
        item.components.um_activatable_item:Activate(act.doer)
        return true
    end
end

ENV.AddComponentAction("INVENTORY", "um_activatable_item", function(inst, doer, actions, right)
    if inst ~= doer then
        table.insert(actions, ACTIONS.UM_ACTIVATABLE_ITEM)
    end
end)

local SCAN_GEMOLOGY_GEM = Action({ mount_valid = false, priority = 10, rmb = false })
SCAN_GEMOLOGY_GEM.id = "SCAN_GEMOLOGY_GEM"
SCAN_GEMOLOGY_GEM.str = "Analyze"
ENV.AddAction(SCAN_GEMOLOGY_GEM)
SCAN_GEMOLOGY_GEM.fn = function(act)
    local gem = act.target
    if gem ~= nil and gem:HasTag("gemology_gem") and act.invobject ~= nil and act.invobject.components.gemologyscanner ~= nil then
        act.invobject.components.gemologyscanner:Scan(gem, act.doer)
        return true
    end
    return false, "GEM_ALREADY_KNOWN"
end

ENV.AddComponentAction("USEITEM", "gemologyscanner", function(inst, doer, target, actions, right)
    local known, tier = TheMineralLogbook:IsGemKnown(target.prefab)
    if inst ~= nil and inst:HasTag("gemologyscanner") and target ~= nil and target:HasTag("gemology_gem") then
        if not target:IsRevealed() or not known or tier < target:GetTier() then
            table.insert(actions, ACTIONS.SCAN_GEMOLOGY_GEM)
        end
    end
end)

ENV.AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SCAN_GEMOLOGY_GEM, "dolongaction"))
local Vector3 = GLOBAL.Vector3
local require = GLOBAL.require
local ACTIONS = GLOBAL.ACTIONS
local Inv = require "widgets/inventorybar"
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local SpawnPrefab = GLOBAL.SpawnPrefab

local containers = require("containers")
--[[
AddComponentPostInit("container", function(self)
	function self:RemoveSingleItemBySlot(slot)
		if slot and self.slots[slot] then
			local item = self.slots[slot]
			return self:RemoveItem(item)
		end
	end
end)
]]
function CheckMush(container, item, slot)
    return item:HasTag("mushroom_fuel")
end

local wardrobe_tags = {
    "_equippable",
    "reloaditem_ammo",
    "tool",
    "weapon",
    "heatrock",
    "fan",
    "pocketwatch",
    "trap",
    "mine",
    "broken",
}

local wardrobe_prefabs = {
    "razor",
    "beef_bell",
    "pocketwatch_parts",
    "pocketwatch_dismantler",
    "sewing_tape",
    "sewing_kit",
    "lunarplant_kit",
    "voidcloth_kit",
    "wagpunkbits_kit",
	"spiderden_bedazzler",
	"spider_whistle",
	"spider_repellent",
    "sludge_oil",
    "saddle_basic",
    "saddle_race",
    "saddle_war",
    "saddle_wathgrithr",
    "saddle_shadow",
}

function CheckWardrobeItem(container, item, slot)
    if item:HasOneOfTags(wardrobe_tags) then
        return true
    end


    for _, prefab in pairs(wardrobe_prefabs) do
        if item.prefab == prefab then
            return true
        end
    end

    return string.match(item.prefab, "wx78module_") ~= nil
end

function CheckToolboxItem(container, item, slot)
    return item:HasTag("toolbox_item") or item:HasTag("gem") or (GetModConfigData("toolbox_tools") and item:HasTag("tool")) or item:HasTag("portableitem") or item:HasTag("NIGHTMARE_fuel")
end

function CheckEquipItem(container, item, slot)
    return item:HasTag("_equippable")
end

function CheckBee(container, item, slot)
    return item:HasTag("bee")
end

function CheckGem(container, item, slot)
    return not item:HasTag("irreplaceable") and item:HasTag("gem")
end

function CheckSlingshotAmmo(container, item, slot)
    return item:HasTag("slingshotammo")
end

function CheckSlingshotAmmoJessie(container, item, slot)
    return item:HasTag("slingshotammo") and container.inst:HasTag("can_take_ammo")
end

function CheckFish(container, item, slot)
    return item:HasTag("smalloceancreature")
end

function CheckDart(container, item, slot)
    return item:HasTag("um_dart")
end

function CheckFeather(container, item, slot)
    return item:HasTag("wingsuit_feather")
end

function CheckNOTHING(container, item, slot)
    return false
end

function CheckInkubator(container, item, slot)
    return not item:HasTag("irreplaceable") and
        (slot == 1 and item:HasTag("um_inkubator_fuel")
            or slot == 2 and item:HasTag("um_inkubator_flesh")
            or slot == 3)
end

local modparams = {}

modparams.air_conditioner =
{
    widget =
    {
        slotpos =
        {
            Vector3(-37.5, 32 + 4, 0),
            Vector3(37.5, 32 + 4, 0),
            Vector3(-37.5, -(32 + 4), 0),
            Vector3(37.5, -(32 + 4), 0),
        },
        slotbg =
        {
            { image = "mushroom_slot.tex", atlas = "images/mushroom_slot.xml" },
            { image = "mushroom_slot.tex", atlas = "images/mushroom_slot.xml" },
            { image = "mushroom_slot.tex", atlas = "images/mushroom_slot.xml" },
            { image = "mushroom_slot.tex", atlas = "images/mushroom_slot.xml" },
        },
        animbank = "ui_chest_2x2",
        animbuild = "ui_chest_2x2",
        pos = Vector3(200, 0, 0),
        side_align_tip = 120,
    },
    itemtestfn = CheckMush,
    acceptsstacks = false,
    type = "cooker",
}

modparams.um_scrapper =
{
    widget =
    {
        slotpos =
        {
            Vector3(-37.5, 32 + 4, 0),
            Vector3(37.5, 32 + 4, 0),
            Vector3(-37.5, -(32 + 4), 0),
            Vector3(37.5, -(32 + 4), 0),
        },
        animbank = "ui_chest_2x2",
        animbuild = "ui_chest_2x2",
        pos = Vector3(200, 0, 0),
        side_align_tip = 120,
    },
    --itemtestfn = CheckEquipItem,
    acceptsstacks = false,
    type = "cooker",
}

modparams.puffvest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(-70, -70, 0),
    },
    issidewidget = true,
    type = "pack",
}
modparams.reflvest =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(-70, -70, 0),
    },
    issidewidget = true,
    type = "pack",
}

modparams.puffvest_big =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_icepack_2x3",
        animbuild = "ui_icepack_2x3",
        pos = Vector3(-5, -70, 0),
    },
    issidewidget = true,
    type = "pack",
}

for y = 0, 2 do
    table.insert(modparams.puffvest_big.widget.slotpos, Vector3(-162, -75 * y + 75, 0))
    table.insert(modparams.puffvest_big.widget.slotpos, Vector3(-162 + 75, -75 * y + 75, 0))
end


modparams.silksack =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
        --pos = Vector3(-5, -70, 0),
        pos = Vector3(-5, -90, 0),
        slotbg =
        {
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "inv_slot.tex",    atlas = "images/hud.xml" },
            { image = "bundle_slot.tex", atlas = "images/bundle_slot.xml" },
            { image = "bundle_slot.tex", atlas = "images/bundle_slot.xml" },
            { image = "silk_slot.tex",   atlas = "images/silk_slot.xml" },
        },
        buttoninfo =
        {
            text = STRINGS.ACTIONS.WRAPBUNDLE,
            position = Vector3(-125, -220, 0),
        }
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,

}
for y = 0, 3 do
    table.insert(modparams.silksack.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(modparams.silksack.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end

table.insert(modparams.silksack.widget.slotpos, Vector3(-162 + 37.5, -60 * 4.5 + 135, 0))


--function modparams.silksack.itemtestfn(container, item, slot)
    --return (item.prefab == "silk" and (slot == 9) or (slot ~= 9) and item.prefab ~= "silk")
--end

function modparams.silksack.widget.buttoninfo.fn(inst, doer)
    if inst.components.container ~= nil then
        GLOBAL.BufferedAction(doer, inst, ACTIONS.UM_SILKWRAP):Do()
        --inst.WrapStuff(inst,doer)
    elseif inst.replica.container ~= nil then
        GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, ACTIONS.UM_SILKWRAP.code, inst, ACTIONS.UM_SILKWRAP.mod_name)
    end
end

function modparams.silksack.widget.buttoninfo.validfn(inst)
    local container = inst.replica.container ~= nil and inst.replica.container or inst.components.container

    if container then
        local has_items, bundle = false, false

        for i = 1, 6 do
            local item = container:GetItemInSlot(i)
            if item ~= nil then
                has_items = true
                if item:HasTag("unwrappable") or item:HasTag("irreplaceable") then
                    bundle = true
                end
            end
        end

        local silk = container:GetItemInSlot(9)
		if silk ~= nil and silk.prefab == "silk" then
			return has_items and silk and (silk.replica ~= nil and silk.replica.stackable ~= nil and silk.replica.stackable:StackSize() >= 6 or silk.components.stackable ~= nil and silk.components.stackable.stacksize >= 6) and not bundle
		end
    end
end

modparams.crabclaw =
{
    widget =
    {
        slotpos =
        {
            --Vector3(0,   32 + 4,  0),
        },
        --[[slotbg =
        {
            { image = "slingshot_ammo_slot.tex" },
        },]]
        slotbg =
        {
            { image = "gem_slot.tex", atlas = "images/gem_slot.xml" },
            { image = "gem_slot.tex", atlas = "images/gem_slot.xml" },
            { image = "gem_slot.tex", atlas = "images/gem_slot.xml" },
            { image = "gem_slot.tex", atlas = "images/gem_slot.xml" },
        },
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(0, 125, 0),
    },
    itemtestfn = CheckGem,
    acceptsstacks = false,
    type = "hand_inv",
}

modparams.matilda =
{
    widget =
    {
        slotpos =
        {
            --Vector3(0,   32 + 4,  0),
        },
        slotbg =
        {
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
        },
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(0, 55, 0),
    },
    excludefromcrafting = true,
    itemtestfn = CheckSlingshotAmmo,
    type = "hand_inv",
}

modparams.jessie =
{
    widget =
    {
        slotpos =
        {
            --Vector3(0,   32 + 4,  0),
        },
        slotbg =
        {
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
            { image = "slingshot_ammo_slot.tex" },
        },
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(0, 180, 0),
    },
    excludefromcrafting = true,
    acceptsstacks = false,
    itemtestfn = CheckSlingshotAmmoJessie, -- HEY SCRIMBLES! FOR SOME REASON IT SEEMS LIKE
    -- JESSIE WONT ACCEPT AMMO DESPITE can_take_ammo BEING TRUE?
    -- FIND WHAT 'container' REFERS TO
    type = "hand_inv",
}

modparams.um_blowgun =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    itemtestfn = CheckDart,
    acceptsstacks = true,
    type = "hand_inv",
}

modparams.um_beegun =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        slotbg =
        {
            { image = "bee_slot.tex", atlas = "images/bee_slot.xml" },
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    itemtestfn = CheckBee,
    usespecificslotsforitems = true,
    acceptsstacks = true,
    type = "hand_inv",
}

modparams.frigginbirdpail =
{
    widget =
    {
        slotpos =
        {
            --Vector3(0,   32 + 4,  0),
        },
        slotbg =
        {
            { image = "fish_slot.tex", atlas = "images/fish_slot.xml" },
            { image = "fish_slot.tex", atlas = "images/fish_slot.xml" },
            { image = "fish_slot.tex", atlas = "images/fish_slot.xml" },
            { image = "fish_slot.tex", atlas = "images/fish_slot.xml" },
        },
        animbank = "ui_lamp_1x4",
        animbuild = "ui_lamp_1x4",
        pos = Vector3(0, 125, 0),
    },
    itemtestfn = CheckFish,
    --acceptsstacks = true,
    type = "hand_inv",
}

modparams.wingsuit =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        slotbg =
        {
            { image = "feather_slot.tex", atlas = "images/feather_slot.xml" },
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(53, 15, 0),
    },
    itemtestfn = CheckFeather,
    usespecificslotsforitems = true,
    type = "hand_inv",
}

modparams.corvushat =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        slotbg =
        {
            { image = "feather_slot.tex", atlas = "images/feather_slot.xml" },
        },
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(106, 15, 0),
    },
    acceptsstacks = false,
    itemtestfn = CheckFeather,
    usespecificslotsforitems = true,
    type = "hand_inv",
}

modparams.winkyburrow_child =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
    },
    itemtestfn = CheckNOTHING,
    type = "special for shared inventory",
}

modparams.skullchest_child =
{
    widget =
    {
        slotpos = {},
        slotbg = {},
    },
    itemtestfn = CheckNOTHING,
    type = "special for shared inventory",
}

for y = 0, 3 do
    table.insert(modparams.puffvest.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end
for y = 0, 3 do
    table.insert(modparams.reflvest.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end
for y = 0, 3 do
    table.insert(modparams.crabclaw.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end
for y = 0, 2 do
    table.insert(modparams.matilda.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end
for y = 0, 5 do
    table.insert(modparams.jessie.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end
for y = 0, 3 do
    table.insert(modparams.frigginbirdpail.widget.slotpos, Vector3(-1, -75 * y + 110, 0))
end

local function NoIreplaceables(container, item, slot)
    return not item:HasTag("irreplaceable")
end

modparams.skullchest = GLOBAL.deepcopy(containers.params.shadowchester)
modparams.skullchest.itemtestfn = NoIreplaceables
modparams.uncompromising_winkyburrow_master = GLOBAL.deepcopy(containers.params.shadowchester)
modparams.uncompromising_winkyburrow_master.itemtestfn = NoIreplaceables
modparams.um_devcapture = GLOBAL.deepcopy(containers.params.shadowchester)
modparams.um_devcapture.itemtestfn = NoIreplaceables
modparams.um_sacred_chest = GLOBAL.deepcopy(containers.params.sacred_chest)
modparams.um_sacred_chest.itemtestfn = NoIreplaceables

modparams.sludge_sack = containers.params.piggyback

local old_wsetup = containers.widgetsetup

function containers.widgetsetup(container, prefab, data, ...)
    local t = modparams[ prefab or container.inst.prefab --[[ or inst.widgetsetup]] ]
    if t ~= nil then
        --if modparams[prefab or container.inst.prefab] and not data then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
        --data = modparams[prefab or container.inst.prefab]
        --return old_wsetup(container, prefab, data, ...)
    else
        return old_wsetup(container, prefab, data, ...)
        --containers_widgetsetup_base(container, prefab, data, ...)
    end
end

if containers.MAXITEMSLOTS == nil or containers.MAXITEMSLOTS < 25 then
    containers.MAXITEMSLOTS = 25
end

if GetModConfigData("scaledchestbuff") then
    containers.params.dragonflychest =
    {
        widget =
        {
            slotpos = {},
            animbank = nil,
            animbuild = nil,
            bgatlas = "images/dragonflycontainerborder.xml",
            bgimage = "dragonflycontainerborder.tex",
            bgimagetint = { r = .82, g = .77, b = .7, a = 1 },
            pos = Vector3(0, 220, 0),
            side_align_tip = 160,
        },
        type = "chest",
    }

    for y = 2.5, -1.5, -1 do
        for x = 0, 4 do
            table.insert(containers.params.dragonflychest.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 + 120
            , 0))
        end
    end
end

containers.params.wardrobe =
{
    widget =
    {
        slotpos = {},
        animbank = nil,
        animbuild = nil,
        bgatlas = "images/dragonflycontainerborder.xml",
        bgimage = "dragonflycontainerborder.tex",
        bgimagetint = { r = .82, g = .77, b = .7, a = 1 },
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
        slotbg =
        {
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
            { image = "wardrobe_chest_slot.tex", atlas = "images/wardrobe_chest_slot.xml" },
            { image = "wardrobe_tool_slot.tex",  atlas = "images/wardrobe_tool_slot.xml" },
            { image = "wardrobe_hat_slot.tex",   atlas = "images/wardrobe_hat_slot.xml" },
        },
    },
    type = "chest",
    itemtestfn = CheckWardrobeItem,
    right = true,
}

for y = 2.5, -1.5, -1 do
    for x = 0, 4 do
        table.insert(containers.params.wardrobe.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 + 120, 0))
    end
end

containers.params.um_cookpot_wagstaff =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 64 + 32 + 8 + 4, 0),
            Vector3(0, 32 + 4, 0),
            Vector3(0, -(32 + 4), 0),
            Vector3(0, -(64 + 32 + 8 + 4), 0),
        },
        animbank = "ui_um_cookpot_wagstaff_1x4",
        animbuild = "ui_um_cookpot_wagstaff_1x4",
        pos = Vector3(200, 0, 0),
        side_align_tip = 100,
        buttoninfo =
        {
            text = "Atomize",
            position = Vector3(0, -165, 0),
        }
    },
    acceptsstacks = false,
    type = "cooker",
}

local cooking = require("cooking")
containers.params.um_cookpot_wagstaff.itemtestfn = function(container, item, slot)
    return cooking.IsCookingIngredient(item.prefab) and not container.inst:HasTag("burnt")
end

containers.params.um_cookpot_wagstaff.widget.buttoninfo.fn = function(inst, doer)
    if inst.components.container ~= nil then
        GLOBAL.BufferedAction(doer, inst, ACTIONS.COOK):Do()
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        GLOBAL.SendRPCToServer(GLOBAL.RPC.DoWidgetButtonAction, ACTIONS.COOK.code, inst, ACTIONS.COOK.mod_name)
    end
end

containers.params.um_cookpot_wagstaff.widget.buttoninfo.validfn = function(inst)
    return inst.replica.container ~= nil and inst.replica.container:IsFull()
end



containers.params.winona_toolbox =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_chester_shadow_3x4",
        animbuild = "ui_chester_shadow_3x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = CheckToolboxItem,
}

if GetModConfigData("toolbox_tools") then
    containers.params.winona_toolbox.widget.slotgb =
    {
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
        { image = "wardrobe_tool_slot.tex", atlas = "images/wardrobe_tool_slot.xml" },
    }
end

containers.params.winona_toolbox.widget.slotpos = containers.params.shadowchester.widget.slotpos

modparams.sunkenchest_royal_random = containers.params.shadowchester
modparams.sunkenchest_royal_red = containers.params.shadowchester
modparams.sunkenchest_royal_blue = containers.params.shadowchester
modparams.sunkenchest_royal_purple = containers.params.shadowchester
modparams.sunkenchest_royal_green = containers.params.shadowchester
modparams.sunkenchest_royal_orange = containers.params.shadowchester
modparams.sunkenchest_royal_yellow = containers.params.shadowchester
modparams.sunkenchest_royal_rainbow = containers.params.shadowchester

for k, v in pairs(modparams) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end


containers.params.um_inkubator =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 64 + 32 + 8 + 4, 0),
            Vector3(0, 32 + 4, 0),
            Vector3(0, -(32 + 4), 0),
            --Vector3(0, -(64 + 32 + 8 + 4), 0),
        },
        slotbg =
        {
            { image = "um_inkubator_fuelslot.tex", atlas = "images/um_inkubator_fuelslot.xml" },
            { image = "um_inkubator_meatslot.tex", atlas = "images/um_inkubator_meatslot.xml" },
        },
        animbank = "ui_cookpot_1x4",
        animbuild = "ui_cookpot_1x4",
        pos = Vector3(200, 0, 0),
        side_align_tip = 100,
    },
    acceptsstacks = false,
    type = "chest",
    itemtestfn = CheckInkubator,
}

containers.params.spicepack = GLOBAL.deepcopy(containers.params.beargerfur_sack)
containers.params.spicepack.itemtestfn = function(container, item, slot)
    for i, v in ipairs(GLOBAL.FOODGROUP.OMNI.types) do
        if item:HasAnyTag("fresh", "stale", "spoiled", "spice", "edible_" .. v) or cooking.IsCookingIngredient(item.prefab) then return true end
    end
end

for k, v in pairs(containers.params.spicepack.widget.slotbg) do
    containers.params.spicepack.widget.slotbg[k] = { image = "inv_slot_morsel.tex" }
end


-- Polar Bearger Bin dried jerky change
vanilla_beargerfur_sack_itemtestfn = containers.params.beargerfur_sack.itemtestfn
containers.params.beargerfur_sack.itemtestfn = function(container, item, slot)

    -- Klei's containers.lua [[ beargerfur_sack ]]
    if vanilla_beargerfur_sack_itemtestfn and vanilla_beargerfur_sack_itemtestfn(container, item, slot) then
        return true
    end

    if not item or not item.name then
        return false
    end

    -- Mod compatibility: If item is named in code or in-game "Jerky" or "Dried" then it is probably dried jerky
    -- loopuleasa: Klei don't seem to implement a proper "isdried" generic tag
    local code_name = item.prefab
    local ingame_name = item.name:lower()
    local isdried = false

    isdried = string.find(code_name, "dried", 1, true)
        or string.find(code_name, "jerky", 1, true)
        or string.find(ingame_name, "dried", 1, true)
        or string.find(ingame_name, "jerky", 1, true)

    if isdried and item:HasTag("meat") then
		return true
	end

end


containers.params.silken_bundle = GLOBAL.deepcopy(containers.params.beargerfur_sack)


if TUNING.DSTU.ICEBOX_TWEAKS then
    containers.params.saltbox.lowpriorityselection = true
	containers.params.icebox.lowpriorityselection = true
	local oldicebox = containers.params.icebox.itemtestfn
	function containers.params.icebox.itemtestfn(container, item, slot, ...)
		if cooking.IsCookingIngredient(item.prefab) and not item:HasTag("smallcreature") then
			return true
		end
		return oldicebox(container, item, slot, ...)
	end
end

local function addItemSlotNetvarsInContainer(inst)
    if (#inst._itemspool < containers.MAXITEMSLOTS) then
        for i = #inst._itemspool + 1, containers.MAXITEMSLOTS do
            table.insert(inst._itemspool,
                net_entity(inst.GUID, "container._items[" .. tostring(i) .. "]", "items[" .. tostring(i) .. "]dirty"))
        end
    end
end

AddPrefabPostInit("container_classified", addItemSlotNetvarsInContainer)

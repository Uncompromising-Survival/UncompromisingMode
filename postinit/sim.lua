local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local ORANGE_PICKUP_MUST_ONEOF_TAGS = {"_inventoryitem", "pickable"}
local ORANGE_PICKUP_CANT_TAGS = {
    -- Items
    "INLIMBO", "NOCLICK", "irreplaceable", "knockbackdelayinteraction", --"event_trigger",
    "minesprung", "mineactive", "catchable",
    "fire", --[["light",]] "spider", "cursed", "paired", "bundle",
    --[["heatrock", "deploykititem", "boatbuilder", "singingshell",
    "archive_lockbox", "simplebook",]] "furnituredecor",
    -- Pickables
    "flower", "gemsocket", --"structure",
    -- Either
    --"donotautopick",
}

local function ProductDeterminer(inst)
    return inst.components.pickable and inst.components.pickable.product
end

local function IsSpecializedContainersFull(specialized)
    if specialized then
        for _, container in pairs(specialized) do
            if not container:IsFull() then
                return false
            end
        end
    end

    return true
end

local function FindItems(inventory, fn, specialized)
    local items = inventory:FindItems(fn) or {}

    if specialized then
        for _, container in pairs(specialized) do
            for k, v in pairs(container:FindItems(fn)) do
                table.insert(items, v)
            end
        end
    end

    return items
end

local function ExistsInInventory(owner, inst)
    local inventory = owner.components.inventory
    if not inventory then return true end
    local overflow = inventory:GetOverflowContainer()
    local specialized = inventory:GetSpecializedContainers()
    if not inventory:IsFull() or overflow and not overflow:IsFull() or specialized and not IsSpecializedContainersFull(specialized) or not ProductDeterminer(inst) then return true end
    local stackisnotfull = false
    local function ShouldGoInList(item)
        local stackable, equippable = item.components.stackable, item.components.equippable
        return item and item.prefab == ProductDeterminer(inst)
            and not (stackable and stackable:IsFull())
            and not (equippable and equippable:IsEquipped())
            and not (inventory and item == inventory:GetActiveItem())
    end
    for _, id in pairs(FindItems(inventory, ShouldGoInList, specialized)) do
        if id and not (id.components.stackable and id.components.stackable:IsFull()) then
            stackisnotfull = true
            break
        end
    end
    return stackisnotfull
end

local function PickUpFilter(inst, target, leader)
    if not target.components.inventoryitem then
        return ExistsInInventory(leader, target)
    end
    return true
end

local function FindPickupableItem_filter(v, ba, owner, radius, furthestfirst, positionoverride, ignorethese, onlytheseprefabs, allowpickables, ispickable, worker, extra_filter, inventoryoverride)
    local inventory = inventoryoverride or owner.components.inventory
    if extra_filter and not extra_filter(worker, v, owner) then
        return false
    end
    if v.components.burnable and (v.components.burnable:IsBurning() or v.components.burnable:IsSmoldering()) then
        return false
    end
    if ispickable then
        if not allowpickables then
            return false
        end
    else
        if not (v.components.inventoryitem ~= nil and
            v.components.inventoryitem.canbepickedup and
            v.components.inventoryitem.cangoincontainer and
            not v.components.inventoryitem:IsHeld()) then
            return false
        end
    end
    if ignorethese ~= nil and ignorethese[v] ~= nil and ignorethese[v].worker ~= worker then
        return false
    end
    if onlytheseprefabs ~= nil and onlytheseprefabs[ispickable and v.components.pickable.product or v.prefab] == nil then
        return false
    end
    if v:HasTag("event_trigger") and not v:HasTag("ancienttree") then -- Don't pick things labeled as an "event_trigger", but only if they're not labeled as an "ancienttree".
        return false
    end
    if v.components.craftingstation and v.components.pickable then -- This should stop them from picking Potter's Wheels, and anything similar.
        return false
    end
    if v.components.bait and v.components.bait.trap then -- Do not steal baits.
        return false
    end
    if v.components.trap and not (v.components.trap:IsSprung() and v.components.trap:HasLoot()) then -- Only interact with traps that have something in it to take.
        return false
    end
    if not ispickable and inventory:CanAcceptCount(v, 1) <= 0 then -- TODO(JBK): This is not correct for traps nor pickables but they do not have real prefabs made yet to check against.
        return false
    end
    if ba and ba.target == v and (ba.action == ACTIONS.PICKUP or ba.action == ACTIONS.CHECKTRAP or ba.action == ACTIONS.PICK) then
        return false
    end
    return v, ispickable
end

local _FindPickupableItem = FindPickupableItem
function FindPickupableItem(owner, radius, furthestfirst, positionoverride, ignorethese, onlytheseprefabs, allowpickables, worker, extra_filter, inventoryoverride, ...)
    if owner and owner.um_orangeamulet and owner.um_orangeamulet:IsValid() then
        if not (inventoryoverride or owner.components.inventory) then return nil end
        local ba = owner:GetBufferedAction()
        local x, y, z
        if positionoverride then
            x, y, z = positionoverride:Get()
        else
            x, y, z = owner.Transform:GetWorldPosition()
        end
        local ents = TheSim:FindEntities(x, y, z, radius, nil, ORANGE_PICKUP_CANT_TAGS, ORANGE_PICKUP_MUST_ONEOF_TAGS)
        local istart, iend, idiff = 1, #ents, 1
        if furthestfirst then
            istart, iend, idiff = iend, istart, -1
        end
        for i = istart, iend, idiff do
            local v = ents[i]
            local ispickable = v:HasTag("pickable") and not (v.components.pickable and v.components.pickable:IsStuck())
            if FindPickupableItem_filter(v, ba, owner, radius, furthestfirst, positionoverride, ignorethese, onlytheseprefabs, true, ispickable, worker, PickUpFilter, inventoryoverride) then
                if v and ispickable and v.components.pickable then
                    v.components.pickable:Pick(owner)
                    SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
                    owner.um_orangeamulet.components.finiteuses:Use(1)
                    if owner.components.sanity then owner.components.sanity:DoDelta(-.25) end
                    return nil, nil
                end
                return v, ispickable
            end
        end
        return nil, nil
    end
    return _FindPickupableItem(owner, radius, furthestfirst, positionoverride, ignorethese, onlytheseprefabs, allowpickables, worker, extra_filter, inventoryoverride, ...)
end
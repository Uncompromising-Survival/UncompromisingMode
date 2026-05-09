local env = env
GLOBAL.setfenv(1, GLOBAL)

-- This is an attempt at manually fixing an issue when people are checked for insulation
-- scrimbles

env.AddComponentPostInit("inventory", function(self)
    local _OldIsInsulated = self.IsInsulated

    function self:IsInsulated()
        if self.isexternallyinsulated == nil or self.isexternallyinsulated:Get() == nil then
            for k, v in pairs(self.equipslots) do
                if v and v.components.equippable:IsInsulated() then
                    return true
                end
            end
        else
            return _OldIsInsulated(self)
        end
    end

    local _EquipHasTag = self.EquipHasTag
    function self:EquipHasTag(tag, ...)
        if self.inst.components.skilltreeupdater and self.inst.components.skilltreeupdater:IsActivated("wathom_allegiance_neutral") and tag == "ancient_reader" then return true end
        return _EquipHasTag(self, tag, ...)
    end
end)

env.AddClassPostConstruct("components/inventory_replica", function(self)
    local _EquipHasTag = self.EquipHasTag
    function self:EquipHasTag(tag, ...)
        if self.inst.components.skilltreeupdater and self.inst.components.skilltreeupdater:IsActivated("wathom_allegiance_neutral") and tag == "ancient_reader" then return true end
        return _EquipHasTag(self, tag, ...)
    end
end)

local InventoryReplica = require("components/inventory_replica")
local Inventory = require("components/inventory")

local get_num_slots = InventoryReplica.GetNumSlots
function InventoryReplica:GetNumSlots(...)
    if not self.inst.components.inventory then
        if self.inst:HasTag("vetcurse") and self.inst.prefab == "winky" then
            return 10
        end
    end
    return get_num_slots(self, ...)
end

local _ctor = Inventory._ctor
function Inventory:_ctor(inst, ...)
    if inst.prefab == "winky" and inst:HasTag("vetcurse") then
        local get_max_item_slots = GetMaxItemSlots
        GetMaxItemSlots = function()
            return inst.prefab == "winky" and inst:HasTag("vetcurse") and 10 or GetMaxItemSlots(TheNet:GetServerGameMode())
        end
        local ret = { _ctor(self, inst, ...) }
        GetMaxItemSlots = get_max_item_slots
        return unpack(ret)
    end
    return _ctor(self, inst, ...)
end

env.AddClassPostConstruct("widgets/inventorybar", function(self)
    self.inst:ListenForEvent("winky.inventory_dirty", function() self:Rebuild() end, self.owner)
end)

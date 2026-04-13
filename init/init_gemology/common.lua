local env = env
GLOBAL.setfenv(1, GLOBAL)

local DEFS = require("gemology_defs")
local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = DEFS.GEM_DEFS, DEFS.GEM_LOOKUP, DEFS.INVERTED_GEM_LOOKUP
--------------------------------------------------------------------------
--Common stuff for every gem.

--Add the gem enchantable components
env.AddReplicableComponent("gem_enchantable")
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS and (inst.components.tool or inst.components.weapon) then
        inst:AddComponent("gem_enchantable")
    end
end)

--sets the adjective of the gem enchantments (priotizes chaos emerald, gets the first one if otherwise)
local function GetEnchantmentAdjective(enchants)
    local prefix = ""
    for k, v in pairs(enchants) do
        prefix = prefix .. STRINGS.NAMES.GEMTOOL_PREFIX[string.upper(v)]
        if k ~= #enchants then
            prefix = prefix .. " "
        end
    end
    return prefix
end

local _GetAdjectivedName = EntityScript.GetAdjectivedName
function EntityScript:GetAdjectivedName(...)
    local name = self:GetBasicDisplayName()
    local enchantable = self.replica.gem_enchantable

    if enchantable ~= nil then
        local enchants = self.replica.gem_enchantable:GetEnchantmentNames()

        if #enchants > 0 then
            if not self.no_wet_prefix and (self.always_wet_prefix or self:GetIsWet()) then
                return ConstructAdjectivedName(self, name, STRINGS.WET_PREFIX.TOOL .. " " .. GetEnchantmentAdjective(enchants))
            else
                return ConstructAdjectivedName(self, name, GetEnchantmentAdjective(enchants))
            end
        end
    end

    return _GetAdjectivedName(self, ...)
end

--sets the text color. (priotizes chaos emerald, gets the first one if otherwise)
local function GetAllGemColor(enchants)
    local colors = {}
    for k, v in pairs(enchants) do
        if v ~= nil then
            table.insert(colors, GEM_DEFS[v].color)
        end
    end
    return colors
end



--postconstruct was giving a LOT of stale reference warnings, so i'll just hook like this
local ItemTile = require("widgets/itemtile")
local _UpdateTooltip = ItemTile.UpdateTooltip

function ItemTile:UpdateTooltip(...)
    local ret = _UpdateTooltip(self, ...)
    if self.item ~= nil and self.item:IsValid() and self.item.replica.gem_enchantable then
        local enchants = self.item.replica.gem_enchantable:GetEnchantmentNames()
        if #enchants > 0 then
            self:SetTooltipColour(unpack(GetAllGemColor(enchants)[math.random(#enchants)]))
        end
    end

    return ret
end

--------------------------------------------------------------------------
--Common Gem Effect Handling

env.AddComponentPostInit("weapon", function(self)
    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        if self.inst.components.gem_enchantable then
            for enchant, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.onattack ~= nil then
                    GEM_DEFS[enchant].fns.onattack(self.inst, attacker, target, tier)
                end
            end
        end

        return _OnAttack(self, attacker, target, projectile, ...)
    end
end)



local valid_work_actions = {
    "CHOP",
    "MINE",
    "HAMMER",
    "DIG"
}

for k, action in pairs(valid_work_actions) do
    local old_fn = ACTIONS[action].fn
    ACTIONS[action].fn = function(act, ...)
        local ret = old_fn(act, ...)

        if ret then
            local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if tool and tool.components.gem_enchantable ~= nil then
                for enchant, tier in pairs(tool.components.gem_enchantable.enchants) do
                    if GEM_DEFS[enchant].fns.onwork then
                        GEM_DEFS[enchant].fns.onwork(tool, act.doer, act.target, tier)
                    end
                end
            end
        end
        return ret
    end
end


env.AddComponentPostInit("equippable", function(self)
    local _Equip = self.Equip
    function self:Equip(owner, ...)
        if not owner:HasTag("equipmentmodel") then
            if self.inst.components.gem_enchantable then
                for enchant, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                    if GEM_DEFS[enchant].fns.onequip then
                        GEM_DEFS[enchant].fns.onequip(self.inst, owner, tier)
                    end
                end
            end
        end

        return _Equip(self, owner)
    end

    local _UnEquip = self.Unequip
    function self:Unequip(owner, ...)
        if not owner:HasTag("equipmentmodel") then
            if self.inst.components.gem_enchantable then
                for enchant, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                    if GEM_DEFS[enchant].fns.onunequip then
                        GEM_DEFS[enchant].fns.onunequip(self.inst, owner, tier)
                    end
                end
            end
        end

        return _UnEquip(self, owner)
    end
end)

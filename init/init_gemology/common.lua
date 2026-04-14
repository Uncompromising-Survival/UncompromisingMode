local env = env
GLOBAL.setfenv(1, GLOBAL)

local DEFS = require("gemology_defs")
local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = DEFS.GEM_DEFS, DEFS.GEM_LOOKUP, DEFS.INVERTED_GEM_LOOKUP
local UpvalueHacker = require("tools/upvaluehacker")
local UIAnim = require "widgets/uianim"

--------------------------------------------------------------------------
--Common stuff for every gem.

--Add the gem enchantable components
env.AddReplicableComponent("gem_enchantable")
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS and (inst.components.tool or inst.components.weapon) and not inst.components.stackable then
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

local function getframesymbol(durability)
    if durability > .75 then
        return "frame"
    elseif durability <= .75 and durability > .5 then
        return "frame-0"
    elseif durability <= .5 and durability > .25 then
        return "frame-1"
    else
        return "frame-2"
    end
end

local function HasEnchant(_table)
    for k, v in pairs(_table) do
        if v ~= nil then
            return true
        end
    end
    return false
end

local __ctor = ItemTile._ctor

function ItemTile._ctor(self, invitem, ...)
    __ctor(self, invitem, ...)
    if invitem.replica.gem_enchantable ~= nil and HasEnchant(invitem.replica.gem_enchantable.enchant_durabilty) then
        self.gem_border = self:AddChild(UIAnim())
        self.gem_border:GetAnimState():SetBank("gem_meter")
        self.gem_border:GetAnimState():SetBuild("gem_meter")
        self.gem_border:GetAnimState():PlayAnimation("idle")
        self.gem_border:GetAnimState():AnimateWhilePaused(false)
        self.gem_border:SetClickable(false)

        if invitem.replica.gem_enchantable:IsEnchanted() and not self.dragging then
            self.gem_border:Show()
        else
            self.gem_border:Hide()
        end

        local enchant, durability = invitem.replica.gem_enchantable:GetLowestGemDurability()
        if durability ~= nil and enchant ~= nil then
            self.gem_border:GetAnimState():OverrideSymbol("frame", "gem_meter", getframesymbol(durability))

            local color = GEM_DEFS[enchant].color
            self.gem_border:GetAnimState():SetMultColour(color[1], color[2], color[3], 1)
        end
        self.inst:ListenForEvent("gemology.enchant_durabilitydirty", function(inst)
            if invitem.replica.gem_enchantable:IsEnchanted() and not self.dragging then
                self.gem_border:Show()
            else
                self.gem_border:Hide()
            end

            local enchant, durability = invitem.replica.gem_enchantable:GetLowestGemDurability()
            if durability == nil or enchant == nil then
                return
            end

            self.gem_border:GetAnimState():OverrideSymbol("frame", "gem_meter", getframesymbol(durability))

            local color = GEM_DEFS[enchant].color
            self.gem_border:GetAnimState():SetMultColour(color[1], color[2], color[3], 1)
        end, invitem)
    end
end

local _StartDrag = ItemTile.StartDrag
function ItemTile:StartDrag()
    _StartDrag(self)
    if self.gem_border ~= nil then
        self.gem_border:Hide()
    end
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


--gem durability

--gem durability
env.AddComponentPostInit("finiteuses", function(self)
    local _SetUses = self.SetUses

    function self:SetUses(val, ...)
        local curr_percent = self:GetPercent()
        local new_percent = val / self.total
        local delta = new_percent - curr_percent


        if delta < 0 and self.inst.components.gem_enchantable ~= nil then
            for gem, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if self.inst.components.gem_enchantable:HasDurabilityEnabled(gem) then
                    self.inst.components.gem_enchantable:DoDurabilityDelta(gem, delta)
                end
            end
        end

        _SetUses(self, val, ...)
    end
end)

env.AddComponentPostInit("fueled", function(self)
    local _DoDelta = self.DoDelta

    function self:DoDelta(amount, doer, ...)
        local curr_percent = self:GetPercent()
        local new_percent = amount / self.maxfuel
        local delta = new_percent - curr_percent

        if delta < 0 and self.inst.components.gem_enchantable ~= nil then
            for gem, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if self.inst.components.gem_enchantable:HasDurabilityEnabled(gem) then
                    self.inst.components.gem_enchantable:DoDurabilityDelta(gem, delta)
                end
            end
        end

        _DoDelta(self, amount, doer, ...)
    end
end)

env.AddComponentPostInit("armor", function(self)
    local _SetCondition = self.SetCondition

    function self:SetCondition(amount, ...)
        local curr_percent = self:GetPercent()
        local new_percent = amount / self.maxcondition
        local delta = new_percent - curr_percent

        if delta < 0 and self.inst.components.gem_enchantable ~= nil then
            for gem, tier in pairs(self.inst.components.gem_enchantable.enchants) do
                if self.inst.components.gem_enchantable:HasDurabilityEnabled(gem) then
                    self.inst.components.gem_enchantable:DoDurabilityDelta(gem, delta)
                end
            end
        end

        _SetCondition(self, amount, ...)
    end
end)
local env = env
GLOBAL.setfenv(1, GLOBAL)

local GEM_DEFS, GEM_LOOKUP, INVERTED_GEM_LOOKUP = require("gemology_defs")
--------------------------------------------------------------------------
--Common stuff for every gem.

--extra gemology data
env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnSave = inst.OnSave
    local _OnLoad = inst.OnLoad

    inst.OnSave = function(inst, data, ...)
        data.gemology_data = inst.gemology_data

        if _OnSave ~= nil then
            return _OnSave(inst, data, ...)
        else
            return data
        end
    end

    inst.OnLoad = function(inst, data, ...)
        if data ~= nil and data.gemology_data ~= nil then
            inst.gemology_data = data.gemology_data
        end

        if _OnLoad ~= nil then
            _OnLoad(inst, data, ...)
        end
    end
end)

--Add the gem enchantable components
env.AddReplicableComponent("gem_enchantable")
env.AddPrefabPostInitAny(function(inst)
    if inst.components.equippable and inst.components.equippable.equipslot == EQUIPSLOTS.HANDS and (inst.components.tool or inst.components.weapon) then
        inst:AddComponent("gem_enchantable")
    end
end)

--sets the adjective of the gem enchantments (priotizes chaos emerald, gets the first one if otherwise)
local function GetEnchantmentAdjective(enchants)
    if table.contains(enchants, "um_gemologygreengem2") then
        return STRINGS.NAMES.GEMTOOL_PREFIX.UM_GEMOLOGYGREENGEM2       --prio chaos emerald so it doesn't just tell you every effect.
    else
        return STRINGS.NAMES.GEMTOOL_PREFIX[string.upper(enchants[1])] --get the first gem enchant
    end
end

local _GetAdjectivedName = EntityScript.GetAdjectivedName
function EntityScript:GetAdjectivedName(...)
    local name = self:GetBasicDisplayName()
    local enchantable = self.replica.gem_enchantable

    if enchantable ~= nil then
        local enchants = self.replica.gem_enchantable:GetEnchantmentNames()

        if not self.no_wet_prefix and (self.always_wet_prefix or self:GetIsWet()) then
            return ConstructAdjectivedName(self, name, STRINGS.WET_PREFIX.TOOL .. " " .. GetEnchantmentAdjective(enchants))
        else
            return ConstructAdjectivedName(self, name, GetEnchantmentAdjective(enchants))
        end
    end

    return _GetAdjectivedName(self, ...)
end

--sets the text color. (priotizes chaos emerald, gets the first one if otherwise)
local function GetFirstGemColor(enchants)
    if table.contains(enchants, "um_gemologygreengem2") then
        return GEM_DEFS["um_gemologygreengem2"] --prio chaos emerald so it doesn't just tell you every effect.
    else
        return GEM_DEFS[enchants[1]].color or RGB(1, 1, 1)
    end
end

env.AddClassPostConstruct("widgets/itemtile", function(self)
    local _UpdateTooltip = self.UpdateTooltip
    function self:UpdateTooltip(...)
        local ret = _UpdateTooltip(self, ...)
        if self.item ~= nil and self.item:IsValid() and self.item.replica.gem_enchantable then
            local enchants = self.item.replica.gem_enchantable:GetEnchantmentNames()
            self:SetTooltipColour(unpack(GetFirstGemColor(enchants)))
        end

        return ret
    end
end)

--------------------------------------------------------------------------
--Common Gem Effect Handling

env.AddComponentPostInit("weapon", function(self)
    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        if self.inst.components.gem_enchantable then
            for enchant, tier in ipairs(self.inst.components.gem_enchantable.enchants) do
                GEM_DEFS[enchant].fns.onattack(self.inst, attacker, target, tier)
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
    ACTIONS[action].fn = function(act, ...)
        local tool = act.doer.components.inventory and act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool.components.gem_enchantable then
            for enchant, tier in ipairs(tool.components.gem_enchantable.enchants) do
                if GEM_DEFS[enchant].fns.onwork then
                    GEM_DEFS[enchant].fns.onwork(tool, act.doer, act.target, tier)
                end
            end
        end
    end
end


env.AddComponentPostInit("equippable", function(self)
    local _Equip = self.Equip
    function self:Equip(owner, ...)
        if owner:HasTag("equipmentmodel") then
            if self.inst.components.gem_enchantable then
                for enchant, tier in ipairs(self.inst.components.gem_enchantable.enchants) do
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
                for enchant, tier in ipairs(self.inst.components.gem_enchantable.enchants) do
                    if GEM_DEFS[enchant].fns.onunequip then
                        GEM_DEFS[enchant].fns.onunequip(self.inst, owner, tier)
                    end
                end
            end
        end

        return _UnEquip(self, owner)
    end
end)

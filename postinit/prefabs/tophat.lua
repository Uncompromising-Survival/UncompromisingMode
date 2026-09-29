local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UMUpvalueHacker = require("tools/um_upvaluehacker")

local function TophatPostinit(inst)
    local equippable = inst.components.equippable
    if equippable then
        local _OnEquip = equippable.onequipfn
        equippable:SetOnEquip(function(inst, owner, ...)
            if _OnEquip then _OnEquip(inst, owner, ...) end
            owner.um_Funny_Words_Magic_Man = true
        end)
        local _OnUnequip = equippable.onunequipfn
        equippable:SetOnUnequip(function(inst, owner, ...)
            if _OnUnequip then _OnUnequip(inst, owner, ...) end
            owner.um_Funny_Words_Magic_Man = nil
        end)
    end
end

env.AddSimPostInit(function()
    local _top_convert_to_magician = UMUpvalueHacker.TryGetUpvalue(Prefabs.tophat.fn, "top_convert_to_magician")
    if _top_convert_to_magician then
        local function top_convert_to_magician(inst, ...)
            local wasmagicantool = inst.components.magiciantool ~= nil
            local ret = _top_convert_to_magician(inst, ...)
            if not wasmagicantool then TophatPostinit(inst) end
            return ret
        end
        UMUpvalueHacker.SetUpvalue(Prefabs.tophat.fn, top_convert_to_magician, "top_convert_to_magician")
    end
end)


env.AddPrefabPostInit("tophat", function(inst)
    if not TheWorld.ismastersim then return end
    TophatPostinit(inst)
end)

env.AddPrefabPostInit("flowerhat", function(inst) -- Wow! Don't look at mee!
    if not TheWorld.ismastersim then return end
    local fuel = inst:AddComponent("fuel")
    fuel.fuelvalue = TUNING.MED_LARGE_FUEL
end)

-- Tophat Sanity Reduction stuff.

--Dark Sword
--[[local function CalcDappernessNightSword(inst, owner)
    if owner.um_Funny_Words_Magic_Man then
        return TUNING.CRAZINESS_MED * .8 -- This ends up blah blah blah shut up bro ur weird
    else
        return TUNING.CRAZINESS_MED
    end
end

env.AddPrefabPostInit("nightsword", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.equippable ~= nil then
        inst.components.equippable.dapperfn = CalcDappernessNightSword
    end
end)

--Fire Staff
env.AddPrefabPostInit("firestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _redonattack = inst.components.weapon.onattack
    local function RedOnAttack(inst, attacker, target, skipsanity)
        if not skipsanity and attacker ~= nil and attacker.components.sanity ~= nil and attacker.um_Funny_Words_Magic_Man then
            attacker.components.sanity:DoDelta(TUNING.SANITY_SUPERTINY * .5) --Counter the sanity drain                    
        end
        _redonattack(inst, attacker, target, skipsanity)
    end

    inst.components.weapon:SetOnAttack(RedOnAttack)
end)

--Ice Staff
env.AddPrefabPostInit("icestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _blueonattack = inst.components.weapon.onattack
    local function BlueOnAttack(inst, attacker, target, skipsanity)
        if not skipsanity and attacker ~= nil and attacker.components.sanity ~= nil and attacker.um_Funny_Words_Magic_Man then
            attacker.components.sanity:DoDelta(TUNING.SANITY_SUPERTINY * .5) --Counter the sanity drain                    
        end
        _blueonattack(inst, attacker, target, skipsanity)
    end

    inst.components.weapon:SetOnAttack(BlueOnAttack)
end)

--Tele Staff
env.AddPrefabPostInit("telestaff", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _teleport_func = inst.components.spellcaster.spell
    local function TeleFunction(inst, target)
        _teleport_func(inst, target)

        local caster = inst.components.inventoryitem.owner or target
        if target == nil then
            target = caster
        end

        if caster ~= nil and caster.components.sanity ~= nil and caster.um_Funny_Words_Magic_Man then
            caster.components.sanity:DoDelta(TUNING.SANITY_HUGE * .8) --Cut the sanity loss in half
        end
    end

    inst.components.spellcaster:SetSpellFn(TeleFunction)
end)


--Bat Bat
env.AddPrefabPostInit("batbat", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local _onattack = inst.components.weapon.onattack

    local function OnAttackBatBat(inst, owner, target)
        _onattack(inst, owner, target)
        if owner.components.sanity ~= nil and owner.um_Funny_Words_Magic_Man and owner.components.health:GetPercent() < 1 then
            owner.components.sanity:DoDelta(TUNING.BATBAT_DRAIN * .5 * .8)
        end
    end

    inst.components.weapon.onattack = OnAttackBatBat
end)

local function NightArmorFunctions(inst)
    if inst.components.armor then
        local _OnTakeDamage = inst.components.armor.ontakedamage
        local function OnTakeDamage(inst, damage_amount, ...)
            local owner = inst.components.inventoryitem.owner
            if owner and owner.um_Funny_Words_Magic_Man then
                local sanity = owner.components.sanity
                if sanity then
                    local unsaneness = damage_amount * TUNING.ARMOR_SANITY_DMG_AS_SANITY
                    unsaneness = unsaneness  * .8 -- Cutting it by this much because of the fact that you're giving up your headslot, which is usually VERY important for using night armor so you can extend its small durability.
                    sanity:DoDelta(-unsaneness, false)
                end
            else
                return _OnTakeDamage(inst, damage_amount, ...)
            end
        end
        inst.components.armor.ontakedamage = OnTakeDamage
    end

    if inst.components.equippable then
        local function CalcDapperness(inst, owner)
            return TUNING.CRAZINESS_SMALL * (owner.um_Funny_Words_Magic_Man and .8 or 1) -- This ends up being about -5/min + 3.3/min from the hat itself, willing to cut it more for this one
        end
        inst.components.equippable.dapperfn = CalcDapperness
    end
end

env.AddPrefabPostInit("armor_sanity", function(inst)
    if not TheWorld.ismastersim then return end
    NightArmorFunctions(inst)
end)]]

local function GetTophatSanityMult(delta)
    return delta < -1 and .75 or .5
end

local function ShouldDoTophatHook(doer, item)
    return doer.um_Funny_Words_Magic_Man and item.components.shadowlevel
end

local function ToggleHookSanityDoDelta(doer, item, oldfn) -- DoDelta doesn't pass reasons to check against for what we want to do, so I'm doing this for now.
    local sanity =  doer and doer:IsValid() and ShouldDoTophatHook(doer, item) and doer.components.sanity
    if sanity then
        if oldfn then
            sanity.DoDelta = oldfn
        else
            local _DoDelta = sanity.DoDelta
            sanity.DoDelta = function(self, delta, overtime, ...)
                if delta and delta < 0 then delta = delta * GetTophatSanityMult(delta) end
                local ret = _DoDelta(self, delta, overtime, ...)
                sanity.DoDelta = _DoDelta -- Try and unhook immediately after we're done.
                return ret
            end
            return _DoDelta
        end
    end
end

env.AddComponentPostInit("weapon", function(self)
    local _OnAttack = self.OnAttack
    function self:OnAttack(attacker, target, projectile, ...)
        local _DoDelta = ToggleHookSanityDoDelta(attacker, self.inst)
        local ret = _OnAttack(self, attacker, target, projectile, ...)
        ToggleHookSanityDoDelta(attacker, self.inst, _DoDelta)
        return ret
    end
end)

env.AddComponentPostInit("spellcaster", function(self)
    local _CastSpell = self.CastSpell
    function self:CastSpell(target, pos, doer, ...)
        local _DoDelta = ToggleHookSanityDoDelta(doer, self.inst)
        local ret = _CastSpell(self, target, pos, doer, ...)
        ToggleHookSanityDoDelta(doer, self.inst, _DoDelta)
        return ret
    end
end)

env.AddComponentPostInit("blinkstaff", function(self)
    local _Blink = self.Blink
    function self:Blink(pt, caster, ...)
        local _DoDelta = ToggleHookSanityDoDelta(caster, self.inst)
        local ret = _Blink(self, pt, caster, ...)
        ToggleHookSanityDoDelta(caster, self.inst, _DoDelta)
        return ret
    end
end)

env.AddComponentPostInit("armor", function(self)
    local _TakeDamage = self.TakeDamage
    function self:TakeDamage(damage_amount, ...)
        local inventoryitem = self.inst.components.inventoryitem
        local owner = inventoryitem and inventoryitem:GetGrandOwner()
        local _DoDelta = ToggleHookSanityDoDelta(owner, self.inst)
        local ret = _TakeDamage(self, damage_amount, ...)
        ToggleHookSanityDoDelta(owner, self.inst, _DoDelta)
        return ret
    end
end)

env.AddComponentPostInit("equippable", function(self)
    local _GetDapperness = self.GetDapperness
    function self:GetDapperness(owner, ignore_wetness, ...)
        local _dapperness
        local _dapperfn
        if owner and ShouldDoTophatHook(owner, self.inst) then
            if self.dapperness then
                _dapperness = self.dapperness
                self.dapperness = _dapperness * GetTophatSanityMult(_dapperness)
            end
            if self.dapperfn then
                _dapperfn = self.dapperfn
                self.dapperfn = function(inst, _owner, ...)
                    local ret = _dapperfn(inst, _owner, ...)
                    return ret * (ret < 0 and GetTophatSanityMult(ret) or 1)
                end
            end
        end
        local ret = {_GetDapperness(self, owner, ignore_wetness, ...)}
        if _dapperfn then self.dapperfn = _dapperfn end
        if _dapperness then self.dapperness = _dapperness end
        return unpack(ret)
    end
end)
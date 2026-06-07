local env = env
GLOBAL.setfenv(1, GLOBAL)

local SpDamageUtil = require("components/spdamageutil")

local function HasSkill(inst, name)
    return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

env.AddComponentPostInit("combat", function(self)
    local _GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" and self.inst.UMSlipAway and self.inst:UMSlipAway({attacker = attacker, weapon = weapon, stimuli = stimuli}, true) then
            if attacker and weapon and weapon:IsValid() then
                attacker:PushEvent("um_attacker_attacked_pst", {weapon = weapon})
            end
            return true
        end
        if self.inst:HasTag("take_extra_spdamage") and attacker and not attacker:HasTag("player") and attacker.components.health and attacker.components.combat then
            --type check to not crash mods that pass spdamage as something other than actual spdamage.
            if spdamage and type(spdamage) == "table" and spdamage.planar then
                spdamage.planar = spdamage.planar + 10
            else
                spdamage = { planar = 10 }
            end
        end

        local feather_frock = self.inst.components.inventory and self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)

        if feather_frock and feather_frock:HasTag("um_feather_frock") then
            if damage - feather_frock.frock_damage_reduction <= 0 then
                damage = 1
            else
                damage = damage - feather_frock.frock_damage_reduction
            end
        end

        if self.inst:HasTag("wathom_really_spooking_me") then
            damage = damage * 1.5
        end

        if stimuli and stimuli == "fire" and self.inst.components.health and self.inst.components.health:GetFireDamageScale() then
            damage = damage * self.inst.components.health:GetFireDamageScale()
        end

        local damageredirecttarget = self.redirectdamagefn and self.redirectdamagefn(self.inst, attacker, damage, weapon, stimuli)
        local redirect_combat = damageredirecttarget and damageredirecttarget.components.combat
        if TUNING.DSTU.BEEFALO_NERF and damageredirecttarget and damageredirecttarget.components.rideable and redirect_combat then
            if self.inst.components.health and not self.inst.components.health:IsDead() then
                redirect_combat:GetAttacked(attacker, damage, weapon, stimuli)
                return _GetAttacked(self, attacker, damage / 2, weapon, "beefalo_half_damage", ...) -- added new stimuli to prevent Stackoverflow
            else
                redirect_combat:GetAttacked(attacker, damage, weapon, stimuli)
            end
        end

        if self.inst and self.inst:HasTag("wathom") and self.inst.AmpDamageTakenModifier and damage and (not self.inst.components.rider or not self.inst.components.rider:IsRiding()) and TUNING.DSTU.WATHOM_ARMOR_DAMAGE then
            -- Take extra damage
            -- if HasSkill(self.inst,"ancient_terror_3") and self.inst:HasTag("amped") and not self.inst:HasTag("deathamp") then
            -- damage = damage * self.inst.AmpDamageTakenModifier*0.5
            -- self.inst.components.adrenaline:DoDelta(-damage/3)
            -- else
            damage = damage * self.inst.AmpDamageTakenModifier
            --end
        elseif self.inst and self.inst.components.upgrademoduleowner and damage and (not self.inst.components.rider or not self.inst.components.rider:IsRiding()) and TUNING.DSTU.WXLESS then
            -- Hardy circuit flat damage reduction
            local small_absorb_table = { 0, 2, 4, 5.5, 7, 8, 9, 9.5, 10 }
            local big_absorb_table = { 0, 5, 9, 12, 15 }
            local small_modules = self.inst.components.upgrademoduleowner:GetModuleTypeCount('maxhealth') or 0
            local big_modules = self.inst.components.upgrademoduleowner:GetModuleTypeCount('maxhealth2') or 0
            if small_modules > 8 then small_modules = 8 end
            if big_modules > 4 then big_modules = 4 end
            local hpmodulereduct = small_absorb_table[small_modules + 1] + big_absorb_table[big_modules + 1]
            if self.inst._cherriftchips and self.inst._cherriftchips > 0 then
                hpmodulereduct = hpmodulereduct + self.inst._cherriftchips * 1.5
            end
            if damage > 5 then
                damage = damage - hpmodulereduct
                if damage < 5 then damage = 5 end
            end
        elseif self.inst ~= nil and attacker ~= nil and attacker:HasTag("wathom") and TUNING.DSTU.WATHOM_MAX_DAMAGE_CAP then
            if damage > 600 then damage = 600 end
            --elseif self.inst ~= nil and (self.inst.prefab == "bernie_active" or self.inst.prefab == "bernie_big") and attacker ~= nil and attacker:HasTag("shadow") and TUNING.DSTU.BERNIE_BUFF then
            --damage = damage * 0.2
            --return _GetAttacked(self, attacker, damage, weapon, stimuli, ...)
        elseif self.inst:HasTag("ratwhisperer") and attacker and attacker.prefab == "catcoon" and self.inst.components.health then
            self.inst.components.health:DoDelta(-10, false, attacker.prefab)
        end
        local ret = {_GetAttacked(self, attacker, damage, weapon, stimuli, spdamage, ...)}
        if attacker and attacker:IsValid() and weapon and weapon:IsValid() then
            attacker:PushEvent("um_attacker_attacked_pst", {weapon = weapon})
        end
        return unpack(ret)
    end
end)
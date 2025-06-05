local env = env
GLOBAL.setfenv(1, GLOBAL)

local SpDamageUtil = require("components/spdamageutil")

env.AddComponentPostInit("combat", function(self)
    if not TheWorld.ismastersim then return end

    function self:DoNaughtAttack(targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos)
        if instrangeoverride then
            self.temprange = instrangeoverride
        end
        if instpos then
            self.temppos = instpos
        end
        if not targ then
            targ = self.target
        end
        if not weapon then
            weapon = self:GetWeapon()
        end
        if not stimuli then
            if weapon and weapon.components.weapon and weapon.components.weapon.overridestimulifn then
                stimuli = weapon.components.weapon.overridestimulifn(weapon, self.inst, targ)
            end
            if not stimuli and self.inst.components.electricattacks then
                stimuli = "electric"
            end
        end

        if not self:CanHitTarget(targ, weapon) or self.AOEarc then
            self.inst:PushEvent("onmissother", { target = targ, weapon = weapon })
            if self.areahitrange and not self.areahitdisabled then
                self:DoAreaAttack(projectile or self.inst, self.areahitrange, weapon, self.areahitcheck, stimuli, AREA_EXCLUDE_TAGS)
            end
            self:ClearAttackTemps()
            return
        end

        self.inst:PushEvent("onattackother", {target = targ, weapon = weapon, projectile = projectile, stimuli = stimuli, mockattack = true})

        if weapon and not projectile then
            if weapon.components.projectile then
                local projectile = self.inst.components.inventory:DropItem(weapon, false)
                if projectile then
                    projectile.components.projectile:Throw(self.inst, targ)
                end
                self:ClearAttackTemps()
                return
            elseif weapon.components.complexprojectile and not weapon.components.complexprojectile.ismeleeweapon then
                local projectile = self.inst.components.inventory:DropItem(weapon, false)
                if projectile then
                    projectile.components.complexprojectile:Launch(targ:GetPosition(), self.inst)
                end
                self:ClearAttackTemps()
                return
            elseif weapon.components.weapon:CanRangedAttack() then
                weapon.components.weapon:LaunchProjectile(self.inst, targ)
                self:ClearAttackTemps()
                return
            end
        end

        local reflected_dmg = 0
        local reflected_spdmg
        local reflect_list = {}
        if targ.components.combat then
            local mult = (stimuli == "electric" or (weapon and weapon.components.weapon and weapon.components.weapon.stimuli == "electric"))
                and not (targ:HasTag("electricdamageimmune") or (targ.components.inventory and targ.components.inventory:IsInsulated()))
                and TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (targ.components.moisture and targ.components.moisture:GetMoisturePercent()
                or (targ:GetIsWet() and 1 or 0)) or 1
            local dmg, spdmg = self:CalcDamage(targ, weapon, mult)
            dmg = (dmg * (instancemult or 1)) / 2
            --Calculate reflect first, before GetAttacked destroys armor etc.
            if not projectile then
                reflected_dmg, reflected_spdmg = self:CalcReflectedDamage(targ, dmg, weapon, stimuli, reflect_list, spdmg)
            end
            targ.components.combat:GetAttacked(self.inst, dmg, weapon, stimuli, spdmg)
        elseif not projectile then
            reflected_dmg, reflected_spdmg = self:CalcReflectedDamage(targ, 0, weapon, stimuli, reflect_list)
        end

        if weapon and not weapon:HasTag("pocketwatch") then
            weapon.components.weapon:OnAttack_NoDurabilityLoss(self.inst, targ, projectile)
        end

        if self.areahitrange and not self.areahitdisabled then
            self:DoAreaAttack(targ, self.areahitrange, weapon, self.areahitcheck, stimuli, AREA_EXCLUDE_TAGS)
        end
        self:ClearAttackTemps()
        self.lastdoattacktime = GetTime()

        --Apply reflected damage to self after our attack damage is completed
        if (reflected_dmg > 0 or reflected_spdmg) and self.inst.components.health and not self.inst.components.health:IsDead() then
            self:GetAttacked(targ, reflected_dmg, nil, nil, reflected_spdmg)
            for i, v in ipairs(reflect_list) do
                if v.inst:IsValid() then
                    v.inst:PushEvent("onreflectdamage", v)
                end
            end
        end
    end

    local _GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage, ...)
        if self.inst:HasTag("take_extra_spdamage") and attacker and not attacker:HasTag("player") and attacker.components.health and attacker.components.combat then
            --type check to not crash mods that pass spdamage as something other than actual spdamage.
            if spdamage and type(spdamage) == "table" and spdamage.planar then
                spdamage.planar = spdamage.planar + 10
            else
                spdamage = {planar = 10}
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

        local weapon_check = weapon ~= nil and weapon:IsValid() and weapon

        if stimuli and stimuli == "fire" and self.inst.components.health and self.inst.components.health:GetFireDamageScale() then
            damage = damage * self.inst.components.health:GetFireDamageScale()
        end

        local damageredirecttarget = self.redirectdamagefn and self.redirectdamagefn(self.inst, attacker, damage, weapon_check, stimuli)

        local redirect_combat = damageredirecttarget and damageredirecttarget.components.combat
        if redirect_combat and TUNING.DSTU.BEEFALO_NERF then
            if self.inst.components.health and not self.inst.components.health:IsDead() then
                redirect_combat:GetAttacked(attacker, damage, weapon_check, stimuli)
                return _GetAttacked(self, attacker, damage / 2, weapon_check, "beefalo_half_damage", ...) -- added new stimuli to prevent Stackoverflow
            else
                redirect_combat:GetAttacked(attacker, damage, weapon_check, stimuli)
            end
        end

        if self.inst and self.inst:HasTag("wathom") and self.inst.AmpDamageTakenModifier and damage and (not self.inst.components.rider or not self.inst.components.rider:IsRiding()) and TUNING.DSTU.WATHOM_ARMOR_DAMAGE then
            -- Take extra damage
            damage = damage * self.inst.AmpDamageTakenModifier
        elseif self.inst and self.inst.components.upgrademoduleowner and damage and (not self.inst.components.rider or not self.inst.components.rider:IsRiding()) and TUNING.DSTU.WXLESS then
            -- Hardy circuit flat damage reduction
            local small_absorb_table = {0, 2, 4, 5.5, 7, 8, 9, 9.5, 10}
            local big_absorb_table = {0, 5, 9, 12, 15}
            local small_modules = self.inst.components.upgrademoduleowner:GetModuleTypeCount('maxhealth') or 0
            local big_modules = self.inst.components.upgrademoduleowner:GetModuleTypeCount('maxhealth2') or 0
            if small_modules > 8 then small_modules = 8 end
            if big_modules > 4 then big_modules = 4 end
            local hpmodulereduct = small_absorb_table[small_modules+1] + big_absorb_table[big_modules+1]
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
            --return _GetAttacked(self, attacker, damage, weapon_check, stimuli, ...)
        elseif self.inst:HasTag("ratwhisperer") and attacker and attacker.prefab == "catcoon" and self.inst.components.health then
            self.inst.components.health:DoDelta(-10, false, attacker.prefab)
        end

        return _GetAttacked(self, attacker, damage, weapon_check, stimuli, spdamage, ...)
    end
end)
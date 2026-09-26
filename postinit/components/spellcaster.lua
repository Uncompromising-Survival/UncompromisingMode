local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

--env.AddComponentPostInit("spellcaster", function(self) end)

local UMUpvalueHacker = require("tools/um_upvaluehacker")
env.AddSimPostInit(function()
    local COMPONENT_ACTIONS = UMUpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local POINT, EQUIPPED = COMPONENT_ACTIONS.POINT, COMPONENT_ACTIONS.EQUIPPED
        if POINT then
            local _POINT_spellcaster_fn = POINT["spellcaster"]
            if _POINT_spellcaster_fn then
                POINT["spellcaster"] = function(inst, doer, pos, actions, right, target, ...)
                    if inst.um_cancastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and not inst:um_cancastontarget(doer, pos, target, UMCommonFns.HasRightClickAction(inst, doer, pos, target)) then return end
                    local wixie_weapon = inst:HasTag("wixie_weapon")
                    if wixie_weapon or inst:HasTag("um_gun") then
                        if not right or wixie_weapon and not doer:HasTag("troublemaker") then return end
                        local action = wixie_weapon and ACTIONS.WIXIE_SLINGSHOT or ACTIONS.UM_GUNSHOOTY
                        local cast_on_water = inst:HasTag("castonpointwater")
                        if inst:HasTag("castonpoint") then
                            local px, py, pz = pos:Get()
                            if TheWorld.Map:IsAboveGroundAtPoint(px, py, pz, cast_on_water) and not TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, action)
                            end
                        elseif cast_on_water then
                            local px, py, pz = pos:Get()
                            if TheWorld.Map:IsOceanAtPoint(px, py, pz, false) and not TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, action)
                            end
                        end
                        return
                    end
                    return _POINT_spellcaster_fn(inst, doer, pos, actions, right, target, ...)
                end
            end
        end
        if EQUIPPED then
            local _EQUIPPED_spellcaster_fn = EQUIPPED["spellcaster"]
            if _EQUIPPED_spellcaster_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    if inst.um_cancastontarget and right and doer.components.playercontroller and not doer.components.playercontroller:IsControlPressed(TUNING.DSTU.CASTSPELL_OVERRIDECONTROL)
                        and not inst:um_cancastontarget(doer, nil, target, UMCommonFns.HasRightClickAction(inst, doer, nil, target)) then return end
                    local wixie_weapon = inst:HasTag("wixie_weapon")
                    if wixie_weapon or inst:HasTag("um_gun") then
                        if right and (not wixie_weapon or doer:HasTag("troublemaker")) and (inst:HasTag("castontargets") or (target:HasTag("locomotor") and (inst:HasTag("castonlocomotors")
                            or (inst:HasTag("castonlocomotorspvp") and (target == doer or TheNet:GetPVPEnabled() or not (target:HasTag("player") and doer:HasTag("player"))))))
                            or (inst:HasTag("castoncombat") and doer.replica.combat and doer.replica.combat:CanTarget(target))) then
                            table.insert(actions, wixie_weapon and ACTIONS.WIXIE_SLINGSHOT or ACTIONS.UM_GUNSHOOTY)
                        end
                        return
                    end
                    return _EQUIPPED_spellcaster_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)
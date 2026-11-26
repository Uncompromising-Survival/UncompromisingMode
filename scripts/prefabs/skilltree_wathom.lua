
-- Carlos may have left this here?
local function ShowLowHealth(inst)
    local WARNING_MUST_TAGS = {"_health", "_combat"}
    local WARNING_MUST_NOT_TAGS = {"player", "wall", "soulless"}
    local x,y,z = inst.Transform:GetWorldPosition()
    local creatures = TheSim:FindEntities(x, y, z, 24, WARNING_MUST_TAGS, WARNING_MUST_NOT_TAGS)
    for i,creature in ipairs(creatures) do
        if creature.components.combat and creature.components.health then
            if (creature.components.health:GetPercent() <= 0.3 and not creature:HasTag("epic")) or (creature.components.health:GetPercent() <= 0.1 and creature:HasTag("epic")) then
                local fx = SpawnPrefab("reticuleaoewinonaengineeringping") --reticuleaoewinonaengineeringping or some Forge thing or wurt_tentacle_warning
                fx.entity:SetParent(creature.entity)
            end
        end
    end
end


local function SetDiet(inst)
    local diet = {FOODTYPE.MEAT, FOODTYPE.GOODIES}
    local group = {FOODGROUP.OMNI}
    
    if inst.wathom_munches_lichen then
        inst.components.eater:SetStrongStomach(true) -- No bad stats from MM
        table.insert(diet,FOODTYPE.LICHEN)
    end
    if inst.wathom_consumes_nightmares then
        table.insert(diet,FOODTYPE.UM_NIGHTMARES)
        table.insert(group,FOODTYPE.UM_NIGHTMARES)
    end

    inst.components.eater:SetDiet(group,diet)
    
end

-- Magic Affinity - Taken from Maxwell
local function GetEquippableDapperness(owner, equippable)
	local dapperness = equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
	return equippable.inst:HasTag("shadow_item")
		and dapperness * 0.5 -- Wathom's resistance is not as good as Maxwell's
		or dapperness
end


local function BuildSkillsData(SkillTreeFns)
    local skills = 
    {
        artificer_1 = {
            title = STRINGS.SKILLTREE.WATHOM.ARTIFICER_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ARTIFICER_1_DESC,
            icon = "wathom_artificer_1",
            pos = {-38-38-38,38},
            --pos = {0,-1},
            group = "artificer",
            tags = {"artificer","the_mind"},
            root = true,
            onactivate = function(inst, fromload)
                inst.components.sanity.get_equippable_dappernessfn = GetEquippableDapperness
                inst:AddComponent("staffsanity") -- Taken from Wanda
                inst.components.staffsanity:SetMultiplier(0.5)
            end,
            ondeactivate = function(inst,fromload)
                inst.components.sanity.get_equippable_dappernessfn = nil
                inst:RemoveComponent("staffsanity")
            end,
            connects = {
                "artificer_2",
            },
        },
        artificer_2 = {
            title = STRINGS.SKILLTREE.WATHOM.ARTIFICER_2_TITLE,
            icon = "wathom_artificer_2",
            desc = STRINGS.SKILLTREE.WATHOM.ARTIFICER_2_DESC,
            group = "artificer",
            tags = {"artificer","the_mind"},
            pos = {-38-38-38,38+38},
            connects = {
                "artificer_3",
            },
        },
        artificer_3 = {
            title = STRINGS.SKILLTREE.WATHOM.ARTIFICER_3_TITLE,
            icon = "wathom_artificer_3",
            desc = STRINGS.SKILLTREE.WATHOM.ARTIFICER_3_DESC,
            group = "artificer",
            tags = {"artificer","the_mind"},
            pos = {-38-38-38,38+38+38},
        },
        wathom_artificer_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {-38-38-38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "artificer", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or  
                (SkillTreeFns.CountTags(prefabname, "artificer", activatedskills) == 4) then
                    return true
                end
            end,
        },
        artificer_4 = {
            title = STRINGS.SKILLTREE.WATHOM.ARTIFICER_4_TITLE,
            icon = "wathom_artificer_4",
            desc = STRINGS.SKILLTREE.WATHOM.ARTIFICER_4_DESC,
            group = "artificer",
            tags = {"capstone","the_mind","artificer"},
            locks = {"wathom_artificer_lock"},
            pos = {-38-38-38,38+38+38+38+38},
        },


        stalker_1 = {
            title = STRINGS.SKILLTREE.WATHOM.STALKER_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.STALKER_1_DESC,
            icon = "wathom_stalker_1",
            pos = {-38-38,38},
            --pos = {0,-1},
            group = "stalker",
            tags = {"stalker","the_mind"},
            root = true,
            connects = {
                "stalker_2",
            },
        },
        stalker_2 = {
            title = STRINGS.SKILLTREE.WATHOM.STALKER_2_TITLE,
            icon = "wathom_stalker_2",
            desc = STRINGS.SKILLTREE.WATHOM.STALKER_2_DESC,
            group = "stalker",
            tags = {"stalker","the_mind"},
            pos = {-38-38,38+38},
            connects = {
                "stalker_3",
            },
        },
        stalker_3 = {
            title = STRINGS.SKILLTREE.WATHOM.STALKER_3_TITLE,
            icon = "wathom_stalker_3",
            desc = STRINGS.SKILLTREE.WATHOM.STALKER_3_DESC,
            group = "stalker",
            tags = {"stalker","the_mind"},
            pos = {-38-38,38+38+38},
        },
        wathom_stalker_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {-38-38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "stalker", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or 
                (SkillTreeFns.CountTags(prefabname, "stalker", activatedskills) == 4) then
                    return true
                end
            end,
        },
        stalker_4 = {
            title = STRINGS.SKILLTREE.WATHOM.STALKER_4_TITLE,
            icon = "wathom_stalker_4",
            desc = STRINGS.SKILLTREE.WATHOM.STALKER_4_DESC,
            group = "stalker",
            tags = {"stalker","capstone","the_mind"},
            locks = {"wathom_stalker_lock"},
            pos = {-38-38,38+38+38+38+38},
        },

        hyper_1 = {
            title = STRINGS.SKILLTREE.WATHOM.HYPER_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.HYPER_1_DESC,
            icon = "wathom_hyper_1",
            pos = {-38,38},
            --pos = {0,-1},
            group = "hyper",
            tags = {"hyper","the_mind"},
            root = true,
            connects = {
                "hyper_2",
            },
        },
        hyper_2 = {
            title = STRINGS.SKILLTREE.WATHOM.HYPER_2_TITLE,
            icon = "wathom_hyper_2",
            desc = STRINGS.SKILLTREE.WATHOM.HYPER_2_DESC,
            group = "hyper",
            tags = {"hyper","the_mind"},
            pos = {-38,38+38},
            connects = {
                "hyper_3",
            },
        },
        hyper_3 = {
            title = STRINGS.SKILLTREE.WATHOM.HYPER_3_TITLE,
            icon = "wathom_hyper_3",
            desc = STRINGS.SKILLTREE.WATHOM.HYPER_3_DESC,
            group = "hyper",
            tags = {"hyper","the_mind"},
            pos = {-38,38+38+38},
        },
        wathom_hyper_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {-38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "hyper", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or 
                (SkillTreeFns.CountTags(prefabname, "hyper", activatedskills) == 4) then
                    return true
                end
            end,
        },
        hyper_4 = {
            title = STRINGS.SKILLTREE.WATHOM.HYPER_4_TITLE,
            icon = "wathom_hyper_4",
            desc = STRINGS.SKILLTREE.WATHOM.HYPER_4_DESC,
            group = "hyper",
            tags = {"hyper","capstone","the_mind"},
            locks = {"wathom_hyper_lock"},
            pos = {-38,38+38+38+38+38},
        },
        rampage_1 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_1_TITLE,
            icon = "wathom_rampage_1",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_1_DESC,
            group = "rampage",
            tags = {"rampage","the_body"},
            pos = {38,38},
            root = true,
            connects = {
                "rampage_2",
            },
        },
        rampage_2 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_2_TITLE,
            icon = "wathom_rampage_2",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_2_DESC,
            group = "rampage",
            tags = {"rampage","the_body"},
            pos = {38,38+38},
            connects = {
                "rampage_3",
            },
        },
        rampage_3 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_3_TITLE,
            icon = "wathom_rampage_3",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_3_DESC,
            group = "rampage",
            tags = {"rampage","the_body"},
            pos = {38,38+38+38},
        },
        wathom_rampage_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "rampage", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or 
                (SkillTreeFns.CountTags(prefabname, "rampage", activatedskills) == 4) then
                    return true
                end
            end,
        },
        rampage_4 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_4_TITLE,
            icon = "wathom_rampage_4",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_4_DESC,
            group = "rampage",
            tags = {"rampage","capstone","the_body"},
            locks = {"wathom_rampage_lock"},
            pos = {38,38+38+38+38+38},
        },

        glutton_1 = {
            title = STRINGS.SKILLTREE.WATHOM.GLUTTON_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.GLUTTON_1_DESC,
            icon = "wathom_glutton_1",
            pos = {38+38,38},
            group = "glutton",
            tags = {"glutton","the_body"},
            root = true,
            connects = {
                "glutton_2",
            },
        },
        glutton_2 = {
            title = STRINGS.SKILLTREE.WATHOM.GLUTTON_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.GLUTTON_2_DESC,
            icon = "wathom_glutton_2",
            pos = {38+38,38+38},
            group = "glutton",
            tags = {"glutton","the_body"},
            onactivate = function(inst, fromload)
                inst.wathom_consumes_nightmares = true
                SetDiet(inst)
            end,
            ondeactivate = function(inst,fromload)
                inst.wathom_consumes_nightmares = false
                SetDiet(inst)
            end,
            connects = {
                "glutton_3",
            },
        },
        glutton_3 = {
            title = STRINGS.SKILLTREE.WATHOM.GLUTTON_3_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.GLUTTON_3_DESC,
            icon = "wathom_glutton_3",
            pos = {38+38,38+38+38},
            group = "glutton",
            tags = {"glutton","the_body"},
        },
        wathom_glutton_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {38+38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "glutton", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or 
                (SkillTreeFns.CountTags(prefabname, "glutton", activatedskills) == 4) then
                    return true
                end
            end,
        },
        glutton_4 = {
            title = STRINGS.SKILLTREE.WATHOM.GLUTTON_4_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.GLUTTON_4_DESC,
            icon = "wathom_glutton_4",
            pos = {38+38,38+38+38+38+38},
            group = "glutton",
            tags = {"capstone","glutton","the_body"},
            locks = {"wathom_glutton_lock"},
            onactivate = function(inst, fromload)
                if inst:HasTag("amped") and not inst.glutton_regen then
                    inst.glutton_regen = inst:DoPeriodicTask(1,function(inst) inst.HealingGlutton(inst) end)
                end
            end,
            ondeactivate = function(inst,fromload)
                if inst.glutton_regen then
                    inst.glutton_regen:Cancel()
                    inst.glutton_regen = nil
                end
            end,
        },

        devour_1 = {
            title = STRINGS.SKILLTREE.WATHOM.DEVOUR_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.DEVOUR_1_DESC,
            icon = "wathom_devour_1",
            onactivate = function(inst, fromload)
                inst.wathom_munches_lichen = true
                SetDiet(inst)
            end,
            ondeactivate = function(inst,fromload)
                inst.wathom_munches_lichen = false
                SetDiet(inst)
            end,
            pos = {38+38+38,38},
            group = "devour",
            tags = {"devour","the_body"},
            root = true,
            connects = {
                "devour_2",
            },
        },

        devour_2 = {
            title = STRINGS.SKILLTREE.WATHOM.DEVOUR_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.DEVOUR_2_DESC,
            icon = "wathom_devour_2",
            onactivate = function(inst, fromload)
                inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE+2.5)
            end,
            ondeactivate = function(inst, fromload)
                inst.components.combat:SetDefaultDamage(TUNING.UNARMED_DAMAGE)
            end,
            pos = {38+38+38,38+38},
            group = "devour",
            tags = {"devour","the_body"},
            connects = {
                "devour_3",
            },
        },
        devour_3 = {
            title = STRINGS.SKILLTREE.WATHOM.DEVOUR_3_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.DEVOUR_3_DESC,
            icon = "wathom_devour_3",
            pos = {38+38+38,38+38+38},
            group = "devour",
            tags = {"devour","the_body"},
        },
        wathom_devour_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_CAPSTONE_LOCK_DESC,
            pos = {38+38+38,38+38+38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if (SkillTreeFns.CountTags(prefabname, "devour", activatedskills) == 3 and 
                SkillTreeFns.CountTags(prefabname, "capstone", activatedskills) == 0) or  
                (SkillTreeFns.CountTags(prefabname, "devour", activatedskills) == 4) then
                    return true
                end
            end,
        },
        devour_4 = {
            title = STRINGS.SKILLTREE.WATHOM.DEVOUR_4_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.DEVOUR_4_DESC,
            icon = "wathom_devour_4",
            pos = {38+38+38,38+38+38+38+38},
            group = "devour",
            tags = {"devour","capstone","the_body"},
            locks = {"wathom_devour_lock"},
            onactivate = function(inst, fromload)
                if inst:HasTag("amped") then
                    inst.wathom_is_hungry = inst:ListenForEvent("hungerdelta",function(inst) inst.NewHungy(inst) end)
                end
            end,
            ondeactivate = function(inst, fromload)
                if inst.wathom_is_hungry then
                    inst.wathom_is_hungry:Cancel()
                    inst.wathom_is_hungry = nil
                end
            end,
        },

        wathom_themind_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_THEMIND_LOCK_DESC,
            pos = {-38-38-38-38-38,38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "the_mind", activatedskills) > 5 then
                    return true
                end
            end,
        },

        wathom_thebody_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_THEBODY_LOCK_DESC,
            pos = {38+38+38+38+38,38+38},
            --pos = {0.5,0},
            group = "capstone",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "the_body", activatedskills) > 5 then
                    return true
                end
            end,
        },

        escalation = {
            title = STRINGS.SKILLTREE.WATHOM.ESCALATION_AFFINITY_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ESCALATION_AFFINITY_DESC,
            icon = "escalation",
            pos = {38+38+38+38+38+38/2,38+38+38},
            group = "affinity",
            tags = {"affinity"},
            locks = {"wathom_thebody_lock"},
            onactivate = function(inst, fromload)

            end,
            ondeactivate = function(inst, fromload)

            end,
        },

        expedition = {
            title = STRINGS.SKILLTREE.WATHOM.EXPEDITION_AFFINITY_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.EXPEDITION_AFFINITY_DESC,
            icon = "expedition",
            pos = {-38-38-38-38-38-38/2,38+38+38},
            group = "affinity",
            tags = {"affinity"},
            locks = {"wathom_themind_lock"},
            onactivate = function(inst, fromload)

            end,
            ondeactivate = function(inst, fromload)

            end,
        },
        wathom_barkmod_attacks = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_BARKMODS_ATTACKS_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_BARKMODS_ATTACKS_DESC,
            icon = "wathom_barkmod_attacks",
            pos = {-38-38-38-38-38/2,38+38+38},
            group = "affinity",
            tags = {"affinity"},
            locks = {"wathom_themind_lock"},
            onactivate = function(inst, fromload)

            end,
            ondeactivate = function(inst, fromload)

            end,
        },
        wathom_barkmod_effects = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_BARKMODS_EFFECTS_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_BARKMODS_EFFECTS_DESC,
            icon = "wathom_barkmod_effects",
            pos = {38+38+38+38+38/2,38+38+38},
            group = "affinity",
            tags = {"affinity"},
            locks = {"wathom_thebody_lock"},
            onactivate = function(inst, fromload)

            end,
            ondeactivate = function(inst, fromload)

            end,
        },
    }


    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

--------------------------------------------------------------------------------------------------

return BuildSkillsData
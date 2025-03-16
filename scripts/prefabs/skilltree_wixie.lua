require("wixie_skilltree_strings")

local ORDERS =
{
    {"ammocraft",       { -214+18   , 176 + 30 }},
    {"taunt",           { -62       , 176 + 30 }},
    {"shove",           { 66+18     , 176 + 30 }},
    {"allegiance",      { 204       , 176 + 30 }},
}

--------------------------------------------------------------------------------------------------

local function BuildSkillsData(SkillTreeFns)
    local skills = 
    {
        wixie_taunt_1 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_1_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_1_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62,176},
            --pos = {1,0},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_tauntlevel_1")
                end,
            root = true,
            connects = {
                "wixie_taunt_2",
                "wixie_taunt_5",
            },
        },

        wixie_taunt_2 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_2_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_2_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62-38,176-54},
            --pos = {1,-1},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_taunteffect_1")
                end,
            connects = {
                "wixie_taunt_3",
            },
        },
        wixie_taunt_3 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_3_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_3_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62-38,176-54-38},
            --pos = {1,-2},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_taunteffect_2")
                end,        
            connects = {
                "wixie_taunt_4",
            },
        },
        wixie_taunt_4 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_4_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_4_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62-38,176-54-38-38},
            --pos = {1,-3},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_taunteffect_3")
                end,
        },

        wixie_taunt_5 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_5_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_5_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62+38,176-54},
            --pos = {2,-1},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_tauntlevel_2")
                end,         
            connects = {
                "wixie_taunt_6",
            },
        },
        wixie_taunt_6 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_6_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_TAUNT_6_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-62+38,176-54-38},
            --pos = {2,-2},
            group = "taunt",
            tags = {"taunt"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_tauntlevel_3")
                end,
        },

        wixie_ammocraft_1 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_1_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_1_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,176},
            --pos = {0,0},
            group = "ammocraft",
            tags = {"ammocraft"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_ammocraft_1")
                end,
            root = true,
            connects = {
                "wixie_ammocraft_2",
            },
        },
        wixie_ammocraft_2 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_2_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_2_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,176-38},
            --pos = {0,-1},
            group = "ammocraft",
            tags = {"ammocraft"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_ammocraft_2")
                end,        
            connects = {
                "wixie_ammocraft_3",
            },
        },
        wixie_ammocraft_3 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_3_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMOCRAFT_3_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,176-38-38},
            --pos = {0,-2},
            group = "ammocraft",
            tags = {"ammocraft"},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_ammocraft_3")
                end,
        }, 
        wixie_shove_1 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_1_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_1_DESC,
            --icon = "wilson_torch_brightness_1",
            pos = {-214+38,176},        
            --pos = {1,0},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_shove_1")
                end,
            group = "shove",
            tags = {"shove"},
            root = true,
            connects = {
                "wixie_shove_2",
            },
            defaultfocus = true,
        },
        wixie_shove_2 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_2_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_2_DESC,
            --icon = "wilson_torch_brightness_2",
            pos = {-214+38,176-38},
            --pos = {1,-1},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_shove_2")
                end,
            group = "shove",
            tags = {"shove"},
            connects = {
                "wixie_shove_3",
            },
        },
        wixie_shove_3 = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_3_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SHOVE_3_DESC,
            --icon = "wilson_torch_brightness_3",
            pos = {-214+38,176-38-38},
            --pos = {1,-2},
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_shove_3")
                end,
            group = "shove",
            tags = {"shove"},
        }, 

		--[[wixie_slingshot_ammo_honey = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_HONEY_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_HONEY_DESC,
            --icon = "wilson_alchemy_1",
            pos = {66,176},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_honey")
                end,
            tags = {"wixie_slingshot_ammo_honey"},
            root = true,
        },]]
        wixie_slingshot_ammo_stinger = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_STINGER_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_STINGER_DESC,
            --icon = "wilson_alchemy_1",
            pos = {66,176-38},
            --pos = {0,-1},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_stinger")
                end,
            tags = {"wixie_slingshot_ammo_stinger"},
            root = true,
        },
        wixie_slingshot_ammo_scrapfeather = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_SCRAPFEATHER_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_SCRAPFEATHER_DESC,
            --icon = "wilson_alchemy_1",
            pos = {66,176-38-38},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_scrapfeather")
                end,
            tags = {"wixie_slingshot_ammo_scrapfeather"},
            root = true,
        },

        --[[wixie_slingshot_ammo_moonglass = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_MOONGLASS_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_MOONGLASS_DESC,
			--icon = "wilson_beard_speed_1",
            pos = {66+38,176},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_moonglass")
                end,
            tags = {"wixie_slingshot_ammo_moonglass"},
            root = true,
        },]]
        wixie_slingshot_ammo_gunpowder = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_GUNPOWDER_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_GUNPOWDER_DESC,
            --icon = "wilson_beard_speed_2",
            pos = {66+38,176-38},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_gunpowder")
                end,
            tags = {"wixie_slingshot_ammo_gunpowder"},
            root = true,
        },
        wixie_slingshot_ammo_dreadstone = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_DREADSTONE_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_SLINGSHOT_AMMO_DREADSTONE_DESC,
            --icon = "wilson_beard_speed_3",
            pos = {66+38,176-38-38},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_slingshot_ammo_dreadstone")
                end,
            tags = {"wixie_slingshot_ammo_dreadstone"},
            root = true,
        },
		
		wixie_ammo_bag = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMO_BAG_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_AMMO_BAG_DESC,
            --icon = "wilson_torch_throw",
            pos = {-214+18,58-38},        
            --pos = {2,-1},
            group = "wixie_ammo",
            onactivate = function(inst, fromload)
                    inst:AddTag("wixie_ammo_bag")
                end,
            tags = {"wixie_ammo_bag"},
            root = true,
        },   

        wixie_allegiance_lock_1 = {
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_ALLEGIANCE_LOCK_1_DESC,
            pos = {204+2,176},
            --pos = {0.5,0},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                return SkillTreeFns.CountSkills(prefabname, activatedskills) >= 12
            end,
            connects = {
                "wixie_allegiance_shadow",
            },
        },

        wixie_allegiance_lock_2 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_2_DESC,
            pos = {204-22+2,176-50+2},  
            --pos = {0,-1},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if readonly then
                    return "question"
                end

                return TheGenericKV:GetKV("fuelweaver_killed") == "1"
            end,
            connects = {
                "wixie_allegiance_shadow",
            },
        },

        wixie_allegiance_lock_4 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_4_DESC,
            pos = {204-22+2,176-100+8},  
            --pos = {0,-1},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                if SkillTreeFns.CountTags(prefabname, "lunar_favor", activatedskills) == 0 then
                    return true
                end
    
                return nil -- Important to return nil and not false.
            end,
            connects = {
                "wixie_allegiance_shadow",
            },
        },    

        wixie_allegiance_shadow = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_ALLEGIANCE_SHADOW_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_ALLEGIANCE_SHADOW_DESC,
            --icon = "wilson_favor_shadow",
            pos = {204-22+2 ,176-110-38+10},  --  -22
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","shadow","shadow_favor"},
            locks = {"wixie_allegiance_lock_1", "wixie_allegiance_lock_2", "wixie_allegiance_lock_4"},
            onactivate = function(inst, fromload)
                inst:AddTag("skill_wixie_allegiance_shadow")
                inst:AddTag("player_shadow_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("shadow_aligned", inst, TUNING.SKILLS.WIXIE_ALLEGIANCE_SHADOW_RESIST, "wixie_allegiance_shadow")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.SKILLS.WIXIE_ALLEGIANCE_VS_LUNAR_BONUS, "wixie_allegiance_shadow")
                end
            end,
            ondeactivate = function(inst, fromload)
                inst:RemoveTag("skill_wixie_allegiance_shadow")
                inst:RemoveTag("player_shadow_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("shadow_aligned", inst, "wixie_allegiance_shadow")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("lunar_aligned", inst, "wixie_allegiance_shadow")
                end
            end,
        },  

        wixie_allegiance_lock_3 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_3_DESC,
            pos = {204+22+2,176-50+2},
            --pos = {0,-1},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if readonly then
                    return "question"
                end

                return TheGenericKV:GetKV("celestialchampion_killed") == "1"
            end,
            connects = {
                "wixie_allegiance_lunar",
            },
        },

        wixie_allegiance_lock_5 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_5_DESC,
            pos = {204+22+2,176-100+8},  
            --pos = {0,-1},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                if SkillTreeFns.CountTags(prefabname, "shadow_favor", activatedskills) == 0 then
                    return true
                end
    
                return nil -- Important to return nil and not false.
            end,
            connects = {
                "wixie_allegiance_lunar",
            },
        },

        wixie_allegiance_lunar = {
            title = STRINGS.SKILLTREE.WIXIE.WIXIE_ALLEGIANCE_LUNAR_TITLE,
            desc = STRINGS.SKILLTREE.WIXIE.WIXIE_ALLEGIANCE_LUNAR_DESC,
            --icon = "wilson_favor_lunar",
            pos = {204+22+2 ,176-110-38+10},
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","lunar","lunar_favor"},
            locks = {"wixie_allegiance_lock_1", "wixie_allegiance_lock_3","wixie_allegiance_lock_5"},
            onactivate = function(inst, fromload)
                inst:AddTag("skill_wixie_allegiance_lunar")
                inst:AddTag("player_lunar_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("lunar_aligned", inst, TUNING.SKILLS.WIXIE_ALLEGIANCE_LUNAR_RESIST, "wixie_allegiance_lunar")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.SKILLS.WIXIE_ALLEGIANCE_VS_SHADOW_BONUS, "wixie_allegiance_lunar")
                end
            end,
            ondeactivate = function(inst, fromload)
                inst:RemoveTag("skill_wixie_allegiance_lunar")
                inst:RemoveTag("player_lunar_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("lunar_aligned", inst, "wixie_allegiance_lunar")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("shadow_aligned", inst, "wixie_allegiance_lunar")
                end
            end,
        },
    }

    for name, data in pairs(skills) do
        -- If it's not a lock.
        if not data.lock_open then
            data.icon = data.icon or name

            if not table.contains(data.tags, data.group) then
                table.insert(data.tags, data.group)
            end
        end
    end

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

--------------------------------------------------------------------------------------------------

return BuildSkillsData
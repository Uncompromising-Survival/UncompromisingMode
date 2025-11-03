
local ORDERS =
{
    {"entropic_anatomy",       { -214+18   , 176 + 30 }},
    {"amp_up",           { -62       , 176 + 30 }},
    {"forgotten_knowledge",           { 66+18     , 176 + 30 }},
    {"allegiance",      { 204-50       , 176 + 30 }},
}
STRINGS.SKILLTREE.PANELS.ENTROPIC_ANATOMY = "Entropic Anatomy"
STRINGS.SKILLTREE.PANELS.FORGOTTEN_KNOWLEDGE = "Forgotten Knowledge" 
STRINGS.SKILLTREE.PANELS.AMP_UP = "Amp Up"
--------------------------------------------------------------------------------------------------
local function disable_despawn(inst)
	inst._can_despawn = false
end

local function HasSkill(inst,name)
	return inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local brain = require "brains/um_pissedgestaltbrain"
local function CheckForGreater(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local guards = TheSim:FindEntities(x,y,z,24,{"brightmare_guard"})
	if #guards == 0 and inst.components.sanity and inst.components.sanity:GetPercent() > 0.95 then
		local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, 16, 20)
		if offset then
			local guard = SpawnPrefab("gestalt_guard")
			guard.Transform:SetPosition(x+offset.x,0,z+offset.z)
			guard.tracking_target = inst
			--guard.components.combat:SetTarget(inst)
		end
	end
end

local function CheckForMORE(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local gestalts = TheSim:FindEntities(x,y,z,24,{"brightmare"})
	if #gestalts < 10 then
		local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, 16, 20)
		if offset then
			local gestalt = SpawnPrefab("gestalt")
			gestalt.Transform:SetPosition(x+offset.x,0,z+offset.z)
			gestalt.components.locomotor.walkspeed = TUNING.GESTALT_WALK_SPEED*2
			gestalt.components.locomotor.runspeed = TUNING.GESTALT_WALK_SPEED*2
			gestalt.tracking_target = inst
			--guard.components.combat:SetTarget(inst)
			-- gestalt.brain:Stop()
			-- guard.brain = nil
			-- gestalt:SetBrain(brain)
		end
	end
end

local function PissOfGestalts(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local gestalts = TheSim:FindEntities(x,y,z,24,{"brightmare"})
	for i,gestalt in ipairs(gestalts) do
		if gestalt.components.combat and not gestalt.components.combat.target and not gestalt.pissed then
			gestalt.pissed = true
			gestalt.components.locomotor.walkspeed = TUNING.GESTALT_WALK_SPEED*2
			gestalt.components.locomotor.runspeed = TUNING.GESTALT_WALK_SPEED*2
			--gestalt.components.combat:SetTarget(inst)
			--gestalt.brain:Stop()
			-- guard.brain = nil
			-- gestalt:SetBrain(brain)
			gestalt.tracking_target = inst
			disable_despawn(gestalt)
		end
	end

	--CheckForGreater(inst)
	CheckForMORE(inst)
end

local function BuildSkillsData(SkillTreeFns)
    local skills = 
    {
		rampage_1 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_1_TITLE,
			icon = "wathom_rampage_1",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_1_DESC,
            group = "rampage",
            tags = {"rampage"},
            pos = {-214+38+38+38+38,58},
            --pos = {1,-3},
			--root = true,
            connects = {
                "rampage_2",
            },
        },
        rampage_2 = {
            title = STRINGS.SKILLTREE.WATHOM.RAMPAGE_2_TITLE,
			icon = "wathom_rampage_2",
            desc = STRINGS.SKILLTREE.WATHOM.RAMPAGE_2_DESC,
            group = "rampage",
            tags = {"rampage"},
            pos = {-214+38+38+38+38,58+38},
        },

        amp_1 = {
            title = STRINGS.SKILLTREE.WATHOM.AMP_1_TITLE,
			icon = "wathom_amp_1",
            desc = STRINGS.SKILLTREE.WATHOM.AMP_1_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,58-38},
            group = "amp",
            tags = {"amp"},
            onactivate = function(inst, fromload)
                end,
            root = true,
            connects = {
                "amp_2",
            },
        },
        amp_2 = {
            title = STRINGS.SKILLTREE.WATHOM.AMP_2_TITLE,
			icon = "wathom_amp_2",
            desc = STRINGS.SKILLTREE.WATHOM.AMP_2_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,58+38-38},
            group = "amp",
            tags = {"amp"},
            onactivate = function(inst, fromload)
                end,        
            connects = {
                "amp_3",
            },
        },
        amp_3 = {
            title = STRINGS.SKILLTREE.WATHOM.AMP_3_TITLE,
			icon = "wathom_amp_3",
            desc = STRINGS.SKILLTREE.WATHOM.AMP_3_DESC,
            --icon = "wilson_alchemy_1",
            pos = {-214,58+38+38-38},
            group = "amp",
            tags = {"amp3"},
            onactivate = function(inst, fromload)
                end,
            connects = {
                "shadow_wathom_1",
            },
        }, 
        shadow_wathom_1 = {
            title = STRINGS.SKILLTREE.WATHOM.SHADOW_WATHOM_1_TITLE,
			icon = "wathom_shadow_wathom_1",
            desc = STRINGS.SKILLTREE.WATHOM.SHADOW_WATHOM_1_DESC,
            --icon = "wilson_torch_brightness_1",
            pos = {-214,58+38+38-38+38},    
            --pos = {1,0},
            onactivate = function(inst, fromload)
                end,
            group = "shadow_wathom",
            tags = {"shadow_wathom"},
            connects = {
                "shadow_wathom_2",
            },
            defaultfocus = true,
        },
        shadow_wathom_2 = {
            title = STRINGS.SKILLTREE.WATHOM.SHADOW_WATHOM_2_TITLE,
			icon = "wathom_shadow_wathom_2",
            desc = STRINGS.SKILLTREE.WATHOM.SHADOW_WATHOM_2_DESC,
            --icon = "wilson_torch_brightness_2",
            pos = {-214,58+38+38-38+38+38},
            --pos = {1,-1},
            onactivate = function(inst, fromload)
				inst._skeleton_prefab = inst.skeleton_prefab
				inst.skeleton_prefab = nil
            end,
            ondeactivate = function(inst, fromload)
				if inst._skeleton_prefab then
					inst.skeleton_prefab = inst._skeleton_prefab
				end
            end,
            group = "shadow_wathom",
            tags = {"shadow_wathom"},
        },

        digitigrade_1 = {
            title = STRINGS.SKILLTREE.WATHOM.DIGITIGRADE_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.DIGITIGRADE_1_DESC,
            icon = "wathom_digitigrade_1",
            pos = {-214+38+38+38,58},
            --pos = {0,-1},
            group = "digitigrade",
            tags = {"digitigrade"},
            --root = true,
            connects = {
                "digitigrade_2",
            },
        },
        digitigrade_2 = {
            title = STRINGS.SKILLTREE.WATHOM.DIGITIGRADE_2_TITLE,
			icon = "wathom_digitigrade_2",
            desc = STRINGS.SKILLTREE.WATHOM.DIGITIGRADE_2_DESC,
            group = "digitigrade",
            tags = {"digitigrade"},
            --icon = "wilson_alchemy_1",
            pos = {-214+38+38+38,58+38},
        },

        bite_1 = {
            title = STRINGS.SKILLTREE.WATHOM.BITE_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.BITE_1_DESC,
			icon = "wathom_bite_1",
            pos = {-214+38+38,58},
            group = "bite",
            tags = {"bite"},
			--root = true,
            connects = {
                "bite_2",
            },
        },
        bite_2 = {
            title = STRINGS.SKILLTREE.WATHOM.BITE_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.BITE_2_DESC,
			icon = "wathom_bite_2",
            pos = {-214+38+38,58+38},
            group = "bite",
            tags = {"bite"},
        },

        bite_mastery = {
            title = STRINGS.SKILLTREE.WATHOM.BITE_MASTERY_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.BITE_MASTERY_DESC,
			icon = "wathom_bite_mastery",
            onactivate = function(inst, fromload)
				inst.components.eater:SetDiet({FOODGROUP.OMNI}, {FOODTYPE.MEAT, FOODTYPE.GOODIES,FOODTYPE.LICHEN})
				--inst.components.eater:SetCanEatRawMeat(true) -- Comment out when we want to invert insanity.
			end,
            pos = {-214+38+38/2,58+38+38+38},
            group = "bite",
            tags = {"bite"},
        },

        bark_mastery = {
            title = STRINGS.SKILLTREE.WATHOM.BARK_MASTERY_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.BARK_MASTERY_DESC,
			icon = "wathom_bark_mastery",
            pos = {-214+38+38+38+38/2,58+38+38+38},
            group = "bark",
            tags = {"bark"},
        },

        echolocation_1 = {
            title = STRINGS.SKILLTREE.WATHOM.ECHOLOCATION_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ECHOLOCATION_1_DESC,
            icon = "wathom_echolocation_1",
            pos = {-214+38,58},
            group = "echo",
            tags = {"echo"},
            --root = true,
            onactivate = function(inst, fromload)
				inst:AddTag("echolocation")
				if not inst.wathom_mapexplorerbonus then
					-- Increases map exploration radius
					local radius = 20
					local intervals = 25
					local theta = 0
					inst.wathom_mapexplorerbonus = inst:DoPeriodicTask(FRAMES, function()
						if TheWorld:HasTag("cave") or TheWorld.state.isnight then
							local pt = Vector3(inst.Transform:GetWorldPosition())
							local offset = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
							theta = theta + (2 * PI / intervals)
							if inst.player_classified ~= nil then
								inst.player_classified.MapExplorer:RevealArea((pt + offset):Get())
								inst.player_classified.MapExplorer:RevealArea((pt - offset):Get())
							end
						end
					end)
				end

			end,
            connects = {
                "echolocation_2",
            },
        },
        echolocation_2 = {
            title = STRINGS.SKILLTREE.WATHOM.ECHOLOCATION_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ECHOLOCATION_2_DESC,
            icon = "wathom_echolocation_2",
            pos = {-214+38,58+38},
            group = "echo",
            tags = {"echo"},
            onactivate = function(inst, fromload)
				inst.wathom_houndtask = inst:DoPeriodicTask(60,function(inst) inst.HoundTask(inst) end)
            end,
            ondeactivate = function(inst, fromload)
				if inst.wathom_houndtask then
					inst.wathom_houndtask:Canel()
					inst.wathom_houndtask = nil
				end
            end,
        },
		
        wathom_allegiance_lock_1a = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_LOCK_1A,
            pos = {204-22+2-50,176},
            --pos = {0.5,0},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "shadow_wathom", activatedskills)	> 1 then
                    return true
                end
            end,
            connects = {
                "wathom_allegiance_shadow",
            },
        },

        wathom_allegiance_lock_1b = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_LOCK_1B,
            pos = {204+22+2-50,176},
            --pos = {0.5,0},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "amp3", activatedskills) > 0 then
                    return true
                end
            end,
            connects = {
                "wathom_allegiance_neutral",
            },
        },

        wathom_allegiance_lock_2 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_2_DESC,
            pos = {204-22+2-50,176-38},  
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
                "wathom_allegiance_shadow",
            },
        },
	
        wathom_bite_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_BITE_LOCK,
            pos = {-214+38+38/2,58-38+38+38+38},  
			group = "bite",
            --pos = {0,-1},
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "bite", activatedskills) >= 2 and SkillTreeFns.CountTags(prefabname, "echo", activatedskills) >= 2 then
                    return true
                end
            end,
            connects = {
                "bite_mastery",
            },
        },
	
        wathom_bark_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_BARK_LOCK,
            pos = {-214+38+38+38+38/2,58-38+38+38+38},  
			group = "bite",
            --pos = {0,-1},
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "rampage", activatedskills) >= 2 and SkillTreeFns.CountTags(prefabname, "digitigrade", activatedskills) >= 2 then
                    return true
                end
            end,
            connects = {
                "bark_mastery",
            },
        },
		
        wathom_amp_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_AMP_LOCK,
            pos = {-214+38+38+38/2,58-38},
            --pos = {0.5,0},
			group = "amp",
            tags = {"lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "amp3", activatedskills)	> 0 then
                    return true
                end
            end,
            connects = {
                "echolocation_1","bite_1","rampage_1","digitigrade_1",
            },
        },
		
        wathom_undying_lock = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_UNDYING_LOCK,
            pos = {0,25+38/2},
            --pos = {0.5,0},
            group = "undying",
            tags = {"undying","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly) 
                if SkillTreeFns.CountTags(prefabname, "amp3", activatedskills) > 0 then
                    return true
                end
            end,
            connects = {
                "wathom_magics","wathom_friends_1"
            },
        },

        wathom_magics = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_MAGICS_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_MAGICS_DESC,
            icon = "wathom_magics",
            pos = {38,25+38},
            group = "ampfuel",
            tags = {"ampfuel"},
            --root = true,
            connects = {
                "wathom_artifacts",
            },
        },
		
        wathom_artifacts = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_ARTIFACTS_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ARTIFACTS_DESC,
            icon = "wathom_artifacts",
            pos = {38+38,25+38},
            group = "ampfuel",
            tags = {"ampfuel"},
            --root = true,
        },
		
        wathom_friends_1 = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_FRIENDS_1_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_FRIENDS_1_DESC,
            icon = "wathom_friends_1",
            pos = {38,25},
            group = "rally",
            tags = {"rally"},
            --root = true,
            connects = {
                "wathom_friends_2",
            },
        },
		
        wathom_friends_2 = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_FRIENDS_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_FRIENDS_2_DESC,
            icon = "wathom_friends_2",
            pos = {38+38,25},
            group = "rally",
            tags = {"rally"},
        },
		
        wathom_allegiance_lock_4 = {
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_LOCK_4,
            pos = {204-22+2-50,176-38-38},  
            --pos = {0,-1},
            group = "allegiance",
            tags = {"allegiance","lock"},
            root = true,
            lock_open = function(prefabname, activatedskills, readonly)
                if SkillTreeFns.CountTags(prefabname, "neutrality", activatedskills) == 0 then
                    return true
                end
    
                return nil -- Important to return nil and not false.
            end,
            connects = {
                "wathom_allegiance_shadow",
            },
        },    

        wathom_allegiance_shadow = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_SHADOW_TITLE,
			icon = "wathom_terror_1",
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_SHADOW_DESC,
            --icon = "wilson_favor_shadow",
            pos = {204-22+2-100 ,176-110-38+38+38+10},  --  -22
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","shadow","shadow_favor"},
            locks = {"wathom_allegiance_lock_1a", "wathom_allegiance_lock_2", "wathom_allegiance_lock_4"},
            onactivate = function(inst, fromload)
                STRINGS._STATUS_ANNOUNCEMENTS.WATHOM.SANITY = STRINGS._STATUS_ANNOUNCEMENTS.WATHOM.LUNACY
				
				if inst.components.sanity then
					local _OldRate
					if inst.components.sanity.custom_rate_fn then
						_OldRate = inst.components.sanity.custom_rate_fn
					end
					inst.components.sanity.custom_rate_fn = function(inst,dt) -- Leave code here for Night Terrors
						local rate = 0
						if TheWorld.state.isday and not TheWorld:HasTag("cave") then
							rate = TUNING.DAPPERNESS_LARGE*10/6.6	
						end	
						local rate1 = 0
						if _OldRate then
							rate1 = _OldRate(inst,dt)
						end
						return rate + rate1
					end
				end
				inst:AddTag("inherentshadowdominance")
				inst:AddTag("shadowdominance")					
                if inst.components.eater then
                    inst.components.eater:SetCanEatRawMeat(false)
                end
				
				-- if not inst.wathom_freebee_sanity then
					-- local pct = inst.components.sanity:GetPercent()
					-- inst.components.sanity:SetPercent(1-pct)
					-- inst.wathom_freebee_sanity = true
				-- end
				
				inst.components.sanity:EnableLunacy(true, "ancientterror")
                inst:AddTag("skill_wathom_allegiance_shadow")
                inst:AddTag("player_shadow_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("shadow_aligned", inst, 0.9, "wathom_allegiance_shadow")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("lunar_aligned", inst, 1.1, "wathom_allegiance_shadow")
                end
				inst:AddTag("inherentshadowdominance")
				inst:AddTag("shadowdominance")				
				inst.pissygestalts = inst:DoPeriodicTask(5,PissOfGestalts)
            end,
            ondeactivate = function(inst, fromload)
                STRINGS._STATUS_ANNOUNCEMENTS.WATHOM.SANITY = STRINGS._STATUS_ANNOUNCEMENTS.WATHOM.SANITY
				inst.components.sanity.night_drain_mult=1
				inst.components.sanity.dapperness=0
				inst.components.sanity.light_drain_immune = true

                if inst.components.eater then
                    inst.components.eater:SetCanEatRawMeat(true)
                end

				inst.components.sanity:EnableLunacy(false, "ancientterror")
                inst:RemoveTag("skill_wathom_allegiance_shadow")
                inst:RemoveTag("player_shadow_aligned")
                local damagetyperesist = inst.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("shadow_aligned", inst, "wathom_allegiance_shadow")
                end
                local damagetypebonus = inst.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("lunar_aligned", inst, "wathom_allegiance_shadow")
                end
				inst:RemoveTag("inherentshadowdominance")
				inst:RemoveTag("shadowdominance")				
				if inst.pissygestalts then
					inst.pissygestalts:Cancel()
					inst.pissygestalts = nil
				end
				inst:RemoveTag("inherentshadowdominance")
				inst:RemoveTag("shadowdominance")	
            end,
            connects = {
                "ancient_terror_2",
            },
        }, 

        ancient_terror_2 = {
            title = STRINGS.SKILLTREE.WATHOM.ANCIENT_TERROR_2_TITLE,
			icon = "wathom_terror_2",
            desc = STRINGS.SKILLTREE.WATHOM.ANCIENT_TERROR_2_DESC,
            pos = {204-22+2-100 ,176-110-38+10+38+38+38},  --  -22
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","shadow","shadow_favor"},
            onactivate = function(inst, fromload)
		
            end,
            ondeactivate = function(inst, fromload)

		
            end,
            connects = {
                "ancient_terror_3",
            },
        },  



        ancient_terror_3 = {
            title = STRINGS.SKILLTREE.WATHOM.ANCIENT_TERROR_3_TITLE,
			icon = "wathom_terror_3",
            desc = STRINGS.SKILLTREE.WATHOM.ANCIENT_TERROR_3_DESC,
            pos = {204-22+2-100 ,176-110-38+10+38+38+38+38},  --  -22
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","shadow","shadow_favor"},
            onactivate = function(inst, fromload)
		
            end,
            ondeactivate = function(inst, fromload)

		
            end,
        },  		

        wathom_allegiance_lock_3 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_3_DESC,
            pos = {204+22+2-50,176-38},
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
                "wathom_allegiance_neutral",
            },
        },

        wathom_allegiance_lock_5 = {
            desc = STRINGS.SKILLTREE.ALLEGIANCE_LOCK_5_DESC,
            pos = {204+22+2-50,176-38-38},  
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
                "wathom_allegiance_neutral",
            },
        },

        wathom_allegiance_neutral = {
            title = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_NEUTRAL_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.WATHOM_ALLEGIANCE_NEUTRAL_DESC,
            icon = "wathom_ancient_kinship_1",
            pos = {204+22+2 ,176-110-38+10+38+38},
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance","neutrality"},--,"lunar","lunar_favor"},
            locks = {"wathom_allegiance_lock_1b", "wathom_allegiance_lock_3","wathom_allegiance_lock_5"},
            -- onactivate = function(inst, fromload)
				-- inst:AddTag("um_ancient_builder")
            -- end,
            -- ondeactivate = function(inst, fromload)
				-- inst:RemoveTag("um_ancient_builder")		
            -- end,

            connects = {
                "ancient_kinship_2",
            },
        },
		
        ancient_kinship_2 = {
            title = STRINGS.SKILLTREE.WATHOM.ANCIENT_KINSHIP_2_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ANCIENT_KINSHIP_2_DESC,
            icon = "wathom_ancient_kinship_2",
            pos = {204+22+2 ,176-110-38+10+38+38+38},
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance"},--,"lunar","lunar_favor"},
            connects = {
                "ancient_kinship_3",
            },
        },

        -- ancient_kinship_3 = {
            -- title = "Ancient Kinship III",
            -- desc = "Unlock the ability to prototype recipes from the Pseudoscience Station, allowing you to craft subsequent items regardless of location.",
            -- icon = "wathom_ancient_kinship_3",
            -- pos = {204+22+2 ,176-110-38+10+38+38},
            -- --pos = {0,-2},
            -- group = "allegiance",
            -- tags = {"allegiance"},--,"lunar","lunar_favor"},
            -- connects = {
                -- "ancient_kinship_4",
            -- },
        -- },

        -- ancient_kinship_4 = {
            -- title = "Ancient Kinship IV",
            -- desc = "Being Amped Up will now replenish the durability of ancient magical items in your inventory regardless of fuel source.", 
            -- icon = "wathom_ancient_kinship_4",
            -- pos = {204+22+2 ,176-110-38+10+38+38+38},
            -- --pos = {0,-2},
            -- group = "allegiance",
            -- tags = {"allegiance"},--,"lunar","lunar_favor"},
            -- connects = {
                -- "ancient_kinship_5",
            -- },
        -- },

        ancient_kinship_3 = {
            title = STRINGS.SKILLTREE.WATHOM.ANCIENT_KINSHIP_3_TITLE,
            desc = STRINGS.SKILLTREE.WATHOM.ANCIENT_KINSHIP_3_DESC,
            icon = "wathom_ancient_kinship_3",
            pos = {204+22+2 ,176-110-38+10+38+38+38+38},
            --pos = {0,-2},
            group = "allegiance",
            tags = {"allegiance"},--,"lunar","lunar_favor"},
        },		
    }

    -- for name, data in pairs(skills) do
        -- -- If it's not a lock.
        -- if not data.lock_open then
            -- --data.icon = data.icon or name

            -- if not table.contains(data.tags, data.group) then
                -- table.insert(data.tags, data.group)
            -- end
        -- end
    -- end

    return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

--------------------------------------------------------------------------------------------------

return BuildSkillsData
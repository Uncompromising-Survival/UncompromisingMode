local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

--[[local function teach(inst)
    local recipe = inst.product_orchestrina
    if recipe == "turfcraftingstation" then
        recipe = "um_scrapper"
	elseif recipe == "refined_dust" then
        recipe = "um_inkubator"
	elseif recipe == "archive_resonator_item" then
        recipe = "um_astral_projector"
    end
	
	local recipe2 = recipe == "um_astral_projector" and "um_astral_projector_target" or nil

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local players = FindPlayersInRange( pos.x, pos.y, pos.z, 20, true )

    for i,player in ipairs(players) do
        if recipe and player.components.builder then
            if not player.components.builder:KnowsRecipe(recipe) then
                player.components.inventory:GiveItem(SpawnPrefab(recipe .. "_blueprint"))
			end
		
            if recipe2 and not player.components.builder:KnowsRecipe(recipe2) then
                player.components.inventory:GiveItem(SpawnPrefab(recipe2 .. "_blueprint"))
			end
        end
    end
	
	inst._Old_teach(inst)
end]]

--[[env.AddPrefabPostInit("archive_lockbox", function(inst)
    if not TheWorld.ismastersim then
        return
    end
	
    local _teach = inst.teach

    local function teach(inst)
        TheNet:Announce("helloooooo heyy")
        local recipe = inst.product_orchestrina
        TheNet:Announce(recipe)
        local players = FindPlayersInRange(pos.x, pos.y, pos.z, 20, true)
        if recipe == "turfcraftingstation" or recipe == "archive_resonator" or recipe == "refined_dust" or recipe == "archive_resonator_item" or recipe == "turf_archive" then
            recipe = "um_scrapper"
        elseif recipe == "refined_dust" then
            recipe = "um_inkubator"
        elseif recipe == "archive_resonator_item" then
            recipe = "um_astral_projector"
        end

        local recipe2 = recipe == "um_astral_projector" and "um_astral_projector_target" or nil

        local pos = Vector3(inst.Transform:GetWorldPosition())
        

        for i, player in ipairs(players) do
            if recipe and player.components.builder then
                if not player.components.builder:KnowsRecipe(recipe) then
                    player.components.inventory:GiveItem(SpawnPrefab(recipe .. "_blueprint"))
                else
                    TheNet:Announce("For the love of god what's wrong")
                end

                if recipe2 and not player.components.builder:KnowsRecipe(recipe2) then
                    player.components.inventory:GiveItem(SpawnPrefab(recipe2 .. "_blueprint"))
                end
            end
        end
        _teach(inst)
    end

	inst.teach = teach]]

	--[[if inst.teach ~= nil then
		inst._Old_teach = inst.teach
		inst.teach = teach
	end]]
--end)

env.AddPrefabPostInit("archive_lockbox_dispencer", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local _OnActivate = inst.components.activatable.OnActivate

    local function OnActivate(inst, doer)
        --local loot = SpawnPrefab("archive_lockbox")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local players = FindPlayersInRange( pt.x, pt.y, pt.z, 20, true )
        local archivemanager = TheWorld.components.archivemanager
		local powered = archivemanager == nil or archivemanager:GetPowerSetting()
        inst:DoTaskInTime(5.2 ,function()
            if math.random() > 0.25 and TUNING.DSTU.DATES.APRIL_FOOLS then
                SpawnPrefab("balloonparty_confetti_cloud").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            for i,player in ipairs(players) do
                local talker = player.components.talker
                local papyrus = SpawnPrefab("wixie_piano_card")
                local fx = SpawnPrefab("archive_lockbox_player_fx")
                if player.components.builder and powered then
                    if inst.product_orchestrina == "archive_resonator_item" then -- Blue
                        if not player.components.builder:KnowsRecipe("um_astral_projector") then
                            player.components.builder:UnlockRecipe("um_astral_projector")
                            --player.components.builder:UnlockRecipe("um_astral_projector_target")
                            if talker then talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_NEW_KNOWLEDGE"), nil, true) end
                            if fx then player:AddChild(fx) end
                            papyrus.Transform:SetPosition(inst.Transform:GetWorldPosition())
                            papyrus.name = "You got: Astral Projectinator!"
                            Launch2(papyrus, inst, 2, 0, 1, .5)
                        else
                            if talker then talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true) end
                        end
                    elseif inst.product_orchestrina == "refined_dust" then -- Red
                        if not player.components.builder:KnowsRecipe("um_astral_projector_target") then
                            player.components.builder:UnlockRecipe("um_astral_projector_target")
                            if talker then talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_NEW_KNOWLEDGE"), nil, true) end
                            if fx then player:AddChild(fx) end
                            papyrus.Transform:SetPosition(inst.Transform:GetWorldPosition())
                            papyrus.name = "You got: Astral Receptionator!"
                            Launch2(papyrus, inst, 2, 0, 1, .5)
                        else
                            if talker then talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true) end
                        end
                    else -- turf_vault = Green, vaultrelic = Orange
                        if not player.components.builder:KnowsRecipe("um_scrapper") then
                            player.components.builder:UnlockRecipe("um_scrapper")
                            if talker then talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_NEW_KNOWLEDGE"), nil, true) end
                            if fx then player:AddChild(fx) end
                            papyrus.Transform:SetPosition(inst.Transform:GetWorldPosition())
                            papyrus.name = "You got: Ancient Scrapper!"
                            Launch2(papyrus, inst, 2, 0, 1, .5)
                        end
                    end
                end
            end
        end)
        _OnActivate(inst, doer)
    end

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
end)
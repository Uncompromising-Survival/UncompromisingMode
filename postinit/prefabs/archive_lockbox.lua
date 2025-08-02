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

    local num = 0
    local function CycleRecipes()
        if num == 0 then
            num = num + 1
            return "um_inkubator"
        elseif num == 1 then
            num = num + 1
            return "um_scrapper"
        elseif num == 2 then
            num = num + 1
            return "um_astral_projector" and "um_astral_projector_target" or nil
        elseif num >= 3 then
            num = 0
            return "um_astral_projector_target"
        end
    end

    local function OnActivate(inst, doer)
        --local loot = SpawnPrefab("archive_lockbox")
        local pt = Vector3(inst.Transform:GetWorldPosition())
        local players = FindPlayersInRange( pt.x, pt.y, pt.z, 20, true )
        local recipe = CycleRecipes()

        inst:DoTaskInTime(5.2 ,function()
            if math.random > 0.25 and TUNING.DSTU.DATES.APRIL_FOOLS then
                SpawnPrefab("balloonparty_confetti_cloud").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            for i,player in ipairs(players) do
                if recipe and player.components.builder then
                    if inst.product_orchestrina == "archive_resonator_item" then
                        if not player.components.builder:KnowsRecipe("um_astral_projector") or player.components.builder:KnowsRecipe("um_astral_projector_target") then
                            player.components.inventory:GiveItem(SpawnPrefab("um_astral_projector_blueprint"))
                            player.components.inventory:GiveItem(SpawnPrefab("um_astral_projector_target_blueprint"))
                        elseif player.components.talker then
                            player.components.talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true)
                        end
                    elseif inst.product_orchestrina == "refined_dust" then
                        if not player.components.builder:KnowsRecipe("um_inkubator") then
                            player.components.inventory:GiveItem(SpawnPrefab("um_inkubator_blueprint"))
                        elseif player.components.talker then
                            player.components.talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true)
                        end
                    else
                        if not player.components.builder:KnowsRecipe("um_scrapper") then
                            player.components.inventory:GiveItem(SpawnPrefab("um_scrapper_blueprint"))
                        elseif player.components.talker then
                            player.components.talker:Say(GetString(player, "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE"), nil, true)
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
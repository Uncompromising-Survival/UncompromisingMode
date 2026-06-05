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

local function UMBlueprints(product)
	if product == "archive_resonator_item" or product == "archive_resonator" then
		return { "um_astral_projector_blueprint" }
	elseif product == "refined_dust" then
		return { "um_astral_projector_target_blueprint" }
	else
		return { "um_scrapper_blueprint" }
	end
end

local function Giveknowledge(inst)
	local pos = Vector3(inst.Transform:GetWorldPosition())
	local players = FindPlayersInRange(pos.x, pos.y, pos.z, 20, true)
	local blueprints = UMBlueprints(inst.product_orchestrina)

	for _, player in ipairs(players) do
		if player.components.builder ~= nil and player.components.inventory ~= nil then
			local they_know = false

			for _, blueprint_prefab in ipairs(blueprints) do
				local recipe = string.gsub(blueprint_prefab, "_blueprint$", "")

				if not player.components.builder:KnowsRecipe(recipe) then
					local loot = SpawnPrefab(blueprint_prefab)

					if loot ~= nil then
						they_know = true
						player.components.inventory:GiveItem(loot, nil, pos)
					end
				end
			end

			local fx = SpawnPrefab("archive_lockbox_player_fx")
			if fx ~= nil then
				player:AddChild(fx)
			end

			if player.components.talker ~= nil then
				player.components.talker:Say(GetString(player, they_know and "ANNOUNCE_ARCHIVE_NEW_KNOWLEDGE" or "ANNOUNCE_ARCHIVE_OLD_KNOWLEDGE" ), nil, true)
			end
		end
	end
end

env.AddPrefabPostInit("archive_lockbox", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:ListenForEvent("onteach", function(inst)
		inst:DoTaskInTime(174 / 30, function()
			if inst ~= nil and inst:IsValid() then
				Giveknowledge(inst)
			end
		end)
	end)
end)

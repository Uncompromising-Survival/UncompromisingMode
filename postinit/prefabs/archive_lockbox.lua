local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function teach(inst)
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
end

env.AddPrefabPostInit("archive_lockbox", function(inst)
    if not TheWorld.ismastersim then
        return
    end
	
	if inst.teach ~= nil then
		inst._Old_teach = inst.teach
		inst.teach = teach
	end
end)

local env = env
GLOBAL.setfenv(1, GLOBAL)

-----------------------------------------------------------------
-- Krampii will knock the items out of players
-----------------------------------------------------------------

local function OnHitOther(inst, data)
    if data.target ~= nil then
        inst.components.thief:StealItem(data.target)
    end
end

local function CheckLeaving(inst, data)
	if data.statename ~= nil and data.statename == "exit" then
		if not inst.components.health:IsDead() then
			local klaus_sack = TheSim:FindFirstEntityWithTag("klaussacklock")
			local current_middleman = TheSim:FindFirstEntityWithTag("krampus_middleman")
			
			if klaus_sack ~= nil and klaus_sack.components.inventory ~= nil then
				inst.components.inventory:TransferInventory(klaus_sack)
			elseif current_middleman ~= nil then
				inst.components.inventory:TransferInventory(current_middleman)
			else
				local middleman = SpawnPrefab("krampus_middleman_inventory")
				middleman.Transform:SetPosition(inst.Transform:GetWorldPosition())
				inst.components.inventory:TransferInventory(middleman)
			end
		end
	end
end

env.AddPrefabPostInit("krampus", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    inst:AddComponent("thief")
	
    inst:ListenForEvent("onhitother", OnHitOther)
	inst:ListenForEvent("newstate", CheckLeaving)
end)
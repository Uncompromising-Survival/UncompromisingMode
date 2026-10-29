local env = env
GLOBAL.setfenv(1, GLOBAL)


env.AddPrefabPostInit("resurrectionstone", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	local function OnActivateResurrection(inst, guy)
		if math.random() < .69 and TUNING.DSTU.DATES.APRIL_FOOLS then
            SpawnPrefab("balloonparty_confetti_cloud").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
	end

	inst:ListenForEvent("activateresurrection", OnActivateResurrection) -- Add New max health recovery, this is not a penalty, you get your max health back via using touch stones (net zero)
end)
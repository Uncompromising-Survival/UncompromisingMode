local env = env
GLOBAL.setfenv(1, GLOBAL)

-- Chalky Bones interaction

local function OnGetItemFromPlayer(inst, giver, item)
	local id = inst:GetTouchStoneID()
	table.remove(giver.components.touchstonetracker.used,id)
	item:Remove()
	inst.SoundEmitter:PlaySound("dontstarve/common/together/draw")

	local x,y,z = inst.Transform:GetWorldPosition()
	SpawnPrefab("small_puff").Transform:SetPosition(x+math.random(1,2),y,z)
	SpawnPrefab("small_puff").Transform:SetPosition(x,y,z+math.random(1,2))
	SpawnPrefab("small_puff").Transform:SetPosition(x-math.random(1,2),y,z)
end

local function OnRefuseItem(inst, giver, item)
	-- Cannot
end

local function GiverHasUsedMe(inst,giver)
	return not giver:CanUseTouchStone(inst)
end

local function AcceptTest(inst, item, giver)
    return item.prefab == "um_rubbleloot_bones" and GiverHasUsedMe(inst,giver)
end

env.AddPrefabPostInit("resurrectionstone", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	local function OnActivateResurrection(inst, guy)
		if guy.components.health then
			guy.components.health:DeltaPenalty(-0.25)
		end
		if math.random() < 0.69 and TUNING.DSTU.DATES.APRIL_FOOLS then
            SpawnPrefab("balloonparty_confetti_cloud").Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
	end
	inst:ListenForEvent("activateresurrection", OnActivateResurrection) -- Add New max health recovery, this is not a penalty, you get your max health back via using touch stones (net zero)


	inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AcceptTest)
    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

end)
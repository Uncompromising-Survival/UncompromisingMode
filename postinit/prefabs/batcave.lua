local env = env
GLOBAL.setfenv(1, GLOBAL)

SetSharedLootTable('um_batcave',
{
    {'rocks',       1.00},
    {'guano',       1.00},
    {'guano',        1.00},
    {'fossil_piece',1.00},
    {'nitre', 0.25},
    {'rocks',        0.50},
})

local function spawner_onworked(inst, worker, workleft)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren(worker)
    end
end

local function rock_onworked(inst, worker, workleft)
    if workleft <= 0 then
        local pos = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
        inst.components.lootdropper:DropLoot(pos)
        inst:Remove()
    end
end

env.AddPrefabPostInit("batcave", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	if inst.components.childspawner and TUNING.DSTU.ADULTBATILISKS then
		inst.components.childspawner.childname = "vampirebat"
	elseif inst.components.childspawner then
		inst.components.childspawner.childname = "bat"
	end
	
	-- inst:AddComponent("workable")
    -- inst.components.workable:SetWorkAction(ACTIONS.MINE)
    -- inst.components.workable:SetWorkLeft(12)
    -- inst.components.workable:SetOnWorkCallback(spawner_onworked)
    -- inst.components.workable:SetOnFinishCallback(rock_onworked)
	
	-- inst:AddComponent("lootdropper")
	-- inst.components.lootdropper:SetChanceLootTable('um_batcave')
end)



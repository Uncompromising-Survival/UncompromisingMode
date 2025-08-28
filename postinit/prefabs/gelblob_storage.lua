local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

env.AddPrefabPostInit("gelblob_storage", function(inst)
	if not TheWorld.ismastersim then
		return
	end

    local oldonfoodgiven = inst.components.inventoryitemholder.onitemgivenfn
    inst.components.inventoryitemholder:SetOnItemGivenFn(function(inst, item, giver)
        oldonfoodgiven(inst,item,giver)
        item:AddTag("NORATCHECK")
    end)

    local oldonfoodtaken = inst.components.inventoryitemholder.onitemtakenfn
    inst.components.inventoryitemholder:SetOnItemTakenFn(function(inst, item, taker, wholestack)
        oldonfoodtaken(inst, item, taker, wholestack)
        if not item:HasTag("donotautopick") then -- This is a powedercake tag. Powercake should not lose ratcheck tag
            item:RemoveTag("NORATCHECK")
        end
    end)
end)

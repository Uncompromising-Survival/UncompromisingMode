local env = env
GLOBAL.setfenv(1, GLOBAL)

-- Leaving this here for clarity
TUNING.SEEDPOUCH_PRESERVER_RATE = 0

local function OnUpgrade(inst, performer, upgraded_from_item)
    local numupgrades = inst.components.upgradeable.numupgrades
    if numupgrades == 1 then
        --inst._chestupgrade_stacksize = true
        if inst.components.container ~= nil then -- NOTES(JBK): The container component goes away in the burnt load but we still want to apply builds.
            --inst.components.container:Close()
            inst.components.container:EnableInfiniteStackSize(true)
            --inst.components.inspectable.getstatus = regular_getstatus
        end
        if upgraded_from_item then
            -- Spawn FX from an item upgrade not from loads.
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("chestupgrade_stacksize_fx")
            fx.Transform:SetPosition(x, y, z)
        end
    end
    inst.components.upgradeable.upgradetype = nil
end


local function OnLoad(inst, data, newents)
    if inst.components.upgradeable and inst.components.upgradeable.numupgrades > 0 then
        OnUpgrade(inst)
    end
end

--[[local function regular_ShouldCollapse(inst)
	if inst.components.container and inst.components.container.infinitestacksize then
		--NOTE: should already have called DropEverything(nil, true) (worked or burnt or deconstructed)
		--      so everything remaining counts as an "overstack"
		local overstacks = 0
		for k, v in pairs(inst.components.container.slots) do
			local stackable = v.components.stackable
			if stackable then
				overstacks = overstacks + math.ceil(stackable:StackSize() / (stackable.originalmaxsize or stackable.maxsize))
				if overstacks >= TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD then
					return true
				end
			end
		end
	end
	return false
end]]

local function OnDecontructStructure(inst, caster)
    if inst.components.upgradeable and inst.components.upgradeable.numupgrades > 0 then
        if inst.components.lootdropper then
            inst.components.lootdropper:SpawnLootPrefab("alterguardianhatshard")
        end
    end

	--[[if regular_ShouldCollapse(inst) then
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)
		if not inst.components.container:IsEmpty() then
			regular_ConvertToCollapsed(inst, false, false)
			inst.no_delete_on_deconstruct = true
			return
		end
	elseif inst.components.container ~= nil then
        --If not burnt, we might still have some overstacks, just not enough to "collapse"
        inst.components.container:DropEverything()
	end

	--fallback to default
	inst.no_delete_on_deconstruct = nil]]
end

env.AddPrefabPostInit("seedpouch", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local upgradeable = inst:AddComponent("upgradeable")
    upgradeable.upgradetype = UPGRADETYPES.CHEST
    upgradeable:SetOnUpgradeFn(OnUpgrade)

    inst:AddComponent("lootdropper")

    inst:ListenForEvent("ondeconstructstructure", OnDecontructStructure)

    inst.OnLoad = OnLoad
end)
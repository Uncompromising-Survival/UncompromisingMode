require "prefabutil" -- for the MakePlacer function

local assets = {
	Asset("ANIM", "anim/um_poofshrooms.zip"),
}

local function FxAppear(inst)
	SpawnPrefab("blueberryexplosion").Transform:SetPosition(inst.Transform:GetWorldPosition())
	SpawnPrefab("blueberrypuddle").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:AddTag("plant")
end

local mine_test_tags = { "monster", "character", "animal" }
local mine_must_tags = { "_combat" }
local mine_no_tags = { "notraptrigger", "flying", "ghost", "playerghost", "plantkin" }

local function on_deactivate(inst)
    -- if inst.components.lootdropper ~= nil then
        -- if inst.harvestable == "full" then
            -- if math.random() > 0.1 then
    inst.components.lootdropper:SpawnLootPrefab("giant_blueberry")
				-- local x, y, z = inst.Transform:GetWorldPosition()
				-- local otherbombs = TheSim:FindEntities(x, y, z, 1.1*TUNING.STARFISH_TRAP_RADIUS, {"blueberrybomb"}, mine_no_tags)
				-- for i, target in ipairs(otherbombs) do
					-- if target ~= inst and target.components.mine and not target.components.mine.issprung and not target.froze then
						-- target.components.mine:Explode(target)
					-- end
				-- end				
            -- else
                -- local berryman = SpawnPrefab("fruitbat")
                -- berryman.Transform:SetPosition(inst.Transform:GetWorldPosition())
            -- end
        -- end    
    -- end
    if inst.harvestable == "regrow" then
        inst:Remove()
    else
        inst.components.workable:SetWorkLeft(1)
        inst.harvestable = "regrow"
    end
end

local function OnPickedFn(inst,picker)
	if not inst.components.mine.issprung then
		inst.components.mine:Explode()
	end
	
	on_deactivate(inst)
	inst.AnimState:PlayAnimation("dig")
	inst.AnimState:PushAnimation("spawn")
	inst.AnimState:PushAnimation("trap_idle")
	inst.components.workable:SetWorkable(true)
end

local function on_blueberry_dug_up(inst, digger)
	if digger:HasTag("player") then
		if inst.harvestable == "full" then
			if not inst.components.mine.issprung then
				inst.components.mine:Explode()
			end
			
			on_deactivate(inst)
			inst.AnimState:PlayAnimation("dig")
			inst.AnimState:PushAnimation("spawn")
			inst.AnimState:PushAnimation("trap_idle")
			inst.components.workable:SetWorkable(false)
			inst:AddTag("plant")
			inst:DoTaskInTime(5, function(inst)
				inst.components.workable:SetWorkable(true)
			end)
		else
			inst:Remove()
		end
	else
		inst.components.workable:SetWorkLeft(1)
	end
end

local function MakeNotWinter(inst)
	inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*1.1)
	inst:RemoveComponent("workable")
	inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(on_blueberry_dug_up)
    inst.components.workable:SetWorkable(true)
end

local function Melt(inst)
	MakeNotWinter(inst)
	inst.AnimState:PlayAnimation("melt")
	inst.AnimState:PushAnimation("idle"..math.random(1,4))
end

local function on_anim_over(inst)
    if inst.components.mine.issprung then
        return
    end
	if inst.froze then
		if inst.harvestable == "full" and TheWorld.state.iswinter then
			inst.AnimState:PushAnimation("idle_frozen", true)
			elseif not TheWorld.state.iswinter  then
			inst.froze = false
			Melt(inst)
		else
			inst.AnimState:PushAnimation("trap_idle", true)
		end
	elseif not TheWorld.state.iswinter then
		inst.AnimState:PushAnimation("idle"..math.random(1,4))
	end
end

-- Copied from mine.lua to emulate its mine test.
local mine_test_fn = function(target, inst)
    return not (target.components.health ~= nil and target.components.health:IsDead())
            and (target.components.combat ~= nil and target.components.combat:CanBeAttacked(inst))
end

local function do_snap(inst)
	if inst.harvestable == "full" then
		inst.AnimState:PushAnimation("spawn")
		inst.AnimState:PushAnimation("trap_idle", true)
		inst.SoundEmitter:PlaySound("wintersfeast2019/creatures/gingerbread_vargr/splat", nil, 2)
		inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/trap")

		FxAppear(inst)
		-- Do an AOE attack, based on how the combat component does it.
		local x, y, z = inst.Transform:GetWorldPosition()
		local target_ents = TheSim:FindEntities(x, y, z, 1.1*TUNING.STARFISH_TRAP_RADIUS, mine_must_tags, mine_no_tags, mine_test_tags)
		for i, target in ipairs(target_ents) do
			if target ~= inst and target.entity:IsVisible() and mine_test_fn(target, inst) then
				target.components.combat:GetAttacked(inst, TUNING.STARFISH_TRAP_DAMAGE)
			end
		end
		local otherbombs = TheSim:FindEntities(x, y, z, 3*TUNING.STARFISH_TRAP_RADIUS, {"blueberrybomb"}, mine_no_tags)
		for i, target in ipairs(otherbombs) do
			if target ~= inst and target.components.mine and not target.components.mine.issprung and not target.froze then
                    target.components.mine:Explode(target)
			end
		end
		inst.harvestable = "regrow"
	end
    if inst._snap_task ~= nil then
        inst._snap_task:Cancel()
        inst._snap_task = nil
    end
end

local function Regrow(inst)
	inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*1.1)
    inst.components.mine:Reset()
	inst.harvestable = "full"
	inst:RemoveTag("plant")
end

local function CheckTimeRegrow(inst)
	if TheWorld.state.iswinter then
		inst.pendingregrow = true
	else
		Regrow(inst)
	end
end

local function start_reset_task(inst)
	inst.components.timer:StartTimer("regrow", 3840)
end

local function on_explode(inst, target)
    inst.AnimState:PlayAnimation("trap")
	inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*1.1) --Gotta Reset
    inst:RemoveEventCallback("animover", on_anim_over)
    if --[[target ~= nil and]] inst._snap_task == nil then
        local frames_until_anim_snap = 40
        inst._snap_task = inst:DoTaskInTime(frames_until_anim_snap * FRAMES, do_snap)
    end
    start_reset_task(inst)
end

local function on_reset(inst)
    inst:ListenForEvent("animover", on_anim_over)
    inst.AnimState:PlayAnimation("reset")
    inst.SoundEmitter:PlaySound("turnoftides/creatures/together/starfishtrap/idle")
    inst.AnimState:PushAnimation("idle"..math.random(1,4), true)
end

local function on_sprung(inst)
    inst.AnimState:PlayAnimation("trap_idle", true)
	inst.AnimState:PushAnimation("trap_idle", true)
    inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())
    inst:RemoveEventCallback("animover", on_anim_over)
	inst:AddTag("plant")
    start_reset_task(inst)
end

local function get_status(inst)
    return (inst.components.mine.issprung and "REGROWING") or (inst.froze and "FROZE") or "READY"
end

local function calculate_mine_test_time()
    return TUNING.STARFISH_TRAP_TIMING.BASE + (math.random() * TUNING.STARFISH_TRAP_TIMING.VARIANCE) --This will be the "regrow" period of the blueberry, will extend it to be much longer.
end

local function on_save(inst, data)
    if inst._reset_task ~= nil then
        local remaining_task_time = inst._reset_task_end_time - GetTime()
        if remaining_task_time >= 0 then
            data.reset_task_time_remaining = remaining_task_time
        end
    end
	data.froze = inst.froze
	data.harvestable = inst.harvestable
	data.pendingregrow = inst.pendingregrow
end

local function on_blueberry_mine(inst)
	inst.components.lootdropper:SpawnLootPrefab("ice")
	local x,y,z = inst.Transform:GetWorldPosition()
	local players = TheSim:FindEntities(x,y,z,1.5,{"player"},{"ghost"})
	for i, v in ipairs(players) do
		if v.components.moisture ~= nil then
			v.components.moisture:DoDelta(5)
		end
	end
	inst.harvestable = "regrow"
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(on_blueberry_dug_up)
	start_reset_task(inst)
	FxAppear(inst)
	inst.AnimState:PlayAnimation("mine")
	inst.AnimState:PushAnimation("spawn")
	inst.AnimState:PushAnimation("trap_idle")
end

local function MakeWinter(inst)
	inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*0)
	if inst.harvestable == "full" then
		inst.components.workable:SetWorkAction(ACTIONS.MINE)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(on_blueberry_mine)
		inst.components.workable:SetWorkable(true)
	else
		inst.components.workable:SetWorkAction(ACTIONS.DIG)
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetOnFinishCallback(on_blueberry_dug_up)
		inst.components.workable:SetWorkable(true)
		inst:AddTag("plant")
	end
end

local function on_load(inst, data)
    if data then
		if data.harvestable then
			inst.harvestable = data.harvestable
		end
		if data.reset_task_time_remaining then
			if inst._reset_task then
				inst._reset_task:Cancel()
			end
			inst._reset_task = inst:DoTaskInTime(data.reset_task_time_remaining, reset)
			inst._reset_task_end_time = GetTime() + data.reset_task_time_remaining
		end
		if data.pendingregrow then
			inst.pendingregrow = data.pendingregrow
		end
    end
	if TheWorld.state.iswinter then
		inst.froze = true
		MakeWinter(inst)
	else
		inst.froze = false
		MakeNotWinter(inst)
	end
end



local function OnSpring(inst)
	if inst.pendingregrow or (inst.harvestable == "regrow" and not inst.components.timer:TimerExists("regrow"))then
		Regrow(inst)
	end
	if inst.harvestable == "full" and inst.froze then
		inst:RemoveEventCallback("animover",on_anim_over)
		inst:DoTaskInTime(3+math.random(0,15), function(inst) 
			Melt(inst)
			inst:ListenForEvent("animover", on_anim_over)
		end)
	end
	inst.froze = false
end

local function Freeze(inst)
	if TheWorld.state.iswinter then
		MakeWinter(inst)
		if inst.harvestable == "full" then
			inst.AnimState:PlayAnimation("freeze")
			inst.froze = true
		end
	else
		inst.froze = false
	end
end

local function OnWinter(inst)
	if inst.froze ~= true then
		inst:DoTaskInTime(3+math.random(0,15), Freeze)
	end
end

local function master()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()



    inst:AddTag("trap")
    inst:AddTag("trapdamage")
    inst:AddTag("birdblocker")
	if inst.harvestable == "regrow" then
		inst:AddTag("plant") --Wormwood will lose sanity collecting them otherwise...
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end



    inst:AddComponent("lootdropper")

	

    inst:AddComponent("mine")
    inst.components.mine:SetRadius(TUNING.STARFISH_TRAP_RADIUS*1.1)
    inst.components.mine:SetAlignment("plantkin") -- blueberries trigger on EVERYTHING on the ground, players and non-players alike.
    inst.components.mine:SetOnExplodeFn(on_explode)
    inst.components.mine:SetOnResetFn(on_reset)
    inst.components.mine:SetOnSprungFn(on_sprung)
    inst.components.mine:SetOnDeactivateFn(on_deactivate)
    inst.components.mine:SetTestTimeFn(calculate_mine_test_time)
    inst.components.mine:SetReusable(false)
	
    return inst
end

local function poofredmaster()
	
end

return Prefab("um_poofshroom_red_master", poofredmaster,assets)
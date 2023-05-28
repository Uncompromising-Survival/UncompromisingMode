require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/nightmare_torch.zip"),
}

local prefabs =
{
	"collapse_small",
	"nightlight_flame",
}

local function Advance_Full(inst)
	if inst.Advance_Task ~= nil then
		inst.Advance_Task:Cancel()
	end
	inst.Advance_Task = nil

	inst.startmoving = true

	inst.AnimState:PlayAnimation("tornado_loop", true)
end

local function Init(inst)
	inst.SoundEmitter:PlaySound("UCSounds/um_tornado/um_tornado_loop", "spinLoop")

	if not inst.is_full then
		TheWorld:PushEvent("ms_forceprecipitation", true)
		inst.AnimState:PlayAnimation("tornado_pre")

		inst.Advance_Task = inst:ListenForEvent("animover", Advance_Full)

		SendModRPCToClient(GetClientModRPC("UncompromisingSurvival", "ToggleLagCompOn"), nil)
		inst.is_full = true
	else
		Advance_Full(inst)
	end
end

local function teleport_end(teleportee, locpos, inst)
	if teleportee.components.inventory ~= nil and teleportee.components.inventory:IsHeavyLifting() then
		teleportee.components.inventory:DropItem(
			teleportee.components.inventory:Unequip(EQUIPSLOTS.BODY),
			true,
			true
		)
	end

	if teleportee:HasTag("player") then
		teleportee:ShowHUD(true)
		teleportee.sg.statemem.teleport_task = nil
		teleportee.sg:GoToState(teleportee:HasTag("playerghost") and "appear" or "um_tornado_wakeup")
	else
		teleportee:Show()
		if teleportee.DynamicShadow ~= nil then
			teleportee.DynamicShadow:Enable(true)
		end
		if teleportee.components.health ~= nil then
			teleportee.components.health:SetInvincible(false)
		end
		teleportee:PushEvent("teleported")
	end
end

local function getrandomposition(caster)
	local centers = {}

	for i, node in ipairs(TheWorld.topology.nodes) do
		--local antimoonnode = TheWorld.Map:FindNodeAtPoint(node.x, 0, node.z)

		if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y) and node.type ~= NODE_TYPE.SeparatedRoom and not (node ~= nil and node.tags ~= nil and (table.contains(node.tags, "lunacyarea") or table.contains(node.tags, "not_mainland"))) then
			table.insert(centers, { x = node.x, z = node.y })
		end
	end
	if #centers > 0 then
		local pos = centers[math.random(#centers)]
		return Point(pos.x, 0, pos.z)
	else
		return caster:GetPosition()
	end
end

local function teleport_continue(teleportee, locpos, inst)
	local ground = TheWorld
	if teleportee.Physics ~= nil then
		teleportee.Physics:Teleport(locpos.x, 0, locpos.z)
	else
		teleportee.Transform:SetPosition(locpos.x, 0, locpos.z)
	end

	if teleportee:HasTag("player") then
		teleportee:SnapCamera()
		teleportee:ScreenFade(true, 2)
		teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(3,
			function() teleport_end(teleportee, locpos, inst) end)
	else
		teleport_end(teleportee, locpos, inst)
	end
end

local function TornadoTask(inst)
	if inst.startmoving then
		local x, y, z = inst.Transform:GetWorldPosition()

		if not TheWorld.state.israining then
			TheWorld:PushEvent("ms_forceprecipitation", true)
			--TheWorld:PushEvent("ms_deltamoistureceil", 15)
		end

		local destination = TheSim:FindFirstEntityWithTag("um_tornado_destination")

		if math.random() > 0.8 then
			SpawnPrefab("hound_lightning").Transform:SetPosition(x + math.random(-300, 300), 0,
				z + math.random(-300, 300))
		end

		if math.random() >= 0.9 then
			if #inst.components.inventory.itemslots ~= 0 then
				local random_item = inst.components.inventory:RemoveItem(inst.components.inventory
					.itemslots[math.random(#inst.components.inventory
						.itemslots)])
				if random_item ~= nil then
					random_item:AddTag("tornado_nosucky")
					random_item:DoTaskInTime(8, function(inst) inst:RemoveTag("tornado_nosucky") end)
					Launch2(random_item, inst, 24, 1, math.random(4, 8), 2, math.random(8, 32), math.random(360))
				end
			end
		end

		local players = TheSim:FindEntities(x, y, z, 200, nil, { "playerghost" },
			{ "player", "_inventoryitem", "oceanfishable" })

		for i, v in ipairs(players) do
			local px, py, pz = v.Transform:GetWorldPosition()

			if v:HasTag("player") then
				v:AddTag("under_the_weather")

				if v.um_tornado_weathertask ~= nil then
					v.um_tornado_weathertask:Cancel()
					v.um_tornado_weathertask = nil
				end

				v.um_tornado_weathertask = v:DoTaskInTime(1, function()
					v:RemoveTag("under_the_weather")

					v.um_tornado_weathertask = nil
				end)

				if math.random() > 0.99 then
					SpawnPrefab("hound_lightning").Transform:SetPosition(px + math.random(-5, 5), 0,
						pz + math.random(-5, 5))
				end
			end



			if v ~= nil and v:IsValid() and v:HasTag("player") and v.sg ~= nil and not v.sg:HasStateTag("gotgrabbed") and v:GetDistanceSqToInst(inst) < 300 or
				v.prefab ~= "bullkelp_beachedroot" and v.components.inventoryitem ~= nil and not v:HasTag("INLIMBO") and v:GetDistanceSqToInst(inst) < 600 and not v:HasTag("tornado_nosucky") and GetClosestInstWithTag("player", inst, PLAYER_CAMERA_SEE_DISTANCE) ~= nil or
				v.components.oceanfishable ~= nil and not v:HasTag("INLIMBO") then
				local rad = math.rad(v:GetAngleToPoint(x, y, z))
				local velx = math.cos(rad)
				local velz = -math.sin(rad)

				local multiplierplayer = inst:GetDistanceSqToPoint(px, py, pz)

				multiplierplayer = multiplierplayer / 60

				if multiplierplayer < .4 then
					multiplierplayer = .4

					if v.components.health ~= nil and not v.components.health:IsDead() and v.sg ~= nil and not v.sg:HasStateTag("nointerrupt") and not v.components.health:IsInvincible() and v:HasTag("player") then
						local locpos = getrandomposition(v)
						v.sg:GoToState("um_tornado_teleport")
						v.sg.statemem.teleport_task = v:DoTaskInTime(3, function() teleport_continue(v, locpos, inst) end)
					end
				end

				local dx, dy, dz = px + (((FRAMES * 5) * velx) / multiplierplayer) * inst.Transform:GetScale(), 0,
					pz + (((FRAMES * 5) * velz) / multiplierplayer) * inst.Transform:GetScale()

				local ground = TheWorld.Map:IsOceanTileAtPoint(dx, dy, dz) --changed to IsOceanTile for better ocean support, don't want tornado scuking things into the void.
				local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
				local p_ground = TheWorld.Map:IsOceanTileAtPoint(px, py, pz)
				local p_boat = TheWorld.Map:GetPlatformAtPoint(px, pz)

				if dx ~= nil and (ground == p_ground or boat) then
					v.Transform:SetPosition(dx, dy, dz)
				end
			end
		end
		--minor boost so it doesn't just start doing stuff visually on-screen.
		if GetClosestInstWithTag("player", inst, PLAYER_CAMERA_SEE_DISTANCE * 1.125) == nil then --tornado doesn't sleep. Using alt distance-based check.
			local tornado_workables = TheSim:FindEntities(x, y, z, 4, nil, { "INLIMBO" },
				{ "DIG_workable", "CHOP_workable" })

			for k, v in ipairs(tornado_workables) do
				if v.components.workable ~= nil and v.components.pickable == nil then
					if v.components.workable.action == ACTIONS.DIG then
						local fx = SpawnPrefab("shovel_dirt")
						local x1, y1, z1 = v.Transform:GetWorldPosition()
						fx.Transform:SetPosition(x1, y1, z1)
					end
					v.components.workable:Destroy(inst)
				end
			end

			local tornado_pickables = TheSim:FindEntities(x, y, z, 16, nil, { "INLIMBO", "burning", "tornado_nosucky" },
				{ "pickable", "_inventoryitem", "oceanfishable" })
			for k, v in ipairs(tornado_pickables) do
				if v.components.pickable ~= nil then --you never know...
					if v:GetDistanceSqToInst(inst) < 16 then
						v.components.pickable:Pick(inst)
					else
						v.components.pickable:Pick(TheWorld)
					end
				elseif v.components.inventoryitem ~= nil and v:GetDistanceSqToInst(inst) < 16 and v:IsValid() and not v:HasTag("INLIMBO") and v.prefab ~= "bullkelp_beachedroot" then
					inst.components.inventory:GiveItem(v)
					local stacksize = v.components.stackable ~= nil and v.components.stackable:StackSize() or
						1

					if v.components.health ~= nil then
						-- NOTES(JBK): Push the events before spawning any giving any loot.
						v:PushEvent("murdered", { victim = v, stackmult = stacksize })
						v:PushEvent("killed", { victim = v, stackmult = stacksize })

						if v.components.lootdropper ~= nil then
							v.causeofdeath = inst
							for i = 1, stacksize do
								local loots = v.components.lootdropper:GenerateLoot()
								for k, _loot in pairs(loots) do
									local loot = SpawnPrefab(_loot)
									if loot ~= nil then
										inst.components.inventory:GiveItem(loot)
									end
								end
							end
						end


						if v ~= nil and v.components.inventory and v:HasTag("drop_inventory_onmurder") then
							v.components.inventory:TransferInventory(inst)
						end

						v:Remove()
					end
				elseif v.components.oceanfishable ~= nil and v:GetDistanceSqToInst(inst) < 16 and v:IsValid() and not v:HasTag("INLIMBO") then
					local fishdef = v.fish_def ~= nil and v.fish_def.prefab ~= nil and v.fish_def.prefab or nil
					local fish = fishdef ~= nil and SpawnPrefab(fishdef .. "_inv") or nil

					if fish == nil then
						fish = fishdef ~= nil and SpawnPrefab(fishdef .. "_land") or nil
					end

					if fish ~= nil then
						inst.components.inventory:GiveItem(fish)
						v:Remove()
					end
				end
			end
		end



		if destination ~= nil then
			local x_dest, y_dest, z_dest = destination.Transform:GetWorldPosition()
			local dest_rad = math.rad(inst:GetAngleToPoint(x_dest, y_dest, z_dest))
			local dest_velx = math.cos(dest_rad)
			local dest_velz = -math.sin(dest_rad)

			local x_dest2, y_dest2, z_dest2 = x + ((FRAMES * 3) * dest_velx), 0, z + ((FRAMES * 3) * dest_velz)

			if x_dest2 ~= nil then
				inst.Transform:SetPosition(x_dest2, y_dest2, z_dest2)
			end

			if inst.persists and destination:IsValid() and inst:GetDistanceSqToInst(destination) < 50 --[[or not (TheWorld.Map:IsPassableAtPoint(x, 0, z) or TheWorld.Map:IsOceanAtPoint(x, 0, z)))]] then
				inst.AnimState:PlayAnimation("tornado_pst", false)

				inst:ListenForEvent("animover", function()
					inst.startmoving = false

					destination:Remove()
					inst:Remove()
				end)

				inst.persists = false
				destination.persists = false
			end
		elseif inst.persists then
			inst.AnimState:PlayAnimation("tornado_pst", false)

			inst:ListenForEvent("animover", function()
				inst.startmoving = false

				inst:Remove()
			end)

			inst.persists = false
		end

		if inst.whirlpool == nil and TheWorld.Map:IsOceanAtPoint(inst.Transform:GetWorldPosition()) then
			inst.whirlpool = SpawnPrefab("um_whirlpool")
			inst.whirlpool.entity:SetParent(inst.entity)
			inst.whirlpool.Transform:SetPosition(0, 0, 0)
			inst.whirlpool.Transform:SetScale(2, 2, 2)
		elseif inst.whirlpool ~= nil and not TheWorld.Map:IsOceanAtPoint(inst.Transform:GetWorldPosition()) then
			inst.whirlpool.components.timer:StartTimer("kill_whirlpool", 1)
			inst.whirlpool = nil
		end
	end
end

local function OnSave(inst, data)
	data.is_full = inst.is_full
end

local function OnLoad(inst, data)
	if data ~= nil then
		inst.is_full = data.is_full
	end
end

local function fn()
	local inst = CreateEntity()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")
	inst:AddTag("scarytoprey")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("tornado_weather")
	inst.AnimState:SetBuild("tornado_weather")

	inst:AddTag("um_tornado")

	inst.AnimState:SetMultColour(1, 1, 1, .8)
	inst.Transform:SetScale(1.5, 1.5, 1.5)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.Advance_Task = nil
	inst.is_full = false

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	--inst:DoPeriodicTask(FRAMES, TornadoTask)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(TornadoTask)

	inst:AddComponent("inventory")
	inst.components.inventory.ignorescangoincontainer = true
	inst.components.inventory.maxslots = 100
	inst:DoTaskInTime(0, Init)

	return inst
end

local function CaveTornadoTask(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local destination = TheSim:FindFirstEntityWithTag("um_tornado_destination")

	if math.random() > 0.96 then
		SpawnPrefab("cavein_debris").Transform:SetPosition(x, 0, z)
	end

	if destination ~= nil then
		local x_dest, y_dest, z_dest = destination.Transform:GetWorldPosition()
		local dest_rad = math.rad(inst:GetAngleToPoint(x_dest, y_dest, z_dest))
		local dest_velx = math.cos(dest_rad)
		local dest_velz = -math.sin(dest_rad)

		local x_dest2, y_dest2, z_dest2 = x + ((FRAMES * 3) * dest_velx), 0, z + ((FRAMES * 3) * dest_velz)

		if x_dest2 ~= nil then
			inst.Transform:SetPosition(x_dest2, y_dest2, z_dest2)
		end

		if destination:IsValid() and inst:GetDistanceSqToInst(destination) < 50 then
			destination:Remove()
			inst:Remove()
		end
	else
		inst:Remove()
	end
end

local function CanSpawnWaterfall(inst, x, y, z)
	local is_valid_tile = true

	if x ~= nil then
		local ents = TheSim:FindEntities(x, y, z, 40, { "um_waterfall" })

		if ents ~= nil and #ents > 0 then
			is_valid_tile = false
		end

		local offs =
		{
			{ -2, -2 }, { -1, -2 }, { 0, -2 }, { 1, -2 }, { 2, -2 },
			{ -2, -1 }, { 2, -1 },
			{ -2, 0 }, { 2, 0 },
			{ -2, 1 }, { 2, 1 },
			{ -2, 2 }, { -1, 2 }, { 0, 2 }, { 1, 2 }, { 2, 2 },
			{ -2, -2 }, { -2, -3 }, { 0, -3 }, { 2, -3 }, { 3, -3 },
			{ -3, -2 }, { 3, -2 },
			{ -3, 0 }, { 3, 0 },
			{ -3, 1 }, { 3, 2 },
			{ -3, 3 }, { -2, 3 }, { 0, 3 }, { 2, 3 }, { 3, 3 }
		}

		for i = 1, #offs, 1 do
			local curoff = offs[i]
			local offx, offz = curoff[1], curoff[2]

			if not TheWorld.Map:IsPassableAtPoint(x + offx, y, z + offz) then
				is_valid_tile = false
			end
		end
	else
		is_valid_tile = false
	end

	return is_valid_tile
end

local function TrySpawnWaterfall(inst, x, z)
	local x, y, z = inst.Transform:GetWorldPosition()

	x = x + math.random(-15, 15)
	z = z + math.random(-15, 15)

	if CanSpawnWaterfall(inst, x, y, z) then
		SpawnPrefab("um_waterfall_spawner").Transform:SetPosition(x, y, z)
	end
end

local function cavefn()
	local inst = CreateEntity()

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(CaveTornadoTask)

	inst:DoPeriodicTask(5, TrySpawnWaterfall)

	return inst
end

local function destfn()
	local inst = CreateEntity()

	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")
	inst:AddTag("um_tornado_destination")

	inst.entity:SetCanSleep(false)

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	return inst
end

return Prefab("um_tornado", fn, assets, prefabs),
	Prefab("um_cavetornado", cavefn, assets, prefabs),
	Prefab("um_tornado_destination", destfn, assets, prefabs)

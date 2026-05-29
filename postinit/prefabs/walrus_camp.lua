local env = env
GLOBAL.setfenv(1, GLOBAL)

local DESPAWN_RADIUS = 35
local WALRUS_MUST = { "walrus" }

local USED_NAMES = {}

local function ReleaseName(inst)
	if inst and inst.Name then
		USED_NAMES[inst.Name] = nil
		inst.Name = nil
	end
end

local function GetUniqueName()
	local names = STRINGS.NAMES.UM_VARGLET_PET_NAMES

	if not names or #names <= 0 then
		return nil
	end

	local available = {}

	for _, name in ipairs(names) do
		if not USED_NAMES[name] then
			table.insert(available, name)
		end
	end

	if #available <= 0 then
		return names[math.random(#names)]
	end

	local chosen = available[math.random(#available)]
	USED_NAMES[chosen] = true

	return chosen
end

local function NameTheDog(inst)
	if not (inst and inst:IsValid()) then
		return
	end

	if inst.Name then
		return
	end

	local name = GetUniqueName()
	if not name then
		return
	end

	if inst.components.named == nil then
		inst:AddComponent("named")
	end

	inst.Name = name
	inst.components.named:SetName(name)

	inst:ListenForEvent("onremove", function()
		ReleaseName(inst)
	end)
end

local function SaveName(inst, data)
	if inst.Name then
		data.WalrusHoundName = inst.Name
	end
end

local function LoadName(inst, data)
	if data and data.WalrusHoundName then
		if inst.components.named == nil then
			inst:AddComponent("named")
		end

		inst.Name = data.WalrusHoundName
		USED_NAMES[inst.Name] = true
		inst.components.named:SetName(inst.Name)

		inst:ListenForEvent("onremove", function()
			ReleaseName(inst)
		end)
	end
end

local function AddSavedName(prefab)
	env.AddPrefabPostInit(prefab, function(inst)
		if not TheWorld.ismastersim then
			return
		end

		local _OnSave = inst.OnSave
		inst.OnSave = function(inst, data, ...)
			if _OnSave then
				_OnSave(inst, data, ...)
			end

			SaveName(inst, data)
		end

		local _OnLoad = inst.OnLoad
		inst.OnLoad = function(inst, data, ...)
			if _OnLoad then
				_OnLoad(inst, data, ...)
			end

			LoadName(inst, data)
		end
	end)
end

AddSavedName("icehound")
AddSavedName("glacialhound")

local function RemoveIceShield(varglet)
	if not (varglet and varglet:IsValid()) then
		return
	end

	if varglet.ice_shield and varglet.ice_shield:IsValid() then
		varglet.ice_shield._silent_remove = true
		varglet.ice_shield:Remove()
		varglet.ice_shield = nil
	end

	if varglet.shield_fx and varglet.shield_fx:IsValid() then
		varglet.shield_fx:Remove()
		varglet.shield_fx = nil
	end

	if varglet.shield_fx2 and varglet.shield_fx2:IsValid() then
		varglet.shield_fx2:Remove()
		varglet.shield_fx2 = nil
	end

	varglet:RemoveTag("ice_shielded")
end

local function GetLeader(camp)
	if not (camp and camp.data and camp.data.children) then
		return nil
	end

	local walrus = nil

	for child in pairs(camp.data.children) do
		if child:IsValid() then
			if child.prefab == "little_walrus" then
				return child
			elseif child.prefab == "walrus" then
				walrus = child
			end
		end
	end

	return walrus
end

local function DidTheyShowUp(camp)
	if not (camp and camp.data and camp.data.children) then
		return false
	end

	for child in pairs(camp.data.children) do
		if child:IsValid() and child:HasTag("flare_summoned") then
			return true
		end
	end

	return false
end

local function ClearTag(camp)
	if not (camp and camp.data and camp.data.children) then
		return
	end

	for child in pairs(camp.data.children) do
		if child:IsValid() then
			child:RemoveTag("flare_summoned")
		end
	end
end

local function Detection(inst)
	if not (inst and inst:IsValid()) then
		return true
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	return #FindPlayersInRange(x, y, z, DESPAWN_RADIUS) <= 0
end

local function DespawnVarglet(camp)
	if camp.DespawnVarglet then
		return
	end

	camp.DespawnVarglet = camp:DoPeriodicTask(1, function()
		local varglet = camp.GlacialVarglet

		if not (varglet and varglet:IsValid()) then
			camp.GlacialVarglet = nil

			if camp.DespawnVarglet then
				camp.DespawnVarglet:Cancel()
				camp.DespawnVarglet = nil
			end

			return
		end

		if Detection(varglet) then
			ReleaseName(varglet)
			RemoveIceShield(varglet)
			varglet:Remove()
			camp.GlacialVarglet = nil

			if camp.DespawnVarglet then
				camp.DespawnVarglet:Cancel()
				camp.DespawnVarglet = nil
			end
		end
	end)
end

local function SetupVarglet(camp, varglet, leader)
	varglet.persists = true
	varglet:AddTag("pet_hound")
	varglet:AddTag("flare_summoned")

	NameTheDog(varglet)

	if varglet.components.follower == nil then
		varglet:AddComponent("follower")
	end

	varglet.components.follower:SetLeader(leader)
	varglet.components.follower.leashmaxdist = 10
	varglet.components.follower.leashmindist = 5

	if varglet.components.combat then
		varglet.components.combat:SetTarget(nil)
		varglet.components.combat:SetKeepTargetFunction(function(inst, target)
			return target ~= nil and target:IsValid() and leader ~= nil and leader:IsValid() and inst:GetDistanceSqToInst(leader) <= 40 * 40
		end)
	end

	if varglet.sg then
		varglet.sg:GoToState("idle")
	end

	varglet:DoPeriodicTask(.5, function(inst)
		if not (camp and camp:IsValid()) then
			ReleaseName(inst)
			RemoveIceShield(inst)
			inst:Remove()
			return
		end

		if not DidTheyShowUp(camp) then
			DespawnVarglet(camp)
			return
		end

		if not (leader and leader:IsValid()) then
			DespawnVarglet(camp)
			return
		end

		if inst.components.follower then
			if inst.components.follower:GetLeader() ~= leader then
				inst.components.follower:SetLeader(leader)
			end

			inst.components.follower.leashmaxdist = 10
			inst.components.follower.leashmindist = 5
		end
	end)
end

local function SpawnVarglet(camp)
	if not (camp and camp:IsValid()) then
		return
	end

	if camp.VargletSpawned then
		return
	end

	if camp.GlacialVarglet and camp.GlacialVarglet:IsValid() then
		return
	end

	if camp.DespawnVarglet then
		camp.DespawnVarglet:Cancel()
		camp.DespawnVarglet = nil
	end

	local leader = GetLeader(camp)
	if not (leader and leader:IsValid()) then
		return
	end

	local x, y, z = leader.Transform:GetWorldPosition()
	local varglet = SpawnPrefab("glacialhound")

	if varglet then
		camp.VargletSpawned = true

		varglet.Transform:SetPosition(x, y, z)
		SetupVarglet(camp, varglet, leader)
		camp.GlacialVarglet = varglet
	end
end

local function WalrusNaming(camp)
	if not (camp and camp.data and camp.data.children) then
		return
	end

	for child in pairs(camp.data.children) do
		if child:IsValid() and child.prefab == "icehound" then
			NameTheDog(child)
		end
	end

	if camp.GlacialVarglet and camp.GlacialVarglet:IsValid() then
		NameTheDog(camp.GlacialVarglet)
	end
end

local function OnMegaFlare(inst, data)
	inst:DoTaskInTime(5, function()
		if not (inst:IsValid() and data and data.sourcept) then
			return
		end

		if not TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) then
			return
		end

		local party_active = nil
		local engaged = nil
		local spawnpoint = nil

		if inst.data.children then
			for k in pairs(inst.data.children) do
				if k:IsValid() then
					party_active = true

					local x, y, z = k.Transform:GetWorldPosition()

					if #FindPlayersInRange(x, y, z, 35) > 0 then
						engaged = true
					end

					if k.components.combat and k.components.combat.target then
						engaged = true
					end
				end
			end
		end

		if not engaged and party_active then
			local players = FindPlayersInRange(data.sourcept.x, data.sourcept.y, data.sourcept.z, 35)

			if #players > 0 then
				local offset = FindValidPositionByFan(math.random() * TWOPI, 40, 32, function(testoffset)
					local newpt = data.sourcept + testoffset

					return TheWorld.Map:IsAboveGroundAtPoint(newpt.x, newpt.y, newpt.z)
						and #FindPlayersInRange(newpt.x, newpt.y, newpt.z, 35) == 0
				end)

				if offset then
					spawnpoint = data.sourcept + offset
				end
			end
		end

		if spawnpoint then
			local ents = TheSim:FindEntities(data.sourcept.x, 0, data.sourcept.z, 70, WALRUS_MUST)

			if #ents > 0 then
				spawnpoint = nil
			end
		end

		if party_active and spawnpoint and not engaged then
			inst.VargletSpawned = nil

			local players = FindPlayersInRange(spawnpoint.x, spawnpoint.y, spawnpoint.z, 40)

			for k in pairs(inst.data.children) do
				if k:IsValid() then
					k.Transform:SetPosition(spawnpoint.x, spawnpoint.y, spawnpoint.z)
					k:AddTag("flare_summoned")

					if k.components.combat and players[1] then
						k.components.combat:SuggestTarget(players[1])
					end
				end
			end

			WalrusNaming(inst)
			SpawnVarglet(inst)

			if inst.GlacialVarglet and inst.GlacialVarglet:IsValid() then
				inst.GlacialVarglet.Transform:SetPosition(spawnpoint.x, spawnpoint.y, spawnpoint.z)

				if inst.GlacialVarglet.components.combat then
					inst.GlacialVarglet.components.combat:SetTarget(nil)
				end
			end
		end
	end)
end

local function RemoveVanilla(inst)
	if inst.event_listeners and inst.event_listeners.megaflare_detonated and inst.event_listeners.megaflare_detonated[TheWorld] then

		local listeners = {}

		for fn in pairs(inst.event_listeners.megaflare_detonated[TheWorld]) do
			table.insert(listeners, fn)
		end

		for _, fn in ipairs(listeners) do
			inst:RemoveEventCallback("megaflare_detonated", fn, TheWorld)
		end
	end
end

env.AddPrefabPostInit("walrus_camp", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	RemoveVanilla(inst)

	inst:ListenForEvent("megaflare_detonated", function(src, data)
		OnMegaFlare(inst, data)
	end, TheWorld)

	inst:DoPeriodicTask(1, function()
		WalrusNaming(inst)

		if DidTheyShowUp(inst) then
			SpawnVarglet(inst)
		elseif inst.GlacialVarglet and inst.GlacialVarglet:IsValid() then
			DespawnVarglet(inst)
		end
	end)

	inst:ListenForEvent("onwenthome", function()
		inst.VargletSpawned = nil
		ClearTag(inst)
		DespawnVarglet(inst)
	end)
	
	local _OnSave = inst.OnSave
	inst.OnSave = function(inst, data, ...)
		local refs = _OnSave and _OnSave(inst, data, ...) or nil

		if inst.GlacialVarglet and inst.GlacialVarglet:IsValid() then
			data.GlacialVarglet = inst.GlacialVarglet.GUID
			data.VargletSpawned = inst.VargletSpawned or nil

			if refs == nil then
				refs = {}
			end

			table.insert(refs, inst.GlacialVarglet.GUID)
		end

		return refs
	end

	local _OnLoad = inst.OnLoad
	inst.OnLoad = function(inst, data, ...)
		local ret = _OnLoad and _OnLoad(inst, data, ...)

		inst.SavedVarglet = data and data.GlacialVarglet or nil
		inst.VargletSpawned = data and data.VargletSpawned or nil

		return ret
	end

	local _OnLoadPostPass = inst.OnLoadPostPass
	inst.OnLoadPostPass = function(inst, newents, data, ...)
		local ret = _OnLoadPostPass and _OnLoadPostPass(inst, newents, data, ...)

		if inst.SavedVarglet and newents[inst.SavedVarglet] and newents[inst.SavedVarglet].entity then

			inst.GlacialVarglet = newents[inst.SavedVarglet].entity

			local leader = GetLeader(inst)
			if leader and leader:IsValid() then
				SetupVarglet(inst, inst.GlacialVarglet, leader)
			end
		end

		inst.SavedVarglet = nil

		return ret
	end
	
end)

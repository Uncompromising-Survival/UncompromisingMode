local env = env
GLOBAL.setfenv(1, GLOBAL)

local WAGSTAFF_LEVERS =
{
	um_cookpot_wagstaff_lever = true,
	um_cookpot_wagstaff_lever2 = true,
}

local function GetData()
	TheWorld.WagstaffLevers = TheWorld.WagstaffLevers or {}
	return TheWorld.WagstaffLevers
end

env.AddPrefabPostInit("world", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.WagstaffLevers = inst.WagstaffLevers or {}
	TheWorld.WagstaffLevers = inst.WagstaffLevers

	local old_OnSave = inst.OnSave
	inst.OnSave = function(inst, data)
		if old_OnSave ~= nil then
			old_OnSave(inst, data)
		end

		data.WagstaffLevers = inst.WagstaffLevers
	end

	local old_OnLoad = inst.OnLoad
	inst.OnLoad = function(inst, data)
		if old_OnLoad ~= nil then
			old_OnLoad(inst, data)
		end

		inst.WagstaffLevers = data ~= nil and data.WagstaffLevers or {}
		TheWorld.WagstaffLevers = inst.WagstaffLevers
	end
end)

SetSharedLootTable("um_daywalker2",
{
	{ "gears",							0.5 },
	{ "wagpunk_bits",					1 },
	{ "wagpunk_bits",					1 },
	{ "wagpunk_bits",					1 },
	{ "wagpunk_bits",					1 },
	{ "wagpunk_bits",					1 },
	{ "wagpunk_bits",					0.5 },

	{ "um_cookpot_wagstaff_lever",		1 },
	{ "um_cookpot_wagstaff_lever2",		1 },

	{ "armorwagpunk_blueprint",			1 },
	{ "wagpunkhat_blueprint",			1 },
	{ "um_boatbottle_blueprint",		1 },
	{ "chestupgrade_stacksize_blueprint",	1 },
	{ "wagpunkbits_kit_blueprint",		1 },
	{ "chesspiece_daywalker2_sketch",	1 },
})

local function RemoveLevers(loot)
	local dropped = GetData()

	if loot ~= nil then
		for i = #loot, 1, -1 do
			local prefab = loot[i]

			if WAGSTAFF_LEVERS[prefab] and dropped[prefab] then
				table.remove(loot, i)
			end
		end
	end
end

local function MarkLevers(inst)
	local lootdropper = inst.components.lootdropper

	if lootdropper._um_old_droploot ~= nil then
		return
	end

	lootdropper._um_old_droploot = lootdropper.DropLoot

	lootdropper.DropLoot = function(self, ...)
		local dropped = GetData()
		local old_SpawnLootPrefab = self.SpawnLootPrefab

		self.SpawnLootPrefab = function(self, prefab, ...)
			local loot = old_SpawnLootPrefab(self, prefab, ...)

			if WAGSTAFF_LEVERS[prefab] then
				dropped[prefab] = true
			end

			return loot
		end

		local ret = self._um_old_droploot(self, ...)

		self.SpawnLootPrefab = old_SpawnLootPrefab

		return ret
	end
end

local function HookLoot(inst)
	local lootdropper = inst.components.lootdropper

	if lootdropper._um_old_generateloot ~= nil then
		return
	end

	lootdropper._um_old_generateloot = lootdropper.GenerateLoot

	lootdropper.GenerateLoot = function(self, ...)
		local loot = self:_um_old_generateloot(...)

		RemoveLevers(loot)

		return loot
	end
end

env.AddPrefabPostInit("daywalker2", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst.components.lootdropper:SetChanceLootTable("um_daywalker2")

	HookLoot(inst)
	MarkLevers(inst)
end)

--technically not daywalker but i'm putting it here anyway
local function OnEntityWake(inst)
    if not inst.hascannon then
        inst.hascannon = true
    end

    inst:UpdateShaker()
end

env.AddPrefabPostInit("junk_pile_big", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.OnEntityWake = OnEntityWake
end)

env.AddPrefabPostInit("wagstaff_machinery", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.lootdropper then
        inst.components.lootdropper:SetLootSetupFn(nil)
    end
end)

-- env.AddShardModRPCHandler("UncompromisingSurvival", "DayWalkerDeathPenalty", function(shardid, segs)
-- if TheWorld ~= nil and TheWorld.components.forestdaywalkerspawner ~= nil then
-- TheWorld.components.forestdaywalkerspawner:TryToSetDayWalkerJunkPile()
-- if TheWorld.components.forestdaywalkerspawner.bigjunk ~= nil then
-- TheWorld.components.forestdaywalkerspawner.bigjunk:StartDaywalkerBuried()
-- end
-- end
-- end)

-- env.AddComponentPostInit("daywalkerspawner", function(self)
-- if not TheWorld.ismastersim then
-- return
-- end

-- local _SpawnDayWalkerArena = self.SpawnDayWalkerArena

-- function self:SpawnDayWalkerArena(x, y, z, ...)
-- if ((math.random() > 0.5 and TUNING.DSTU.DAYWALKERSPAWN == "random") or TUNING.DSTU.DAYWALKERSPAWN == "surface") and not self.first_time then
-- local daywalker = SpawnPrefab("daywalker")
-- daywalker:DoTaskInTime(30, function(daywalker)
-- daywalker.components.lootdropper:SetLootSetupFn(nil)
-- daywalker.defeated = true

-- daywalker.components.health:Kill()
-- SendModRPCToShard(GetShardModRPC("UncompromisingSurvival", "DayWalkerDeathPenalty"), nil)
-- daywalker:Remove()

-- end)
-- self.first_time = true
-- return daywalker
-- else
-- self.first_time = true
-- return _SpawnDayWalkerArena(self, x, y, z, ...)
-- end
-- end

-- local _OnSave = self.OnSave

-- function self:OnSave(...)
-- local data, refs = _OnSave(self, ...)
-- data.first_time = self.first_time
-- return data, refs
-- end

-- local _OnLoad = self.OnLoad
-- function self:OnLoad(data, ...)
-- _OnLoad(self, data, ...)

-- if not data then
-- return
-- end

-- self.first_time = data.first_time
-- end
-- end)

-- local fx = {
-- "daywalker2_object_break_fx",
-- "daywalker2_spike_break_fx",
-- "daywalker2_cannon_break_fx",
-- "daywalker2_armor2_break_fx",
-- "daywalker2_cloth_break_fx"
-- }

-- for k, v in pairs(fx) do
-- env.AddPrefabPostInit(v, function(inst)
-- if not TheWorld.ismastersim then
-- return
-- end

-- inst:ListenForEvent("animover", function(inst)
-- --if math.random() > 0.33 then
-- local loot = SpawnPrefab("wagpunk_bits")
-- loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
-- --end
-- end)
-- end)
-- end

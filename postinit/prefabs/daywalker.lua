local env = env
GLOBAL.setfenv(1, GLOBAL)

local _lootsetfn
local function lootsetfn(lootdropper, ...)
    local ret = _lootsetfn and _lootsetfn(lootdropper, ...)
    --[[lootdropper:ClearRandomLoot()
    if TheWorld.components.riftspawner and TheWorld.components.riftspawner:GetLunarRiftsEnabled() then
        --lootdropper:AddRandomLoot("um_boatbottle_blueprint", 1)
    end

    lootdropper.numrandomloot = 1]]
    local inst = lootdropper.inst
    if inst.UMUpdateLoot then inst:UMUpdateLoot(lootdropper) end
    return ret
end

local lootitemstoremove = {
    ["wagpunkhat_blueprint"] = true,
    ["armorwagpunk_blueprint"] = true,
    ["chestupgrade_stacksize_blueprint"] = true,
    ["wagpunkbits_kit_blueprint"] = true,
    ["wagpunkbits_kit"] = true
}

local function UpdateLoot(inst, lootdropper)
    local randomloot = lootdropper.randomloot
    if randomloot then
        for id, loot in pairs(randomloot) do
            if loot.prefab and lootitemstoremove[loot.prefab] then
                table.remove(lootdropper.randomloot, id)
                lootdropper.totalrandomweight = lootdropper.totalrandomweight - loot.weight
                if not next(randomloot) then lootdropper:ClearRandomLoot() end
            end
        end
    end
end

SetSharedLootTable("um_daywalker2",
    {
        { "gears",                            0.5 },
        { "wagpunk_bits",                     1 },
        { "wagpunk_bits",                     1 },
        { "wagpunk_bits",                     1 },
        { "wagpunk_bits",                     1 },
        { "wagpunk_bits",                     1 },
        { "wagpunk_bits",                     0.5 },
        { "um_cookpot_wagstaff_lever",        1 },
        { "um_cookpot_wagstaff_lever2",       1 },
        { "armorwagpunk_blueprint",           1 },
        { "wagpunkhat_blueprint",             1 },
        { "um_boatbottle_blueprint",          1 },
        { "chestupgrade_stacksize_blueprint", 1 },
        { "chesspiece_daywalker2_sketch",     1 },
        { "wagpunkbits_kit_blueprint",        1 }
    })


env.AddPrefabPostInit("daywalker2", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.lootdropper:SetChanceLootTable('um_daywalker2')

    if not _lootsetfn then
        _lootsetfn = inst.components.lootdropper.lootsetupfn
    end
    inst.components.lootdropper:SetLootSetupFn(lootsetfn)

    inst.UMUpdateLoot = UpdateLoot
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

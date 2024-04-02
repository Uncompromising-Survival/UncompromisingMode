local env = env
GLOBAL.setfenv(1, GLOBAL)

local function lootsetfn(lootdropper)
    lootdropper:ClearRandomLoot()
    if TheWorld.components.riftspawner and TheWorld.components.riftspawner:GetLunarRiftsEnabled() then
        lootdropper:AddRandomLoot("chestupgrade_stacksize_blueprint", 1)
    end

    lootdropper.numrandomloot = 1
end

SetSharedLootTable("um_daywalker2",
    {
        { "gears",            0.5 },

        { "wagpunk_bits",     1 },
        { "wagpunk_bits",     1 },
        { "wagpunk_bits",     1 },
        { "wagpunk_bits",     1 },
        { "wagpunk_bits",     1 },
        { "wagpunk_bits",     0.5 },

        { "armorwagpunk_blueprint",     1 },
        { "wagpunkhat",     1 },
        { "wagpunkbits_kit_blueprint",     1 },
    })


env.AddPrefabPostInit("daywalker2", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst.components.lootdropper:SetChanceLootTable('um_daywalker2')

    inst.components.lootdropper:SetLootSetupFn(lootsetfn)
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

env.AddShardModRPCHandler(env.modname, "DayWalkerDeathPenalty", function(shard_id, data)
    if TheWorld ~= nil and TheWorld.components.forestdaywalkerspawner ~= nil then
        TheWorld.components.forestdaywalkerspawner:TryToSetDayWalkerJunkPile()
        if TheWorld.components.forestdaywalkerspawner.bigjunk ~= nil then
            TheWorld.components.forestdaywalkerspawner.bigjunk:StartDaywalkerBuried()
        end
    end
end)

env.AddComponentPostInit("daywalkerspawner", function(self)
    if not TheWorld.ismastersim then return end

    local _SpawnDayWalkerArena = self.SpawnDayWalkerArena

    function self:SpawnDayWalkerArena(x, y, z, ...)
        if math.random() > 0.5 and not self.first_time then
            local daywalker = SpawnPrefab("daywalker")
            daywalker.components.lootdropper:SetLootSetupFn(nil)
            daywalker.components.health:Kill()
            daywalker.defeated = true
            daywalker:DoTaskInTime(20, function(inst)
                inst:Remove()
                SendModRPCToShard(GetShardModRPC(env.modname, "DayWalkerDeathPenalty"), nil)
            end)
            self.first_time = true
            return daywalker
        else
            self.first_time = true
            return _SpawnDayWalkerArena(self, x, y, z, ...)
        end
    end

    local _OnSave = self.OnSave

    function self:OnSave(...)
        local data, refs = _OnSave(self, ...)
        data.first_time = self.first_time
        return data, refs
    end

    local _OnLoad = self.OnLoad
    function self:OnLoad(data, ...)
        _OnLoad(self, data, ...)

        if not data then
            return
        end

        self.first_time = data.first_time
    end
end)

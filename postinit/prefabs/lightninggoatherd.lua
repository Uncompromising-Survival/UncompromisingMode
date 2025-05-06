local env = env
GLOBAL.setfenv(1, GLOBAL)

local ALPHA_LIGHTNINGGOAT_SPAWN_DELAY = 240 + math.random(240)
local PERIODICSPAWNER_CANTTAGS = {"INLIMBO"}
local function TrySpawnAlpha(inst, data)
    if data.name == "spawn_alpha" then
        local prefab = "alpha_lightninggoat"

        if not inst:IsAsleep() then
            inst.components.timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
            return
        end

        local x, y, z = inst.Transform:GetWorldPosition()

        if inst.components.periodicspawner.range or inst.components.periodicspawner.spacing then
            local density = inst.components.periodicspawner.density or 0
            if density <= 0 then
                inst.components.timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
                return
            end

            local ents = TheSim:FindEntities(x, y, z, inst.components.periodicspawner.range or inst.components.periodicspawner.spacing, nil, PERIODICSPAWNER_CANTTAGS)
            local count = 0
            for i, v in ipairs(ents) do
                if v.prefab == prefab then
                    --know that FindEntities radius is within "spacing"
                    if not inst.components.periodicspawner.range or (inst.components.periodicspawner.spacing
                        and (inst.components.periodicspawner.spacing >= inst.components.periodicspawner.range
                        or v:GetDistanceSqToPoint(x, y, z) < inst.components.periodicspawner.spacing * inst.components.periodicspawner.spacing)) then
                        inst.components.timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
                        return
                    end
                    count = count + 1
                    if count >= density then
                        inst.components.timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
                        return
                    end
                end
            end
        end


        for i, v in pairs(inst.components.herd.members) do
            if i:HasTag("alpha_goat") then
                inst.components.timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
                return
            end
        end

        local goat = SpawnPrefab(prefab)
        goat.Transform:SetPosition(x, y, z)

        if inst.components.periodicspawner.onspawn then
            inst.components.periodicspawner.onspawn(inst, goat)
        end
    end
end

local function NotHasAlphaStartTimer(inst)
    local has_alpha = false

    for i, v in pairs(inst.components.herd.members) do
        if i:HasTag("alpha_goat") then
            has_alpha = true
            break
        end
    end

    local timer = inst.components.timer
    if timer and not timer:TimerExists("spawn_alpha") and not has_alpha then
        timer:StartTimer("spawn_alpha", ALPHA_LIGHTNINGGOAT_SPAWN_DELAY)
    end
end

local function LightningGoatHerdPostInit(inst)
    if not inst.components.timer then
        inst:AddComponent("timer")
        inst:ListenForEvent("timerdone", TrySpawnAlpha)
    end

    local herd = inst.components.herd
    if herd then
        local _OldOnFull = herd.onfull or nil
        herd:SetOnFullFn(function(inst)
            if _OldOnFull ~= nil then
                _OldOnFull(inst)
            end

            NotHasAlphaStartTimer(inst)
        end)

        local _OldRemoveMember = herd.removemember or nil
        herd:SetRemoveMemberFn(function(inst)
            if _OldRemoveMember ~= nil then
                _OldRemoveMember(inst)
            end

            if inst.components.herd:IsFull() then
                NotHasAlphaStartTimer(inst)
            end
        end)

        local _OldAddMember = herd.addmember or nil
        herd:SetAddMemberFn(function(inst)
            if _OldAddMember ~= nil then
                _OldAddMember(inst)
            end

            if inst.components.herd:IsFull() then
                NotHasAlphaStartTimer(inst)
            end
        end)
    end
end

env.AddPrefabPostInit("lightninggoatherd", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    LightningGoatHerdPostInit(inst)
end)

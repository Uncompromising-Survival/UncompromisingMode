local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function CupcakeTheHound(guard, camp)
    if not guard or not camp then
        return
    end

    local function GetLeader()
        if camp and camp.data and camp.data.children then
            local walrus = nil

            for ent in pairs(camp.data.children) do
                if ent:IsValid() then
                    if ent.prefab == "little_walrus" then
                        return ent
                    elseif ent.prefab == "walrus" then
                        walrus = ent
                    end
                end
            end

            return walrus
        end

        return nil
    end

    guard:AddTag("flare_summoned")

    local named = guard.components.named or guard:AddComponent("named")
    named:SetName("Cupcake") -- Turn into a string and remove this comment.

    if guard.components.combat then
        guard.components.combat:SetKeepTargetFunction(function(inst, target)
            if not (target and target:IsValid()) then
                return false
            end

            local leader = GetLeader()
            if not leader or not leader:IsValid() then
                return true
            end

            if inst:GetDistanceSqToInst(leader) > 40 * 40 then
                return false
            end

            return true
        end)
    end

    guard:DoPeriodicTask(.5, function()
        if not guard.components.combat then
            return
        end

        local leader = GetLeader()
        if not leader or not leader:IsValid() then
            return
        end

        if guard.components.follower.leader ~= leader then
            guard.components.follower:SetLeader(leader)
        end
        guard.components.follower.leashmaxdist = 10
        guard.components.follower.leashmindist = 5

        if guard:GetDistanceSqToInst(leader) > 40 * 40 then
            guard.components.combat:SetTarget(nil)
            return
        end

        if leader.components.combat then
            local target = leader.components.combat.target
            if target and target:IsValid() and guard:GetDistanceSqToInst(leader) <= 20 * 20 then
                if guard.components.combat.target ~= target then
                    guard.components.combat:SetTarget(target)
                end
            end
        end
    end)
end

local function Stay(hound)
    if not (hound and hound:IsValid()) then
        return
    end

    hound._flare_hidden = true
    hound:AddTag("NOCLICK")
    hound.persists = false

    if hound.components.combat then
        hound.components.combat:SetTarget(nil)
    end

    if hound.Physics then
        hound.Physics:Stop()
    end

    hound:Hide()
    hound.entity:SetInLimbo(true)
end

local function GoodHounds(hound, x, y, z)
    if not (hound and hound:IsValid()) then
        return
    end

    if not hound._flare_hidden then
        return
    end

    hound._flare_hidden = nil
    hound:RemoveTag("NOCLICK")
    hound.persists = true

    hound.entity:SetInLimbo(false)
    hound:Show()

    if x and y and z then
        hound.Transform:SetPosition(x, y, z)
    end
end

local function Replacement(inst)
    if inst._flare_return_task then
        inst._flare_return_task:Cancel()
        inst._flare_return_task = nil
    end

    if inst._flare_state_task then
        inst._flare_state_task:Cancel()
        inst._flare_state_task = nil
    end

    if inst._flare_glacial and inst._flare_glacial:IsValid() then
        if inst._flare_glacial.ice_shield and inst._flare_glacial.ice_shield:IsValid() then
            inst._flare_glacial.ice_shield._silent_remove = true
            inst._flare_glacial.ice_shield:Remove()
        end

        if inst._flare_glacial.shield_fx and inst._flare_glacial.shield_fx:IsValid() then
            inst._flare_glacial.shield_fx:Remove()
        end

        inst._flare_glacial:Remove()
    end
    
    inst._flare_glacial = nil

    if inst._hidden_hounds then
        local x, y, z = inst.Transform:GetWorldPosition()
        for _, hound in ipairs(inst._hidden_hounds) do
            GoodHounds(hound, x, y, z)
        end
    end

    inst._hidden_hounds = nil
end

local function CupcakeOffscreen(guard)
    if not guard then
        return false
    end

    if not guard:IsValid() then
        return true
    end

    local x, y, z = guard.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 35)

    return #players == 0
end

local function PartyCheck(inst)
    if not (inst and inst.data and inst.data.children) then
        return false
    end

    local has_walrus = false
    local has_little = false

    for ent in pairs(inst.data.children) do
        if ent:IsValid() then
            if ent.prefab == "walrus" then
                has_walrus = true
            elseif ent.prefab == "little_walrus" then
                has_little = true
            end
        end
    end

    return not has_walrus and not has_little
end

local function AllHoundsGoToHeaven(inst)
    if not (inst and inst:IsValid() and inst._flare_glacial) then
        return
    end

    if inst._flare_return_task then
        return
    end

    inst._flare_return_task = inst:DoPeriodicTask(.5, function()
        if not inst:IsValid() then
            return
        end

        if CupcakeOffscreen(inst._flare_glacial) then
            Replacement(inst)
        end
    end)
end

local function HowIsTheHuntGoing(inst)
    if inst._flare_state_task then
        inst._flare_state_task:Cancel()
        inst._flare_state_task = nil
    end

    inst._flare_state_task = inst:DoPeriodicTask(.5, function()
        if not inst:IsValid() then
            return
        end

        if PartyCheck(inst) then
            AllHoundsGoToHeaven(inst)
            return
        end

        if inst._flare_glacial and not inst._flare_glacial:IsValid() then
            Replacement(inst)
            return
        end
    end)
end

local WALRUS_MUST = {"walrus"}

local function OnMegaFlare(inst, data)
    inst:DoTaskInTime(5, function()
        if data.sourcept and TheWorld.Map:IsVisualGroundAtPoint(data.sourcept.x, data.sourcept.y, data.sourcept.z) then

            local party_active = nil
            local engaged = nil
            local spawnpoint = nil

            if inst.data.children then
                for k in pairs(inst.data.children) do
                    if k:IsValid() then
                        party_active = true

                        local x, y, z = k.Transform:GetWorldPosition()
                        local players = FindPlayersInRange(x, y, z, 35)
                        if #players > 0 then
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

                        if TheWorld.Map:IsAboveGroundAtPoint(newpt.x, newpt.y, newpt.z) then
                            local testplayers = FindPlayersInRange(newpt.x, newpt.y, newpt.z, 35)
                            if #testplayers == 0 then
                                return true
                            end
                        end
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
                Replacement(inst)

                inst._hidden_hounds = {}
                local spawned_replacement = false
                local flare_guard = nil

                for k in pairs(inst.data.children) do
                    if k:IsValid() and k:HasTag("hound") then
                        local x, y, z = k.Transform:GetWorldPosition()

                        table.insert(inst._hidden_hounds, k)
                        Stay(k)

                        if not spawned_replacement then
                            local danger = SpawnPrefab("glacialhound")
                            if danger then
                                danger.Transform:SetPosition(x, y, z)

                                CupcakeTheHound(danger, inst)
                                flare_guard = danger
                                spawned_replacement = true
                            end
                        end
                    end
                end

                inst._flare_glacial = flare_guard

                for k in pairs(inst.data.children) do
                    if k:IsValid() and not k._flare_hidden then
                        k.Transform:SetPosition(spawnpoint.x, spawnpoint.y, spawnpoint.z)
                        k:AddTag("flare_summoned")
                    end
                end

                if inst._flare_glacial and inst._flare_glacial:IsValid() then
                    inst._flare_glacial.Transform:SetPosition(spawnpoint.x, spawnpoint.y, spawnpoint.z)
                end

                HowIsTheHuntGoing(inst)
            end
        end
    end)
end

env.AddPrefabPostInit("walrus_camp", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("megaflare_detonated", function(src, data)
        OnMegaFlare(inst, data)
    end, TheWorld)

    inst:ListenForEvent("onwenthome", function()
        AllHoundsGoToHeaven(inst)
    end)
end)
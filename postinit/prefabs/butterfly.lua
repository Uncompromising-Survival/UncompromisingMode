local env = env
GLOBAL.setfenv(1, GLOBAL)

if TUNING.DSTU.BUTTERFLYWINGS_NERF == "unique" then
    local function Slippy(inst, target, distancemod) -- Reduced from wixie_shove to something only applicable to the butterfly
        local x, y, z = inst.Transform:GetWorldPosition()
        for i = 1, 50 do
            inst:DoTaskInTime((i - 1) / 50, function(inst)
                local tx, ty, tz = target.Transform:GetWorldPosition()
                if tx then
                    local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
                    local velx = math.cos(rad)
                    local velz = -math.sin(rad)
                    local distancemultiplier = distancemod and 1 + (distancemod / 10) or 1
                    local dx, dy, dz = tx + ((((3 / (i + 2)) * velx))) / distancemultiplier, ty, tz + ((((3 / (i + 2)) * velz))) / distancemultiplier
                    target.Transform:SetPosition(dx, dy, dz)
                end
            end)
        end
    end

    local allowedstimuli = {"soul"}
    local function AbleToBeAttacked(inst, weapon, stimuli)
        return inst.sg:HasStateTag("busy") and inst.sg.currentstate.name ~= "takeoff"
            or weapon and (weapon.prefab == "bugzapper" or IsRangedWeapon(weapon))
            or stimuli and table.contains(allowedstimuli, stimuli)
    end

    local function UMSlipAway(inst, data)
        local attacker = data.attacker
        local shouldslip = false
        if attacker and attacker:IsValid() and not AbleToBeAttacked(inst, data.weapon or attacker, data.stimuli) then -- Can only attack when criteria is met.
            inst.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop")
            Slippy(attacker, inst)
            if attacker:HasTag("player") then UMCommonFns.Say(attacker, GetString(attacker, "ANNOUNCE_BUTTERFLY_SLIP")) end
            shouldslip = true
        end
        return shouldslip
    end

    local function BozoUpdate(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 8, {"_health"}, {"structure", "smallcreature"})
        local mindist = 12
        if ents then
            for i,v in ipairs(ents) do
                if inst:GetDistanceSqToInst(v) ^ 0.5 < mindist then
                    mindist = inst:GetDistanceSqToInst(v) ^ 0.5
                end
            end
        end
        if mindist < 8 then
            local statename = inst.sg.currentstate.name
            if statename == "pollinate" or statename == "land_idle" and not inst.takeoff then
                inst.takeoff = inst:DoTaskInTime(1.2, function(inst)
                    local statename = inst.sg.currentstate.name
                    if statename == "pollinate" or statename == "land_idle" and TheWorld.state.isday then
                        inst.sg:GoToState("takeoff")
                    end
                    inst.takeoff = nil
                end)
            elseif inst:GetBufferedAction() and TheWorld.state.isday then
                inst:ClearBufferedAction()
                if inst.components.locomotor then
                    inst.components.locomotor:Clear()
                end
            end
        end
    end

    local function CheckForNearbyBozos(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 12, {"_health"}, {"structure", "smallcreature"})
        if #ents > 0 and not inst.active_monitoring then
            inst.active_monitoring = inst:DoPeriodicTask(FRAMES, BozoUpdate)
        elseif inst.active_monitoring then
            inst.active_monitoring:Cancel()
            inst.active_monitoring = nil
        end
    end

    local function MakeButtery(inst)
        SpawnPrefab("um_buttery_fly").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
    end

    local function RollForButtery(inst)
        if inst.buttery and inst.buttery >= 98 then
            MakeButtery(inst)
        end
    end

    local butterflies = {"butterfly", "um_buttery_fly", "moonbutterfly"}
    for _, prefab in pairs(butterflies) do
        env.AddPrefabPostInit(prefab, function(inst)
            inst:AddTag("um_slippery")

            if not TheWorld.ismastersim then return end

            inst.UMSlipAway = UMSlipAway

            inst:DoPeriodicTask(2, CheckForNearbyBozos)

            if prefab == "butterfly" then
                local lootdropper = inst.components.lootdropper
                if lootdropper then lootdropper:SetLoot({"butterflywings"}) end

                local _OnSave = inst.OnSave
                inst.OnSave = function(_inst, data, ...)
                    if _inst.buttery then data.buttery = _inst.buttery end
                    return _OnSave and _OnSave(_inst, data, ...)
                end
                local _OnLoad = inst.OnLoad
                inst.OnLoad = function(_inst, data, ...)
                    _inst.buttery = data and data.buttery or math.random(1, 100)
                    RollForButtery(_inst)
                    return _OnLoad and _OnLoad(_inst, data, ...)
                end
            end
        end)
    end

    local function ReEnableButterfly(inst)
        if inst.spawned_butterfly then inst.spawned_butterfly = nil end
    end
    
    local flower_types = {"flower", "flower_evil", "um_buttercup"}
    for i,v in ipairs(flower_types) do
        env.AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then return end
            inst:WatchWorldState("isday", ReEnableButterfly)
        end)
    end

    local FLOWER_TAGS = {"flower"}
    local function GetSpawnPoint(player)
        local rad = 25
        local mindistance = 36
        local x, y, z = player.Transform:GetWorldPosition()
        local flowers = TheSim:FindEntities(x, y, z, rad, FLOWER_TAGS)

        for i, v in ipairs(flowers) do
            while v ~= nil and player:GetDistanceSqToInst(v) <= mindistance or (v ~= nil and v.spawned_butterfly) do
                table.remove(flowers, i)
                v = flowers[i]
            end
        end

        local chosen_flower
        if next(flowers) then
            chosen_flower = flowers[math.random(1, #flowers)]
            chosen_flower.spawned_butterfly = true
        end
        return chosen_flower
    end

    local UMUpvalueHacker = require("tools/um_upvaluehacker")
    env.AddComponentPostInit("butterflyspawner", function(self)
        local _GetSpawnPoint = UMUpvalueHacker.TryGetUpvalue(self.OnPostInit, "ToggleUpdate", "ScheduleSpawn", "SpawnButterflyForPlayer", "GetSpawnPoint")
        if _GetSpawnPoint then UMUpvalueHacker.SetUpvalue(self.OnPostInit, GetSpawnPoint, "ToggleUpdate", "ScheduleSpawn", "SpawnButterflyForPlayer", "GetSpawnPoint") end
    end)
end
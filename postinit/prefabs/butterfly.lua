local env = env
GLOBAL.setfenv(1, GLOBAL)

if TUNING.DSTU.BUTTERFLYWINGS_NERF == "slippery" then
    local function Slippy(inst, target, speed, distancemod) -- Reduced from wixie_shove to something only applicable to the butterfly
        local x, y, z = inst.Transform:GetWorldPosition()
        for i = 1, 50 do
            inst:DoTaskInTime((i - 1) / 50, function(inst)
                local tx, ty, tz = target.Transform:GetWorldPosition()
                if tx then
                    local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
                    local velx = math.cos(rad)
                    local velz = -math.sin(rad)
                    local distancemultiplier = distancemod ~= nil and 1 + (distancemod / 10) or 1
                    local dx, dy, dz = tx + ((((3 / (i + 2)) * velx))) / distancemultiplier, ty, tz + ((((3 / (i + 2)) * velz))) / distancemultiplier
                    target.Transform:SetPosition(dx, dy, dz)
                end
            end)
        end
    end

    local function SittingStill(statename)
        return statename and (statename == "pollinate" or statename == "land_idle" or statename == "thaw" or statename == "frozen")
    end

    local function ByPassWeapon(weapon, attacker, inst)
        return weapon and (weapon.prefab == "bugzapper" or weapon:HasTag("blowdart") or ((weapon.components.weapon and weapon.components.weapon.projectile) or weapon.components.projectile))
    end

    local function ByStimuli(stimuli)
        return stimuli and stimuli == "soul"
    end

    local function SlipAway(inst, data)
        if data.attacker then
            local statename = inst.sg.currentstate.name
            if not SittingStill(statename) and not ByPassWeapon(data.weapon, data.attacker, inst) and not ByStimuli(data.stimuli) then -- Can only attack when idle
                inst.SoundEmitter:PlaySound("dontstarve/movement/slip_fall_whoop")
                Slippy(data.attacker, inst)
                if data.attacker.components.talker and data.attacker:HasTag("player") then
                    data.attacker.components.talker:Say(GetString(data.attacker, "ANNOUNCE_BUTTERFLY_SLIP"))
                end
                return true
            end
        end
        return false
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
        else
            inst.components.lootdropper:SetLoot({"butterflywings"})
        end
    end

    local butterflies = {"butterfly","um_buttery_fly","moonbutterfly"}
    for i,v in ipairs(butterflies) do
        env.AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then
                return
            end

			inst.SlipAway = SlipAway

            inst:DoPeriodicTask(2, CheckForNearbyBozos)
            
            
            if v == "butterfly" then
                inst.OnSave = function(inst,data)
                    if inst.buttery then
                        data.buttery = inst.buttery
                    end
                end
                inst.OnLoad = function(inst,data)
                    if data.buttery then
                        inst.buttery = data.buttery
                    end
                    RollForButtery(inst)
                    return data
                end
                inst:DoTaskInTime(0, function(inst)
                    if not inst.buttery then
                        inst.buttery = math.random(1, 100)
                    end
                    RollForButtery(inst)
                end)
            end
        end)
    end

    local function ReEnableButterfly(inst)
        if inst.spawned_butterfly then
            inst.spawned_butterfly = nil
        end
    end
    
    local flower_types = {"flower", "flower_evil"}
    for i,v in ipairs(flower_types) do
        env.AddPrefabPostInit(v, function(inst)
            if not TheWorld.ismastersim then
                return
            end
            inst:WatchWorldState("isday",ReEnableButterfly)
        end)
    end
	
	-- Burnable Butterfly Wings.
    local wing_types = {"butterflywings", "moonbutterflywings"}
    for i,v in ipairs(wing_types) do
        env.AddPrefabPostInit(v, function(inst)
			MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
			MakeSmallPropagator(inst)
			MakeHauntableLaunchAndIgnite(inst)
        end)
    end

    local FLOWER_TAGS = {"flower"}
    local BUTTERFLY_TAGS = {"butterfly"}
    
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
        return chosen_flower ~= nil and chosen_flower or nil
    end

    local UpvalueHacker = require("tools/upvaluehacker")
    env.AddComponentPostInit("butterflyspawner", function(cmp)
        local _GetSpawnPoint, _fn_i, scope_fn = UpvalueHacker.GetUpvalue(cmp.OnPostInit, "ToggleUpdate", "ScheduleSpawn", "SpawnButterflyForPlayer", "GetSpawnPoint")

        debug.setupvalue(scope_fn, _fn_i,GetSpawnPoint)
    end)

    env.AddStategraphState("butterfly", State{
        name = "idle_flutter",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            if not inst.AnimState:IsCurrentAnimation("flight_cycle") then
                inst.AnimState:PlayAnimation("flight_cycle", true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        ontimeout = function(inst)
            if inst.sg.statemem.wantstomove then
                inst.sg:GoToState("moving")
            else
                inst.sg:GoToState("idle")
            end
        end,
    })
end
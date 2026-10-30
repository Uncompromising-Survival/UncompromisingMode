local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
if TUNING.DSTU.PK_GUARDS then
    local UMUpvalueHacker = require("tools/um_upvaluehacker")

    local function ErectPoleBuild(inst, x, y, z)
        local pole = SpawnPrefab("pigking_pigtorch")
        local collapse = SpawnPrefab("collapse_big")
        pole.Transform:SetPosition(x, y, z)
        collapse.Transform:SetPosition(x, y, z)
        inst.sg:GoToState("cointoss")
    end

    local function IsGuard(guy)
        return guy.prefab == "pigking_pigguard" and guy.components.follower and not guy.components.follower:GetLeader()
    end

    local function FindRecruit(inst)
        return FindEntity(inst, 20, IsGuard) or nil
    end

    local function AcceptTest(inst, item, giver)
        -- Wurt can still play the mini-game though
        if giver:HasTag("merm") and item.prefab ~= "pig_token" then
            return
        end

        local is_event_item = IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) and
            item.components.tradable.halloweencandyvalue and item.components.tradable.halloweencandyvalue > 0
        return item.components.tradable.goldvalue > 0 or is_event_item or item.prefab == "pig_token" or
            (item.components.edible ~= nil and item.components.edible.foodtype ~= FOODTYPE.ROUGHAGE and item.components.edible.hungervalue > 70 and FindRecruit(inst))
    end

    local function SendRecruit(inst, hunger, guard, giver)
        giver:PushEvent("makefriend")
        giver.components.leader:AddFollower(guard)
        guard.components.follower:AddLoyaltyTime(hunger * TUNING.PIG_LOYALTY_PER_HUNGER)
        guard.components.follower.maxfollowtime = giver:HasTag("polite") and TUNING.PIG_LOYALTY_MAXTIME + TUNING.PIG_LOYALTY_POLITENESS_MAXTIME_BONUS
            or TUNING.PIG_LOYALTY_MAXTIME
    end

    local _OnAccept
    local function OnAccept(inst, giver, item, ...)
        local recruit = FindRecruit(inst)
        if item.components.edible and item.components.edible.foodtype ~= FOODTYPE.ROUGHAGE and item.components.edible.hungervalue > 70 and recruit then
            SendRecruit(inst, item.components.edible.hungervalue, recruit, giver)
            inst.sg:GoToState("cointoss")
            --inst.sg:GoToState("recruit")
        else
            return _OnAccept and _OnAccept(inst, giver, item, ...)
        end
    end

    env.AddPrefabPostInit("pigking", function(inst)
        if not TheWorld.ismastersim then return end

        inst.Rebuild = ErectPoleBuild

        inst:DoTaskInTime(0, function(_inst)
            local x, y, z = _inst.Transform:GetWorldPosition()
            if #TheSim:FindEntities(x, y, z, 30, {"pkpole"}) == 0 then
                ErectPoleBuild(_inst, x + 7, y, z + 7)
                ErectPoleBuild(_inst, x + 7, y, z - 7)
                ErectPoleBuild(_inst, x - 7, y, z + 7)
                ErectPoleBuild(_inst, x - 7, y, z - 7)
            end
        end)

        local trader = inst.components.trader
        if trader then
            trader:SetAcceptTest(AcceptTest)
            if not _OnAccept then
                _OnAccept = trader.onaccept
            end
            trader:SetOnAccept(OnAccept)
        end
    end)

    -- Make sure everything else has loaded
    local BLOCKING_CANT_OBJECTS = {"pkpole"}
    env.AddSimPostInit(function()
        local _BLOCKING_CANT_OBJECTS = UMUpvalueHacker.GetUpvalue(Prefabs.pigking.fn, "AbleToAcceptTest", "CanStartMinigame", "IsAreaClearForMinigame", "BLOCKING_CANT_OBJECTS")
        for i, TAG in pairs(BLOCKING_CANT_OBJECTS) do
            table.insert(_BLOCKING_CANT_OBJECTS, TAG)
        end
    end)
end
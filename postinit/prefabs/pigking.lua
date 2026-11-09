local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
if UM_CONFIG.PIGKING_GUARDS then
    local UMUpvalueHacker = require("tools/um_upvaluehacker")

    local function ErectPoleBuild(inst, x, y, z)
        local pole = SpawnPrefab("pigtorch")
        pole.Transform:SetPosition(x, y, z)
        pole:UMSetPKTorch()
        SpawnPrefab("collapse_big").Transform:SetPosition(x, y, z)
        inst.sg:GoToState("cointoss")
    end

    local function IsGuard(guy)
        return guy.components.follower and not guy.components.follower:GetLeader()
    end

    local GUARD_MUST_TAGS = {"um_pkguard"}
    local function FindRecruit(item, inst)
        local edible = item.components.edible
        return edible and edible.foodtype ~= FOODTYPE.ROUGHAGE and edible.hungervalue > 70 and FindEntity(inst, 20, IsGuard, GUARD_MUST_TAGS) or nil
    end

    local _AcceptTest
    local function AcceptTest(inst, item, giver, ...)
        return not giver:HasTag("merm") and FindRecruit(item, inst)
            or _AcceptTest and _AcceptTest(inst, item, giver, ...)
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
        local recruit = FindRecruit(item, inst)
        if recruit then
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
            if #TheSim:FindEntities(x, y, z, 30, {"um_pktorch"}) == 0 then
                ErectPoleBuild(_inst, x + 7, y, z + 7)
                ErectPoleBuild(_inst, x + 7, y, z - 7)
                ErectPoleBuild(_inst, x - 7, y, z + 7)
                ErectPoleBuild(_inst, x - 7, y, z - 7)
            end
        end)

        local trader = inst.components.trader
        if trader then
            if not _AcceptTest then
                _AcceptTest = trader.test
            end
            trader:SetAcceptTest(AcceptTest)
            if not _OnAccept then
                _OnAccept = trader.onaccept
            end
            trader:SetOnAccept(OnAccept)
        end
    end)

    -- Make sure everything else has loaded
    local BLOCKING_CANT_OBJECTS = {"um_pktorch"}
    env.AddSimPostInit(function()
        local _BLOCKING_CANT_OBJECTS = UMUpvalueHacker.GetUpvalue(Prefabs.pigking.fn, "AbleToAcceptTest", "CanStartMinigame", "IsAreaClearForMinigame", "BLOCKING_CANT_OBJECTS")
        for i, TAG in pairs(BLOCKING_CANT_OBJECTS) do
            table.insert(_BLOCKING_CANT_OBJECTS, TAG)
        end
    end)
end
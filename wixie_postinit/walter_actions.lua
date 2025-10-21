local UpvalueHacker = require("tools/upvaluehacker")

local function AddEnemyDebuffFx(fx, target)
    target:DoTaskInTime(math.random()*0.25, function()
        local x, y, z = target.Transform:GetWorldPosition()
        local fx = GLOBAL.SpawnPrefab(fx)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end
        return fx
    end)
end

local wobycommand = AddAction("WOBY_COMMAND", "WOBY_COMMAND_FETCH", function(act)
        local hasfollowers, hasmerms = false, false
        if act.doer and act.doer.components.leader and act.target then
            for k,v in pairs(act.doer.components.leader.followers) do
                if not k:HasTag("customwobytag") and k.components.follower then 
                    if k.components.combat and act.target.components.combat and k.components.follower.canaccepttarget then
                        k.components.combat:SuggestTarget(act.target)
                    end
                    hasfollowers = true
                    if k:HasTag("merm") then
                        hasmerms = true
                        break
                    end
                end
            end
        end
        if act.doer and act.doer.woby and act.doer.woby.sg.currentstate.name ~= "transform" then
            if act.doer.components.rider and act.doer.components.rider:IsRiding() and act.doer.components.rider:GetMount() and act.doer.components.rider:GetMount():HasTag("woby")
                and not (hasfollowers and act.target and act.target:HasTag("CHOP_workable")) then
                if act.target and act.target.components.combat then
                    act.doer.sg:GoToState("bark_at")
                    if act.target.components.combat:CanTarget(act.doer) and not (act.target.components.combat:TargetIs(act.doer)
                        or act.target.components.grouptargeter and act.target.components.grouptargeter:IsTargeting(act.doer))
                        and not (act.target.sg and act.target.sg:HasStateTag("attack")) then
                        act.target.components.combat:SetTarget(act.doer)
                    end
                    return true
                end
                return false, "WOBYNEEDTODISMOUNT"
            else
                local act_pos = act:GetActionPoint()

                --if act.target and act.doer.woby.wobytarget then
                    if act.doer.woby.wobytarget == act.target then
                        act.doer.woby.wobytarget = nil
                        act.doer.woby.oldwobytarget = nil
                        act.doer.woby.sg:GoToState("bark_clearaction")
                        act.doer.components.talker:Say(GLOBAL.GetString(act.doer, act.target.components.combat and "ANNOUNCE_WOBY_COMBAT_STOP" or "ANNOUNCE_WOBY_STOP"))
                        return true
                    end
                --end

                if act.doer.woby.components.hunger:GetPercent() == 0 then
                    act.doer.woby.sg:GoToState("hungry")
                    return false, "WOBYHUNGRY"
                end
                if act.target then
                    if act.target.components then
                        if (act.target:HasTag("DIG_workable") and not (act.target.components.pickable and (act.target.components.pickable.canbepicked
                            and act.target.components.pickable.caninteractwith)) or act.target:HasTag("snowpile_basic")) and not act.doer.woby:HasTag("woby") then
                            act.doer.woby.wobytarget = nil
                            act.doer.woby.oldwobytarget = nil
                            if act.doer.woby.brain then
                                act.doer.woby.brain:Stop()
                                act.doer.woby.brain:Start()
                            end
                            act.doer.woby.sg:GoToState("bark_clearaction")
                            return false, "WOBYTOOSMALL"
                        end
                        if act.target:HasTag("blueberrybomb") then
                            return false, "WOBYTOODANGEROUS"
                        end
                        if act.target.components.combat then
                            act.doer.components.talker:Say(GLOBAL.GetString(act.doer, hasfollowers and "ANNOUNCE_TROUP_ATTACK" or "ANNOUNCE_WOBY_BARK"))
                        else
                            if hasfollowers and (act.target:HasTag("CHOP_workable") or hasmerms and act.target:HasTag("MINE_workable")) then
                                act.doer.components.talker:Say(GLOBAL.GetString(act.doer, "ANNOUNCE_TROUP_ATTENTION"))
                            elseif act.doer.components.skilltreeupdater:IsActivated("walter_woby_taskaid") and act.doer.woby:HasTag("woby") and act.target:HasAnyTag("CHOP_workable", "MINE_workable") then
                                act.doer.components.talker:Say(GLOBAL.GetString(act.doer, "ANNOUNCE_WOBY_WORK"))
                                return true
                            else
                                if (not act.target.components.pickable and not act.target.components.inventoryitem
                                    and not (act.doer.woby:HasTag("woby") and act.target:HasTag("DIG_workable"))) then
                                    return false, hasfollowers and "TROUPNEVERMIND" or "WOBYNEVERMIND"
                                end
                                act.doer.components.talker:Say(GLOBAL.GetString(act.doer, "ANNOUNCE_WOBY_FETCH"))
                            end
                        end
                        act.doer.woby.sg:GoToState("bark_clearaction")
                        act.doer.woby.wobytarget = nil
                        act.doer.woby.oldwobytarget = nil
                        if act.doer.woby.brain then
                            act.doer.woby.brain:Stop()
                            act.doer.woby.brain:Start()
                        end
                        act.doer.woby.wobytarget = act.target
                        return true
                    end
                end
                return false, hasfollowers and "TROUPNEVERMIND" or "WOBYNEVERMIND"
            end
        end
    end)

wobycommand.priority = HIGH_ACTION_PRIORITY
wobycommand.rmb = true
wobycommand.distance = 36
wobycommand.mount_valid = true

local wobystay = AddAction("WOBY_STAY", "WOBY_STAY", function(act)
        local act_pos = act:GetActionPoint()
        local hasfollowers = false
        if act.doer and act.doer.components.leader ~= nil then
            for k,v in pairs(act.doer.components.leader.followers) do
                if not k:HasTag("customwobytag") and k.components.follower then
                    if k.brain then
                        k.brain:Stop()
                        k.brain:Start()
                    end
                    if k.components.locomotor then
                        k.components.locomotor:GoToPoint(act_pos, nil, true)
                    end
                    hasfollowers = true
                end
            end
        end
        if act.doer and act.doer.woby and act_pos and act.doer.woby.sg.currentstate.name ~= "transform" then
            act.doer.woby.wobytarget = nil
            act.doer.woby.oldwobytarget = nil
            if act.doer.woby.brain then
                act.doer.woby.brain:Stop()
                act.doer.woby.brain:Start()
            end
            local sitpoint = GLOBAL.SpawnPrefab("woby_target")
            sitpoint.Transform:SetPosition(act_pos.x, 0, act_pos.z)
            sitpoint.owner = act.doer
            act.doer.woby.wobytarget = sitpoint
            act.doer.components.talker:Say(GLOBAL.GetString(act.doer, hasfollowers and "ANNOUNCE_TROUP_STAY" or "ANNOUNCE_WOBY_SIT"))
            return true
        end
    end)

wobystay.priority = HIGH_ACTION_PRIORITY
wobystay.rmb = true
wobystay.distance = 36
wobystay.mount_valid = false

local wobyhere = AddAction("WOBY_HERE", "WOBY_HERE", function(act)
        if act.doer and act.doer.woby_commands_classified then
            act.doer.woby_commands_classified:RecallWoby()
        end
        local hasfollowers = false
        if act.doer and act.doer.components.leader then
            for k,v in pairs(act.doer.components.leader.followers) do
                if not k:HasTag("customwobytag") and k.components.follower then
                    if k.brain then
                        k.brain:Stop()
                        k.brain:Start()
                    end
                    if k.components.locomotor then 
                        k.components.locomotor:GoToEntity(act.doer, nil, true)
                    end
                    hasfollowers = true
                end
            end
        end
        if act.doer and act.doer.woby and act.doer.woby.sg.currentstate.name ~= "transform" then
            act.doer.woby.wobytarget = nil
            act.doer.woby.oldwobytarget = nil
            if act.doer.woby.brain then
                act.doer.woby.brain:Stop()
                act.doer.woby.brain:Start()
            end
            if act.doer.woby.sg.currentstate.name ~= "transform" then
                act.doer.woby.sg:GoToState(act.doer.woby:IsNear(act.doer, 3) and act.doer.woby.sg:HasState("woby_does_a_flip") and "woby_does_a_flip" or "bark_clearaction")
            end
            if hasfollowers then
                act.doer.components.talker:Say(GLOBAL.GetString(act.doer, "ANNOUNCE_TROUP_STAY"))
            end
            return true
        end
    end)

wobyhere.priority = HIGH_ACTION_PRIORITY
wobyhere.rmb = true
wobyhere.distance = 36
wobyhere.mount_valid = false

local wobyopen = AddAction("WOBY_OPEN", "WOBY_OPEN", function(act)
        if act.doer.woby then
            if act.doer.woby.components.container:IsOpen() then
                --act.doer.woby.components.container:Close(act.doer)
            else
                act.doer.woby.components.container:Open(act.doer)
            end
        end
    end)

wobyopen.priority = HIGH_ACTION_PRIORITY
wobyopen.rmb = true
wobyopen.distance = 36
wobyopen.mount_valid = true

local wobybark = AddAction("WOBY_BARK", "WOBY_BARK", function(act)
        if act.target then
            if act.target.components.combat then
                --[[if act.doer:HasTag("woby") and act.doer.scarytask == nil then
                    act.doer.scarytask = act.doer:DoTaskInTime(10, function(inst)
                            inst.scarytask = nil
                        end)
                    
                    local x, y, z = act.target.Transform:GetWorldPosition()
                    local ents = GLOBAL.TheSim:FindEntities(x, y, z, 10, { "_combat" }, { "companion" })
                    for i, v in ipairs(ents) do
                        if v.components.hauntable ~= nil and v.components.hauntable.panicable and not
                        (v.components.follower ~= nil and v.components.follower:GetLeader() and v.components.follower:GetLeader():HasTag("player")) then
                            v.components.hauntable:Panic(TUNING.BATTLESONG_PANIC_TIME)
                            AddEnemyDebuffFx("battlesong_instant_panic_fx", v)
                        end
                    end
                
                    act.target:AddDebuff("bigwoby_debuff", "bigwoby_debuff")
                    
                    
                    act.doer.components.hunger:DoDelta(-5) 
                end]]
                
                act.target.components.combat:SetTarget(act.doer)
                --act.target.components.combat:SuggestTarget(act.doer)
                return true
            end
        end
    end)

wobybark.distance = 10
wobybark.mount_valid = false

GLOBAL.STRINGS.ACTIONS.WIXIE_TAUNT = "Taunt!"
local wixie_taunt = AddAction("WIXIE_TAUNT", "WIXIE_TAUNT", function(act)
        --print(act.doer, act.target)
        if act.doer and act.target then
            act.doer.wixie_taunt_target = act.target
            --print("do taunt")
        end
    end)

wixie_taunt.priority = HIGH_ACTION_PRIORITY
wixie_taunt.rmb = true
wixie_taunt.distance = 36
wixie_taunt.mount_valid = false

GLOBAL.STRINGS.ACTIONS.WIXIE_SLINGSHOT = "Shoot"
local wixie_slingshot = GLOBAL.Action({priority = -1, rmb = true, distance = 40, mount_valid = true})
wixie_slingshot.id = "WIXIE_SLINGSHOT"
wixie_slingshot.str = GLOBAL.STRINGS.ACTIONS.WIXIE_SLINGSHOT
wixie_slingshot.fn = function(act)
    local staff = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local act_pos = act:GetActionPoint()
    if staff and staff.components.spellcaster then
        if staff.components.itemmimic and staff.components.itemmimic.fail_as_invobject then
            return false, "ITEMMIMIC"
        end

        local can_cast, cant_cast_reason = staff.components.spellcaster:CanCast(act.doer, act.target, act_pos)
        if can_cast then
            staff.components.spellcaster:CastSpell(act.target, act_pos, act.doer)
            return true
        end
        return can_cast, cant_cast_reason
    end
end

AddAction(wixie_slingshot)

AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(GLOBAL.EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local POINT, EQUIPPED = COMPONENT_ACTIONS.POINT, COMPONENT_ACTIONS.EQUIPPED
        if POINT then
            local OldPOINT_fn = POINT["spellcaster"]
            if OldPOINT_fn then
                POINT["spellcaster"] = function(inst, doer, pos, actions, right, target, ...)
                    if doer:HasTag("troublemaker") and inst:HasTag("wixie_weapon") then
                        if not right then
                            return
                        end
                        local cast_on_water = inst:HasTag("castonpointwater")
                        if inst:HasTag("castonpoint") then
                            local px, py, pz = pos:Get()
                            if GLOBAL.TheWorld.Map:IsAboveGroundAtPoint(px, py, pz, cast_on_water) and not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, GLOBAL.ACTIONS.WIXIE_SLINGSHOT)
                            end
                        elseif cast_on_water then
                            local px, py, pz = pos:Get()
                            if GLOBAL.TheWorld.Map:IsOceanAtPoint(px, py, pz, false) and not GLOBAL.TheWorld.Map:IsGroundTargetBlocked(pos) and not doer:HasAnyTag("steeringboat", "rotatingboat") then
                                table.insert(actions, GLOBAL.ACTIONS.WIXIE_SLINGSHOT)
                            end
                        end
                        return
                    end
                    return OldPOINT_fn(inst, doer, pos, actions, right, target, ...)
                end
            end
        end
        if EQUIPPED then
            local OldEQUIPPED_fn = EQUIPPED["spellcaster"]
            if OldEQUIPPED_fn then
                EQUIPPED["spellcaster"] = function(inst, doer, target, actions, right, ...)
                    if doer:HasTag("troublemaker") and inst:HasTag("wixie_weapon") then
                        if right and (inst:HasTag("castontargets") or (target:HasTag("locomotor") and (inst:HasTag("castonlocomotors")
                            or (inst:HasTag("castonlocomotorspvp") and (target == doer or GLOBAL.TheNet:GetPVPEnabled() or not (target:HasTag("player") and doer:HasTag("player"))))))
                            or (inst:HasTag("castoncombat") and doer.replica.combat and doer.replica.combat:CanTarget(target))) then
                            table.insert(actions, GLOBAL.ACTIONS.WIXIE_SLINGSHOT)
                        end
                        return
                    end
                    return OldEQUIPPED_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
    end
end)

local _OldWhistle = GLOBAL.ACTIONS.WHISTLE.fn
GLOBAL.ACTIONS.WHISTLE.fn = function(act)
    --print("Whistle")
    if act.doer and act.doer.woby then
        act.doer.woby.wobytarget = nil
        act.doer.woby.oldwobytarget = nil
        if act.doer.woby.brain then
            act.doer.woby.brain:Stop()
            act.doer.woby.brain:Start()
        end
    end
    return _OldWhistle(act)
end

local _OldDirectCourier = GLOBAL.ACTIONS.DIRECTCOURIER_MAP.fn

GLOBAL.ACTIONS.DIRECTCOURIER_MAP.fn = function(act)
    --print("Direct Courier")
    if act.doer and act.doer.woby then
        act.doer.woby.wobytarget = nil
        act.doer.woby.oldwobytarget = nil
        if act.doer.woby.brain then
            act.doer.woby.brain:Stop()
            act.doer.woby.brain:Start()
        end
    end
    return _OldDirectCourier(act)
end

GLOBAL.ACTIONS.CAST_NET.mount_valid = false
GLOBAL.ACTIONS.DRY.mount_valid = true
GLOBAL.ACTIONS.ACTIVATE.mount_valid = true
--GLOBAL.ACTIONS.CASTSPELL.distance = 40
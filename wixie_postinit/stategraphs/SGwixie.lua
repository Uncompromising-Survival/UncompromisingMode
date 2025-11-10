local env = env
GLOBAL.setfenv(1, GLOBAL)

require("wixie_shove")

env.AddStategraphPostInit("wilson", function(inst)
    local function DoTalkSound(inst)
        if inst.talksoundoverride ~= nil then
            inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
            return true
        elseif not inst:HasTag("mime") then
            inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/talk_LP", "talk")
            return true
        end
    end

    local function StopTalkSound(inst, instant)
        if not instant and inst.endtalksound ~= nil and inst.SoundEmitter:PlayingSound("talk") then
            inst.SoundEmitter:PlaySound(inst.endtalksound)
        end
        inst.SoundEmitter:KillSound("talk")
    end

    local function ClearStatusAilments(inst)
        if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
            inst.components.freezable:Unfreeze()
        end
        if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
            inst.components.pinnable:Unstick()
        end
    end

    local function ForceStopHeavyLifting(inst)
        if inst.components.inventory:IsHeavyLifting() then
            inst.components.inventory:DropItem(inst.components.inventory:Unequip(EQUIPSLOTS.BODY), true, true)
        end
    end

    local _OldAttack = inst.actionhandlers[ACTIONS.ATTACK].deststate
    inst.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        local weapon = inst.components.combat and inst.components.combat:GetWeapon()
        if inst:HasTag("troublemaker") and weapon and weapon:HasTag("slingshot") then
            inst.sg.mem.localchainattack = not action.forced or nil
            return not (inst.components.rider and inst.components.rider:IsRiding()) and "shove" or "attack"
        end
        return _OldAttack(inst, action, ...)
    end

    local _OldBuild = inst.actionhandlers[ACTIONS.BUILD].deststate
    inst.actionhandlers[ACTIONS.BUILD].deststate = function(inst, action, ...)
        local rec = GetValidRecipe(action.recipe)

        return (inst:HasTag("troublemaker") and inst:HasTag("wixie_ammocraft_1") and rec ~= nil and rec.builder_tag == "pebblemaker" and "domediumaction")
            --or (inst:HasTag("pinetreepioneer") and rec ~= nil and rec.tab.str == "SURVIVAL" and "domediumaction")
            or _OldBuild(inst, action, ...)
    end

    local _OldPick = inst.actionhandlers[ACTIONS.PICK].deststate
    inst.actionhandlers[ACTIONS.PICK].deststate = function(inst, action, ...)
        return (inst.components.rider ~= nil and
                inst.components.rider:IsRiding() and
                inst.components.rider:GetMount() and
                inst.components.rider:GetMount():HasTag("woby") and
                action.target ~= nil and
                action.target.components.pickable ~= nil and
                (action.target.components.pickable.jostlepick and "doshortaction" or
                    action.target.components.pickable.quickpick and "domediumaction"))
            or _OldPick(inst, action, ...)
    end

    local _OldPickUp = inst.actionhandlers[ACTIONS.PICKUP].deststate
    inst.actionhandlers[ACTIONS.PICKUP].deststate = function(inst, action, ...)
        return (inst.components.rider ~= nil and
                inst.components.rider:IsRiding() and
                inst.components.rider:GetMount() and
                inst.components.rider:GetMount():HasTag("woby") and "doshortaction")
            or _OldPickUp(inst, action, ...)
    end

    local actionhandlers = {
        ActionHandler(ACTIONS.WOBY_COMMAND, function(inst, action) return "play_woby_whistle" end),
        ActionHandler(ACTIONS.WOBY_STAY, function(inst, action) return "play_woby_whistle" end),
        ActionHandler(ACTIONS.WOBY_HERE, function(inst, action) return "play_woby_whistle" end),
        ActionHandler(ACTIONS.WOBY_OPEN, function(inst, action) return "doshortaction" end),
        ActionHandler(ACTIONS.WIXIE_TAUNT, function(inst, action)
            if action.target ~= nil then
                inst.wixie_taunt_target = action.target
            end

            inst.wixie_taunt_count = 0

            return "wixie_taunt"
        end),
        ActionHandler(ACTIONS.WIXIE_SLINGSHOT, function(inst, action)
            return action.invobject and (action.invobject:HasTag("slingshot") and inst:HasTag("pebblemaker") and (inst.sg.slingshot_charge and inst.sg:HasStateTag("slingshot_ready") and "slingshot_cast" or "slingshot_charge")
                or action.invobject:HasTag("slingshot_claire") and (inst.components.channelcaster:IsChanneling() and "wixie_slings_a_rock" or "start_channelcast")
                or action.invobject:HasTag("wixiegun") and "wixieshootsagun")
        end)
    }

    local states = {
        State{
            name = "wixie_taunt",
            tags = {"talking", "acting"},

            onenter = function(inst, noanim)
                inst.sg:SetTimeout(2)

                inst.wixie_taunt_count = inst.wixie_taunt_count + 1

                if inst.wixie_taunt_count == 1 then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_WIXIE_TAUNT_1"))
                elseif inst.wixie_taunt_count == 2 then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_WIXIE_TAUNT_2"))
                elseif inst.wixie_taunt_count == 3 then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_WIXIE_TAUNT_3"))
                end

                local function gettalk()
                    if math.random() < 0.5 then
                        return "acting_1"
                    else
                        return "acting_2"
                    end
                end

                if not noanim then
                    inst.AnimState:PlayAnimation(gettalk(), false)
                end

                DoTalkSound(inst)
            end,

            ontimeout = function(inst)
                if inst.wixie_taunt_target ~= nil then
                    if inst.wixie_taunt_target.components.combat ~= nil then
                        inst.wixie_taunt_target.components.combat:SuggestTarget(inst)
                    end

                    if inst.wixie_taunt_count == 1 then
                        inst.wixie_taunt_target:AddDebuff("wixietaunt_debuff", "wixietaunt_debuff", {inflicter = inst})
                    elseif inst.wixie_taunt_count == 2 then
                        inst.wixie_taunt_target:PushEvent("wixie_taunt_lvl2", {inflicter = inst})
                    elseif inst.wixie_taunt_count == 3 then
                        inst.wixie_taunt_target:PushEvent("wixie_taunt_lvl3", {inflicter = inst})
                    end
                end

                local wixie_taunt_level = inst:HasTag("wixie_tauntlevel_3") and 3 or inst:HasTag("wixie_tauntlevel_2") and 2
                    or inst:HasTag("wixie_tauntlevel_1") and 1

                if inst.wixie_taunt_count >= wixie_taunt_level then
                    inst.sg:GoToState("idle")
                else
                    inst.sg:GoToState("wixie_taunt")
                end
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.sg.statemem.talkdone then
                        local function getidle()
                            if math.random() < 0.5 then
                                return "acting_idle1"
                            else
                                return "acting_idle2"
                            end
                        end

                        inst.AnimState:PlayAnimation(getidle())
                        StopTalkSound(inst)
                    else
                        local function gettalk()
                            if math.random() < 0.5 then
                                return "acting_1"
                            else
                                return "acting_2"
                            end
                        end

                        inst.AnimState:PlayAnimation(gettalk())
                        inst.sg.statemem.talkdone = true
                    end
                end),
            },

            onexit = function(inst)
                StopTalkSound(inst)
                inst.sg.statemem.talkdone = false

                if inst.wixie_taunt_count >= 3 then
                    --inst.wixie_taunt_target = nil
                end
            end,
        },

        State {
            name = "shove",
            tags = {"attack", "notalking", "abouttoattack", "autopredict"},

            onenter = function(inst)
                if inst.components.combat:InCooldown() then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end
                if inst.sg.laststate == inst.sg.currentstate then
                    inst.sg.statemem.chained = true
                end
                local buffaction = inst:GetBufferedAction()
                local target = buffaction and buffaction.target or nil
                inst.components.combat:SetTarget(target)
                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()
                local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES
                --cooldown = 24 * FRAMES

                --inst.AnimState:Show("ARM_normal")

                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 24 * FRAMES)

                inst.sg:SetTimeout(cooldown)

                if target then
                    inst.components.combat:BattleCry()
                    if target:IsValid() then
                        inst:FacePoint(target:GetPosition())
                        inst.sg.statemem.attacktarget = target
                        inst.sg.statemem.retarget = target
                    end
                end
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:AddStateTag("idle")
            end,

            events =
            {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                --[[if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                    --inst.AnimState:Show("ARM_carry")
                    --inst.AnimState:Hide("ARM_normal")
                end

                inst:ClearBufferedAction()]]
                inst.components.combat:SetTarget(nil)
                if inst.sg:HasStateTag("abouttoattack") then
                    inst.components.combat:CancelAttack()
                end
            end,
        },

        State {
            name = "slingshot_charge",
            tags = {"abouttoattack", "notalking"},

            onenter = function(inst)
                inst.sg.slingshot_charge = true

                if inst.wixiequickshot == nil then
                    inst.wixiequickshot = false
                end

                if inst.components.combat:InCooldown() and not inst.wixiequickshot then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end

                inst.wixiequickshot = false

                inst.sg.statemem.abouttoattack = true
                inst.framecount = -0.55
                inst.reverseanim = false

                inst.AnimState:PlayAnimation("slingshot_pre")
                --inst:DoTaskInTime(0.5, function(inst)
                --[[inst.chargeshottask = inst:DoPeriodicTask(FRAMES / 2, function(inst)
                    inst.framecount = inst.framecount + (FRAMES * 1.7)
                    if inst.framecount > 0 and inst.framecount < 0.35 then
                        inst.AnimState:SetPercent("slingshot", inst.framecount)
                    end

                    if inst.wixiepointx ~= nil then
                        inst:ForceFacePoint(inst.wixiepointx, inst.wixiepointy, inst.wixiepointz)
                    end
                end)]]
                --end)

                --inst.AnimState:PlayAnimation("wixieshot_pre")
                --inst.AnimState:PushAnimation("wixieshot_loop", true)

                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()

                --inst.sg:SetTimeout(16 * FRAMES)
            end,

            onupdate = function(inst, dt)
                --[[if inst.framecount < 0.35 and not inst.reverseanim then
                inst.framecount = inst.framecount + (FRAMES * 1.5)
            else
                inst.reverseanim = true
                inst.framecount = inst.framecount - (FRAMES)

                if inst.framecount <= 0.2 then
                    inst.reverseanim = false
                end
            end]]
                inst.framecount = inst.framecount + (FRAMES * 1.5)

                if inst.framecount > 0 and inst.framecount < 0.35 then
                    inst.AnimState:SetPercent("slingshot", inst.framecount)
                end

                if inst.wixiepointx ~= nil then
                    inst:ForceFacePoint(inst.wixiepointx, inst.wixiepointy, inst.wixiepointz)
                end
            end,

            timeline =
            {
                TimeEvent(12 * FRAMES, function(inst)
                    --inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
                end),

                TimeEvent(13 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_verylow")
                end),

                TimeEvent(14 * FRAMES, function(inst) -- start of slingshot
                    local fx = SpawnPrefab("dr_warm_loop_1")
                    fx.entity:SetParent(inst.entity)
                    fx.Transform:SetPosition(0, 2.35, 0)
                    fx.Transform:SetScale(0.8, 0.8, 0.8)

                    inst.slingshot_power = 1
                    inst.slingshot_amount = 1
                    inst:ClearBufferedAction()
                    inst.sg:AddStateTag("slingshot_ready")
                end),

                TimeEvent(19 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            inst.slingshot_power = 1
                        else
                            local fx = SpawnPrefab("dr_warm_loop_1")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1.25
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_low")
                        end
                    end
                end),

                TimeEvent(21 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            local fx = SpawnPrefab("dr_warmer_loop")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1
                            inst.slingshot_amount = 2
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_low")
                        end
                    end
                end),

                TimeEvent(24 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            inst.slingshot_power = 1
                        elseif weapon:HasTag("gnasher") then
                            local fx = SpawnPrefab("dr_hot_loop")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 2
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_veryhigh")
                        else
                            local fx = SpawnPrefab("dr_warm_loop_2")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1.5
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_med")
                        end
                    end
                end),

                TimeEvent(28 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            local fx = SpawnPrefab("dr_hot_loop")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1
                            inst.slingshot_amount = 3
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_med")
                        end
                    end
                end),

                TimeEvent(29 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            inst.slingshot_power = 1
                        elseif weapon:HasTag("gnasher") then
                            local fx = SpawnPrefab("dr_warm_loop_2")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1.25
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_low")
                        else
                            local fx = SpawnPrefab("dr_warmer_loop")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 1.75
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_high")
                        end
                    end
                end),

                TimeEvent(34 * FRAMES, function(inst)
                    local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil

                    if weapon ~= nil then
                        if weapon:HasTag("matilda") then
                            inst.slingshot_power = 1
                        elseif weapon:HasTag("gnasher") then
                            local fx = SpawnPrefab("dr_warm_loop_1")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)
                            fx.Transform:SetScale(0.8, 0.8, 0.8)
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_low")
                        else
                            local fx = SpawnPrefab("dr_hot_loop")
                            fx.entity:SetParent(inst.entity)
                            fx.Transform:SetPosition(0, 2.35, 0)

                            inst.slingshot_power = 2
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/slingshot_veryhigh")
                        end
                    end
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:AddStateTag("idle")
            end,

            events =
            {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                --[[EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),]]
            },

            onexit = function(inst)
                inst.sg.slingshot_charge = false

                if inst.sg.statemem.abouttoattack and inst.replica.combat ~= nil then
                    inst.replica.combat:CancelAttack()
                end

                if inst.chargeshottask ~= nil then
                    inst.chargeshottask:Cancel()
                end

                inst.chargeshottask = nil
                inst.framecount = 0
            end,
        },

        State {
            name = "slingshot_cast",
            tags = {"attack", "notalking"},

            onenter = function(inst)
                if inst.components.combat:InCooldown() then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end

                inst.sg.statemem.abouttoattack = true

                --inst.AnimState:PlayAnimation("atk_leap_pre")
                --inst.AnimState:PushAnimation("slingshot_pre")


                --inst.AnimState:PlayAnimation("slingshot", false)


                inst.framecount = 0.35
                --[[inst.chargeshottask = inst:DoPeriodicTask(FRAMES / 2, function(inst)
                    inst.framecount = inst.framecount + (FRAMES * 1.8)
                    if inst.framecount < 1 then
                        inst.AnimState:SetPercent("slingshot", inst.framecount)
                    else
                        inst.sg:GoToState("idle")
                    end

                end)]]
                --inst.AnimState:PlayAnimation("wixieshot", false)

                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()

                --inst.sg:SetTimeout(9 * FRAMES)
            end,

            onupdate = function(inst, dt)
                if inst.wixiepointx ~= nil then
                    inst:ForceFacePoint(inst.wixiepointx, inst.wixiepointy, inst.wixiepointz)
                end
                
                inst.framecount = inst.framecount + (FRAMES * 2)
                if inst.framecount < 1 then
                    inst.AnimState:SetPercent("slingshot", inst.framecount)
                else
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and (equip.components.weapon.projectile ~= nil or equip:HasTag("matilda") and (equip.loaded_projectile1 ~= nil or equip.loaded_projectile2 ~= nil or equip.loaded_projectile3 ~= nil)) then
                        inst.wixiequickshot = true
                        inst.sg:GoToState("slingshot_charge")
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end,

            timeline =
            {
                --[[TimeEvent(7 * FRAMES, function(inst) -- start of slingshot
                inst.sg:RemoveStateTag("busy")
            end),

            TimeEvent(27 * FRAMES, function(inst) -- start of slingshot
                inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/stretch")
            end),]]

                TimeEvent(3 * FRAMES, function(inst)
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and (equip.components.weapon.projectile ~= nil or equip:HasTag("matilda") and (equip.loaded_projectile1 ~= nil or equip.loaded_projectile2 ~= nil or equip.loaded_projectile3 ~= nil)) then
                        inst.sg.statemem.abouttoattack = false

                        if inst.slingshot_power == nil then
                            inst.slingshot_power = 1
                        end

                        if inst.slingshot_amount == nil then
                            inst.slingshot_amount = 1
                        end
                        
                        local gnasher_charged = false
                        
                        if equip ~= nil and equip:HasTag("gnasher") and inst.slingshot_power == 2 then
                            gnasher_charged = true
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/gnasher_bark")
                            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
                        end

                        equip.powerlevel = inst.slingshot_power
                        equip.slingshot_amount = inst.slingshot_amount

                        inst:PerformBufferedAction()

                        inst.slingshot_power = 1
                        inst.slingshot_amount = 1

                        equip.powerlevel = inst.slingshot_power
                        equip.slingshot_amount = inst.slingshot_amount

                        
                        if TUNING.DSTU.DATES.APRIL_FOOLS then
                            inst.SoundEmitter:PlaySound("wixie/characters/wixie/glock")
                        elseif not equip:HasTag("matilda") or equip.loaded_projectile1 ~= nil then
                            inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/shoot")
                        end
                        
                        if gnasher_charged then
                            if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                                inst.wixiequickshot = true
                                inst.sg:GoToState("slingshot_charge")
                            else
                                inst.sg:GoToState("idle")
                            end
                        end
                        
                    elseif not (equip ~= nil and equip:HasTag("matilda")) then -- out of ammo
                        inst:ClearBufferedAction()
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_SLINGHSOT_OUT_OF_AMMO"))
                        inst.SoundEmitter:PlaySound("dontstarve/characters/walter/slingshot/no_ammo")
                    end
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:AddStateTag("idle")
            end,

            events =
            {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.abouttoattack and inst.replica.combat ~= nil then
                    inst.replica.combat:CancelAttack()
                end

                if inst.chargeshottask ~= nil then
                    inst.chargeshottask:Cancel()
                end

                inst.chargeshottask = nil
                inst.framecount = 0
            end,
        },

        State {
            name = "claustrophobic",
            tags = { "busy", "pausepredict", "nomorph", "nodangle", "wixiepanic", "nointerrupt" },

            onenter = function(inst)
                --[[if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")]]
                local panicshield = SpawnPrefab("wixie_panicshield")
                panicshield.Transform:SetPosition(inst.Transform:GetWorldPosition())
                panicshield.host = inst
                --panicshield.entity:SetParent(inst.entity)

                inst.components.sanity:DoDelta(-15)

                ClearStatusAilments(inst)
                ForceStopHeavyLifting(inst)
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()

                if inst.components.rider:IsRiding() then
                    inst.sg:AddStateTag("dismounting")
                    inst.AnimState:PlayAnimation("fall_off")
                    inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
                else
                    inst.AnimState:PlayAnimation("mindcontrol_pre")
                end
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        if inst.sg:HasStateTag("dismounting") then
                            inst.sg:RemoveStateTag("dismounting")
                            inst.components.rider:ActualDismount()
                            inst.AnimState:PlayAnimation("mindcontrol_pre")
                        else
                            inst.sg:GoToState("claustrophobic_loop")
                        end
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg:HasStateTag("dismounting") then
                    --interrupted
                    inst.components.rider:ActualDismount()
                end
                --[[if not inst.sg.statemem.mindcontrolled then
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
            end]]
            end,
        },

        State {
            name = "claustrophobic_loop",
            tags = { "busy", "pausepredict", "nomorph", "nodangle", "wixiepanic", "nointerrupt" },

            onenter = function(inst)
                if not inst.AnimState:IsCurrentAnimation("mindcontrol_loop") then
                    inst.AnimState:PlayAnimation("mindcontrol_loop", true)
                end

                inst.sg:SetTimeout(5)
            end,

            events =
            {
                EventHandler("mindcontrolled", function(inst)
                    inst.sg.statemem.mindcontrolled = true
                    inst.sg:GoToState("mindcontrolled_loop")
                end),
            },

            ontimeout = function(inst)
                inst.sg:GoToState("claustrophobic_pst")
            end,

            --[[onexit = function(inst)
            if not inst.sg.statemem.mindcontrolled then
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
            end
        end,]]
        },

        State {
            name = "claustrophobic_pst",
            tags = { "busy", "pausepredict", "nomorph", "nodangle", "wixiepanic" },

            onenter = function(inst)
                inst.AnimState:PlayAnimation("mindcontrol_pst")
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },

        State {
            name = "play_woby_whistle",
            tags = {"doing", "playing", "busy"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("action_uniqueitem_pre")
                inst.AnimState:PushAnimation("whistle", false)
                
                inst.AnimState:SetDeltaTimeMultiplier(1.5)
                
                inst.AnimState:OverrideSymbol("hound_whistle01", "walterwhistle", "hound_whistle01")
                --inst.AnimState:Hide("ARM_carry")
                inst.AnimState:Show("ARM_normal")
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst)
                    local buffaction = inst:GetBufferedAction()
                    if buffaction ~= nil and buffaction.target ~= nil then
                        if buffaction.target:HasTag("CHOP_workable") then
                            inst.sg:AddStateTag("chopping")
                        elseif buffaction.target:HasTag("MINE_workable") then
                            inst.sg:AddStateTag("mining")
                        end
                    end

                    inst:PerformBufferedAction()
                    inst.SoundEmitter:PlaySound("wixie/characters/wixie/walterwhistle_fast", nil, nil, false)
                end),
                TimeEvent(12 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                
                if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                    inst.AnimState:Show("ARM_carry")
                    inst.AnimState:Hide("ARM_normal")
                end
            end,
        },
        State{
            name = "special_woby_attack",
            tags = { "attack", "notalking", "abouttoattack", "autopredict" },

            onenter = function(inst)
                if inst.components.combat:InCooldown() then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end
                
                if inst.sg.laststate == inst.sg.currentstate then
                    inst.sg.statemem.chained = true
                end
                
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                inst.components.combat:SetTarget(target)
                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()
                local cooldown = inst.components.combat.min_attack_period
                inst.AnimState:PlayAnimation("player_atk_pre")
                inst.AnimState:PushAnimation("player_atk", false)
                
                if equip ~= nil and equip:HasTag("toolpunch") then
                    inst.sg.statemem.istoolpunch = true
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
                    cooldown = math.max(cooldown, 13 * FRAMES)
                elseif equip ~= nil and equip:HasTag("whip") then
                    inst.sg.statemem.iswhip = true
                    inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                    cooldown = math.max(cooldown, 17 * FRAMES)
                elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                    cooldown = math.max(cooldown, 13 * FRAMES)
                else
                    inst.SoundEmitter:PlaySound(
                        (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                        (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                        (equip:HasTag("firepen") and "wickerbottom_rework/firepen/launch") or
                        "dontstarve/wilson/attack_weapon",
                        nil, nil, true
                    )
                    cooldown = math.max(cooldown, 13 * FRAMES)
                end

                inst.sg:SetTimeout(cooldown)

                if target ~= nil then
                    inst.components.combat:BattleCry()
                    if target:IsValid() then
                        inst:FacePoint(target:GetPosition())
                        inst.sg.statemem.attacktarget = target
                        inst.sg.statemem.retarget = target
                    end
                end
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)
                    if not inst.sg.statemem.iswhip then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end),
                TimeEvent(10 * FRAMES, function(inst)
                    if inst.sg.statemem.iswhip then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:AddStateTag("idle")
            end,

            events =
            {
                EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.components.combat:SetTarget(nil)
                if inst.sg:HasStateTag("abouttoattack") then
                    inst.components.combat:CancelAttack()
                end
            end,
        },

        State {
            name = "bark_at",
            tags = {"busy", "canrotate"},

            onenter = function(inst)
                local mount = inst.components.rider:GetMount()
                if mount and mount:HasTag("woby") then
                    inst.AnimState:PlayAnimation("bark1_woby", false)
                else
                    inst.sg:GoToState("mounted_idle")
                end
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("mounted_idle")
                    end
                end),
            },

            timeline =
            {
                TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/walter/woby/big/bark") end),
            },
        },

        State {
            name = "wixie_slings_a_rock",
            tags = {"doing", "canrotate", "busy", "keepchannelcasting"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_prop_pre")
            inst.AnimState:PushAnimation("atk_prop", false)
            end,

            timeline =
            {
                TimeEvent(7 * FRAMES, function(inst)
                    inst:PerformBufferedAction()
                end),
                TimeEvent(10 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },

        State {
            name = "wixieshootsagun",
            tags = {"doing", "canrotate", "busy", "keepchannelcasting"},

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("hand_shoot")
            end,

            timeline =
            {
                TimeEvent(17 * FRAMES, function(inst)
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("busy")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },
        },

        State {
            name = "wixie_spawn",
            tags = {"busy", "pausepredict", "nomorph", "nodangle"},

            onenter = function(inst)
                if inst.components.playercontroller then
                    inst.components.playercontroller:Enable(false)
                    inst.components.playercontroller:RemotePausePrediction()
                end

                inst.sg.statemem.iszoomed = true
                inst:SetCameraZoomed(true)
                inst.components.inventory:Hide()
                inst.components.locomotor:Stop()
            end,

            onexit = function(inst)
                if inst.sg.statemem.iszoomed then
                    inst:SetCameraZoomed(false)
                end
                if inst.components.playercontroller then
                    inst.components.playercontroller:Enable(true)
                end

                inst.components.inventory:Show()
            end,
        },
    }

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

    for k, v in pairs(actionhandlers) do
        assert(v:is_a(ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end
end)
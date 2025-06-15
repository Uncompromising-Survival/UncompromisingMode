local env = env
GLOBAL.setfenv(1, GLOBAL)

require("wixie_shove")

env.AddStategraphPostInit("wilson", function(inst)
    local function ToggleOffPhysics(inst)
        inst.sg.statemem.isphysicstoggle = true
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
    end

    local function ToggleOnPhysics(inst)
        inst.sg.statemem.isphysicstoggle = nil
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(COLLISION.GIANTS)
    end

    local function ClearStatusAilments(inst)
        if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
            inst.components.freezable:Unfreeze()
        end
        if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
            inst.components.pinnable:Unstick()
        end
    end

    local function teleport_end(inst)
        inst.sg.statemem.teleport_task = nil
        inst.sg:GoToState(inst:HasTag("playerghost") and "appear" or "wakeup")
        if inst.components.health ~= nil then
            inst.components.health:SetInvincible(false)
        end
    end

    local function getrandomposition(caster, teleportee, target_in_ocean)
        if target_in_ocean then
            local pt = TheWorld.Map:FindRandomPointInOcean(20)
            if pt ~= nil then
                return pt
            end
            local from_pt = teleportee:GetPosition()
            local offset = FindSwimmableOffset(from_pt, math.random() * 2 * PI, 90, 16)
                or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 60, 16)
                or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 30, 16)
                or FindSwimmableOffset(from_pt, math.random() * 2 * PI, 15, 16)
            if offset ~= nil then
                return from_pt + offset
            end
            return teleportee:GetPosition()
        else
            local centers = {}
            for i, node in ipairs(TheWorld.topology.nodes) do
                if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y) and node.type ~= NODE_TYPE.SeparatedRoom then
                    table.insert(centers, { x = node.x, z = node.y })
                end
            end
            if #centers > 0 then
                local pos = centers[math.random(#centers)]
                return Point(pos.x, 0, pos.z)
            else
                return caster:GetPosition()
            end
        end
    end

    local function ForceStopHeavyLifting(inst)
        if inst.components.inventory:IsHeavyLifting() then
            inst.components.inventory:DropItem(
                inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
                true,
                true
            )
        end
    end

    local function DoHurtSound(inst)
        if inst.hurtsoundoverride ~= nil then
            inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
        elseif not inst:HasTag("mime") then
            inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") ..
                (inst.soundsname or inst.prefab) .. "/hurt", nil, inst.hurtsoundvolume)
        end
    end

    local function StopTalkSound(inst, instant)
        if not instant and inst.endtalksound ~= nil and inst.SoundEmitter:PlayingSound("talk") then
            inst.SoundEmitter:PlaySound(inst.endtalksound)
        end
        inst.SoundEmitter:KillSound("talk")
    end

    local function DoTalkSound(inst)
        if inst.talksoundoverride ~= nil then
            inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
            return true
        elseif not inst:HasTag("mime") then
            inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") ..
                (inst.soundsname or inst.prefab) .. "/talk_LP", "talk")
            return true
        end
    end

    local function DoMockAttack(inst)
        local target = inst.components.combat ~= nil and inst.components.combat.target
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if equip ~= nil and target ~= nil and target.components.health ~= nil and not target.components.health:IsDead() then
            inst.components.combat:DoNaughtAttack(target)
        end
    end


    local SLEEPREPEL_MUST_TAGS = { "_combat" }
    local SLEEPREPEL_CANT_TAGS = { "player", "companion", "abigail", "shadow", "playerghost", "INLIMBO", "wixieshoved", "invisible",
        "hiding", "NOTARGET", "flight", "toadstool" }

    local function Check_Bowling(inst)
        if inst ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()

            local ents = TheSim:FindEntities(x, y, z, 3.5, SLEEPREPEL_MUST_TAGS, SLEEPREPEL_CANT_TAGS)

            for i, v in ipairs(ents) do
                v:AddTag("wixieshoved")
                SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(v.Transform:GetWorldPosition())

                if v.components.combat ~= nil then
                    v.components.combat:GetAttacked(inst, 0)
                end

                if v.components.locomotor ~= nil and not v:HasTag("stageusher") then
                    for i = 1, 50 do
                        v:DoTaskInTime((i - 1) / 50, function(v)
                            if v ~= nil and inst ~= nil then
                                local x, y, z = inst.Transform:GetWorldPosition()
                                local tx, ty, tz = v.Transform:GetWorldPosition()

                                local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
                                local velx = math.cos(rad)  --* 4.5
                                local velz = -math.sin(rad) --* 4.5

                                local giantreduction = v:HasTag("epic") and 1.5 or v:HasTag("smallcreature") and 0.8 or 1
                                local cursemultiplier = v:HasDebuff("wixiecurse_debuff") and 1.75 or 1.25
                                local shovevalue = inst:HasTag("troublemaker") and 3 or 2

                                local dx, dy, dz =
                                    tx + (((shovevalue / (i + 3)) * velx) / giantreduction) * cursemultiplier, ty,
                                    tz + (((shovevalue / (i + 3)) * velz) / giantreduction) * cursemultiplier
                                local ground = TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
                                local boat = TheWorld.Map:GetPlatformAtPoint(dx, dz)
                                local ocean_collision = TheWorld.Map:IsOceanAtPoint(dx, dy, dz)

                                if not (v.sg ~= nil and (v.sg:HasStateTag("swimming") or v.sg:HasStateTag("invisible"))) then
                                    if v ~= nil and dx ~= nil and (ground or boat or ocean_collision and v.components.locomotor:CanPathfindOnWater() or v.components.tiletracker ~= nil and not v:HasTag("whale")) then
                                        --[[if ocean_collision and v.components.amphibiouscreature and not v.components.amphibiouscreature.in_water then
                                                v.components.amphibiouscreature:OnEnterOcean()
                                            end]]
                                        v.Transform:SetPosition(dx, dy, dz)
                                    end
                                end

                                if i >= 50 then
                                    v:RemoveTag("wixieshoved")
                                end
                            end
                        end)
                    end
                end
            end
        end
    end

    local events =
    {
        EventHandler("sneeze", function(inst, data)
            if not inst.components.health:IsDead() and not inst.components.health.invincible then
                --[[ if inst.sg:HasStateTag("busy") and inst.sg.currentstate.name ~= "emote" then
                inst.wantstosneeze = true
            else]]
                inst.wantstosneeze = true
                inst.sg:GoToState("sneeze")
                -- end
            end
        end),

        EventHandler("dreadeye_spooked", function(inst)
            if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead() or inst.components.rider:IsRiding()) then
                inst.sg:GoToState("dreadeye_spooked")
            end
        end)
    }

    local _OldSpellCast = inst.actionhandlers[ACTIONS.CASTSPELL].deststate
    inst.actionhandlers[ACTIONS.CASTSPELL].deststate =
        function(inst, action, ...)
            if action.invobject ~= nil then
                if action.invobject:HasTag("lighter") then
                    return "castspelllighter"
                elseif action.invobject:HasTag("charles_t_horse") then
                    if action.invobject.components.fueled:GetPercent() >= 0.2 then
                        if inst.components.rider and inst.components.rider:IsRiding() then
                            inst.components.rider:Dismount()
                        else
                            return "charles_charge"
                        end
                    else
                        return
                    end
                elseif action.invobject:HasTag("beargerclaw") then
                    if inst.components.rider and inst.components.rider:IsRiding() then
                        inst.components.rider:Dismount()
                    else
                        return "bearclaw_dig_start"
                    end
                elseif action.invobject:HasTag("beegun") then
                    return "collectthebees"
                end
            end
            return _OldSpellCast(inst, action, ...)
        end

    local _OldPlay = inst.actionhandlers[ACTIONS.PLAY].deststate
    inst.actionhandlers[ACTIONS.PLAY].deststate =
        function(inst, action, ...)
            if action.invobject ~= nil then
                if action.invobject:HasTag("pied_piper_flute") then
                    return "play_pied_piper_flute"
                end
            end
            return _OldPlay(inst, action, ...)
        end

    local _OldChannel = inst.actionhandlers[ACTIONS.STARTCHANNELING].deststate
    inst.actionhandlers[ACTIONS.STARTCHANNELING].deststate =
        function(inst, action, ...)
            if action.target and action.target.components.channelable and
                action.target.components.channelable.use_channel_longaction_noloop then
                return "dostandingaction"
            else
                return _OldChannel(inst, action, ...)
            end
        end

    local _OldAttackState = inst.actionhandlers[ACTIONS.ATTACK].deststate
    inst.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action, ...)
        local weapon = inst.components.combat and inst.components.combat:GetWeapon()
        if weapon and weapon:HasTag("beegun") then
            if inst.sg.laststate.name == "beegun" or inst.sg.laststate.name == "beegun_short" then
                return "beegun_short"
            else
                return "beegun"
            end
        else
            return _OldAttackState(inst, action, ...)
        end
    end

    local _OldCast_Net = inst.actionhandlers[ACTIONS.CAST_NET].deststate
    inst.actionhandlers[ACTIONS.CAST_NET].deststate = function(inst, action, ...)
        if inst then
            return "cast_net_fixed"
        else
            return _OldCast_Net(inst, action, ...)
        end
    end

    local _OldDeathEvent = inst.events["death"].fn
    inst.events["death"].fn = function(inst, data)
        inst.components.health:DeltaPenalty(0.25) -- ALL deaths cause 25% penalty....
        if data ~= nil and data.cause == "shadowvortex" and not inst:HasTag("wereplayer") then
            inst.components.rider:ActualDismount()
            inst.sg:GoToState("blackpuddle_death")
        elseif data ~= nil and (data.cause == "mindweaver" or data.cause == "um_tornado") and not inst:HasTag("wereplayer") then
            inst.components.rider:ActualDismount()
            inst.sg:GoToState("rne_player_grabbed")
        else
            _OldDeathEvent(inst, data)
        end
    end
    
    
    local function FindBlueFuncap(inst)
        local helm = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if helm and helm.prefab == "blue_mushroomhat" then
            return helm
        end
    end
    --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    -- Blue Funcap Changes!
    -- Upgrade
    local _OldUpgrade = inst.actionhandlers[ACTIONS.UPGRADE].deststate
    inst.actionhandlers[ACTIONS.UPGRADE].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 or (action and action.target and action.target.prefab == "nightmarefuel") then
            inst.temp_speed_mod = (inst:HasTag("hungrybuilder") and 0.5)
                or (inst:HasTag("fastbuilder") and 0.05)
                or (inst:HasTag("slowbuilder") and 2)
                or 1
            if (action and action.target and action.target.prefab == "nightmarefuel") then
                inst.temp_speed_mod = 0.8
            end
            return "bluecap_general_action"
        end
        return _OldUpgrade(inst, action, ...)
    end
    -- Build
    local _OldBuild = inst.actionhandlers[ACTIONS.BUILD].deststate
    inst.actionhandlers[ACTIONS.BUILD].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            inst.temp_speed_mod = (inst:HasTag("hungrybuilder") and 0.5)
                or (inst:HasTag("fastbuilder") and 0.05)
                or (inst:HasTag("slowbuilder") and 2)
                or 1
            return "bluecap_general_action"
        end
        return _OldBuild(inst, action, ...)
    end
    -- Pick
    local _OldPick = inst.actionhandlers[ACTIONS.PICK].deststate
    inst.actionhandlers[ACTIONS.PICK].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            inst.temp_speed_mod = (action.target and action.target:HasTag("noquickpick") and 1) or -- Get Speed Mod
            (inst:HasTag("farmplantfastpicker") and action.target ~= nil and action.target:HasTag("farm_plant") and 0.7) or
            (inst.components.rider ~= nil and inst.components.rider:IsRiding() and (
                (inst:HasTag("woodiequickpicker") and "dowoodiefastpick") or
                1
            )) or
            (
                action.target ~= nil and
                (action.target.components.pickable ~= nil and
                (
                    (action.target.components.pickable.jostlepick and 1) or
                    (action.target.components.pickable.quickpick and 1) or
                    (inst:HasTag("fastpicker") and 0.7) or
                    (inst:HasTag("woodiequickpicker") and 0.7) or
                    (inst:HasTag("quagmire_fasthands") and 0.7) or
                    1
                )) or
                (action.target.components.searchable ~= nil and
                (
                    (action.target.components.searchable.jostlesearch and 1) or
                    (action.target.components.searchable.quicksearch and 1) or
                    1
                ))
            )
            if (action.target.components.pickable ~= nil and ((action.target.components.pickable.jostlepick) or (action.target.components.pickable.quickpick))) or
                (action.target.components.searchable ~= nil and ((action.target.components.searchable.jostlesearch) or (action.target.components.searchable.quicksearch))) then
                
                return "bluecap_fast_action"
            else
                return "bluecap_general_action"
            end
        end
        return _OldPick(inst, action, ...)
    end
    -- Pick up
    local _OldPickup = inst.actionhandlers[ACTIONS.PICKUP].deststate
    inst.actionhandlers[ACTIONS.PICKUP].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return (inst.components.rider ~= nil and inst.components.rider:IsRiding()
                    and (action.target ~= nil and action.target:HasTag("heavy") and "dodismountaction"
                        or "bluecap_general_action")
                    )
                or (action.target ~= nil and action.target:HasTag("minigameitem") and "dosilentshortaction")
                or "bluecap_fast_action"
        end
        return _OldPickup(inst, action, ...)
    end
    -- Chop
    local _OldChop = inst.actionhandlers[ACTIONS.CHOP].deststate
    inst.actionhandlers[ACTIONS.CHOP].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            if inst:HasTag("beaver") then
                return "bluecap_gnaw"
            end
            return not inst.sg:HasStateTag("prechop")
                and (inst.sg:HasStateTag("chopping") and
                    "bluecap_chop" or
                    "bluecap_chop_start")
                or nil
        end
        return _OldChop(inst, action, ...)
    end
    -- Mine
    local _OldMine = inst.actionhandlers[ACTIONS.MINE].deststate
    inst.actionhandlers[ACTIONS.MINE].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            if inst:HasTag("beaver") then
                return "bluecap_gnaw"
            end
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mine") and
                    "bluecap_mine" or
                    "bluecap_mine_start")
                or nil
        end
        return _OldMine(inst, action, ...)
    end
    -- Hammer
    local _OldHammer = inst.actionhandlers[ACTIONS.HAMMER].deststate
    inst.actionhandlers[ACTIONS.HAMMER].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            if inst:HasTag("beaver") then
                return "bluecap_gnaw"
            end
            return not inst.sg:HasStateTag("prehammer")
                and (inst.sg:HasStateTag("hammering") and
                    "bluecap_hammer" or
                    "bluecap_hammer_start")
                or nil
        end
        return _OldHammer(inst, action, ...)
    end
    -- Dig
    local _OldDig = inst.actionhandlers[ACTIONS.DIG].deststate
    inst.actionhandlers[ACTIONS.DIG].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            if inst:HasTag("beaver") then
                return "bluecap_gnaw"
            end
            return not inst.sg:HasStateTag("predig")
            and (inst.sg:HasStateTag("digging") and
                "bluecap_dig" or
                "bluecap_dig_start")
                or nil
        end
        return _OldDig(inst, action, ...)
    end
    -- Till
    local _OldTill = inst.actionhandlers[ACTIONS.TILL].deststate
    inst.actionhandlers[ACTIONS.TILL].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_till_start"
        end
        return _OldTill(inst, action, ...)
    end
    -- Terraform
    local _OldTerraform = inst.actionhandlers[ACTIONS.TERRAFORM].deststate
    inst.actionhandlers[ACTIONS.TERRAFORM].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_terraform"
        end
        return _OldTerraform(inst, action, ...)
    end
    -- Bugnet
    local _OldBugnet = inst.actionhandlers[ACTIONS.NET].deststate
    inst.actionhandlers[ACTIONS.NET].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return not inst.sg:HasStateTag("prenet") and (inst.sg:HasStateTag("netting") and "bluecap_bugnet" or "bluecap_bugnet_start") or nil
        end
        return _OldBugnet(inst, action, ...)
    end
    -- Deploy
    local _OldDeploy = inst.actionhandlers[ACTIONS.DEPLOY].deststate
    inst.actionhandlers[ACTIONS.DEPLOY].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_fast_action"
        end
        return _OldDeploy(inst, action, ...)
    end
    -- Deploy Tile Arrive
    local _OldDeploy_TileArrive = inst.actionhandlers[ACTIONS.DEPLOY_TILEARRIVE].deststate
    inst.actionhandlers[ACTIONS.DEPLOY_TILEARRIVE].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_fast_action"
        end
        return _OldDeploy_TileArrive(inst, action, ...)
    end
    -- Store
    local _OldStore  = inst.actionhandlers[ACTIONS.STORE].deststate
    inst.actionhandlers[ACTIONS.STORE].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_fast_action"
        end
        return _OldStore(inst, action, ...)
    end
    -- Drop
    local _OldDrop  = inst.actionhandlers[ACTIONS.DROP].deststate
    inst.actionhandlers[ACTIONS.DROP].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return inst.components.inventory:IsHeavyLifting()
                and not inst.components.rider:IsRiding()
                and "heavylifting_drop"
                or "bluecap_fast_action"
        end
        return _OldDrop(inst, action, ...)
    end
    -- Row
    local _OldRow  = inst.actionhandlers[ACTIONS.ROW].deststate
    inst.actionhandlers[ACTIONS.ROW].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_row"
        end
        return _OldRow(inst, action, ...)
    end
    -- Heal
    local _OldHeal  = inst.actionhandlers[ACTIONS.HEAL].deststate
    inst.actionhandlers[ACTIONS.HEAL].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            return "bluecap_general_action"
        end
        return _OldHeal(inst, action, ...)
    end

    -- Need this for eating state:

    local function TryResumePocketRummage(inst)
        local item = inst.sg.mem.pocket_rummage_item
        if item then
            if item.components.container and
                item.components.container:IsOpenedBy(inst) and
                item.components.inventoryitem and
                item.components.inventoryitem:GetGrandOwner() == inst
            then
                inst.sg.statemem.keep_pocket_rummage_mem_onexit = true
                inst.sg:GoToState("start_pocket_rummage", item)
                return true
            end
            inst.sg.mem.pocket_rummage_item = nil
        end
        return false
    end
    --Call this when exiting a "keep_pocket_rummage" state
    local function CheckPocketRummageMem(inst)
        local item = inst.sg.mem.pocket_rummage_item
        if item then
            if not (item.components.container and
                    item.components.container:IsOpenedBy(inst) and
                    item.components.inventoryitem and
                    item.components.inventoryitem:GetGrandOwner() == inst)
            then
                SetPocketRummageMem(inst, nil)
            else
                local stayopen = inst.sg.statemem.keep_pocket_rummage_mem_onexit
                if not stayopen and inst.sg.statemem.is_going_to_action_state then
                    local buffaction = inst:GetBufferedAction()
                    if buffaction and
                        (buffaction.action == ACTIONS.BUILD or
                            (buffaction.invobject and
                                buffaction.invobject.components.inventoryitem and
                                buffaction.invobject.components.inventoryitem:IsHeldBy(item)
                            )
                        )
                    then
                        stayopen = true
                    end
                end
                if not stayopen then
                    ClosePocketRummageMem(inst)
                end
            end
        end
    end

    -- Eat
    local _OldEat  = inst.actionhandlers[ACTIONS.EAT].deststate
    inst.actionhandlers[ACTIONS.EAT].deststate = function(inst, action, ...)
        local funcap = FindBlueFuncap(inst)
        if funcap and funcap.charge > 0 then
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if not obj then
                return
            elseif obj.components.edible then
                if not inst.components.eater:PrefersToEat(obj) then
                    inst:PushEvent("wonteatfood", {food = obj})
                    return
                end
            elseif obj.components.soul then
                if not inst.components.souleater then
                    inst:PushEvent("wonteatfood", {food = obj})
                    return
                end
            else
                return
            end
            return (obj.components.soul or obj.components.edible.foodtype == FOODTYPE.MEAT) and "bluecap_eat"
                or "bluecap_quickeat"
        end
        return _OldEat(inst, action, ...)
    end

    --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    local actionhandlers =
    {
        --[[ActionHandler(ACTIONS.CASTSPELL,
        function(inst, action)
            return action.invobject ~= nil"
                and action.invobject:HasTag("lighter") and "castspelllighter"
                or _OldSpellCast
        end),]]
        ActionHandler(ACTIONS.CASTLIGHTER,
            function(inst, action)
                return action.invobject ~= nil
                    and action.invobject:HasTag("lighter") and "castspelllighter"
            end),
        ActionHandler(ACTIONS.WINGSUIT,
            function(inst, action)
                return (inst.sg.currentstate.name == "wingsuit_loop" or inst.sg.currentstate.name == "wingsuit_pst" or inst.sg.currentstate.name == "wingsuit_pre")
                and "wingsuit_pre_quick" 
                or "wingsuit_pre"
            end),
        ActionHandler(ACTIONS.CREATE_BURROW,
            function(inst, action)
                return "dolongaction"
            end),
        ActionHandler(ACTIONS.UM_ACTIVATABLE_ITEM,
            function(inst, action)
                return "doshortaction"
            end),
        ActionHandler(ACTIONS.CHARGE_POWERCELL,
            function(inst, action)
                return action.invobject ~= nil and action.invobject:HasTag("powercell") and "doshortaction"
            end),
        ActionHandler(ACTIONS.SET_CUSTOM_NAME, "doshortaction"),
    }

    local _OldIdleState = inst.states["idle"].onenter
    inst.states["idle"].onenter = function(inst, pushanim)
        if inst.wantstosneeze then
            inst.sg:GoToState("sneeze")
        else
            _OldIdleState(inst, pushanim)
        end
    end

    local _OldEatState = inst.states["eat"].onenter
    inst.states["eat"].onenter = function(inst, foodinfo)
        if inst.wantstosneeze then
            inst.sg:GoToState("sneeze")
        else
            _OldEatState(inst, foodinfo)
        end
    end

    local _dolongaction_onexit = inst.states["dolongaction"].onexit
    inst.states["dolongaction"].onexit = function(inst)
        inst.AnimState:SetDeltaTimeMultiplier(1)
        _dolongaction_onexit(inst)
    end

    local states = {
        State {
            name = "castspelllighter",
            tags = { "doing", "busy", "canrotate" },

            onenter = function(inst)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(false)
                end
                inst.AnimState:PlayAnimation("staff_pre")
                inst.AnimState:PushAnimation("staff", false)
                inst.components.locomotor:Stop()

                --Spawn an effect on the player's location
                local staff = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                local colour = staff ~= nil and staff.fxcolour or { 1, 1, 1 }
                --[[
            inst.sg.statemem.stafffx = SpawnPrefab(inst.components.rider:IsRiding() and "staffcastfx_mount" or "frog")
            inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
            inst.sg.statemem.stafffx.Transform:SetRotation(inst.Transform:GetRotation())
            inst.sg.statemem.stafffx:SetUp(colour)
            ]]
                inst.sg.statemem.stafflight = SpawnPrefab("staff_castinglight")
                inst.sg.statemem.stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
                inst.sg.statemem.stafflight:SetUp(colour, 1.9, .33)

                if staff ~= nil and staff.components.aoetargeting ~= nil and
                    staff.components.aoetargeting.targetprefab ~= nil then
                    local buffaction = inst:GetBufferedAction()
                    if buffaction ~= nil and buffaction.pos ~= nil then
                        inst.sg.statemem.targetfx = SpawnPrefab(staff.components.aoetargeting.targetprefab)
                        if inst.sg.statemem.targetfx ~= nil then
                            inst.sg.statemem.targetfx.Transform:SetPosition(buffaction:GetActionPoint():Get())
                            inst.sg.statemem.targetfx:ListenForEvent("onremove", OnRemoveCleanupTargetFX, inst)
                        end
                    end
                end

                inst.sg.statemem.castsound = staff ~= nil and staff.castsound or "dontstarve/wilson/use_gemstaff"
            end,

            timeline =
            {
                TimeEvent(13 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.castsound)
                end),
                TimeEvent(53 * FRAMES, function(inst)
                    if inst.sg.statemem.targetfx ~= nil then
                        if inst.sg.statemem.targetfx:IsValid() then
                            OnRemoveCleanupTargetFX(inst)
                        end
                        inst.sg.statemem.targetfx = nil
                    end
                    inst.sg.statemem.stafffx = nil    --Can't be cancelled anymore
                    inst.sg.statemem.stafflight = nil --Can't be cancelled anymore
                    --V2C: NOTE! if we're teleporting ourself, we may be forced to exit state here!
                    inst:PerformBufferedAction()
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
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                if inst.sg.statemem.stafffx ~= nil and inst.sg.statemem.stafffx:IsValid() then
                    inst.sg.statemem.stafffx:Remove()
                end
                if inst.sg.statemem.stafflight ~= nil and inst.sg.statemem.stafflight:IsValid() then
                    inst.sg.statemem.stafflight:Remove()
                end
                if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
                    OnRemoveCleanupTargetFX(inst)
                end
            end,
        },

        State {
            name = "bearclaw_dig_start",
            tags = { "predig", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("shovel_pre")
            end,

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("bearclaw_dig")
                    end
                end),
            },
        },

        State {
            name = "bearclaw_dig",
            tags = { "busy", "attack" },

            onenter = function(inst)
                inst.AnimState:PlayAnimation("shovel_loop")
            end,

            timeline =
            {
                TimeEvent(15 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                    inst:PerformBufferedAction()
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation("shovel_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },
        },


        State {
            name = "curse_controlled",
            tags = { "busy", "pausepredict", "nomorph", "nodangle" },

            onenter = function(inst)
                if not inst.AnimState:IsCurrentAnimation("mindcontrol_loop") then
                    inst.AnimState:PlayAnimation("mindcontrol_loop", true)
                end
                inst.sg:SetTimeout(2)
            end,

            events =
            {
                EventHandler("mindcontrolled", function(inst)
                    inst.sg.statemem.mindcontrolled = true
                    inst.sg:GoToState("mindcontrolled_loop")
                end),
            },

            ontimeout = function(inst)
                inst.sg:GoToState("mindcontrolled_pst")
            end,

            onexit = function(inst)
                if not inst.sg.statemem.mindcontrolled then
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                    inst.components.inventory:Show()
                end
            end,
        },

        State {
            name = "sneeze",
            tags = { "busy", "sneeze", "pausepredict" },

            onenter = function(inst)
                local usehit = inst.components.rider:IsRiding() or inst:HasTag("wereplayer")
                local stun_frames = usehit and 6 or 9
                inst.wantstosneeze = false
                inst:ClearBufferedAction()
                inst.components.locomotor:Stop()
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit", nil, .02)


                if inst.components.rider ~= nil and not inst.components.rider:IsRiding() then
                    inst.AnimState:PlayAnimation("sneeze")
                end

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction(stun_frames <= 7 and stun_frames or nil)
                end


                if inst.prefab ~= "wes" then
                    inst.SoundEmitter:PlaySound("UCSounds/Sneeze/sneeze")
                    local sound_name = inst.soundsname or inst.prefab
                    local path = inst.talker_path_override or "dontstarve/characters/"
                    --local equippedHat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                    --if equippedHat and equippedHat:HasTag("muffler") then
                    --inst.SoundEmitter:PlaySound(path..sound_name.."/gasmask_hurt")
                    --else
                    local sound_event = path .. sound_name .. "/hurt"
                    inst.SoundEmitter:PlaySound(inst.hurtsoundoverride or sound_event)
                    --end

                    inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_SNEEZE"))
                end
            end,

            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst)
                    if inst.components.hayfever then
                        inst.components.hayfever:DoSneezeEffects()
                    end
                    inst.sg:RemoveStateTag("busy")
                end),
            },

        },

        State {
            name = "play_pied_piper_flute",
            tags = { "doing", "playing" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("action_uniqueitem_pre")
                inst.AnimState:PushAnimation("whistle", false)
                inst.AnimState:OverrideSymbol("hound_whistle01", "pied_piper_flute", "hound_whistle01")
                --inst.AnimState:Hide("ARM_carry")
                inst.AnimState:Show("ARM_normal")
                inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and
                    inst.bufferedaction.invobject or nil)
            end,

            timeline =
            {
                TimeEvent(20 * FRAMES, function(inst)
                    if inst:PerformBufferedAction() then
                        inst.SoundEmitter:PlaySound("UCSounds/piedpiper/play")
                    else
                        inst.AnimState:SetTime(34 * FRAMES)
                    end
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
                if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                    inst.AnimState:Show("ARM_carry")
                    inst.AnimState:Hide("ARM_normal")
                end
            end,
        },

        State {
            name = "force_klaus_attack",
            tags = { "busy", "attack", "notalking", "abouttoattack", "autopredict" },

            onenter = function(inst)
                if inst.components.combat:InCooldown() then
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle", true)
                    return
                end
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                inst.components.combat:SetTarget(target)
                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()
                local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES
                if inst.components.rider:IsRiding() then
                    if equip ~= nil and (equip.components.projectile ~= nil or equip:HasTag("rangedweapon")) then
                        inst.AnimState:PlayAnimation("player_atk_pre")
                        inst.AnimState:PushAnimation("player_atk", false)

                        if (equip.projectiledelay or 0) > 0 then
                            --V2C: Projectiles don't show in the initial delayed frames so that
                            --     when they do appear, they're already in front of the player.
                            --     Start the attack early to keep animation in sync.
                            inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                            if inst.sg.statemem.projectiledelay > FRAMES then
                                inst.sg.statemem.projectilesound =
                                    (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                    (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                    "dontstarve/wilson/attack_weapon"
                            elseif inst.sg.statemem.projectiledelay <= 0 then
                                inst.sg.statemem.projectiledelay = nil
                            end
                        end
                        if inst.sg.statemem.projectilesound == nil then
                            inst.SoundEmitter:PlaySound(
                                (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                "dontstarve/wilson/attack_weapon",
                                nil, nil, true
                            )
                        end
                        cooldown = math.max(cooldown, 13 * FRAMES)
                    else
                        inst.AnimState:PlayAnimation("atk_pre")
                        inst.AnimState:PushAnimation("atk", false)
                        DoMountSound(inst, inst.components.rider:GetMount(), "angry", true)
                        cooldown = math.max(cooldown, 16 * FRAMES)
                    end
                elseif equip ~= nil and equip:HasTag("toolpunch") then
                    -- **** ANIMATION WARNING ****
                    -- **** ANIMATION WARNING ****
                    -- **** ANIMATION WARNING ****

                    --  THIS ANIMATION LAYERS THE LANTERN GLOW UNDER THE ARM IN THE UP POSITION SO CANNOT BE USED IN STANDARD LANTERN GLOW ANIMATIONS.

                    inst.AnimState:PlayAnimation("toolpunch")
                    inst.sg.statemem.istoolpunch = true
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
                    cooldown = math.max(cooldown, 13 * FRAMES)
                elseif equip ~= nil and equip:HasTag("whip") then
                    inst.AnimState:PlayAnimation("whip_pre")
                    inst.AnimState:PushAnimation("whip", false)
                    inst.sg.statemem.iswhip = true
                    inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                    cooldown = math.max(cooldown, 17 * FRAMES)
                elseif equip ~= nil and equip:HasTag("pocketwatch") then
                    inst.AnimState:PlayAnimation(inst.sg.statemem.chained and "pocketwatch_atk_pre_2" or
                        "pocketwatch_atk_pre")
                    inst.AnimState:PushAnimation("pocketwatch_atk", false)
                    inst.sg.statemem.ispocketwatch = true
                    cooldown = math.max(cooldown, 15 * FRAMES)
                    if equip:HasTag("shadow_item") then
                        inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow", nil, nil, true)
                        inst.AnimState:Show("pocketwatch_weapon_fx")
                        inst.sg.statemem.ispocketwatch_fueled = true
                    else
                        inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre", nil, nil, true)
                        inst.AnimState:Hide("pocketwatch_weapon_fx")
                    end
                elseif equip ~= nil and equip:HasTag("book") then
                    inst.AnimState:PlayAnimation("attack_book")
                    inst.sg.statemem.isbook = true
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                    cooldown = math.max(cooldown, 19 * FRAMES)
                elseif equip ~= nil and equip:HasTag("chop_attack") and inst:HasTag("woodcutter") then
                    inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and
                        inst.AnimState:GetCurrentAnimationTime() < 7.1 * FRAMES and "woodie_chop_atk_pre" or
                        "woodie_chop_pre")
                    inst.AnimState:PushAnimation("woodie_chop_loop", false)
                    inst.sg.statemem.ischop = true
                    cooldown = math.max(cooldown, 11 * FRAMES)
                elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                    if (equip.projectiledelay or 0) > 0 then
                        --V2C: Projectiles don't show in the initial delayed frames so that
                        --     when they do appear, they're already in front of the player.
                        --     Start the attack early to keep animation in sync.
                        inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                        if inst.sg.statemem.projectiledelay > FRAMES then
                            inst.sg.statemem.projectilesound =
                                (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                "dontstarve/wilson/attack_weapon"
                        elseif inst.sg.statemem.projectiledelay <= 0 then
                            inst.sg.statemem.projectiledelay = nil
                        end
                    end
                    if inst.sg.statemem.projectilesound == nil then
                        inst.SoundEmitter:PlaySound(
                            (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                            (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                            "dontstarve/wilson/attack_weapon",
                            nil, nil, true
                        )
                    end
                    cooldown = math.max(cooldown, 13 * FRAMES)
                elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                    cooldown = math.max(cooldown, 13 * FRAMES)
                elseif inst:HasTag("beaver") then
                    inst.sg.statemem.isbeaver = true
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                    cooldown = math.max(cooldown, 13 * FRAMES)
                elseif inst:HasTag("weremoose") then
                    inst.sg.statemem.ismoose = true
                    inst.AnimState:PlayAnimation(
                        (
                            (inst.AnimState:IsCurrentAnimation("punch_a") or inst.AnimState:IsCurrentAnimation("punch_c"))
                            and "punch_b") or
                        (inst.AnimState:IsCurrentAnimation("punch_b") and "punch_c") or
                        "punch_a"
                    )
                    cooldown = math.max(cooldown, 15 * FRAMES)
                else
                    inst.AnimState:PlayAnimation("punch")
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                    cooldown = math.max(cooldown, 24 * FRAMES)
                end

                inst.sg:SetTimeout(cooldown)

                if target ~= nil then
                    inst.components.combat:BattleCry()
                    if target:IsValid() then
                        inst:FacePoint(target:GetPosition())
                        inst.sg.statemem.attacktarget = target
                    end
                end
            end,

            onupdate = function(inst, dt)
                if (inst.sg.statemem.projectiledelay or 0) > 0 then
                    inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                    if inst.sg.statemem.projectiledelay <= FRAMES then
                        if inst.sg.statemem.projectilesound ~= nil then
                            inst.SoundEmitter:PlaySound(inst.sg.statemem.projectilesound, nil, nil, true)
                            inst.sg.statemem.projectilesound = nil
                        end
                        if inst.sg.statemem.projectiledelay <= 0 then
                            DoMockAttack(inst)
                            inst:ClearBufferedAction()
                            inst.sg:RemoveStateTag("abouttoattack")
                        end
                    end
                end
            end,

            timeline =
            {
                TimeEvent(5 * FRAMES, function(inst)
                    if inst.sg.statemem.ismoose then
                        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/moose/punch", nil, nil, true)
                    end
                end),
                TimeEvent(6 * FRAMES, function(inst)
                    if inst.sg.statemem.isbeaver then
                        DoMockAttack(inst)
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    elseif inst.sg.statemem.ischop then
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                    end
                end),
                TimeEvent(7 * FRAMES, function(inst)
                    if inst.sg.statemem.ismoose then
                        DoMockAttack(inst)
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end),
                TimeEvent(8 * FRAMES, function(inst)
                    if not (inst.sg.statemem.isbeaver or
                            inst.sg.statemem.ismoose or
                            inst.sg.statemem.iswhip or
                            inst.sg.statemem.ispocketwatch or
                            inst.sg.statemem.isbook) and
                        inst.sg.statemem.projectiledelay == nil then
                        DoMockAttack(inst)
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                        inst.sg:RemoveStateTag("busy")
                    end
                end),
                TimeEvent(10 * FRAMES, function(inst)
                    if inst.sg.statemem.iswhip or inst.sg.statemem.isbook or inst.sg.statemem.ispocketwatch then
                        DoMockAttack(inst)
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                        inst.sg:RemoveStateTag("busy")
                    end
                end),
            },

            ontimeout = function(inst)
                inst.sg:RemoveStateTag("attack")
                inst.sg:RemoveStateTag("busy")
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
            name = "blackpuddle_death",
            tags = { "busy", --[["dead",]] "pausepredict", "nomorph", "blackpuddle_death" },

            onenter = function(inst)
                --assert(inst.deathcause ~= nil, "Entered death state without cause.")

                ClearStatusAilments(inst)
                ForceStopHeavyLifting(inst)

                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()

                inst.AnimState:Hide("swap_arm_carry")
                inst.AnimState:PlayAnimation("boat_death")

                --local death_fx = SpawnPrefab("rne_grabbyshadows")
                --death_fx.Transform:SetPosition(inst:GetPosition():Get())

                if inst.components.rider:IsRiding() then
                    inst.sg:AddStateTag("dismounting")
                end

                inst.SoundEmitter:PlaySound("dontstarve/characters/" .. (inst.soundsname or inst.prefab) .. "/sinking")
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/characters/" ..
                    (inst.soundsname or inst.prefab) .. "/sinking")
                if TUNING.DSTU.COMPROMISING_SHADOWVORTEX and inst.components.health ~= nil then
                    inst.components.health:SetInvincible(true)
                end
                inst.components.burnable:Extinguish()
                inst.sg:ClearBufferedEvents()
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        if not TUNING.DSTU.COMPROMISING_SHADOWVORTEX then
                            inst.components.inventory:DropEverything(true)
                            inst:PushEvent(inst.ghostenabled and "makeplayerghost" or "playerdied", { skeleton = nil }) -- if we are not on valid ground then don't drop a skeleton
                        else
                            local locpos = getrandomposition(inst, inst, false)
                            if inst.Physics ~= nil then
                                inst.Physics:Teleport(locpos.x, 0, locpos.z)
                            else
                                inst.Transform:SetPosition(locpos.x, 0, locpos.z)
                            end

                            if inst:HasTag("player") then
                                inst:SnapCamera()
                                inst:ScreenFade(true, 1)
                            end
                            inst.sg.statemem.teleport_task = inst:DoTaskInTime(1, teleport_end)
                        end
                    end
                end),
            },

            onexit = function(inst)
                inst.DynamicShadow:Enable(true)
            end,

            timeline =
            {
                TimeEvent(50 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boat_sinking_shadow")
                end),
                TimeEvent(70 * FRAMES, function(inst)
                    inst.DynamicShadow:Enable(false)
                end),
            },
        },


        State {
            name = "rne_player_grabbed",
            tags = { "busy", "dead", "pausepredict", "nomorph" },

            onenter = function(inst)
                assert(inst.deathcause ~= nil, "Entered death state without cause.")

                ClearStatusAilments(inst)
                ForceStopHeavyLifting(inst)

                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()

                inst.AnimState:Hide("swap_arm_carry")
                inst.AnimState:PlayAnimation("grabbedbytheghoulie")

                if inst.components.rider:IsRiding() then
                    inst.sg:AddStateTag("dismounting")
                end

                if inst.deathsoundoverride ~= nil then
                    inst.SoundEmitter:PlaySound(inst.deathsoundoverride)
                elseif not inst:HasTag("mime") then
                    inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") ..
                        (inst.soundsname or inst.prefab) .. "/death_voice")
                end

                inst.components.burnable:Extinguish()
                inst.sg:ClearBufferedEvents()
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.components.inventory:DropEverything(true)
                        inst:PushEvent(inst.ghostenabled and "makeplayerghost" or "playerdied", { skeleton = nil }) -- if we are not on valid ground then don't drop a skeleton
                    end
                end),
            },

            onexit = function(inst)
                inst.DynamicShadow:Enable(true)
            end,

            timeline =
            {
                TimeEvent(547 * FRAMES, function(inst)
                    inst.DynamicShadow:Enable(false)
                end),
            },
        },

        State {
            name = "grabby_teleport",
            tags = { "busy", "pausepredict", "nomorph", "nodangle", "gotgrabbed" },

            onenter = function(inst, cb)
                inst.sg.statemem.cb = cb

                --This state is only valid as a substate of openwardrobe
                inst.AnimState:OverrideSymbol("shadow_hands", "shadow_skinchangefx", "shadow_hands")
                inst.AnimState:OverrideSymbol("shadow_ball", "shadow_skinchangefx", "shadow_ball")
                inst.AnimState:OverrideSymbol("splode", "shadow_skinchangefx", "splode")

                --inst.AnimState:PlayAnimation("gift_pst", false)
                inst.AnimState:PlayAnimation("skin_change", false)

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            end,

            timeline =
            {
                -- gift_pst plays first and it is 20 frames long
                TimeEvent(0, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/common/together/skin_change")
                end),
                TimeEvent(41 * FRAMES, function(inst)
                    if inst.components.inventory ~= nil then
                        local hand = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                        if hand ~= nil then
                            inst.components.inventory:DropItem(hand)
                        end

                        local body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                        if body ~= nil and body._light ~= nil then
                            inst.components.inventory:DropItem(body)
                        end

                        local hat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                        if hat ~= nil and (hat:HasTag("nightvision") or hat._light) then
                            inst.components.inventory:DropItem(hat)
                        end

                        if inst.components.sanity ~= nil then
                            inst.components.sanity:DoDelta(-15)
                        end
                    end
                end),
                -- frame 42 of skin_change is where the character is completely hidden
                TimeEvent(42 * FRAMES, function(inst)
                    if inst.sg.statemem.cb ~= nil then
                        inst.sg.statemem.cb()
                        inst.sg.statemem.cb = nil
                    end
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
                if inst.sg.statemem.cb ~= nil then
                    -- in case of interruption
                    inst.sg.statemem.cb()
                    inst.sg.statemem.cb = nil
                end
                inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
                --Cleanup from openwardobe state
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
                inst:ShowActions(true)
            end,
        },

        State {
            name = "hit_weaver",
            tags = { "busy", "pausepredict" },

            onenter = function(inst, attacker)
                ForceStopHeavyLifting(inst)
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()

                if attacker ~= nil then
                    inst:ForceFacePoint(attacker.Transform:GetWorldPosition())
                end

                inst.AnimState:PlayAnimation("lighthit_back")

                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)

                --V2C: some of the woodie's were-transforms have shorter hit anims
                local stun_frames = math.min(math.floor(inst.AnimState:GetCurrentAnimationLength() / FRAMES + .5),
                    attacker and 10 or 6)
                if inst.components.playercontroller ~= nil then
                    --Specify min frames of pause since "busy" tag may be
                    --removed too fast for our network update interval.
                    inst.components.playercontroller:RemotePausePrediction(stun_frames <= 7 and stun_frames or nil)
                end
                inst.sg:SetTimeout(stun_frames * FRAMES)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("idle", true)
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
            name = "soundstun",
            tags = { "busy", "pausepredict" },

            onenter = function(inst, attacker)
                ForceStopHeavyLifting(inst)
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()



                inst.AnimState:PlayAnimation("idle_sanity_pre", false)
                inst.AnimState:PushAnimation("idle_sanity_loop", true)

                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)

                --V2C: some of the woodie's were-transforms have shorter hit anims
                local stun_frames = 160
                --if inst.components.playercontroller ~= nil then
                    --Specify min frames of pause since "busy" tag may be
                    --removed too fast for our network update interval.
                    --inst.components.playercontroller:RemotePausePrediction(stun_frames)
                --end
                inst.sg:SetTimeout(stun_frames * FRAMES)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("idle", true)
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
            name = "opossum_death",
            tags = { "hiding", "notalking", "nomorph", "busy", "nopredict", "nodangle" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                inst.AnimState:PlayAnimation("death2_idle")

                --inst.SoundEmitter:PlaySound("dontstarve/wilson/death")
                --inst.AnimState:PlayAnimation("death")
            end,

            timeline =
            {
                TimeEvent(24 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("nopredict")
                    inst.sg:AddStateTag("idle")
                end),
            },

            events =
            {
                EventHandler("ontalk", function(inst)
                    if inst.sg.statemem.talktask ~= nil then
                        inst.sg.statemem.talktask:Cancel()
                        inst.sg.statemem.talktask = nil
                        StopTalkSound(inst, true)
                    end
                    if DoTalkSound(inst) then
                        inst.sg.statemem.talktask =
                            inst:DoTaskInTime(1.5 + math.random() * .5,
                                function()
                                    inst.sg.statemem.talktask = nil
                                    StopTalkSound(inst)
                                end)
                    end
                end),
                EventHandler("donetalking", function(inst)
                    if inst.sg.statemem.talktalk ~= nil then
                        inst.sg.statemem.talktask:Cancel()
                        inst.sg.statemem.talktask = nil
                        StopTalkSound(inst)
                    end
                end),
                EventHandler("unequip", function(inst, data)
                    -- We need to handle this during the initial "busy" frames
                    if not inst.sg:HasStateTag("idle") then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.talktask ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    StopTalkSound(inst)
                end
            end,
        },

        State {
            name = "cast_net_fixed",
            tags = { "doing", "busy" },

            onenter = function(inst, silent)
                inst.components.locomotor:Stop()
                --inst.AnimState:PlayAnimation("cast_pre")
                --inst.AnimState:PushAnimation("cast_loop", true)
                inst.AnimState:PlayAnimation("fishing_ocean_pre")
                inst.AnimState:PushAnimation("fishing_ocean_cast", false)
                inst.AnimState:PushAnimation("fishing_ocean_cast_loop", true)
                --inst.sg.statemem.action = inst.bufferedaction
                --inst.sg.statemem.silent = silent
                --inst.sg:SetTimeout(10 * FRAMES)
            end,

            timeline =
            {
                TimeEvent(6 * FRAMES, function(inst)
                    inst.AnimState:ClearOverrideSymbol("swap_object")

                    inst:PerformBufferedAction()
                end),
            },

            events =
            {
                EventHandler("begin_retrieving", function(inst)
                    inst.sg:GoToState("cast_net_retrieving_fixed")
                end),
            },

            --[[
        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,
        ]] --

            --[[
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action and
            (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                inst:ClearBufferedAction()
            end
        end,
        ]] --
        },

        State {
            name = "cast_net_retrieving_fixed",
            tags = { "doing", "busy" },

            onenter = function(inst, silent)
                --inst.AnimState:PlayAnimation("cast_pst")
                --inst.AnimState:PushAnimation("return_pre")
                --inst.AnimState:PushAnimation("return_loop", true)
                inst.AnimState:PlayAnimation("fishing_ocean_catch")
                inst.AnimState:PushAnimation("fishing_ocean_pst")
            end,

            events =
            {
                EventHandler("begin_final_pickup", function(inst)
                    inst.sg:GoToState("cast_net_release_fixed")
                end),
            },
        },

        State {
            name = "cast_net_release_fixed",
            tags = { "doing", "busy" },

            onenter = function(inst, silent)
                --inst.AnimState:PlayAnimation("release_loop", false)

                inst.AnimState:OverrideSymbol("swap_object", "swap_boat_net", "swap_boat_net")
                inst.AnimState:PlayAnimation("pickup")
            end,

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("cast_net_release_pst_fixed")
                end),
            }
        },

        State {
            name = "cast_net_release_pst_fixed",
            tags = { "doing" },

            onenter = function(inst, silent)
                inst.sg:RemoveStateTag("busy")
                --inst.AnimState:PlayAnimation("release_pst", false)
                inst.AnimState:PlayAnimation("pickup_pst", false)
            end,

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            }
        },


        State {
            name = "beegun",
            tags = { "attack", "notalking", "abouttoattack" },

            onenter = function(inst)
                if inst.components.rider:IsRiding() then
                    inst.Transform:SetFourFaced()
                end

                inst.sg.statemem.target = inst.components.combat.target
                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("speargun")

                inst.sg.statemem.abouttoattack = true

                if inst.components.combat.target then
                    if inst.components.combat.target and inst.components.combat.target:IsValid() then
                        inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
                    end
                end
            end,

            onexit = function(inst)
                if inst.components.rider:IsRiding() then
                    inst.Transform:SetSixFaced()
                end
            end,

            timeline =
            {

                TimeEvent(12 * FRAMES, function(inst)
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        if target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target) then
                            inst.sg.statemem.abouttoattack = false
                            inst:PerformBufferedAction()
                        else
                            inst:ClearBufferedAction()
                            inst.sg:GoToState("idle")
                        end
                    else
                        inst:ClearBufferedAction()
                    end
                    -- inst.components.combat:DoAttack(inst.sg.statemem.target)
                    --inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/use_speargun")
                end),
                TimeEvent(20 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },

        State {
            name = "beegun_short",
            tags = { "attack", "notalking", "abouttoattack" },

            onenter = function(inst)
                if inst.components.rider:IsRiding() then
                    inst.Transform:SetFourFaced()
                end

                inst.sg.statemem.target = inst.components.combat.target
                inst.components.combat:StartAttack()
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("speargun")
                inst.AnimState:SetTime(5 * FRAMES)

                inst.sg.statemem.abouttoattack = true

                if inst.components.combat.target then
                    if inst.components.combat.target and inst.components.combat.target:IsValid() then
                        inst:FacePoint(Point(inst.components.combat.target.Transform:GetWorldPosition()))
                    end
                end
            end,

            onexit = function(inst)
                if inst.components.rider:IsRiding() then
                    inst.Transform:SetSixFaced()
                end
            end,

            timeline =
            {

                TimeEvent(6 * FRAMES, function(inst)
                    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    if equip ~= nil and equip.components.weapon ~= nil and equip.components.weapon.projectile ~= nil then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        if target ~= nil and target:IsValid() and inst.components.combat:CanTarget(target) then
                            inst.sg.statemem.abouttoattack = false
                            inst:PerformBufferedAction()
                        else
                            inst:ClearBufferedAction()
                            inst.sg:GoToState("idle")
                        end
                    else
                        inst:ClearBufferedAction()
                    end
                    -- inst.components.combat:DoAttack(inst.sg.statemem.target)
                    --inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/use_speargun")
                end),
                TimeEvent(20 * FRAMES, function(inst) inst.sg:RemoveStateTag("attack") end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },

        State {
            name = "collectthebees",
            tags = { "doing", "busy", "canrotate" },

            onenter = function(inst)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(false)
                end
                inst.AnimState:PlayAnimation("staff_pre")
                inst.AnimState:PushAnimation("staff", false)

                --inst.AnimState:PushAnimation("staff", false)
                inst.components.locomotor:Stop()

                --Spawn an effect on the player's location
                local staff = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                local colour = staff ~= nil and staff.fxcolour or { 1, 1, 1 }

                inst.sg.statemem.stafffx = SpawnPrefab("bee_poof_big")
                inst.sg.statemem.stafffx.entity:SetParent(inst.entity)
                inst.sg.statemem.stafffx.entity:AddFollower()
                inst.sg.statemem.stafffx.Follower:FollowSymbol(inst.GUID, "swap_object", 30, 0, 0.1)
            end,

            timeline =
            {
                TimeEvent(13 * FRAMES, function(inst)
                    inst.sg.statemem.stafffx = nil --Can't be cancelled anymore
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bee_queen/taunt")
                    inst:PerformBufferedAction()
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
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                if inst.sg.statemem.stafffx ~= nil and inst.sg.statemem.stafffx:IsValid() then
                    inst.sg.statemem.stafffx:Remove()
                end
            end,
        },

        State {
            name = "dreadeye_spooked",
            tags = { "busy", "pausepredict" },

            onenter = function(inst)
                ForceStopHeavyLifting(inst)
                inst.components.locomotor:Stop()
                inst:ClearBufferedAction()

                inst.AnimState:PlayAnimation("spooked")

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            end,

            timeline =
            {
                TimeEvent(20 * FRAMES, function(inst)
                    if inst.components.talker ~= nil then
                        inst.components.talker:Say(GetString(inst, "ANNOUNCE_DREADEYE_SPOOKED"))
                    end
                end),
                TimeEvent(49 * FRAMES, function(inst)
                    inst.sg:GoToState("idle", true)
                end),
            },

            events =
            {
                EventHandler("ontalk", function(inst)
                    if inst.sg.statemem.talktask ~= nil then
                        inst.sg.statemem.talktask:Cancel()
                        inst.sg.statemem.talktask = nil
                        StopTalkSound(inst, true)
                    end
                    if DoTalkSound(inst) then
                        inst.sg.statemem.talktask =
                            inst:DoTaskInTime(1.5 + math.random() * .5,
                                function()
                                    inst.sg.statemem.talktask = nil
                                    StopTalkSound(inst)
                                end)
                    end
                end),
                EventHandler("donetalking", function(inst)
                    if inst.sg.statemem.talktalk ~= nil then
                        inst.sg.statemem.talktask:Cancel()
                        inst.sg.statemem.talktask = nil
                        StopTalkSound(inst)
                    end
                end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.talktask ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    StopTalkSound(inst)
                end
            end,
        },

        State {
            name = "charles_charge",
            tags = { "canrotate", "busy" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil and buffaction.pos ~= nil then
                    inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                elseif buffaction ~= nil and buffaction.target ~= nil then
                    inst:ForceFacePoint(buffaction.target:GetPosition())
                end

                inst:PerformBufferedAction()
                --inst.AnimState:PlayAnimation("spearjab_pre")
                --inst.AnimState:PushAnimation("spearjab", false)

                inst.AnimState:PlayAnimation("spearjab")

                local fxcircle = SpawnPrefab("dreadeye_sanityburstring")
                fxcircle:AddTag("ignore_transparency")
                fxcircle.Transform:SetScale(1.3, 1.3, 1.3)
                fxcircle.entity:SetParent(inst.entity)
            end,

            timeline =
            {
                TimeEvent(0 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/knight/attack")

                    inst.Physics:SetMotorVelOverride(20, 0, 0)

                    Check_Bowling(inst)
                end),

                TimeEvent(5 * FRAMES, function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.Physics:SetMotorVelOverride(15, 0, 0)
                    Check_Bowling(inst)
                end),

                TimeEvent(10 * FRAMES, function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.Physics:SetMotorVelOverride(10, 0, 0)
                    Check_Bowling(inst)
                end),

                TimeEvent(15 * FRAMES, function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.Physics:SetMotorVelOverride(5, 0, 0)
                    Check_Bowling(inst)
                end),

                TimeEvent(18 * FRAMES, function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.components.locomotor:EnableGroundSpeedMultiplier(true)

                    inst.sg:RemoveStateTag("busy")
                end),
            },

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },

            onexit = function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.Physics:ClearMotorVelOverride()
            end,
        },

        State {
            name = "um_tornado_teleport",
            tags = { "busy", "nopredict", "nomorph", "nointerrupt" },

            onenter = function(inst, shore_pt)
                ForceStopHeavyLifting(inst)
                inst:ClearBufferedAction()

                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()

                inst.components.health:SetInvincible(true)

                inst.DynamicShadow:Enable(false)

                if inst:HasTag("wereplayer") then
                    inst.AnimState:PlayAnimation("dozy")
                else
                    inst.AnimState:PlayAnimation("grabbedbytheghoulie")
                end

                if inst.deathsoundoverride ~= nil then
                    inst.SoundEmitter:PlaySound(inst.deathsoundoverride)
                elseif not inst:HasTag("mime") then
                    inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/") ..
                        (inst.soundsname or inst.prefab) .. "/death_voice")
                end

                inst.components.rider:ActualDismount()

                inst:ShowHUD(false)

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(false)
                end
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst:ScreenFade(false, 1)
                end),
            },

            onexit = function(inst)
                inst.components.health:SetInvincible(false)
                inst.DynamicShadow:Enable(true)
                inst:Show()

                if inst.sg.statemem.teleport_task ~= nil then
                    -- Still have a running teleport_task
                    -- Interrupt!
                    inst.sg.statemem.teleport_task:Cancel()
                    inst.sg.statemem.teleport_task = nil
                    inst:ScreenFade(true, .5)
                end

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
            end,
        },

        State {
            name = "um_tornado_wakeup",
            tags = { "busy", "canrotate", "nopredict", "nomorph", "nointerrupt" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end

                if inst:HasTag("wereplayer") then
                    inst.AnimState:PlayAnimation("wakeup")
                else
                    inst.AnimState:PlayAnimation("enter")
                end
                
                if inst.components.drownable ~= nil then
                    --inst.components.drownable:TakeDrowningDamage()
                    
                    local tunings = inst.components.drownable and inst.components.drownable.customtuningsfn ~= nil and inst.components.drownable.customtuningsfn(inst) or
                                        inst.prefab == "wx78" and TUNING.DROWNING_DAMAGE[string.upper(inst.prefab)] or
                                        TUNING.DROWNING_DAMAGE["DEFAULT"]
                    
                    if inst.components.moisture ~= nil and tunings.WETNESS ~= nil then
                        inst.components.moisture:DoDelta(tunings.WETNESS, true)
                    end
                    
                    if inst.components.hunger ~= nil and tunings.HUNGER ~= nil then
                        local delta = -math.min(tunings.HUNGER, inst.components.hunger.current - 30)
                        if delta < 0 then
                            inst.components.hunger:DoDelta(delta)
                        end
                    end
                    
                    if inst.components.health ~= nil then
                        if tunings.HEALTH_PENALTY ~= nil then
                            inst.components.health:DeltaPenalty(tunings.HEALTH_PENALTY)
                        end

                        if tunings.HEALTH ~= nil then
                            local delta = -math.min(tunings.HEALTH, inst.components.health.currenthealth - 30)
                            if delta < 0 then
                                inst.components.health:DoDelta(delta, false, "Tornado", true, nil, true)
                            end
                        end
                    end

                    if inst.components.sanity ~= nil and tunings.SANITY ~= nil then
                        local delta = -math.min(tunings.SANITY, inst.components.sanity.current - 30)
                        if delta < 0 then
                            inst.components.sanity:DoDelta(delta)
                        end
                    end
                    
                end
            end,

            timeline =
            {
                TimeEvent(11 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")

                    if inst.components.health ~= nil then
                        inst.components.health:DoDelta(-50, false, "Tornado")
                    end
                end),
            },


            events =
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
            },

        },

        State {
            name = "wingsuit_pre",
            tags = { "doing", "nointerrupt", --[["busy",]] "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

            onenter = function(inst)
                
                inst.um_wingsuit_flapcount = 0
            
                inst.Physics:SetMotorVelOverride(10, 0, 0)
                inst:PerformBufferedAction()
                inst.AnimState:PlayAnimation("boat_jump_pre")
                
                inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
                inst.Physics:SetCollisionMask(COLLISION.GROUND)
                if not TheWorld.ismastersim then
                    inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
                end
            end,

            --timeline = timelines.hop_pre or nil,

            ontimeout = function(inst)
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("wingsuit_loop")
                end),
            },

            onexit = function(inst)
                inst.Physics:ClearLocalCollisionMask()
                if inst.sg.statemem.collisionmask ~= nil then
                    inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
                end
                inst:RemoveTag("ignorewalkableplatforms")

                if inst.components.locomotor.isrunning then
                    inst:PushEvent("locomote")
                end
            end,
        },

        State {
            name = "wingsuit_pre_quick",
            tags = { "doing", --[["busy",]] "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

            onenter = function(inst, data)
                inst.Physics:SetMotorVelOverride(10, 0, 0)
                inst:PerformBufferedAction()
                inst.AnimState:PlayAnimation("boat_jump_loop")
                
                inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
                inst.Physics:SetCollisionMask(COLLISION.GROUND)
                if not TheWorld.ismastersim then
                    inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
                end
                inst:AddTag("ignorewalkableplatforms")
            end,
            
            timeline =
            {
                TimeEvent(1 * FRAMES, function(inst)
                    inst.sg:GoToState("wingsuit_loop")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("wingsuit_loop")
                end),
            },

            onexit = function(inst)
                inst.Physics:ClearLocalCollisionMask()
                if inst.sg.statemem.collisionmask ~= nil then
                    inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
                end
                inst:RemoveTag("ignorewalkableplatforms")

                if inst.components.locomotor.isrunning then
                    inst:PushEvent("locomote")
                end
            end,
        },

        State {
            name = "wingsuit_loop",
            tags = { "doing", "nointerrupt", --[["busy",]] "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

            onenter = function(inst, data)
                if inst.um_wingsuit_flapcount >= 10 then
                    inst.sg:AddStateTag("busy")
                end
            
                SpawnPrefab("spikes_malbatross").entity:SetParent(inst.entity)
                inst.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/flap")
                inst.Physics:SetMotorVelOverride(10 - inst.um_wingsuit_flapcount, 0, 0)
                
                inst.um_wingsuit_flapcount = inst.um_wingsuit_flapcount + 1.25
                inst:PerformBufferedAction()
                    
                inst.AnimState:PlayAnimation("boat_jump_loop", true)
                
                inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
                inst.Physics:SetCollisionMask(COLLISION.GROUND)
                if not TheWorld.ismastersim then
                    inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
                end
                inst:AddTag("ignorewalkableplatforms")
                
                inst.sg:SetTimeout(1.1)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("wingsuit_pst")
            end,


            timeline =
            {
                TimeEvent(.9, function(inst)
                    SpawnPrefab("spikes_malbatross").entity:SetParent(inst.entity)
                    inst.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/flap")
                end),
                TimeEvent(.75, function(inst)
                    SpawnPrefab("spikes_malbatross").entity:SetParent(inst.entity)
                    inst.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/flap")
                end),
                TimeEvent(.6, function(inst)
                    SpawnPrefab("spikes_malbatross").entity:SetParent(inst.entity)
                    inst.SoundEmitter:PlaySound("saltydog/creatures/boss/malbatross/flap")
                end),
            },
            --[[events =
            {
                EventHandler("animover", function(inst)
                end),
            },]]

            onexit = function(inst)
                inst.Physics:ClearLocalCollisionMask()
                if inst.sg.statemem.collisionmask ~= nil then
                    inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
                end
                inst:RemoveTag("ignorewalkableplatforms")

                if inst.components.locomotor.isrunning then
                    inst:PushEvent("locomote")
                end
            end,
        },

        State {
            name = "wingsuit_pst",
            tags = { "doing", "nointerrupt", "busy", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

            onenter = function(inst, data)
                inst.Physics:SetMotorVelOverride(5, 0, 0)
                inst.Physics:ClearMotorVelOverride()
                inst.AnimState:PlayAnimation("boat_jump_pst")
            end,

            --timeline = timelines.hop_pst or nil,

            events =
            {
                EventHandler("animover", function(inst)
                    inst.um_wingsuit_flapcount = 0
                    
                    local x, y, z = inst.Transform:GetWorldPosition()
                    
                    if TheWorld.Map:IsOceanAtPoint(x, y, z) then
                        inst.sg:GoToState("sink_fast")
                    else
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                
                inst.Physics:ClearLocalCollisionMask()
                if inst.sg.statemem.collisionmask ~= nil then
                    inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
                end
                inst:RemoveTag("ignorewalkableplatforms")

                if inst.components.locomotor.isrunning then
                    inst:PushEvent("locomote")
                end
            end,
        },
        
        --[[State{
            name = "pact_armor_craft",
            tags = { "doing", "busy", "nocraftinginterrupt", "nomorph" },

            onenter = function(inst, product)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("wendy_recall")
                inst.AnimState:PushAnimation("wendy_recall_pst", false)
                
                inst.sg.statemem.action = inst.bufferedaction
            end,

            timeline =
            {
                FrameEvent(20, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/attack")
                    
                    local body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                    
                    if body ~= nil then
                        inst.components.inventory:GiveItem(inst.components.inventory:Unequip(EQUIPSLOTS.BODY))
                    end
                    
                    inst:PerformBufferedAction()
                    SpawnPrefab("um_shadow_attune_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end),
                FrameEvent(25, function(inst)
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

            onexit = function(inst)
                if inst.bufferedaction == inst.sg.statemem.action and
                        (not inst.components.playercontroller or
                        inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                    inst:ClearBufferedAction()
                end
            end,
        },
        
        State{
            name = "pact_sword_craft",
            tags = { "doing", "busy", "nocraftinginterrupt", "nomorph" },

            onenter = function(inst, product)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("tornado")
                
                inst.sg.statemem.action = inst.bufferedaction
                
                local hands = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    
                if hands == nil then
                    inst.AnimState:OverrideSymbol("swap_object", "nothing_lmao", "nothing_lmao")
                    inst.AnimState:Show("ARM_carry")
                end
            end,

            timeline =
            {
                FrameEvent(15, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/attack")
                    
                    local hands = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    
                    if hands ~= nil then
                        inst.components.inventory:GiveItem(inst.components.inventory:Unequip(EQUIPSLOTS.HANDS))
                    end
                    
                    inst:PerformBufferedAction()
                    SpawnPrefab("um_shadow_attune_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end),
                FrameEvent(20, function(inst)
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

            onexit = function(inst)
                if inst.bufferedaction == inst.sg.statemem.action and
                        (not inst.components.playercontroller or
                        inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                        
                    local hands = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                    
                    if hands == nil then
                        inst.AnimState:Hide("ARM_carry")
                    end
                    
                    inst:ClearBufferedAction()
                end
            end,
        },]]

        State{
            name = "usewaxwelljournal_pre",
            tags = {"doing", "busy", "nocraftinginterrupt", "nomorph"},

            onenter = function(inst, repeatcast)
                inst.components.locomotor:Stop()
                inst.AnimState:SetDeltaTimeMultiplier(2)
                inst.AnimState:PlayAnimation("action_uniqueitem_pre")
                local fxname = "waxwell_book_fx"
                if inst.components.rider:IsRiding() then
                    fxname = fxname.."_mount"
                end
                inst.sg.statemem.book_fx = SpawnPrefab(fxname)
                inst.sg.statemem.book_fx.AnimState:SetDeltaTimeMultiplier(2)
                inst.sg.statemem.book_fx.entity:SetParent(inst.entity)
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("usewaxwelljournal", {book_fx = inst.sg.statemem.book_fx})
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst.sg.statemem.book_fx.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },

        State{
            name = "usewaxwelljournal",
            tags = {"doing", "nocraftinginterrupt", "nomorph"},

            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("book")

                if data then
                    inst.sg.statemem.book_fx = data.book_fx
                end

                local suffix = inst.components.rider:IsRiding() and "_mount" or ""

                inst.sg.statemem.fx_shadow = SpawnPrefab("waxwell_shadow_book_fx"..suffix)
                inst.sg.statemem.fx_shadow.entity:SetParent(inst.entity)

                inst.AnimState:OverrideSymbol("book_open", "book_maxwell", "book_open")
                inst.AnimState:OverrideSymbol("book_closed", "book_maxwell", "book_closed")
                inst.sg.statemem.symbolsoverridden = true
                inst.sg.statemem.earlycast = true

                inst.sg.statemem.castsound = "maxwell_rework/shadow_magic/cast"
            end,

            timeline =
            {
                FrameEvent(13, function(inst)
                    local function fn19()
                        inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
                        
                        if inst.sg.statemem.earlycast then
                            if inst.sg.statemem.fx_shadow then
                                if inst.sg.statemem.fx_shadow:IsValid() then
                                    local x, y, z = inst.sg.statemem.fx_shadow.Transform:GetWorldPosition()
                                    inst.sg.statemem.fx_shadow.entity:SetParent(nil)
                                    inst.sg.statemem.fx_shadow.Transform:SetPosition(x, y, z)
                                    inst.sg.statemem.fx_shadow.Transform:SetRotation(inst.Transform:GetRotation())
                                end
                                inst.sg.statemem.fx_shadow = nil --Don't cancel anymore
                            end
                            inst.SoundEmitter:PlaySound(inst.sg.statemem.castsound)
                            if not inst:PerformBufferedAction() then
                                inst.sg.statemem.canrepeatcast = false
                                inst:RemoveTag("canrepeatcast")
                            end
                        end
                    end
                    if inst.sg.statemem.repeatcast then
                        fn19()
                    else
                        inst.sg.statemem.fn19 = fn19
                    end
                end),
                FrameEvent(19, function(inst)
                    if inst.sg.statemem.fn19 then
                        inst.sg.statemem.fn19()
                        inst.sg.statemem.fn19 = nil
                    end
                end),
                FrameEvent(24, function(inst)
                    local function fn30()
                        if inst.sg.statemem.fx_shadow then
                            if inst.sg.statemem.fx_shadow:IsValid() then
                                local x, y, z = inst.sg.statemem.fx_shadow.Transform:GetWorldPosition()
                                inst.sg.statemem.fx_shadow.entity:SetParent(nil)
                                inst.sg.statemem.fx_shadow.Transform:SetPosition(x, y, z)
                                inst.sg.statemem.fx_shadow.Transform:SetRotation(inst.Transform:GetRotation())
                            end
                            inst.sg.statemem.fx_shadow = nil --Don't cancel anymore
                        end
                    end
                    if inst.sg.statemem.repeatcast then
                        fn30()
                    else
                        inst.sg.statemem.fn30 = fn30
                    end
                end),
                FrameEvent(30, function(inst)
                    if inst.sg.statemem.fn30 then
                        inst.sg.statemem.fn30()
                        inst.sg.statemem.fn30 = nil
                    end
                end),
                FrameEvent(44, function(inst)
                    local function fn50()
                        local book_fx = inst.sg.statemem.book_fx
                        if book_fx then
                            if book_fx:IsValid() then
                                local x, y, z = book_fx.Transform:GetWorldPosition()
                                book_fx.entity:SetParent(nil)
                                book_fx.Transform:SetPosition(x, y, z)
                                book_fx.Transform:SetRotation(inst.Transform:GetRotation())
                            else
                                book_fx = nil
                            end
                            inst.sg.statemem.book_fx = nil --Don't cancel anymore
                        end
                    end
                    if inst.sg.statemem.repeatcast then
                        fn50()
                    else
                        inst.sg.statemem.fn50 = fn50
                    end
                end),
                FrameEvent(50, function(inst)
                    if inst.sg.statemem.fn50 then
                        inst.sg.statemem.fn50()
                        inst.sg.statemem.fn50 = nil
                    end
                end),
                FrameEvent(51, function(inst)
                    inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
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

            onexit = function(inst)
                if inst.sg.statemem.symbolsoverridden then
                    inst.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
                    inst.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
                end
                if inst.sg.statemem.book_fx and inst.sg.statemem.book_fx:IsValid() then
                    inst.sg.statemem.book_fx:Remove()
                end
                if inst.sg.statemem.fx_shadow and inst.sg.statemem.fx_shadow:IsValid() then
                    inst.sg.statemem.fx_shadow:Remove()
                end
                if inst.sg.statemem.fx_over and inst.sg.statemem.fx_over:IsValid() then
                    inst.sg.statemem.fx_over:Remove()
                end
                if inst.sg.statemem.fx_under and inst.sg.statemem.fx_under:IsValid() then
                    inst.sg.statemem.fx_under:Remove()
                end
                if inst.sg.statemem.soundtask then
                    inst.sg.statemem.soundtask:Cancel()
                elseif inst.SoundEmitter:PlayingSound("book_layer_sound") then
                    inst.SoundEmitter:SetVolume("book_layer_sound", .5)
                end
                inst:RemoveTag("canrepeatcast")
            end,
        },

        State{
            name = "enterastralportal",
            tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

            onenter = function(inst, data)
                ToggleOffPhysics(inst)
                inst.Physics:Stop()
                inst.components.locomotor:Stop()

                inst.sg.statemem.target = data.teleporter
                inst.sg.statemem.teleportarrivestate = "exitastralportal_pre"

                inst.AnimState:PlayAnimation("townportal_enter_pre")

                local astpool = SpawnPrefab("um_astral_pool")
                astpool.Transform:SetScale(1, 1, 1)
                astpool.Transform:SetPosition(inst.Transform:GetWorldPosition())
                astpool.components.colourtweener:StartTween({1,1,1,1}, .5)
                astpool.components.timer:StartTimer("kill_whirlpool", 5)
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)
                    local puff = SpawnPrefab("halloween_firepuff_cold_"..math.random(3))
                    puff.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.sg.statemem.isteleporting = true
                    inst.components.health:SetInvincible(true)
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(false)
                    end
                    inst.DynamicShadow:Enable(false)
                end),
                TimeEvent(18 * FRAMES, function(inst)
                    inst:Hide()
                end),
                TimeEvent(26 * FRAMES, function(inst)
                    if inst.sg.statemem.target ~= nil and
                        inst.sg.statemem.target.components.teleporter ~= nil and
                        inst.sg.statemem.target.components.teleporter:Activate(inst) then
                        inst:Hide()
                    else
                        inst.sg:GoToState("exitastralportal")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end

                if inst.sg.statemem.isteleporting then
                    inst.components.health:SetInvincible(false)
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                    inst:Show()
                    inst.DynamicShadow:Enable(true)
                end
            end,
        },

        State{
            name = "enterastralportal_nofx",
            tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

            onenter = function(inst, data)
                ToggleOffPhysics(inst)
                inst.Physics:Stop()
                inst.components.locomotor:Stop()

                inst.sg.statemem.target = data.teleporter
                inst.sg.statemem.teleportarrivestate = "exitastralportal_pre"

                inst.AnimState:PlayAnimation("townportal_enter_pre")
            end,

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)
                    local puff = SpawnPrefab("halloween_firepuff_cold_"..math.random(3))
                    puff.Transform:SetPosition(inst.Transform:GetWorldPosition())
                
                    inst.sg.statemem.isteleporting = true
                    inst.components.health:SetInvincible(true)
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(false)
                    end
                    inst.DynamicShadow:Enable(false)
                end),
                TimeEvent(18 * FRAMES, function(inst)
                    inst:Hide()
                end),
                TimeEvent(26 * FRAMES, function(inst)
                    if inst.sg.statemem.target ~= nil and
                        inst.sg.statemem.target.components.teleporter ~= nil and
                        inst.sg.statemem.target.components.teleporter:Activate(inst) then
                        inst:Hide()
                    else
                        inst.sg:GoToState("exitastralportal")
                    end
                end),
            },

            onexit = function(inst)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end

                if inst.sg.statemem.isteleporting then
                    inst.components.health:SetInvincible(false)
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                    inst:Show()
                    inst.DynamicShadow:Enable(true)
                end
            end,
        },

        State{
            name = "exitastralportal_pre",
            tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

            onenter = function(inst)
                ToggleOffPhysics(inst)
                inst.components.locomotor:Stop()

                inst:Hide()
                inst.components.health:SetInvincible(true)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(false)
                end
                inst.DynamicShadow:Enable(false)

                inst.sg:SetTimeout(32 * FRAMES)
            end,

            ontimeout = function(inst)
                inst.sg:GoToState("exitastralportal")
            end,

            onexit = function(inst)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end

                inst:Show()
                inst.components.health:SetInvincible(false)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst.DynamicShadow:Enable(true)
            end,
        },

        State{
            name = "exitastralportal",
            tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

            onenter = function(inst)
                local puff = SpawnPrefab("halloween_firepuff_cold_"..math.random(3))
                puff.Transform:SetPosition(inst.Transform:GetWorldPosition())
                
                ToggleOffPhysics(inst)
                inst.components.locomotor:Stop()

                inst.AnimState:PlayAnimation("townportal_exit_pst")
            end,

            timeline =
            {
                TimeEvent(18 * FRAMES, function(inst)
                    if inst.sg.statemem.isphysicstoggle then
                        ToggleOnPhysics(inst)
                    end
                end),
                TimeEvent(26 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("nopredict")
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

            onexit = function(inst)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end
            end,
        },
        
        
        -- Bluecap
        State{
            name = "bluecap_general_action",

            onenter = function(inst)
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap and funcap.charge == 12 then
                    mod = 0.2
                elseif funcap and funcap.charge > 6 then
                    mod = 0.4
                elseif funcap then
                    mod = 0.7
                end
                if inst.temp_speed_mod then
                    mod = inst.temp_speed_mod * mod
                    inst.temp_speed_mod = nil
                end
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)
                inst.sg:GoToState("dolongaction", mod)
            end,
        },

        State{
            name = "bluecap_fast_action",
            tags = { "doing", "busy", "keepchannelcasting" },

            onenter = function(inst, silent)
                inst.components.locomotor:Stop()
                if inst:HasTag("beaver") then
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                else
                    inst.AnimState:PlayAnimation("pickup")
                    inst.AnimState:PushAnimation("pickup_pst", false)
                end
                
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap.charge == 12 then
                    mod = 0.2
                elseif funcap.charge > 6 then
                    mod = 0.4
                else
                    mod = 0.7
                end
                if inst.temp_speed_mod then
                    mod = inst.temp_speed_mod * mod
                    inst.temp_speed_mod = nil
                end
                    
                inst.sg.statemem.action = inst.bufferedaction
                inst.sg.statemem.silent = silent
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)
                inst.sg:SetTimeout(10 * mod * FRAMES)
            end,

            ontimeout = function(inst)
                if inst.sg.statemem.silent then
                    inst.components.talker:IgnoreAll("silentpickup")
                    inst:PerformBufferedAction()
                    inst.components.talker:StopIgnoringAll("silentpickup")
                else
                    inst:PerformBufferedAction()
                end
                inst.sg:GoToState("idle", true)
            end,

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                if inst.bufferedaction == inst.sg.statemem.action and
                (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                    inst:ClearBufferedAction()
                end
            end,
        },

        -- Bluecap chopping states
        State{
            name = "bluecap_chop_start",
            tags = { "prechop", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation(inst:HasTag("woodcutter") and "woodie_chop_pre" or "chop_pre")
                inst:AddTag("prechop")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                else
                    mod = 0.7
                end
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
            end,

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg.statemem.chopping = true
                        inst.sg:GoToState("bluecap_chop")
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                if not inst.sg.statemem.chopping then
                    inst:RemoveTag("prechop")
                end
            end,
        },

        State{
            name = "bluecap_chop",
            tags = { "prechop", "chopping", "working" },

            onenter = function(inst)
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst.sg.statemem.iswoodcutter = inst:HasTag("woodcutter")
                inst.AnimState:PlayAnimation(inst.sg.statemem.iswoodcutter and "woodie_chop_loop" or "chop_loop")
                inst:AddTag("prechop")
                
                
            end,

            timeline =
            {
                ----------------------------------------------
                --Woodcutter chop
                
                
                -- 0.1
                TimeEvent(2 * FRAMES * 0.1, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(5 * FRAMES * 0.1, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(10 * FRAMES * 0.1, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 and
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(12 * FRAMES * 0.1, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
                
                -- 0.4
                TimeEvent(2 * FRAMES * 0.4, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(5 * FRAMES * 0.4, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(10 * FRAMES * 0.4, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 and 
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(12 * FRAMES * 0.4, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
                
                -- 0.7
                TimeEvent(2 * FRAMES * 0.7, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(5 * FRAMES * 0.7, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(10 * FRAMES * 0.7, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 and
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(12 * FRAMES * 0.7, function(inst)
                    if inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
                
                ----------------------------------------------
                --Normal chop
                
                -- 0.1
                TimeEvent(2 * FRAMES * 0.1, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.1, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.1, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 and
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(16 * FRAMES * 0.1, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
                
                -- 0.4
                TimeEvent(2 * FRAMES * 0.4, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.4, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.4, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 and
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(16 * FRAMES * 0.4, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
                
                -- 0.7
                TimeEvent(2 * FRAMES * 0.7, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.7, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("prechop")
                        inst:RemoveTag("prechop")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.7, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 and
                        inst.components.playercontroller ~= nil and
                        inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) and
                        inst.sg.statemem.action ~= nil and
                        inst.sg.statemem.action:IsValid() and
                        inst.sg.statemem.action.target ~= nil and
                        inst.sg.statemem.action.target.components.workable ~= nil and
                        inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                        inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                        CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                        --No fast-forward when repeat initiated on server
                        inst.sg.statemem.action.options.no_predict_fastforward = true
                        inst:ClearBufferedAction()
                        inst:PushBufferedAction(inst.sg.statemem.action)
                    end
                end),

                TimeEvent(16 * FRAMES * 0.7, function(inst)
                    if not inst.sg.statemem.iswoodcutter and inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("chopping")
                    end
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        --We don't have a chop_pst animation
                        inst.sg:GoToState("idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)    
                inst:RemoveTag("prechop")
                inst.dyn_anim_mod = nil
            end,
        },

        -- Bluecap mining states
        
        State{
            name = "bluecap_mine_start",
            tags = { "premine", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("pickaxe_pre")
                inst:AddTag("premine")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                else
                    mod = 0.7
                end
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)
                
            end,

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg.statemem.mining = true
                        inst.sg:GoToState("bluecap_mine")
                    end
                end),
            },

            onexit = function(inst)
                if not inst.sg.statemem.mining then
                    inst:RemoveTag("premine")
                end
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },    
        

        State{
            name = "bluecap_mine",
            tags = { "premine", "mining", "working" },

            onenter = function(inst)
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst.AnimState:PlayAnimation("pickaxe_loop")
                inst:AddTag("premine")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
            end,

            timeline =
            {
            
                -- 0.7
                TimeEvent(7 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.action ~= nil then
                            PlayMiningFX(inst, inst.sg.statemem.action.target)
                        end
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("premine")
                        inst:RemoveTag("premine")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_PRIMARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                
                -- 0.4
                TimeEvent(7 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.action ~= nil then
                            PlayMiningFX(inst, inst.sg.statemem.action.target)
                        end
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("premine")
                        inst:RemoveTag("premine")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_PRIMARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),            
                
                
                -- 0.1
                TimeEvent(7 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.action ~= nil then
                            PlayMiningFX(inst, inst.sg.statemem.action.target)
                        end
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("premine")
                        inst:RemoveTag("premine")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_PRIMARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation("pickaxe_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst:RemoveTag("premine")
                inst.dyn_anim_mod = nil
            end,
        },
        

        State{
            name = "bluecap_hammer_start",
            tags = { "prehammer", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("pickaxe_pre")
                inst:AddTag("prehammer")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                else
                    mod = 0.7
                end
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)
                
            end,

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg.statemem.hammering = true
                        inst.sg:GoToState("hammer")
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                if not inst.sg.statemem.hammering then
                    inst:RemoveTag("prehammer")
                end
            end,
        },

        State{
            name = "bluecap_hammer",
            tags = { "prehammer", "hammering", "working" },

            onenter = function(inst)    
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst.AnimState:PlayAnimation("pickaxe_loop")
                inst:AddTag("prehammer")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
            end,

            timeline =
            {
                -- 0.7
                TimeEvent(7 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod ==  0.7 then
                        inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod ==  0.7 then
                        inst.sg:RemoveStateTag("prehammer")
                        inst:RemoveTag("prehammer")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod ==  0.7 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ALTACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                
                -- 0.4
                TimeEvent(7 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod ==  0.4 then
                        inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod ==  0.4 then
                        inst.sg:RemoveStateTag("prehammer")
                        inst:RemoveTag("prehammer")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod ==  0.4 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ALTACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),            
                
                -- 0.1
                TimeEvent(7 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod ==  0.1 then
                        inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
                        inst.sg.statemem.recoilstate = "mine_recoil"
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(9 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod ==  0.1 then
                        inst.sg:RemoveStateTag("prehammer")
                        inst:RemoveTag("prehammer")
                    end
                end),

                TimeEvent(14 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod ==  0.1 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ALTACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),                
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation("pickaxe_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst:RemoveTag("prehammer")
                inst.dyn_anim_mod = nil
            end,
        },
        
        State{
            name = "bluecap_dig_start",
            tags = { "predig", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("shovel_pre")
                inst:AddTag("predig")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 1
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                else
                    mod = 0.7
                end
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)
            end,

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg.statemem.digging = true
                        inst.sg:GoToState("bluecap_dig")
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                if not inst.sg.statemem.digging then
                    inst:RemoveTag("predig")
                end
            end,
        },

        State{
            name = "bluecap_dig",
            tags = { "predig", "digging", "working" },

            onenter = function(inst)
                inst.AnimState:PlayAnimation("shovel_loop")
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst:AddTag("predig")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
            end,

            timeline =
            {    
            
            
                -- 0.7
                TimeEvent(15 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("predig")
                        inst:RemoveTag("predig")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(35 * FRAMES*0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                
                -- 0.4
                TimeEvent(15 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("predig")
                        inst:RemoveTag("predig")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(35 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                
                -- 0.1
                TimeEvent(15 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("predig")
                        inst:RemoveTag("predig")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(35 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.components.playercontroller ~= nil and
                            inst.components.playercontroller:IsAnyOfControlsPressed(
                                CONTROL_SECONDARY,
                                CONTROL_ACTION,
                                CONTROL_CONTROLLER_ACTION) and
                            inst.sg.statemem.action ~= nil and
                            inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation("shovel_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst:RemoveTag("predig")
            end,
        },
        
        State{
            name = "bluecap_till_start",
            tags = { "doing", "busy" },

            onenter = function(inst)
        
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
                inst.components.locomotor:Stop()
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool ~= nil and equippedTool.components.tool ~= nil and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
                    --upside down tool build
                    inst.AnimState:PlayAnimation("till2_pre")
                else
                    inst.AnimState:PlayAnimation("till_pre")
                end
            end,
            
            
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
            
            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("bluecap_till")
                    end
                end),
            },
        },

        State{
            name = "bluecap_till",
            tags = { "doing", "busy", "tilling" },

            onenter = function(inst)
            
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool ~= nil and equippedTool.components.tool ~= nil and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
                    --upside down tool build
                    inst.sg.statemem.fliptool = true
                    inst.AnimState:PlayAnimation("till2_loop")
                else
                    inst.AnimState:PlayAnimation("till_loop")
                end
            end,

            timeline =
            {    
                -- 0.7
                TimeEvent(4 * FRAMES * 0.7, function(inst) if inst.dyn_anim_mod == 0.7 then inst.SoundEmitter:PlaySound("dontstarve/wilson/dig") end end),
                TimeEvent(11 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then 
                        inst:PerformBufferedAction()
                    end
                end),
                TimeEvent(12 * FRAMES * 0.7, function(inst) 
                    if inst.dyn_anim_mod == 0.7 then 
                        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
                    end
                end),
                TimeEvent(22 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then 
                        inst.sg:RemoveStateTag("busy")
                    end
                end),
                
                -- 0.4
                TimeEvent(4 * FRAMES * 0.4, function(inst) if inst.dyn_anim_mod == 0.4 then inst.SoundEmitter:PlaySound("dontstarve/wilson/dig") end end),
                TimeEvent(11 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then 
                        inst:PerformBufferedAction()
                    end
                end),
                TimeEvent(12 * FRAMES * 0.4, function(inst) 
                    if inst.dyn_anim_mod == 0.4 then 
                        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
                    end
                end),
                TimeEvent(22 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then 
                        inst.sg:RemoveStateTag("busy")
                    end
                end),
                
                -- 0.1
                TimeEvent(4 * FRAMES * 0.1, function(inst) if inst.dyn_anim_mod == 0.1 then inst.SoundEmitter:PlaySound("dontstarve/wilson/dig") end end),
                TimeEvent(11 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then 
                        inst:PerformBufferedAction()
                    end
                end),
                TimeEvent(12 * FRAMES * 0.1, function(inst) 
                    if inst.dyn_anim_mod == 0.1 then 
                        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
                    end
                end),
                TimeEvent(22 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then 
                        inst.sg:RemoveStateTag("busy")
                    end
                end),
                
                
            },
            
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
            
            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation(inst.sg.statemem.fliptool and "till2_pst" or "till_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },
        },
        
        State{
            name = "bluecap_gnaw",
            tags = { "gnawing", "working" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.sg.statemem.action = inst:GetBufferedAction()
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                inst:AddTag("gnawing")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
            end,

            timeline =
            {
                -- 0.7
                TimeEvent(6 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.action ~= nil then
                            local target = inst.sg.statemem.action.target
                            if target ~= nil and target:IsValid() then
                                if inst.sg.statemem.action.action == ACTIONS.MINE then
                                    inst.sg.statemem.recoilstate = "gnaw_recoil"
                                    PlayMiningFX(inst, target)
                                elseif inst.sg.statemem.action.action == ACTIONS.HAMMER then
                                    inst.sg.statemem.rmb = true
                                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                                elseif inst.sg.statemem.action.action == ACTIONS.DIG then
                                    inst.sg.statemem.rmb = target:HasTag("sign")
                                    SpawnPrefab("shovel_dirt").Transform:SetPosition(target.Transform:GetWorldPosition())
                                end
                            end
                        end
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(7 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("gnawing")
                        inst:RemoveTag("gnawing")
                    end
                end),

                TimeEvent(8 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.action == nil or
                            inst.sg.statemem.action.action == nil or
                            inst.components.playercontroller == nil then
                            return
                        end
                        if inst.sg.statemem.rmb then
                            if not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_SECONDARY,
                                    CONTROL_CONTROLLER_ALTACTION) then
                                return
                            end
                        elseif not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_PRIMARY,
                                    CONTROL_ACTION,
                                    CONTROL_CONTROLLER_ACTION) then
                            return
                        end
                        if inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target.components.workable:GetWorkAction() == inst.sg.statemem.action.action and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                -- 0.4
                TimeEvent(6 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.action ~= nil then
                            local target = inst.sg.statemem.action.target
                            if target ~= nil and target:IsValid() then
                                if inst.sg.statemem.action.action == ACTIONS.MINE then
                                    inst.sg.statemem.recoilstate = "gnaw_recoil"
                                    PlayMiningFX(inst, target)
                                elseif inst.sg.statemem.action.action == ACTIONS.HAMMER then
                                    inst.sg.statemem.rmb = true
                                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                                elseif inst.sg.statemem.action.action == ACTIONS.DIG then
                                    inst.sg.statemem.rmb = target:HasTag("sign")
                                    SpawnPrefab("shovel_dirt").Transform:SetPosition(target.Transform:GetWorldPosition())
                                end
                            end
                        end
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(7 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("gnawing")
                        inst:RemoveTag("gnawing")
                    end
                end),

                TimeEvent(8 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.action == nil or
                            inst.sg.statemem.action.action == nil or
                            inst.components.playercontroller == nil then
                            return
                        end
                        if inst.sg.statemem.rmb then
                            if not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_SECONDARY,
                                    CONTROL_CONTROLLER_ALTACTION) then
                                return
                            end
                        elseif not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_PRIMARY,
                                    CONTROL_ACTION,
                                    CONTROL_CONTROLLER_ACTION) then
                            return
                        end
                        if inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target.components.workable:GetWorkAction() == inst.sg.statemem.action.action and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
                end),
                -- 0.1
                TimeEvent(6 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.action ~= nil then
                            local target = inst.sg.statemem.action.target
                            if target ~= nil and target:IsValid() then
                                if inst.sg.statemem.action.action == ACTIONS.MINE then
                                    inst.sg.statemem.recoilstate = "gnaw_recoil"
                                    PlayMiningFX(inst, target)
                                elseif inst.sg.statemem.action.action == ACTIONS.HAMMER then
                                    inst.sg.statemem.rmb = true
                                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                                elseif inst.sg.statemem.action.action == ACTIONS.DIG then
                                    inst.sg.statemem.rmb = target:HasTag("sign")
                                    SpawnPrefab("shovel_dirt").Transform:SetPosition(target.Transform:GetWorldPosition())
                                end
                            end
                        end
                        inst:PerformBufferedAction()
                    end
                end),

                TimeEvent(7 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("gnawing")
                        inst:RemoveTag("gnawing")
                    end
                end),

                TimeEvent(8 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.action == nil or
                            inst.sg.statemem.action.action == nil or
                            inst.components.playercontroller == nil then
                            return
                        end
                        if inst.sg.statemem.rmb then
                            if not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_SECONDARY,
                                    CONTROL_CONTROLLER_ALTACTION) then
                                return
                            end
                        elseif not inst.components.playercontroller:IsAnyOfControlsPressed(
                                    CONTROL_PRIMARY,
                                    CONTROL_ACTION,
                                    CONTROL_CONTROLLER_ACTION) then
                            return
                        end
                        if inst.sg.statemem.action:IsValid() and
                            inst.sg.statemem.action.target ~= nil and
                            inst.sg.statemem.action.target.components.workable ~= nil and
                            inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                            inst.sg.statemem.action.target.components.workable:GetWorkAction() == inst.sg.statemem.action.action and
                            CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                            --No fast-forward when repeat initiated on server
                            inst.sg.statemem.action.options.no_predict_fastforward = true
                            inst:ClearBufferedAction()
                            inst:PushBufferedAction(inst.sg.statemem.action)
                        end
                    end
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

            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst:RemoveTag("gnawing")
            end,
        },

        State{
            name = "bluecap_terraform",
            tags = { "busy" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("shovel_pre")
                inst.AnimState:PushAnimation("shovel_loop", false)
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
            
            end,

            timeline =
            {
                -- 0.1
                TimeEvent(25 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("busy")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                    end
                end),
                -- 0.4
                TimeEvent(25 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("busy")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                    end
                end),
                -- 0.7
                TimeEvent(25 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("busy")
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                    end
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.AnimState:PlayAnimation("shovel_pst")
                        inst.sg:GoToState("idle", true)
                    end
                end),
            },
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)    
            end,
        },

        State{
            name = "bluecap_bugnet_start",
            tags = { "prenet", "working", "autopredict" },

            onenter = function(inst)
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("bugnet_pre")
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("bluecap_bugnet")
                    end
                end),
            },
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },

        State{
            name = "bluecap_bugnet",
            tags = { "prenet", "netting", "working", "autopredict" },

            onenter = function(inst)
                inst.AnimState:PlayAnimation("bugnet")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet", nil, nil, true)
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
            end,

            timeline =
            {
                -- 0.1
                TimeEvent(10*FRAMES*0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        local buffaction = inst:GetBufferedAction()
                        local tool = buffaction ~= nil and buffaction.invobject or nil
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("prenet")
                        inst.SoundEmitter:PlaySound(tool ~= nil and tool.overridebugnetsound or "dontstarve/wilson/dig")
                    end
                end),
                
                -- 0.4
                TimeEvent(10*FRAMES*0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        local buffaction = inst:GetBufferedAction()
                        local tool = buffaction ~= nil and buffaction.invobject or nil
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("prenet")
                        inst.SoundEmitter:PlaySound(tool ~= nil and tool.overridebugnetsound or "dontstarve/wilson/dig")
                    end
                end),

                -- 0.7
                TimeEvent(10*FRAMES*0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        local buffaction = inst:GetBufferedAction()
                        local tool = buffaction ~= nil and buffaction.invobject or nil
                        inst:PerformBufferedAction()
                        inst.sg:RemoveStateTag("prenet")
                        inst.SoundEmitter:PlaySound(tool ~= nil and tool.overridebugnetsound or "dontstarve/wilson/dig")
                    end
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
            
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
            
        },


        State{
            name = "bluecap_row",
            tags = { "rowing", "doing" },

            onenter = function(inst)
                local locomotor = inst.components.locomotor
                local target_pos = nil
                if locomotor.bufferedaction then
                    target_pos = locomotor.bufferedaction:GetActionPoint()
                    if target_pos == nil then
                        target_pos = locomotor.bufferedaction.target:GetPosition()
                        inst:ForceFacePoint(target_pos:Get())
                    end
                else
                    target_pos = Vector3(inst.Transform:GetWorldPosition())
                end
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
                inst:AddTag("is_rowing")
                inst.AnimState:PlayAnimation("row_pre")
                locomotor:Stop()

                local my_x, my_y, my_z = inst.Transform:GetWorldPosition()
                local boat_x, boat_y, boat_z = 0, 0, 0
                local boat = inst:GetCurrentPlatform()
                if boat ~= nil then
                    boat_x, boat_y, boat_z = boat.Transform:GetWorldPosition()
                end

                -- if is_client then
                    -- inst:PerformPreviewBufferedAction()
                -- end

                local target_x, target_z = nil,nil

                if inst.components.playercontroller.isclientcontrollerattached then
                    local dir_x, dir_z = VecUtil_Normalize(my_x - boat_x, my_z - boat_z)
                    target_x, target_z = my_x + dir_x, my_z + dir_z
                else
                    target_x, target_z = target_pos.x, target_pos.z
                end

                local delta_target_x, delta_target_z = target_x- my_x, target_z - my_z
                local delta_boat_x, delta_boat_z = my_x - boat_x, my_z - boat_z

                local camera_down_vec = TheCamera:GetDownVec()
                local camera_right_vec = TheCamera:GetRightVec()

                local camera_up_x, camera_up_z = -camera_down_vec.x, -camera_down_vec.z
                local camera_right_x, camera_right_z = camera_right_vec.x, camera_right_vec.z

                local delta_target_x_camera, delta_target_z_camera = delta_target_x * camera_right_x + delta_target_z * camera_right_z, delta_target_x * camera_up_x + delta_target_z * camera_up_z
                local delta_boat_x_camera, delta_boat_z_camera = delta_boat_x * camera_right_x + delta_boat_z * camera_right_z, delta_boat_x * camera_up_x + delta_boat_z * camera_up_z

                local target_anim = "row_medium"
                local debug_id = ""
                local is_facing_horizontal = math.abs(delta_target_x_camera) > math.abs(delta_target_z_camera)
                local is_on_upper_half = delta_boat_z_camera > 0
                local is_on_right_side = delta_boat_x_camera > 0
                local is_facing_right = delta_target_x_camera > 0
                local is_facing_up = delta_target_z_camera > 0

                if is_facing_horizontal then
                    if is_on_upper_half then
                        if is_facing_right then
                            target_anim = "row_medium_off"
                            debug_id = "is_facing_horizontal, is_on_upper_half, is_facing_right"
                        else
                            target_anim = "row_medium_off"
                            debug_id = "is_facing_horizontal, is_on_upper_half, is_facing_left"
                        end
                    else
                        if is_facing_right then
                            target_anim = "row_medium"
                            debug_id = "is_facing_horizontal, is_on_lower_half, is_facing_right"
                        else
                            target_anim = "row_medium"
                            debug_id = "is_facing_horizontal, is_on_lower_half, is_facing_left"
                        end
                    end
                else
                    if is_on_right_side then
                        if is_facing_up then
                            target_anim = "row_medium"
                            debug_id = "is_facing_vertical, is_on_right_side, is_facing_up"
                        else
                            target_anim = "row_medium_off"
                            debug_id = "is_facing_vertical, is_on_right_side, is_facing_down"
                        end
                    else
                        if is_facing_up then
                            target_anim = "row_medium_off"
                            debug_id = "is_facing_vertical, is_on_left_side, is_facing_up"
                        else
                            target_anim = "row_medium"
                            debug_id = "is_facing_vertical, is_on_left_side, is_facing_down"
                        end
                    end
                end

                inst.AnimState:PushAnimation(target_anim, false)

                inst:ForceFacePoint(target_x, 0, target_z)
            end,

            onexit = function(inst)
                inst:RemoveTag("is_rowing")
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,

            timeline =
            {
                -- 0.7
                TimeEvent(5 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        --if not is_client then
                            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
                        --end
                    end
                end),

                TimeEvent(8 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        --if not is_client then
                            inst:PerformBufferedAction()
                        --end
                    end
                end),

                TimeEvent(13 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst.sg:RemoveStateTag("rowing")
                    end
                end),
                
                -- 0.4
                TimeEvent(5 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        --if not is_client then
                            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
                        --end
                    end
                end),

                TimeEvent(8 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        --if not is_client then
                            inst:PerformBufferedAction()
                        --end
                    end
                end),

                TimeEvent(13 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst.sg:RemoveStateTag("rowing")
                    end
                end),
                
                -- 0.1
                TimeEvent(5 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        --if not is_client then
                            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
                        --end
                    end
                end),

                TimeEvent(8 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        --if not is_client then
                            inst:PerformBufferedAction()
                        --end
                    end
                end),

                TimeEvent(13 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst.sg:RemoveStateTag("rowing")
                    end
                end),
            },

            events =
            {
                EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("row_idle")
                end),
            },

            ontimeout = function(inst)
                --if is_client then
                    inst:ClearBufferedAction()
                    inst.sg:GoToState("idle")
                --end
            end,
        },
        State{
            name = "bluecap_quickeat",
            tags = { "busy", "keep_pocket_rummage" },

            onenter = function(inst, foodinfo)
                inst.components.locomotor:Stop()
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                local feed = foodinfo and foodinfo.feed
                if feed ~= nil then
                    inst.components.locomotor:Clear()
                    inst:ClearBufferedAction()
                    inst.sg.statemem.feed = foodinfo.feed
                    inst.sg.statemem.feeder = foodinfo.feeder
                    inst.sg:AddStateTag("pausepredict")
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:RemotePausePrediction()
                    end
                elseif inst:GetBufferedAction() then
                    feed = inst:GetBufferedAction().invobject
                end

                if feed == nil or
                    feed.components.edible == nil or
                    feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
                end

                if inst.components.inventory:IsHeavyLifting() and
                    not inst.components.rider:IsRiding() then
                    inst.AnimState:PlayAnimation("heavy_quick_eat")
                else
                    inst.AnimState:PlayAnimation("quick_eat_pre")
                    inst.AnimState:PushAnimation("quick_eat", false)
                end

                inst.components.hunger:Pause()
            end,

            timeline =
            {
                -- 0.1
                TimeEvent(12 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.feed ~= nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        else
                            inst:PerformBufferedAction()
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(21 * 0.1, function(inst)            
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        else
                            TryResumePocketRummage(inst)
                        end
                    end
                end),
                
                -- 0.4
                TimeEvent(12 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.feed ~= nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        else
                            inst:PerformBufferedAction()
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(21 * 0.4, function(inst)            
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        else
                            TryResumePocketRummage(inst)
                        end
                    end
                end),
                
                -- 0.7
                TimeEvent(12 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.feed ~= nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        else
                            inst:PerformBufferedAction()
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(21 * 0.7, function(inst)            
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        else
                            TryResumePocketRummage(inst)
                        end
                    end
                end),
            },

            events =
            {
                EventHandler("queue_post_eat_state", function(inst, data)
                    --NOTE: this event can trigger instantly instead of buffered
                    if data ~= nil then
                        inst.sg.statemem.queued_post_eat_state = data.post_eat_state
                        if data.nointerrupt then
                            inst.sg:AddStateTag("nointerrupt")
                        end
                    end
                end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state or "idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.SoundEmitter:KillSound("eating")
                if not GetGameModeProperty("no_hunger") then
                    inst.components.hunger:Resume()
                end
                if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                    inst.sg.statemem.feed:Remove()
                end
                CheckPocketRummageMem(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },    
        
        State{
            name = "bluecap_eat",
            tags = { "busy", "nodangle", "keep_pocket_rummage" },

            onenter = function(inst, foodinfo)
                inst.components.locomotor:Stop()
                
                local funcap = FindBlueFuncap(inst)
                local mod = 0.7
                if funcap.charge == 12 then
                    mod = 0.1
                elseif funcap.charge > 6 then
                    mod = 0.4
                end
                
                inst.dyn_anim_mod = mod
                
                
                inst.AnimState:SetDeltaTimeMultiplier(1/mod)    
                
                local feed = foodinfo and foodinfo.feed
                if feed ~= nil then
                    inst.components.locomotor:Clear()
                    inst:ClearBufferedAction()
                    inst.sg.statemem.feed = foodinfo.feed
                    inst.sg.statemem.feeder = foodinfo.feeder
                    inst.sg:AddStateTag("pausepredict")
                    if inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:RemotePausePrediction()
                    end
                elseif inst:GetBufferedAction() then
                    feed = inst:GetBufferedAction().invobject
                end

                if feed == nil or
                    feed.components.edible == nil or
                    feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
                end

                if feed ~= nil and feed.components.soul ~= nil then
                    inst.sg.statemem.soulfx = SpawnPrefab("wortox_eat_soul_fx")
                    inst.sg.statemem.soulfx.entity:SetParent(inst.entity)
                    if inst.components.rider:IsRiding() then
                        inst.sg.statemem.soulfx:MakeMounted()
                    end
                end

                if inst.components.inventory:IsHeavyLifting() and
                    not inst.components.rider:IsRiding() then
                    inst.AnimState:PlayAnimation("heavy_eat")
                else
                    inst.AnimState:PlayAnimation("eat_pre")
                    inst.AnimState:PushAnimation("eat", false)
                end

                inst.components.hunger:Pause()
            end,

            timeline =
            {
                -- 0.1
                TimeEvent(28 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.feed == nil then
                            inst:PerformBufferedAction()
                        elseif inst.sg.statemem.feed.components.soul == nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        elseif inst.components.souleater ~= nil then
                            inst.components.souleater:EatSoul(inst.sg.statemem.feed)
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                    end
                end),
                TimeEvent(30 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(52 * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        end
                    end
                end),
                TimeEvent(70 * FRAMES * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        inst.SoundEmitter:KillSound("eating")
                    end
                end),
                FrameEvent(94 * 0.1, function(inst)
                    if inst.dyn_anim_mod == 0.1 then
                        TryResumePocketRummage(inst)
                    end
                end),
                
                -- 0.4
                TimeEvent(28 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.feed == nil then
                            inst:PerformBufferedAction()
                        elseif inst.sg.statemem.feed.components.soul == nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        elseif inst.components.souleater ~= nil then
                            inst.components.souleater:EatSoul(inst.sg.statemem.feed)
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                    end
                end),
                TimeEvent(30 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(52 * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        end
                    end
                end),
                TimeEvent(70 * FRAMES * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        inst.SoundEmitter:KillSound("eating")
                    end
                end),
                FrameEvent(94 * 0.4, function(inst)
                    if inst.dyn_anim_mod == 0.4 then
                        TryResumePocketRummage(inst)
                    end
                end),
                -- 0.7
                TimeEvent(28 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.feed == nil then
                            inst:PerformBufferedAction()
                        elseif inst.sg.statemem.feed.components.soul == nil then
                            inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                        elseif inst.components.souleater ~= nil then
                            inst.components.souleater:EatSoul(inst.sg.statemem.feed)
                        end
                        --NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
                    end
                end),
                TimeEvent(30 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.queued_post_eat_state == nil then
                            inst.sg:RemoveStateTag("busy")
                            inst.sg:RemoveStateTag("pausepredict")
                        end
                    end
                end),
                FrameEvent(52 * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        if inst.sg.statemem.queued_post_eat_state ~= nil then
                            inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
                        end
                    end
                end),
                TimeEvent(70 * FRAMES * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        inst.SoundEmitter:KillSound("eating")
                    end
                end),
                FrameEvent(94 * 0.7, function(inst)
                    if inst.dyn_anim_mod == 0.7 then
                        TryResumePocketRummage(inst)
                    end
                end),
            },

            events =
            {
                EventHandler("queue_post_eat_state", function(inst, data)
                    --NOTE: this event can trigger instantly instead of buffered
                    if data ~= nil then
                        inst.sg.statemem.queued_post_eat_state = data.post_eat_state
                        if data.nointerrupt then
                            inst.sg:AddStateTag("nointerrupt")
                        end
                    end
                end),
                EventHandler("animqueueover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state or "idle")
                    end
                end),
            },

            onexit = function(inst)
                inst.SoundEmitter:KillSound("eating")
                if not GetGameModeProperty("no_hunger") then
                    inst.components.hunger:Resume()
                end
                if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                    inst.sg.statemem.feed:Remove()
                end
                if inst.sg.statemem.soulfx ~= nil then
                    inst.sg.statemem.soulfx:Remove()
                end
                CheckPocketRummageMem(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
    }

    for k, v in pairs(events) do
        assert(v:is_a(EventHandler), "Non-event added in mod events table!")
        inst.events[v.name] = v
    end

    for k, v in pairs(states) do
        assert(v:is_a(State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

    for k, v in pairs(actionhandlers) do
        assert(v:is_a(ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end
end)

-- Lifting dumbbells can now increase mightiness past 100
if env.GetModConfigData("wolfgang") then
    env.AddStategraphPostInit("wilson", function(inst)
        local _AnimOverFn = inst.states.use_dumbbell_loop.events.animover.fn
        inst.states.use_dumbbell_loop.events.animover.fn = function(inst)
            inst.sg.statemem.dumbbell_anim_done = true
            local mightiness_max = inst.components.mightiness:GetMax()
            local mightiness_overmax = inst.components.mightiness:GetOverMax()
            local overmax_percent = 1 + mightiness_overmax / mightiness_max
            if inst.sg.statemem.queue_stop or inst.components.dumbbelllifter.dumbbell == nil then
                inst.sg:GoToState("use_dumbbell_pst")
            elseif inst.components.dumbbelllifter:Lift() and inst.components.mightiness:GetPercent() < overmax_percent then
                inst.sg:GoToState("use_dumbbell_loop")
            else
                return _AnimOverFn(inst)
            end
        end
    end)
end
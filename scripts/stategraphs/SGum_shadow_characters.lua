require("stategraphs/commonstates")

local easing = require("easing")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.PICKUP, "warly_throw"),
}

local events =
{
    CommonHandlers.OnLocomote(false, true),
    EventHandler("attacked", function(inst, data)
        if not inst.sg:HasStateTag("attack") and not inst.components.health:IsDead() then
            inst.sg:GoToState("disappear")
        end
    end),
    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
    EventHandler("doattack", function(inst, data)
        if not inst.sg:HasStateTag("busy") and not inst.components.health:IsDead() then
            inst.sg:GoToState(inst.charactertype .. "_attack", data.target)
        end
    end),
}

local function GetANewTarget(inst)
    inst.components.combat:DropTarget()
end

local function LightStealTarget(inst)
    if inst:HasTag("um_shadow_walter") then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 4)

        for i, v in ipairs(ents) do
            if v.components.burnable ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
                return true
            elseif v._light ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
                return true
            elseif v._lastpulsesync ~= nil and v.components.timer and v.components.timer:GetTimeLeft("extinguish") then
                return true
            end
        end
    end

    return false
end

local function ConsumeLight(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5)

    for i, v in ipairs(ents) do
        if v.components.burnable ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
            v.components.fueled:DoDelta(-12)

            SpawnPrefab("fuelseeker_circle").Transform:SetPosition(v.Transform:GetWorldPosition())

            --inst:LevelUp()
        elseif v._light ~= nil and v.components.fueled ~= nil and v.components.fueled.consuming then
            v.components.fueled:DoDelta(-8)

            SpawnPrefab("fuelseeker_circle").Transform:SetPosition(v.Transform:GetWorldPosition())

            --inst:LevelUp()
        elseif v._lastpulsesync ~= nil and v.components.timer then
            if v.components.timer:GetTimeLeft("extinguish") ~= nil then
                v.components.timer:SetTimeLeft("extinguish", v.components.timer:GetTimeLeft("extinguish") - 25)

                SpawnPrefab("fuelseeker_circle").Transform:SetPosition(v.Transform:GetWorldPosition())

                --inst:LevelUp()
            end
        end
    end
end

local function DoTalkSound(inst)
    if not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound("dontstarve/characters/" .. inst.charactertype .. "/talk_LP", "talk")
        return true
    end
end

local function StopTalkSound(inst, instant)
    inst.SoundEmitter:KillSound("talk")
end

local function DoMimeAnimations(inst)
    inst.AnimState:PlayAnimation("mime" .. tostring(math.random(13)))
    for k = 1, math.random(2) do
        inst.AnimState:PushAnimation("mime" .. tostring(math.random(13)), false)
    end
end

local states =
{

    State {
        name = "idle",
        tags = { "idle", "canrotate" },
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,

        onupdate = function(inst)
            if LightStealTarget(inst) then
                inst.sg:GoToState("stealing_pre")
            end
        end,
    },

    State {
        name = "stealing_pre",
        tags = { "idle", "canrotate", "stealing", "busy" },

        onenter = function(inst, start_anim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_walter_storytelling_pre")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                --DoTalkSound(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if LightStealTarget(inst) then
                    inst.sg:GoToState("stealing")
                else
                    inst.sg:GoToState("stealing_pst")
                end
            end),
        },
    },

    State {
        name = "stealing",
        tags = { "idle", "canrotate", "stealing", "busy" },

        onenter = function(inst, start_anim)
            DoTalkSound(inst)
            inst.components.locomotor:StopMoving()

            inst.components.talker:Say("AAAAAAAAAAAAAAAAAAA")

            if inst.consumetask == nil then
                inst.consumetask = inst:DoPeriodicTask(0.5, ConsumeLight)
            end

            inst.AnimState:PushAnimation(math.random() < 0.75 and "idle_walter_storytelling" or "idle_walter_storytelling_2")
        end,

        onexit = function(inst)
            StopTalkSound(inst)

            if inst.consumetask ~= nil then
                inst.consumetask:Cancel()
                inst.consumetask = nil
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if LightStealTarget(inst) then
                    inst.sg:GoToState("stealing")
                else
                    inst.sg:GoToState("stealing_pst")
                end
            end),
        },
    },

    State {
        name = "stealing_pst",
        tags = { "idle", "canrotate", "stealing", "busy" },

        onenter = function(inst, start_anim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_walter_storytelling_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "laugh_at_you",
        tags = { "busy" },
        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("emote_laugh")

            inst.SoundEmitter:PlaySound("UCSounds/shadow_wixie/laugh")
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
        name = "attack",
        tags = { "attack", "abouttoattack", "busy" },

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("punch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")

            inst.components.combat:StartAttack()
            if target == nil then
                target = inst.components.combat.target
            end
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.target = target
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("abouttoattack")
                --inst.components.combat:DoAttack(inst.sg.statemem.target)

                local other = inst.sg.statemem.target

                if other:HasTag("creatureknockbackable") then
                    other:PushEvent("knockback", { knocker = inst, radius = 20, strengthmult = 1 })
                else
                    other:PushEvent("knockback", { knocker = inst, radius = 20, strengthmult = 1 })
                end
            end),
            TimeEvent(12 * FRAMES, function(inst) -- Keep FRAMES time synced up with ShouldKiteProtector.
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(13 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("attack")
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
            GetANewTarget(inst)

            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State {
        name = "wickerbottom_attack",
        tags = { "attack", "doing", "busy" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.components.combat:StartAttack()
            inst:PerformBufferedAction()

            local pickabook = math.random()

            if pickabook > 0.66 then
                inst.sg.statemem.bookspellprefab = "bigshadowtentacle"
                inst.sg.statemem.bookfx = SpawnPrefab("fx_tentacles_under_book")
                inst.sg.statemem.bookfx.entity:SetParent(inst.entity)
                inst.sg.statemem.bookfx.Follower:FollowSymbol(inst.GUID, "swap_book_fx_under", 0, 0, 0, true)

                inst.sg.statemem.bookfx.AnimState:SetMultColour(0, 0, 0, .3)

                inst.AnimState:OverrideSymbol("book_open", "swap_books", "book_tentacles_open")
                inst.AnimState:OverrideSymbol("book_closed", "swap_books", "book_tentacles_closed")
            elseif pickabook < 0.33 then
                inst.sg.statemem.bookspellprefab = "um_shadow_canary"
                inst.sg.statemem.bookfx = SpawnPrefab("fx_book_birds")
                inst.sg.statemem.bookfx.entity:SetParent(inst.entity)

                --inst.sg.statemem.bookfx.AnimState:SetMultColour(0, 0, 0, .6)

                --inst.sg.statemem.bookfx.Follower:FollowSymbol(inst.GUID, "swap_book_fx_under", 0, 0, 0, true)
                inst.AnimState:OverrideSymbol("book_open", "swap_books", "book_birds_open")
                inst.AnimState:OverrideSymbol("book_closed", "swap_books", "book_birds_closed")
            else
                inst.sg.statemem.bookspellprefab = "hound_lightning"
                inst.sg.statemem.bookfx = SpawnPrefab("fx_lightning_over_book")
                inst.sg.statemem.bookfx.entity:SetParent(inst.entity)
                inst.sg.statemem.bookfx.Follower:FollowSymbol(inst.GUID, "swap_book_fx_over", 0, 0, 0, true)

                inst.sg.statemem.bookfx.AnimState:SetMultColour(0, 0, 0, .6)

                inst.AnimState:OverrideSymbol("book_open", "swap_books", "book_brimstone_open")
                inst.AnimState:OverrideSymbol("book_closed", "swap_books", "book_brimstone_closed")
            end

            inst.AnimState:PlayAnimation("book")

            inst.sg.statemem.symbolsoverridden = true
        end,

        timeline =
        {
            TimeEvent(44 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
                inst.DoSpell(inst, inst.sg.statemem.bookspellprefab)
            end),

            TimeEvent(51 * FRAMES, function(inst)
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

            if inst.sg.statemem.bookfx ~= nil and inst.sg.statemem.bookfx:IsValid() then
                inst.sg.statemem.bookfx:Remove()
            end
        end,
    },

    State {
        name = "wortox_attack",
        tags = { "attack", "doing", "busy" },

        onenter = function(inst, data)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil and buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() and not inst:PerformBufferedAction() then
                    inst.sg:GoToState("wortox_attack_jumpin")
                end
            end),
        },
    },

    State {
        name = "wortox_attack_jumpin",
        tags = { "busy" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wortox_portal_jumpin")
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("wortox_portal_jumpin_fx").Transform:SetPosition(x, y, z)

            local dest = inst.components.combat.target and inst.components.combat.target:GetPosition()
            if dest ~= nil and math.random() > 0.2 then
                inst.sg.statemem.dest = dest
                inst:ForceFacePoint(dest)
            else
                local x, y, z = inst.Transform:GetWorldPosition()
                inst.sg.statemem.dest = inst:GetPosition()
                inst:ForceFacePoint(dest)
            end


            inst.sg:SetTimeout(4 + math.random(3))
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .7)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
            end),
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:AddStateTag("noattack")
                inst.components.health:SetInvincible(true)
                --inst.DynamicShadow:Enable(false)
            end),

            TimeEvent(2, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
            end),

            TimeEvent(3, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
            end),

            TimeEvent(4, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
            end),

            TimeEvent(6, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
            end),

            TimeEvent(7, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.portaljumping = true
            inst.sg:GoToState("wortox_attack_jumpout", { dest = inst.sg.statemem.dest })
        end,

        onexit = function(inst)
            if not inst.sg.statemem.portaljumping then
                inst.components.health:SetInvincible(false)
            end
        end,
    },

    State {
        name = "wortox_attack_jumpout",
        tags = { "busy", "nopredict", "nomorph", "noattack", "nointerrupt" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wortox_portal_jumpout")

            local dest = data and data.dest or nil
            if dest ~= nil then
                inst.Physics:Teleport(dest:Get())
            else
                dest = inst:GetPosition()
            end

            SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(dest:Get())
            inst.sg:SetTimeout(14 * FRAMES)
            inst.components.health:SetInvincible(true)
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out") end),
            TimeEvent(7 * FRAMES, function(inst)
                inst.components.health:SetInvincible(false)
                inst.sg:RemoveStateTag("noattack")
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")

                local x, y, z = inst.Transform:GetWorldPosition()
                local players = TheSim:FindEntities(x, y, z, 3, { "player" }, { "playerghost" })

                for i, v in ipairs(players) do
                    if v:IsValid() then
                        if v.components.combat ~= nil
                            and v.components.health ~= nil
                            and not v.components.health:IsDead() then
                            if v.components.combat:CanBeAttacked() then
                                v.components.combat:GetAttacked(inst, 30)
                            end
                        end
                    end
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                --inst.DynamicShadow:Enable(true)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
    },

    State {
        name = "wendy_attack",
        tags = { "doing", "busy", "attack" },

        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wendy_commune_pre")
            inst.AnimState:PushAnimation("wendy_commune_pst", false)

            inst.AnimState:OverrideSymbol("flower", "wendy_channel_flower", "flower")
        end,

        timeline =
        {
            TimeEvent(35 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.CommandAbby(inst)
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
            inst.AnimState:ClearOverrideSymbol("flower")
        end,
    },

    State {
        name = "wes_attack",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_make", "make")
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_blowup")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                --inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
            inst.AnimState:PlayAnimation("build_pst")
            inst:PerformBufferedAction()

            inst.MakeBalloon(inst)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.swes_balloon_count < 5 then
                    inst.swes_balloon_count = inst.swes_balloon_count + 1
                    inst.sg:GoToState("wes_attack")
                elseif inst.AnimState:AnimDone() then
                    inst.swes_balloon_count = 0
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make")
            if inst.bufferedaction == inst.sg.statemem.action and
                (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                inst:ClearBufferedAction()
            end
        end,
    },

    State {
        name = "wanda_attack",
        tags = { "attack", "abouttoattack" },

        onenter = function(inst)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period


            inst.AnimState:PlayAnimation("pocketwatch_atk_pre")
            inst.AnimState:PushAnimation("pocketwatch_atk", false)
            cooldown = math.max(cooldown, 15 * FRAMES)
            inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow", nil, nil, true)
            inst.AnimState:Show("pocketwatch_weapon_fx")

            inst.sg:SetTimeout(cooldown)

            if target ~= nil then
                if target:IsValid() then
                    inst:FacePoint(target:GetPosition())
                    inst.sg.statemem.attacktarget = target
                    inst.sg.statemem.retarget = target
                end
            end
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
            TimeEvent(17 * FRAMES, function(inst)
                if inst.sg.statemem.ispocketwatch then
                    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pst_shadow" or "wanda2/characters/wanda/watch/weapon/pst")
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
        name = "wolfgang_attack",
        tags = { "attack", "doing", "busy", "canrotate" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()

            if inst.wolfstate == "wimpy" then
                inst.sg:GoToState("wolfgang_lift_pre")
            else
                local target = inst.components.combat.target

                if target ~= nil then
                    inst:ForceFacePoint(target.Transform:GetWorldPosition())
                end

                inst.AnimState:PlayAnimation("throw_pre")
                inst.AnimState:PushAnimation("throw", false)
            end
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.AnimState:Hide("ARM_carry")
                inst.AnimState:Show("ARM_normal")

                inst.Toss_Dumbell(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.wolflift = inst.wolflift - 1
                    if inst.wolflift <= 0 then
                        inst.sg:GoToState("wolfgang_powerdown")
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },

        onexit = function(inst)
            inst.AnimState:OverrideSymbol("swap_object", "swap_dumbbell", "swap_dumbbell")
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        end,
    },

    State {
        name = "wolfgang_lift_pre",
        tags = { "doing", "busy" },

        onenter = function(inst)
            --inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()

            local pre_anim = "dumbbell_skinny_pre"

            if inst.wolfstate == "normal" then
                pre_anim = "dumbbell_normal_pre"
            elseif inst.wolfstate == "mighty" then
                pre_anim = "dumbbell_mighty_pre"
            end

            inst.AnimState:PlayAnimation(pre_anim, false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                --if inst.AnimState:AnimDone() then
                inst.sg:GoToState("wolfgang_lift_loop")
                --end
            end),
        },
    },

    State {
        name = "wolfgang_lift_loop",
        tags = { "busy", "doing", "lifting_dumbbell" },

        onenter = function(inst)
            local loop_anim = "dumbbell_skinny_loop"

            if inst.wolfstate == "normal" then
                loop_anim = "dumbbell_normal_loop"
            elseif inst.wolfstate == "mighty" then
                loop_anim = "dumbbell_mighty_loop"
            end

            inst.AnimState:PlayAnimation(loop_anim, false)
        end,

        timeline = {
            TimeEvent(FRAMES * 7, function(inst)
                if inst.wolfstate == "mighty" then
                    inst.SoundEmitter:PlaySound("wolfgang1/dumbbell/twirl")
                end
            end),
            TimeEvent(FRAMES * 3, function(inst)
                if inst.wolfstate == "mighty" then
                    inst.SoundEmitter:PlaySound("wolfgang2/characters/wolfgang/grunt")
                end
            end),
            TimeEvent(FRAMES * 12, function(inst)
                if inst.wolfstate == "wimpy" or inst.wolfstate == "normal" then
                    inst.SoundEmitter:PlaySound("wolfgang2/characters/wolfgang/grunt")
                end
            end),
        },

        events =
        {

            EventHandler("animover", function(inst)
                inst.wolflift = inst.wolflift + 1

                if inst.wolflift >= 8 and inst.wolfstate == "normal" then
                    inst.wolfstate = "mighty"
                    inst.sg:GoToState("wolfgang_powerup")
                elseif inst.wolflift >= 4 and inst.wolfstate == "wimpy" then
                    inst.wolfstate = "normal"
                    inst.sg:GoToState("wolfgang_powerup")
                else
                    inst.sg:GoToState("wolfgang_lift_loop")
                end
            end),
        },
    },

    State {
        name = "wolfgang_powerup",
        tags = { "busy", "pausepredict", "nomorph", "powerup" },

        onenter = function(inst)
            local build = "wolfgang_skinny"

            if inst.wolfstate == "normal" then
                inst.components.combat:SetRange(8)
                build = "wolfgang"
            elseif inst.wolfstate == "mighty" then
                inst.components.combat:SetRange(10)
                build = "wolfgang_mighty"
            end

            inst.AnimState:SetBuild(build)

            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("wolfgang_mighty_fx").Transform:SetPosition(x, y, z)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("powerup")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.wolflift < 8 then
                        inst.sg:GoToState("wolfgang_lift_pre")
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    },

    State {
        name = "wolfgang_powerdown",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst)
            inst.components.combat:SetRange(12)
            inst.Physics:Stop()
            inst.wolfstate = "wimpy"
            inst.AnimState:SetBuild("wolfgang_skinny")
            inst.AnimState:PlayAnimation("powerdown")
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
        name = "taunt",
        tags = { --[["busy"]] },

        onenter = function(inst)
            inst.Physics:Stop()
            if inst:HasTag("um_shadow_wes") then
                DoMimeAnimations(inst)
            else
                inst.AnimState:PlayAnimation("idle_" .. inst.charactertype)
            end
            inst.SoundEmitter:PlaySound("UCSounds/shadow_wixie/taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State {
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:Hide("swap_arm_carry")
            inst.AnimState:PlayAnimation("death")

            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst:DoTaskInTime(1, function()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    SpawnPrefab("statue_transition").Transform:SetPosition(x, y, z)
                    SpawnPrefab("statue_transition_2").Transform:SetPosition(x, y, z)
                    inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_despawn")
                    inst:Remove()
                end)
            end),
        },
    },

    State {
        name = "disappear",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("wortox_portal_jumpin")

            SpawnPrefab("cavehole_flick_warn").Transform:SetPosition(inst.Transform:GetWorldPosition())

            inst.SoundEmitter:PlaySound("UCSounds/shadow_wixie/appear")
            inst.Physics:Stop()
            inst:AddTag("NOCLICK")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local max_tries = 4
                for k = 1, max_tries do
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local offset = 12
                    x = x + math.random(2 * offset) - offset
                    z = z + math.random(2 * offset) - offset
                    if TheWorld.Map:IsPassableAtPoint(x, y, z) then
                        inst.Physics:Teleport(x, y, z)
                        break
                    end
                end

                inst.sg:GoToState("appear")
            end),
        },
    },

    State {
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            SpawnPrefab("cavehole_flick").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.AnimState:PlayAnimation("jumpout")
            inst.SoundEmitter:PlaySound("UCSounds/shadow_wixie/appear")
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst) inst.Physics:SetMotorVelOverride(4, 0, 0) end),
            TimeEvent(20 * FRAMES,
                function(inst)
                    inst.Physics:ClearMotorVelOverride()
                    inst.components.locomotor:Stop()
                end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },

    State {
        name = "warly_throw",
        tags = { "attack", "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("throw_pre")
            inst.AnimState:PushAnimation("throw", false)

            local buffaction = inst:GetBufferedAction()
            local actiontarget = buffaction ~= nil and buffaction.target or nil
            if actiontarget ~= nil then
                actiontarget:Remove()
            end

            local target = TheSim:FindFirstEntityWithTag("um_shadow_warly_crockpot")
            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
            end
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.Toss_Food(inst)
            end),

            TimeEvent(14 * FRAMES, function(inst)
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
    },

    State {
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}
CommonStates.AddWalkStates(states)

return StateGraph("um_shadow_characters", states, events, "appear", actionhandlers)

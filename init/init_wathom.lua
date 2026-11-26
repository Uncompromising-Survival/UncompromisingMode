AddMinimapAtlas("images/map_icons/wathom.xml")

require "class"
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local FRAMES = GLOBAL.FRAMES
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local SpawnPrefab = GLOBAL.SpawnPrefab
local ActionHandler = GLOBAL.ActionHandler

-- It's 1 AM and I don't want to pick apart which local is needed so I'll just grab all of it.

--------------------------------------------------------------------------
-- 90% of code here is taken from Warfarin, made by the wonderful Tiddler..
-- AXE Not so much anymore.... There's a lot of skilltree stuff in this file now. The original one (leap attack yada yada yada) came from warfarin though.

-- Setting up new actions
local function HasSkill(inst,name)
    return inst and inst:IsValid() and inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated(name)
end

local function ShouldLeap(inst)
    return HasSkill(inst,"hyper_3") and inst.FindSpeed(inst)
end

local function FindAndTryUpgradeWathomHeaHun(inst) --HeaHun refers to health/hunger
    local x,y,z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x,y,z,64)
    for i,player in ipairs(players) do
        if player.prefab == "wathom" and not table.contains(player.um_bosses_killed,inst.prefab) then
            player.components.health.maxhealth = player.components.health.maxhealth + 3
            player.components.hunger.max = player.components.hunger.max + 3
            table.insert(player.um_bosses_killed,inst.prefab)
        end
    end
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    if inst:HasTag("epic") then
        inst:ListenForEvent("death",FindAndTryUpgradeWathomHeaHun)
    end
end)


-- Hollow Mind
env.AddComponentPostInit("locomotor", function(self)
    if self.ismastersim then
        local _GetSpeedMultiplier = self.GetSpeedMultiplier
        function self:GetSpeedMultiplier(...)
            local mult = _GetSpeedMultiplier(self, ...)
            if HasSkill(self.inst,"artificer_4") and self.inst:HasTag("amped") and mult < 1.2 then
                mult = 1.2
            end
            return mult
        end
    end
end)

env.AddComponentPostInit("sanity", function(self)
    local _DoDelta = self.DoDelta

    local function DoDelta(self,delta,overtime,...)
        if HasSkill(self.inst,"artificer_4") and self.inst:HasTag("amped") and delta ~= 0 then
            delta = 0

            -- This is only to make the arrow stop on the icon
            self.rate = 0
            self.ratescale = RATE_SCALE.NEUTRAL 
        end    
        return _DoDelta(self, delta, overtime, ...)
    end
    self.DoDelta = DoDelta
end)

env.AddComponentPostInit("temperature", function(self)
    local _SetTemperature = self.SetTemperature
    local function SetTemperature(self,value)
        if HasSkill(self.inst,"artificer_4") and self.inst:HasTag("amped") then
            if self.current < 5 then
                value = 5
            elseif self.current > 65 then
                value = 65
            else
                value = self.current
            end
        end  
        return _SetTemperature(self,value)
    end

    self.SetTemperature = SetTemperature
end)

env.AddComponentPostInit("moisture", function(self)
    local _DoDelta = self.DoDelta

    local function DoDelta(self,delta,overtime,...)
        if HasSkill(self.inst,"artificer_4") and self.inst:HasTag("amped") and delta ~= 0 then
            delta = 0
        end    
        return _DoDelta(self, delta, ...)
    end

    self.DoDelta = DoDelta
end)



local function Vomit(inst,targetpos)
    local x,y,z = inst.Transform:GetWorldPosition()
    local projectile = SpawnPrefab("um_wathom_goo")
    projectile.Transform:SetPosition(x, y+1, z)
    projectile.components.complexprojectile:SetHorizontalSpeed(20)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)


    projectile.damage = 20
    projectile.owner = inst

    if inst.chargecounter > 15 then
        projectile.tier = 3
        inst.components.hunger:DoDelta(-25)
    elseif inst.chargecounter > 10 then
        projectile.tier = 2
        inst.components.hunger:DoDelta(-12.5)
    else
        inst.components.hunger:DoDelta(-6.25)
    end
end



local function Effect(inst) -- I dumbed the shit out of this.
    if GLOBAL.TheWorld.state.wetness > 25 then
        local puff = SpawnPrefab("weregoose_splash_med2")
        puff.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local SGWilson = require "stategraphs/SGwilson"
local SGWilsonClient = require "stategraphs/SGwilson_client"
local Attack_Old
local ClientAttack_Old

for k1, v1 in pairs(SGWilson.actionhandlers) do
    if SGWilson.actionhandlers[k1]["action"]["id"] == "ATTACK" then
        Attack_Old = SGWilson.actionhandlers[k1]["deststate"]
    end
end

local special_staff = {
    "staff_lunarplant",
    "icestaff",
    "firestaff"
}

local function Attack_New(inst, action, ...)
    local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if weapon and not ((weapon:HasTag("blowdart") or weapon:HasTag("thrown") or (weapon:HasTag("rangedweapon") and not table.contains(special_staff, weapon.prefab)))) and inst:HasTag("wathom") and
        not inst.sg:HasStateTag("attack") and not (inst.components.rider and inst.components.rider:IsRiding()) then
        return ("wathomleap")
    elseif not weapon and HasSkill(inst,"devour_2") then
        return ("wathombite")
    else
        return Attack_Old(inst, action, ...)
    end
end

--Client

for k1, v1 in pairs(SGWilsonClient.actionhandlers) do
    if SGWilsonClient.actionhandlers[k1]["action"]["id"] == "ATTACK" then
        ClientAttack_Old = SGWilsonClient.actionhandlers[k1]["deststate"]
    end
end

local function AttackClient_New(inst, action, ...)
    local weapon = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if weapon and not ((weapon:HasTag("blowdart") or weapon:HasTag("thrown"))) and inst:HasTag("wathom") and
        not inst.sg:HasStateTag("attack") and (inst.components.rider ~= nil and not inst.components.rider:IsRiding() or inst.replica.rider ~= nil and not inst.replica.rider:IsRiding()) then
        return ("wathomleap_pre")
    elseif not weapon and HasSkill(inst,"devour_2") then
        return ("wathombite")
    else    
        return ClientAttack_Old(inst, action, ...)
    end
end

--Pack it up

AddStategraphActionHandler("wilson", ActionHandler(GLOBAL.ACTIONS.ATTACK, Attack_New))
GLOBAL.package.loaded["stategraphs/SGwilson"] = nil

AddStategraphActionHandler("wilson_client", ActionHandler(GLOBAL.ACTIONS.ATTACK, AttackClient_New))
GLOBAL.package.loaded["stategraphs/SGwilson_client"] = nil

AddStategraphActionHandler("wilson", ActionHandler(GLOBAL.ACTIONS.ATTACK, Attack_New))
------------------------
-- the MEAT


-- This could be refined, it's only called by SGs that Wathom uses.
local function ConfigureRunState(inst)
    if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
        inst.sg.statemem.riding = true
        inst.sg.statemem.groggy = inst:HasTag("groggy")
        inst.sg:AddStateTag("nodangle")

        local mount = inst.components.rider:GetMount()
        inst.sg.statemem.ridingwoby = mount and mount:HasTag("woby")
    elseif inst.components.inventory ~= nil and inst.components.inventory:IsHeavyLifting() then
        inst.sg.statemem.heavy = true
        inst.sg.statemem.heavy_fast = inst.components.mightiness ~= nil and inst.components.mightiness:IsMighty()
    elseif inst:HasTag("wereplayer") then
        inst.sg.statemem.iswere = true
        if inst:HasTag("weremoose") then
            if inst:HasTag("groggy") then
                inst.sg.statemem.moosegroggy = true
            else
                inst.sg.statemem.moose = true
            end
        elseif inst:HasTag("weregoose") then
            if inst:HasTag("groggy") then
                inst.sg.statemem.goosegroggy = true
            else
                inst.sg.statemem.goose = true
            end
        elseif inst:HasTag("groggy") then
            inst.sg.statemem.groggy = true
        else
            inst.sg.statemem.normal = true
        end
    elseif inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
        inst.sg.statemem.sandstorm = true
    elseif inst:HasTag("groggy") then
        inst.sg.statemem.groggy = true
    elseif inst:IsCarefulWalking() then
        inst.sg.statemem.careful = true
    else
        inst.sg.statemem.normal = true
        inst.sg.statemem.normalwonkey = inst:HasTag("wonkey") or nil
    end
end

local skilltree_defs = require("prefabs/skilltree_defs")
local BuildSkillsData = require("prefabs/skilltree_wathom")
if BuildSkillsData then
    local data = BuildSkillsData(skilltree_defs.FN)

    skilltree_defs.CreateSkillTreeFor("wathom", data.SKILLS)
    skilltree_defs.SKILLTREE_ORDERS["wathom"] = data.ORDERS

    --RegisterSkilltreeBGForCharacter(GLOBAL.resolvefilepath("images/wathom_skilltree.xml"), "wathom")
    
    for k, v in pairs(data.SKILLS) do
        if v.icon then
            RegisterSkilltreeIconsAtlas("images/wathom_skilltree.xml", v.icon .. ".tex")
        end
    end
end

    
local function GetAdrenalShove(inst)
    if inst.components.adrenaline then
        return inst:HasTag("amped") and 1 or .5 + inst.components.adrenaline:GetPercent() * .5
    else
        return .5
    end
end
    
-- This is Scrimble's Shove Code, it's used for both Charles T. Horse and Wixie, be appreciative, swine.
local NO_SHOVE_TAGS = {"stageusher", "toadstool"}
local function Check_Bowling(inst, target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, MUST_TAGS, CANT_TAGS)
    for i, v in ipairs(ents) do
        if inst.components.combat:CanTarget(v) and not inst.components.combat:IsAlly(v) then --(not target) or (target and v ~= target)
            v:AddTag("wixieshoved")
            SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(v.Transform:GetWorldPosition())

            if not (v.components.health and v.components.health:IsDead()) then        
                local damage = HasSkill(inst, "rampage_3") and inst.components.adrenaline and (inst:HasTag("amped") and 68 or 50 * inst.components.adrenaline:GetPercent()) or 0  
                v.components.combat:GetAttacked(inst, damage,nil,"wathom_aoe")
            end

            if v.components.locomotor ~= nil and not v:HasAnyTag(NO_SHOVE_TAGS) then
                for i = 1, 50 do
                    v:DoTaskInTime((i - 1) / 50, function(v)
                        if v ~= nil and inst ~= nil then
                            local x, y, z = inst.Transform:GetWorldPosition()
                            local tx, ty, tz = v.Transform:GetWorldPosition()

                            local rad = math.rad(inst:GetAngleToPoint(tx, ty, tz))
                            local velx = math.cos(rad)  --* 4.5
                            local velz = -math.sin(rad) --* 4.5

                            local giantreduction = v:HasTag("epic") and 1.5 or v:HasTag("smallcreature") and .8 or 1
                            local cursemultiplier = v:HasDebuff("wixiecurse_debuff") and 1.75 or 1.25
                            local shovevalue = GetAdrenalShove(inst)

                            local dx, dy, dz =
                                tx + (((shovevalue / (i + 3)) * velx) / giantreduction) * cursemultiplier, ty,
                                tz + (((shovevalue / (i + 3)) * velz) / giantreduction) * cursemultiplier
                            local ground = GLOBAL.TheWorld.Map:IsPassableAtPoint(dx, dy, dz)
                            local boat = GLOBAL.TheWorld.Map:GetPlatformAtPoint(dx, dz)
                            local ocean_collision = GLOBAL.TheWorld.Map:IsOceanAtPoint(dx, dy, dz)

                            if not (v.sg and v.sg:HasAnyStateTag("swimming", "invisible")) then
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

local function AddEnemyDebuffFx(fx, target)
    target:DoTaskInTime(math.random() * .25, function()
        local x, y, z = target.Transform:GetWorldPosition()
        local fx = SpawnPrefab(fx)
        if fx then
            fx.Transform:SetPosition(x, y, z)
        end
        return fx
    end)
end

-- AXE Wathom bite effect proc
local function CheckIfDead(inst, target)
    if target and HasSkill(inst,"devour_3") and 
        not (target and target.components.health and target.components.health:IsDead() and target:IsValid()) and
            target.components.health.currenthealth < target.components.health.maxhealth * 0.1 then
        target.components.health:Kill()
    end

    if (target and target.components.health and target.components.health:IsDead() and target:IsValid()) and not (target:HasAnyTag("soulless", "wall")) then
        local bite_heal_mod = target.components.health.maxhealth
        if not inst.devour_fx then
            inst.devour_fx = SpawnPrefab("deer_ice_flakes")
            inst.devour_fx.AnimState:SetMultColour(0,0,0,0.3)
            inst.devour_fx.Transform:SetScale(0.6,0.6,0.6)
            inst.devour_fx.entity:AddFollower():FollowSymbol(inst.GUID, inst.components.combat.hiteffectsymbol, 0, -50, 0)
            inst.components.hunger.burnratemodifiers:SetModifier(inst.devour_fx, 0.5)
        end
        if inst.devour_fx_timer then
            inst.devour_fx_timer:Cancel()
            inst.devour_fx_timer = nil
        end
        inst.devour_fx_timer = inst:DoTaskInTime(10,function(inst)
            if inst.components.hunger and inst.devour_fx then
                inst.components.hunger.burnratemodifiers:RemoveModifier(inst.devour_fx)
                inst.devour_fx:Remove()
                inst.devour_fx = nil
            end
            inst.devour_fx_timer = nil
        end)
        inst.components.health:DoDelta(0.05 * bite_heal_mod)
    end
end

AddStategraphPostInit("wilson", function(inst)
    local _RunOnEnter = inst.states["run_start"].onenter
    local function NewOnEnter(inst, ...)
        if (inst:HasTag("wathom") and inst:HasTag("wathomrun") and inst.components.rider ~= nil and not inst.components.rider:IsRiding()) or (inst:HasTag("wathom") and inst:HasTag("wathomrun") and inst.components.rider == nil) then
            inst.sg.mem.footsteps = 0
            inst.sg:GoToState("run_wathom")
            return
        else
            _RunOnEnter(inst, ...)
        end
    end

    inst.states["run_start"].onenter = NewOnEnter

    local actionhandlers =
    {
        ActionHandler(GLOBAL.ACTIONS.WATHOMBARK,
            function(inst, action)
                if not inst.bark_cd then
                    if ShouldLeap(inst) and ((inst.components.adrenaline and inst.components.adrenaline:GetPercent() > 0.05) or inst:HasTag("amped")) then -- I have a leap
                        return "wathom_hunterleap"
                    elseif HasSkill(inst,"glutton_3") and inst.chargecounter and inst.chargecounter > 5 and inst.sg.currentstate.name == "wathombark_charge" then
                        return "wathombark_charge_release"
                    elseif HasSkill(inst,"glutton_3") and inst.sg.currentstate.name ~= "wathombark_charge" and (inst.components.adrenaline and inst.components.adrenaline:GetPercent() >= 0.5) then
                        return "wathombark_charge"
                    elseif (inst.components.adrenaline and inst.components.adrenaline:GetPercent() >= 0.5) or inst:HasTag("amped") then
                        return "wathombark"
                    else
                        return "cantbark"
                    end
                else
                    return "cantbark"
                end
            end),
    }



    local states = {
        GLOBAL.State {
            name = "wathom_hunterleap",
            tags = {"busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt","notraptrigger" },

            onenter = function(inst, data)
                Effect(inst)
                --            inst.components.health:SetInvincible(true) -- I wonder why Tiddler did this?
                --inst.AnimState:PlayAnimation("atk_leap_pre", false)
                inst.AnimState:PlayAnimation("umrun", true)
                
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
                SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    if buffaction.pos ~= nil then
                        inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                    end
                end

                -- 1 Second bark delay
                inst.bark_cd = inst:DoTaskInTime(1,function(inst)
                    inst.bark_cd:Cancel()
                    inst.bark_cd = nil
                end)
                
                inst.sg:SetTimeout(14 * FRAMES)
            end,

            onexit = function(inst)
                inst.components.locomotor:Stop()
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.leapvelocity = 0
                inst.Physics:SetCollisionMask(COLLISION.WORLD, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS)
                inst:DoTaskInTime(0, function()
                    if inst.components.drownable and inst.components.drownable:ShouldDrown() then
                        inst.sg:GoToState("sink_fast")
                        inst.AnimState:SetFrame(70)
                        SpawnPrefab("um_ocean_splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                end)
            end,

            timeline =
            {
                TimeEvent(0 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/bark")
                    inst.Physics:ClearCollisionMask() 
                    local x,y,z = inst.Transform:GetWorldPosition()
                    inst.Physics:SetCollisionMask(COLLISION.GROUND, COLLISION.OBSTACLES, COLLISION.SMALLOBSTACLES, COLLISION.CHARACTERS, COLLISION.GIANTS) -- Can launch yourself over gaps.
                    inst.Physics:Teleport(x, y, z)
                    inst.leapvelocity = 30
                    inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
                    inst:PerformBufferedAction()
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end   
                end),
                TimeEvent(4 * FRAMES,function(inst)
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end   
                end),
                TimeEvent(8 * FRAMES,function(inst)
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end   
                end),
                TimeEvent(12 * FRAMES,function(inst)
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end   
                end),
                TimeEvent(16 * FRAMES,function(inst)
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end   
                end),
            },
            onupdate = function(inst)
                if inst.leapvelocity then
                    inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
                end
            end,
            ontimeout = function(inst)
                inst.sg:GoToState("idle")
            end,
        },
        GLOBAL.State {
            name = "run_wathom",
            tags = { "moving", "running", "canrotate", "autopredict" },

            onenter = function(inst)
                ConfigureRunState(inst)
                if ((inst.components.adrenaline and inst.components.adrenaline:GetPercent() > .75) or (HasSkill(inst,"hyper_1") and inst.components.adrenaline and inst.components.adrenaline:GetPercent() > .48)) or inst:HasTag("amped") then
                    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED + TUNING.WONKEY_SPEED_BONUS
                end

                --inst.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE * TUNING.WONKEY_RUN_HUNGER_RATE_MULT)
                inst.components.locomotor:RunForward()
                
                if not inst.AnimState:IsCurrentAnimation("umrun") then
                    inst.AnimState:PlayAnimation("umrun", true)
                end

                --V2C: adding half a frame time so it rounds up
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
            end,

            timeline =
            {
                TimeEvent(6 * FRAMES, function(inst) GLOBAL.PlayFootstep(inst, .5) end),
                TimeEvent(7 * FRAMES, function(inst) GLOBAL.PlayFootstep(inst, .5) end),
            },

            onupdate = function(inst)
                if inst.components.rider ~= nil and inst.components.rider:IsRiding() and not inst:HasTag("wathomrun") or not inst:HasTag("wathomrun") then
                    inst.sg:GoToState("run")
                    return
                end
                inst.components.locomotor:RunForward()    
            end,

            ontimeout = function(inst)
                inst.sg.statemem.funkyrunning = true
                inst.sg:GoToState("run_wathom")
            end,

            onexit = function(inst)
                if not inst.sg.statemem.funkyrunning then
                    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
                    inst.Transform:ClearPredictedFacingModel()
                end
            end,
        },

        GLOBAL.State {
            name = "wathombark",
            tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                inst.AnimState:PlayAnimation("emote_angry", false)
                inst.components.locomotor:Stop()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
                -- 5 Second bark delay
                inst.bark_cd = inst:DoTaskInTime(5,function(inst)
                    inst.bark_cd:Cancel()
                    inst.bark_cd = nil
                end)
            end,

            onexit = function(inst)
                if not inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
            end,

            timeline =
            {
                TimeEvent(10 * FRAMES, function(inst)
                    inst.components.locomotor:Stop()
                    inst:PerformBufferedAction() --Dis is the important part, canis -Axe
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("nointerrupt")
                end),
            },

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },
        GLOBAL.State {
            name = "wathombark_charge",
            tags = { "attack", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("emote_angry", false)
                inst.components.locomotor:Stop()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
                inst.chargecounter = 0


                inst.charge_fx = SpawnPrefab("deer_fire_charge")
                local x,y,z = inst.Transform:GetWorldPosition()
                inst.charge_fx.Transform:SetPosition(x,y+1,z)
                inst.charge_fx.AnimState:SetMultColour(0,0,0,0.6)
                inst.charge_fx.Transform:SetScale(0.6,0.6,0.6)
                inst.charge_fx.killed = true
                inst.charge_fx.Light:Enable(false) -- Remove the light from the old FX

                -- Count up the charges in stages, when a stage is reached, change the FX to be bigger.
                inst.chargecounter_task = inst:DoPeriodicTask(0.2,function(inst)
                    inst.charge_fx.Light:Enable(false) -- need to periodically tell it to turn it off.... the normal code turns it on again.
                    inst.chargecounter = inst.chargecounter + 1
                    if inst.charge_fx then
                        if inst.chargecounter == 5 then
                            inst.charge_fx.Transform:SetScale(1,1,1)
                        elseif inst.chargecounter == 10 then
                            inst.charge_fx.Transform:SetScale(1.2,1.2,1.2)
                        elseif inst.chargecounter == 15 then
                            inst.charge_fx.Transform:SetScale(1.8,1.8,1.8)
                        end
                    end
                end)
                if inst:HasTag("amped") then
                    inst.components.hunger.burnratemodifiers:SetModifier(inst.charge_fx, 10) -- Need to tie it to something that's not wathom - he's the source of the Amp burn rate mod
                else
                    inst.components.hunger.burnratemodifiers:SetModifier(inst.charge_fx, 50) -- Need to tie it to something that's not wathom - he's the source of the Amp burn rate mod 
                end
            
            end,

            timeline =
            {
                TimeEvent(2 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("nointerrupt")
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("pausepredict")
                    if not inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                    inst:ClearBufferedAction()
                    inst.AnimState:SetDeltaTimeMultiplier(0)
                end),
            },
            onexit = function(inst)
                inst.components.hunger.burnratemodifiers:RemoveModifier(inst.charge_fx) -- Need to tie it to something that's not wathom - he's the source of the Amp burn rate mod
                if inst.charge_fx then
                    inst.charge_fx:Remove()
                    inst.charge_fx = nil
                end
                inst.chargecounter_task:Cancel()
                inst.chargecounter_task = nil
                inst.AnimState:SetDeltaTimeMultiplier(1)
            end,
        },
        GLOBAL.State {
            name = "wathombark_charge_release",
            tags = { "attack", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                inst.AnimState:PlayAnimation("sing_fail", false)
                inst.AnimState:SetFrame(math.floor(inst.AnimState:GetCurrentAnimationNumFrames()/2))
                inst.components.locomotor:Stop()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
                inst.chargedbark = true


                -- 5 Second bark delay
                inst.bark_cd = inst:DoTaskInTime(5,function(inst)
                    inst.bark_cd:Cancel()
                    inst.bark_cd = nil
                end)
            end,

            timeline =
            {
                TimeEvent(5 * FRAMES, function(inst)
                    inst.components.locomotor:Stop()
                    inst:PerformBufferedAction() --Dis is the important part, canis -Axe
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("nointerrupt")
                    if not inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                end),
            },
            onexit = function(inst)
                inst.chargedbark = nil
                inst.chargecounter = 0
            end,

            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },

        GLOBAL.State {
            name = "cantbark",
            tags = { "busy" },

            onenter = function(inst)
                inst.AnimState:PlayAnimation("sing_fail", false)

                inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") -- maybe make something new later?
            end,
            timeline =
            {
                TimeEvent(12 * FRAMES, function(inst)
                    inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap") --place your funky sounds here
                end),                                                       --bark twice.
            },
            events =
            {
                EventHandler("animover", function(inst)
                    if inst.AnimState:AnimDone() then
                        inst.sg:GoToState("idle")
                        inst.sg:RemoveStateTag("busy")
                        inst:ClearBufferedAction()
                    end
                end),
            }
        },

        GLOBAL.State {
            name = "wathomleap",
            tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                Effect(inst)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                
                if target ~= nil and (target:HasTag("bird_mutant") or not target:HasTag("bird")) then
                    inst.components.combat:SetTarget(target)
                else
                    inst.components.combat:SetTarget(nil)
                end
                
                inst.components.combat:StartAttack()


                inst.AnimState:PlayAnimation("atk_leap", false)
                inst.Transform:SetEightFaced()
                inst.AnimState:ClearOverrideBuild("player_lunge")
                inst.AnimState:ClearOverrideBuild("player_attack_leap")
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end


                local buffaction = inst:GetBufferedAction()
                local hyper_multiplier = 1.33
                if inst:HasTag("amped") and HasSkill(inst,"hyper_4") and not (buffaction and buffaction.mockattack) and not (inst.components.rider and inst.components.rider:IsRiding()) and hyper_multiplier then
                    inst.AnimState:SetDeltaTimeMultiplier(hyper_multiplier)
                    if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / hyper_multiplier) end
                    if not inst.sg.currentstate.preserved_timelinetime then
                        inst.sg.currentstate.preserved_timelinetime = {}
                    end
                    for i, v in ipairs(inst.sg.currentstate.timeline) do
                        local time = inst.sg.currentstate.timeline[i].time
                        if not inst.sg.currentstate.preserved_timelinetime[i] then
                            inst.sg.currentstate.preserved_timelinetime[i] = time
                        end
                        inst.sg.currentstate.timeline[i].time = time / hyper_multiplier
                    end
                elseif inst.sg.currentstate.preserved_timelinetime then
                    for i, v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
                        local time = inst.sg.currentstate.preserved_timelinetime[i]
                        inst.sg.currentstate.timeline[i].time = time
                    end
                    inst.sg.currentstate.preserved_timelinetime = nil
                end

                inst.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/leap")
                inst.Physics:ClearCollisionMask() -- all of this physics stuff will give the impression that Wathom is jumping over things. It also allows him to slide past targets instead of ending his leap in front.
                --                     inst.components.hunger:DoDelta(-1, 2)
                inst.Physics:CollidesWith(GLOBAL.COLLISION.WORLD)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction and buffaction.target or nil
                if target then
                    local pos = inst:GetPosition()
                    local targetpos = target:GetPosition()
                    if distsq(targetpos, pos) <= inst.components.combat:CalcAttackRangeSq(target) then
                        inst.sg.statemem.startingpos = pos
                        inst.sg.statemem.targetpos = targetpos
                        if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or
                            inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                            local mult = (inst:HasTag("amped") and HasSkill(inst,"hyper_4")) and 9 or 12
                            inst.leapvelocity = math.sqrt(GLOBAL.distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (mult * FRAMES)
                        end
                        inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
                        if HasSkill(inst,"rampage_2") then
                            target:AddTag("wixieshoved")
                            target:DoTaskInTime(1,function(target) target:RemoveTag("wixieshoved") end)
                        end
                    end
                end
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
            end,

            onexit = function(inst)
                --            inst.components.health:SetInvincible(false)
                inst.components.combat:SetTarget(nil)
                if inst.sg:HasStateTag("abouttoattack") then
                    inst.components.combat:CancelAttack()
                end
                inst.Transform:SetFourFaced()
                inst.components.locomotor:Stop()

                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)

                inst.AnimState:AddOverrideBuild("player_lunge")
                inst.AnimState:AddOverrideBuild("player_attack_leap")

                inst.AnimState:SetDeltaTimeMultiplier(1)
                if inst.sg.currentstate.preserved_timelinetime then
                    for i, v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
                        local time = inst.sg.currentstate.preserved_timelinetime[i]
                        inst.sg.currentstate.timeline[i].time = time
                    end
                    inst.sg.currentstate.preserved_timelinetime = nil
                end
                if not inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                if inst.components.drownable and inst.components.drownable:ShouldDrown() then
                    inst.sg:GoToState("sink_fast")
                    inst.AnimState:SetFrame(70)
                    SpawnPrefab("um_ocean_splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end,

            timeline =
            {
                TimeEvent(12 * FRAMES, function(inst)
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst.components.locomotor:Stop()
                    inst.Physics:ClearMotorVelOverride()
                    inst:PerformBufferedAction()
                    inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                    inst.Physics:CollidesWith(GLOBAL.COLLISION.OBSTACLES)
                    inst.Physics:CollidesWith(GLOBAL.COLLISION.SMALLOBSTACLES)
                end),

                TimeEvent(14 * FRAMES, function(inst) -- this is when the target gets hit
                    local hypermult = (inst:HasTag("amped") and HasSkill(inst,"hyper_4")) and 1.33 or 1
                    if inst:HasTag("wearingheavyarmor") then
                        inst.leapvelocity = 2 * hypermult
                    else
                        if inst:HasTag("amped") then
                            inst.leapvelocity = 15 * hypermult
                        else
                            local adrenaline_percent = inst.components.adrenaline:GetPercent()
                            
                            inst.leapvelocity = hypermult * (7.5 + (adrenaline_percent)*7.5)
                        end
                    end
                    SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end
                end),

                TimeEvent(19 * FRAMES, function(inst)
                    SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end
                end),

                TimeEvent(24 * FRAMES, function(inst)
                    SpawnPrefab("dirt_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
                    inst.sg:RemoveStateTag("busy")
                    inst.sg:RemoveStateTag("attack")
                    inst.sg:RemoveStateTag("nointerrupt")
                    inst.sg:RemoveStateTag("pausepredict")
                    inst.sg:RemoveStateTag("abouttoattack")
                    --inst.sg:AddStateTag("idle")
                    inst.leapvelocity = 0                   -- Stops Wathom's sliding.
                    inst.Physics:Stop()
                    inst.Physics:CollidesWith(GLOBAL.COLLISION.CHARACTERS) -- Re-enabling Wathom's normal collision.
                    if HasSkill(inst,"rampage_2") then
                        local buffaction = inst:GetBufferedAction()
                        local target = buffaction ~= nil and buffaction.target or nil
                        Check_Bowling(inst,target)
                    end
                    if not inst.components.playercontroller ~= nil then
                        inst.components.playercontroller:Enable(true)
                    end
                    inst:ClearBufferedAction()
                end),

            },
            onupdate = function(inst)
                if inst.leapvelocity then
                    inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
                end
            end,
            events =
            {
                EventHandler("animover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },

        GLOBAL.State {
            name = "wathombite",
            tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                SpawnPrefab("round_puff_fx_sm").Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- Buff FX

                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                inst.components.combat:StartAttack()
                --            inst.components.health:SetInvincible(true) -- I wonder why Tiddler did this?
                --inst.AnimState:PlayAnimation("atk_leap_pre", false)
                inst.AnimState:PlayAnimation("umrun")
                inst.components.locomotor:Stop()
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)

                inst.AnimState:SetDeltaTimeMultiplier(1.3)

                -- Borrowed from wathomleap
                local target = buffaction and buffaction.target or nil
                if target then
                    local pos = inst:GetPosition()
                    local targetpos = target:GetPosition()
                    if distsq(targetpos, pos) <= inst.components.combat:CalcAttackRangeSq(target) then
                        inst.sg.statemem.startingpos = pos
                        inst.sg.statemem.targetpos = targetpos
                        if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or
                            inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                            local mult = 8
                            inst.leapvelocity = math.sqrt(GLOBAL.distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (mult * FRAMES)
                        end
                        inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
                        if HasSkill(inst,"rampage_2") then
                            target:AddTag("wixieshoved")
                            target:DoTaskInTime(1,function(target) target:RemoveTag("wixieshoved") end)
                        end
                    end
                end
            end,
            onupdate = function(inst)
                if inst.leapvelocity then
                    inst.Physics:SetMotorVel(inst.leapvelocity, 0, 0)
                end
            end,
            onexit = function(inst)
                inst.AnimState:SetDeltaTimeMultiplier(1)
                inst.components.locomotor:Stop()

                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            end,    

            timeline =
            {
                TimeEvent(8 * FRAMES, function(inst)    
                    inst.AnimState:PlayAnimation("feast_eat_pre", false)
                    inst.sg:RemoveStateTag("abouttoattack")
                    inst.components.locomotor:Stop()
                    local buffaction = inst:GetBufferedAction()
                    local target = buffaction ~= nil and buffaction.target or nil
                    inst:PerformBufferedAction()
                    inst.AnimState:SetFrame(5)
                    inst.leapvelocity = 0
                    inst.Physics:ClearMotorVelOverride()
                    inst.components.locomotor:EnableGroundSpeedMultiplier(true)

                    if target then
                        inst:DoTaskInTime(.25,function(inst) CheckIfDead(inst,target) end)
                    end
                end),
                TimeEvent(16 * FRAMES, function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
            events = -- if somehow he gets stuck
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },
        },
    }

    for k, v in pairs(states) do
        GLOBAL.assert(v:is_a(GLOBAL.State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

    for k, v in pairs(actionhandlers) do
        GLOBAL.assert(v:is_a(GLOBAL.ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end
end)

--client. Uses a "pre" as this should only be used if there's lag.

AddStategraphPostInit("wilson_client", function(inst)
    local _RunOnEnter = inst.states["run_start"].onenter
    local function NewOnEnter(inst, ...)
        if (inst:HasTag("wathom") and inst:HasTag("wathomrun")) then
            inst.sg.mem.footsteps = 0
            inst.sg:GoToState("run_wathom")
            return
        else
            _RunOnEnter(inst, ...)
        end
    end

    inst.states["run_start"].onenter = NewOnEnter

    local actionhandlers =
    {
        ActionHandler(GLOBAL.ACTIONS.WATHOMBARK,
            function(inst, action)
                return "wathombark_pre"
            end),
    }
    local states = {

        GLOBAL.State {
            name = "run_wathom",
            tags = { "moving", "running", "canrotate" },

            onenter = function(inst)
                if not inst:HasTag("wathomrun") then -- Make a previously running wathom do a regular walk
                    inst.sg:GoToState("run")
                end
                ConfigureRunState(inst)
                if inst.components.adrenaline and inst.components.adrenaline:GetPercent() > (HasSkill(inst,"hyper_1") and 0.5 or .75 ) then
                    inst.components.locomotor.predictrunspeed = TUNING.WILSON_RUN_SPEED + TUNING.WONKEY_SPEED_BONUS
                end
                inst.components.locomotor:RunForward()
                if not inst.AnimState:IsCurrentAnimation("umrun") then
                    inst.AnimState:PlayAnimation("umrun", true)
                end
                --V2C: adding half a frame time so it rounds up
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + .5 * FRAMES)
            end,

            timeline =
            {
                --[[TimeEvent(4*FRAMES, function(inst) PlayFootstep(inst, .5) end),
            TimeEvent(5*FRAMES, function(inst) PlayFootstep(inst, .5) DoFoleySounds(inst) end),
            TimeEvent(10*FRAMES, function(inst) PlayFootstep(inst, .5) end),
            TimeEvent(11*FRAMES, function(inst) PlayFootstep(inst, .5) end),]]
            },

            onupdate = function(inst)
                if not inst:HasTag("wathomrun") then
                    inst.sg:GoToState("run")
                    return
                end
                inst.components.locomotor:RunForward()
            end,

            --[[events =
        {
            EventHandler("gogglevision", function(inst, data)
                if not data.enabled and inst:GetStormLevel() >= TUNING.SANDSTORM_FULL_LEVEL then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("sandstormlevel", function(inst, data)
                if data.level >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("carefulwalking", function(inst, data)
                if data.careful then
                    inst.sg:GoToState("run")
                end
            end),
        },]]

            ontimeout = function(inst)
                inst.sg.statemem.funkyrunning = true
                inst.sg:GoToState("run_wathom")
            end,

            onexit = function(inst)
                if not inst.sg.statemem.funkyrunning then
                    inst.components.locomotor.predictrunspeed = nil
                    inst.Transform:ClearPredictedFacingModel()
                end

            end,
        },

        
        GLOBAL.State {
            name = "wathomleap_pre",
            tags = { "busy" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                inst.AnimState:PlayAnimation("atk_leap_pre", false)
                inst.AnimState:PushAnimation("atk_leap_lag", false)

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    inst:PerformPreviewBufferedAction()

                    if buffaction.pos ~= nil then
                        inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                    end
                end

                inst.sg:SetTimeout(2)
            end,

            onupdate = function(inst)
                if inst:HasTag("busy") then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.AnimState:PlayAnimation("atk_leap_lag", false)
                    end
                elseif inst.bufferedaction == nil then
                    inst.sg:GoToState("idle")
                end
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
        },

        GLOBAL.State {
            name = "wathombite",
            tags = { "attack", "backstab", "busy", "notalking", "abouttoattack", "pausepredict", "nointerrupt" },

            onenter = function(inst, data)
                inst.components.locomotor:Stop()

                inst.AnimState:PlayAnimation("feast_eat_pre_pre", false)
                inst.AnimState:PushAnimation("feast_eat_pre", false)

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    inst:PerformPreviewBufferedAction()

                    if buffaction.pos ~= nil then
                        inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                    end
                end

                inst.sg:SetTimeout(2)
            end,

            --[[onexit = function(inst)
            
            end,]]

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
        },
        GLOBAL.State {
            name = "wathombark_pre",
            tags = { "busy" },

            onenter = function(inst)
                inst.components.locomotor:Stop()

                inst.AnimState:PlayAnimation("idle", false)

                local buffaction = inst:GetBufferedAction()
                if buffaction ~= nil then
                    inst:PerformPreviewBufferedAction()

                    if buffaction.pos ~= nil then
                        inst:ForceFacePoint(buffaction:GetActionPoint():Get())
                    end
                end

                inst.sg:SetTimeout(0)
                inst.AnimState:PushAnimation("idle", true)
            end,

            onupdate = function(inst)
                if inst:HasTag("busy") then
                    if inst.entity:FlattenMovementPrediction() then
                        inst.sg:GoToState("idle", "noanim")
                    end
                elseif inst.bufferedaction == nil then
                    inst.sg:GoToState("idle")
                end
            end,

            ontimeout = function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end,
        }
    }

    for k, v in pairs(states) do
        GLOBAL.assert(v:is_a(GLOBAL.State), "Non-state added in mod state table!")
        inst.states[v.name] = v
    end

    for k, v in pairs(actionhandlers) do
        GLOBAL.assert(v:is_a(GLOBAL.ActionHandler), "Non-action added in mod state table!")
        inst.actionhandlers[v.action] = v
    end
end)

-- The handling is mostly done in getattacked
local function AttachWathomBarkDebuff(inst)
    if inst.um_wathom_barkmod_debuff then
        inst.um_wathom_barkmod_debuff:Cancel()
        inst.um_wathom_barkmod_debuff = nil
    end
    inst.um_wathom_barkmod_debuff = inst:DoTaskInTime(10,function(inst)
        inst.um_wathom_barkmod_debuff:Cancel()
        inst.um_wathom_barkmod_debuff = nil  
    end)
end


-----------------------------------------------------------------------------------------------------
local function ShouldVomit(doer)
    return HasSkill(doer, "glutton_3") and doer.chargecounter > 5 and doer.chargedbark
end

local function DoRingFX(doer,scale)
    local x,y,z = doer.Transform:GetWorldPosition()
    local fx = SpawnPrefab("dreadeye_sanityburstring")
    fx.Transform:SetPosition(x, 0, z)
    fx:AddTag("ignore_transparency")
    fx.Transform:SetScale(scale, scale, scale)
end

local bark_must_tags = {"companion", "INLIMBO", "notarget", "noattack", "player", "playerghost", "wall", "abigail", "shadowminion", "shadow"}
local function CreateBark(inst,doer,act)

    local x,y,z = doer.Transform:GetWorldPosition()

    -- FX That appears near wathom
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(doer.Transform:GetWorldPosition())
        fx.Transform:SetScale(1.2, 1.2, 1.2)
    end
    local fx1 = SpawnPrefab("statue_transition")
    if fx1 ~= nil then
        fx1.Transform:SetPosition(doer.Transform:GetWorldPosition())
        fx1.Transform:SetScale(1.2, 1.2, 1.2)
    end

    
    local range = 12
    local scale = 2.5
    -- Cast the bark to another location
    if ShouldLeap(doer) and not ShouldVomit(doer) then
        local pos = act:GetActionPoint()
        x = pos.x
        z = pos.z
        scale = scale/3
        range = range/3
    end

    -- Indicator of where the bark is

    DoRingFX(doer,scale)
            
    if ShouldVomit(doer) then
        local targetpos = act:GetActionPoint()
        Vomit(doer, targetpos)
    end

    local ents = GLOBAL.TheSim:FindEntities(x,y,z, range, {"_combat"}) --added playertags because of the taunt.
    for i, v in ipairs(ents) do
        if v ~= doer and v:HasTag("player") and HasSkill(doer,"wathom_barkmod_effects") then
            doer.SurvivorBarkEffect(v)
        end
        if v ~= doer and v.entity:IsVisible()
            and not (v.components.health and v.components.health:IsDead())
            and not (doer.components.combat and doer.components.combat:IsAlly(v)) then
            if v.components.hauntable and v.components.hauntable.panicable then
                if not ShouldLeap(doer) then
                    v.components.hauntable:Panic(10) -- Fallback to TUNING.BATTLESONG_PANIC_TIME (6 seconds) if needed
                end
                AddEnemyDebuffFx("battlesong_instant_panic_fx", v)
            end
            if not v:HasTag("bird") and v.components.combat and (not v.components.hauntable or v.components.hauntable and not v.components.hauntable.panicable) then
                v.components.combat:SetTarget(doer)
                AddEnemyDebuffFx("battlesong_instant_taunt_fx", v)
            end
            if HasSkill(doer,"wathom_barkmod_attacks") then
                AttachWathomBarkDebuff(v)
            end


            -- May attack foes via glutton 2
            if doer.num_planar_hits > 0 or doer.num_nightmare_hits > 0 and not (ShouldLeap(doer) and not ShouldVomit(doer)) then
                
                doer:DoTaskInTime(0.2,DoRingFX,scale)
                doer:DoTaskInTime(0.4,DoRingFX,scale)
                doer.EmpoweredDamage(doer,v)
                doer:DoTaskInTime(0.5,function(inst)
                    doer.num_planar_hits = 0
                    doer.num_nightmare_hits = 0
                    doer:SetEmpoweredFx(doer)
                end)
            end
        end
    end
end

STRINGS.ACTIONS.WATHOMBARK = "Bark"

local wathombark = AddAction(
    "WATHOMBARK",
    STRINGS.ACTIONS.WATHOMBARK,
    function(act)
        local doer = act.doer



        if doer and doer.components.adrenaline then -- previously act.target
            doer.AnimState:AddOverrideBuild("emote_angry")
            local adrenaline_cost = ShouldLeap(doer) and -5 or -25
            doer.SoundEmitter:PlaySound("wathomcustomvoice/wathomvoiceevent/bark") --place your funky sounds here
            doer.components.adrenaline:DoDelta(adrenaline_cost, 2)

            CreateBark(inst,doer,act)
            return true
        else
            return false
        end
    end
)

wathombark.priority = HIGH_ACTION_PRIORITY
wathombark.rmb = true
wathombark.distance = 36
wathombark.mount_valid = false

STRINGS.ACTIONS.WATHOMBARK = "Bark"

-- STRINGS.ACTIONS.AMPUP = "Amp Up!"

---------------------------------------------

local KnownModIndex = GLOBAL.KnownModIndex
local Text = require "widgets/text"
local Image = require "widgets/image"
local NUMBERFONT = GLOBAL.NUMBERFONT

local function GetModName(modname) -- modinfo's modname and internal modname is different.
    for _, knownmodname in ipairs(KnownModIndex:GetModsToLoad()) do
        if KnownModIndex:GetModInfo(knownmodname).name == modname then
            return knownmodname
        end
    end
end

local function GetModOptionValue(knownmodname, known_option_name)
    local modinfo = KnownModIndex:GetModInfo(knownmodname)
    for _, option in pairs(modinfo.configuration_options) do
        if option.name == known_option_name then
            return option.saved
        end
    end
end

local DEERCLOPS_TIMERNAME = "deerclops_timetoattack"
local MOTHERGOOSE_TIMERNAME = "mothergoose_timetoattack"
local MOCKFLY_TIMERNAME = "mockfly_timetoattack"
local BEARGER_TIMERNAME = "bearger_timetospawn"

local function Say(inst,text)
    inst.components.talker:Say(text)
end

local function WathomWarnsEarly(inst, threattype, stage)
    if threattype == "megafauna" then
        if stage == 1 then
            Say(inst,"Distant Roar. Awoken, megafauna. Far away, still.")
        else
            Say(inst,"Distant Megafauna. Time for preparation.")
        end
    elseif threattype == "dogs" then
        if GLOBAL.TheWorld:HasTag("cave") then
            if stage == 1 then
                Say(inst,"Vocalizations, depth worms. Hunt began. Far away, still.")
            else
                Say(inst,"Worms. Our footsteps, felt. Soon, attack.")
            end
        else
            if stage == 1 then
                Say(inst,"Howling, distant dogs. Hunt began. Far away, still.")
            else
                Say(inst,"Dogs. Our footsteps, felt. Soon, attack.")
            end        
        end
    end
end

local function HoundTask(inst)
    local _worldsettingstimer = GLOBAL.TheWorld.components.worldsettingstimer
    if GLOBAL.TheWorld.components.hounded then
        local houndtime = GLOBAL.TheWorld.components.hounded:GetTimeToAttack() / 60
        if houndtime < 8.5 and houndtime > 7.5 then
            WathomWarnsEarly(inst, "dogs", 1)
        end
        if houndtime < 4.5 and houndtime > 3.5 then
            WathomWarnsEarly(inst, "dogs", 2)
        end
    end

    if _worldsettingstimer then
        if _worldsettingstimer:GetTimeLeft(DEERCLOPS_TIMERNAME) then
            local timeleft = _worldsettingstimer:GetTimeLeft(DEERCLOPS_TIMERNAME)
            if timeleft < 8.5 and timeleft > 7.5 then
                WathomWarnsEarly(inst,"megafauna",1)
            end
            if timeleft < 4.5 and timeleft > 3.5 then
                WathomWarnsEarly(inst,"megafauna",2)
            end
        end
        if _worldsettingstimer:GetTimeLeft(MOTHERGOOSE_TIMERNAME) then
            local timeleft = _worldsettingstimer:GetTimeLeft(MOTHERGOOSE_TIMERNAME)
            if timeleft > 8.5 and timeleft > 7.5 then
                WathomWarnsEarly(inst,"megafauna",1)
            end
            if timeleft < 4.5 and timeleft > 3.5 then
                WathomWarnsEarly(inst,"megafauna",2)
            end
        end
        if _worldsettingstimer:GetTimeLeft(MOCKFLY_TIMERNAME) then
            local timeleft = _worldsettingstimer:GetTimeLeft(MOCKFLY_TIMERNAME)
            if timeleft < 8.5 and timeleft > 7.5 then
                WathomWarnsEarly(inst,"megafauna",1)
            end
            if timeleft < 4.5 and timeleft > 3.5 then
                WathomWarnsEarly(inst,"megafauna",2)
            end
        end
        if _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME) then
            local timeleft = _worldsettingstimer:GetTimeLeft(BEARGER_TIMERNAME)
            if timeleft < 8.5 and timeleft > 7.5 then
                WathomWarnsEarly(inst,"megafauna",1)
            end
            if timeleft < 4.5 and timeleft > 3.5 then
                WathomWarnsEarly(inst,"megafauna",2)
            end
        end
    end
end

AddPlayerPostInit(function(inst)
    if inst:HasTag("wathom") then
        inst.counter_max = GLOBAL.net_shortint(inst.GUID, "counter_max", "counter_maxdirty")
        inst.counter_current = GLOBAL.net_shortint(inst.GUID, "counter_current", "counter_currentdirty")
    
        
        if _G.TheWorld.ismastersim then
            inst.HoundTask = HoundTask
            inst:AddComponent("adrenaline")    
        end
        --inst:ListenForEvent("onattackother", AttackOther)
    end
end)

local function AmpbadgeDisplays(self)
    if self.owner:HasTag("wathom") then
        local ampbadge = require "widgets/ampbadge"

        self.combinedmod = GetModName("Combined Status")

        self.adrenaline = self:AddChild(ampbadge(self.owner))

        if self.combinedmod ~= nil then
            self.brain:SetPosition(0, 35, 0)
            self.stomach:SetPosition(-62, 35, 0)
            self.heart:SetPosition(62, 35, 0)

            self.adrenaline:SetScale(.9, .9, .9)
            self.adrenaline:SetPosition(-62, -50, 0)
            self.adrenaline.combinedmod = true
            self.adrenaline.showmaxonnumbers = GetModOptionValue(self.combinedmod, "SHOWMAXONNUMBERS")

            self.adrenaline.bg = self.adrenaline:AddChild(Image("images/status_bgs.xml", "status_bgs.tex"))
            self.adrenaline.bg:SetScale(.4, .43, 0)
            self.adrenaline.bg:SetPosition(-.5, -40, 0)

            if self.boatmeter then
                self.boatmeter:SetPosition(-124, -52)
            end

            self.adrenaline.num:SetFont(NUMBERFONT)
            self.adrenaline.num:SetSize(28)
            self.adrenaline.num:SetPosition(3.5, -40.5, 0)
            self.adrenaline.num:SetScale(1, .78, 1)

            self.adrenaline.num:MoveToFront()
            self.adrenaline.num:Show()

            self.adrenaline.maxnum = self.adrenaline:AddChild(Text(NUMBERFONT, self.adrenaline.showmaxonnumbers and 25 or 33))
            self.adrenaline.maxnum:SetPosition(6, 0, 0)
            self.adrenaline.maxnum:MoveToFront()
            self.adrenaline.maxnum:Hide()
        else
            self.adrenaline:SetPosition(self.column3, -130, 0)
            self.moisturemeter:SetPosition(self.column1, -130, 0)
            --self.brain:SetPosition(40, -50, 0)
            --self.stomach:SetPosition(-40, 17, 0)
        end

        --self.inst:ListenForEvent("adrenalinedelta", function(inst, data) self.adrenaline:SetPercent(data.newpercent, self.owner.components.pestilencecounter:Max()) end, self.owner)

        local _SetGhostMode = self.SetGhostMode
        function self:SetGhostMode(ghostmode)
            if not self.isghostmode == not ghostmode then --force boolean
                return
            end

            _SetGhostMode(self, ghostmode)
            if ghostmode then
                self.adrenaline:Hide()
            else
                self.adrenaline:Show()
            end
        end
    end
end

AddClassPostConstruct("widgets/statusdisplays", AmpbadgeDisplays)

-- New code for Wathom's echolocation! Needs to be controls so it doesnt screw with player hud!
AddClassPostConstruct( "widgets/controls", function(self, inst)
    local ownr = self.owner
    if ownr == nil then return end

    if self.owner:HasTag("wathom") then
        local Wathom_Sonar = require "widgets/wathom_sonar"
        self.wathom_sonar = self:AddChild( Wathom_Sonar(self.owner) )
        self.wathom_sonar:MoveToBack()
    end
end)

GLOBAL.FOODTYPE.LICHEN = "LICHEN"
GLOBAL.FOODTYPE.UM_NIGHTMARES = "UM_NIGHTMARES"
table.insert(GLOBAL.FOODGROUP.OMNI.types,GLOBAL.FOODTYPE.LICHEN)
--table.insert(GLOBAL.FOODGROUP.OMNI.types,GLOBAL.FOODTYPE.UM_NIGHTMARES)

AddPrefabPostInit("cutlichen", function(inst)
    if not _G.TheWorld.ismastersim then return end

    inst:AddComponent("edible")
    inst.components.edible.secondaryfoodtype = GLOBAL.FOODTYPE.LICHEN
end)



-- Wathom may feast on fuel.
AddPrefabPostInit("nightmarefuel", function(inst)
    if not _G.TheWorld.ismastersim then return end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.UM_NIGHTMARES
    inst.components.edible.healthvalue = 8
    inst.components.edible.hungervalue = 18.8
    inst.components.edible.sanityvalue = -15
end)

AddPrefabPostInit("horrorfuel", function(inst)
    if not _G.TheWorld.ismastersim then return end

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.UM_NIGHTMARES
    inst.components.edible.healthvalue = 20
    inst.components.edible.hungervalue = 37.5
    inst.components.edible.sanityvalue = -33
end)






local UpvalueHacker = require("tools/upvaluehacker")
env.AddPrefabPostInit("world", function(inst) -- Supposedly, this is better since it's called once for each "world" prefab, which usually only spawns once per shard.
    if not _G.TheWorld.ismastersim then return end
    local _tryproc = UpvalueHacker.GetUpvalue(_G.Prefabs.ruinshat.fn, "tryproc")
    if _tryproc then
        local _ruinshat_proc = UpvalueHacker.GetUpvalue(_tryproc, "ruinshat_proc")
        local function tryproc(inst, owner, data, ...)
            if HasSkill(owner, "ancient_kinship_2") then
                if inst._task == nil and (data and not data.redirected) or not data and math.random() < .7 then
                    _ruinshat_proc(inst, owner)
                end
                return
            end
            return _tryproc(inst, owner, data, ...)
        end
        UpvalueHacker.SetUpvalue(_G.Prefabs.ruinshat.fn, tryproc, "tryproc")
    end
end)

AddPrefabPostInit("ruinshat", function(inst)
    if not _G.TheWorld.ismastersim then return end

    local _OnUnequip = inst.components.equippable.onunequipfn
    local _OnEquip = inst.components.equippable.onequipfn

    local function OnEquip(inst, owner, ...)
        if HasSkill(owner, "ancient_kinship_3") then
            inst:AddComponent("planardefense")
            inst.components.planardefense:SetBaseDefense(10)
        end
        return _OnEquip(inst, owner, ...)
    end

    local function OnUnequip(inst, owner, ...)
        if inst.components.planardefense then
            inst:RemoveComponent("planardefense")
        end
        return _OnUnequip(inst, owner, ...)
    end

    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end)

AddPrefabPostInit("armorruins", function(inst)
    if not _G.TheWorld.ismastersim then return end

    local _OnUnequip = inst.components.equippable.onunequipfn
    local _OnEquip = inst.components.equippable.onequipfn

    local function OnEquip(inst, owner, ...)
        if HasSkill(owner, "ancient_kinship_3") then
            inst:AddComponent("planardefense")
            inst.components.planardefense:SetBaseDefense(10)
        end
        return _OnEquip(inst, owner, ...)
    end

    local function OnUnequip(inst, owner, ...)
        if inst.components.planardefense then
            inst:RemoveComponent("planardefense")
        end
        return _OnUnequip(inst, owner, ...)
    end

    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
end)


local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end

local function NewOnAttackClub(inst, attacker, target) -- Reason for convolution, we need to edit the if statement determining if there will be a tentacle spawn, 
    -- this is normally impossible, we can instead wrap the OnAttack function call and use our version if Wathom can use our version
    -- or alternatively use the existing version in any other scenario. This is also why the damagetypebonus tidbit is here.
    -- Since directing to the Wathom if statement means that our other damagetypebonus code will no longer be in the wrap.
    -- They also don't have a "SpawnTentacle" function to grab, all of the actual spawning code is just nested inside the if statement, which is big sad.
    
    local ID = attacker.FindHoneID and attacker.FindHoneID(attacker,inst.prefab) -- Ask what it is incase someone changed it
    if ID and attacker.hone_amounts[ID] >= attacker.hone_tiers[1] then
        -- Bolster the chance to hit by adrenaline, up to 100% at 100 adrenaline
        if TryLuckRoll(attacker, TUNING.SHADOW_TENTACLE_RUINS_BAT_CHANCE+0.8*(attacker:HasTag("amped") and 1 or attacker.components.adrenaline:GetPercent()), LuckFormulas.ShadowTentacleSpawn) then
            local pt
            if target ~= nil and target:IsValid() then
                pt = target:GetPosition()
            else
                pt = attacker:GetPosition()
                target = nil
            end
            local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true, true)
            if offset ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
                local tentacle = SpawnPrefab("shadowtentacle")
                if tentacle ~= nil then
                    tentacle.owner = attacker
                    tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                    tentacle.components.combat:SetTarget(target)
                end
            end
        end
        
        -- Other Code from UM
        inst:AddComponent("damagetypebonus")
        inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, 1 + 17 / 59)
    else
        inst.components.weapon._UMBackup_OnAttack(inst, attacker, target)
    end
end

AddPrefabPostInit("ruins_bat", function(inst)
    if not _G.TheWorld.ismastersim then return end

    local _OnUnequip = inst.components.equippable.onunequipfn
    local _OnEquip = inst.components.equippable.onequipfn
   
    local function OnEquip(inst, owner, ...)

        local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab)
        if ID and owner.hone_amounts[ID] >= owner.hone_tiers[2] then
            inst:AddComponent("planardamage")
            inst.components.planardamage:SetBaseDamage(20)
        end
        return _OnEquip(inst, owner, ...)
    end

    local function OnUnequip(inst, owner, ...)
        if inst.components.planardamage then
            inst:RemoveComponent("planardamage")
        end
        return _OnUnequip(inst, owner, ...)
    end

    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    if inst.components.weapon ~= nil then
        inst.components.weapon._UMBackup_OnAttack = inst.components.weapon.onattack
        inst.components.weapon:SetOnAttack(NewOnAttackClub) --The old one doesn't have anything that's really useful to this new version. Replacing.
    end
    
end)

local MUST_TAGS = {"_combat"}
local CANT_TAGS = {"player", "companion", "abigail", "shadowminion", "playerghost", "INLIMBO", "wixieshoved", "invisible",
    "hiding", "notarget", "noattack", "flight", "wall","companion"}

local function AttackingPickAxe(inst, owner, target)
    local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab) -- Ask what it is incase someone changed it
    if ID and owner.hone_amounts[ID] >= owner.hone_tiers[1] then
		local x, y, z = owner.Transform:GetWorldPosition()
		owner:ShakeCamera(CAMERASHAKE.SIDE, 0.25, 0.02, 0.25)
        local scale = owner:HasTag("amped") and 1 or owner.components.adrenaline:GetPercent()
		local ents = TheSim:FindEntities(x, y, z, 4 + 4 * scale, MUST_TAGS,CANT_TAGS)
		if target ~= nil then
			local ring = SpawnPrefab("groundpoundring_fx")
			local x1, y1, z1 = target.Transform:GetWorldPosition()

			ring.Transform:SetPosition(x1, y1, z1)

            local scale2 = 0.55 + scale * 0.3
			ring.Transform:SetScale(scale2, scale2, scale2)
		end
		
		for k, v in ipairs(ents) do
			v.components.combat:GetAttacked(owner, TUNING.MULTITOOL_DAMAGE,nil,"wathom_aoe")
		end

    elseif inst.components.weapon._UMBackup_OnAttack then
        inst.components.weapon._UMBackup_OnAttack(inst, owner, target)
	end
end

AddPrefabPostInit("multitool_axe_pickaxe", function(inst)
    if not _G.TheWorld.ismastersim then return end

    if inst.components.weapon ~= nil then
        inst.components.weapon._UMBackup_OnAttack = inst.components.weapon.onattack
        inst.components.weapon:SetOnAttack(AttackingPickAxe) --The old one doesn't have anything that's really useful to this new version. Replacing.
    end
end)

local function voidcloth_applyitembuff(inst, item, stacks)
    if item.components.planardamage ~= nil then
        if stacks > 0 then
            local bonus = Remap(stacks, 0, 2*TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS, 0, 2*TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX)
            item.components.planardamage:AddBonus(inst, bonus, "voidclothhat_rampingbuff")
        else
            item.components.planardamage:RemoveBonus(inst, "voidclothhat_rampingbuff")
        end
    end
end

local function AttackingReaper(inst, owner, target)
    local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab) -- Ask what it is incase someone changed it
    local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if ID and hat and hat.prefab == "voidclothhat" then
        if owner.hone_amounts[ID] >= owner.hone_tiers[2] then
            hat.buff_stacks = TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS + 3.75*(owner:HasTag("amped") and 1 or owner.components.adrenaline:GetPercent()) * TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS
        elseif owner.hone_amounts[ID] >= owner.hone_tiers[1] then
            hat.buff_stacks = TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS
        end
	end
    if inst.components.weapon._UMBackup_OnAttack then
        inst.components.weapon._UMBackup_OnAttack(inst, owner, target)
    end
    if hat then
        voidcloth_applyitembuff(hat, inst, hat.buff_stacks)
    end
end


AddPrefabPostInit("voidcloth_scythe", function(inst)
    if not _G.TheWorld.ismastersim then return end

    if inst.components.weapon ~= nil then
        inst.components.weapon._UMBackup_OnAttack = inst.components.weapon.onattack
        inst.components.weapon:SetOnAttack(AttackingReaper) --The old one doesn't have anything that's really useful to this new version. Replacing.
    end
end)

local function SapAdrenaline(inst,owner)
    if owner and owner.components.adrenaline and (owner.components.adrenaline:GetPercent() > 0.25 or owner:HasTag("amped")) then
        owner.components.adrenaline:DoDelta(-6)
        inst.components.hunger:DoDelta(6)
    end
end

local function CheckAdrenlineFeeding(inst,owner)
    local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab) -- Ask what it is incase someone changed it
    local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if ID then
        if owner.hone_amounts[ID] > owner.hone_tiers[1] and not inst.sap_adrenaline then
            inst.sap_adrenaline = inst:DoPeriodicTask(10,SapAdrenaline,nil,owner)
        end       
	end 
end

local function AttackingBattleAxe(inst, owner, target)
    CheckAdrenlineFeeding(inst,owner)
    local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab) -- Ask what it is incase someone changed it
    local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if ID then
        --Incase we wanna do anything with the hat
	end 
    if inst.components.weapon._UMBackup_OnAttack then
        inst.components.weapon._UMBackup_OnAttack(inst, owner, target)
    end
end

local function OnPutInInventory(inst,owner)
    CheckAdrenlineFeeding(inst,owner)
    if inst.components.inventoryitem._UMBackup_onputininventoryfn then 
        inst.components.inventoryitem._UMBackup_onputininventoryfn(inst, owner)
    end
end

local function OnDropped(inst)
    if inst.sap_adrenaline then
        inst.sap_adrenaline:Cancel()
        inst.sap_adrenaline = nil
    end
    if inst.components.inventoryitem._UMBackup_ondropfn then 
        inst.components.inventoryitem._UMBackup_ondropfn(inst)
    end
end

local function SayRegularChatLine(inst, list, owner)
    local ID = owner.FindHoneID and owner.FindHoneID(owner,inst.prefab)
    if ID and owner.hone_amounts[ID] >= owner.hone_tiers[1] then
        if inst._classified == nil then
            return
        end
        if list ~= nil then
            local cooldown = TUNING.SHADOW_BATTLEAXE.TALK_INTERVAL[string.upper(list)] or TUNING.SHADOW_BATTLEAXE.TALK_INTERVAL.OVERTIME

            if inst._talktime[list] == nil or (inst._talktime[list] + cooldown <= GetTime()) then
                inst._talktime[list] = GetTime()
            else
                return -- In cooldown!
            end
        end
        -- Level 3 lines are shared with level 4 for regular speech.
        local level = inst.level >= #TUNING.SHADOW_BATTLEAXE.LEVEL_THRESHOLDS and math.random() >= .5 and (inst.level - 1) or inst.level

        list = STRINGS.SHADOW_BATTLEAXE_TALK["overtime_wathomhone_l"..level]

        if list ~= nil then
            inst._classified:Say(list, math.random(#list), "rifts4/nightmare_axe/lvl"..inst.level.."_talk_LP")
        end

        if owner ~= nil and inst.talktask ~= nil then
            inst:StartOvertimeChatTask(owner)
        end

    else
        inst._UMSayRegularChatLine(inst,list,owner)
    end
end

local function SetLevel(inst, level, loading)
    inst._UMSetLevel(inst, level, loading)
    local owner = inst._owner
    local ID = owner and owner.FindHoneID and owner.FindHoneID(owner,inst.prefab)
    if ID and owner.hone_amounts[ID] >= owner.hone_tiers[2] then
        inst._lifesteal = TUNING.SHADOW_BATTLEAXE.LEVEL[inst.level].LIFE_STEAL

        inst.components.planardamage:SetBaseDamage(TUNING.SHADOW_BATTLEAXE.LEVEL[inst.level].PLANAR_DAMAGE*2)

        if inst.components.tool ~= nil then
            inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.SHADOW_BATTLEAXE.LEVEL[inst.level].CHOPPING_EFFICIENCY*2)
        end

        if inst.components.hunger ~= nil then
            inst.components.hunger:SetRate(TUNING.SHADOW_BATTLEAXE.LEVEL[inst.level].HUNGER_RATE*2)

            if inst.level > 1 then
                inst.components.hunger:Resume()
            end
        end
    end
end

AddPrefabPostInit("shadow_battleaxe", function(inst)
    if not _G.TheWorld.ismastersim then return end

    if inst.components.weapon ~= nil then
        inst.components.weapon._UMBackup_OnAttack = inst.components.weapon.onattack
        inst.components.weapon:SetOnAttack(AttackingBattleAxe) 
    end

    inst.components.inventoryitem._UMBackup_onputininventoryfn = inst.components.inventoryitem.onputininventoryfn
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)

    inst.components.inventoryitem._UMBackup_ondropfn = inst.components.inventoryitem.ondropfn
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    
    inst._UMSayRegularChatLine = inst.SayRegularChatLine
    inst.SayRegularChatLine = SayRegularChatLine

    inst._UMSetLevel = inst.SetLevel
    inst.SetLevel = SetLevel
end)

-- Wathom code to break weapons faster
local function BreakWeaponFaster(weapon,damage)
    local weapondamage = weapon.components.weapon and weapon.components.weapon.damage or 0
    damage = damage - weapondamage
    if weapon.components.finiteuses then
        weapon.components.finiteuses:Use(damage/weapondamage)
    elseif weapon.components.perishable then
        weapon.components.perishable:AddTime(-20*damage/weapondamage)
    elseif weapon.components.fueled then
        weapon.components.fueled:DoDelta(-5*damage/weapondamage)
    end
end




-------------------------------------------------------
-- The character select screen lines
STRINGS.CHARACTER_TITLES.wathom = "The Forgotten Parody"
STRINGS.CHARACTER_NAMES.wathom = "Wathom"
STRINGS.CHARACTER_DESCRIPTIONS.wathom = "*Apex Predator\n*Gets amped up with adrenaline\n*Causes animals to panic\n*The faster he goes, the harder he falls"
STRINGS.CHARACTER_QUOTES.wathom = "\"Cruel, the abyss.\""
STRINGS.CHARACTER_SURVIVABILITY.wathom = "Slim"

-- Custom speech strings
STRINGS.CHARACTERS.WATHOM = require "speech_wathom"

-- The character's name as appears in-game
STRINGS.NAMES.WATHOM = "Wathom"
STRINGS.SKIN_NAMES.wathom_none = "Wathom"

-- The skins shown in the cycle view window on the character select screen.
-- A good place to see what you can put in here is in skinutils.lua, in the function GetSkinModes
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = .75,
        offset = { 0, -25 }
    },
}

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
if GetModConfigData("holy fucking shit it's wathom") then
    AddModCharacter("wathom", "MALE", skin_modes)
end

--skincolor
for k, v in pairs(GLOBAL.CLOTHING) do
    if v and v.symbol_overrides_by_character and v.symbol_overrides_by_character.wortox then
        GLOBAL.CLOTHING[k].symbol_overrides_by_character.wathom = v.symbol_overrides_by_character.wortox
    end
end

local function PlanarMassiveAttack(self)
    local x,y,z = self.inst.Transform:GetWorldPosition()
    local fx2 = SpawnPrefab("shadowthrall_projectile_fx")
    fx2.Transform:SetPosition(x,y,z)   
    fx2.Transform:SetScale(1.5,1.5,1.5) 
    fx2.AnimState:PlayAnimation("projectile_impact")
    fx2.DynamicShadow:Enable(false)
    fx2.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")
end


local planar_attack = {} -- Klei structures planar damage calculation in this way
planar_attack["planar"] = 68

-- Relevent combat damage (Bonus Damage due to Wathom's abilities)
env.AddComponentPostInit("combat", function(self)
    local _GetAttacked_Internal = self.GetAttacked_Internal
    function self:GetAttacked_Internal(attacker, damage, weapon, stimuli, spdamage, ...)


        -- The enemy is being damaged further by wathom's bark effect
        if self.inst.um_wathom_barkmod_debuff and attacker and not self.inst.prefab == "wathom" then
            damage = damage * 1.25    
            if spdamage and spdamage["planar"] then --- Buff planar damage
                spdamage["planar"] = 1.25 * spdamage["planar"] 
            end       
        end

        -- For Devour 4 wathom
        if attacker and attacker:HasTag("amped") and not (stimuli and stimuli == "wathom_aoe") and 
            HasSkill(attacker,"glutton_4") and attacker.components.hunger and attacker.components.hunger.current > 100 then
            if not spdamage then -- I'm not attacking with a planar weapon.
                spdamage = {}
                spdamage["planar"] = 34
            elseif spdamage and spdamage["planar"] then -- I'm attacking with a planar weapon.
                spdamage["planar"] = 34 + 1.5 * spdamage["planar"] 
            end 

            -- Some planar FX to show that you were attacked.
            PlanarMassiveAttack(self)

        -- Stalker 2+4 Wathom
        elseif ((HasSkill(attacker,"stalker_2") and attacker.components.adrenaline and attacker.components.adrenaline:GetPercent() < 0.5) or
                (HasSkill(attacker,"stalker_4") and attacker:HasTag("amped"))) and
                not self.inst.wathom_shouldnt_ambush and not (not HasSkill(attacker,"stalker_4") and
                attacker:HasTag("amped")) then
            -- ho boy okay the logic is: if wathom's got < 0.5 adrenaline and not amped with stalker 2, then ambush.
            -- if wathom has stalker 4 and is amped, then ambush as well.
            -- A final conditional is that wathom can't have recently ambushed this recepient of damage

            self.inst.wathom_shouldnt_ambush = true
            
            if HasSkill(attacker,"stalker_4") then
                damage = damage * 2.5
            else
                damage = damage * 1.5
            end
            local planar -- decide if we should make maxwell smoke or planar smash
            if spdamage and spdamage["planar"] then -- I'm attacking with a planar weapon.
                planar = true
                spdamage["planar"] = 1.5 * spdamage["planar"]
                PlanarMassiveAttack(self)
                if HasSkill(attacker,"stalker_4") then
                    spdamage["planar"] = 8 * spdamage["planar"]
                end 
            end 
            if not planar then
                SpawnPrefab("maxwell_smoke").Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            end
        end

        if attacker and attacker.prefab == "wathom" and weapon then
            local planar = spdamage and spdamage["planar"] and spdamage["planar"] or 0
            weapon:DoTaskInTime(0,BreakWeaponFaster,damage + planar) -- Give a delay, since DoAttack needs a weapon.components.weapon reference, breaking reaper will remove it
        end

        return _GetAttacked_Internal(self, attacker, damage, weapon, stimuli, spdamage, ...)
    end

    -- Stalker 2 and 3

    local see_stalker = {"shadow","gestalt"} -- continually growing list of things that are allowed to target stalker wathom
    local _SetTarget = self.SetTarget
    function self:SetTarget(target,...)
        if target and ((HasSkill(target,"stalker_3") and target.components.adrenaline and 
            target.components.adrenaline:GetPercent() < 0.5 and target:GetDistanceSqToInst(self.inst) > 36 and 
                not self.inst.wathom_shouldnt_ambush) or 
                    (HasSkill(target,"stalker_4") and target:HasTag("amped"))) and not self.inst:HasAnyTag(see_stalker) then
            -- Don't target.
        else
            _SetTarget(self,target,...)
            if target and HasSkill(target,"stalker_2") and not self.inst.wathom_shouldnt_ambush then
                self.inst.wathom_shouldnt_ambush = true
            end
        end
    end
end)

env.AddComponentPostInit("health",function(self)
    local _DoDelta = self.DoDelta
    function self:DoDelta(amount,...)
        local inst = self.inst
        if inst.prefab == "wathom" and amount < 0 then
            local mod = 1
            local ad_pct = inst.components.adrenaline:GetPercent()
            if inst:HasTag("amped") then
                mod = 4
            elseif ad_pct > 0.75 then
                mod = 3
            elseif ad_pct > 0.5 then
                mod = 2
            elseif ad_pct > 0.25 then
                mod = 1.5
            end
            
            -- Adrenaline is already not nil if this is wathom
            inst.components.adrenaline:DoDelta(-amount)
            
            inst.adrenalpause = true
            if inst.adrenalresume then
                inst.adrenalresume:Cancel()
                inst.adrenalresume = nil
            end
            inst.adrenalresume = inst:DoTaskInTime(10, function(inst) inst.adrenalpause = false end)
            amount = mod * amount
        end
        _DoDelta(self,amount,...)
    end
end)

local PREFAB_SKINS = GLOBAL.PREFAB_SKINS
local PREFAB_SKINS_IDS = GLOBAL.PREFAB_SKINS_IDS
local SKIN_AFFINITY_INFO = GLOBAL.require("skin_affinity_info")

-- Modded Skin API
--[[
modimport("skins_api")

SKIN_AFFINITY_INFO.wathom = {
    "wathom_triumphant", --Hornet: These skins will show up for the character when the Survivor filter is enabled
}

PREFAB_SKINS["wathom"] = {"wathom_none", "wathom_triumphant",}

PREFAB_SKINS_IDS = {} --Make sure this is after you  change the PREFAB_SKINS["character"] table
for prefab,skins in pairs(PREFAB_SKINS) do
    PREFAB_SKINS_IDS[prefab] = {}
    for k,v in pairs(skins) do
          PREFAB_SKINS_IDS[prefab][v] = k
    end
end
AddSkinnableCharacter("wathom")]]

local function DidIBreathe(inst)
    if inst.sg:HasStateTag("idle") then
        local adrenaline = inst.components.adrenaline
        local current = adrenaline.current
        adrenaline:SetPercent(0)
        if inst.components.sanity then
            inst.components.sanity:DoDelta(current * 0.25)
        end
    end
end

STRINGS.SKIN_NAMES.wathom_none = "Wathom"
STRINGS.SKIN_NAMES.wathom_triumphant = "The Archaic"

STRINGS.SKIN_QUOTES.wathom_none = "\"Cruel, the abyss.\""
STRINGS.SKIN_QUOTES.wathom_triumphant = "\"Pursuit of knowledge; A thousand deaths, will endure.\""

STRINGS.SKIN_DESCRIPTIONS.wathom_none = "A crude recreation of those who came before him."
STRINGS.SKIN_DESCRIPTIONS.wathom_triumphant = "Donned with military attire, Wathom acknowledges and accepts his fate when tracing the Ancients' footsteps. He was born for this."



local wathom_speeds_up = {"dolongaction","doshortaction","chop_start","chop","chop_start", "chop", "mine_start", "mine", "hammer_start", "hammer", "scythe", "till_start", "till", "pour", "dig_start", "dig", "row" }
-- HYPER adaptation - Many Actions are Faster
AddStategraphPostInit("wilson", function(inst) -- Plan on moving this to the other blue mushroomhat states, this is a way cleaner way of making a state play out faster
    for _,j in ipairs(wathom_speeds_up) do
        local _onenter = inst.states[j].onenter
        inst.states[j].onenter = function(inst, pushanim, ...)
            _onenter(inst, pushanim, ...)
            local buffaction = inst:GetBufferedAction()
            local hyper_multiplier = 1.33
            if inst:HasTag("amped") and HasSkill(inst,"hyper_4") and not (buffaction and buffaction.mockattack) and not (inst.components.rider and inst.components.rider:IsRiding()) and hyper_multiplier then
                inst.AnimState:SetDeltaTimeMultiplier(hyper_multiplier)
                if inst.sg.timeout then inst.sg:SetTimeout(inst.sg.timeout / hyper_multiplier) end
                if not inst.sg.currentstate.preserved_timelinetime then
                    inst.sg.currentstate.preserved_timelinetime = {}
                end
                for i, v in ipairs(inst.sg.currentstate.timeline) do
                    local time = inst.sg.currentstate.timeline[i].time
                    if not inst.sg.currentstate.preserved_timelinetime[i] then
                        inst.sg.currentstate.preserved_timelinetime[i] = time
                    end
                    inst.sg.currentstate.timeline[i].time = time / hyper_multiplier
                end
            elseif inst.sg.currentstate.preserved_timelinetime then
                for i, v in ipairs(inst.sg.currentstate.preserved_timelinetime) do
                    local time = inst.sg.currentstate.preserved_timelinetime[i]
                    inst.sg.currentstate.timeline[i].time = time
                end
                inst.sg.currentstate.preserved_timelinetime = nil
            end
        end
    
        local _onexit = inst.states[j].onexit
        inst.states[j].onexit = function(inst, ...)
            inst.AnimState:SetDeltaTimeMultiplier(1)
            _onexit(inst, ...)
        end
    end

    local idle_state = "idle"
    local _onenter = inst.states[idle_state].onenter
    inst.states[idle_state].onenter = function(inst, pushanim, ...)
        _onenter(inst, pushanim, ...)
        if HasSkill(inst,"stalker_1") and inst.components.adrenaline and (inst.components.adrenaline.current > 25 or inst:HasTag("amped")) then
            inst.AnimState:PlayAnimation("idle_hot_pre")
            inst.AnimState:PushAnimation("idle_hot_loop")
            inst.AnimState:PushAnimation("idle_hot_pst", false)
            inst.wathom_listen_for_idle = true
            inst:ListenForEvent("animqueueover",DidIBreathe)
        end
    end

    local _onexit = inst.states[idle_state].onexit
    inst.states[idle_state].onexit = function(inst, ...)
        if inst.wathom_listen_for_idle then
            inst:RemoveEventCallback("animqueueover",DidIBreathe)
            inst.wathom_listen_for_idle = nil
        end
        if _onexit then
            _onexit(inst, ...)
        end
    end

    local _onenter = inst.states["run"].onenter -- AXE Make a previously regular walking wathom run
    inst.states["run"].onenter = function(inst, pushanim, ...)
        if inst:HasTag("wathomrun") then
            inst.sg:GoToState("run_wathom")
        else
            _onenter(inst, pushanim, ...)
        end
    end
end)

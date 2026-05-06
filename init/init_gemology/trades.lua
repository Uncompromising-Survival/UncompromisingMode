local env = env
GLOBAL.setfenv(1, GLOBAL)


local function RetargetSnaildrakeFn(inst)
    if inst.components.combat:HasTarget() then
        return
    end

    local new_target = FindEntity(inst, TUNING.SNAILDRAKE_AGGRO_DIST, function(ent)
        return inst.components.combat:CanTarget(ent)
    end, nil, {"snaildrake","player"}) -- AXE They like people now

    local follower = new_target and new_target.components.follower and new_target.components.follower or nil -- AXE Make them not aggro on your followers
    if new_target and not (follower and follower.leader and follower.leader:HasTag("player")) then
        inst.components.combat:SuggestTarget(new_target)
    end
end

local function BeFriendlyToPlayers(inst)
    local self = inst.components.combat

    -- Old Values
    self._targetfn = self.targetfn
    self._retargetperiod = self._retargetperiod
    if inst.prefab == "snaildrake_slime" or inst.prefab == "snaildrake_magma" then
        inst.components.combat:SetRetargetFunction(3, RetargetSnaildrakeFn)
    end

    local combat = inst.components.combat and inst.components.combat or nil
    if combat and combat.target then -- AXE Drop target if traded
        combat:SetTarget(nil)
    end
end

local function IfPlayerThenLoseFaithInHumanity(inst,data,override)
    local attacker = data and data.attacker and data.attacker or nil
    local follower = attacker and attacker.components.follower and attacker.components.follower or nil

    if (attacker and attacker:HasTag("player") or (follower and follower.leader and follower.leader:HasTag("player"))) or override then
        local self = inst.components.combat
        inst.components.combat:SetRetargetFunction(self._retargetperiod, self._targetfn)
    end
end

local function ShouldAcceptItem(inst, item, giver)
    return item:HasTag("gemology_gem") 
end

local function ProduceItem(inst,prefab,num,tier)
    for i = 1,(num and num or 1),1 do
        local item = SpawnPrefab(prefab)
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if tier then
            item:SetTier(tier)
        end
        if inst.trader and inst.trader:IsValid() then
            LaunchAt(item, inst, inst.trader, 1, 1, nil, math.random(-10,10))
        else
            Launch2(item, inst, 1, 0, 1, math.random(-10,10))
        end
    end
end

local function GenerateLoot(inst)
    local tier = inst.itemquality
    local itemtype = inst.itemtype
    local rnd = math.random()

    local element = (inst.prefab == "slurtle" or inst.prefab == "snurtle") and "green" or "red"
    local hated_element = (inst.prefab == "slurtle" or inst.prefab == "snurtle") and "red" or "blue"
    local generic_item = (inst.prefab == "slurtle" or inst.prefab == "snurtle") and "slurtleslime" or "snapalm"


    if (itemtype == "um_gemology"..element.."gem1") or (itemtype == "um_gemology"..element.."gem2") then
        if tier == 1 then
            if math.random() > 0.75 then
                ProduceItem(inst,itemtype,1,2)
            elseif math.random() > 0.25 then
                ProduceItem(inst,itemtype,1,1)
            else
                ProduceItem(inst,generic_item,math.random(3,5),nil)
            end
        end
        if tier == 2 then
            if math.random() > 0.9 then
                ProduceItem(inst,itemtype,1,3)
            elseif math.random() > 0.7 then
                ProduceItem(inst,itemtype,1,2)
            else
                if (math.random() > 0.5 and element == "red") or (math.random() > 0.9 and element == "green") then
                    ProduceItem(inst,element.."gem",1,nil) -- They can refine into their special gems.
                else
                    ProduceItem(inst,generic_item,math.random(5,9),nil)
                end
            end
        end        
        if tier == 3 then
            if math.random() > 0.75 then
                ProduceItem(inst,itemtype,1,3)
            elseif math.random() > 0.5 then
                ProduceItem(inst,itemtype,1,2)
            else
                ProduceItem(inst,element.."gem",1,nil)
            end
        end    
    elseif itemtype == "um_gemology"..hated_element.."gem1" or itemtype == "um_gemology"..hated_element.."gem2" then
        if hated_element == "blue" then -- Snaildrakes Only
            inst.components.freezable:AddColdness(20) -- FREEZE
            IfPlayerThenLoseFaithInHumanity(inst,nil,true) -- Override, make angry at player
        end
        if hated_element == "red" then
            inst.components.burnable:Ignite()
        end   
        inst.traded_and_friendly = nil
        if inst.trader and inst.components.combat then
            inst.components.combat:SetTarget(inst.trader)
        end
    else
        if tier == 1 then
            if math.random() > 0.9 then
                ProduceItem(inst,itemtype,1,2)
            elseif math.random() > 0.5 then
                ProduceItem(inst,generic_item,1,nil)
                ProduceItem(inst,itemtype,1,1)
            else
                ProduceItem(inst,generic_item,math.random(3,5),nil)
            end
        end
        if tier == 2 then
            if math.random() > 0.9 then
                ProduceItem(inst,itemtype,1,2)
            elseif math.random() > 0.5 then
                ProduceItem(inst,itemtype,1,1)
            else
                ProduceItem(inst,generic_item,math.random(5,9),nil)
            end
        end        
        if tier == 3 then
            if math.random() > 0.75 then
                ProduceItem(inst,itemtype,1,2)
            elseif math.random() > 0.5 then
                ProduceItem(inst,itemtype,1,1)
            else
                ProduceItem(inst,generic_item,math.random(5,9),nil)
            end
        end     
    end

    inst.itemquality = nil
    inst.itemtype = nil
    inst.components.trader.enabled = true
end

local function OnAccept(inst, giver, item, count, name)
    if giver and giver:HasTag("player") then
        inst.components.trader.enabled = false
        if inst.prefab == "snaildrake_slime" or inst.prefab == "snaildrake_magma" then
            BeFriendlyToPlayers(inst)
        end
        inst.traded_and_friendly = true
        --I eat food
        if item.components.edible ~= nil then
            --if inst.components.sleeper:IsAsleep() then -- AXE Funnily enough, snaildrakes and slurtles both don't sleep.
                --inst.components.sleeper:WakeUp()
            --end
            inst.itemquality = item:GetTier()
            inst.itemtype = item.prefab

            inst.GemologyEatFn = GenerateLoot
            inst.trader = giver
            inst.sg:GoToState("rangedattack")
        end
    end
end

-- Snaildrakes and Slurtles
local snaildrakes = {"snaildrake_magma","snaildrake_slime","slurtle","snurtle"}
for i,snaildrake in ipairs(snaildrakes) do
    env.AddPrefabPostInit(snaildrake, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        local _OnSave = inst.OnSave
        local _OnLoad = inst.OnLoad

        local function OnSave(inst,data)
            local data = {}
            if inst.traded_and_friendly then
                data.traded_and_friendly = true
            end
            return _OnSave and _OnSave(inst,data) or data
        end
        local function OnLoad(inst,data)
            if data and data.traded_and_friendly then
                inst.traded_and_friendly = true
                inst:DoTaskInTime(0,BeFriendlyToPlayers)
            end
            return _OnLoad and _OnLoad(inst,data) or nil
        end
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        
        inst:ListenForEvent("attacked",IfPlayerThenLoseFaithInHumanity)

        inst:AddComponent("trader")

        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnAccept
        inst.components.trader.deleteitemonaccept = true

    end)
end

-- AXE Thank Max for this code! It grabs the "StealFood" action regardless of whatever location it may be in.
local UpvalueHacker = require("tools/upvaluehacker")
local SlurtleBrain = require("brains/slurtlebrain")
local _StealFoodAction = UpvalueHacker.GetUpvalue(SlurtleBrain.OnStart, "StealFoodAction")
local function FindStealNode(self)
    for id, node in pairs(self.bt.root.children) do
        if node.getactionfn and node.getactionfn == _StealFoodAction then
            self.bt.root.children[id] = WhileNode(function() return not self.inst.traded_and_friendly end, "ShouldBeNice",
            DoAction(self.inst, _StealFoodAction))
        end
    end
end     
env.AddBrainPostInit("slurtlebrain", function(self)
    FindStealNode(self)
end)


-- Antlion

local function GetAntlionReward(inst)
    local gem = inst.pendingrewarditem
    local tier = inst.pendingrewardtier_gemology

    local orange = (gem == "um_gemologyorangegem1" or gem == "um_gemologyorangegem2")

    local rnd = math.random()
    local itemname
    local newtier
    if tier == 3 then
        if (rnd > 0.9 and orange) or rnd > 0.75 then
            itemname = gem
            newtier = 2
        elseif rnd > 0.1 and orange then
            itemname = "orangegem"
        else
            itemname = "townportaltalisman"
        end
    elseif tier == 2 then
        if (rnd > 0.9 and orange) then
            itemname = gem
            newtier = 3
        elseif (rnd > 0.4 and orange) or rnd > 0.7 then
            itemname = gem
            newtier = 2
        else
            itemname = "townportaltalisman"
        end
    else
        if (rnd > 0.8 and orange) or rnd > 0.9 then
            itemname = gem
            newtier = 2
        elseif (rnd > 0.4 and orange) or rnd > 0.6 then
            itemname = gem
            newtier = 2
        else
            itemname = "townportaltalisman"
        end
    end
    local item = SpawnPrefab(itemname)
    if newtier then
        item:SetTier(newtier)
    end
    return item
end

local ANTLION_RAGE_TIMER = "rage"

env.AddPrefabPostInit("antlion", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    local trader = inst.components.trader

    local _AcceptTest = trader.test
    local _OnGivenItem = trader.onaccept

    local function AcceptTest(inst, item)
        return item:HasTag("gemology_gem") or _AcceptTest(inst,item)
    end

    trader:SetAcceptTest(AcceptTest)

    local function OnGivenItem(inst, giver, item)
        if item:HasTag("gemology_gem") then
            local gemhot = (item.prefab == "um_gemologyredgem1" or item.prefab == "um_gemologyredgem2")
            local gemcold = (item.prefab == "um_gemologybluegem1" or item.prefab == "um_gemologybluegem2")
            local trigger
            if gemhot then
                trigger = "burn"
            elseif gemcold then
                trigger = "freeze"
            end
            if trigger then
                inst:PushEvent("onacceptfighttribute", { tributer = giver, trigger = trigger })
                return
            end

            inst.tributer = giver
            inst.pendingrewarditem = item.prefab
            inst.pendingrewardtier_gemology = item:GetTier()

            local rage_calming = item.components.tradable.rocktribute * TUNING.ANTLION_TRIBUTE_TO_RAGE_TIME
            inst.maxragetime = math.min(inst.maxragetime + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)

            local timeleft = inst.components.worldsettingstimer:GetTimeLeft(ANTLION_RAGE_TIMER)
            if timeleft ~= nil then
                timeleft = math.min(timeleft + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)
                inst.components.worldsettingstimer:SetTimeLeft(ANTLION_RAGE_TIMER, timeleft)
                inst.components.worldsettingstimer:ResumeTimer(ANTLION_RAGE_TIMER)
            else
                inst.components.worldsettingstimer:StartTimer(ANTLION_RAGE_TIMER, inst.maxragetime)
            end
            inst.components.sinkholespawner:StopSinkholes()

            inst:PushEvent("onaccepttribute", { tributepercent = (timeleft or 0) / TUNING.ANTLION_RAGE_TIME_MAX })

            if giver ~= nil and giver.components.talker ~= nil and GetTime() - (inst.timesincelasttalker or -TUNING.ANTLION_TRIBUTER_TALKER_TIME) > TUNING.ANTLION_TRIBUTER_TALKER_TIME then
                inst.timesincelasttalker = GetTime()
                giver.components.talker:Say(GetString(giver, "ANNOUNCE_ANTLION_TRIBUTE"))
            end
        else
            _OnGivenItem(inst, giver, item)
        end
    end
    trader.onaccept = OnGivenItem

    local _GiveReward = inst.GiveReward
    local function GiveReward(inst)
        if inst.pendingrewardtier_gemology then
            local item = GetAntlionReward(inst)

            LaunchAt(item, inst, (inst.tributer ~= nil and inst.tributer:IsValid()) and inst.tributer or nil, 1, 2, 1)
            inst.pendingrewarditem = nil
            inst.pendingrewardtier_gemology = nil
            inst.tributer = nil
        else
            _GiveReward(inst)
        end
    end

    inst.GiveReward = GiveReward

end)

local function AddFollowerTime(inst,giver)
    if inst.components.combat:TargetIs(giver) then
        inst.components.combat:SetTarget(nil)
    elseif giver.components.leader ~= nil then
        if not giver.components.minigame_participator then
            giver:PushEvent("makefriend")
            giver.components.leader:AddFollower(inst)
        end
        inst.components.follower:AddLoyaltyTime(
            (giver:HasTag("polite")
            and TUNING.ROCKY_LOYALTY + TUNING.ROCKY_POLITENESS_LOYALTY_BONUS)
            or TUNING.ROCKY_LOYALTY
        )
        inst.sg:GoToState("rocklick")
    end
end


local function GenerateRockyLoot(inst,giver,item)
    local gem = item.prefab  
    local tier = item:GetTier()
    local pale = (gem == "um_gemologypalegem1" or gem == "um_gemologypalegem2")

    local rnd = math.random()
    local itemname
    local newtier
    if tier == 3 then
        if (rnd > 0.9 and pale) or rnd > 0.75 then
            itemname = gem
            newtier = 2
        else
            itemname = "friendship"
        end
    elseif tier == 2 then
        if (rnd > 0.9 and pale) then
            itemname = gem
            newtier = 3
        elseif (rnd > 0.4 and pale) or rnd > 0.7 then
            itemname = gem
            newtier = 2
        else
            itemname = "friendship"
        end
    else
        if (rnd > 0.8 and pale) or rnd > 0.9 then
            itemname = gem
            newtier = 2
        elseif (rnd > 0.3 and pale) or rnd > 0.6 then
            itemname = gem
            newtier = 1
        else
            itemname = "friendship"
        end
    end
    if itemname ~= "friendship" then
        local item = SpawnPrefab(itemname)
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
        if newtier then
            item:SetTier(newtier)
        end
        if item and item:IsValid() and giver and giver:IsValid() then
            LaunchAt(item, inst, giver, 1, 1, nil, math.random(-10,10))
        else
            Launch2(item, inst, 1, 0, 1, math.random(-10,10))
        end
        inst.sg:GoToState("rocklick")
    elseif giver then
        AddFollowerTime(inst,giver)
    end
end


env.AddPrefabPostInit("rocky", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    local trader = inst.components.trader

    local _AcceptTest = trader.test
    local _OnGivenItem = trader.onaccept

    local function AcceptTest(inst, item)
        return item:HasTag("gemology_gem") or _AcceptTest(inst,item)
    end

    trader:SetAcceptTest(AcceptTest)  
    local _OnGetItemFromPlayer =  trader.onaccept

    local function OnGetItemFromPlayer(inst, giver, item)
        if item:HasTag("gemology_gem") then
            GenerateRockyLoot(inst,giver,item)            
        else
            _OnGetItemFromPlayer(inst,giver,item)         
        end
    end
    trader.onaccept = OnGetItemFromPlayer

end)

local function TryGemologyLoot(inst)
    if inst.gem_level then
        local rnd = math.random()
        local chance = inst.gem_chance
        local loot = SpawnPrefab("um_gemologybluegem"..math.random(1,2)) -- Random!
        if inst.gem_level == 1 then
            if 10*(rnd) < chance then
                loot:SetTier(2)
            elseif 5*(rnd) < chance then
                loot:SetTier(1)
            else
                loot:Remove()
            end 
        elseif inst.gem_level == 2 then
            if 30*(rnd) < chance  then
                loot:SetTier(3)
            elseif 20*(rnd) < chance then
                loot:SetTier(2)
            else
                loot:Remove()
            end       
        elseif inst.gem_level == 3 then
            loot:Remove()
            loot = SpawnPrefab("bluegem") -- Purify
        end
        if loot and loot:IsValid() then
            loot.Transform:SetPosition(inst.Transform:GetWorldPosition())
            Launch2(loot, inst, 1, 0, 1, math.random(0,360))
        end
    end
end

env.AddPrefabPostInit("snowmong",function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.TryGemologyLoot = TryGemologyLoot
end)
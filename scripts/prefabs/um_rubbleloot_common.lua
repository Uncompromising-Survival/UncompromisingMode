-----------------------------------------
-- Predefs
-----------------------------------------
local rl_name = "um_rubbleloot_"

local assets =
{
    Asset("ANIM", "anim/"..rl_name.."rainometer.zip"),
    Asset("ANIM", "anim/"..rl_name.."thermometer.zip"),
    Asset("ANIM", "anim/"..rl_name.."researchlab1.zip"),
    Asset("ANIM", "anim/"..rl_name.."researchlab2.zip"),
    Asset("ANIM", "anim/"..rl_name.."bloodbag.zip"),
    Asset("ANIM", "anim/"..rl_name.."goldacorn.zip"),
    Asset("ANIM", "anim/"..rl_name.."petrifier.zip"),
    Asset("ANIM", "anim/"..rl_name.."garlicbraid.zip"),
    Asset("ANIM", "anim/"..rl_name.."bones.zip"),
    Asset("ANIM", "anim/"..rl_name.."rimeseed.zip"),
    Asset("ANIM", "anim/"..rl_name.."preservecan.zip"),
    Asset("ANIM", "anim/"..rl_name.."multitool.zip"),
    Asset("ANIM", "anim/"..rl_name.."pocketforge.zip"),
    Asset("ANIM", "anim/"..rl_name.."mrnoisy.zip"),
    Asset("ANIM", "anim/swap_mrnoisy.zip")
}

local UpvalueHacker = require("tools/upvaluehacker")

local LINK_FX_SPAWNER_STEPDIST = 3
local function MakeFxAtPoint(pt,prefab)
    local stink = SpawnPrefab(prefab)
    stink.Transform:SetPosition(pt.x,0,pt.z)
    stink:ListenForEvent("animover",function(stink)
        stink:Remove()
    end)
end

local function CreateLineFx(inst,v,newpos_x,newpos_z,prefab)
    local x, y, z = inst.Transform:GetWorldPosition()
    --[[if inst.components.invenotryitem and inst.components.inventoryitem:IsHeld() then
        x,y,z = inst.components.inventoryitem.owner.Transform:GetWorldPosition()
    end]]
    local xc,yc,zc = v.Transform:GetWorldPosition()
    if newpos_x then
        x = newpos_x
        z = newpos_z
    end
    local len = VecUtil_Length(xc - x, zc - z)
    if len > 2 then
        local dir_x, dir_z = VecUtil_Normalize(xc - x, zc - z)
        local newpos_x, newpos_z = x + dir_x * LINK_FX_SPAWNER_STEPDIST, z + dir_z * LINK_FX_SPAWNER_STEPDIST
        local pt = {}
        pt.x = newpos_x
        pt.z = newpos_z
        MakeFxAtPoint(pt,prefab)
        CreateLineFx(inst,v,newpos_x,newpos_z,prefab)
    end
end

-----------------------------------------
-- Mr Noisy
-----------------------------------------
UMCommonFns = require("tools/um_commonfns")

local should_hit = { "_combat", "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable" }
local shouldnt_hit = { "INLIMBO", "notarget", "noattack", "playerghost" }
local ACTIONS_TO_WORK = {
    [ACTIONS.CHOP] = 15,
    [ACTIONS.HAMMER] = 4,
    [ACTIONS.DIG] = 1
}
local function Detonate(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("explosivehit")
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(1.25, 1.25, 1.25)
    fx.persists = false
    fx:DoTaskInTime(1, fx.Remove)
    local ents = TheSim:FindEntities(x, y, z, 3, nil, shouldnt_hit, should_hit)
    if #ents > 0 then
        for i, v in pairs(ents) do
                if not v.components.fueled and v.components.burnable and not v.components.burnable:IsBurning() and not v:HasTag("burnt") then
                    v.components.burnable:Ignite(true, inst)
                end
                if v.components.combat then
                    v.components.combat:GetAttacked(TheWorld, TUNING.DSTU.PYREBOMB_DAMAGE)
                end
            local workable = v.components.workable
            if workable and not v.components.health and not v:HasTag("NET_workable") then workable:WorkedBy(TheWorld, ACTIONS_TO_WORK[workable.action] or 3) end
        end
    end
    inst:Remove()
end

local function NoisyAttacked(inst, data)
	if data and data.attacker and inst.components.health and not inst.components.health:IsDead() then
        if math.random() > 0.2 then
            inst.SoundEmitter:PlaySound("um_mrnoisy/um_mrnoisy/hit_slip")
            if inst.prev_health then
                inst.components.health:SetCurrentHealth(inst.prev_health)
            end
        else
            inst.SoundEmitter:PlaySound("um_mrnoisy/um_mrnoisy/hit")
            inst.prev_health = inst.components.health.currenthealth
        end
        Launch(inst,data.attacker,4) -- All hits are knockback
        if inst.components.health and not inst.components.health:IsDead() then
            inst.SoundEmitter:SetParameter("loopannoy", "pitch", 1-inst.components.health:GetPercent())
        end
    end
end

local dont_aggro = JoinArrays(UMCommonFns.GHOSTLIKE_TAGS, {"player"}) -- dummy second table, leaving here because I'm sure we'll need to add more exceptions
local function TryGrabAggro(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local above_ground
    if TheWorld.Map:IsAboveGroundAtPoint(x,y,z) then -- function changes if not reachable
        above_ground = true
    else
        above_ground = false
    end

    local creatures = TheSim:FindEntities(x,y,z,16,{"_combat"},dont_aggro)

    for i,v in ipairs(creatures) do -- Filter to ensure that whatever noisy is provoking can actually reach him
        local should_provoke = true
        
        if not (v:HasTag("flying") or v.components.amphibiouscreature) then -- ampbibious meaning they can go both on land and sea.
            local x,y,z = v.Transform:GetWorldPosition()
            local c_above_ground = TheWorld.Map:IsAboveGroundAtPoint(x,y,z)
            if c_above_ground ~= above_ground then -- Simple check really, if we're both above ground or above water then you can try to get me
                should_provoke = nil
            end
        end

        if should_provoke then
            v.components.combat:SetTarget(inst)
        end
    end
end

local function BecomeNoisy(inst)
    if inst:HasTag("NOCLICK") then
        inst:RemoveTag("NOCLICK")
    end
    -- Reset Physics
    inst.Physics:SetFriction(0.5)
    inst.Physics:SetDamping(0.5)
    inst.Physics:SetCollisionMask(
        COLLISION.GROUND,
        COLLISION.OBSTACLES,
        COLLISION.ITEMS,
        COLLISION.WORLD
    )
    inst.AnimState:PlayAnimation("idletoloop",false)
    inst.AnimState:PushAnimation("loop",true)

    inst.components.fueled:StartConsuming()

    inst.SoundEmitter:PlaySound("um_mrnoisy/um_mrnoisy/wind")
    inst:DoTaskInTime(0.9,function(inst)
        if not (inst.components.inventoryitem and inst.components.inventoryitem:IsHeld()) then
            TryGrabAggro(inst)
            inst.SoundEmitter:PlaySound("um_mrnoisy/um_mrnoisy/loop","loopannoy")
            inst.SoundEmitter:SetParameter("loopannoy", "pitch", 0.01)
            inst.SoundEmitter:SetParameter("loopannoy", "volume", -0.4)
            inst.music_looptask = inst:DoPeriodicTask(18,function(inst) -- loop the FX, if possible
                if inst.SoundEmitter:PlayingSound("loopannoy") then
                    inst.SoundEmitter:KillSound("loopannoy")
                end
                inst.SoundEmitter:PlaySound("um_mrnoisy/um_mrnoisy/loop","loopannoy")
                
            end)
        end
    end)
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)
    inst.components.inventoryitem.canbepickedup = true
    inst.grab_aggro_task = inst:DoPeriodicTask(5,TryGrabAggro)
    inst.prev_health = inst.components.health.currenthealth

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
    inst:AddTag("chum")
end

local function onequipnoisy(inst, owner)
    
    --[[local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", "swap_" .. skin_build, "swap_twisted_antler", inst.GUID, "swap_cursed_antler")
    else]]
        owner.AnimState:OverrideSymbol("swap_object", "swap_mrnoisy", "swap_mrnoisy")
    --end -- for when the skins come around

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequipnoisy(inst, owner)
    --[[local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end]] -- For when the noisy skins come around I guess

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onthrown_noisy(inst)
    inst.Physics:SetCollisionMask(
        COLLISION.GROUND,
        COLLISION.OBSTACLES,
        COLLISION.ITEMS
    )

    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.AnimState:PlayAnimation("spin_loop", true)
end

local function PickupNoisy(inst)
    inst.components.fueled:StopConsuming()
    inst.SoundEmitter:KillSound("loopannoy")

    if inst.music_looptask then
        inst.music_looptask:Cancel()
        inst.music_looptask = nil
    end

    if inst:HasTag("chum") then
        inst:RemoveTag("chum")
    end

    inst.AnimState:PlayAnimation("idle") -- need to stop whatever animation it was playing and do idle instead for when it next drops

    if inst.components.health then
        inst:RemoveComponent("health")
    end

    if inst.components.sanityaura then
        inst:RemoveComponent("sanityaura")
    end
end

-----------------------------------------
-- Multi Tool (winona toolbox but not the best)
-----------------------------------------

local num2letter = {"b","c","d"}
local function OpenTool(inst,doer)
    if inst.components.inventoryitem and not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("empty")
        inst.components.inventoryitem:ChangeImageName(rl_name.."multitool_a")
    end
    inst.components.fueled:StopConsuming()
end

local function CloseTool(inst,doer)
    if inst.components.container:GetAllItems() and #inst.components.container:GetAllItems() > 0 then
        inst.AnimState:PlayAnimation("tool"..#inst.components.container:GetAllItems())
        inst.components.fueled:StartConsuming()
        inst.components.inventoryitem:ChangeImageName(rl_name.."multitool_"..num2letter[#inst.components.container:GetAllItems()])
    else
        inst.AnimState:PlayAnimation("empty")
        inst.components.inventoryitem:ChangeImageName(rl_name.."multitool_a")
    end
end
-----------------------------------------
-- Preserve Can
-----------------------------------------

local function WrapStuff(inst, owner)
    if CanWrap(inst) then
        local bundle = SpawnPrefab("um_rubbleloot_preservecan_full")
        local pos = inst:GetPosition()
        if owner then
            pos = owner:GetPosition()
        end

        local item = inst.components.container:GetItemInSlot(1)
        if item ~= nil and not item:HasTag("irreplaceable") then -- and not (item.components.edible and item.components.perishable) then --Initially disallowed food, instead rework to not protect against spoilage
            table.insert(items, item)
            inst.components.container:RemoveItemBySlot(1)
        end

        bundle.components.unwrappable:WrapItems(items, inst)
        for i, v in ipairs(items) do
            v:Remove()
        end
        bundle.timebundled = (TheWorld.state.time + TheWorld.state.cycles) * 8 * 60 --shouldn't we use GetTime instead?
        inst.components.container:GiveItem(bundle, inst.components.container:GetItemInSlot(7) == nil and 7 or 8, pos, true)
        return true
    elseif owner and owner.components.talker then
        owner.components.talker:Say(GetString(owner, "ACTIONFAIL_GENERIC"))
        return false
    end
end

local function OnStartBundling(inst)--, doer)
    inst.components.stackable:Get():Remove()
end

local function OpenCan(inst,doer)
    if inst.components.inventoryitem and not inst.components.inventoryitem:IsHeld() then
        inst.AnimState:PlayAnimation("empty")
        inst.components.inventoryitem:ChangeImageName(rl_name.."preservecan_a")
    end
end

local function CloseCan(inst, num, doer)
    if doer ~= nil and doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound(inst.skin_wrap_sound or "dontstarve/common/together/packaged")
    end
    inst.AnimState:PlayAnimation("full")
    inst.components.inventoryitem:ChangeImageName(rl_name.."preservecan_b")
end

local function CheckIfHoldingThenDrop(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
    end
    inst:Remove()
end

local function OnUnwrapped(inst, pos, doer)
    -- Need a replacement FX
    --SpawnPrefab((inventoryimage or name).."_unwrap").Transform:SetPosition(pos:Get())

    -- Could try for a different SFX
    if doer ~= nil and doer.SoundEmitter ~= nil then
        doer.SoundEmitter:PlaySound("dontstarve/common/together/packaged")
    end
    inst:Remove()
end
-----------------------------------------
-- Rime
-----------------------------------------

local function on_deploy_rime(inst, position, deployer)
    local new_rime = SpawnPrefab("rimeweed_main")
    if new_rime then
        new_rime.Transform:SetPosition(position:Get())
        new_rime.SoundEmitter:PlaySound("dontstarve/common/plant")
        inst:Remove()
    end
end

-----------------------------------------
-- Chalky Bones
-----------------------------------------

local function LeapOutToTouchy(inst,player,touchy)
    local direction = (touchy:GetPosition() - player:GetPosition()):GetNormalized()
    inst = player.components.inventory:DropItem(inst, false, direction)
    player:PushEvent("onitemstolen", { item = inst, thief = touchy, })
    Launch(inst, touchy, -3)
end

local function SearchForTouchStone(inst)
    local player = inst.player
    if player then
        local touchy = FindEntity(player,32,function(ent) return ent.prefab == "resurrectionstone" and player.components.touchstonetracker:IsUsed(ent) end)
        if touchy then
            CreateLineFx(player,touchy,nil,nil,"moon_altar_link_fx")
            
            if math.random() > 0.75 then
                LeapOutToTouchy(inst,player,touchy)
            end
            if inst.pace == 10 then -- Quicken the search if it got a hit - so the FX appears more frequent.
                inst.pace = 2
                if inst.BonesTask then
                    inst.BonesTask:Cancel()
                    inst.BonesTask = nil
                end
                if inst.components.inventoryitem:IsHeld() then
                    inst.BonesTask = inst:DoPeriodicTask(inst.pace,SearchForTouchStone)
                end
            end
        else
            if inst.pace == 2 then
                inst.pace = 10
                if inst.BonesTask then
                    inst.BonesTask:Cancel()
                    inst.BonesTask = nil
                end
                if inst.components.inventoryitem:IsHeld() then
                    inst.BonesTask = inst:DoPeriodicTask(inst.pace,SearchForTouchStone)
                end
            end
        end            
    end
end

local function BonesAwakens(inst, guy)
    if guy and guy:HasTag("player") then
        inst.player = guy
        inst.pace = 10
        if inst.BonesTask then
            inst.BonesTask:Cancel()
            inst.BonesTask = nil
        end
        inst.BonesTask = inst:DoPeriodicTask(inst.pace,SearchForTouchStone) -- Long gap between searches
    end
end

local function BonesSleeps(inst)
    if inst.BonesTask then
        inst.BonesTask:Cancel()
        inst.BonesTask = nil
    end
    inst.player = nil
end



-----------------------------------------
-- Garlic Braid
-----------------------------------------

local function FindBatsToSpook(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local bats = TheSim:FindEntities(x,y,z,16,{"bat"})
    for i,v in ipairs(bats) do
        if not v.um_vampire_garlic_cd then
            if v.components.hauntable and v.components.health and not v.components.health:IsDead() then
                if inst.components.perishable then
                    inst.components.perishable:ReducePercent(0.001)
                end

                CreateLineFx(inst,v,nil,nil,"ratmask_stinklines")
                v.components.hauntable:Panic(6)
                v.um_vampire_garlic_cd = true
                if v.components.sleeper and v.components.sleeper:IsAsleep() then
                    v.components.sleeper:WakeUp()
                end
                v:DoTaskInTime(v.components.health.maxhealth / 10,function(v) -- CD based upon health
                    v.um_vampire_garlic_cd = nil
                end) -- Delay re-use based upon health
            end
        end
    end
end

local function GarlicAwakens(inst)
    inst.GarlicTask = inst:DoPeriodicTask(5,FindBatsToSpook) -- Long gap between searches
end

local function GarlicSleeps(inst)
    if inst.GarlicTask then
        inst.GarlicTask:Cancel()
        inst.GarlicTask = nil
    end
end

-----------------------------------------
-- Petrifier
-----------------------------------------
local petrify_radius = 16
-- Klei's local stuff from hound.lua and pigman.lua...

-- This does not work like this or with GLOBAL.(stuff) on the call... If there's a way to grab these functions, I don't know what it is
local _OnMoonPetrifyHound = UpvalueHacker.GetUpvalue(Prefabs.moonhound.fn, "OnMoonPetrify")
local _OnMoonPetrifyPig = UpvalueHacker.GetUpvalue(Prefabs.moonpig.fn, "OnMoonPetrify")

local function OnMoonPetrifyMisc(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation()
    inst:Remove()

    SpawnPrefab("halloween_moonpuff").Transform:SetPosition(x, y, z)
    local gargoyle = SpawnPrefab("moonrock_pieces")
    gargoyle.Transform:SetPosition(x, y, z)
    gargoyle.Transform:SetRotation(rot)

    local type = math.random(1,8)
    if inst:HasTag("bird") then
        type = math.random() > 0.5 and 1 or 5
    end
    if inst:HasTag("spider") then
        type = 4
    end
    if inst.prefab == "rabbit" then
        type = 3
    end
    if inst.prefab == "flower" or inst.prefab == "flower_evil" then
        type = math.random(6,8)
    end
    gargoyle.AnimState:PlayAnimation("s"..type)
    gargoyle.piece = type
end

local POINTS_ANGLEDIFF = PI/18
local function GeneratePoints(inst)
    local _points = {}
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local angle = 0
    while angle < TWOPI do
        local x = ix + petrify_radius * math.cos(angle)
        local z = iz + petrify_radius * math.sin(angle)
        table.insert(_points, {x, z})
        angle = angle + POINTS_ANGLEDIFF
    end

    return shuffleArray(_points)
end
local function PetrifierEffect(inst,worker)
    local points = GeneratePoints(inst)
    for i,v in ipairs(points) do
        local x, z = v[1], v[2]
        local fx = SpawnPrefab("moon_altar_link_fx")
        fx.Transform:SetPosition(x, 0, z)
    end

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,petrify_radius)

    for i,v in ipairs(ents) do
        -- Things to turn into moonrocks
        if v.components.health then
            if v.prefab == "hound" or v.prefab == "moonhound" then
                _OnMoonPetrifyHound(v)
            end
            if v.prefab == "moonpig" or (v:HasTag("werepig") and v:HasTag("pig")) then
                _OnMoonPetrifyPig(v)
            end
        end

        --Things that look like the moonrock pieces from the moonstone event
        if v.prefab == "rabbit" or v.prefab == "spider" or 
                v.prefab == "flower" or v.prefab == "flower_evil" or v:HasTag("bird") then
            v.origin_petrify = inst:GetPosition() -- This prefab will likely be gone by the end of the taskintime
            v:DoTaskInTime(0.1 * math.sqrt(v:GetDistanceSqToPoint(v.origin_petrify)),function(v)
                if math.sqrt(v:GetDistanceSqToPoint(v.origin_petrify)) < petrify_radius then
                    OnMoonPetrifyMisc(v)
                else
                    v.origin_petrify = nil
                end
            end)
        end

        -- Things to Petrify (evergreens)
        if v.components.workable and v.components.petrifiable then
			v:ListenForEvent("animover",function(v)
                SpawnPrefab("halloween_moonpuff").Transform:SetPosition(v.Transform:GetWorldPosition())
            end)
            v.components.petrifiable:Petrify(true)
        end
        -- Mushtrees
        if v:HasTag("mushtree") and v.DoShroomPetrify then -- Incase other prefabs don't have the mushtree tag, check to see if the function call exists
            v:DoTaskInTime(17*FRAMES,function(v)
                SpawnPrefab("halloween_moonpuff").Transform:SetPosition(v.Transform:GetWorldPosition())
            end)
            v.DoShroomPetrify(v,nil,0.1)
        end
    end
end




-----------------------------------------
-- Anim Calls
-----------------------------------------

-- Rainometer 
local function Raincheck(inst)
    local cur_rain = TheWorld.state.pop
    if cur_rain <= 0.33 then
        return "low"
    elseif cur_rain > 0.33 and cur_rain <= 0.66 then
        return "med"
    else
        return "full"
    end
end

local function RainAnimFn(inst)
    inst.components.finiteuses:Use(0.01488) -- AXE This will eventually break the rainometer in approximately a year 100/(60*8*70/5), 
    local rain_anim = Raincheck(inst)       -- the /5 is for the periodic task triggering only every 5 seconds.
    inst.AnimState:PlayAnimation(rain_anim) -- 100 is 100 finiteuses, 60*8*70 is the number of seconds in a Don't Starve year.
end

-- Thermometer
local function Tempcheck(inst)
    local temp = math.clamp(GetLocalTemperature(inst), 0, TUNING.OVERHEAT_TEMP) / TUNING.OVERHEAT_TEMP

    local heatwave = TheWorld:HasTag("heatwavestart") or TheWorld.net:HasTag("heatwavestartnet") 
        or TheWorld.components.worldsettingstimer ~= nil and 
        TheWorld.components.worldsettingstimer:GetTimeLeft("um_heatwave_timer") ~= nil and 
        TheWorld.components.worldsettingstimer:GetTimeLeft("um_heatwave_timer") < 120

    local snowstorm = TheWorld:HasTag("snowstormstart") or TheWorld.net:HasTag("snowstormstartnet") 
        or TheWorld.components.worldsettingstimer ~= nil and 
        TheWorld.components.worldsettingstimer:GetTimeLeft("um_snowstorm_timer") ~= nil and 
        TheWorld.components.worldsettingstimer:GetTimeLeft("um_snowstorm_timer") < 120

    if heatwave then
        return "heatshake"
    elseif snowstorm then
        return "lowshake"
    end

    if temp <= 0.2 then
        return "low","a"
    elseif temp > 0.2 and temp <= 0.4 then
        return "lowmed","b"
    elseif temp > 0.4 and temp <= 0.6 then
        return "med","c"
    elseif temp > 0.6 and temp <= 0.8 then
        return "medfull","d"
    else
        return "full","e"
    end
end

local function ThermAnimFn(inst)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(0.05) 
    end
    local temp_anim,suffix = Tempcheck(inst)
    inst.AnimState:PlayAnimation(temp_anim) 
    inst.components.inventoryitem:ChangeImageName(rl_name.."thermometer_"..suffix)
end

-----------------------------------------
-- IsGifting Check - Research labs only - Borrowed from scienceprototyper.lua prefab.
-----------------------------------------
-- This only exists in this spot because some workable functions need to call it.
local function isgifting(inst)
    for k, v in pairs(inst.components.prototyper.doers) do
        if k.components.giftreceiver ~= nil and
            k.components.giftreceiver:HasGift() and
            k.components.giftreceiver.giftmachine == inst then
            return true
        end
    end
end

-----------------------------------------
-- Workable FNs
-----------------------------------------

-- Common
local function OnCommonHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnPetriHammered(inst, worker)
    PetrifierEffect(inst,worker)
    OnCommonHammered(inst, worker)
end

-- Could unify these
-- Rainometer
local function OnRainHit(inst)
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    local hitanim = "hit"..Raincheck(inst)
    inst.AnimState:PlayAnimation(hitanim,false)
    inst.task = inst:DoPeriodicTask(5,RainAnimFn)
end

-- Thermometer
local function OnTempHit(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.AnimState:PlayAnimation("hit",false)
    inst.task = inst:DoPeriodicTask(1,ThermAnimFn)
end

-- Prototyper
local function OnProtoHit(inst)
    inst.AnimState:PlayAnimation("hit")
    if inst.components.prototyper.on then
        inst.AnimState:PushAnimation("proximity_loop",true) --isgifting(inst) and "proximity_gift_loop" or "proximity_loop", true)
    else
        inst.AnimState:PushAnimation("idle", false)
    end
end

-----------------------------------------
-- Prototyper - Research labs only - Borrowed from scienceprototyper.lua prefab.
-----------------------------------------
local function onturnonPrototyper(inst)
    local soundprefix = inst.prefab == rl_name.."researchlab1" and "lvl1" or "lvl2"
    if inst._activetask == nil then
        if isgifting(inst) then
            if inst.AnimState:IsCurrentAnimation("proximity_loop") or --inst.AnimState:IsCurrentAnimation("proximity_gift_loop") or
                inst.AnimState:IsCurrentAnimation("place") then
                --NOTE: push again even if already playing, in case an idle was also pushed
                --inst.AnimState:PushAnimation("proximity_gift_loop", true)
                inst.AnimState:PushAnimation("proximity_loop", true)
            else
                --inst.AnimState:PushAnimation("proximity_gift_loop", true)
                inst.AnimState:PushAnimation("proximity_loop", true)
            end
            if not inst.SoundEmitter:PlayingSound("loop") then
                inst.SoundEmitter:KillSound("idlesound")
                inst.SoundEmitter:PlaySound("dontstarve/common/research_machine_gift_active_LP", "loop")
            end
        else
            if inst.AnimState:IsCurrentAnimation("proximity_loop") or
                inst.AnimState:IsCurrentAnimation("place") then
                --NOTE: push again even if already playing, in case an idle was also pushed
                inst.AnimState:PushAnimation("proximity_loop", true)
            else
                inst.AnimState:PlayAnimation("proximity_loop", true)
            end
            if not inst.SoundEmitter:PlayingSound("idlesound") then
                inst.SoundEmitter:KillSound("loop")
                inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_idle_LP", "idlesound")
            end
        end
    end
end

local function onturnoffPrototyper(inst)
    if inst._activetask == nil and not inst:HasTag("burnt") then
		inst.AnimState:PlayAnimation("idle", false)
        inst.SoundEmitter:KillSound("idlesound")
        inst.SoundEmitter:KillSound("loop")
    end
end

local function refreshonstate(inst)
    if inst.components.prototyper.on then
        onturnonPrototyper(inst)
    end
end

local function doneact(inst)
    if not inst.components.inventoryitem:IsHeld() then
        inst._activetask = nil
        if inst.components.prototyper.on then
            onturnonPrototyper(inst)
        else
            onturnoffPrototyper(inst)
        end
    end
end

local function doonact(inst, soundprefix)
    if not inst.components.inventoryitem:IsHeld() then
        local soundprefix = inst.prefab == rl_name.."researchlab1" and "lvl1" or "lvl2"
        if inst._activecount and inst._activecount > 1 then
            inst._activecount = inst._activecount - 1
        else
            if inst._activecount then
                inst._activecount = 0
            end
            inst.SoundEmitter:KillSound("sound")
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_ding")
    end
end

local function onactivatePrototyper(inst)
    local soundprefix = inst.prefab == rl_name.."researchlab1" and "lvl1" or "lvl2"

    inst.AnimState:PlayAnimation("use")
    inst.AnimState:PushAnimation("idle", false)
    if not inst.SoundEmitter:PlayingSound("sound") then
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..soundprefix.."_run", "sound")
    end
    inst._activecount = inst._activecount + 1
    inst:DoTaskInTime(1.5, doonact, soundprefix)
    if inst._activetask ~= nil then
        inst._activetask:Cancel()
    end
    inst._activetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, doneact)

    inst.components.finiteuses:Use(1)
end


local function ongiftopened(inst)
    local giftsound = inst.prefab == rl_name.."researchlab1" and "science" or "alchemy"

    inst.AnimState:PlayAnimation("use")
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_"..giftsound.."_gift_recieve")
    if inst._activetask ~= nil then
        inst._activetask:Cancel()
    end
    inst._activetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, doneact)

    inst.components.finiteuses:Use(0.5)
end

-----------------------------------------
-- Chargeable - Rainometer Only - Borrowed from lightningrod.lua prefab.
-----------------------------------------

local function dozap(inst)
    if inst.zaptask ~= nil then
        inst.zaptask:Cancel()
    end

    inst.SoundEmitter:PlaySound("dontstarve/common/lightningrod")
    SpawnPrefab("lightning_rod_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst.zaptask = inst:DoTaskInTime(math.random(10, 40), dozap)
end

local ondaycomplete

local function discharge(inst)
    if inst.charged then
        inst:StopWatchingWorldState("cycles", ondaycomplete)
        inst.AnimState:ClearBloomEffectHandle()
        inst.charged = false
        inst.chargeleft = nil
        inst.Light:Enable(false)
        if inst.zaptask ~= nil then
            inst.zaptask:Cancel()
            inst.zaptask = nil
        end
    end
end

local function ondaycomplete(inst)
    dozap(inst)
    if inst.chargeleft > 1 then
        inst.chargeleft = inst.chargeleft - 1
    else
        discharge(inst)
    end
end

local function setcharged(inst, charges)
    if not inst.charged then
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        TheNet:Announce("enabled")
        inst.Light:Enable(true)
        inst:WatchWorldState("cycles", ondaycomplete)
        inst.charged = true
    end
    inst.chargeleft = math.max(inst.chargeleft or 0, charges)
    dozap(inst)
end

local function onlightning(inst)
    inst.components.finiteuses:Use(5)
    OnRainHit(inst)
    setcharged(inst, 3)
end

local function CalcActualCharge(inst)
	return inst.chargeleft and inst.chargeleft - (math.ceil(inst.chargeleft) - 1)
end

local function CanBeUsedAsBattery(inst, user, mult)
	if mult then
		local actual_charge = CalcActualCharge(inst)
		if actual_charge and actual_charge >= mult then
			return true
		end
	elseif inst.charged then
        return true
    end
	return false, "NOT_ENOUGH_CHARGE"
end

local function CanBeUsedAsBattery(inst, user, mult)
	if mult then
		local actual_charge = CalcActualCharge(inst)
		if actual_charge and actual_charge >= mult then
			return true
		end
	elseif inst.charged then
        return true
    end
	return false, "NOT_ENOUGH_CHARGE"
end

local function UseAsBattery(inst, user, mult)
	if mult then
		local actual_charge = CalcActualCharge(inst)
		if actual_charge and actual_charge > mult then
			dozap(inst)
            inst.components.finiteuses:Use(10)
			inst.chargeleft = inst.chargeleft - mult
			return
		end
	end
	discharge(inst)
end

local function ResolvePartialChargeMult(inst, user, mult)
	local actual_charge = CalcActualCharge(inst)
end

-----------------------------------------
-- Tornado Spotter - Rainometer Only - Borrowed from postinits/prefabs/rainometer.lua, potentially can make it call the same source in a cleanup update.
-----------------------------------------

local function getrevealtargetpos_rainometer(inst, doer) -- This could be a commonfn
	local tornado = TheWorld:FindFirstEntityWithTag("um_tornado")

	if tornado == nil then
		return false, "MESSAGEBOTTLEMANAGER_NOT_FOUND"
	end
	
	local pos = tornado.Transform:GetPosition()
	local reason = "dunno lmao" -- AXE Why did you do this Scrimbles?
	
	return pos, reason
end

local function CheckForTornadoRevealers(inst) -- This could be a commonfn
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 2)
    
    for i, v in pairs(players) do
        if v ~= nil then
            if v.um_tornado_revealer_task ~= nil then
                v.um_tornado_revealer_task:Cancel()
            end
            
            v.um_tornado_revealer_task = nil
            
            v.um_tornado_revealer_task = v:DoTaskInTime(2, function()
                v:RemoveTag("um_tornadotracker")
            end)
            
            v:AddTag("um_tornadotracker")
        end
    end
end

local function OnActivateRainometer(inst, doer) -- This could be a commonfn
	CheckForTornadoRevealers(inst)
	local tornado = TheSim:FindFirstEntityWithTag("um_tornado")
	
	if tornado ~= nil and doer ~= nil and doer.player_classified ~= nil then
		local x, y, z = tornado.Transform:GetWorldPosition()
	
		doer.player_classified.revealmapspot_worldx:set(x)
		doer.player_classified.revealmapspot_worldz:set(z)
		doer.player_classified.revealmapspotevent:push()
        inst.components.finiteuses:Use(10)
	else
		if doer ~= nil and doer.components.talker ~= nil then
			doer.components.talker:Say(GetString(doer, "ANNOUNCE_UM_NO_TORNADO"))
		end
	end

    inst.components.activatable.inactive = true
end
-----------------------------------------
-- Lucky - Only used by Golden Acorn
-----------------------------------------
local acorn_luck = 0.06
local function GetLuckFn(inst, owner)
    return acorn_luck
end

-- Putting sparkling function in here too - from Atoba
local function Shine(inst)
    if not inst:HasTag("INLIMBO") and not inst:IsAsleep() then
        local fx = SpawnPrefab("crab_king_shine")
        fx.Transform:SetScale(0.25, 0.25, 0.25)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "symbol0", 0, 0, 0)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, Shine)
end

local function OnEntityWakeShine(inst)
    if inst.shinetask == nil then
        inst.shinetask = inst:DoTaskInTime(4 + math.random() * 5, Shine)
    end
end

-----------------------------------------
-- Healer - Only used by Blood Bag
-----------------------------------------
local function SetHealingAmounts(inst)
    if inst.components.activatable then
        inst:RemoveComponent("activatable")
    end
    inst.AnimState:PlayAnimation("full")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."bloodbag.xml"
    inst.components.inventoryitem:ChangeImageName(rl_name.."bloodbag_b")
    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(inst.blood) -- AXE inst.blood is always defined when this is called.
    inst.components.healer:SetOnHealFn(function(inst) inst:Remove() end)
end

-----------------------------------------
-- activatable - Only used by Blood Bag
-----------------------------------------
local function OnBloodbagUse(inst,owner)
    if owner and owner.components.health and not owner.components.health:IsDead() then
        local blood_drive = 100
        if owner.components.health.currenthealth < blood_drive then
            blood_drive = owner.components.health.currenthealth - 1
        end
        owner.components.health:DoDelta(-blood_drive)
        inst.blood = blood_drive
        inst:DoTaskInTime(0,SetHealingAmounts)
    end
end

local function NewCanInteract(self,doer)
    local inventoryitem = self.inst.components.inventoryitem 
    return inventoryitem and inventoryitem:IsHeld()
end
-----------------------------------------
-- Dropping and Picking Up
-----------------------------------------


-- Rainometer
local function RainometerDrop(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    -- Lightningrod
    inst:AddTag("lightningrod")
    inst:ListenForEvent("lightningstrike", onlightning)

    -- Vanilla Rainometer
    if not inst.task then
        inst.task = inst:DoPeriodicTask(5,RainAnimFn)
    end

    -- UM Tornado Checker
	inst:AddComponent("mapspotrevealer")
	inst.components.mapspotrevealer:SetGetTargetFn(getrevealtargetpos_rainometer)

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivateRainometer
    inst.components.activatable.inactive = true
	inst.components.activatable.quickaction = true

    inst:DoTaskInTime(0,function(inst)
        inst.Transform:SetPosition(x,y,z)
    end)
end

local function RainometerPickup(inst)
    -- Lightningrod - but keep the glowing effect in the inventory of the player, if possible. As well as being the battery bank
    inst:RemoveEventCallback("lightningstrike", onlightning)
    inst:RemoveTag("lightningrod")

    -- Vanilla Rainometer
    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end

    -- UM Tornado Checker
    if inst.components.activatable then
        inst:RemoveComponent("activatable")
    end
    if inst.components.mapspotrevealer then
        inst:RemoveComponent("mapspotrevealer")
    end
end

-- Researchlabs
local function ResearchlabDrop(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    inst.Transform:SetScale(0.7,0.7,0.7)
    local techtree = inst.prefab == rl_name.."researchlab1" and TUNING.PROTOTYPER_TREES.SCIENCEMACHINE or TUNING.PROTOTYPER_TREES.ALCHEMYMACHINE
    inst:AddTag("giftmachine")
    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnonPrototyper -- AXE Gave them more distinct names so no conflicts occur later if this file is added to.
    inst.components.prototyper.onturnoff = onturnoffPrototyper
    inst.components.prototyper.trees = techtree
    inst.components.prototyper.onactivate = onactivatePrototyper

    inst:AddComponent("wardrobe")
    inst.components.wardrobe:SetCanUseAction(false) --also means NO wardrobe tag!
    inst.components.wardrobe:SetCanBeShared(true)
    inst.components.wardrobe:SetRange(TUNING.RESEARCH_MACHINE_DIST + .1)

    inst:ListenForEvent("ms_addgiftreceiver", refreshonstate)
    inst:ListenForEvent("ms_removegiftreceiver", refreshonstate)
    inst:ListenForEvent("ms_giftopened", ongiftopened)

    inst._activecount = 0
    inst._activetask = nil

    inst:DoTaskInTime(0,function(inst)
        inst.Transform:SetPosition(x,y,z)
    end)
end

local function ResearchlabPickup(inst)
    inst:RemoveTag("giftmachine")
    if inst.components.prototyper then
        inst:RemoveComponent("prototyper")
    end

    if inst.components.wardrobe then
        inst:RemoveComponent("wardrobe")
    end

    inst:RemoveEventCallback("ms_addgiftreceiver", refreshonstate)
    inst:RemoveEventCallback("ms_removegiftreceiver", refreshonstate)
    inst:RemoveEventCallback("ms_giftopened", ongiftopened)

    inst._activecount = nil
    inst._activetask = nil
end



-----------------------------------------
-- Save/Load FNs
-----------------------------------------
local function OnSave(inst, data)
    local data = {}
    -- Rainometer loading (its lightningrod attachment)
    if inst.charged then
        data.charged = inst.charged
        data.chargeleft = inst.chargeleft
    end
    if inst.blood then
        data.blood = inst.blood
    end

    return data
end
local function OnLoad(inst, data)
    if data then
        -- Rainometer loading
        if data ~= nil and data.charged and data.chargeleft ~= nil and data.chargeleft > 0 then
            setcharged(inst, data.chargeleft)
        end
        if data and data.blood then
            inst.blood = data.blood
            SetHealingAmounts(inst)
        end
    end
end


local function InitCommon(inst)
    if not inst.components.inventoryitem:IsHeld() then
        inst.components.inventoryitem:OnDropped() -- Run dropped code if it started on the ground
    end
end

local function RLCommon(type,is_workable,has_finiteuses,is_burnable)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if type == "rainometer" then
        inst.entity:AddLight()
        inst.Light:Enable(false)
        inst.Light:SetRadius(1.5)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.5)
        inst.Light:SetColour(235/255,121/255,12/255)
    end
    
    local startanim = "idle" -- AXE Just a set of if-statements for ones that may not have an animation named "idle"
    if type == "thermometer" or type == "rainometer" then
        startanim = "med"
    elseif type == "bloodbag" then
        startanim = "empty"
    end

    inst.AnimState:SetBank(rl_name..type)
    inst.AnimState:SetBuild(rl_name..type)
    inst.AnimState:PlayAnimation(startanim)
    
    if type == "goldacorn" then
        inst:AddTag("luckyitem")
    end

    if type == "garlicbraid" then
        inst:AddTag("show_spoilage")
        inst:AddTag("icebox_valid")
    end
    
    if type == "preservecan_full" then
        inst:AddTag("bundle")
        --unwrappable (from unwrappable component) added to pristine state for optimization
        inst:AddTag("unwrappable")
        inst:AddTag("canpeek")
    end

    if type == "preservecan_full" or type == "preservecan_empty" then
        inst.pickupsound = "metal"
    end

    if type == "mrnoisy" then
        inst:AddTag("allow_action_on_impassable")
        MakeInventoryFloatable(inst, "med", 0.2, {1.5,1,1.5})

        -- Noisy has special physics
        inst.Physics:SetMass(1)
        inst.Physics:SetCapsule(0.2, 0.2)
        inst.Physics:SetFriction(0.5)
        inst.Physics:SetDamping(0.5)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
        inst.Physics:SetCollisionMask(
            COLLISION.GROUND,
            COLLISION.OBSTACLES,
            COLLISION.ITEMS,
            COLLISION.WORLD
        )
    else -- Conveniently - all other inventory items need no tuning on floatable (probably)
        MakeInventoryFloatable(inst)
    end


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inventoryitem")

    
    -- Make special dropped Fns
    local DroppedFn = function(inst) end -- dummy function
    local PickupFn = function(inst) end -- dummy function
    if type == "rainometer" then
        DroppedFn = RainometerDrop
        PickupFn = RainometerPickup
    elseif type == "thermometer" then
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."thermometer.xml"
        ThermAnimFn(inst)
        inst.task = inst:DoPeriodicTask(1, ThermAnimFn)
        --DroppedFn = ThermometerDrop
        --PickupFn = ThermometerPickup
        inst.Transform:SetScale(0.75,0.75,0.75)
    elseif type == "researchlab1" or type == "researchlab2" then
        DroppedFn = ResearchlabDrop
        PickupFn = ResearchlabPickup
    elseif type == "bones" then
        DroppedFn = BonesSleeps
        PickupFn = BonesAwakens
    elseif type == "bones" then
        DroppedFn = CheckCanAnim  
    elseif type == "mrnoisy" then
        PickupFn = PickupNoisy
    end
    inst.components.inventoryitem:SetOnDroppedFn(DroppedFn)
    inst.components.inventoryitem:SetOnPutInInventoryFn(PickupFn)


    if has_finiteuses then
        inst:AddComponent("finiteuses")
        local uses = 100 -- For now set to 100, may set to different numbers later.
        if type == "researchlab1" or type == "researchlab2" then
            uses = 5
        end
        inst.components.finiteuses:SetMaxUses(uses)
        inst.components.finiteuses:SetUses(uses)
        inst.components.finiteuses:SetOnFinished(OnCommonHammered)
    end


    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 3 -- AXE by default PK will take all of them for 3 gold.

    -----------------------------------
    inst:AddComponent("inspectable")

    if is_burnable then
        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    end

    if is_workable then    
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(OnCommonHammered)
        if type == "petrifier" then
            inst.Transform:SetScale(0.7,0.7,0.7)
            inst.components.workable:SetOnFinishCallback(OnPetriHammered)
            inst.components.workable:SetWorkLeft(1)
        end
        if type == "garlicbraid" then
            inst.components.workable:SetWorkLeft(1)
        end
        local WorkCallback
        if type == "rainometer" then
            WorkCallback = OnRainHit
        elseif type == "thermometer" then
            WorkCallback = OnTempHit
        elseif type == "researchlab1" or type == "researchlab2" then
            WorkCallback = OnProtoHit
        end
        inst.components.workable:SetOnWorkCallback(WorkCallback)
    end
    if type == "rainometer" then
        inst:AddComponent("battery")
        inst.components.battery:SetCanBeUsedFn(CanBeUsedAsBattery)
        inst.components.battery:SetOnUsedFn(UseAsBattery)
        inst.components.battery:SetResolvePartialChargeMultFn(ResolvePartialChargeMult)

        inst.Transform:SetScale(0.75,0.75,0.75)
    end

    if type == "bloodbag" then
        inst:AddComponent("activatable")
        inst.components.activatable.OnActivate = OnBloodbagUse
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."bloodbag.xml"
        inst.components.inventoryitem:ChangeImageName(rl_name.."bloodbag_a")

        inst.Transform:SetScale(0.65,0.65,0.65)
    end

    if type == "goldacorn" then
        inst:AddComponent("luckitem")
        inst.components.luckitem:SetLuck(GetLuckFn)
        inst.OnEntityWake = OnEntityWakeShine
    end

    if type == "goldacorn" or type == "rimeseed" then
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst.Transform:SetScale(0.9,0.9,0.9)
    end

    if type == "rimeseed" then
        inst:AddComponent("deployable")
        inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable.ondeploy = on_deploy_rime
    end

    if type == "garlicbraid" then
        inst:ListenForEvent("entitywake",GarlicAwakens)
        inst:ListenForEvent("entitysleep",GarlicSleeps)
        inst.um_pocket_sanity_res = 0.4
        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
        inst.components.perishable:StartPerishing()
        inst.components.perishable.onperishreplacement = "spoiled_food"

        inst.Transform:SetScale(0.65,0.65,0.65)
    end
 
    if type == "preservecan_empty" then
        inst.components.inventoryitem.cangoincontainer = true

        inst:AddComponent("stackable")

        inst:AddComponent("bundlemaker")
        inst.components.bundlemaker:SetBundlingPrefabs(rl_name.."preservecan_container", rl_name.."preservecan_full")
        inst.components.bundlemaker:SetOnStartBundlingFn(OnStartBundling)

        inst.AnimState:SetBank(rl_name.."preservecan")
        inst.AnimState:SetBuild(rl_name.."preservecan")
        inst.AnimState:PlayAnimation("empty")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."preservecan.xml"
        inst.components.inventoryitem:ChangeImageName(rl_name.."preservecan_a")
    end

    if type == "preservecan_full" then
        inst.components.inventoryitem.cangoincontainer = true

        inst:AddComponent("unwrappable")
        inst.components.unwrappable:SetOnWrappedFn(CloseCan)
        inst.components.unwrappable:SetOnUnwrappedFn(OnUnwrapped)
        inst.components.unwrappable:SetPeekContainer(rl_name.."preservecan_container")

        inst.AnimState:SetBank(rl_name.."preservecan")
        inst.AnimState:SetBuild(rl_name.."preservecan")
        inst.AnimState:PlayAnimation("full")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."preservecan.xml"
        inst.components.inventoryitem:ChangeImageName(rl_name.."preservecan_b")

        inst.um_refreshing = true -- Unwrappable postinit looks for this
    end
    
    if type == "multitool" then
        inst.components.inventoryitem.cangoincontainer = true
        
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(40*TUNING.TOTAL_DAY_TIME)
        inst.components.fueled:SetDepletedFn(CheckIfHoldingThenDrop) -- Works for both the can and the budget toolbox

        inst:AddComponent("container")
        inst.components.container.onclosefn = CloseTool
        inst.components.container.onopenfn = OpenTool
        inst.components.container:WidgetSetup(rl_name.."multitool")
        --inst.components.container.skipclosesnd = true
        --inst.components.container.skipopensnd = true

        --inst:ListenForEvent("container_got_item_while_closed",CheckCanAnim)
        -- this does not work, but it would be nice to be able to check to see if it received an item while it's closed so that it may update its inv icon and anim

        inst.AnimState:PlayAnimation("empty")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..rl_name.."multitool.xml"
        inst.components.inventoryitem:ChangeImageName(rl_name.."multitool_a")

        inst:DoTaskInTime(0,CloseTool) -- Run code to check to see if I've got something in me.

    end

    if type == "mrnoisy" then
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(1*TUNING.TOTAL_DAY_TIME)
        inst.components.fueled:SetDepletedFn(Detonate)
        inst.components.fueled:StopConsuming()

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequipnoisy)
        inst.components.equippable:SetOnUnequip(onunequipnoisy)
        inst.Transform:SetScale(0.95,0.95,0.95)

        inst:AddComponent("complexprojectile")
        inst.components.complexprojectile:SetHorizontalSpeed(25)
        inst.components.complexprojectile:SetGravity(-35)
        inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
        inst.components.complexprojectile:SetOnLaunch(onthrown_noisy)
        inst.components.complexprojectile:SetOnHit(BecomeNoisy)


        -- health has to only be a component when it's thrown.
        inst:AddComponent("combat")
        inst:ListenForEvent("attacked", NoisyAttacked)
        inst:ListenForEvent("death",Detonate)
        inst:AddTag("soulless")
    end

    inst.OnSave = OnSave
    inst.Onload = OnLoad

    MakeHauntableLaunch(inst)

    inst:DoTaskInTime(0,InitCommon)



    MakeSmallPropagator(inst)

    return inst
end


local function fnpreservecan_container()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("bundle")

    --V2C: blank string for controller action prompt
    inst.name = " "

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup(rl_name.."preservecan_container")

    inst.persists = false

    return inst
end

local function RL(type,is_workable,has_finiteuses,is_burnable)
    return function()
        return RLCommon(type,is_workable,has_finiteuses,is_burnable)
    end
end

-- RL - Rubble Loot
return Prefab(rl_name.."rainometer", RL("rainometer",true,true,true), assets),
Prefab(rl_name.."thermometer", RL("thermometer",true,true,true), assets),
Prefab(rl_name.."researchlab1", RL("researchlab1",true,true,true), assets),
Prefab(rl_name.."researchlab2", RL("researchlab2",true,true,true), assets),
Prefab(rl_name.."bloodbag", RL("bloodbag"), assets),
Prefab(rl_name.."goldacorn", RL("goldacorn"), assets),
Prefab(rl_name.."petrifier", RL("petrifier",true), assets),
Prefab(rl_name.."garlicbraid", RL("garlicbraid",true,false,true), assets),
Prefab(rl_name.."bones", RL("bones",true,false,true), assets),
Prefab(rl_name.."rimeseed", RL("rimeseed"), assets),
MakePlacer(rl_name.."rimeseed_placer", "um_rimeweed", "um_rimeweed", "flower_1_idle"),
Prefab(rl_name.."preservecan_empty", RL("preservecan_empty"), assets),
Prefab(rl_name.."preservecan_full", RL("preservecan_full"), assets),
Prefab(rl_name.."preservecan_container", fnpreservecan_container, assets),
Prefab(rl_name.."multitool", RL("multitool"), assets),
--Prefab(rl_name.."pocketforge", RL("pocketforge"), assets), -- the pocket forge is located in um_gemologyforge.lua since it needs several local functions from there
Prefab(rl_name.."mrnoisy", RL("mrnoisy"), assets)

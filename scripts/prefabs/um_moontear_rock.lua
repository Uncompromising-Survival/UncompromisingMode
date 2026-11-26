local assets =
{
    Asset("ANIM", "anim/um_moontear_rock.zip"),
    Asset("ANIM", "anim/um_moontear_pillar.zip"),
    Asset("IMAGE", "images/map_icons/moonpillar_icon.tex"),
    Asset("ATLAS", "images/map_icons/moonpillar_icon.xml"),
}

local loot_break = {"moonrocknugget","moonrocknugget","moonglass","moonglass","moonglass"}
local himalaya_endtime = 140
local himalaya_warntime = himalaya_endtime - 20 -- This determines when the characters will comment about the event that's about to end...

local function CalcSanityAura(inst)
    if inst.prefab == "um_moontear_core_base" then
        return not inst.lost_the_tear and TUNING.SANITYAURA_SUPERHUGE or 0
    end
    if inst.prefab == "um_moontear_rock" then
        return inst.is_malding and TUNING.SANITYAURA_SUPERHUGE or 0
    end
end

local function onsave(inst, data)
    data.variant = inst.variant
end

local function onload(inst, data)
    if data and data.variant then
        inst.variant = data.variant
    end
end

local rockname = "moonglass_rock"

local function RecoilFnRock(inst, worker, tool, numworks)
    local tool = worker ~= nil and worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local can_work = tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork() or nil
    if not can_work then -- The tool isn't hard working
        return true
    end
    if inst.is_malding then -- The event hasn't started yet
        return false
    end
    return true -- We can go. to. work.
end

local function RockAnimation(inst,suffix,loop,push,preserve_position)
    local workable = inst.components.workable
    local workleft = inst.components.workable.workleft
    local maxwork = inst.components.workable.maxwork
    local prefix = "full"
    if workleft < maxwork/2 and workleft > 0 then
        prefix = "med"
    elseif workleft <= 0 then
        prefix = "empty"
    end
    local time
    if preserve_position then
        time = inst.AnimState:GetCurrentAnimationTime()
    end
    --TheNet:Announce(rockname..inst.variant.."_"..prefix..suffix)
    if push then
        inst.AnimState:PushAnimation(rockname..inst.variant.."_"..prefix..suffix,loop)
    else
        inst.AnimState:PlayAnimation(rockname..inst.variant.."_"..prefix..suffix,loop)
    end
    if preserve_position then
        inst.AnimState:SetFrame(time)
    end
end

local LINK_FX_SPAWNER_STEPDIST = 3
local function ShowLink(inst,newpos_x,newpos_z)
    local core = inst.core
    local x, y, z = inst.Transform:GetWorldPosition()
    local xc,yc,zc = core.Transform:GetWorldPosition()
    if newpos_x then
        x = newpos_x
        z = newpos_z
    end
    local len = VecUtil_Length(xc - x, zc - z)
    if len > 2 then
        local dir_x, dir_z = VecUtil_Normalize(xc - x, zc - z)

        local newpos_x, newpos_z = x + dir_x * LINK_FX_SPAWNER_STEPDIST, z + dir_z * LINK_FX_SPAWNER_STEPDIST
        SpawnPrefab("moon_altar_link_fx").Transform:SetPosition(newpos_x, 0, newpos_z)
        ShowLink(inst,newpos_x,newpos_z)
    end
end

local function Seethe(inst) -- Stop Playing Shielding animations
    inst.is_malding = nil
    RockAnimation(inst,"pst",false,false)
    RockAnimation(inst,"idle",true,true)
    if inst.link_task then
        inst.link_task:Cancel()
        inst.link_task = nil
    end

    if inst.linking_fx then
        inst.linking_fx:Remove()
    end

end

local function Mald(inst) -- Begin playing shielding animations
    inst.is_malding = true
    RockAnimation(inst,"pre",false,false)
    RockAnimation(inst,"loop",true,true)

    inst.link_task = inst:DoPeriodicTask(1.2,ShowLink)
end

local function OnWorkRock(inst,worker,workleft,numworks)
    local tool = worker ~= nil and worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local can_work = tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork() or nil

    if can_work then
        local fx = SpawnPrefab("mining_moonglass_fx")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.entity:SetParent(inst.entity)
        if inst.is_malding then
            
            if inst.core then
                local fx_core = SpawnPrefab("mining_moonglass_fx")
                fx_core.Transform:SetPosition(inst.core.Transform:GetWorldPosition())
                fx_core.entity:SetParent(inst.core.entity)
            end
            if workleft <= 0 then
                Seethe(inst)
                inst.components.lootdropper:DropLoot()
                inst.broken = true
                if inst.core then
                    inst.core.CheckRocks(inst.core)
                end
            else
                RockAnimation(inst,"loop",true,false,true) -- Need to update it such that it stays the same
            end
        else
            worker:PushEvent("himalaya_dormant", { workaction = ACTIONS.MINE })
        end
    else
        worker:PushEvent("tooltooweak", { workaction = ACTIONS.MINE })
    end
end

local size_xz = {500,320,450}
local size_y = {300,200,250}
local function InitRock(inst)
    if not inst.variant then
        inst.variant = math.random(0,2)
    end
    if not inst.components.umripples then
        inst:AddComponent("umripples")
    end
    inst.components.umripples._resize_target:set({size_xz[inst.variant+1], size_y[inst.variant+1], size_xz[inst.variant+1]})
    RockAnimation(inst,"idle",true,false)  
end

local function rock()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("moonpillar_icon.tex")

    inst.AnimState:SetBank("um_moontear_rock")
    inst.AnimState:SetBuild("um_moontear_rock")

    inst:AddTag("boulder")
    inst:AddTag("moonglass")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- NOTE(DiogoW): Only use dependencies generated by lootdropper.
    inst.scrapbook_deps = {}

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot_break)
    inst.components.lootdropper.min_speed = 4.0
    inst.components.lootdropper.max_speed = 6.0
    inst.components.lootdropper.y_speed = 14
    inst.components.lootdropper.y_speed_variance = 2

    local workable = inst:AddComponent("workable")
    local work = 20
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(work) -- Set a tuning value later.
    workable:SetOnWorkCallback(OnWorkRock)
    workable:SetShouldRecoilFn(RecoilFnRock)
    workable:SetMaxWork(work)
    inst:DoTaskInTime(0,InitRock)

    inst:AddComponent("inspectable")

    inst.OnSave = onsave
    inst.OnLoad = onload

    inst.Mald = Mald
    inst.Seethe = Seethe

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    return inst
end

local function RecoilFnCore(inst, worker, tool, numworks)
    local tool = worker ~= nil and worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local can_work = tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork() or nil
    if not can_work then
        return true
    end
    if inst.shielded then  
        return true
    end
end

local function CoreAnimation(inst,suffix,loop,push)
    local workable = inst.components.workable
    local workleft = inst.components.workable.workleft
    local maxwork = inst.components.workable.maxwork
    local prefix = "full"
    if workleft < maxwork/2 and workleft > 0 then
        prefix = "med"
    elseif workleft <= 0 then
        prefix = "empty"
    end
    --TheNet:Announce("pillar_"..prefix..suffix)
    if push then
        inst.AnimState:PushAnimation("pillar_"..prefix..suffix,loop)
    else
        inst.AnimState:PlayAnimation("pillar_"..prefix..suffix,loop)
    end
end

local function PutCoreShieldDown(inst)
    inst.shielded = nil
    CoreAnimation(inst,"pst",false,false)
    CoreAnimation(inst,"idle",true,true)
end

local function PutCoreShieldUp(inst)
    inst.shielded = true
    CoreAnimation(inst,"pre",false,false)
    CoreAnimation(inst,"loop",true,true)
end

local function noentcheckfn(pt)
    local entities = TheSim:FindEntities(pt.x,pt.y,pt.z,8,{"_health"})
    for i,v in ipairs(entities) do
        if v.um_moontear_projected and v:GetDistanceSqToPoint(pt) < 2^2 then
            return false
        end
    end
    return true
end

local function notentacles(pt)
    local entities = TheSim:FindEntities(pt.x,pt.y,pt.z,16,{"_health"})
    for i,v in ipairs(entities) do
        if v.um_moontear_projected and v.prefab == "um_tentacle_moon" then
            return false
        end
    end
    return true
end

-- Don't place projected enemies on top of each other, space them out a bit
local function PlaceCreature(inst,creature)
    local position = inst:GetPosition()
    local offset
    if creature.prefab == "um_tentacle_moon" then
        offset = FindWalkableOffset(position,math.random() * 2 * PI,12,36,false, true, notentacles)
    else
        offset = FindWalkableOffset(position,math.random() * 2 * PI,10,32,false, true, noentcheckfn)
    end
    if offset then
        creature.Transform:SetPosition(position.x + offset.x,0,position.z+offset.z)
        creature.AnimState:SetErosionParams(-0.5, -0.2, -1.0)
        creature.AnimState:SetMultColour(0.5,1,1,1)
        creature.persists = false
        local fx = SpawnPrefab("halloween_firepuff_cold_" .. math.random(3))
        fx.Transform:SetPosition(position.x + offset.x,0,position.z+offset.z)
    else
        creature:Remove()
    end
end

local possible_creatures = {"molebat","spider_moon","mushgnome","lightflier"}

local function CreatureFeature(inst,tier,worms)
    for i = 1,tier do
        local creature_name = possible_creatures[math.random(1,#possible_creatures)]
        local creature = SpawnPrefab(creature_name)
        creature.um_moontear_projected = true
        table.insert(inst.creature_features,creature)
        PlaceCreature(inst,creature)
    end


    for i = 1,(tier + 1) do
        local creature 
        if worms then
            creature = SpawnPrefab("shockworm")
        else
            creature = SpawnPrefab("um_tentacle_moon")
        end
        table.insert(inst.creature_features,creature)
        creature.um_moontear_projected = true
        PlaceCreature(inst,creature)
    end
end

local function RemoveCreatures(inst)
    if inst.creature_features and #inst.creature_features > 0 then
        for i,v in ipairs(inst.creature_features) do
            if v and v:IsValid() then
                v:Remove()
            end
        end
    end
    inst.creature_features = nil
    inst.creature_features = {}
end

local function StartOrRestartResettingTimer(inst)
    if inst.components.timer:TimerExists("reset_tear") then
        inst.components.timer:SetTimeLeft("reset_tear",himalaya_endtime)
    else
        inst.components.timer:StartTimer("reset_tear",himalaya_endtime)
    end 
    if inst.components.timer:TimerExists("warn_survivors") then
        inst.components.timer:SetTimeLeft("warn_survivors",himalaya_warntime)
    else
        inst.components.timer:StartTimer("warn_survivors",himalaya_warntime)
    end
end


local function PushMusic(inst, level)
    if ThePlayer ~= nil and ThePlayer:IsNear(inst, 48) then
        print("found the player")
        ThePlayer:PushEvent("triggeredevent", { name = "moonbase", level = level })
    end
end

local function OnMusicDirty(inst)
    --Dedicated server does not need to trigger music
    if not TheNet:IsDedicated() then
        if inst._musictask ~= nil then
            inst._musictask:Cancel()
        end
        inst._musictask = inst._music:value() > 0 and inst:DoPeriodicTask(1, PushMusic, 0, inst._music:value()) or nil
    end
end

local function StartMusic(inst, level)
    print("starting")
    
    if inst._music:value() ~= level then
        inst._music:set(level)
        OnMusicDirty(inst)
    end
end

local function StopMusic(inst)
    StartMusic(inst, 0)
end


-- Generate a shuffled list of evenly spaced points in the circle radius.
-- We factor in the inst position here because it's better than going to C++
-- for every spawn later.
local POINTS_ANGLEDIFF = PI/18

local RADIUS = 1.5 * math.sqrt(TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ) 
local function GeneratePoints(inst)
    local ix, _, iz = inst.Transform:GetWorldPosition()

    local timeleft = 10
    if inst.components.timer and inst.components.timer:GetTimeLeft("reset_tear") then
        timeleft = inst.components.timer:GetTimeLeft("reset_tear")
    end
    local RADIUS_timecoef = RADIUS * (timeleft+5)/himalaya_endtime
    local angle = 0
    while angle < TWOPI do
        local x = ix + RADIUS_timecoef * math.cos(angle)
        local z = iz + RADIUS_timecoef * math.sin(angle)
        table.insert(inst._points, {x, z})
        angle = angle + POINTS_ANGLEDIFF
    end

    shuffleArray(inst._points)
end

-- Spawn an FX at one of the circle points, regenerating them first if necessary.
local function spawn_fx(inst)
    if #inst._points <= 0 then
        GeneratePoints(inst)
    end

    local next_point = table.remove(inst._points)
    local x, z = next_point[1], next_point[2]

    local fx = SpawnPrefab("alterguardian_lasertrail")
    fx.Transform:SetPosition(x, 0, z)
end


local function TryActivateRonk(inst,worker,workleft,numworks)
    local maxwork = inst.components.workable.maxwork
    
    if not inst.circle_fx then
        inst.circle_fx = inst:DoPeriodicTask(3*FRAMES, spawn_fx)
    end

    local try_shield = false
    if not inst.tier1 then
        try_shield = true
        inst.tier1 = true
        if inst.pulse_fx then
            inst.pulse_fx:SetLevel(2)
        end
        CreatureFeature(inst,1,true)
        StartOrRestartResettingTimer(inst)
        StartMusic(inst, 1)
    elseif not inst.tier2 and workleft < (0.75 * maxwork) then
        try_shield = true
        inst.tier2 = true
        CreatureFeature(inst,2)
        StartOrRestartResettingTimer(inst)
        StartMusic(inst, 1)
        inst.components.lootdropper:DropLoot()
    elseif not inst.tier3 and workleft < (0.5 * maxwork) then
        if inst.pulse_fx then
            --inst.pulse_fx.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_level_up")
            inst.pulse_fx:SetLevel(3)
        end
        try_shield = true
        inst.tier3 = true
        CreatureFeature(inst,3,true)
        StartOrRestartResettingTimer(inst)
        StartMusic(inst, 2)
        inst.components.lootdropper:DropLoot()
    elseif not inst.tier4 and workleft < (0.25 * maxwork) then
        try_shield = true
        inst.tier4 = true
        CreatureFeature(inst,4)
        StartOrRestartResettingTimer(inst)
        StartMusic(inst, 2)
        inst.components.lootdropper:DropLoot()
    end

    if inst.anchors and #inst.anchors > 0 and try_shield then
        local should_shield = false

        local found_rock = false
        for i,v in ipairs(inst.anchors) do
            if v.components.workable:GetWorkLeft() > 0 and not v.broken and not found_rock then
                should_shield = true
                if not v.is_malding then -- "mald" is for when the rock is leaking lunar energy.
                    v.Mald(v)
                    found_rock = true
                end
            end
        end
        if should_shield then
            PutCoreShieldUp(inst)
        end
    end
end

local function OnWorkCore(inst,worker,workleft,numworks)
    TryActivateRonk(inst,worker,workleft,numworks)
    local tool = worker ~= nil and worker.components.inventory ~= nil and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    local can_work = tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork() or nil


    if can_work then
        local fx = SpawnPrefab("mining_moonglass_fx")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.entity:SetParent(inst.entity)
        if inst.shielded then
            worker:PushEvent("himalaya_shielded", { workaction = ACTIONS.MINE })
            worker:PushEventImmediate("recoil_off", { target = inst })
        else
            if workleft <= 0 then

                inst.SoundEmitter:PlaySound("grotto/common/archive_lockbox/use")

                -- Call twice for double loot.
                inst.components.lootdropper:DropLoot()
                inst.components.lootdropper:DropLoot()
                
                inst.lost_the_tear = true
                StopMusic(inst)
                RemoveCreatures(inst)
                if inst.pulse_fx then
                    inst.pulse_fx:Remove()
                    inst.pulse_fx = nil
                end
                if inst.circle_fx then
                    inst.circle_fx:Cancel()
                    inst.circle_fx = nil
                end
                inst.components.timer:StartTimer("regain_tear",TUNING.TOTAL_DAY_TIME * 15)
                if inst.components.timer:TimerExists("warn_survivors") then
                    inst.components.timer:StopTimer("warn_survivors")
                end
                if inst.components.timer:TimerExists("reset_tear") then
                    inst.components.timer:StopTimer("reset_tear")
                end
                inst.stalactite.DropTear(inst.stalactite)
            end
            CoreAnimation(inst,"idle",false,false)
        end
    else
        worker:PushEvent("tooltooweak", { workaction = ACTIONS.MINE })
    end
end

local function MakePulseFx(inst)
    inst.pulse_fx = SpawnPrefab("positronpulse")
    inst.pulse_fx:SetLevel(2)
    inst.pulse_fx.entity:SetParent(inst.stalactite.entity)

    if not inst.pulse_fx.Follower then
        inst.pulse_fx.entity:AddFollower()
    end
    local scale = 1.5
    inst.pulse_fx.Transform:SetScale(scale,scale,scale)
    inst.pulse_fx.Follower:FollowSymbol(inst.stalactite.GUID, "tear_frag", 0, 250, 0)
    inst.pulse_fx.SoundEmitter:KillAllSounds()
end

local function InitializeCore(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local rocks = TheSim:FindEntities(x,y,z,64,{"boulder"})
    for i,v in ipairs(rocks) do
        if v.prefab == "um_moontear_rock" then
            v.core = inst
            table.insert(inst.anchors,v)

            if inst.lost_the_tear then
                v.components.workable.workleft = 0 -- No more work till it regrows -- SetWorkLeft rounds it up to 1.
                v.components.workable.workable = false
                RockAnimation(v,"idle",true,false)
            end
        end
    end

    -- Spawn in Core FX above
    inst.stalactite = SpawnPrefab("um_moontear_core_stalactite")
    inst.stalactite.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.stalactite.base = inst
    if inst.lost_the_tear then
        inst.stalactite.AnimState:PlayAnimation("stalactite_tear_empty",true)
    else
        inst.stalactite.AnimState:PlayAnimation("stalactite_tear_idle",true)
    end

    if not inst.pulse_fx and not inst.lost_the_tear then
        MakePulseFx(inst)
    end
end

local function CheckRocks(inst)
    if inst.anchors and #inst.anchors > 0 and inst.shielded then
        local should_break_shield = true
        for i,v in ipairs(inst.anchors) do
            if not v.broken and v.is_malding then
                should_break_shield = false
            end
        end
        if should_break_shield then
            PutCoreShieldDown(inst)
        end
    end
end


local function onsavecore(inst, data)
    if data then
        if inst.lost_the_tear then
            data.lost_the_tear = inst.lost_the_tear
        end
    end
end

local function onloadcore(inst, data)
    if data and data.lost_the_tear then
        inst.lost_the_tear = data.lost_the_tear
        inst.components.workable.workleft = 0 -- SetWorkleft rounds up to 1
        inst.components.workable.workable = false
        CoreAnimation(inst,"idle",true,false)
    end
end

local function QueueResettingAnimation(inst,tier)
    local core = inst.prefab == "um_moontear_core_base"

    -- these Pre animations always play
    if core then
        CoreAnimation(inst,"pre",false,false)
    else
        RockAnimation(inst,"pre",false,false)
    end

    if inst.circle_fx then
        inst.circle_fx:Cancel()
        inst.circle_fx = nil
    end

    -- it may play a different series of animations depending on the work done
    if tier <= 0 then
        if core then
            inst.AnimState:PushAnimation("pillar_emptytomed",false)
            inst.AnimState:PushAnimation("pillar_medtofull",false)
            
        else
            inst.AnimState:PushAnimation(rockname..inst.variant.."_emptytomed",false)
            inst.AnimState:PushAnimation(rockname..inst.variant.."_medtofull",false)
        end
    elseif tier < 0.5 then
        if core then
            inst.AnimState:PushAnimation("pillar_medtofull",false)
        else
            inst.AnimState:PushAnimation(rockname..inst.variant.."_medtofull",false)
        end
    end

    inst.components.workable:SetWorkLeft(inst.components.workable.maxwork)
    -- These pst animations always play
    if core then
        CoreAnimation(inst,"pst",false,true)
        CoreAnimation(inst,"idle",false,true)
    else
        RockAnimation(inst,"pst",false,true)
        RockAnimation(inst,"idle",false,true)
    end
end


local function ResetTear(inst)
    RemoveCreatures(inst)
    StopMusic(inst)
    inst.tier1 = nil
    inst.tier2 = nil
    inst.tier3 = nil
    inst.tier4 = nil

    if inst.anchors then
        for i,v in ipairs(inst.anchors) do
            QueueResettingAnimation(v,v.components.workable.workleft/v.components.workable.maxwork)
            v.broken = nil
            --RockAnimation(v,"idle",true,false)
        end
    end
    QueueResettingAnimation(inst,inst.components.workable.workleft/inst.components.workable.maxwork)
    --CoreAnimation(inst,"idle",true,false)

    if inst.stalactite and inst.lost_the_tear then
        inst.stalactite.AnimState:PlayAnimation("stalactite_tear_idlepre",false)
        inst.stalactite.AnimState:PushAnimation("stalactite_tear_idle",true)
    end
    if not inst.pulse_fx then
        MakePulseFx(inst)
    else
        inst.pulse_fx:SetLevel(2)
    end
    inst.lost_the_tear = nil
end

local function WarnSurvivors(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x,y,z,64)
    for i,v in ipairs(players) do
        v:PushEvent("himalaya_resetting")
    end
end

local function TimerHandling(inst,data)
    if data then
        if data.name == "regain_tear" or data.name == "reset_tear" then
            ResetTear(inst)
        end
        if data.name == "warn_survivors" then
            WarnSurvivors(inst)
        end
    end
end

local function core()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.Light:SetRadius(20)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    MakeObstaclePhysics(inst, 3)
    
    inst:AddComponent("umripples")
    inst.components.umripples.xscale = 7
    inst.components.umripples.zscale = 7
    inst.components.umripples.yscale = 4
    inst.components.umripples.vert_offset = 0.4

    inst.MiniMapEntity:SetIcon("moontear_icon.tex")

    inst.AnimState:SetBank("um_moontear_glass")
    inst.AnimState:SetBuild("um_moontear_pillar")
    
    inst:AddTag("boulder")
    inst:AddTag("moonglass")
    inst:AddTag("moonbase")
    inst:AddTag("event_trigger")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("NPC_workable")

    inst._music = net_tinybyte(inst.GUID, "moonbase._music", "musicdirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("musicdirty", OnMusicDirty)
        return inst
    end

    -- NOTE(DiogoW): Only use dependencies generated by lootdropper.
    inst.scrapbook_deps = {}

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot_break)
    inst.components.lootdropper.min_speed = 4.0
    inst.components.lootdropper.max_speed = 6.0
    inst.components.lootdropper.y_speed = 14
    inst.components.lootdropper.y_speed_variance = 2

    local work = 45
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(work) -- Move to TUNING after merging... also probably could scale up with boss health.
    workable:SetMaxWork(work)
    workable:SetOnWorkCallback(OnWorkCore)
    workable:SetShouldRecoilFn(RecoilFnCore)

    CoreAnimation(inst,"idle",true,false)
    inst:AddComponent("inspectable")

    inst.anchors = {}
    inst.creature_features = {}
    inst._points = {} -- For the ring flame FX

    inst.OnSave = onsavecore
    inst.OnLoad = onloadcore
    inst:DoTaskInTime(0,InitializeCore)

    inst.PutCoreShieldUp = PutCoreShieldUp
    inst.CheckRocks = CheckRocks

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone",TimerHandling)
    -- Borrow the stafflight effect from a powered moon base
    --inst._staffstar = SpawnPrefab("staffcoldlightfx")
    --inst._staffstar.entity:SetParent(inst.entity)


    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura


    return inst
end

local function OnRestoreItemPhysics(item)
    item.Physics:CollidesWith(COLLISION.OBSTACLES)
end

local function DropTearItem(inst)
    local item = SpawnPrefab("moon_tear")
    local x, y, z = inst.Transform:GetWorldPosition()
    local spd = 3.5 + math.random() * (3.5)
	if bit.band(item.Physics:GetCollisionMask(), COLLISION.OBSTACLES) ~= 0 then
		item.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
		item:DoTaskInTime(0.6, OnRestoreItemPhysics)
	end
    item.Physics:Teleport(x, 8, z)
    local angle = math.random(1,360)
    item.Physics:SetVel(math.cos(angle) * spd, 11.5, math.sin(angle) * spd)
    item:PushEvent("knockbackdropped", { owner = inst, knocker = inst, delayinteraction = .75, delayplayerinteraction = .5 })

    inst.AnimState:PlayAnimation("stalactite_tear_empty",true)
    inst:RemoveEventCallback("animover",DropTearItem)
end

local function DropTear(inst)
    inst.AnimState:PlayAnimation("stalactite_tear_pst",false)
    inst:ListenForEvent("animover",DropTearItem)
end

local function core_stalactite()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_moontear_glass")
    inst.AnimState:SetBuild("um_moontear_pillar")
    

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- NOTE(DiogoW): Only use dependencies generated by lootdropper.
    inst.scrapbook_deps = {}
    inst:AddComponent("inspectable")

    inst:DoTaskInTime(0,function(inst)
        if not inst.base then
            TheNet:Announce("There cannot be a "..inst.prefab.." without its corresponding base.")
            inst:Remove()
        end
    end)
    inst.um_ripple_blacklist = true -- This prefab cannot have ripples and appears underground
    inst.persists = false

    inst.DropTear = DropTear
    
    return inst
end

local function StalactiteInit(inst)
    if not inst.variant then
        inst.variant = math.random(1,10)
    end
    inst.AnimState:PlayAnimation("stalactite"..inst.variant)
end

local function glass_stalactite()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("um_moontear_glass")
    inst.AnimState:SetBuild("um_moontear_pillar")
    inst.AnimState:PlayAnimation("pillar_fullloop",true)



    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -- NOTE(DiogoW): Only use dependencies generated by lootdropper.
    inst.scrapbook_deps = {}
    inst:AddComponent("inspectable")

    inst.um_ripple_blacklist = true -- This prefab cannot have ripples and appears underground
    inst:DoTaskInTime(0,StalactiteInit)
    
    inst.OnSave = onsave
    inst.OnLoad = onload
    return inst
end

return Prefab("um_moontear_rock",rock, assets),
Prefab("um_moontear_core_base",core, assets),
Prefab("um_moontear_core_stalactite",core_stalactite, assets),
Prefab("um_moontear_stalactite",glass_stalactite, assets)
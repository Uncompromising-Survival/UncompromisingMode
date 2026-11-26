local assets =
{
    Asset("ANIM", "anim/um_hooded_rubble_oldwall.zip"), -- Lidemo Rock
    Asset("ANIM", "anim/um_rubbleground.zip"), -- Deimos Mud
    Asset("ANIM", "anim/um_rubblerock.zip"), -- Deimos Rock
}


SetSharedLootTable("um_hooded_rubble1", -- A section of stone wall, nothing particularly interesting
{
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'rocks',      0.25},
    {'cutstone',   1.00},
    {'cutstone',   0.25},
    {'um_moss',      1.00},
    {'um_moss',      0.25},
})


SetSharedLootTable("um_hooded_rubble2", -- A section of stone wall, nothing particularly interesting
{
    {'rocks',      1.00},
    {'cutstone',   0.25},
    {'um_moss',   0.25},
})

SetSharedLootTable("um_hooded_rubble7", -- A strange-looking boulder
{
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'flint',      1.00},
    {'flint',      0.50},
})


SetSharedLootTable("um_hooded_rubble8", -- A boulder which has smashed some old structure
{
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'rocks',      1.00},
    {'boards',     1.00},
    {'transistor',      0.50},
})

SetSharedLootTable("um_hooded_rubble9", -- The canopeer's normal collection of garbage, has a pinch 'n winch and some scrap
{
    {'rope',      1.00},
    {'boards',      1.00},
    {'cutsone',      1.00},
    {'rocks',     1.00},
    {'rocks',     1.00},
    {'rocks',     1.00},
    {'wagpunk_bits', 1},
    {'wagpunk_bits', 0.50},
})

SetSharedLootTable("um_hooded_rubble10", -- The canopeer found a science machine
{
    {'log',      1.00},
    {'log',      1.00},
    {'log',      0.50},
    {'rocks',     1.00},
    {'rocks',     1.00},
    {'rocks',     0.50},
    {'goldnugget', 1.00},
    {'goldnugget', .50},
    {'wagpunk_bits', 1},
})

SetSharedLootTable("um_hooded_rubble11", -- The canopeer found an alchemy engine
{
    {'boards',      1.00},
    {'boards',      1.00},
    {'boards',      0.50},
    {'cutstone',     1.00},
    {'cutstone',     1.00},
    {'cutstone',     0.50},
    {'transistor', 1.00},
    {'transistor', .50},
    {'wagpunk_bits', 1},
    {'wagpunk_bits', 1},
    {'wagpunk_bits', 0.5},
})

local rlt = "um_rubbleloot_"
local rubbleloots = {"rainometer","thermometer","researchlab1","researchlab2","bloodbag","goldacorn","petrifier","garlicbraid",
    "bones","rimeseed","preservecan_empty","multitool","mrnoisy","pocketforge"}

local function RollRubbleLoot(inst,receiver)
    local chance = math.random()
    if chance < 0.2 or (inst.style and inst.style >= 9) then
        local loot = rlt..rubbleloots[math.random(1,#rubbleloots)]
        local item = SpawnPrefab(loot)
        if receiver then
            receiver.components.inventory:GiveItem(item,nil,inst:GetPosition())
        else
            inst.components.lootdropper:FlingItem(item)
        end
    end
end



-- Misc constants from junk_pile.lua and junk_pile_common.lua (Cannot use the same, we have modifications)
local RUMMAGE_SOUND_NAME = "rummage"
local START_PICKING_LOOT_TIME = 0.2
local NUM_VARIANCES = 3
local CRITTER_SPAWN_CHANCE = 0.1
local LOOT_PERISHABLE_PERCENT = 0.25

-- Anim Assembly
local rubble_anim_prefix_codex = {"","","mudtent_","mud1_","mud1_","mud2_"}
local rummage_anim_tier_codex_1 = {"big_","med_","small_"}
local rummage_anim_tier_codex_2 = {"big_","small_"}
local canopeer_codex = {"generic","science","alchemy"}

-- Workable/Pickable Assembly
local style_work_amount = {6,2} -- Lidemo Style work (hammering)
local style_pick_amount = {0,0,1,3,3,2} -- Deimos 1 Style work (Rummage - Combination of Pickable and Workable), note that canopeer loot is an exception and requires hammering


-- Modified version of loot table within junk_pile_common.lua: Note that "EMPTY" isn't a real prefab and will result in nothing
local LOOT = {
    CRITTERS = {
        { weight=4, prefab = "spider",targetplayer=true, state="warrior_attack", enabled_tuning = "SPIDERDEN_ENABLED" },
        { weight=1, prefab = "spider_trapdoor_hooded", targetplayer=true, state="warrior_attack"},
        { weight=2, prefab = "aphid",targetplayer=true, state="leap_attack"},
    },

    ITEMS1 = { -- Mud Tent
        { weight=10, prefab = "EMPTY"}, -- 20% for nothing
        { weight=10, prefab = "silk" }, -- 20% for silk
        { weight=10, prefab = "rocks"}, -- 20% for rocks
        { weight=10, prefab = "twigs"}, -- 20% for twigs
        { weight=10, prefab = "log"}, -- 20% for logs
    },
    ITEMS2 = { -- Large Muddy Pile
        { weight=60, prefab = "EMPTY"}, -- 30% for nothing
        { weight=20, prefab = "boards" }, -- 10% for boards
        { weight=70, prefab = "rocks"}, -- 30% for rocks
        { weight=40, prefab = "um_moss"}, -- 20% for moss
        { weight=10, prefab = "transistor"}, -- 5% for doodads
    },
    ITEMS3 = { -- Large Muddy Pile with lightning rod
        { weight=60, prefab = "EMPTY"}, -- 30% for nothing
        { weight=20, prefab = "boards" }, -- 10% for boards
        { weight=40, prefab = "rocks"}, -- 20% for rocks
        { weight=30, prefab = "goldnugget"}, -- 15% for gold
        { weight=30, prefab = "um_moss"}, -- 15% for moss
        { weight=20, prefab = "transistor"}, -- 10% for doodads
    },
    ITEMS4 = { -- Muddy pile with rocks, stone, metal
        { weight=50, prefab = "EMPTY"}, -- 25% for nothing
        { weight=10, prefab = "cutstone" }, -- 5% for cut stones
        { weight=40, prefab = "rocks"}, -- 20% for rocks
        { weight=40, prefab = "wagpunk_bits"}, -- 20% for scrap
        { weight=10, prefab = "boards"}, -- 5% for boards
        { weight=20, prefab = "log"}, -- 10% for logs
        { weight=20, prefab = "um_moss"}, -- 10% for moss
    },
}

local WEIGHTED_CRITTER_TABLE = {}
local WIT_1 = {}
local WIT_2 = {}
local WIT_3 = {}
local WIT_4 = {}

for _, critter in ipairs(LOOT.CRITTERS) do
    WEIGHTED_CRITTER_TABLE[critter] = critter.weight
end

for _, item in ipairs(LOOT.ITEMS1) do
    WIT_1[item] = item.weight
end

for _, item in ipairs(LOOT.ITEMS2) do
    WIT_2[item] = item.weight
end

for _, item in ipairs(LOOT.ITEMS3) do
    WIT_3[item] = item.weight
end

for _, item in ipairs(LOOT.ITEMS4) do
    WIT_4[item] = item.weight
end

local function SpawnRummageLoot(inst,digger) 
    -- Should a monster attack a player?
    if TryLuckRoll(digger, CRITTER_SPAWN_CHANCE, LuckFormulas.ChildSpawnerRareChild) then
        local choice = weighted_random_choice(WEIGHTED_CRITTER_TABLE)
        local enabled = choice.enabled_tuning and TUNING[choice.enabled_tuning]


        -- Check to see if spider tuning is enabled - this may be extended if future persons want to allow tuning of hooded widowers and such
        if (enabled == nil or enabled) and choice.prefab ~= nil and choice.prefab ~= "EMPTY" then
            local critter = SpawnPrefab(choice.prefab)
            local attackplayer = not (critter:HasTag("spider") and digger:HasOneOfTags("spiderwhisperer", "spiderdisguise"))
            inst.components.lootdropper:FlingItem(critter)
            if attackplayer and choice.targetplayer and critter.components.combat ~= nil then
                critter.components.combat:SetTarget(digger)
            end

            -- Would benefit from New FX
            SpawnPrefab("junk_break_fx").Transform:SetPosition(critter.Transform:GetWorldPosition())

            if choice.state ~= nil and (not choice.targetplayer or attackplayer) then
                critter.sg:GoToState(choice.state, digger)
            end
        end
    end

    local WIT -- Weighted Item Table
    local style = inst.style
    if style == 3 then
        WIT = WIT_1 
    elseif style == 4 then
        WIT = WIT_2
    elseif style == 5 then
        WIT = WIT_3
    elseif style == 6 then
        WIT = WIT_4
    end

    -- Item is always considered
    local choice = weighted_random_choice(WIT)
    if choice.prefab ~= nil and choice.prefab ~= "EMPTY" then
        local item = SpawnPrefab(choice.prefab)
        if item.components.perishable ~= nil then
            item.components.perishable:SetPercent(LOOT_PERISHABLE_PERCENT)
        end

        if item.components.stackable then -- Anywhere between 2 and 6 of stackable items
            item.components.stackable.stacksize = math.random(1,3)
        end

		if  digger.components.inventory and digger.components.inventory:IsOpenedBy(digger) then
            digger.components.inventory:GiveItem(item, nil, inst:GetPosition())
        else
            inst.components.lootdropper:FlingItem(item)
        end
    end
end


local function GetNewRummageRubbleAnim(inst,style,loop) -- This function stitches together the proper anim call
    local animname = rubble_anim_prefix_codex[style]
    local tier = math.max(1,inst.components.workable.workleft)
    if style == 3 then
        -- nothing
    elseif style == 4 or style == 5 then
        animname = animname..rummage_anim_tier_codex_1[3-tier+1]
    elseif style == 6 then
        animname = animname..rummage_anim_tier_codex_2[2-tier+1]
    end
    
    if loop then
        animname = animname.."loop"
    else
        animname = animname.."idle"
    end

    if style == 5 and tier ~= 3 then
        animname = animname.."_rod"
    end
    inst.AnimState:PlayAnimation(animname,loop and true or false)
end

local function UpdatePhysics(inst, workleft)
	local radius = workleft < 2 and 0.5 or 1
	if inst.Physics:GetRadius() ~= radius then
		inst.Physics:SetCapsule(radius, 2)
	end
end

local function Shake(inst, workleft, nosound)
    if inst._pickingloop then
        GetNewRummageRubbleAnim(inst,inst.style,true)
		--inst.AnimState:PlayAnimation("loop"..animlevel, true)
	else
        GetNewRummageRubbleAnim(inst,inst.style,false)
		--inst.AnimState:PlayAnimation("loop"..animlevel)
		--inst.AnimState:PushAnimation("idle"..animlevel, false)
	end

	if not nosound then
		inst.SoundEmitter:PlaySound("qol1/wagstaff_ruins/rummagepile_pst")
	end

	UpdatePhysics(inst, workleft)
end

local function SpawnLootForWorkedLevels(inst, worker, workleft, numwork)
	local new_level = math.ceil(workleft)
	local old_level = math.ceil(math.min(workleft + numwork, style_pick_amount[inst.style]))
	for i = new_level, old_level - 1 do
		SpawnRummageLoot(inst,worker)
	end
end

local function OnWorkRummage(inst, worker, workleft, numwork)
    Shake(inst,workleft)
    SpawnLootForWorkedLevels(inst, worker, workleft, numwork)
    if workleft <= 0 then
		SpawnPrefab("junk_break_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
        RollRubbleLoot(inst,worker)
        inst:Remove()
        return
    end
end


local function StopPickingLoot(inst, nosound)
    if inst._pickingtask ~= nil then
        inst._pickingtask:Cancel()
        inst._pickingtask = nil

        return -- Loop hadn't actually started yet.
    end
	inst._pickingloop = nil

    inst.SoundEmitter:KillSound(RUMMAGE_SOUND_NAME)
	if not nosound then
		inst.SoundEmitter:PlaySound("qol1/wagstaff_ruins/rummagepile_pst", nil, 0.3)
	end

    GetNewRummageRubbleAnim(inst,inst.style,false)
end

local function StartPickingLoot(inst)
    if inst._pickingtask ~= nil then
        inst._pickingtask:Cancel()
        inst._pickingtask = nil
    end
	inst._pickingloop = true

    local workleft = inst.components.workable:GetWorkLeft()

    inst.SoundEmitter:PlaySound(
        (workleft > 2 and "qol1/wagstaff_ruins/rummagepile_lrg") or 
        (workleft > 1 and "qol1/wagstaff_ruins/rummagepile_med") or
        (workleft >= 0 and "qol1/wagstaff_ruins/rummagepile_sml") ,
        RUMMAGE_SOUND_NAME
    )


    GetNewRummageRubbleAnim(inst,inst.style,true)
	--inst.AnimState:PlayAnimation("loop"..GetAnimLevel(inst, workleft), true)
end

local function OnStartPicking(inst, doer)
    if inst._pickingtask == nil then
        inst._pickingtask = inst:DoTaskInTime(START_PICKING_LOOT_TIME, StartPickingLoot)
    end

    inst._pickers = inst._pickers or {}

    if inst._pickers[doer] ~= nil then
        return
    end

    local pickingstate = doer.sg.currentstate.name

    local cb = function(doer, data)
        if not (data and data.statename == pickingstate) then
            inst:CancelPicking(doer)
        end
    end

    inst._pickers[doer] = cb

    inst:ListenForEvent("newstate", cb, doer)
    inst:ListenForEvent("onremove", cb, doer)
end

local function CancelPicking(inst, doer, nosound)
	local cb = inst._pickers and inst._pickers[doer] or nil
	if cb == nil then
		return
	end

    inst:RemoveEventCallback("newstate", cb, doer)
    inst:RemoveEventCallback("onremove", cb, doer)
    inst._pickers[doer] = nil

    if next(inst._pickers) == nil then
        inst._pickers = nil
		inst:StopPickingLoot(nosound)
    end
end

local function OnPickedFn(inst, digger)
    inst.components.workable:WorkedBy(digger, 1)
end

local function WorkMultiplierFn(inst, worker, numworks)
	return worker:HasTag("junk") and 0 or nil
end

local function SetPickableWork(inst,amount)
    inst:AddComponent("pickable")
    inst.components.pickable:SetUp(nil, 0)
    inst.components.pickable.onpickedfn = OnPickedFn
    inst.components.pickable.max_cycles  = amount
    inst.components.pickable.cycles_left = amount
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

    inst:AddComponent("workable")
    inst.components.workable.savestate = true
	inst.components.workable:SetWorkAction(nil)
    inst.components.workable:SetWorkLeft(amount)
	inst.components.workable:SetWorkMultiplierFn(WorkMultiplierFn)
    inst.components.workable:SetOnWorkCallback(OnWorkRummage)

    inst.StartPickingLoot = StartPickingLoot
    inst.StopPickingLoot  = StopPickingLoot
    inst.OnStartPicking = OnStartPicking
    inst.CancelPicking  = CancelPicking

    inst:ListenForEvent("startlongaction", inst.OnStartPicking)

end


local function OnHammeredOrMined(inst, worker)
    inst.components.lootdropper:DropLoot()
    RollRubbleLoot(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")
	inst:Remove()
end

local function OnHit(inst, worker, workLeft)
    --inst.AnimState:PlayAnimation("hit"..inst.style)
	--inst.AnimState:PushAnimation("idle"..inst.style, false)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    if inst.style >= 9 then
        inst.AnimState:PlayAnimation("canopeer"..canopeer_codex[inst.style-8].."_rubblehit") 
        inst.AnimState:PushAnimation("canopeer"..canopeer_codex[inst.style-8].."_rubbleidle") 
    end
end

local function SetHammerableWork(inst,amount)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(amount)
    inst.components.workable:SetMaxWork(amount)
    inst.components.workable:SetOnFinishCallback(OnHammeredOrMined)
    inst.components.workable:SetOnWorkCallback(OnHit)
end

local function OnMine(inst, worker, workLeft)
    inst.AnimState:PushAnimation("rock"..(inst.style-7).."_hit",false)  
	inst.AnimState:PushAnimation("rock"..(inst.style-7).."_idle",false)  
    local pt = inst:GetPosition()
    SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
end

local function SetMineableWork(inst)
    local rubble_mine_amount = 6
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(rubble_mine_amount)
    inst.components.workable:SetMaxWork(rubble_mine_amount)
    inst.components.workable:SetOnFinishCallback(OnHammeredOrMined)
    inst.components.workable:SetOnWorkCallback(OnMine)
end

local function SetWorkType(inst,style)
    if style <= 2 then
        SetHammerableWork(inst,style_work_amount[style])
    elseif style >= 3 and style <= 6 then
        SetPickableWork(inst,style_pick_amount[style])     
    elseif style >= 7 and style <= 8 then
        SetMineableWork(inst)
    elseif style >= 9 then -- Canopeer type
        SetHammerableWork(inst,style_work_amount[1]) -- Always 6
    end
end


local function SetAnimations(inst,style)
    if style == 1 or style == 2 then -- Big wall, small wall
        inst.AnimState:SetBank("um_hooded_rubble_oldwall")
        inst.AnimState:SetBuild("um_hooded_rubble_oldwall")
        inst.AnimState:PlayAnimation("idle"..inst.style)
    elseif style >= 3 and style <= 6 then -- Tent, Mud 1 (no rod) Mud 1 (rod), Mud 2
        inst.AnimState:SetBank("um_rubbleground")
        inst.AnimState:SetBuild("um_rubbleground")
        GetNewRummageRubbleAnim(inst,style,false)

        -- String for rummage has to be added via tag.
        inst:AddTag("pickable_rummage_str")
    elseif style >= 7 and style <= 8 then
        inst.AnimState:SetBank("um_rubblerock")
        inst.AnimState:SetBuild("um_rubblerock")  
        inst.AnimState:PlayAnimation("rock"..(inst.style-7).."_idle") -- the style is 7 numbers off for animation name
    elseif style >= 9 then -- Canopeer type
        inst.Transform:SetTwoFaced()
        inst.AnimState:SetBank("um_canopeer")
        inst.AnimState:SetBuild("um_canopeer") 
        inst.AnimState:PlayAnimation("canopeer"..canopeer_codex[inst.style-8].."_rubbleidle") 
    end
end

local function OnSave(inst)
    local data = {}
    data.style = inst.style
    data.revealed = inst.revealed
    return data
end

local function OnLoad(inst,data)
    if data then
        if data.style then
            inst.style = data.style
        end
        if data.revealed then
            inst.revealed = data.revealed
        end
    end
end

local function revealmapicon(inst)
    inst.MiniMapEntity:SetEnabled(true)
    inst.revealed = true
end

local function BaseRubble()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.2)

    inst:AddTag("structure")

    inst.MiniMapEntity:SetIcon("um_rubbleicon.tex")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:DoTaskInTime(0,function(inst) -- Do after initialization of "Style"
        if not inst.style then
            inst.style = math.random(1,8)
        end
        SetWorkType(inst,inst.style)
        SetAnimations(inst,inst.style)
        if inst.style == 1 or inst.style == 2 or inst.style >= 7 then
            inst.components.lootdropper:SetChanceLootTable("um_hooded_rubble"..inst.style)
        end
        if not inst.revealed then
            inst.MiniMapEntity:SetEnabled(false)
            inst.revealed = false
        end

        MakeHauntableWork(inst)
    end)


    inst.SetAnimations = SetAnimations -- for quick calling via canopeer, if it doesn't call, it blinks upon spawning

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6, 8) -- set specific values
    inst.components.playerprox:SetOnPlayerNear(revealmapicon)
    inst.components.playerprox:SetPlayerAliveMode(inst.components.playerprox.AliveModes.AliveOnly)   

    return inst
end

return Prefab("um_hooded_rubble", BaseRubble, assets)
    

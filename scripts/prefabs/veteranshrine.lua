local BigPopupDialogScreen = require "screens/popupdialog"

local assets =
{
    Asset("ANIM", "anim/veteranshrine.zip"),
}

--[[local prefabs =
{
}]]

--[[
local function makeactive(inst)
    inst.AnimState:PlayAnimation("off", true)
    inst.components.activatable.inactive = false
end

local function makeused(inst)
    inst.AnimState:PlayAnimation("flow_loop", true)
end
]]

local function GetVerb()
    return "TOUCH"
end

local function OnDoneTalking(inst)
    if inst.talktask then
        inst.talktask:Cancel()
        inst.talktask = nil
    end
    inst.SoundEmitter:KillSound("talk")
end

local function StartRagtime(inst)
    if not inst.ragtime_playing then
        inst.ragtime_playing = true
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/ragtime", "ragtime")
    else
        inst.SoundEmitter:SetVolume("ragtime", 1)
    end
end

local function ShutUpRagtime(inst)
    inst.SoundEmitter:SetVolume("ragtime", 0)
end

local function OnTalk(inst)
    OnDoneTalking(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/talk_LP", "talk")
    inst.talktask = inst:DoTaskInTime(2 + math.random() * .5, OnDoneTalking)
end

local function onnear(inst, target)
    if target then
        local quotes = target:HasTag("vetcurse") and STRINGS.UM_VETERANSHRINE.VETERANCURSED or STRINGS.UM_VETERANSHRINE.VETERANCURSETAUNT
        inst.components.talker:Say(quotes[math.random(1, #quotes)])
    end
    inst:DoTaskInTime(0, StartRagtime)
end

local function onfar(inst, target)
    inst:DoTaskInTime(0, ShutUpRagtime)
end

local function ToggleCurse(inst, doer)
    if doer.components.debuffable then
        if not doer.vetcurse then
            local sounds = {"common/teleportato/teleportato_maxwelllaugh", "sanity/creature2/taunt"}
            for _, sound in pairs(sounds) do
                doer.SoundEmitter:PlaySound("dontstarve/"..sound)
            end
            doer.components.debuffable:AddDebuff("buff_vetcurse", "buff_vetcurse")
            doer:PushEvent("foodbuffattached", {buff = "ANNOUNCE_ATTACH_BUFF_VETCURSE", 1})
            local x, y, z = inst.Transform:GetWorldPosition()
            local fxlist = {"statue_transition_2", "statue_transition"}
            for _, fx in pairs(fxlist) do
                local fx = _G.Prefabs[fx] and SpawnPrefab(fx)
                if fx then
                    fx.Transform:SetPosition(x, y, z)
                    fx.Transform:SetScale(1.2, 1.2, 1.2)
                end
            end
        end
    end
end

local function OnActivate(inst, doer)
    if not doer:HasTag("vetcurse_warning") then
        inst.valid_cursee_id = doer.userid
        inst.Cursee:set_local(doer)
        inst.Cursee:set(doer)
        if not doer:HasTag("vetcurse") then
            doer:AddTag("vetcurse_warning")
        end
    else
        if not doer:HasTag("vetcurse") then
            doer.sg:GoToState("curse_controlled")
            ToggleCurse(inst, doer)
        end
        doer:RemoveTag("vetcurse_warning")
    end
    inst.components.activatable.inactive = true
end

local function ToggleCursee(inst)
    local player = inst.Cursee:value()
    if player == ThePlayer then
        local function pop_screen()
            TheFrontEnd:PopScreen()
        end
        local title = STRINGS.VETS_TITLE
        local bodytext = STRINGS.VETS
        if player:HasTag("vetcurse") then
            title = STRINGS.VETS_CONFIRMED_TITLE
            bodytext = STRINGS.VETS_CONFIRMED
        end
        local bpds = BigPopupDialogScreen(title, bodytext, {{text = STRINGS.VETS_OK, cb = pop_screen}})
        bpds.title:SetPosition(0, 90, 0)
        bpds.text:SetPosition(0, -15, 0)

        TheFrontEnd:PushScreen(bpds)
    end
end

local function RegisterNetListeners(inst)
    inst:ListenForEvent("SetCurseedirty", ToggleCursee)
end

local function fn(Sim)
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.MiniMapEntity:SetIcon("veteranshrine_map.tex")

    inst.AnimState:SetBuild("veteranshrine")
    inst.AnimState:SetBank("veteranshrine")
    inst.AnimState:PlayAnimation("idle", true)

    --inst.GetActivateVerb = GetVerb
    
    inst.Cursee = net_entity(inst.GUID, "SetCursee.plyr", "SetCurseedirty")

    inst:DoTaskInTime(0, RegisterNetListeners)
    
    MakeObstaclePhysics(inst, 1.8)

    inst.entity:SetPristine()

    inst:AddComponent("talker")
    inst.components.talker.colour = Vector3(252/255, 226/255, 219/255)
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()
    inst.components.talker.lineduration = TUNING.HERMITCRAB.SPEAKTIME * 2 -0.5
    if LOC.GetTextScale() == 1 then
        inst.components.talker.fontsize = 30
    end
    inst.components.talker.font = TALKINGFONT_HERMIT
    inst:AddComponent("npc_talker")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = false
    --inst.components.activatable.standingaction = true

    inst:AddComponent("inspectable")
    inst.components.inspectable:RecordViews()

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(6, 10)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(onfar)

    --inst.deactivate = deactivate

    --inst.OnSave = onsave
    --inst.OnLoad = onload

    inst:ListenForEvent("ontalk", OnTalk)
    inst:ListenForEvent("donetalking", OnDoneTalking)

    return inst
end

return Prefab("veteranshrine", fn, assets)
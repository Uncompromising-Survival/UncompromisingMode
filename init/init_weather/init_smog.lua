local env = env
GLOBAL.setfenv(1, GLOBAL)

local function DoSmog(inst)
    if c_countprefabs("smog", true) <= 150 then
        local smog = SpawnPrefab("smog")
        local x, y, z = inst.Transform:GetWorldPosition()

        smog.Transform:SetPosition(x + math.random(-160, 160) / 10, math.random(0, 4), z + math.random(-160, 160) / 10)
    end
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        inst.smog_task = inst:DoTaskInTime(math.random(5, 15) / 10, DoSmog)
    end
end

env.AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function(inst) -- Maybe delaying this by a frame does something.
        if (inst:HasTag("plant") or inst:HasTag("tree")) and inst.components.burnable ~= nil then
            local _OnIgnite = inst.components.burnable.onignite

            inst.components.burnable.onignite = function(inst, source, doer, ...)
                if TheWorld.state.issummer then
                    inst.smog_task = inst:DoTaskInTime(math.random(5, 15) / 10, DoSmog)
                end

                if _OnIgnite ~= nil then
                    _OnIgnite(inst, source, doer, ...)
                end
            end
        end
    end)
end)

-- Coughing:

local COUGH_FADE_TASK_RATE = 0.1

local function FadeCoughSound(inst, steps, volumeMult)
    inst.um_coughVolume = inst.um_coughVolume - ((inst.hurtsoundvolume or 1) * volumeMult) / steps
    inst.SoundEmitter:SetVolume("um_smog_cough", inst.um_coughVolume)

    if inst.um_coughVolume <= 0 then
        inst.SoundEmitter:KillSound("um_smog_cough")
        if inst.um_fadeCoughTask ~= nil then inst.um_fadeCoughTask:Cancel() end
    end
end

local function DoCoughSound(inst, fadeSteps, volumeMult)
    inst.SoundEmitter:KillSound("um_smog_cough")
    if inst.um_fadeCoughTask ~= nil then inst.um_fadeCoughTask:Cancel() end

    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, "um_smog_cough", inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound(
            (inst.talker_path_override or "dontstarve/characters/") .. (inst.soundsname or inst.prefab) .. "/hurt",
            "um_smog_cough",
            inst.hurtsoundvolume)
    end

    inst.um_coughVolume = (inst.hurtsoundvolume or 1) * volumeMult
    inst.um_fadeCoughTask = inst:DoPeriodicTask(COUGH_FADE_TASK_RATE,
        function() FadeCoughSound(inst, fadeSteps, volumeMult) end)
end

local UM_SMOG_COUGH_STATE_TIME = 1.66666675

env.AddStategraphState("wilson", State {
    name = "um_smog_cough",
    tags = {"um_smog_cough"},

    onenter = function(inst, sayQuote)
        inst.sg.statemem.do_exit_cough = true
        inst.sg.mem.um_smog_cough = true
        inst.sg.mem.um_cough_cant_talk = true
        inst.AnimState:PlayAnimation("sing_pre")
        inst.AnimState:PushAnimation("sing_fail", false)

        -- Hide fx_icon in this state so Wigfrid's cough is consistent with other characters.
        inst.AnimState:HideSymbol("fx_icon")

        local talker = inst.components.talker
        if talker ~= nil and sayQuote ~= nil then
            talker:Say(GetString(inst, "GAS_DAMAGE"))
            inst.SoundEmitter:KillSound("talk")
        end
        inst.sg:SetTimeout(UM_SMOG_COUGH_STATE_TIME)
    end,

    timeline =
    {
        TimeEvent(11 * FRAMES, function(inst)
            DoCoughSound(inst, 5, 0.7)
            inst.sg.statemem.do_exit_cough = false
        end),

        TimeEvent(24 * FRAMES, function(inst)
            DoCoughSound(inst, 10, 0.8)
            inst.sg.mem.um_smog_cough = nil
            inst.sg.mem.queuetalk_timeout = nil
        end),
        TimeEvent(30 * FRAMES, function(inst)
            inst.sg.mem.um_cough_cant_talk = nil
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    onexit = function(inst)
        if inst.sg.statemem.do_exit_cough then DoCoughSound(inst, 5, 0.7) end
        inst.sg.statemem.do_exit_cough = false
        inst.sg.mem.um_cough_cant_talk = nil
        inst.AnimState:ShowSymbol("fx_icon")
    end
})

local CANT_COUGH_TAGS = {"um_smog_cough", "dead"}
local CANT_GO_TO_COUGH_STATE_TAGS = {"busy", "wereplayer"}
local CANT_GO_TO_COUGH_NONSTATE_TAGS = {"sleeping"}
for _, tag in pairs(CANT_COUGH_TAGS) do
    table.insert(CANT_GO_TO_COUGH_STATE_TAGS, 1, tag)
    table.insert(CANT_GO_TO_COUGH_NONSTATE_TAGS, 1, tag)
end

local function CantGoToCough(inst, tags)
    return inst:HasAnyTag(tags) or inst.sg and (type(tags) == "table" and inst.sg:HasAnyStateTag(unpack(tags)) or inst.sg:HasAnyStateTag(tags))
end

local function CoughEventFunction(inst, data)
    if inst.sg.mem.um_recent_smog_cough == true or CantGoToCough(inst, CANT_GO_TO_COUGH_NONSTATE_TAGS) or inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then return end
    inst.sg.mem.um_recent_smog_cough = true
    inst.sg.mem.um_cough_cant_talk = true
    local talker = inst.components.talker
    if data and data.talk and talker then
        talker:Say(GetString(inst, "GAS_DAMAGE"), nil, true)
        inst.SoundEmitter:KillSound("talk")
    end
    inst:DoTaskInTime(11 * FRAMES, function(inst) DoCoughSound(inst, 5, 0.7) end)
    inst:DoTaskInTime(24 * FRAMES, function(inst) DoCoughSound(inst, 10, 0.8) end)
    inst:DoTaskInTime(30 * FRAMES, function(inst) if inst.sg and inst.sg.mem then inst.sg.mem.um_cough_cant_talk = nil end end)
    inst:DoTaskInTime(UM_SMOG_COUGH_STATE_TIME, function(inst) if inst.sg and inst.sg.mem then inst.sg.mem.um_recent_smog_cough = nil end end)
end

env.AddStategraphPostInit("wilson", function(sg)
    local ontalkeventhandler = sg.events["ontalk"]
    local idlestate = sg.states["idle"]

    sg.events["um_smog_cough"] = EventHandler("um_smog_cough", function(inst, data)
        if inst.sg:HasStateTag("idle") and not (CantGoToCough(inst, CANT_GO_TO_COUGH_STATE_TAGS)) then
            inst.sg:GoToState("um_smog_cough", data and data.talk or nil)
            return
        end
        CoughEventFunction(inst, data)
    end)

    local oldontalkeventhandler_fn = ontalkeventhandler.fn
    ontalkeventhandler.fn = function(inst, data, ...)
        if inst.sg.mem.um_cough_cant_talk ~= nil then return end -- In the middle of hacking up some smog, give me a second.
        oldontalkeventhandler_fn(inst, data, ...)
    end

    local oldidlestate_onenter = idlestate.onenter
    idlestate.onenter = function(inst, pushanim, ...)
        local timeRemaining = inst.sg.mem.queuetalk_timeout ~= nil and inst.sg.mem.queuetalk_timeout - GetTime() or nil
        if inst.sg.mem.um_smog_cough == nil or timeRemaining == nil or timeRemaining <= 1 then
            oldidlestate_onenter(inst, pushanim, ...)
            inst.sg.mem.um_smog_cough = nil
            return
        end
        inst:PushEvent("um_smog_cough")
        inst.sg.mem.queuetalk_timeout = nil
    end
end)

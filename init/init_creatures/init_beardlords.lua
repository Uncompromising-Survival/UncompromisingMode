local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local UpvalueHacker = require("tools/upvaluehacker")

_G.UM_BEARDLORDS = {}
UM_BEARDLORDS.AnimStates = {}

local _PlayAnimation = AnimState.PlayAnimation
function AnimState:PlayAnimation(anim, loop, ...)
    local inst = UM_BEARDLORDS.AnimStates and UM_BEARDLORDS.AnimStates[self]
    if inst then
        local beardlord_overrides = inst.um_beardlord_overrides
        if beardlord_overrides then anim, loop = beardlord_overrides.anim, beardlord_overrides.loop end
    end
    return _PlayAnimation(self, anim, loop, ...)
end

local _PlaySound = SoundEmitter.PlaySound
function SoundEmitter:PlaySound(sound, ...)
    local inst = self:GetEntity()
    if inst then
        local beardlord_overrides = inst.um_beardlord_overrides
        if beardlord_overrides then sound = beardlord_overrides.sound end
    end
    return _PlaySound(self, sound, ...)
end

local function RemoveFromGlobalTable(inst)
    local AnimState = inst.AnimState
    if AnimState and UM_BEARDLORDS.AnimStates[AnimState] then UM_BEARDLORDS.AnimStates[AnimState] = nil end
    inst:RemoveEventCallback("onremove", RemoveFromGlobalTable)
end

local function BeardlordAnimations(inst)
    local AnimState = inst.AnimState
    if AnimState then UM_BEARDLORDS.AnimStates[AnimState] = inst end
    inst:ListenForEvent("onremove", RemoveFromGlobalTable)
end

env.AddStategraphPostInit("bunnyman", function(inst)
    local funnyidlestate = inst.states["funnyidle"]

    if funnyidlestate then
        local funnyidlestate_onenter = funnyidlestate.onenter
        funnyidlestate.onenter = function(inst, pushanim, ...)
            if inst.beardlord then inst.um_beardlord_overrides = {anim = "beard_taunt", sound = "dontstarve/creatures/bunnyman/wererabbit_taunt"} end
            local ret = funnyidlestate_onenter(inst, pushanim, ...)
            if inst.um_beardlord_overrides then inst.um_beardlord_overrides = nil end
            return ret
        end
    end

    local states = {
        State{
            name = "um_transform",
            tags = {"transform", "busy"},

            onenter = function(inst)
                inst.Physics:Stop()
                inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/transform")
                inst.AnimState:PlayAnimation(inst.beardlord and "trans_rabbit_pre" or "trans_beard_pre")
                inst.AnimState:PushAnimation(inst.beardlord and "trans_beard_pst" or "trans_rabbit_pst", false)
            end,

            events =
            {
                EventHandler("animqueueover", function(inst)
                    inst.sg:GoToState("idle")
                end),
            },

            --[[onexit = function(inst)
                inst.AnimState:SetBuild("werepig_build")
            end,]]
        },
    }

    --[[for _, event in pairs(events) do
        inst.events[event.name] = event
    end]]

    for _, state in pairs(states) do
        inst.states[state.name] = state
    end
end)

env.AddPrefabPostInit("bunnyman", function(inst)
    if not TheWorld.ismastersim then return end
    BeardlordAnimations(inst)
end)
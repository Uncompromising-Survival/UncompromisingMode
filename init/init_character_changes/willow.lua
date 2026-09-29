local env = env
GLOBAL.setfenv(1, GLOBAL)
local UMUpvalueHacker = require("tools/um_upvaluehacker")

local function StopSmog(inst)
    if inst.smog_task then
        inst.smog_task:Cancel()
        inst.smog_task = nil
    end
end

env.AddSimPostInit(function()
    local _RefreshAttunedSkills = UMUpvalueHacker.TryGetUpvalue(Prefabs.lighter.fn, "RefreshAttunedSkills")
    if _RefreshAttunedSkills then
        local function RefreshAttunedSkills(inst, owner, ...)
            local waschannelcastable = inst.components.channelcastable ~= nil
            _RefreshAttunedSkills(inst, owner, ...)
            local channelcastable = inst.components.channelcastable
            if not waschannelcastable and channelcastable then
                local _OnStartChanneling = channelcastable.onstartchannelingfn
                channelcastable:SetOnStartChannelingFn(function(inst, user, ...)
                    _OnStartChanneling(inst, user, ...)
                    StopSmog(inst)
                    inst.smog_task = inst:DoPeriodicTask(.3, function(inst)
                        if not user:IsValid() then
                            StopSmog(inst)
                            return
                        end

                        local x, y, z = user.Transform:GetWorldPosition()
                        for _, v in ipairs(TheSim:FindEntities(x, y, z, 12, {"smog"}, {"INLIMBO"})) do
                            v:Remove()
                            user.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
                            SpawnPrefab("channel_absorb_smoulder").Follower:FollowSymbol(user.GUID, "swap_object", 56, -40, 0)
                        end
                    end)
                end)
                local _OnStartChanneling = channelcastable.onstopchannelingfn
                channelcastable:SetOnStopChannelingFn(function(inst, user, ...)
                    StopSmog(inst)
                    _OnStartChanneling(inst, user, ...)
                end)
            else
                StopSmog(inst)
            end
        end
        UMUpvalueHacker.SetUpvalue(Prefabs.lighter.fn, RefreshAttunedSkills, "RefreshAttunedSkills")
    end
end)

--[[env.AddPrefabPostInit("lighter", function(inst)
    if not TheWorld.ismastersim then return end
end)]]
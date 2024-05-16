local assets =
{
    Asset("ANIM","anim/squid_inked.zip"),
}

TUNING.SNAILDRAKE_SLIME_DEBUFF_DURATION = 15

-- Get rid of this debuff when the duration is over
local function OnTimerDone(inst, data)
    if data.name == "snaildrake_slime_debuff" then
        inst.components.debuff:Stop()
    end
end

-- Snaildrake slime is sticky and explosive. Pin the target if
-- possible, and explode the slime if the target is ignited.
local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Follower:FollowSymbol(target.GUID, "headbase", 0,0,0)
    if inst._followtask ~= nil then
        inst._followtask:Cancel()
    end
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)

    local function explode()
        local x, y, z = inst.Transform:GetWorldPosition()
        local explosion = SpawnPrefab("snaildrake_explosion")
        explosion.Transform:SetPosition(x, y, z)
        if target.components.pinnable and target.components.pinnable:IsStuck() then
            target.components.pinnable:Unstick()
        end
        inst.components.debuff:Stop()
    end

    inst:ListenForEvent("onignite", explode, target)
    inst:ListenForEvent("firedamage", explode, target)
end

-- Refresh the duration of the debuff when reapplied
local function OnExtended(inst, target)
    inst.components.timer:StopTimer("snaildrake_slime_debuff")
    inst.components.timer:StartTimer("snaildrake_slime_debuff", TUNING.SNAILDRAKE_SLIME_DEBUFF_DURATION)
end

-- Remove the debuff
-- Called in components.debuffable.lua when inst.components.debuff:Stop() is called
local function OnDetached(inst)
    inst.AnimState:PlayAnimation("ink_pst")
    inst:ListenForEvent("animover", function()
        inst:Remove()
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("squid_ink_follow")
    inst.AnimState:SetBuild("squid_inked")
    inst.AnimState:PlayAnimation("ink_pre")
    inst.AnimState:PushAnimation("ink_loop")
    inst.AnimState:SetFinalOffset(3)

    -- Visual VFX until we can get unique art assets.
    inst.AnimState:SetAddColour(0.75, 0.75, 0.1, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("snaildrake_slime_debuff", TUNING.SNAILDRAKE_SLIME_DEBUFF_DURATION)

    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("snaildrake_slime_debuff", fn, assets)
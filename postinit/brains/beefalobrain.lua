local env = env
GLOBAL.setfenv(1, GLOBAL)

require "behaviours/follow"

--local BrainSurgeon = env.require("tools/brainsurgeon")
--local Swire_BrainCommon = require("brains/swire_braincommon")

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end

---------------------------------------------------------------------------------------
local MIN_BELL_DIST = 0
local TARGET_BELL_DIST = 4
local MAX_BELL_DIST = 8

local function GetCalled(inst)
    local node = Follow(inst, function()
        local bell_owner = inst:GetBeefBellOwner() or GetLeader(inst)
            return inst:HasTag("beefcalled") and (bell_owner ~= nil and bell_owner:IsOnValidGround() and not bell_owner:HasTag("pocketdimension_container") and bell_owner)
                or nil
        end, MIN_BELL_DIST, TARGET_BELL_DIST, MAX_BELL_DIST, true)
    return node
end

---------------------------------------------------------------------------------------

env.AddBrainPostInit("beefalobrain", function(brain)
    local inst = brain.inst
    local root = brain.bt and brain.bt.root
    if not root then return end


    -- Insert before first fight node to allow picking up helmets mid battle
    table.insert(root.children, 3, GetCalled(inst))
end)
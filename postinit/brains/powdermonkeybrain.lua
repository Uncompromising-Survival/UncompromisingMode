local CANNON_MUST = {"boatcannon"}
local TARGETS_MUST = {"_health", "_combat"}
local TARGETS_CANT = {"pirate", "bird", "shadow", "structure", "INLIMBO", "notarget"}
local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
local env = env
GLOBAL.setfenv(1, GLOBAL)

local function gotocannon(inst)
    if inst.components.crewmember then
        return nil
    end
    local pos = Vector3(inst.Transform:GetWorldPosition())

    local cannons = TheSim:FindEntities(pos.x, pos.y, pos.z, 24, CANNON_MUST)

    for i, cannon in ipairs(cannons) do
        if cannon.operator == nil or cannon.operator == inst then
            local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, 50, TARGETS_MUST, TARGETS_CANT)
            if #targets > 0 then
                for i, target in ipairs(targets) do
                    print(target)
                    if not cannon.components.timer:TimerExists("monkey_biz") and target.prefab ~= "merm" then
                        local boatpos = Vector3(target.Transform:GetWorldPosition())
                        local cannonangle = cannon:GetAngleToPoint(boatpos.x, boatpos.y, boatpos.z)

                        if math.abs(DiffAngle(cannonangle, cannon.Transform:GetRotation())) < 270 then
                            local cannonpos = Vector3(cannon.Transform:GetWorldPosition())
                            local angle = (cannon.Transform:GetRotation() - 180) * DEGREES
                            local offset = FindWalkableOffset(cannonpos, angle, 2, 12, true, false, nil, true)

                            if offset and inst:GetDistanceSqToPoint(cannonpos) > (0.25 * 0.25) then
                                cannon.operator = inst
                                inst.cannon = cannon
                                cannon.Transform:SetRotation(cannonangle)

                                return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, cannonpos + offset)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function firecannon(inst)
    if inst.components.crewmember then
        return nil
    end
    local pos = Vector3(inst.Transform:GetWorldPosition())

    local cannon = inst.cannon
    if cannon and cannon:IsValid() then
        local targets = TheSim:FindEntities(pos.x, pos.y, pos.z, 25, TARGETS_MUST, TARGETS_CANT)
        if #targets > 0 then
            for i, target in ipairs(targets) do
                print(target)

                if not cannon.components.timer:TimerExists("monkey_biz") and target.prefab ~= "merm" then
                    local boatpos = Vector3(target.Transform:GetWorldPosition())
                    local angle = cannon:GetAngleToPoint(boatpos.x, boatpos.y, boatpos.z)

                    if math.abs(DiffAngle(angle, cannon.Transform:GetRotation())) < 45 then
                        local cannonpos = Vector3(cannon.Transform:GetWorldPosition())
                        local offset = FindWalkableOffset(cannonpos, angle, 2, 12, true, false, nil, true)

                        if inst:GetDistanceSqToPoint(cannonpos + offset) <= (0.3 * 0.3) then
                            return BufferedAction(inst, cannon, ACTIONS.BOAT_CANNON_SHOOT)
                        end
                    end
                end
            end
        end
    else
        inst.cannon = nil
    end
end

env.AddBrainPostInit("powdermonkeybrain", function(self)
    local FireCannon = ChattyNode(self.inst, "MONKEY_TALK_FIRECANNON", DoAction(self.inst, firecannon, "cannon", true))
    local GoToCannon = DoAction(self.inst, gotocannon, "gotocannon", true)

    table.insert(self.bt.root.children, 1, FireCannon)
    table.insert(self.bt.root.children, 2, GoToCannon)
end)

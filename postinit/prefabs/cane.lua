local env = env
GLOBAL.setfenv(1, GLOBAL)

local canes = {}

if TUNING.DSTU.CANEDURABILITY then
    table.insert(canes,"cane")
end

if TUNING.DSTU.COOLDOWN_ORANGESTAFF then
    table.insert(canes,"orangestaff")
end

local function GetPoints(pt, amount)
    local points = {}
    local radius = 1
    local radiusOffset = 0

    for i = 1, amount do
        local r = math.max(0, radius + radiusOffset)
        local numPoints = math.floor(TWOPI * r * .25)
        if i == 1 and numPoints <= 4 then
            numPoints = 1
        end

        if not points[i] then
            points[i] = {}
        end

        local randx = math.cos(math.random(-180, 180) * DEGREES)
        local randz = math.sin(math.random(-180, 180) * DEGREES)
        if numPoints > 1 then
            for p = 1, numPoints do
                randx = math.cos(math.random(-180, 180) * DEGREES)
                randz = math.sin(math.random(-180, 180) * DEGREES)
                local theta = (TWOPI / numPoints) * p
                local x = pt.x + r * math.cos(theta)
                local z = pt.z + r * math.sin(theta)
                local point = Vector3(x + randx, 0, z + randz)

                table.insert(points[i], point)
            end
        else
            table.insert(points[i], Vector3(pt.x + randx, 0, pt.z + randz))
        end

        radius = radius + 1
    end

    return points
end

local function CANEEXPLOSION(inst)
    local dummy = SpawnPrefab("dummytarget")
    if dummy then
        dummy.Transform:SetPosition(inst.Transform:GetWorldPosition())
        dummy:Hide()
        dummy.persists = false
        local fx = 30
        local points = GetPoints(dummy:GetPosition(), fx)
        local map = TheWorld.Map
        for i = 1, fx do
            for j, v in ipairs(points[i]) do
                if map:IsLandTileAtPoint(v:Get()) and not map:IsDockAtPoint(v:Get()) then
                    SpawnPrefab("um_brokentool").Transform:SetPosition(v.x, 0, v.z)
                end
            end
        end
        dummy:DoTaskInTime(.5, inst.Remove)
    end
    inst:Remove()
end

local function MYCANEISDYING(inst, data)
    if data.percent and data.percent <= .15 then
        SpawnPrefab("um_brokentool").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end
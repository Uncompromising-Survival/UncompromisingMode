local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local function OnSave(inst, data)
    data.lavaecond1 = inst.lavaecond1
    data.lavaecond2 = inst.lavaecond2
    data.lavaecond3 = inst.lavaecond3
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.lavaecond1 ~= nil then inst.lavaecond1 = data.lavaecond1 end
        if data.lavaecond2 ~= nil then inst.lavaecond2 = data.lavaecond2 end
        if data.lavaecond3 ~= nil then inst.lavaecond3 = data.lavaecond3 end
        if data.owner ~= nil then inst.owner = data.owner end
    end
end

local function InitializeLavae(inst, owner)
    if inst.lavaecond1 == nil then inst.lavaecond1 = "alive" end
    if inst.lavaecond2 == nil then inst.lavaecond2 = "alive" end
    if inst.lavaecond3 == nil then inst.lavaecond3 = "alive" end
end

local function OneDead(inst)
    inst.lavaecond1 = "dead"
    inst.lavae1 = nil
    inst.components.timer:StartTimer("1revive", 8)
end

local function TwoDead(inst)
    inst.lavaecond2 = "dead"
    inst.lavae2 = nil
    inst.components.timer:StartTimer("2revive", 8)
end

local function ThreeDead(inst)
    inst.lavaecond3 = "dead"
    inst.lavae3 = nil
    inst.components.timer:StartTimer("3revive", 8)
end

local function SpawnLavae(num, pos, boat, inst, owner)
    local lavae = SpawnPrefab("armorlavae")
    lavae.number = num
    lavae.Transform:SetPosition(pos.x + (not boat and GetRandomWithVariance(-3, 3) or 0), pos.y, pos.z + (not boat and GetRandomWithVariance(-3, 3) or 0))
    inst["lavae"..num] = lavae
    owner.components.leader:AddFollower(lavae)
    SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(lavae.Transform:GetWorldPosition())
end

local function OnTimerDone(inst, data)
    if data ~= nil then
        local owner = inst.components.inventoryitem.owner
        local pos = owner and owner:GetPosition() or nil
        for i = 1, 3 do
            if data.name == i.."revive" then
                inst["lavaecond"..i] = "alive"
                if pos and inst.components.equippable.isequipped then SpawnLavae(i, pos, nil, inst, owner) end
            end
        end
    end
end

env.AddPrefabPostInit("armordragonfly", function(inst)
    if not TheWorld.ismastersim then return end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    local _onequip = inst.components.equippable.onequipfn
    local _onunequip = inst.components.equippable.onunequipfn

    local function newonequip(inst, owner)
        if owner:HasTag("player") then
            local x, y, z = owner.Transform:GetWorldPosition()
            local boat = TheWorld.Map:GetPlatformAtPoint(x, z)
            InitializeLavae(inst, owner)
            for i = 1, 3 do
                if inst["lavaecond"..i] == "alive" then SpawnLavae(i, {x = x, y = y, z = z}, boat, inst, owner) end
            end
        end
        _onequip(inst, owner)
    end

    local function newonunequip(inst, owner)
        if owner:HasTag("player") then
            for i = 1, 3 do
                if inst["lavae"..i] then
                    if inst["lavae"..i]:IsValid() then
                        local x, y, z = inst["lavae"..i].Transform:GetWorldPosition()
                        SpawnPrefab("halloween_firepuff_1").Transform:SetPosition(x, y, z)
                        inst["lavae"..i]:Remove()
                    end
                    inst["lavae"..i] = nil
                end
            end
        end
        _onunequip(inst, owner)
    end

    inst.components.equippable:SetOnEquip(newonequip)
    inst.components.equippable:SetOnUnequip(newonunequip)

    inst.components.armor:InitCondition(1500, 0.6)

    inst.OneDead = OneDead
    inst.TwoDead = TwoDead
    inst.ThreeDead = ThreeDead

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
    inst.components.equippable.dapperness = 0 -- No more dapperness
end)
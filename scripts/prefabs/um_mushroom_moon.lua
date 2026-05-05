local assets =
{
    Asset("ANIM", "anim/um_lunar_mushroom.zip"),
}

local function onsave(inst, data)
    if inst.rain > 0 then
        data.rain = inst.rain
    end
end

local function onload(inst, data)
    if data and data.rain then
        inst.rain = data.rain or inst.rain
    end
end

local function onpickedfn(inst)
    if inst.growtask ~= nil then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
    inst.AnimState:PlayAnimation("picked")
    inst.rain = 10 + math.random(10)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function checkregrow(inst)
    if inst.components.pickable ~= nil and not inst.components.pickable.canbepicked and TheWorld.state.israining then
        inst.rain = inst.rain - 1
        if inst.rain <= 0 then
            inst.components.pickable:Regen()
        end
    end
end

local function GetStatus(inst)
    return (not (inst.components.pickable ~= nil and inst.components.pickable.canbepicked) and "PICKED")
        or (inst.components.pickable.caninteractwith and "GENERIC")
        or "INGROUND"
end

local function open(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.opentaskfn)
    end
end

local function close(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.closetaskfn)
    end
end

local function onregenfn(inst)
    inst.components.pickable.caninteractwith = false -- Wait for the mushroom to become visible.

    if TheWorld.state.isfullmoon or inst.components.areaaware:CurrentlyInTag("lunacyarea") then
        open(inst)
    else
        inst.AnimState:PushAnimation("inground", false)
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
    end
end

local function testfortransformonload(inst)
    return TheWorld.state.isfullmoon
end

local function OnIsOpenPhase(inst, isopen)
    if isopen then
        open(inst)
    elseif not inst.components.areaaware:CurrentlyInTag("lunacyarea") then
        close(inst)
    end
end

local function OnSpawnedFromHaunt(inst, data)
    Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
end

--V2C: basically, each colour and type can switch to another colour of the same type
local switchtable = {}
local switchcolours = { "red", "blue", "green" }
local switchtypes = { "_cap", "_cap_cooked", "_mushroom" }
for i, v in ipairs(switchcolours) do
    for i2, v2 in ipairs(switchtypes) do
        local t = {}
        switchtable[v..v2] = t
        for i3, v3 in ipairs(switchcolours) do
            if v ~= v3 then
                table.insert(t, v3..v2)
            end
        end
    end
end
local function pickswitchprefab(inst)
    local t = switchtable[inst.prefab]
    return t ~= nil and t[math.random(#t)] or nil
end

local function OnHauntMush(inst, haunter)
    local ret = false
    if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        local x, y, z = inst.Transform:GetWorldPosition()
        SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
        local prefab = pickswitchprefab(inst)
        local new = prefab ~= nil and SpawnPrefab(prefab) or nil
        if new ~= nil then
            new.Transform:SetPosition(x, y, z)
            -- Make it the right state
            if inst.components.pickable ~= nil and not inst.components.pickable.canbepicked then
                if new.components.pickable ~= nil then
                    new.components.pickable:MakeEmpty()
                end
            elseif inst.components.pickable ~= nil and not inst.components.pickable.caninteractwith then
                new.AnimState:PlayAnimation("inground")
                if new.components.pickable ~= nil then
                    new.components.pickable.caninteractwith = false
                end
            else
                new.AnimState:PlayAnimation(new.data.animname)
                if new.components.pickable ~= nil then
                    new.components.pickable.caninteractwith = true
                end
            end
        end
        new:PushEvent("spawnedfromhaunt", { haunter = haunter, oldPrefab = inst })
        inst:PushEvent("despawnedfromhaunt", { haunter = haunter, newPrefab = new })
        inst.persists = false
        inst.entity:Hide()
        inst:DoTaskInTime(0, inst.Remove)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        ret = true
    elseif inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() and inst.components.pickable.caninteractwith then
        inst:closetaskfn()
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        ret = true
    end
    --#HAUNTFIX
    --if math.random() <= TUNING.HAUNT_CHANCE_VERYRARE then
        --if inst.components.burnable ~= nil and not inst.components.burnable:IsBurning() and
            --inst.components.pickable ~= nil and inst.components.pickable.canbepicked then
            --inst.components.burnable:Ignite()
            --inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            --inst.components.hauntable.cooldown_on_successful_haunt = false
            --ret = true
        --end
    --end
    return ret
end

local function TryPopup(inst)
    if TheWorld.state.isfullmoon or inst.components.areaaware:CurrentlyInTag("lunacyarea") then
        inst.AnimState:PlayAnimation("idle_"..inst.data.animname)
        inst.components.pickable.caninteractwith = true
    else
        inst.AnimState:PlayAnimation("inground")
        inst.components.pickable.caninteractwith = false
    end
end

local function mushcommonfn(data)
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lunarmushroom")
    inst.AnimState:SetBuild("lunar_mushroom")
    inst.AnimState:PlayAnimation("idle_"..data.animname)
    inst.scrapbook_anim = "idle_"..data.animname
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("areaaware")

    inst.data = data

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.opentaskfn = function()
        inst.AnimState:PlayAnimation("open_inground")
        inst.AnimState:PushAnimation("open_"..data.animname)
        inst.AnimState:PushAnimation("idle_"..data.animname, false)
        inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")
        inst.growtask = nil
        if inst.components.pickable ~= nil then
            inst.components.pickable.caninteractwith = true
        end
    end

    inst.closetaskfn = function()
        inst.AnimState:PlayAnimation("close_"..data.animname)
        inst.AnimState:PushAnimation("inground", false)
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
        inst.growtask = nil
        if inst.components.pickable then
            inst.components.pickable.caninteractwith = false
        end
    end

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp(data.pickloot, nil)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    --inst.components.pickable.quickpick = true

    inst.rain = 0

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab(data.pickloot)
        end

        inst.components.lootdropper:SpawnLootPrefab(data.pickloot)
        inst:Remove()
    end)
    inst.components.workable:SetWorkLeft(1)

    AddToRegrowthManager(inst)
    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHauntMush) --AXE Haunting undoes the lunar mutations

    inst:WatchWorldState("isfullmoon", OnIsOpenPhase)

    inst:DoPeriodicTask(TUNING.SEG_TIME, checkregrow, TUNING.SEG_TIME + math.random()*TUNING.SEG_TIME)

    inst:DoTaskInTime(0.1,TryPopup)

    inst.TryPopup = TryPopup

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end

local function moonMushfn()

    local data = {}
    data.animname = "lunar"
    data.pickloot = "moon_cap"

    local inst = mushcommonfn(data)

    return inst
end

return Prefab("um_mushroom_moon",moonMushfn,assets)
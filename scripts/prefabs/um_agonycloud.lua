local assets =
{
    Asset("ANIM", "anim/sleepcloud.zip"),
    Asset("ANIM", "anim/sporecloud_base.zip"),
}

local TICK_PERIOD = .5

local TICK_VALUE = 10
local MAX_SLEEP_TIME = 5
local MIN_SLEEP_TIME = 1.5

local PLAYER_TICK_VALUE = 1
local PLAYER_MAX_SLEEP_TIME = 4
local PLAYER_MIN_SLEEP_TIME = 1

local ATTACK_SLEEP_DELAY = 2
local CHAIN_SLEEP_DELAY = 4

local GLOOM_R, GLOOM_G, GLOOM_B, GLOOM_A = 0.8/0.6, 0.25/0.6, 0.25, 0.6

local function CreateBase(isnew)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("sporecloud_base")
    inst.AnimState:SetBuild("sporecloud_base")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(3)

    if isnew then
        inst.AnimState:PlayAnimation("sporecloud_base_pre")
		inst.AnimState:SetFrame(12)
        inst.AnimState:PushAnimation("sporecloud_base_idle", false)
    else
        inst.AnimState:PlayAnimation("sporecloud_base_idle")
    end
	inst.AnimState:SetMultColour(GLOOM_R, GLOOM_G, GLOOM_B, GLOOM_A)
    return inst
end

local function OnStateDirty(inst)
    if inst._state:value() > 0 then
        if inst._inittask ~= nil then
            inst._inittask:Cancel()
            inst._inittask = nil
        end
        if inst._state:value() == 1 then
            if inst._basefx == nil then
                inst._basefx = inst._create_base_fn(false)
                inst._basefx.entity:SetParent(inst.entity)
            end
        elseif inst._basefx ~= nil then
            inst._basefx.AnimState:PlayAnimation("sporecloud_base_pst")
        end
    end
end

local function OnAnimOver(inst)
    inst:RemoveEventCallback("animover", OnAnimOver)
    inst._state:set(1)
end


local function DoDisperse(inst)
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    if inst._drowsytask ~= nil then
        inst._drowsytask:Cancel()
        inst._drowsytask = nil
    end

    inst:RemoveEventCallback("animover", OnAnimOver)
    inst._state:set(2)

    inst.AnimState:PlayAnimation("sleepcloud_pst")
    inst.SoundEmitter:KillSound("spore_loop")
    inst.persists = false
    inst:DoTaskInTime(3, inst.Remove) --anim len + 1.5 sec

    if inst._basefx ~= nil then
        inst._basefx.AnimState:PlayAnimation("sporecloud_base_pst")
    end
end

local function OnTimerDone(inst, data)
    if data.name == "disperse" then
        DoDisperse(inst)
    end
end

local function OnLoad(inst, data)
    --Not a brand new cloud, cancel initial sound and pre-anims
    if inst._inittask ~= nil then
        inst._inittask:Cancel()
        inst._inittask = nil
    end

    inst:RemoveEventCallback("animover", OnAnimOver)

    local t = inst.components.timer:GetTimeLeft("disperse")
    if t == nil or t <= 0 then
        if inst._drowsytask ~= nil then
            inst._drowsytask:Cancel()
            inst._drowsytask = nil
        end
        inst._state:set(2)
        inst.SoundEmitter:KillSound("spore_loop")
        inst:Hide()
        inst.persists = false
        inst:DoTaskInTime(0, inst.Remove)
    else
        inst._state:set(1)
        inst.AnimState:PlayAnimation("sleepcloud_loop", true)

        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            inst._basefx = inst._create_base_fn(false)
            inst._basefx.entity:SetParent(inst.entity)
        end

    end
end

local function InitFX(inst)
    inst._inittask = nil

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        inst._basefx = inst._create_base_fn(true)
        inst._basefx.entity:SetParent(inst.entity)
    end
end



local function RemoveAgony(v)
	if not FindEntity(v,3.5,function(ent) return ent.prefab == "um_agonycloud" end) then
		v.um_agony_remove:Cancel() 
		v.um_agony_remove = nil
		v:RemoveTag("agony_gas") --AXE There's not an easy way to set up damage vulns that klei endorses, I'm just going to use a tag for this one...
	end
end

local TARGET_PVP_ONEOF_TAGS = { "_combat", "player" }
local TARGET_PVP_CANT_TAGS = { "playerghost", "FX", "DECOR", "INLIMBO" }
local TARGET_MUST_TAGS = { "_combat" }
local TARGET_CANT_TAGS = { "player", "FX", "DECOR", "INLIMBO","agony_gas" }
local function DoAreaVulnerability(inst, sleeptimecache, sleepdelaycache)
    local x, y, z = inst.Transform:GetWorldPosition()
    local range = 3.5
    local t = GetTime()
    local ents =
        TheNet:GetPVPEnabled() and
        TheSim:FindEntities(x, y, z, range, nil, TARGET_PVP_CANT_TAGS, TARGET_PVP_ONEOF_TAGS) or
        TheSim:FindEntities(x, y, z, range, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
	if ents and #ents > 0 then
		for i,v in ipairs(ents) do
			v:AddTag("agony_gas")
			v.um_agony_remove = v:DoPeriodicTask(FRAMES,RemoveAgony)
		end
	end
end

local function SetOwner(inst, owner)
	inst.owner = owner
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("sleepcloud")
    inst.AnimState:SetBuild("sleepcloud")
    inst.AnimState:PlayAnimation("sleepcloud_pre")

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_cloud_LP", "spore_loop")

    inst._state = net_tinybyte(inst.GUID, "sleepcloud._state", "statedirty")

    inst._inittask = inst:DoTaskInTime(0, InitFX)

    inst._create_base_fn = CreateBase

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst:ListenForEvent("statedirty", OnStateDirty)

        return inst
    end

    inst._drowsytask = inst:DoPeriodicTask(TICK_PERIOD, DoAreaVulnerability, nil, {}, {})

    inst.AnimState:PushAnimation("sleepcloud_loop", true)
    inst:ListenForEvent("animover", OnAnimOver)
	inst.AnimState:SetMultColour(GLOOM_R, GLOOM_G, GLOOM_B, GLOOM_A)
    inst:AddComponent("timer")
    inst.components.timer:StartTimer("disperse", TUNING.SLEEPBOMB_DURATION)

    inst:ListenForEvent("timerdone", OnTimerDone)

	inst.SetOwner = SetOwner
    inst.OnLoad = OnLoad

    return inst
end
return Prefab("um_agonycloud", fn, assets) --AXE same as vanilla, just no overlay, since it's unnecessary.

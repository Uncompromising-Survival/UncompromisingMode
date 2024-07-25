require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/snaildrake_hole.zip"),
	Asset("IMAGE", "images/map_icons/snaildrake_hole.tex"),
	Asset("ATLAS", "images/map_icons/snaildrake_hole.xml"),
}

local prefabs =
{
    "snaildrake_magma",
    "snaildrake_slime",
}

TUNING.SNAILDRAKE_RESPAWN_TIME = 480 * 2

-- Update Snaildrake data on respawn.
local function OnTimerDone(inst, data)
    if data.name == "respawn_magma" then
        inst.has_magma = true
    elseif data.name == "respawn_slime" then
        inst.has_slime = true
    end
	inst.SpawnSnaildrakes(inst)
end

-- Remove child listeners for Snaildrakes.
local function RemoveChildListeners(inst, child)
    inst:RemoveEventCallback("death", inst.onchildkilled, child)
end

-- Start respawn timers when Snaildrakes are killed.
local function OnChildKilled(inst, child)
    RemoveChildListeners(inst, child)
    if child.prefab == "snaildrake_magma" then
        inst.components.timer:StartTimer("respawn_magma", TUNING.SNAILDRAKE_RESPAWN_TIME)
        inst.has_magma = false
        inst.snaildrake_magma = nil
    elseif child.prefab == "snaildrake_slime" then
        inst.components.timer:StartTimer("respawn_slime", TUNING.SNAILDRAKE_RESPAWN_TIME)
        inst.has_slime = false
        inst.snaildrake_slime = nil
    end
end

-- Add child listeners for Snaildrakes.
local function AddChildListeners(inst, child)
    inst:ListenForEvent("death", inst.onchildkilled, child)
end

-- Setup linking information between a Snaildrake and its home.
local function InitializeSnaildrake(inst, snaildrake)
    if snaildrake.components.homeseeker == nil then
        snaildrake:AddComponent("homeseeker")
    end
    snaildrake.components.homeseeker:SetHome(inst)
    AddChildListeners(inst, snaildrake)
end

-- Spawn the Snaildrakes and link them together if both are alive.
local function SpawnSnaildrakes(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.has_magma and not inst.snaildrake_magma then
        inst.has_magma = false
        local magma = SpawnPrefab("snaildrake_magma")
        magma.Transform:SetPosition(x, y, z)
        InitializeSnaildrake(inst, magma)
        inst.snaildrake_magma = magma
    end
    if inst.has_slime and not inst.snaildrake_slime then
        inst.has_slime = false
        local slime = SpawnPrefab("snaildrake_slime")
        slime.Transform:SetPosition(x, y, z)
        InitializeSnaildrake(inst, slime)
        inst.snaildrake_slime = slime
    end
    if inst.snaildrake_magma and inst.snaildrake_slime then
        inst.snaildrake_magma.partner = inst.snaildrake_slime
        inst.snaildrake_slime.partner = inst.snaildrake_magma
    end
	if not inst.components.timer:TimerExists("respawn_slime") and not inst.has_slime then -- Restart Timer if somehow the timer ended w/out resetting
		inst.components.timer:StartTimer("respawn_slime", TUNING.SNAILDRAKE_RESPAWN_TIME)
	end
	if not inst.components.timer:TimerExists("respawn_magma") and not inst.has_magma then
		inst.components.timer:StartTimer("respawn_magma", TUNING.SNAILDRAKE_RESPAWN_TIME)
	end	
end

-- Update Snaildrake data.
local function OnWentHome(inst, data)
    if data.doer then
        if data.doer.prefab == "snaildrake_magma" then
            inst.has_magma = true
        elseif data.doer.prefab == "snaildrake_slime" then
            inst.has_slime = true
        end
    end
end

-- Save Snaildrake information.
local function OnSave(inst, data)
    local ents = {}

    data.has_magma = inst.has_magma
    data.has_slime = inst.has_slime

    if inst.snaildrake_magma then
        data.snaildrake_magma = inst.snaildrake_magma.GUID
        table.insert(ents, inst.snaildrake_magma.GUID)
    end
    if inst.snaildrake_slime then
        data.snaildrake_slime = inst.snaildrake_slime.GUID
        table.insert(ents, inst.snaildrake_slime.GUID)
    end

    return ents
end

-- Load Snaildrake information.
local function OnLoad(inst, data)
    if data then
        inst.has_magma = data.has_magma
        inst.has_slime = data.has_slime
    end
end

-- Update references to Snaildrake entities.
local function OnLoadPostPass(inst, newents, savedata)
    if savedata then
        if savedata.snaildrake_magma then
            inst.snaildrake_magma = newents[savedata.snaildrake_magma].entity
            InitializeSnaildrake(inst, inst.snaildrake_magma)
        end
        if savedata.snaildrake_slime then
            inst.snaildrake_slime = newents[savedata.snaildrake_slime].entity
            InitializeSnaildrake(inst, inst.snaildrake_slime)
        end
        if inst.snaildrake_magma and inst.snaildrake_slime then
            inst.snaildrake_magma.partner = inst.snaildrake_slime
            inst.snaildrake_slime.partner = inst.snaildrake_magma
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("snaildrake_hole.tex")

    inst.AnimState:SetBank("snaildrake_hole")
    inst.AnimState:SetBuild("snaildrake_hole")
    inst.AnimState:PlayAnimation("idle", true)

    -- Temporary VFX until we have custom art.
    inst.AnimState:SetHue(0.25)
    inst.AnimState:SetMultColour(0.25, 0.25, 0.25, 1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onwenthome", OnWentHome)

    inst:WatchWorldState("startday", SpawnSnaildrakes) -- This is a fallback now incase it somehow doesn't spawn a snaildrake as soon as it's ready
	inst:DoTaskInTime(0,SpawnSnaildrakes)
	
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    inst.has_magma = true
    inst.has_slime = true
    inst.snaildrake_magma = nil
    inst.snaildrake_slime = nil
    inst.onchildkilled = function(child) 
        OnChildKilled(inst, child)
    end

    inst.SpawnSnaildrakes = SpawnSnaildrakes
	inst:ListenForEvent("timerdone",OnTimerDone)
	
    return inst
end

return Prefab("snaildrake_hole", fn, assets, prefabs)

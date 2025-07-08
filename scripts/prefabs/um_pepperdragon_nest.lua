require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/um_pepperdragon_nest.zip"),
	Asset("IMAGE", "images/map_icons/um_pepperdragon_nest.tex"),
	Asset("ATLAS", "images/map_icons/um_pepperdragon_nest.xml"),
}

SetSharedLootTable( 'um_pepperdragon_nest',
{
    {'firenettles',			1.00},
    {'firenettles',			1.00},
    {'firenettles',		1.00},
    {'boneshards',		1.00},
	{'boneshards',		1.00},
    --{'trinket_22',	1.00},
})

-- Update dragon data on respawn.
local function OnTimerDone(inst, data)
	inst.SpawnDragon(inst)
end

-- Remove child listeners for dragon.
local function RemoveChildListeners(inst, child)
    inst:RemoveEventCallback("death", inst.onchildkilled, child)
end

-- Start respawn timers when dragon are killed.
local function OnChildKilled(inst, child)
    RemoveChildListeners(inst, child)
    inst.components.timer:StartTimer("respawn", 60*8*10)
end

-- Add child listeners for dragon.
local function AddChildListeners(inst, child)
    inst:ListenForEvent("death", inst.onchildkilled, child)
end

-- Setup linking information between a dragon and its home.
local function InitializeDragon(inst, dragon)
    if dragon.components.homeseeker == nil then
        dragon:AddComponent("homeseeker")
    end
    dragon.components.homeseeker:SetHome(inst)
    AddChildListeners(inst, dragon)
end

-- Spawn the dragon and link them together if both are alive.
local function SpawnDragon(inst)

end

local function OnSave(inst, data)

end

local function OnLoad(inst, data)
    if data then

    end
end

local function OnLoadPostPass(inst, newents, savedata)
    if savedata then

    end
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function onhit(inst, worker)

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

    inst.MiniMapEntity:SetIcon("um_pepperdragon_nest.tex")

    inst.AnimState:SetBank("um_pepperdragon_nest")
    inst.AnimState:SetBuild("um_pepperdragon_nest")
    inst.AnimState:PlayAnimation("idle", true)

    -- Temporary VFX until we have custom art.
	
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	inst:AddTag("antlion_sinkhole_blocker")
    inst:AddComponent("timer")

    inst:AddComponent("inspectable")

    inst:WatchWorldState("startday", SpawnDragon) -- This is a fallback now incase it somehow doesn't spawn a snaildrake as soon as it's ready
	inst:DoTaskInTime(0,SpawnDragon)
	
	
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

    inst.SpawnDragon = SpawnDragon
	inst:ListenForEvent("timerdone",OnTimerDone)
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable('um_pepperdragon_nest')
	
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
	
    return inst
end

return Prefab("um_pepperdragon_nest", fn, assets)

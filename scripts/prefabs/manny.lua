local assets =
{
    Asset("ANIM", "anim/manny.zip"),
	Asset("IMAGE", "images/inventoryimages/houndious_observious.tex"),
	Asset("ATLAS", "images/inventoryimages/houndious_observious.xml"),
	Asset("IMAGE", "images/map_icons/houndious_observious_map.tex"),
	Asset("ATLAS", "images/map_icons/houndious_observious_map.xml"),
}

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("built",false)
    inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_place")
    --the global animover handler will restart the check task
	inst.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/walk")
end



local function onhammer(inst)
	inst.AnimState:PlayAnimation("hit")
end

local function NextMannyAnimy(inst)
	if TheWorld.components.hounded then
		local houndtime = TheWorld.components.hounded:GetTimeToAttack()/(60*8) --Convert seconds to DS days 
		if houndtime then -- Will eventually get it to check for giants too, though I think we may wanna *actually* (which means without bug or fail) redo giant spawns before we do that...
			--TheNet:Announce(houndtime)
			if houndtime > 7 then
				inst.AnimState:PushAnimation("idle_7",false)
			elseif houndtime <= 7 and houndtime > 6 then
				inst.AnimState:PushAnimation("idle_6",false)
			elseif houndtime <= 6 and houndtime > 5 then
				inst.AnimState:PushAnimation("idle_5",false)
			elseif houndtime <= 5 and houndtime > 4 then
				inst.AnimState:PushAnimation("idle_4",false)
			elseif houndtime <= 4 and houndtime > 3 then
				inst.AnimState:PushAnimation("idle_3",false)
			elseif houndtime <= 3 and houndtime > 2 then
				inst.AnimState:PushAnimation("idle_2",false)
			elseif houndtime <= 2 and houndtime > 1 then
				inst.AnimState:PushAnimation("idle_1",false)
			elseif houndtime <= 1 then
				inst.AnimState:PushAnimation("idle_0",false)
			end
		end
	else
		inst.AnimState:PushAnimation("idle_7",false)
	end
end


local function MakeWokeAnimations(inst)
	NextMannyAnimy(inst)
	inst:ListenForEvent("animover",NextMannyAnimy)
end

local function BecomeBased(inst)
	inst:RemoveEventCallback("animover",NextMannyAnimy)
end

local function ondestroyed(inst, worker)
	BecomeBased(inst)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
    inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livingtree_die")
    inst.AnimState:PlayAnimation("death",false)
	inst:DoTaskInTime(10,function(inst)
		SpawnPrefab("maxwell_smoke").Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst:Remove()
	end)
end

local PLANT_TAGS = {"tendable_farmplant"}

local function TendToCrops(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y, z, 12, PLANT_TAGS)) do
		if v.components.farmplanttendable ~= nil then
			v.components.farmplanttendable:TendTo(inst)
		end
	end
end


local function onnear(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/walk")
	if TheWorld.components.hounded then
		local houndtime = TheWorld.components.hounded:GetTimeToAttack()/(60*8) --Convert seconds to DS days 
		if houndtime then -- Will eventually get it to check for giants too, though I think we may wanna *actually* (which means without bug or fail) redo giant spawns before we do that...
			--TheNet:Announce(houndtime)
			if houndtime > 7 then
				inst.AnimState:PlayAnimation("talk_7",false)
			elseif houndtime <= 7 and houndtime > 6 then
				inst.AnimState:PlayAnimation("talk_6",false)
			elseif houndtime <= 6 and houndtime > 5 then
				inst.AnimState:PlayAnimation("talk_5",false)
			elseif houndtime <= 5 and houndtime > 4 then
				inst.AnimState:PlayAnimation("talk_4",false)
			elseif houndtime <= 4 and houndtime > 3 then
				inst.AnimState:PlayAnimation("talk_3",false)
			elseif houndtime <= 3 and houndtime > 2 then
				inst.AnimState:PlayAnimation("talk_2",false)
			elseif houndtime <= 2 and houndtime > 1 then
				inst.AnimState:PlayAnimation("talk_1",false)
			elseif houndtime <= 1 then
				inst.AnimState:PlayAnimation("talk_0",false)
			end
		end
	else
		inst.AnimState:PlayAnimation("talk_7",false)
	end
	TendToCrops(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)
	local minimap = inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("plaunt_manny.tex")

    inst.AnimState:SetBank("manny")
    inst.AnimState:SetBuild("manny")

    inst:AddTag("structure")
	
    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
	
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(10)
    inst.components.workable:SetOnFinishCallback(ondestroyed)
    inst.components.workable:SetOnWorkCallback(onhammer)       
	

	
    inst:ListenForEvent("onbuilt", onbuilt)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeSmallPropagator(inst)
    inst:ListenForEvent("burntup", ondestroyed)
	
	inst:ListenForEvent("entitywake",MakeWokeAnimations)
	inst:ListenForEvent("entitysleep",BecomeBased)
	inst:AddComponent("playerprox")

	inst.components.playerprox:SetDist(8, 12)
	inst:DoTaskInTime(3,function(inst)
		inst.components.playerprox:SetOnPlayerNear(onnear)
	end) -- wait for build anim to finish
    MakeHauntableWork(inst)
		
    return inst
end


return Prefab("plaunt_manny", fn, assets),
    MakePlacer("plaunt_manny_placer", "plaunt_manny", "plaunt_manny", "idle_7")

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("berry_idle", true)
    inst:DoTaskInTime(8*FRAMES, function()
        inst.Light:Enable(true)
    end)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")
    inst.Light:Enable(false)
end

local function onpickedfn(inst)
    inst.AnimState:PlayAnimation("picking")
    inst.AnimState:PushAnimation("picked")
    inst.Light:Enable(false)
	if inst.vipertask then
		inst.vipertask:Cancel()
		inst.vipertask = nil
	end
end

local function SpawnViperWorm(inst)
	local bozo = FindEntity(inst,12^2,nil,{"player"},{"playerghost"})
	if bozo then
		local x, y, z = inst.Transform:GetWorldPosition()
		x = x + math.random(-2,2)
		z = z + math.random(-2,2)
		local worm = SpawnPrefab("viperling")
		worm.Transform:SetPosition(x, y, z)
		if worm.components.combat ~= nil then
			worm.components.combat:SuggestTarget(bozo)
			worm.sg:GoToState("taunt")
		end
		inst.AnimState:PlayAnimation("atk_pre")
		inst.AnimState:PushAnimation("berry_idle",true)
	end
end

local function onnear(inst)
	if not inst.vipertask and inst.components.pickable and inst.components.pickable:CanBePicked() then
		inst.vipertask = inst:DoPeriodicTask(math.random(7,10),SpawnViperWorm)
	end
end

local function onfar(inst)
	if not FindEntity(inst,12^2,nil,{"player"},{"playerghost"}) then
		inst.vipertask:Cancel()
		inst.vipertask = nil
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    --inst.MiniMapEntity:SetIcon("grass.png") -- no icon for these?

    inst.Transform:SetTwoFaced()

    inst:AddTag("plant")

    inst.AnimState:SetBank("worm")
    inst.AnimState:SetBuild("viperworm")
    inst.AnimState:PlayAnimation("berry_idle", true)
    inst.scrapbook_anim = "berry_idle"

    inst.Light:SetRadius(1.5)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetColour(1,0,0)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Transform:SetRotation(math.random()*360)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

    inst.components.pickable:SetUp("viperfruit_lesser", TUNING.WORMLIGHT_PLANT_REGROW_TIME)
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
	
	inst:AddComponent("playerprox")
	inst.components.playerprox:SetDist(8, 12) -- set specific values
	inst.components.playerprox:SetOnPlayerNear(onnear)
	inst.components.playerprox:SetOnPlayerFar(onfar)
	inst.components.playerprox:SetPlayerAliveMode(
		inst.components.playerprox.AliveModes.AliveOnly)
	
    ---------------------

    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    ---------------------

    return inst
end

return Prefab("viperfruit_plant", fn)

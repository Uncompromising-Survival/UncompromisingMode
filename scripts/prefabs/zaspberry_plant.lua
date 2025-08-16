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

local function onsave(inst,data)
	if inst.from_waterhole then
		data.from_waterhole = inst.from_waterhole
	end
end

local function onload(inst,data)
	if data and data.from_waterhole then
		inst.from_waterhole = data.from_waterhole
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
	inst:AddTag("shockwormplant")

    inst.AnimState:SetBank("shockworm")
    inst.AnimState:SetBuild("shockworm")
    inst.AnimState:PlayAnimation("berry_idle", true)
    inst.scrapbook_anim = "berry_idle"

    inst.Light:SetRadius(4)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetColour(1,1,0)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.Transform:SetRotation(math.random()*360)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"

    inst.components.pickable:SetUp("zaspberry_lesser", TUNING.WORMLIGHT_PLANT_REGROW_TIME)
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn

    inst:AddComponent("lootdropper")

    inst:AddComponent("inspectable")
	
	inst.OnSave = onsave
	inst.OnLoad = onload	
    ---------------------
	inst:WatchWorldState("iswinter",function(inst,iswinter) 
		if iswinter and inst.from_waterhole then 
			inst:Remove() 
		end 
	end)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    ---------------------

    return inst
end

return Prefab("zaspberry_plant", fn)
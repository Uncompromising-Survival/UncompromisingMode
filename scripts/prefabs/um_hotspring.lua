local assets =
{
  Asset("ANIM", "anim/um_hotspring.zip")
}

local function SpawnPlants(inst, plantname, count, maxradius)

  if inst.decor then
    for i,item in ipairs(inst.decor) do
      item:Remove()
    end
  end
  inst.decor = {}

  local plant_offsets = {}

  for i=1,math.random(math.ceil(count/2),count) do
    local a = math.random()*math.pi*2
    local x = math.sin(a)*maxradius+math.random()*0.2
    local z = math.cos(a)*maxradius+math.random()*0.2
    table.insert(plant_offsets, {x,0,z})
  end

  for k, offset in pairs( plant_offsets ) do
    local plant = SpawnPrefab( plantname )
    plant.entity:SetParent( inst.entity )
    plant.Transform:SetPosition( offset[1], offset[2], offset[3] )
    table.insert( inst.decor, plant )
  end
end

local sizes =
{
  {anim="small_idle", rad=2.0, plantcount=2, plantrad=1.6},
  {anim="med_idle", rad=2.6, plantcount=3, plantrad=2.5},
  {anim="big_idle", rad=3.6, plantcount=4, plantrad=3.4},
}

local function SetSize(inst, size)
  inst.size = math.random(1, #sizes)
  inst.AnimState:PlayAnimation(sizes[inst.size].anim, true)
  --inst.Physics:SetCylinder(sizes[inst.size].rad, 1.0)
  SpawnPlants(inst, "marsh_plant", sizes[inst.size].plantcount, sizes[inst.size].plantrad)
end

local function onsave(inst, data)
	data.size = inst.size
end

local function onload(inst, data, newents)
	if data and data.size then
		SetSize(inst, data.size)
	end
end

local function DoFx(inst) -- This is the hotspring's passive FX
	local pos = Vector3(inst.Transform:GetWorldPosition())

	local spawnrad = math.random(1,8)*sizes[inst.size].rad/10
	local offset = FindWalkableOffset(pos, math.random() * 2 * PI, spawnrad)
	if math.random() > 0.75 then
		SpawnPrefab("crab_king_bubble"..tostring(math.random(1,3))).Transform:SetPosition(pos.x+offset.x,0,pos.z+offset.z)
	else
		if math.random() > 0.5 then
			SpawnPrefab("crater_steam_fx"..tostring(math.random(1,4))).Transform:SetPosition(pos.x+offset.x,0,pos.z+offset.z)
		else
			SpawnPrefab("slow_steam_fx"..tostring(math.random(1,4))).Transform:SetPosition(pos.x+offset.x,0,pos.z+offset.z)
		end
	end
end

local function OnBathBombed(inst)
	inst.Light:Enable(true)
	inst.fxtask2 = inst:DoPeriodicTask(.1*math.random(10,30),DoFx)
	inst.components.timer:StartTimer("bubbly",8*60)
end

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddLight()
	--MakeObstaclePhysics( inst, 3.5)

	inst.AnimState:SetBuild("um_hotspring")
	inst.AnimState:SetBank("um_hotspring")
	inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
	
	inst.AnimState:SetSortOrder( 3 )
	inst.AnimState:SetLayer( LAYER_BACKGROUND )
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon( "pond_cave.png" )

    inst.Light:Enable(false)
    inst.Light:SetRadius(TUNING.HOTSPRING_GLOW.RADIUS)
    inst.Light:SetIntensity(TUNING.HOTSPRING_GLOW.INTENSITY)
    inst.Light:SetFalloff(TUNING.HOTSPRING_GLOW.FALLOFF)
    inst.Light:SetColour(0.1, 1.6, 2)

	inst.entity:SetPristine()

    inst:AddComponent("heater")
    inst.components.heater.heat = TUNING.HOTSPRING_HEAT.PASSIVE

	if not TheWorld.ismastersim then
	return inst
	end
	inst:AddTag("watersource")
	inst:AddComponent("inspectable")
	inst.no_wet_prefix = true

	inst:AddComponent("hauntable")
	inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)  


	inst.OnSave = onsave
	inst.OnLoad = onload

	SetSize(inst)
	inst:AddComponent("um_ripplespawner")
	inst.components.um_ripplespawner:SetRange(sizes[inst.size].rad)

	inst:ListenForEvent("entitywake",function(inst)
		inst.fxtask = inst:DoPeriodicTask(.1*math.random(10,30),DoFx)
		if inst.components.timer:TimerExists("bubbly") then
			inst.fxtask2 = inst:DoPeriodicTask(.1*math.random(10,30),DoFx)
		end
	end)
	
	inst:ListenForEvent("entitysleep",function(inst)
		if inst.fxtask then
			inst.fxtask:Cancel()
			inst.fxtask = nil
		end
		if inst.fxtask2 then
			inst.fxtask2:Cancel()
			inst.fxtask2 = nil
		end		
	end)
	inst:AddComponent("timer")
    inst:AddComponent("bathbombable")
	
	inst:ListenForEvent("timer")
	inst:ListenForEvent("timerdone", 
		function(inst) 
			inst.Light:Enable(false) 
			if inst.fxtask2 then
				inst.fxtask2:Cancel()
				inst.fxtask2 = nil
			end					
		end)
	inst.OnLoadPostPass = function(inst) 
		if inst.components.timer:TimerExists("bubbly") then 
			inst.Light:Enable(true) 
			inst.fxtask2 = inst:DoPeriodicTask(.1*math.random(10,30),DoFx)
		end 
	end
	
    inst.components.bathbombable:SetOnBathBombedFn(OnBathBombed)
	
	return inst
end

local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    --inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    --inst:AddTag("CLASSIFIED")

    inst:DoTaskInTime(1.1, function(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		SpawnPrefab("um_hotspring").Transform:SetPosition(x,y,z)
		local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
		-- Square
		for i = -1,1 do
			for j = -1,1 do
				TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.BOILINGFIELDS_DIRTY)
			end
		end
		inst:Remove()
	end)

    return inst
end

return Prefab( "um_hotspring", fn, assets),
Prefab("um_hotspring_placer",fn2)


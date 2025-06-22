local assets =
{
    Asset("ANIM", "anim/um_hotspring.zip")
}



local sizes =
{
    { anim = "small_idle", rad = 2.0, plantcount = 2, plantrad = 1.6 },
    { anim = "med_idle", rad = 2.6, plantcount = 3, plantrad = 2.5 },
    { anim = "big_idle", rad = 3.6, plantcount = 4, plantrad = 3.4 },
}

local function SetSize2(inst,size)
	inst.AnimState:PlayAnimation(sizes[size].anim, true)
	--inst.Physics:SetCylinder(sizes[inst.size].rad, 1.0)
	inst.components.unevenground.radius = sizes[size].plantrad
	inst.components.um_ripplespawner:SetRange(sizes[inst.size].rad)
end

local function DetermineSize(inst,fitting)
	inst.size = math.random(1, fitting ~= nil and fitting or #sizes)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,sizes[inst.size].rad,nil,nil,{"plant","pond","boulder","rock","tree"})
	for i,v in ipairs(ents) do
		if v ~= inst and inst.size ~= 1 then
			DetermineSize(inst,2)
			break 
		end
	end
	SetSize2(inst,inst.size)
end

local function SetSize(inst, size)
	if not size then
		inst.size = math.random(1, #sizes)
	else
		inst.size = size
	end
    inst.AnimState:PlayAnimation(sizes[inst.size].anim, true)
    --inst.Physics:SetCylinder(sizes[inst.size].rad, 1.0)
	inst.components.unevenground.radius = sizes[inst.size].plantrad
	inst.components.um_ripplespawner:SetRange(sizes[inst.size].rad)
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

		local spawnrad = math.random(1, 8) * sizes[inst.size].rad / 10
		local offset = FindWalkableOffset(pos, math.random() * 2 * PI, spawnrad)
		if offset then
			local fx
			if not inst:HasTag("pond_inducedinsanity") then
				if math.random() > 0.75 then
					fx = SpawnPrefab("crab_king_bubble" .. tostring(math.random(1, 3)))
				else
					if math.random() > 0.5 then
						fx = SpawnPrefab("crater_steam_fx" .. tostring(math.random(1, 4)))
					else
						fx = SpawnPrefab("slow_steam_fx" .. tostring(math.random(1, 4)))
					end
				end
			else
				fx = SpawnPrefab("tophat_shadow_fx")
				fx:DoTaskInTime(1.5,function(fx) fx:Remove() end)
			end
			fx.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
		end
		-- if TheWorld.state.isnewmoon then
			-- fx.AnimState:SetMultColour(0,0,0,1)
		-- end
end

local function OnBathBombed(inst)
	if not TheWorld.state.isnewmoon then
		inst.Light:Enable(true)
		inst.fxtask2 = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
		inst.components.timer:StartTimer("bubbly", 8 * 60)
	end
end

local function FadeToNormal(inst)
	if not inst.color then
		inst.color = 0
	end
	inst:RemoveTag("pond_inducedinsanity")
	inst.color = inst.color + FRAMES
	if inst.color > 1 then
		inst.color = 1
	else
		inst:DoTaskInTime(2*FRAMES, FadeToNormal)
	end
	inst.AnimState:SetMultColour(inst.color,inst.color,inst.color,1)
end

local function FadeToDark(inst)
	if not inst.color then
		inst.color = 1
	end
	inst:AddTag("pond_inducedinsanity")
	inst.color = inst.color - FRAMES
	if inst.color < 0.2 then
		inst.color = 0.1
	else
		inst:DoTaskInTime(2*FRAMES, FadeToDark)
	end
	inst.AnimState:SetMultColour(inst.color,inst.color,inst.color,1)
end

local function EmitSteam(inst)
	if not TheWorld.state.isnewmoon then
		local x,y,z = inst.Transform:GetWorldPosition()
		if inst.size == 1 then
			SpawnPrefab("um_steamcloud").Transform:SetPosition(x,y,z)
		else
			for i = 1,(inst.size*2-1) do
				inst:DoTaskInTime(i*0.66,function(inst)
					local steam = SpawnPrefab("um_steamcloud")
					local offset = FindWalkableOffset(inst:GetPosition(), math.random(PI * 2*((i-1)/3),PI * 2*(i/3)), inst.size*math.random(1,2))
					steam.Transform:SetPosition(x+offset.x,y,z+offset.z)
				end)
			end
		end
	end
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
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("pond_cave.png")

    inst.Light:Enable(false)
    inst.Light:SetRadius(TUNING.HOTSPRING_GLOW.RADIUS)
    inst.Light:SetIntensity(TUNING.HOTSPRING_GLOW.INTENSITY)
    inst.Light:SetFalloff(TUNING.HOTSPRING_GLOW.FALLOFF)
    inst.Light:SetColour(0.1, 1.6, 2)

    inst.entity:SetPristine()

    inst:AddComponent("heater")
    inst.components.heater.heat = 300

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
	inst:AddComponent("unevenground")
    inst.components.unevenground.radius = TUNING.ANTLION_SINKHOLE.UNEVENGROUND_RADIUS
    inst:DoTaskInTime(0,DetermineSize)
    inst:AddComponent("um_ripplespawner")
    
	
	

	
    inst:ListenForEvent("entitywake", function(inst)
        inst.fxtask = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
        if inst.components.timer:TimerExists("bubbly") then
            inst.fxtask2 = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
        end
		if math.random() > 0.5 then
			EmitSteam(inst)
		end
		inst.steamy = inst:DoPeriodicTask(math.random(30,60),EmitSteam)
    end)

    inst:ListenForEvent("entitysleep", function(inst)
        if inst.fxtask then
            inst.fxtask:Cancel()
            inst.fxtask = nil
        end
        if inst.fxtask2 then
            inst.fxtask2:Cancel()
            inst.fxtask2 = nil
        end
		if inst.steamy then
			inst.steamy:Cancel()
			inst.steamy = nil
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
            inst.fxtask2 = inst:DoPeriodicTask(.1 * math.random(10, 30), DoFx)
        end
		if TheWorld.state.isnewmoon then
			if not inst.components.timer:TimerExists("bubbly") then
				inst.shadowfx = {}
				FadeToDark(inst)
			end
		end
    end

    inst.components.bathbombable:SetOnBathBombedFn(OnBathBombed)


	inst:WatchWorldState("isnewmoon", function(inst) 
		if not inst.components.timer:TimerExists("bubbly") then
			inst.shadowfx = {}
			FadeToDark(inst)
		end
	end)
	inst:WatchWorldState("isday", function(inst) 		
		if not inst.components.timer:TimerExists("bubbly") and inst.color and inst.color < 1 then
			FadeToNormal(inst)
		end
	end)


    return inst
end

return Prefab("um_hotspring", fn, assets)

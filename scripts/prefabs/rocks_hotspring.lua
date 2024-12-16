
local function HotSpringCheck(inst)
	return FindEntity(inst,2^2,function(inst) if inst.prefab == "um_hotspring" then return true end end)
end

local function LavaCheck(inst)
	return FindEntity(inst,2^2,function(inst) if inst.prefab == "lava_pond" then return true end end)
end


local function fn1()
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
	
    inst:DoTaskInTime(1, function(inst)
		if not HotSpringCheck(inst) then
			local x,y,z = inst.Transform:GetWorldPosition()
			SpawnPrefab("springrock1").Transform:SetPosition(x,y,z)
			local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
			-- Square
			-- for i = -1,1 do
				-- for j = -1,1 do
					-- TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_WHITEROCK)
				-- end
			-- end
		end
		inst:Remove()
	end)
	
    return inst
end

local function fnmagma1()
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
	
    inst:DoTaskInTime(1, function(inst)
		if not HotSpringCheck(inst) then
			local x,y,z = inst.Transform:GetWorldPosition()
			SpawnPrefab("magmarock1").Transform:SetPosition(x,y,z)
			local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
			-- Square
			-- for i = -1,1 do
				-- for j = -1,1 do
					-- TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_MAGMA)
				-- end
			-- end
		end
		inst:Remove()
	end)
	
    return inst
end
local function fnmagma2()
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
	
    inst:DoTaskInTime(1, function(inst)
		if not LavaCheck(inst) then
			local x,y,z = inst.Transform:GetWorldPosition()
			SpawnPrefab("lava_pond_cave").Transform:SetPosition(x,y,z)
			--[[local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
			-- Square
			for i = -1,1 do
				for j = -1,1 do
					TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_MAGMA)
				end
			end]]
		end
		inst:Remove()
	end)
	
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

    inst:DoTaskInTime(1, function(inst)
		if not HotSpringCheck(inst) then
			local x,y,z = inst.Transform:GetWorldPosition()
			SpawnPrefab("springrock2").Transform:SetPosition(x,y,z)
			local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
			-- Square
			-- for i = -1,1 do
				-- for j = -1,1 do
					-- TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_WHITEROCK)
				-- end
			-- end
		end
		inst:Remove()
	end)

    return inst
end

local function fn3()
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

    inst:DoTaskInTime(1, function(inst)
		if not HotSpringCheck(inst) then
			local x,y,z = inst.Transform:GetWorldPosition()
			SpawnPrefab("springrock3").Transform:SetPosition(x,y,z)
			local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
			
			
			-- Square
			-- for i = -1,1 do
				-- for j = -1,1 do
					-- TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_WHITEROCK)
				-- end
			-- end
		end
		inst:Remove()
	end)

    return inst
end

local function NoOtherRocks(pt)
	return #TheSim:FindEntities(pt.x, 0, pt.z, 5, {"boulder"}) == 0
end

local function SpawnBunch(inst,rock1,rock2)
	local x,y,z = inst.Transform:GetWorldPosition()
	local rocks = math.random(3,5)
	local pos = inst:GetPosition()
	for rock = 1,rocks do 
		local offset = FindWalkableOffset(pos, math.random() * PI2*rock/rocks, rock, 10, false, nil, NoOtherRocks, false, false)
		if offset then
			SpawnPrefab(math.random() > 0.5 and rock1 or rock2).Transform:SetPosition(x+offset.x,y,z+offset.z)
		end
	end
end

local function fnbunchflintless()
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

    inst:DoTaskInTime(1, function(inst)
		SpawnBunch(inst,"rock1_hotspring","rock_flintless_hotspring")
		inst:Remove()
	end)

    return inst
end

local function fnbunchgold()
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

    inst:DoTaskInTime(1, function(inst)
		SpawnBunch(inst,"rock1_hotspring","rock2_hotspring")
		inst:Remove()
	end)

    return inst
end

local function fnbunchmagma()
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

    inst:DoTaskInTime(1, function(inst)
		SpawnBunch(inst,"rock_magma","pool_magma")
		inst:Remove()
	end)

    return inst
end

local function fnbunchcrabs()
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

    inst:DoTaskInTime(1, function(inst)
		SpawnBunch(inst,"boulder_crab","rock2_hotspring")
		inst:Remove()
	end)

    return inst
end

local function fnarenaturfer()
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

    inst:DoTaskInTime(1, function(inst)
		local x,y,z = inst.Transform:GetWorldPosition()
		local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)

		
		-- Square
		for i = -7,7 do
			for j = -7,7 do
				TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_YELLOWROCK)
			end
		end
		
		-- little extra
		for i = -8,8 do
			for j = -5,5 do
				TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_YELLOWROCK)
			end
		end
		
		-- little extra
		for i = -5,5 do
			for j = -8,8 do
				TheWorld.Map:SetTile(tx+i,tz+j,WORLD_TILES.UM_HOTSPRING_YELLOWROCK)
			end
		end
	end)

    return inst
end


return	Prefab("hotspring_dragonfly_areana_turfer",fnarenaturfer), 
Prefab("hotspring_rockbuncher_flintless",fnbunchflintless),
Prefab("hotspring_rockbuncher_gold",fnbunchgold),
Prefab("hotspring_rockbuncher_crabs",fnbunchcrabs),
Prefab("rock1_hotspring",fn1),
Prefab("rock2_hotspring",fn2),
Prefab("rock_flintless_hotspring",fn3),
Prefab("magma_rockbuncher",fnbunchmagma),
Prefab("rock_magma",fnmagma1),
Prefab("pool_magma",fnmagma2)

local function LargeFernCheck(x,y,z)
	local plants = #TheSim:FindEntities(x,y,z,2.3,{"plant"})
	local sculpture = #TheSim:FindEntities(x,y,z,7,{"heavy"})-- The spacing for the sculpture is larger so it doesn't cover them up 
	local sinkhole_bockers = #TheSim:FindEntities(x,y,z,7,{"antlion_sinkhole_blocker"})
	if plants > 0 or sculpture > 0 or sinkhole_bockers > 0 then
		return true
	end
end

local function Populate(inst,tile,plant)
	local x,y,z = inst.Transform:GetWorldPosition()
	for i = -15, 15, 0.5 do
		for j = -15, 15, 0.5 do
			local to_spawn
			if plant == "um_pyre_nettles_stage_" then -- There is variance for pyre nettles
				to_spawn = plant..math.random(1,5)
			else
				to_spawn = plant
			end
			local x1 = x + i + math.random(-1,1)/math.random(2,4)
			local z1 = z + j + math.random(-1,1)/math.random(2,4)
			if TheWorld.Map:GetTileAtPoint(x1, y, z1) == tile and not LargeFernCheck(x1,y,z1) then
				SpawnPrefab(to_spawn).Transform:SetPosition(x1,y,z1)
			end
		end
	end
	inst:Remove()
end


local function fnthicket()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:DoTaskInTime(0,function(inst)
		Populate(inst,WORLD_TILES.HOODEDFOREST_FOLIAGE_DARK,"hooded_fern")
	end)
	
	return inst
end

local function fnpyrethicket()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:DoTaskInTime(0,function(inst)
		Populate(inst,WORLD_TILES.UM_GRASSMAGMA,"um_pyre_nettles_stage_")
	end)
	
	return inst
end


return Prefab("thicket_builder", fnthicket),
Prefab("pyrethicket_builder",fnpyrethicket)
	

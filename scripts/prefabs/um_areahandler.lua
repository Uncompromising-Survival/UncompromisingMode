--for emptying the area around.
local function ClearSeastacks(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local things = TheSim:FindEntities(x,y,z, 80, nil, {"sirenpoint", "umss_utw_inactivebiome", "umss_utw_activebiome"}, {"seastack"})
	for k, v in ipairs(things) do
		v:Remove()
	end
end

--for when an active biome spawns
local function ClearInactiveBiome(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local inactive_biome = TheSim:FindEntities(x,y,z, 80, {"umss_utw_inactivebiome"})
	for k, v in ipairs(inactive_biome) do
		v:Remove()
	end
end

--for clearing an active biome
local function ClearActiveBiome(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local inactive_biome = TheSim:FindEntities(x,y,z, 80, {"umss_utw_activebiome"})
	for k, v in ipairs(inactive_biome) do
		v:Remove()
	end
end

local function SpawnSiren(inst)
	ClearInactiveBiome(inst)--for replacing
	ClearActiveBiome(inst)
	--TheNet:Announce("spawn siren")
	local x,y,z = inst.Transform:GetWorldPosition()

	if inst.sirenpoint == "ocean_speaker" then
		local biome = SpawnPrefab("umss_activebiome_test_rr")
		biome.Transform:SetPosition(x,y,z)
	elseif inst.sirenpoint == "siren_bird_nest" then
		local biome = SpawnPrefab("umss_activebiome_cbts_bb")
		biome.Transform:SetPosition(x,y,z)
	elseif inst.sirenpoint == "siren_throne" then
		local biome = SpawnPrefab("umss_activebiome_cbts_ss")
		biome.Transform:SetPosition(x,y,z)
	end
end

local function SpawnInactive(inst)
	ClearActiveBiome(inst)--for replacing
	ClearInactiveBiome(inst)
	--TheNet:Announce("spawn innactive")
	local x,y,z = inst.Transform:GetWorldPosition()
	local test = SpawnPrefab("umss_inactivebiome_cbts_sludge")
	test.Transform:SetPosition(x,y,z)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

	inst:AddTag("areahandler")
	inst:AddTag("CLASSIFIED")
	inst:AddTag("ignorewalkableplatforms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.sirenpoint = nil

	inst:ListenForEvent("generate_inactive", SpawnInactive)
	inst:ListenForEvent("generate_main", SpawnSiren)
	--inst:ListenForEvent("clear", Clear)

	inst:DoTaskInTime(0,ClearSeastacks)

	if not table.contains(TheWorld.components.um_areahandler.handlers, inst) then
		table.insert(TheWorld.components.um_areahandler.handlers, inst)
	end

    return inst
end

return Prefab("um_areahandler", fn)

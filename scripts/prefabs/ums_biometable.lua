local DecidTable = {
	
	umss_shyTable = 1,
	umss_moxTable = 0.25,
	
}
local DesertTable = {

	umss_sussyTable = 1,

}
local MarshTable = {

	umss_fooltrap1Table = 1,
	umss_swamplake = 1,
	
}
local HoodedTable = {

	umss_ancientwalrusTable = 1,
	
}
local DarkForestTable = {

	umss_walterifgoodTable = 1,
	
}
local RockyTable = {

	umss_singlefather = 1,
	
}
local SavannaTable = {

	umss_sos = 1,
	umss_moxTable = 0.25,

}
local GeneralTable = {

	umss_badfarmerTable = 1,
	umss_moxTable = 0.25,
	umss_sos = 0.1,
	
}

local function SpavvnBiomeUMSS(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
	local umss
	
	if tile == WORLD_TILES.MARSH then
		umss = weighted_random_choice(MarshTable)
	end
	if tile == WORLD_TILES.HOODEDFOREST then
	
		umss = weighted_random_choice(HoodedTable)
	end
	if tile == WORLD_TILES.DESERT_DIRT then
		umss = weighted_random_choice(DesertTable)
	end
	if tile == WORLD_TILES.DECIDUOUS then
		umss = weighted_random_choice(DecidTable)
	end
	if tile == WORLD_TILES.FOREST then
		umss = weighted_random_choice(DarkForestTable)
	end
	if tile == WORLD_TILES.SAVANNA then
		umss = weighted_random_choice(SavannaTable)
	end
	if tile == WORLD_TILES.ROCKY then
		umss = weighted_random_choice(RockyTable)
	end	
	if not umss then
		umss = weighted_random_choice(GeneralTable)
	end
	SpawnPrefab(umss).Transform:SetPosition(x,y,z)
	inst:Remove()
end


local function makefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()
		
    if not TheWorld.ismastersim then
        return inst
    end
	inst:DoTaskInTime(0,SpavvnBiomeUMSS)
    return inst
end

return Prefab("ums_biometable", makefn)


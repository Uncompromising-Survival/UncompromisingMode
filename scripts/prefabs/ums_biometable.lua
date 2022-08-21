local DecidTable = {
	
	shyTable = 1,
	
}
local DesertTable = {

	sussyTable = 1,

}
local MarshTable = {

	fooltrap1Table = 1,
	
}
local HoodedTable = {

	ancientwalrusTable = 1,
	
}
local DarkForestTable = {

	walterifgoodTable = 1,
	
}
local RockyTable = {

	singlefather = 1,

}
local SavannaTable = {

	sos = 1,
	moxTable = 0.25,
	deadBodies = 2,
	
}
local GeneralTable = {
	badfarmerTable = 1,
	baseFrag_smellyKitchen = 0.5,
	baseFrag_rattyStorage = 0.5,
	moonOil = 1,
}

local function AddToTheWorld(inst,umss)
	table.insert(TheWorld.umsetpieces,umss)
end

local function FinalizeSpavvn(inst,umss,x,y,z)
	local spavvner = SpawnPrefab("umss_general")
	spavvner.DefineTable(spavvner,umss)
	spavvner.Transform:SetPosition(x,y,z)
	AddToTheWorld(inst,umss)
	inst:Remove()
end

local function SpavvnBiomeUMSS(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
	local umss
	local Table
	
	if tile == WORLD_TILES.MARSH and weighted_random_choice(inst.MarshTable) then
		Table = inst.MarshTable
		umss = weighted_random_choice(Table) 
	end
	if tile == WORLD_TILES.HOODEDFOREST and weighted_random_choice(inst.HoodedTable) then
		Table = inst.HoodedTable
		umss = weighted_random_choice(Table)
	end
	if tile == WORLD_TILES.DESERT_DIRT and weighted_random_choice(inst.DesertTable) then
		Table = inst.DesertTable
		umss = weighted_random_choice(Table)
	end
	if tile == WORLD_TILES.DECIDUOUS and weighted_random_choice(inst.DecidTable) then
		Table = inst.DecidTable
		umss = weighted_random_choice(Table)
	end
	if tile == WORLD_TILES.FOREST and weighted_random_choice(inst.DarkForestTable)then
		Table = inst.DarkForestTable
		umss = weighted_random_choice(Table)
	end
	if tile == WORLD_TILES.SAVANNA and weighted_random_choice(inst.SavannaTable) then
		Table = inst.SavannaTable
		umss = weighted_random_choice(Table)
	end
	if tile == WORLD_TILES.ROCKY and weighted_random_choice(inst.RockyTable) then
		Table = inst.RockyTable
		umss = weighted_random_choice(Table)
	end	
	if not umss then
		Table = inst.GeneralTable
		umss = weighted_random_choice(Table)
	end
	if not TheWorld.umsetpieces then
		TheWorld.umsetpieces = {}
	end
	
	
	for i,v in ipairs(TheWorld.umsetpieces) do
		if v == umss then
			for i,v in ipairs(Table) do
				if v == umss then
					table.remove(Table,i)
				end
			end
			if inst.count > 3 then
				inst:Remove()
			else				
				inst.fail = true
				inst.count = inst.count+1
			end
		end
	end
	if not inst.fail then
		FinalizeSpavvn(inst,umss,x,y,z)
	else
		inst.fail = nil
		SpavvnBiomeUMSS(inst)
	end
end


local function makefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()
		
    if not TheWorld.ismastersim then
        return inst
    end
	inst.DecidTable = DecidTable
	inst.DesertTable = DesertTable
	inst.MarshTable = MarshTable
	inst.HoodedTable = HoodedTable
	inst.DarkForestTable = DarkForestTable
	inst.RockyTable = RockyTable
	inst.SavannaTable = SavannaTable
	inst.GeneralTable = GeneralTable
	
	
	inst.count = 0
	inst:DoTaskInTime(0,SpavvnBiomeUMSS)
    return inst
end

return Prefab("ums_biometable", makefn)


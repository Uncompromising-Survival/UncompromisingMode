local GroundTiles = 
{
	[WORLD_TILES.HOODEDFOREST] = 	{name = "hoodedmoss", 	anim = "hoodedmoss", 	bank_build = "hfturf"},
	[WORLD_TILES.ANCIENTHOODEDFOREST] = 	{name = "ancienthoodedturf", 	anim = "ancienthoodedturf", 	bank_build = "hfturf"},
	
	-- broiling hills
	[WORLD_TILES.UM_HOTSPRING_GRASS] = 	{name = "um_hotspring_grass", 	anim = "um_hotspring_grass", 	bank_build = "hfturf"},
	[WORLD_TILES.UM_HOTSPRING_YELLOWROCK] = 	{name = "um_hotspring_yellowrock", 	anim = "um_hotspring_yellowrock", 	bank_build = "hfturf"},
	[WORLD_TILES.UM_HOTSPRING_WHITEROCK] = 	{name = "um_hotspring_whiterock", 	anim = "um_hotspring_whiterock", 	bank_build = "hfturf"},	
	
	-- lava caves [need art]
	[WORLD_TILES.UM_MAGMA] = 	{name = "um_hotspring_whiterock", 	anim = "um_hotspring_whiterock", 	bank_build = "hfturf"},
	[WORLD_TILES.UM_MAGMA_LAVABORDER] = 	{name = "um_hotspring_whiterock", 	anim = "um_hotspring_whiterock", 	bank_build = "hfturf"},
	[WORLD_TILES.UM_GRASSMAGMA] = 	{name = "um_hotspring_grass", 	anim = "um_hotspring_grass", 	bank_build = "hfturf"},
}

local assets =
{
	Asset("ANIM", "anim/hfturf.zip"),
}

local prefabs =
{
	"gridplacer",
}

local function make_turf(tile, data)
	local function ondeploy(inst, pt, deployer)
		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
		end
		local map = TheWorld.Map
		local x, y = map:GetTileCoordsAtPoint(pt:Get())
		map:SetTile(x, y, tile)
		inst.components.stackable:Get():Remove()
	end
	
	local function fn()
		local inst = CreateEntity()
		
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		
		MakeInventoryPhysics(inst)
		
		inst.AnimState:SetBank(data.bank_build)
		inst.AnimState:SetBuild(data.bank_build)
		inst.AnimState:PlayAnimation(data.anim)
		
		inst:AddTag("groundtile")
		inst:AddTag("molebait")
		
		MakeInventoryFloatable(inst, "med", nil, 0.65)
		
		inst.entity:SetPristine()
		
		if not TheWorld.ismastersim then
			return inst
		end
		
		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
		
		inst:AddComponent("inspectable")
		
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = "images/inventoryimages/turf_"..data.name..".xml"
		
		inst:AddComponent("bait")
		
		inst:AddComponent("fuel")
		inst.components.fuel.fuelvalue = TUNING.MED_FUEL
		MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
		MakeSmallPropagator(inst)
		MakeHauntableLaunchAndIgnite(inst)
		
		inst:AddComponent("deployable")
		inst.components.deployable:SetDeployMode(DEPLOYMODE.TURF)
		inst.components.deployable.ondeploy = ondeploy
		inst.components.deployable:SetUseGridPlacer(true)

		return inst
	end
	
	return Prefab("turf_"..data.name, fn, assets, prefabs)
end

local ret = {}

for k, v in pairs(GroundTiles) do
	table.insert(ret, make_turf(k, v))
end

return unpack(ret)
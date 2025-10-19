require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/pitcher.zip"),
	Asset("ANIM", "anim/bee_box_hermitcrab.zip"),
	Asset("MINIMAP_IMAGE", "beebox_hermitcrab"),
}

local prefabs =
{
	"fruitbat",
	"honey",
}

SetSharedLootTable('pitcherplant', {
	{ 'honey', 1 },
})

local function onchildgoinghome(inst, data)
	if data.child ~= nil and data.child.bugcount ~= nil then
		inst.count = data.child.bugcount
	end
end

local function onsave(inst, data)
	data.count = inst.count
end

local function onload(inst, data)
	if data ~= nil and data.count ~= nil then
		inst.count = data.count
	end
end

local function UpdateSpawning(inst)
	if inst.components.childspawner == nil then return end

	if TheWorld.state.isday and not TheWorld.state.iswinter then
		inst.components.childspawner:StartSpawning()
	else
		inst.components.childspawner:StopSpawning()
	end
end

local function OnInit(inst)
	inst:WatchWorldState("isday", UpdateSpawning)
	inst:WatchWorldState("iswinter", UpdateSpawning)
	UpdateSpawning(inst)
end

local function onspawnbat(inst, bat)
	if bat and bat.sg then
		bat.sg:GoToState("flyback")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
	inst.entity:AddLightWatcher()

	inst.MiniMapEntity:SetIcon("pitcher.tex")

	inst.AnimState:SetBank("pitcher")
	inst.AnimState:SetBuild("pitcher")
	inst.AnimState:PlayAnimation("swinglong", true)

	inst:AddTag("pitcherplant")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "fruitbat"
	inst.components.childspawner:SetMaxChildren(1)
	inst.components.childspawner:SetRegenPeriod(60 * 8)
	inst.components.childspawner:SetSpawnPeriod(30)
	inst.components.childspawner:SetSpawnedFn(onspawnbat)
	inst.components.childspawner.allowwater = true

	inst:ListenForEvent("childgoinghome", onchildgoinghome)

	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("pitcherplant")

	inst.count = 0
	inst.OnSave = onsave
	inst.OnLoad = onload

	inst:DoTaskInTime(0, OnInit)

	return inst
end

return Prefab("pitcherplant", fn, assets, prefabs)

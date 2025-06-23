local assets =
{
    Asset("ANIM", "anim/um_hat_bee_moon.zip"),
    Asset("ATLAS", "images/inventoryimages/widowshead.xml"),
    Asset("IMAGE", "images/inventoryimages/widowshead.tex"),
}
local BEAVERVISION_COLOURCUBES =
{
    day = "images/colour_cubes/beaver_vision_cc.tex",
    dusk = "images/colour_cubes/beaver_vision_cc.tex",
    night = "images/colour_cubes/beaver_vision_cc.tex",
    full_moon = "images/colour_cubes/beaver_vision_cc.tex",
}

local function SpawnBeeVsOther(inst,data)
	local bee = SpawnPrefab("um_bee_moon")
	bee.Transform:SetPosition(inst.Transform:GetWorldPosition())
	bee.components.combat:SetRetargetFunction(3, nil)
	bee.components.combat:SetKeepTargetFunction(function(bee) return true end)
	bee:AddComponent("follower")
	inst.components.leader:AddFollower(bee)
	bee.components.combat:SuggestTarget(data.target)
	bee:RemoveComponent("lootdropper")
	bee:AddComponent("lootdropper") -- wipe the lootdropper component
	bee.persists = false -- temp minion, no save/load
	bee:RemoveComponent("workable")
end

local function AttackOther(inst,data)
	inst.um_hat_bee_moon_count = inst.um_hat_bee_moon_count + 1
	if inst.um_hat_bee_moon_count > 3 and data.target and data.target.components.health and data.target.components.health:GetMaxWithPenalty() > 50 then
		inst.um_hat_bee_moon_count = 0
		SpawnBeeVsOther(inst,data)
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "um_hat_bee_moon", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
    end
	owner.um_hat_bee_moon_count = 0
	owner:ListenForEvent("onattackother", AttackOther)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end
	owner:RemoveEventCallback("onattackother", AttackOther)
end



local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("catcoonhat")
    inst.AnimState:SetBuild("um_hat_bee_moon")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("donotautopick")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
	
    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.dapperness = TUNING.CRAZINESS_SMALL
	

	inst:AddComponent("insulator")
	inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
	
    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime((4 * TUNING.PERISH_TWO_DAY))
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
	
    MakeHauntableLaunch(inst)
    --------------------------------------------------------------

    return inst
end


return Prefab("um_hat_bee_moon", fn, assets)

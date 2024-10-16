local assets =
{
    Asset("ANIM", "anim/snapalm.zip"),
	Asset("ATLAS", "images/inventoryimages/snapalm.xml"),
	Asset("IMAGE", "images/inventoryimages/snapalm.tex"),
}

local prefabs =
{
    "explode_small",
    "snaildrake_magma_sludge",
}

TUNING.SNAPALM_EXPLODE_DAMAGE = 50
TUNING.SNAPALM_BURN_TIME = 2
TUNING.SNAPALM_BURN_TIME_VARIANCE = 1

local function OnExplodeFn(inst)
    inst.SoundEmitter:KillSound("hiss")
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("explode_small").Transform:SetPosition(x, y, z)
    SpawnPrefab("snaildrake_magma_sludge").Transform:SetPosition(x, y, z)
end

local function fn()
    local inst = Prefabs.slurtleslime.fn()

	inst.AnimState:SetBank("snapalm")
	inst.AnimState:SetBuild("snapalm")
	inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

	inst.components.inventoryitem.atlasname = "images/inventoryimages/snapalm.xml"
	
    inst.components.burnable:SetBurnTime(TUNING.SNAPALM_BURN_TIME + math.random() * TUNING.SNAPALM_BURN_TIME_VARIANCE)

    inst.components.explosive:SetOnExplodeFn(OnExplodeFn)
    inst.components.explosive.explosivedamage = TUNING.SNAPALM_EXPLODE_DAMAGE

    return inst
end

return Prefab("snapalm", fn, assets, prefabs)

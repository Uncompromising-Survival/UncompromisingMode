local assets = {
    Asset("ANIM", "anim/um_magnifier.zip"),
    Asset("ANIM", "anim/um_magnifier_obsidian.zip"),
    Asset("ANIM", "anim/um_magnifier_purplegem.zip"),
}

function CreateManifier(name, durability, build, bank, common_fn)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBuild(build ~= nil and build or name)
        inst.AnimState:SetBank(bank ~= nil and bank or name)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("gemologyscanner")
        inst:AddTag("tradeable")
        inst:AddTag("wardrobe_item")

        MakeInventoryFloatable(inst, "med", nil, 0.6)

        inst.entity:SetPristine()

        if common_fn ~= nil then
            common_fn(inst)
        end

        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("gemologyscanner")
        --inst.components.gemologyscanner:SetOnScannedFn(OnScanned)

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetOnFinished(inst.Remove)
        inst.components.finiteuses:SetMaxUses(durability)
        inst.components.finiteuses:SetUses(durability)
        inst.components.finiteuses:SetConsumption(ACTIONS.SCAN_GEMOLOGY_GEM, 1)

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end

return CreateManifier("um_magnifier", 100),
    CreateManifier("um_magnifier_obsidian", 100, "um_magnifier_obsidian", "um_magnifier_obsidian"),
    CreateManifier("um_magnifier_purplegem", 25, "um_magnifier_purplegem", "um_magnifier_purplegem")

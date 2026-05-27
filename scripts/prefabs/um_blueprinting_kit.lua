local assets = {
    Asset("ANIM", "anim/blueprinting_kit.zip"),
}

function CreateBlueprintingKit(name, durability, build, bank, common_fn)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBuild(build ~= nil and build or name)
        inst.AnimState:SetBank(bank ~= nil and bank or name)
        inst.AnimState:PlayAnimation("idle")

        --from blueprinter component
        inst:AddTag("blueprinter")

        MakeInventoryFloatable(inst, "med", nil, 0.6)

        inst.entity:SetPristine()

        if common_fn ~= nil then
            common_fn(inst)
        end

        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")

        inst:AddComponent("blueprinter")
        inst.components.blueprinter:SetOnUsedFn(function(inst, target, owner, recipe)
            if inst.components.finiteuses ~= nil then
                inst.components.finiteuses:Use(1)
            end
        end)

        inst:AddComponent("finiteuses")
        inst.components.finiteuses:SetOnFinished(inst.Remove)
        inst.components.finiteuses:SetMaxUses(durability)
        inst.components.finiteuses:SetUses(durability)

        MakeHauntableLaunch(inst)

        return inst
    end

    return Prefab(name, fn, assets)
end

return CreateBlueprintingKit("um_blueprinting_kit", 2, "blueprinting_kit", "blueprinting_kit")

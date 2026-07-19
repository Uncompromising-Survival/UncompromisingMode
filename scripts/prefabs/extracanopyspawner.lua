require "prefabutil"
local CANOPY_SHADOW_DATA = require("prefabs/giant_tree_canopy")

local function removecanopyshadow(inst)
    if inst.canopy_data ~= nil then
        for _, shadetile_key in ipairs(inst.canopy_data.shadetile_keys) do
            if TheWorld.hooded_forest_shadetiles[shadetile_key] ~= nil then
                TheWorld.hooded_forest_shadetiles[shadetile_key] = TheWorld.hooded_forest_shadetiles[shadetile_key] - 1

                if TheWorld.hooded_forest_shadetiles[shadetile_key] <= 0 then
                    if TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key] ~= nil then
                        DespawnHoodedforestCanopy(TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key])
                        TheWorld.shadetile_key_to_hooded_forest_canopy_id[shadetile_key] = nil
                    end
                end
            end
        end

        for _, ray in ipairs(inst.canopy_data.lightrays) do
            ray:Remove()
        end
    end
end

local function OnRemoveEntity(inst)
    inst._hascanopy:set(false)
end

local function makefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddDynamicShadow()
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("shadecanopysmall")

    if not TheNet:IsDedicated() then
        local distancefade = inst:AddComponent("distancefade")
        distancefade:Setup(15, 25)

        local canopyshadows = inst:AddComponent("canopyshadows")
        canopyshadows.range = math.floor(TUNING.SHADE_CANOPY_RANGE_SMALL / 4)
		canopyshadows.um_canopyshadows = true

        inst:ListenForEvent("hascanopydirty", function()
            if not inst._hascanopy:value() then
                inst:RemoveComponent("canopyshadows")
            end
        end)
    end

    inst._hascanopy = net_bool(inst.GUID, "extracanopyspawner._hascanopy", "hascanopydirty")
    inst._hascanopy:set(true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnRemoveEntity = OnRemoveEntity

    return inst
end

return Prefab("extracanopyspawner", makefn)

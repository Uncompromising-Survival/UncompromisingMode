local EDIBLES =
{
    "mosquito",
    "bee",
    "killerbee",
    "butterfly",
    "moonbutterfly",
    "aphid",
    "fruitfly",
    "lightflier",
}

local function IsEdibleToTarget(inst, target)
    return target and target:HasAnyTag("OMNI_eater", "INSECT_eater", "compostingbin_accepts_items")
        and (not target:HasTag("player") or target.prefab == "waxwell" or target.replica.inventory and target.replica.inventory:EquipHasTag("um_insect_eater"))
end

local function AddEdibles(prefab)
    AddPrefabPostInit(prefab, function(inst)
        inst.UMIsEdibleToTarget = IsEdibleToTarget

        if not GLOBAL.TheWorld.ismastersim then return end

        local edible = inst.components.edible or inst:AddComponent("edible")
        edible.healthvalue = 5
        edible.hungervalue = 5
        edible.sanityvalue = -TUNING.SANITY_SMALL
        edible.foodtype = FOODTYPE.INSECT
    end)
end

for k, v in pairs(EDIBLES) do
    AddEdibles(v)
end

AddComponentPostInit("eater", function(self)
    local _PrefersToEat = self.PrefersToEat
    function self:PrefersToEat(food, ...)
        if food.UMIsEdibleToTarget and not food:UMIsEdibleToTarget(self.inst) then return false end
        return _PrefersToEat(self, food, ...)
    end
end)

local function IsAnActiveItemAndMounted(inst, doer)
    local rider = doer.replica.rider
    local mount = rider and rider:GetMount() or nil
    local isactiveitem = doer.replica.inventory and doer.replica.inventory:GetActiveItem() == inst
    return mount and (isactiveitem or (not right and doer.components.playercontroller.isclientcontrollerattached)) and inst:UMIsEdibleToTarget(mount)
end

local UpvalueHacker = require("tools/upvaluehacker")
AddSimPostInit(function()
    local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(GLOBAL.EntityScript.CollectActions, "COMPONENT_ACTIONS")
    if COMPONENT_ACTIONS then
        local USEITEM, INVENTORY = COMPONENT_ACTIONS.USEITEM, COMPONENT_ACTIONS.INVENTORY
        if USEITEM then
            local _USEITEM_edible_fn = USEITEM["edible"]
            if _USEITEM_edible_fn then
                USEITEM["edible"] = function(inst, doer, target, actions, right, ...)
                    if inst.UMIsEdibleToTarget and not inst:UMIsEdibleToTarget(target) then return end
                    return _USEITEM_edible_fn(inst, doer, target, actions, right, ...)
                end
            end
        end
        if INVENTORY then
            local _INVENTORY_edible_fn = INVENTORY["edible"]
            if _INVENTORY_edible_fn then
                INVENTORY["edible"] = function(inst, doer, actions, right, ...)
                    if inst.UMIsEdibleToTarget and not (IsAnActiveItemAndMounted(inst, doer) or inst:UMIsEdibleToTarget(doer)) then return end
                    return _INVENTORY_edible_fn(inst, doer, actions, right, ...)
                end
            end
            local _INVENTORY_health_fn = INVENTORY["health"]
            if _INVENTORY_health_fn then
                INVENTORY["health"] = function(inst, doer, actions, ...)
                    if inst.UMIsEdibleToTarget and (IsAnActiveItemAndMounted(inst, doer) or inst:UMIsEdibleToTarget(doer)) and doer.components.playercontroller and doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) then return end
                    return _INVENTORY_health_fn(inst, doer, actions, ...)
                end
            end
            local _INVENTORY_murderable_fn = INVENTORY["murderable"]
            if _INVENTORY_murderable_fn then
                INVENTORY["murderable"] = function(inst, doer, actions, ...)
                    if inst.UMIsEdibleToTarget and (IsAnActiveItemAndMounted(inst, doer) or inst:UMIsEdibleToTarget(doer)) and doer.components.playercontroller and doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) then return end
                    return _INVENTORY_murderable_fn(inst, doer, actions, ...)
                end
            end
        end
    end
end)
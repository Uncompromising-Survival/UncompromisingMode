local function DoDurabilityLoss(item, num)
    item.components.minerologyable:DoDelta(-num)
end


--[[
Note(Atobá):
The key is the prefab name of the gem.

The values are:
{
    onattackfn = function(item, attacker, target, tier) --function that runs when you hit an enemy
    onupdatefn = function(item, tier) --function that runs every second
    onapplyfn = function(item, owner, tier) -- function that runs when you apply the gem to an item
    onremovefn = function(item, owner, tier) -- function that runs when you remove the gem from an item
    onworkfn = function(item, owner, target, tier) -- function that runs when you chop/mine/dig/etc
    onequipfn = function(item, owner, tier) -- function that runs when you equip the item with the gem
    onunequipfn = function(item, owner, tier) -- function that runs when you unequip the item with the gem
    color = RGB(r,g,b) --color for the text/durability border in the UI
}

Additional note:

Every gemolyable item has a field called gemology_data, with holds any relevant data for gems. For example:
item.gemology_data[gem_name].foo = true

This is so we can save some gem-specific data so it can properly revert when removed.
]]
local GEMOLOGY_DEFS = {
    -------------
    --BLUE GEMS--
    -------------
    ["um_gemologybluegem1"] = {
        onattackfn = function(item, attacker, target, tier)
            if target.components.freezable then
                target.components.freezable:AddColdness(0.15 * tier)
                target.components.freezable:SpawnShatterFX()
                if target.sg and target.sg:HasStateTag("frozen") and math.random() < (tier - 1) * 0.25 and tier ~= 1 then
                    target:DoTaskInTime(0, function(inst) -- immediate refreeze
                        target.components.freezable:AddColdness(999)
                    end)
                end
                --item.components.minerologyable:DoDelta(-0.0125)
            end
        end,
        onapplyfn = function(item, owner, tier)
            if not item.components.insulator then
                item:AddComponent("insulator")
            else
                item.gemology_data.um_gemologybluegem1.already_insulator = true
                item.gemology_data.um_gemologybluegem1.prev_insulation = item.components.insulator.insulation
                item.gemology_data.um_gemologybluegem1.prev_insul_type = item.components.insulator.type
            end

            item.components.insulator:SetSummer()
            item.components.insulator:SetInsulation(TUNING.INSULATION_SMALL * tier) -- Note (Axe):A bit too easy...
        end,
        onremovefn = function(item, owner, tier)
            if not item.gemology_data.um_gemologybluegem1.already_insulator then
                item:RemoveComponent("insulator")
            else
                item.components.insulator.insulation = item.gemology_data.um_gemologybluegem1.prev_insulation
                item.components.insulator.type = item.gemology_data.um_gemologybluegem1.prev_insul_type
            end
        end,
        color = RGB(163, 194, 244)
    }
}

return GEMOLOGY_DEFS

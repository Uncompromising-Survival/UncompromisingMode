local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local function NightArmorFunctions(inst)
    if inst.components.armor then
        local _OnTakeDamage = inst.components.armor.ontakedamage
        local function OnTakeDamage(inst, damage_amount, ...)
            local owner = inst.components.inventoryitem.owner
            if owner and owner:HasTag("Funny_Words_Magic_Man") then
                local sanity = owner.components.sanity
                if sanity then
                    local unsaneness = damage_amount * TUNING.ARMOR_SANITY_DMG_AS_SANITY
                    unsaneness = unsaneness  * .8 -- Cutting it by this much because of the fact that you're giving up your headslot, which is usually VERY important for using night armor so you can extend its small durability.
                    sanity:DoDelta(-unsaneness, false)
                end
            else
                return _OnTakeDamage(inst, damage_amount, ...)
            end
        end
        inst.components.armor.ontakedamage = OnTakeDamage
    end

    if inst.components.equippable then
        local function CalcDapperness(inst, owner)
            return TUNING.CRAZINESS_SMALL * (owner:HasTag("Funny_Words_Magic_Man") and .8 or 1) -- This ends up being about -5/min + 3.3/min from the hat itself, willing to cut it more for this one
        end
        inst.components.equippable.dapperfn = CalcDapperness
    end
end

env.AddPrefabPostInit("armor_sanity", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    NightArmorFunctions(inst)
end)
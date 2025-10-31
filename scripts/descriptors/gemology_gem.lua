local gemMap = {
    --gem name, effect description
    um_gemologybluegem1 = {
        "Gives summer insulation when held and freezes enemies on hit.",
        "Gives summer insulation when held and freezes enemies on hit.\nHas a chance to not break free fully frozen enemies.",
        "Gives summer insulation when held and freezes enemies on hit.\nHas a high chance to not break free fully frozen enemies.",
    }, --
    um_gemologybluegem2 = {
        "Converts durability into freshness. Can be fully preserved in an ice box.",
        "Converts durability into freshness. Can be fully preserved in an ice box.\nIf the item is already perishable, extends their freshness and allows them to be fully preserved.",
        "Converts durability into freshness. Can be fully preserved in an ice box.\nIf the item is already perishable, greatly extends their freshness and allows them to be fully preserved.",
    },
    um_gemologyredgem1 = {
        "Killing enemies restores health and sanity.",
        "Killing enemies restores health and sanity.\nHas a chance to feed off monsters and animals, restoring the player's hunger and increasing damage.",
        "Killing enemies restores health and sanity.\nHas a chance to feed off monsters and animals, greatly restoring the player's hunger and increasing damage.",
    },

    um_gemologyredgem2 = {
        "Deals additional fire damage.",
        "Deals additional fire damage.\nAttacking burning enemies stokes their fire and increases the item's damage.",
        "Deals additional fire damage.\nAttacking burning enemies stokes their fire and greatly increases the item's damage.",
    },
    um_gemologypurplegem1 = {
        "When hit, reduces incoming damage for a short duration.",
        "When hit, reduces incoming damage for a short duration.\nIncreases the damage of weaker weapons.",
        "When hit, reduces incoming damage for a short duration.\nGreatly Increases the damage of weaker weapons.",
    },
    um_gemologypurplegem2 = {
        "The item and another random item will remain in the inventory after death.",
        "The item and 2 random items will remain in the inventory after death.\nDirect sanity loss is reduced.",
        "The item and 3 random items will remain in the inventory after death.\nDirect sanity loss is greatly reduced.",
    },
    um_gemologyyellowgem1 = {
        "Gives the item a small amount of sanity regeneration.",
        "Gives the item a small amount of sanity regeneration.\nIncreases the effectiveness of speed boosts.",
        "Gives the item a small amount of sanity regeneration.\nGreatly increases the effectiveness of speed boosts.",
    },
    um_gemologyyellowgem2 = {
        "Adds additional electric damage, more for already electric weapons.",
        "Adds additional electric damage, more for already electric weapons.\nAttacks arc between enemies.",
        "Adds additional electric damage, more for already electric weapons.\nAttacks arc between enemies.",
    },
    um_gemologygreengem1 = {
        "Increases attack and working speed.",
        "Increases attack and working speed.\nA shadow clone will appear to assits you when attakcing or working.",
        "Increases attack and working speed.\nA shadow clone will appear to assits you when attakcing or working.",
    },

    um_gemologygreengem2 = {
        "Copies 3 random gems of the same tier.\nGems are randomized every day.",
        "Copies 3 random gems of the same tier.\nGems are randomized every day.",
        "Copies 3 random gems of the same tier.\nGems are randomized every day.",
    },
    um_gemologyorangegem1 = {
        "Gives the item increased movement speed if the player is slowed down.",
        "Gives the item increased movement speed if the player is slowed down.\nIncreases the speed of various actions.", --I aint writing allat.
        "Gives the item increased movement speed if the player is slowed down.\nIncreases the speed of various actions.",
    },
    um_gemologyorangegem2 = {
        "Gives the item sanity regeneration based on occupied inventory slots.",
        "Gives the item sanity regeneration based on occupied inventory slots.\nSlain enemies and worked objects teleport their loot directly to the user.",
        "Gives the item sanity regeneration based on occupied inventory slots.\nSlain enemies and worked objects teleport their loot directly to the user.",
    },
    um_gemologypalegem1 = {
        "Further increases damage buffs.",
        "Further increases damage buffs.\nIf the item is not craftable, increases damage.",
        "Further increases damage buffs.\nIf the item is not craftable, greatly increases damage.",
    },

    um_gemologypalegem2 = {
        "Doubles item durability.",
        "Tripes item durability.\nIf the item is not prototypeable, adds a chance to not consume durability on use.",
        "Quadruples item durability.\nIf the item is not prototypeable, adds a chance to not consume durability on use.",
    },
}

local function Describe(self, context)
    local description = nil

    --offset tier for stupid lua tables starting at 1 grrrr
    local tier = self.inst.tier ~= nil and self.inst.tier + 1 or 1

    description = "When applied to an item:\n " .. gemMap[self.inst.prefab][tier] .. "\nQuality: " .. tier

    return {
        priority = 0,
        description = description,
        append = true
    }
end

return {
    Describe = Describe,
}

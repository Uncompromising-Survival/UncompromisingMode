local env = env
GLOBAL.setfenv(1, GLOBAL)

local scrapbook_prefabs = require("scrapbook_prefabs")
local scrapbookdata = require("screens/redux/scrapbookdata")

local UM_SCRAPBOOK_DEFS = require("screens/redux/um_scrapbookdata")

for k, v in pairs(UM_SCRAPBOOK_DEFS) do
    if v.anim ~= nil then
        v.name = v.name or k
        v.prefab = k
        v.tex = v.tex or k .. ".tex"
        v.type = v.type or "thing"
        v.deps = v.deps or {}
        v.notes = v.notes or {}

        scrapbook_prefabs[k] = true
        scrapbookdata[k] = v
    end
end

local S = STRINGS.SCRAPBOOK.SPECIALINFO

local specinfo = {
    RAT_WHIP = "Stronger when the user is well fed.",
    AIR_CONDITIONER = "Can crush up Mushrooms for helpful stat clouds.",
    ANCIENT_AMULET_RED = "Drops soul orbs when attacked, which will replenish lost health when picked up.\nRevives players when haunted.",
    ARMOR_GLASSMAIL = "Summons spinning Glass Shards when attacking enemies. Loses shards when damage is taken.",
    SALTPACK = "Drops piles of salt, preventing buildup of Snow Piles.",
    SPOREPACK = "Provides lots of storage space.\nRots food, but refreshes Spores.",
    UM_BEAR_TRAP_EQUIPPABLE_TOOTH =
    "Slows down anything it's attached to.\nDeployable and throwable.\n- Has multiple uses.",
    UM_BEAR_TRAP_EQUIPPABLE_GOLD =
    "- Slows down anything it's attached to.\n- Deployable and throwable.\n- Has even more uses.",
    WATERMELON_LANTERN = "- Has a positive sanity aura.",
    HAT_RATMASK = "- Finds rat burrows\n- Shows sources of unwanted attention.",
    SKULLCHEST_CHILD = "- Shares its contents with other Skull Chests.",
    SNOWGOGGLES = "- Grants protection against Snow Storms / Sand Storms when worn.",
    GASMASK = "- Provides protection against spore clouds.",
    PLAGUEMASK = "- Provides protection against spore clouds.",
    FLORAL_BANDAGE = "- Restores extra health over time.",
    DISEASECUREBOMB = "- Fertilizes plants and get those ready for harvest.",
    SLUDGE_OIL = "- Multi-use fuel for fires and lanterns alike.",
    ARMOR_SHARKSUIT_UM =
    "- High wetness protection. \n- Works as electrical insulation.\n- Wearer will wash ashore with no penalties.",
    HAT_CRAB = "- Repairs & sewing are twice as effective when worn.",
    HAT_CRAB_ICE = "- Resistance scales with wetness.\n- Prevents the wearer from drying up.",
    ARMOR_CRAB_MAXHP = "- Increases maximum health when worn.",
    ARMOR_CRAB_REGEN = "- Self-healing.",
    UM_ARMOR_PYRE_NETTLES = "- Panics and damages nearby miscreants.\n- Ignores tiny, shadow, or fire-aligned creatures.",
}


for k,v in pairs(specinfo) do
    S[k] = v
end
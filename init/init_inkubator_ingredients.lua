STRINGS = GLOBAL.STRINGS
STRINGS.NAMES.AMULET = "Lesser Life Amulet"
STRINGS.RECIPE_DESC.AMULET = "Protects you from death, while worn."

local env = env
GLOBAL.setfenv(1, GLOBAL)

local items = {
    nightmarefuel = "um_inkubator_fuel",
    moonglass = "um_inkubator_fuel",
    monstermeat = "um_inkubator_flesh",
    pondfish = "um_inkubator_flesh",
    moon_cap = "um_inkubator_flesh",
    drumstick = "um_inkubator_flesh",
    meat = "um_inkubator_flesh",
    smallmeat = "um_inkubator_flesh",
    slurtleslime = "um_inkubator_flesh",
    monstersmallmeat = "um_inkubator_flesh",
    plantmeat = "um_inkubator_flesh",
    giant_blueberry = "um_inkubator_flesh",
    froglegs = "um_inkubator_flesh",
    skeletonmeat = "um_inkubator_flesh",
}

for item, tag in ipairs(items) do
	env.AddPrefabPostInit(item, function(inst)
		inst:AddTag(tag)
	end)
end
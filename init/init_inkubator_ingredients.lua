local items =
{
    { item = "nightmarefuel", tag = "um_inkubator_fuel", },
    { item = "moonglass", tag = "um_inkubator_fuel", },
    { item = "wortox_soul", tag = "um_inkubator_fuel", },
    { item = "monstermeat", tag = "um_inkubator_flesh", },
    { item = "pondfish", tag = "um_inkubator_flesh", },
    { item = "moon_cap", tag = "um_inkubator_flesh", },
    { item = "drumstick", tag = "um_inkubator_flesh", },
    { item = "meat", tag = "um_inkubator_flesh", },
    { item = "smallmeat", tag = "um_inkubator_flesh", },
    { item = "slurtleslime", tag = "um_inkubator_flesh", },
    { item = "monstersmallmeat", tag = "um_inkubator_flesh", },
    { item = "plantmeat", tag = "um_inkubator_flesh", },
    { item = "giant_blueberry", tag = "um_inkubator_flesh", },
    { item = "froglegs", tag = "um_inkubator_flesh", },
    { item = "skeletonmeat", tag = "um_inkubator_flesh",},
}

for i, v in ipairs(items) do
	env.AddPrefabPostInit(v.item, function(inst)
		inst:AddTag(v.tag)
	end)
end

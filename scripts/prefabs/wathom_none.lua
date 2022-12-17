local assets =
{
	Asset( "ANIM", "anim/wathom.zip" ),
	Asset( "ANIM", "anim/ghost_wathom_build.zip" ),
}

local skins =
{
	normal_skin = "wathom",
	ghost_skin = "ghost_wathom_build",
}

return CreatePrefabSkin("wathom_none",
{
	base_prefab = "wathom",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"WATHOM", "CHARACTER", "BASE"},
	build_name_override = "wathom",
	rarity = "Character",
}),
CreatePrefabSkin("wathom_triumphant",
{
	base_prefab = "wathom",
	build_name_override = "wathom_triumphant", --The build name of your new skin,
	type = "base",
	rarity = "Elegant", --I did the Elegant Rarity, but you can do whatever rarity you want!
	rarity_modifier = "Woven", --Ive put the rarity_modifier to Woven, Doesnt make a difference other than say youve woven the skin
	skip_item_gen = true,
	skip_giftable_gen = true,
	skin_tags = { "BASE", "wathom", "SHADOW"}, --Notice in this skin_tags table I have "VICTORIAN", This tag actually makes the little gorge icon show up on the skin! Other tags will do the same thing such as forge, yotc, yotp, yotv, yog and so on!
	skins = {
		normal_skin = "wathom_triumphant", --Rename your "normal_skin" accordingly
		ghost_skin = "ghost_wathom_build", --And if you did a ghost skin, rename that too!
	},

	assets = {
		Asset( "ANIM", "anim/wathom_triumphant.zip" ),
		Asset( "ANIM", "anim/ghost_wathom_build.zip" ),
	},
})
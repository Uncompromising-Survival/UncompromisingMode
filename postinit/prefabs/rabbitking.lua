local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")


local loot_aggressive = {
    "monstermeat",
    "beardhair",
    "beardhair",
    "rabbitkingspear",
	"um_strange_rabbit_rock",
}

env.AddPrefabPostInit("rabbitking_aggressive", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.components.lootdropper:SetLoot(loot_aggressive)
end)
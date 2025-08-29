local env = env
GLOBAL.setfenv(1, GLOBAL)
local UpvalueHacker = require("tools/upvaluehacker")
-----------------------------------------------------------------

local function MakeCooker(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	

	local offset = FindWalkableOffset(inst:GetPosition(), math.random() * 2 * PI, 23, 30, true,true)

	local spawner = SpawnPrefab("umss_general")
    spawner.DefineTable(spawner, "wagstaffcooker")
    spawner.Transform:SetPosition(x+offset.x, y, z+offset.z)
    spawner.AnimState:SetMultColour(0, 0, 0, 0) -- makes it invisible too.
    spawner:AddTag("NOCLICK")
    spawner:AddTag("NOBLOCK")
    spawner:DoPeriodicTask(3, function(spawner) spawner:Remove() end) -- just in case it fails.
end


local function LookForCooker(inst)
	if not FindEntity(inst,30,function(ent) return ent.prefab == "um_cookpot_wagstaff" end) then
		MakeCooker(inst)
	end
end

local NEW_FENCE_BLUEPRINT_LOOT = "wagpunkbits_kit_blueprint"

local LAUNCHSPEED = 3
local STARTHEIGHT = 7
local VERTICALSPEED = 2
local function SpawnBlueprintLoot(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local bp = SpawnPrefab(NEW_FENCE_BLUEPRINT_LOOT)

	bp.Transform:SetPosition(x, y, z)

	--FIXME (Omar): junk pile is very tall so this is a lil awkward looking
	Launch2(bp, inst, LAUNCHSPEED, 1, STARTHEIGHT, 0, VERTICALSPEED)
end

env.AddPrefabPostInit("junk_pile_big", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	
	inst:DoTaskInTime(0,LookForCooker)
	inst.SpawnBlueprintLoot = SpawnBlueprintLoot
end)


env.AddPrefabPostInit("world", function(inst)
    local NEW_WAGPUNK_ITEMS = 
    { -- These are prefab names not their blueprints.
        "wagpunkhat",
        "armorwagpunk",
        "chestupgrade_stacksize",
        "fence_electric_item",
    }
    UpvalueHacker.SetUpvalue(Prefabs.wagstaff_machinery.fn, NEW_WAGPUNK_ITEMS, "lootsetfn", "WAGPUNK_ITEMS")
end)
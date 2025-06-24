--postinit to ALL shadow pieces, for individual pieces, see shadow_knight, shadow_rook and shadow_bishop.

local env = env
GLOBAL.setfenv(1, GLOBAL)

local pieces =
{
    "shadow_knight",
    "shadow_rook",
    "shadow_bishop"
}



for k, v in ipairs(pieces) do
    env.AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        RemovePhysicsColliders(inst)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)

		local _lootsetupfn = inst.components.lootdropper.lootsetupfn

		local function lootsetfn(lootdropper)
			_lootsetupfn(lootdropper)
			if lootdropper.inst.level >=3 then
				table.insert(lootdropper.loot,"shadow_crown")
			end
		end
		
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper:SetLootSetupFn(lootsetfn)
        end
    end)
end

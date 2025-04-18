AddPrefabPostInitAny(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return inst
	end
    if inst.components and inst.components.combat then
        inst:AddTag("wesmustdie")
    end
end)

local SPECIAL_FELLOWS = {
    buzzard = true,
    tentacle = true,
	mosquito = true,
}

local CHAOS_RADIUS = 20
local SPECIAL_RADIUS = 4

local function BountyOnYourHead(inst)
    --if not inst:HasTag("vetcurse") then
        --return
    --end
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, CHAOS_RADIUS, {"wesmustdie"}, {"player", "INLIMBO"})
    for i, target in ipairs(targets) do
		if target.components.combat and target.components.combat:CanTarget(inst) and not target:HasTag("companion") and not target:HasTag("shadowcreature") then
			local WHAT_MY_TARGET_IS_TARGETING = target.components.combat.target
			local PLAYER_OR_COMPANION = WHAT_MY_TARGET_IS_TARGETING and (WHAT_MY_TARGET_IS_TARGETING:HasTag("player") or WHAT_MY_TARGET_IS_TARGETING:HasTag("companion"))
			if not PLAYER_OR_COMPANION then
				if not SPECIAL_FELLOWS[target.prefab] then
					target.components.combat:SetTarget(inst)
				end
			end
		end
    end
end

local function SpecialBountyOnYourHead(inst)
    --if not inst:HasTag("vetcurse") then
        --return
    --end
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, SPECIAL_RADIUS, {"wesmustdie"}, {"player", "INLIMBO"})
    for i, target in ipairs(targets) do
		if target.components.combat and target.components.combat:CanTarget(inst) and not target:HasTag("companion") and not target:HasTag("shadowcreature") then
			local WHAT_MY_TARGET_IS_TARGETING = target.components.combat.target
			local PLAYER_OR_COMPANION = WHAT_MY_TARGET_IS_TARGETING and (WHAT_MY_TARGET_IS_TARGETING:HasTag("player") or WHAT_MY_TARGET_IS_TARGETING:HasTag("companion"))
			if not PLAYER_OR_COMPANION then
				if SPECIAL_FELLOWS[target.prefab] then
					target.components.combat:SetTarget(inst)
				end
			end
		end
    end
end

AddPrefabPostInit("wes", function(inst) 
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	inst:AddTag("the_mime")
	inst:DoPeriodicTask(0, BountyOnYourHead)	
	inst:DoPeriodicTask(0, SpecialBountyOnYourHead)
end)

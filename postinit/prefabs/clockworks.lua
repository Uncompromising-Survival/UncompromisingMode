local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------
local clockworks =
{
	"knight",
	"bishop",
	"rook",
	"knight_nightmare",
	"bishop_nightmare",
	"rook_nightmare",
}

local zombies = --Keep the stunning clockworks less likely, roship the least
{
	bight = 0.75,
	knook = 1,
	roship = 0.5,
}

local function ZombieClockwork(inst,target)
	local x,y,z = inst.Transform:GetWorldPosition()
	local x2 = x + math.random(-8, 8)
	local z2 = z + math.random(-8, 8)
	while not TheWorld.Map:IsPassableAtPoint(x2, 0, z2) do
		x2 = x + math.random(-8, 8)
		z2 = z + math.random(-8, 8)
	end
	local zombie = SpawnPrefab(weighted_random_choice(zombies))
	zombie.Transform:SetPosition(x2, 0, z2)
	if not zombie:HasTag("uncompromising_pawn") then
		zombie.sg:GoToState("zombie")
	end
	--[[if target ~= nil and zombie.components.combat ~= nil then
		zombie.components.combat:SuggestTarget(target)
	end]]
end

local function LookNearby(inst,data)
	local x,y,z = inst.Transform:GetWorldPosition()
	local clockworks = #TheSim:FindEntities(x,y,z,24,{"chess"},{"mech"})
	local chessjunk = FindEntity(inst,24,nil,{"chess","mech"})
	if (math.random()-(clockworks^1.5)*0.1) > 0.6 and TUNING.DSTU.AMALGAMS and chessjunk ~= nil then -- We want it to be pretty likely if it was the last clockwork, however, if there's more than 1 it shouldn't be likely
		if data.afflicter ~= nil then
			if chessjunk.SpawnClockwork ~= nil then
				chessjunk.SpawnClockwork(chessjunk,data.afflicter)
			end
		else
			if chessjunk.SpawnClockwork ~= nil then
				chessjunk.SpawnClockwork(chessjunk,nil)
			end
		end
	elseif (math.random()-(clockworks^1.5)*0.1) > 0.8 and TheWorld:HasTag("cave") then --Not quite as likely if there's no chessjunk nearby, but still have a very rare case where a zombie may come out of the ground, damaged pawns can come too
		if data.afflicter ~= nil then
			ZombieClockwork(inst,data.afflicter)
		else
			ZombieClockwork(inst,nil)
		end
	end
end

for i, v in ipairs(clockworks) do
	env.AddPrefabPostInit(v, function(inst)
		inst:ListenForEvent("death", LookNearby)
	end)
end


---------------------------------------------------------------------------------------------------------
--- Clockwork follower regen removal and repair
---------------------------------------------------------------------------------------------------------

TUNING.CLOCKWORK_HEALTH_REGEN_PERIOD = 60
TUNING.CLOCKWORK_HEALTH_REGEN = 0

--[[
local function ShouldAcceptGears(inst, item, giver)
	if not inst.components.follower:GetLeader() then
		return false
	end

	return 	item.prefab == "gears" --and 
			--inst.components.follower ~= nil and 
			--inst.components.follower.leader == giver
end

local function OnAcceptGears(inst, giver, item)
	-- Heal the knight
	if inst.components.health then
		inst.components.health:DoDelta(1000) -- adjust healing amount
	end

	-- Optional: play a sound or effect
	inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
end

local function MakeRepairable(inst)

	--trader (from trader component) added to pristine state for optimization
	inst:AddComponent("trader")

	if not TheWorld.ismastersim then
        return inst
    end

	inst.components.trader:SetAcceptTest(ShouldAcceptGears)
	inst.components.trader.onaccept = OnAcceptGears
	--inst.components.trader.acceptnontradable = true
end

for i, v in ipairs(clockworks) do
	env.AddPrefabPostInit(v, function(inst)
		MakeRepairable(inst)

	end)
end]]

local GIVEGEAR = Action({ priority = 1 })
GIVEGEAR.id = "GIVEGEAR"
GIVEGEAR.str = "Repair"
GIVEGEAR.fn = function(act)
    local target = act.target
    local item = act.invobject

    if target ~= nil and item ~= nil and item.prefab == "gears" then

		target.components.health:DoDelta(1000)

		target.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")

                -- Handle stack properly
        if item.components.stackable ~= nil then
            local single = item.components.stackable:Get(1)
            if single ~= nil then
                single:Remove()
            end
        else
            item:Remove()
        end
        return true
    end

    return false
end

env.AddAction(GIVEGEAR)

env.AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	
    if target ~= nil
        and inst.prefab == "gears"
		and target:HasTag("chess")
		--and target._hasleader ~= nil
        --and target._hasleader:value()  then
		and target.replica.health ~= nil then
		--and target.replica.health:IsHurt() then

        table.insert(actions, ACTIONS.GIVEGEAR)
    end
end)

env.AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.GIVEGEAR, "doshortaction"))
env.AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.GIVEGEAR, "doshortaction"))

env.AddComponentAction("SCENE", "inspectable", function() end)



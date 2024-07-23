local env = env
GLOBAL.setfenv(1, GLOBAL)
-----------------------------------------------------------------

local rocks = {
	"rock1",
	"rock2",
	"rock_flintless",
	"rock_moon",
	"rock_lichen",
	"springrock1",
	"springrock2",
}

local function EvolveIntoCrab(inst,worker)
	RemovePhysicsColliders(inst)
	local crab = SpawnPrefab("boulder_crab")
	crab.Transform:SetPosition(inst.Transform:GetWorldPosition())
	crab.GetRock(crab,inst.prefab)
	crab.futuretarget = worker
	crab:Hide()
	crab.temprock = inst
	crab:DoTaskInTime(1,function(inst) inst.components.combat:SetTarget(inst.futuretarget) end)
	crab.sg:GoToState("hide_pst")
	--inst:Remove()
end

local function TryCrab(inst,worker)
	local days_survived = worker.components.age ~= nil and worker.components.age:GetAgeInDays() or TheWorld.state.cycles
	if days_survived >= 0 then --Maybe no min for crabbos? they're a lot easier than treeguards.
		local chance = 0.0125
		if days_survived > 20 then -- After 1st season
			chance = 2*chance
		end
		if days_survived > 70 then -- After 1st year
			chance = 2*chance
		end
		if math.random() < chance then
			if days_survived <= 30 then
				EvolveIntoCrab(inst,worker)
			else
				EvolveIntoCrab(inst,worker)
				for k = 1, (days_survived <= 30 and 1) or math.random(days_survived <= 80 and 3 or 6) do
					local target = FindEntity(inst, TUNING.LEIF_MAXSPAWNDIST, nil, {"boulder"})
					if target ~= nil and (target.prefab == "rock1" or target.prefab == "rock2" or target.prefab == "rock_flintless") then
						EvolveIntoCrab(target,worker)
					end
				end
			end
		end
	end
end

local function NewCallBack(inst, worker, workleft)
	local x,y,z = inst.Transform:GetWorldPosition()
	if inst.crab then -- If crab then use his position instead
		x,y,z = inst.crab.Transform:GetWorldPosition()
		if workleft <= 0 then
			inst.crab.components.health:SetAbsorptionAmount(0)
			inst.crab.components.timer:StartTimer("startregenrock",math.random(60*4,60*8))--half to a full day
			if (inst.crab.components.sleeper and not inst.crab.components.sleeper:IsAsleep()) and inst.crab.components.health and not inst.crab.components.health:IsDead() then
				inst.crab.sg:GoToState("fuckingsad")
			end
		end
	end
	local crabs = TheSim:FindEntities(x,y,z,20,{"rocky"})
	for i,crab in ipairs(crabs) do
		if crab.prefab == "boulder_crab" and crab.components.combat and (crab.components.sleeper and not crab.components.sleeper:IsAsleep()) then
			crab.components.combat:SuggestTarget(worker)
			if crab.hiding and not crab.components.timer:TimerExists("regenrock") then
				crab.sg:GoToState("hide_pst")
			end
		end
	end
	if workleft >= TUNING.ROCKS_MINE-2 and not inst.crab then
		TryCrab(inst,worker)
	end
	inst._oldcallworkableback(inst, worker, workleft)
end

for i,v in ipairs(rocks) do
	env.AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst._oldcallworkableback = inst.components.workable.onwork
		inst.components.workable:SetOnWorkCallback(NewCallBack)	
	
	end)
end
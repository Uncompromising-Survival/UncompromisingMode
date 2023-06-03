local prefabs = {
	"um_pyre_nettles",
	"houndfire"
}


local onsurface = false
local oncave = false
local function WorldCheck(inst)
	if TheWorld:HasTag("forest") then
		onsurface = true
	end
	if TheWorld:HasTag("cave") then
		oncave = true
	end
end


-- Use lootdropper to drop hound fires in a natural-looking way.
SetSharedLootTable( 'um_smolder_spore',
{
	{'houndfire', 1.0},
	{'houndfire', 1.0},
	{'houndfire', 0.5},
	{'houndfire', 0.25}
})


-- THIS LIST IS INCOMPLETE
-- COMPLETE IT WHEN ALL LAVA CAVE TURFS HAVE BEEN ADDED (but don't add the actual liquid lava turf to this lmao)
-- Turfs that smolder spores are restricted to.
local function IsAcceptableTurf(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tile_at_position = TheWorld.Map:GetTileAtPoint(x, y, z)
	
	if tile_at_position == WORLD_TILES.MAGMA_ASH
	or tile_at_position == WORLD_TILES.MAGMA_ROCK
	or tile_at_position == WORLD_TILES.MAGMAFIELD
	or oncave == false -- Allows spores to exist anywhere when not in the caves. Should only be relevant in testing or near Dragonfly lava.
	then
		return true
	else
		return false
	end
end


-- This prefab just isn't complicated enough to need seperate files for movement. One block of code suffices.
local function SimpleWander(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		if math.random() > 0.5 then
			inst.components.locomotor:RunInDirection(math.random(1, 359))
			inst.components.locomotor:RunForward()
			inst:DoTaskInTime(math.random(4, 7), function()
				inst.components.locomotor:Stop()
			end)
		end
	end
end


local function PlantSelf(inst)
	local blockers = FindClosestEntity(inst, 1, true, { "blocker" }, { "invisible", "notarget", "noattack", "playerghost" })
	local nettlescrowding = FindClosestEntity(inst, 2, true, { "PyreNettle" })
	local x, y, z = inst.Transform:GetWorldPosition()
	local findnettles = TheSim:FindEntities(x, y, z, 50, {"PyreNettle"})
	
	if not inst:HasTag("BUSYSMOLDERSPORE")
	and blockers == nil
	and nettlescrowding == nil
	and #findnettles < 32
	then
		inst:AddTag("BUSYSMOLDERSPORE")
		
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("divebomb", false)
		inst:ListenForEvent("animover", function()
			SpawnPrefab("um_pyre_nettles").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst:DoTaskInTime(0, function()
				inst:Remove()
			end)
		end)
	end
	
	-- If the planting failed, wait a bit and try again.
	inst:DoTaskInTime(10, PlantSelf)
end


-- Spread some fire around!
local function FireSpread(inst)
	-- Makes the spore uninterractable past this point, because it should be visually destroying itself by the time we get here.
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")
	inst:AddTag("noattack")
	
	-- Instantly ignites anything flammable within a radius.
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, nil, { "plantkin", "FX", "NOCLICK", "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	for i, v in pairs(ents) do
		if v.components.burnable ~= nil then
			v.components.burnable:Ignite()
		end
	end
	
	-- Slight AoE damage. Mainly to set off other nearby Smolder Spores.
	inst.components.combat:DoAreaAttack(inst, 3, nil, nil, nil, { "SmolderSporeAvoid", "BUSYSMOLDERSPORE", "INLIMBO", "invisible", "notarget", "noattack" })
	
	inst.components.lootdropper:DropLoot(inst:GetPosition())
end


-- Suddenly pop!
local function PopSpore(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		inst:AddTag("BUSYSMOLDERSPORE")
		
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("explode", false)
		
		FireSpread(inst)
		inst:DoTaskInTime(2, function()
			inst:Remove()
		end)
	end
end

-- Divebomb the ground and explode!
local function Divebomb(inst)
	if not inst:HasTag("BUSYSMOLDERSPORE") then
		inst:AddTag("BUSYSMOLDERSPORE")
		
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("divebomb", false)
		inst:ListenForEvent("animover", function()
			inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/firehound_explo")
			SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
			
			FireSpread(inst)
			inst:DoTaskInTime(1, function()
				inst:Remove()
			end)
		end)
	end
end


local function TargetCheck(inst)
	local nextvictim = FindClosestEntity(inst, 1, true, nil, { "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	
	if not inst:HasTag("BUSYSMOLDERSPORE")
	and nextvictim ~= nil
	and nextvictim.components.burnable ~= nil
	and not nextvictim:HasTag("plantkin")
	and not (nextvictim.components.health ~= nil and nextvictim.components.health:IsDead())
	and not (nextvictim:HasTag("SmolderSporeAvoid") and math.random() > 0.01) -- This keeps them from constantly seeking pyre nettles.
	and (nextvictim:HasTag("player") or math.random() > 0.5) -- For anything but a player, chance to not activate.
	then
		Divebomb(inst)
	end
end


local function TurfCheck(inst)
	if IsAcceptableTurf(inst) == false then
		Divebomb(inst)
	end
end


local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()
	
	MakeCharacterPhysics(inst, 1, 0.5)
	RemovePhysicsColliders(inst)
	
	inst.AnimState:SetBank("um_smolder_spore")
	inst.AnimState:SetBuild("um_smolder_spore")
	inst.Transform:SetScale(1.25, 1.25, 1.25)
	inst.AnimState:PlayAnimation("spawn", false)
	inst.AnimState:PushAnimation("idle", true)
	
	inst:AddTag("PyreToxinImmune")
	inst:AddTag("soulless") -- Prefab shouldn't die via health loss, but...just in case.
	inst:AddTag("scarytoprey")
	inst:AddTag("flying")
	
	inst.Light:Enable(true)
	inst.Light:SetRadius(0.5)
	inst.Light:SetFalloff(0.5)
	inst.Light:SetIntensity(0.75)
	inst.Light:SetColour(235 / 255, 121 / 255, 12 / 255)
	
	inst.no_wet_prefix = true
	
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = 1
	inst.components.locomotor.runspeed = 1
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("um_smolder_spore")
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(5) -- To make it poppable via ranged attacks or earthquake drops.
	inst.components.health:SetMinHealth(1) -- We don't want it to die a 'normal' death.
	inst.components.health.fire_damage_scale = 0 -- Take no damage from fire.
	
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(1)
	
	inst:AddComponent("hauntable")
	inst.components.hauntable:SetOnHauntFn(Divebomb)
	
	inst:ListenForEvent("attacked", PopSpore)
	inst:ListenForEvent("explosion", PopSpore)
	
	inst:DoPeriodicTask((FRAMES * 3), TargetCheck, 5)
	inst:DoTaskInTime((math.random(1, 60) * math.random(1, 5)) + 30, PlantSelf)
	
	inst.persists = false
	
	inst:DoTaskInTime(0, WorldCheck)
	inst:DoPeriodicTask(10, TurfCheck, 10)
	
	inst:DoPeriodicTask(9, SimpleWander, 2)
	
	return inst
end

return Prefab("um_smolder_spore", fn, nil, prefabs)
